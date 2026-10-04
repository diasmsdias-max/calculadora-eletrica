'use strict';

const http = require('node:http');
const {
  randomUUID, randomBytes, createHash, createPrivateKey, createPublicKey, sign,
} = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const { JsonStore } = require('./store');

const port = Number(process.env.VIS_LICENSE_PORT || 8787);
const host = process.env.VIS_LICENSE_HOST || '127.0.0.1';
const signingKeyPath = process.env.VIS_LICENSE_PRIVATE_KEY_FILE || '';
const signingKeyId = process.env.VIS_LICENSE_KEY_ID || 'vis-license-signing-1';
const dataFile = process.env.VIS_LICENSE_DATA_FILE || path.join(__dirname, '..', '.local-data', 'licensing-v1.json');
const adminToken = process.env.VIS_LICENSE_ADMIN_TOKEN || '';

if (host !== '127.0.0.1' && host !== '::1' && !adminToken) {
  throw new Error('VIS_LICENSE_ADMIN_TOKEN é obrigatório ao expor o servidor fora do loopback.');
}

if (!signingKeyPath) {
  throw new Error('VIS_LICENSE_PRIVATE_KEY_FILE é obrigatório. A chave privada deve ficar fora do repositório.');
}
const privateKey = createPrivateKey(fs.readFileSync(signingKeyPath));
if (privateKey.asymmetricKeyType !== 'ed25519') {
  throw new Error('A chave de licenciamento deve ser Ed25519.');
}
const publicKey = createPublicKey(privateKey);
const publicKeyPem = publicKey.export({ type: 'spki', format: 'pem' });
const publicKeyDer = publicKey.export({ type: 'spki', format: 'der' });
// Ed25519 SPKI DER termina nos 32 bytes da chave pública (RFC 8410).
const publicKeyRawBase64 = Buffer.from(publicKeyDer).subarray(-32).toString('base64');

const store = new JsonStore(dataFile);
const persisted = store.load();
const state = {
  customers: new Map(persisted.customers.map((item) => [item.id, item])),
  plans: new Map(persisted.plans.map((item) => [item.code, item])),
  licensesByHash: new Map(persisted.licenses.map((item) => [item.activationKeyHash, item])),
  installations: new Map(persisted.installations.map((item) => [item.storageKey, item])),
  audit: persisted.audit,
};

if (!state.plans.has('professional')) {
  state.plans.set('professional', {
    id: randomUUID(),
    code: 'professional',
    name: 'VIS ELECTRICA Profissional',
    defaultMaxDevices: 1,
    offlineDays: 7,
    permissions: ['professional'],
    status: 'ACTIVE',
  });
  persist();
}

function persist() {
  store.save({
    schemaVersion: 1,
    customers: [...state.customers.values()],
    plans: [...state.plans.values()],
    licenses: [...state.licensesByHash.values()],
    installations: [...state.installations.entries()].map(([storageKey, item]) => ({ ...item, storageKey })),
    audit: state.audit,
  });
}

function sha256(value) {
  return createHash('sha256').update(value, 'utf8').digest('hex');
}
function base64url(value) {
  return Buffer.from(value).toString('base64url');
}
function canonicalPayload(payload) {
  // Campos são construídos nesta ordem fixa para VIS-LIC-1.
  return JSON.stringify(payload);
}
function issueCredential({ license, installation, plan, offlineValidUntil }) {
  const payload = {
    contractVersion: 1,
    credentialFormat: 'VIS-LIC-1',
    licenseId: license.id,
    installationIdHash: installation.installationIdHash,
    plan: license.planCode,
    permissions: [...license.permissions].sort(),
    issuedAt: new Date().toISOString(),
    offlineValidUntil: offlineValidUntil.toISOString(),
    commercialValidUntil: license.validUntil,
    keyId: signingKeyId,
  };
  const encodedPayload = base64url(canonicalPayload(payload));
  const signature = sign(null, Buffer.from(encodedPayload, 'utf8'), privateKey).toString('base64url');
  return { format: 'VIS-LIC-1', payload: encodedPayload, signature, keyId: signingKeyId };
}
function json(res, status, body) {
  const data = Buffer.from(JSON.stringify(body));
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'content-length': data.length,
    'cache-control': 'no-store',
  });
  res.end(data);
}
async function readJson(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const raw = Buffer.concat(chunks).toString('utf8');
  if (!raw) return {};
  if (raw.length > 32 * 1024) throw new Error('REQUEST_TOO_LARGE');
  return JSON.parse(raw);
}
function error(res, status, code, message) {
  return json(res, status, { contractVersion: 1, error: { code, message } });
}
function generateActivationKey() {
  const token = randomBytes(10).toString('hex').toUpperCase();
  return 'VIS-PRO-' + token.match(/.{1,4}/g).join('-');
}
function audit(action, data = {}) {
  state.audit.push({ id: randomUUID(), occurredAt: new Date().toISOString(), action, ...data });
  persist();
}

async function createCustomer(req, res) {
  const body = await readJson(req);
  if (!body.name || typeof body.name !== 'string') {
    return error(res, 400, 'INVALID_REQUEST', 'Nome do cliente é obrigatório.');
  }
  const customer = {
    id: randomUUID(), name: body.name.trim(), companyName: body.companyName?.trim() || null,
    phone: body.phone?.trim() || null, email: body.email?.trim() || null,
    taxId: body.taxId?.trim() || null, notes: body.notes?.trim() || null,
    status: 'ACTIVE', createdAt: new Date().toISOString(),
  };
  state.customers.set(customer.id, customer);
  persist();
  audit('CUSTOMER_CREATED', { customerId: customer.id });
  return json(res, 201, { contractVersion: 1, customer });
}
async function createLicense(req, res) {
  const body = await readJson(req);
  const customer = state.customers.get(body.customerId);
  const plan = state.plans.get(body.planCode || 'professional');
  if (!customer || !plan) return error(res, 400, 'INVALID_REQUEST', 'Cliente ou plano inválido.');
  const activationKey = generateActivationKey();
  const now = new Date();
  const validUntil = body.validUntil ? new Date(body.validUntil) : new Date(now.getTime() + 365 * 86400000);
  if (Number.isNaN(validUntil.getTime()) || validUntil <= now) {
    return error(res, 400, 'INVALID_REQUEST', 'Validade da licença inválida.');
  }
  const license = {
    id: randomUUID(), customerId: customer.id, planCode: plan.code,
    activationKeyHash: sha256(activationKey), activationKeyHint: activationKey.slice(-4),
    status: 'ACTIVE', validFrom: now.toISOString(), validUntil: validUntil.toISOString(),
    maxDevices: Number.isInteger(body.maxDevices) && body.maxDevices > 0 ? body.maxDevices : plan.defaultMaxDevices,
    permissions: plan.permissions, createdAt: now.toISOString(),
  };
  state.licensesByHash.set(license.activationKeyHash, license);
  persist();
  audit('LICENSE_CREATED', { customerId: customer.id, licenseId: license.id });
  return json(res, 201, {
    contractVersion: 1,
    license: { id: license.id, customerId: license.customerId, planCode: license.planCode,
      status: license.status, validUntil: license.validUntil, maxDevices: license.maxDevices,
      activationKeyHint: license.activationKeyHint },
    activationKey,
  });
}
function publicLicense(license) {
  const activeDevices = [...state.installations.values()]
    .filter((item) => item.licenseId === license.id && item.status === 'ACTIVE').length;
  const customer = state.customers.get(license.customerId);
  return {
    id: license.id,
    customerId: license.customerId,
    customerName: customer?.name || 'Cliente',
    companyName: customer?.companyName || null,
    planCode: license.planCode,
    status: license.status,
    validUntil: license.validUntil,
    maxDevices: license.maxDevices,
    activeDevices,
    activationKeyHint: license.activationKeyHint,
  };
}

function publicInstallation(item) {
  const license = [...state.licensesByHash.values()].find((value) => value.id === item.licenseId);
  const customer = license ? state.customers.get(license.customerId) : null;
  return {
    id: item.id,
    licenseId: item.licenseId,
    customerName: customer?.name || 'Cliente',
    installationIdHint: item.installationIdHint,
    status: item.status,
    activatedAt: item.activatedAt,
    lastSeenAt: item.lastSeenAt,
    deactivatedAt: item.deactivatedAt || null,
  };
}

async function deactivateInstallation(req, res, installationId) {
  const body = await readJson(req);
  const entry = [...state.installations.entries()]
    .find(([, item]) => item.id === installationId);
  if (!entry) return error(res, 404, 'INSTALLATION_NOT_FOUND', 'Dispositivo não encontrado.');
  const [storageKey, installation] = entry;
  if (installation.status !== 'ACTIVE') {
    return json(res, 200, { contractVersion: 1, installation: publicInstallation(installation) });
  }
  installation.status = 'DEACTIVATED';
  installation.deactivatedAt = new Date().toISOString();
  installation.lastSeenAt = installation.deactivatedAt;
  state.installations.set(storageKey, installation);
  persist();
  audit('INSTALLATION_DEACTIVATED', {
    licenseId: installation.licenseId,
    installationId: installation.id,
    reason: typeof body.reason === 'string' ? body.reason.slice(0, 160) : 'ADMIN_TRANSFER',
  });
  return json(res, 200, { contractVersion: 1, installation: publicInstallation(installation) });
}

async function activate(req, res) {
  const body = await readJson(req);
  if (body.contractVersion !== 1 || !body.activationKey || !body.installationId) {
    return error(res, 400, 'INVALID_REQUEST', 'Dados de ativação inválidos.');
  }
  const license = state.licensesByHash.get(sha256(body.activationKey));
  if (!license) return error(res, 401, 'INVALID_ACTIVATION_KEY', 'Chave de ativação inválida.');
  if (license.status !== 'ACTIVE') return error(res, 403, 'LICENSE_INACTIVE', 'Licença inativa.');
  if (new Date(license.validUntil) <= new Date()) return error(res, 403, 'LICENSE_EXPIRED', 'Licença expirada.');

  const installationHash = sha256(body.installationId);
  const key = license.id + ':' + installationHash;
  let installation = state.installations.get(key);
  if (!installation || installation.status !== 'ACTIVE') {
    const active = [...state.installations.values()]
      .filter((item) => item.licenseId === license.id && item.status === 'ACTIVE').length;
    if (active >= license.maxDevices) {
      return error(res, 409, 'DEVICE_LIMIT_REACHED', 'Limite de dispositivos atingido.');
    }
    installation = {
      id: randomUUID(), licenseId: license.id, installationIdHash: installationHash,
      installationIdHint: installationHash.slice(0, 8), status: 'ACTIVE',
      activatedAt: new Date().toISOString(), lastSeenAt: new Date().toISOString(),
    };
    state.installations.set(key, installation);
    persist();
    audit('INSTALLATION_ACTIVATED', { licenseId: license.id, installationId: installation.id });
  } else {
    installation.lastSeenAt = new Date().toISOString();
    persist();
  }

  const plan = state.plans.get(license.planCode);
  const offlineValidUntil = new Date(Date.now() + plan.offlineDays * 86400000);
  if (offlineValidUntil > new Date(license.validUntil)) offlineValidUntil.setTime(new Date(license.validUntil).getTime());
  const activeDevices = [...state.installations.values()]
    .filter((item) => item.licenseId === license.id && item.status === 'ACTIVE').length;
  const credential = issueCredential({ license, installation, plan, offlineValidUntil });

  return json(res, 200, {
    contractVersion: 1, status: 'ACTIVE',
    license: { licenseId: license.id, plan: license.planCode, permissions: license.permissions,
      commercialValidUntil: license.validUntil, maxDevices: license.maxDevices, activeDevices },
    installation: { id: installation.id, offlineValidUntil: offlineValidUntil.toISOString() },
    credential, serverTime: new Date().toISOString(),
  });
}

function findLicenseById(id) {
  return [...state.licensesByHash.values()].find((item) => item.id === id);
}
function findInstallation(licenseId, rawInstallationId) {
  const installationHash = sha256(rawInstallationId);
  return state.installations.get(licenseId + ':' + installationHash);
}
function ensureActiveLicense(res, license) {
  if (!license) { error(res, 404, 'LICENSE_INACTIVE', 'Licença não encontrada.'); return false; }
  if (license.status !== 'ACTIVE') { error(res, 403, 'LICENSE_INACTIVE', 'Licença inativa.'); return false; }
  if (new Date(license.validUntil) <= new Date()) { error(res, 403, 'LICENSE_EXPIRED', 'Licença expirada.'); return false; }
  return true;
}
function licenseSessionResponse(license, installation) {
  const plan = state.plans.get(license.planCode);
  const offlineValidUntil = new Date(Math.min(
    Date.now() + plan.offlineDays * 86400000,
    new Date(license.validUntil).getTime(),
  ));
  const activeDevices = [...state.installations.values()]
    .filter((item) => item.licenseId === license.id && item.status === 'ACTIVE').length;
  return {
    contractVersion: 1,
    status: 'ACTIVE',
    license: {
      licenseId: license.id, plan: license.planCode, permissions: license.permissions,
      commercialValidUntil: license.validUntil, maxDevices: license.maxDevices, activeDevices,
    },
    installation: { id: installation.id, offlineValidUntil: offlineValidUntil.toISOString() },
    credential: issueCredential({ license, installation, plan, offlineValidUntil }),
    serverTime: new Date().toISOString(),
  };
}
async function validateOrRefresh(req, res, operation) {
  const body = await readJson(req);
  if (body.contractVersion !== 1 || !body.licenseId || !body.installationId) {
    return error(res, 400, 'INVALID_REQUEST', 'Dados de licença ou instalação inválidos.');
  }
  const license = findLicenseById(body.licenseId);
  if (!ensureActiveLicense(res, license)) return;
  const installation = findInstallation(license.id, body.installationId);
  if (!installation || installation.status !== 'ACTIVE') {
    return error(res, 403, 'INSTALLATION_INACTIVE', 'Instalação inativa ou não autorizada.');
  }
  installation.lastSeenAt = new Date().toISOString();
  persist();
  audit(operation === 'refresh' ? 'LICENSE_REFRESHED' : 'LICENSE_VALIDATED', {
    licenseId: license.id, installationId: installation.id,
  });
  return json(res, 200, licenseSessionResponse(license, installation));
}
async function deactivateSelf(req, res) {
  const body = await readJson(req);
  if (body.contractVersion !== 1 || !body.licenseId || !body.installationId) {
    return error(res, 400, 'INVALID_REQUEST', 'Dados de licença ou instalação inválidos.');
  }
  const license = findLicenseById(body.licenseId);
  if (!license) return error(res, 404, 'LICENSE_INACTIVE', 'Licença não encontrada.');
  const installationHash = sha256(body.installationId);
  const storageKey = license.id + ':' + installationHash;
  const installation = state.installations.get(storageKey);
  if (!installation || installation.status !== 'ACTIVE') {
    return error(res, 403, 'INSTALLATION_INACTIVE', 'Instalação inativa ou não autorizada.');
  }
  installation.status = 'DEACTIVATED';
  installation.deactivatedAt = new Date().toISOString();
  installation.lastSeenAt = installation.deactivatedAt;
  state.installations.set(storageKey, installation);
  persist();
  audit('INSTALLATION_SELF_DEACTIVATED', { licenseId: license.id, installationId: installation.id });
  return json(res, 200, { contractVersion: 1, status: 'DEACTIVATED', serverTime: new Date().toISOString() });
}
async function updateLicense(req, res, licenseId) {
  const body = await readJson(req);
  const license = findLicenseById(licenseId);
  if (!license) return error(res, 404, 'LICENSE_NOT_FOUND', 'Licença não encontrada.');
  if (body.validUntil !== undefined) {
    const validUntil = new Date(body.validUntil);
    if (Number.isNaN(validUntil.getTime()) || validUntil <= new Date()) {
      return error(res, 400, 'INVALID_REQUEST', 'Validade da licença inválida.');
    }
    license.validUntil = validUntil.toISOString();
  }
  if (body.maxDevices !== undefined) {
    if (!Number.isInteger(body.maxDevices) || body.maxDevices < 1 || body.maxDevices > 100) {
      return error(res, 400, 'INVALID_REQUEST', 'Limite de dispositivos inválido.');
    }
    const activeDevices = [...state.installations.values()]
      .filter((item) => item.licenseId === license.id && item.status === 'ACTIVE').length;
    if (body.maxDevices < activeDevices) {
      return error(res, 409, 'DEVICE_LIMIT_BELOW_ACTIVE', 'Desative dispositivos antes de reduzir o limite.');
    }
    license.maxDevices = body.maxDevices;
  }
  license.updatedAt = new Date().toISOString();
  persist();
  audit('LICENSE_UPDATED', {
    licenseId: license.id,
    validUntil: license.validUntil,
    maxDevices: license.maxDevices,
  });
  return json(res, 200, { contractVersion: 1, license: publicLicense(license) });
}

async function setLicenseStatus(req, res, licenseId) {
  const body = await readJson(req);
  const license = findLicenseById(licenseId);
  if (!license) return error(res, 404, 'LICENSE_NOT_FOUND', 'Licença não encontrada.');
  const allowed = new Set(['ACTIVE', 'SUSPENDED', 'REVOKED']);
  if (!allowed.has(body.status)) return error(res, 400, 'INVALID_REQUEST', 'Status de licença inválido.');
  license.status = body.status;
  license.updatedAt = new Date().toISOString();
  persist();
  audit('LICENSE_STATUS_CHANGED', { licenseId: license.id, status: license.status });
  return json(res, 200, { contractVersion: 1, license: publicLicense(license) });
}

function serveStatic(res, fileName, contentType) {
  const publicRoot = path.join(__dirname, '..', 'public');
  const filePath = path.join(publicRoot, fileName);
  const data = fs.readFileSync(filePath);
  res.writeHead(200, {
    'content-type': contentType,
    'content-length': data.length,
    'cache-control': 'no-store',
    'x-content-type-options': 'nosniff',
  });
  res.end(data);
}

const server = http.createServer(async (req, res) => {
  try {
    const path = new URL(req.url, 'http://localhost').pathname;
    const isAdminPath = path === '/admin-ui' || path.startsWith('/admin-ui/') || path === '/admin' || path.startsWith('/admin/');
    if (isAdminPath && adminToken) {
      const supplied = req.headers['x-vis-admin-token'];
      if (typeof supplied !== 'string' || supplied !== adminToken) {
        return error(res, 401, 'ADMIN_AUTH_REQUIRED', 'Autenticação administrativa obrigatória.');
      }
    }
    if (req.method === 'GET' && (path === '/admin-ui' || path === '/admin-ui/')) {
      return serveStatic(res, 'index.html', 'text/html; charset=utf-8');
    }
    if (req.method === 'GET' && path === '/admin-ui/styles.css') {
      return serveStatic(res, 'styles.css', 'text/css; charset=utf-8');
    }
    if (req.method === 'GET' && path === '/admin/dashboard') {
      const activeDevices = [...state.installations.values()].filter((item) => item.status === 'ACTIVE').length;
      return json(res, 200, {
        contractVersion: 1,
        counts: {
          customers: state.customers.size,
          licenses: state.licensesByHash.size,
          activeDevices,
        },
      });
    }
    if (req.method === 'GET' && path === '/health') {
      return json(res, 200, { status: 'ok', service: 'vis-licensing', contractVersion: 1 });
    }
    if (req.method === 'GET' && path === '/api/v1/licensing/public-key') {
      return json(res, 200, {
        contractVersion: 1,
        keyId: signingKeyId,
        algorithm: 'Ed25519',
        publicKeyPem,
        publicKeyRawBase64,
      });
    }
    // /admin permanece bootstrap local sem exposição de rede.
    if (req.method === 'GET' && path === '/admin/customers') {
      return json(res, 200, { contractVersion: 1, customers: [...state.customers.values()] });
    }
    if (req.method === 'POST' && path === '/admin/customers') return await createCustomer(req, res);
    if (req.method === 'GET' && path === '/admin/licenses') {
      return json(res, 200, {
        contractVersion: 1,
        licenses: [...state.licensesByHash.values()].map(publicLicense),
      });
    }
    if (req.method === 'POST' && path === '/admin/licenses') return await createLicense(req, res);
    if (req.method === 'GET' && path === '/admin/installations') {
      return json(res, 200, {
        contractVersion: 1,
        installations: [...state.installations.values()].map(publicInstallation),
      });
    }
    const deactivateMatch = path.match(/^\/admin\/installations\/([^/]+)\/deactivate$/);
    if (req.method === 'POST' && deactivateMatch) {
      return await deactivateInstallation(req, res, decodeURIComponent(deactivateMatch[1]));
    }
    const licenseUpdateMatch = path.match(/^\/admin\/licenses\/([^/]+)$/);
    if (req.method === 'PATCH' && licenseUpdateMatch) {
      return await updateLicense(req, res, decodeURIComponent(licenseUpdateMatch[1]));
    }
    const licenseStatusMatch = path.match(/^\/admin\/licenses\/([^/]+)\/status$/);
    if (req.method === 'POST' && licenseStatusMatch) {
      return await setLicenseStatus(req, res, decodeURIComponent(licenseStatusMatch[1]));
    }
    if (req.method === 'POST' && path === '/api/v1/licensing/activate') return await activate(req, res);
    if (req.method === 'POST' && path === '/api/v1/licensing/validate') return await validateOrRefresh(req, res, 'validate');
    if (req.method === 'POST' && path === '/api/v1/licensing/refresh') return await validateOrRefresh(req, res, 'refresh');
    if (req.method === 'POST' && path === '/api/v1/licensing/deactivate') return await deactivateSelf(req, res);
    return error(res, 404, 'NOT_FOUND', 'Rota não encontrada.');
  } catch (e) {
    if (e instanceof SyntaxError) return error(res, 400, 'INVALID_REQUEST', 'JSON inválido.');
    return error(res, 500, 'SERVER_ERROR', 'Erro interno do servidor.');
  }
});
server.listen(port, host, () => console.log(`VIS Licensing local: http://${host}:${port} | keyId=${signingKeyId}`));
