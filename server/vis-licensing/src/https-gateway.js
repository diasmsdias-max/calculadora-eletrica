'use strict';

const fs = require('node:fs');
const http = require('node:http');
const https = require('node:https');

const publicPrefix = '/api/v1/licensing/';

function isPublicLicensingPath(requestUrl) {
  try {
    const parsed = new URL(requestUrl, 'https://vis.local');
    return parsed.pathname.startsWith(publicPrefix);
  } catch (_) {
    return false;
  }
}

function jsonError(res, status, code, message) {
  const payload = Buffer.from(JSON.stringify({
    contractVersion: 1,
    error: { code, message },
  }));
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'content-length': payload.length,
    'cache-control': 'no-store',
  });
  res.end(payload);
}

function startGateway() {
  const host = process.env.VIS_LICENSE_HTTPS_HOST || '0.0.0.0';
  const port = Number(process.env.VIS_LICENSE_HTTPS_PORT || 8444);
  const upstreamPort = Number(process.env.VIS_LICENSE_PORT || 8787);
  const certFile = process.env.VIS_LICENSE_TLS_CERT_FILE || '';
  const keyFile = process.env.VIS_LICENSE_TLS_KEY_FILE || '';
  if (!certFile || !keyFile) {
    throw new Error('VIS_LICENSE_TLS_CERT_FILE e VIS_LICENSE_TLS_KEY_FILE são obrigatórios.');
  }

  const server = https.createServer({
    cert: fs.readFileSync(certFile),
    key: fs.readFileSync(keyFile),
    minVersion: 'TLSv1.2',
  }, (req, res) => {
    if (!isPublicLicensingPath(req.url || '')) {
      return jsonError(res, 404, 'NOT_FOUND', 'Rota não encontrada.');
    }

    const headers = { ...req.headers };
    delete headers['x-vis-admin-token'];
    headers.host = `127.0.0.1:${upstreamPort}`;
    headers['x-forwarded-proto'] = 'https';

    const proxy = http.request({
      host: '127.0.0.1',
      port: upstreamPort,
      method: req.method,
      path: req.url,
      headers,
    }, (upstream) => {
      res.writeHead(upstream.statusCode || 502, upstream.headers);
      upstream.pipe(res);
    });
    proxy.on('error', () => {
      if (!res.headersSent) {
        jsonError(res, 502, 'SERVER_UNAVAILABLE', 'Servidor de licenciamento indisponível.');
      } else {
        res.destroy();
      }
    });
    req.pipe(proxy);
    return undefined;
  });

  server.listen(port, host, () => {
    console.log(`VIS Licensing HTTPS: https://${host}:${port}${publicPrefix}`);
    console.log('Somente a API pública de licenciamento é encaminhada; painel e /admin permanecem locais.');
  });
  return server;
}

if (require.main === module) {
  startGateway();
}

module.exports = { isPublicLicensingPath, startGateway };

