'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { isPublicLicensingPath } = require('../src/https-gateway');

test('publishes only the public licensing prefix', () => {
  assert.equal(isPublicLicensingPath('/api/v1/licensing/activate'), true);
  assert.equal(isPublicLicensingPath('/api/v1/licensing/public-key'), true);
  assert.equal(isPublicLicensingPath('/admin/licenses'), false);
  assert.equal(isPublicLicensingPath('/admin-ui/'), false);
  assert.equal(isPublicLicensingPath('/health'), false);
});

test('normalized traversal cannot reach administrative routes', () => {
  assert.equal(isPublicLicensingPath('/api/v1/licensing/../../admin/licenses'), false);
  assert.equal(isPublicLicensingPath('/api/v1/licensing'), false);
});

