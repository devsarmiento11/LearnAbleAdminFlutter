const test = require('node:test');
const assert = require('node:assert/strict');
const {parentProfile, saveParentProfile} = require('../parent_account');
class HttpsError extends Error { constructor(code, message) { super(message); this.code = code; } }
const profile = {firstName: 'Jane', middleName: '', lastName: 'Doe', email: 'jane@example.com', gender: 'Female', childrenId: 's2144'};
test('parent profile normalizes Children ID and excludes secrets/untrusted role', () => {
  const data = parentProfile('P0001', 'P0001', {...profile, password: 'secret', role: 'admin'}, HttpsError);
  assert.equal(data.childrenId, 'S2144'); assert.equal(data.password, undefined); assert.equal(data.role, undefined);
});
test('reject invalid parent ID, child ID and missing personal information', () => {
  assert.throws(() => parentProfile('T0001', 'T0001', profile, HttpsError));
  assert.throws(() => parentProfile('P0001', 'other', profile, HttpsError));
  for (const changed of [{childrenId: 'T2144'}, {childrenId: ''}, {firstName: ''}, {lastName: ''}, {email: 'invalid'}]) {
    assert.throws(() => parentProfile('P0001', 'P0001', {...profile, ...changed}, HttpsError));
  }
});
test('save requires an existing student and a unique Parents ID', async () => {
  for (const [exists, childRole, parentExists, succeeds] of [[true, 'student', false, true], [false, '', false, false], [true, 'teacher', false, false], [true, 'student', true, false]]) {
    let saved = null;
    const db = {collection: () => ({doc: (id) => ({id})}), runTransaction: async (fn) => fn({
      get: async (ref) => ref.id === 'P0001' ? {exists: parentExists} : {exists, data: () => ({role: childRole})},
      create: (ref, data) => {saved = data;},
    })};
    const operation = saveParentProfile({db, reference: {id: 'P0001'}, data: {childrenId: 'S2144'}, HttpsError});
    if (succeeds) { await operation; assert.equal(saved.childrenId, 'S2144'); }
    else { await assert.rejects(operation); assert.equal(saved, null); }
  }
});
