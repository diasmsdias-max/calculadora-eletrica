'use strict';

const fs = require('node:fs');
const path = require('node:path');

class JsonStore {
  constructor(filePath) {
    this.filePath = filePath;
    this.data = {
      schemaVersion: 1,
      customers: [],
      plans: [],
      licenses: [],
      installations: [],
      audit: [],
    };
  }

  load() {
    if (!fs.existsSync(this.filePath)) return this.data;
    const parsed = JSON.parse(fs.readFileSync(this.filePath, 'utf8'));
    if (parsed.schemaVersion !== 1) {
      throw new Error('Versão de persistência VIS não suportada.');
    }
    this.data = parsed;
    return this.data;
  }

  save(data) {
    const dir = path.dirname(this.filePath);
    fs.mkdirSync(dir, { recursive: true });
    const temp = this.filePath + '.tmp';
    const serialized = JSON.stringify(data, null, 2);
    fs.writeFileSync(temp, serialized, { encoding: 'utf8', mode: 0o600 });
    fs.renameSync(temp, this.filePath);
    this.data = data;
  }
}

module.exports = { JsonStore };
