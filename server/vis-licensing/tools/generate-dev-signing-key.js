'use strict';

const fs = require('node:fs');
const path = require('node:path');
const { generateKeyPairSync } = require('node:crypto');

const serverRoot = path.resolve(__dirname, '..');
const output = path.join(serverRoot, '.local-secrets', 'vis-license-ed25519.pem');
const force = process.argv.includes('--force');

if (fs.existsSync(output) && !force) {
  console.error(`A chave já existe em ${output}. Use --force somente para substituí-la deliberadamente.`);
  process.exitCode = 1;
  return;
}

fs.mkdirSync(path.dirname(output), { recursive: true });
const { privateKey } = generateKeyPairSync('ed25519');
const pem = privateKey.export({ type: 'pkcs8', format: 'pem' });
fs.writeFileSync(output, pem, { encoding: 'utf8', mode: 0o600 });

console.log(`Chave Ed25519 de desenvolvimento criada em ${output}`);
console.log('A chave está sob .local-secrets/ e não deve ser versionada ou copiada para o APK.');

