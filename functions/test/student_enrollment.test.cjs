const {test} = require('node:test');
const assert = require('node:assert/strict');
const {createStudentEnrollmentHandlers} = require('../student_enrollment');
class HttpsError extends Error { constructor(code, message) { super(message); this.code = code; } }
function fixture() {
  const records = new Map([['T1234', {role: 'teacher', authUid: 'teacher-uid'}]]);
  const users = new Map();
  const snapshot = id => ({id, exists: records.has(id), data: () => records.get(id)});
  const reference = id => ({id, get: async () => snapshot(id)});
  const db = {collection: () => ({doc: reference, where: (key, op, value) => ({query: true, key, value})}),
    runTransaction: async callback => callback({
      get: async ref => ref.query ? {docs: [...records].filter(([, value]) => value[ref.key] === ref.value).map(([id]) => snapshot(id))} : snapshot(ref.id),
      create: (ref, value) => { assert(!records.has(ref.id)); records.set(ref.id, value); },
      update: (ref, value) => { assert(records.has(ref.id)); records.set(ref.id, {...records.get(ref.id), ...value}); },
    })};
  const auth = {
    createUser: async data => { if (users.has(data.uid)) throw Object.assign(new Error(), {code: 'auth/uid-already-exists'}); users.set(data.uid, data); return data; },
    deleteUser: async uid => users.delete(uid),
    updateUser: async (uid, patch) => { assert(users.has(uid)); users.set(uid, {...users.get(uid), ...patch}); },
  };
  const handlers = createStudentEnrollmentHandlers({db, auth, HttpsError, FieldValue: {serverTimestamp: () => 'SERVER_TIME'}});
  const profile = {firstName: 'Alex', middleName: 'Lee', lastName: 'Cruz', grade: 'Grade 3', gender: 'Male', condition: 'ASD', birthday: '2016-03-15',
    motherName: 'Maria Lee Cruz', fatherName: 'Juan Cruz', guardianName: 'Maria Lee Cruz', address: 'Test address', contactNumber: '09123456789', relationship: 'Mother'};
  const request = {auth: {uid: 'teacher-uid', token: {name: 'T1234'}}, data: {id: 'S4321', profile, password: ' secret12 ', requestId: 'a'.repeat(32)}};
  return {handlers, request, records, users};
}
test('enrollment creates compatible login and profile without storing passwords; retry is idempotent', async () => {
  const f = fixture(); await f.handlers.enroll(f.request);
  const student = f.records.get('S4321'), user = f.users.get(student.authUid);
  assert.equal(student.role, 'student'); assert.equal(student.username, 'S4321'); assert.equal(user.email, 's4321@users.learnable.app');
  assert.equal(user.displayName, 'S4321'); assert.equal(user.password, ' secret12 '); assert.equal(student.password, undefined);
  assert.equal(student.motherFirstName, 'Maria Lee'); assert.equal(student.motherLastName, 'Cruz');
  assert.deepEqual(await f.handlers.enroll(f.request), {id: 'S4321'}); assert.equal(f.users.size, 1);
});
test('unauthenticated, student and spoofed teacher callers cannot enroll or edit', async () => {
  for (const auth of [undefined, {uid: 'wrong', token: {name: 'T1234'}}, {uid: 'student', token: {name: 'S4321'}}]) {
    const f = fixture(); f.request.auth = auth;
    await assert.rejects(f.handlers.enroll(f.request), HttpsError);
    await assert.rejects(f.handlers.update(f.request), HttpsError);
    assert.equal(f.users.size, 0);
  }
});
test('missing fields, impossible/future birthdays and short passwords are rejected', async () => {
  for (const patch of [{middleName: ''}, {guardianName: ''}, {birthday: '2016-02-30'}, {birthday: '2999-01-01'}, {grade: 'Grade 9'}, {contactNumber: 'abc'}]) {
    const f = fixture(); Object.assign(f.request.data.profile, patch);
    await assert.rejects(f.handlers.enroll(f.request), {code: 'invalid-argument'}); assert.equal(f.users.size, 0);
  }
  const f = fixture(); f.request.data.password = 'short'; await assert.rejects(f.handlers.enroll(f.request), {code: 'invalid-argument'});
});
test('duplicate IDs and identities do not create a second account', async () => {
  const f = fixture(); await f.handlers.enroll(f.request);
  f.request.data.requestId = 'b'.repeat(32);
  await assert.rejects(f.handlers.enroll(f.request), {code: 'already-exists'});
  f.request.data.id = 'S4322';
  await assert.rejects(f.handlers.enroll(f.request), {code: 'already-exists'});
  assert.equal(f.users.size, 1); assert(!f.records.has('S4322'));
});
test('personal and family edits preserve unrelated data, identity and login', async () => {
  const f = fixture(); await f.handlers.enroll(f.request);
  const existing = f.records.get('S4321'); existing.academicGrades = {MATH_1ST: 98}; existing.schoolYear = '2026-2027';
  f.request.data.section = 'personal'; f.request.data.profile.firstName = 'Updated'; f.request.data.profile.role = 'admin';
  await f.handlers.update(f.request);
  let updated = f.records.get('S4321'); assert.equal(updated.firstName, 'Updated'); assert.equal(updated.name, 'Updated Lee Cruz');
  assert.equal(updated.role, 'student'); assert.equal(updated.authUid, existing.authUid); assert.equal(updated.address, existing.address);
  assert.deepEqual(updated.academicGrades, {MATH_1ST: 98}); assert.equal(updated.schoolYear, '2026-2027');
  f.request.data.section = 'family'; f.request.data.profile.address = 'New address'; f.request.data.profile.firstName = 'Ignored';
  await f.handlers.update(f.request); updated = f.records.get('S4321'); assert.equal(updated.firstName, 'Updated'); assert.equal(updated.address, 'New address');
});
test('account editing changes Auth password only, blank leaves existing password, non-students rejected', async () => {
  const f = fixture(); await f.handlers.enroll(f.request); const student = f.records.get('S4321');
  f.request.data.section = 'account'; f.request.data.password = '';
  await f.handlers.update(f.request); assert.equal(f.users.get(student.authUid).password, ' secret12 ');
  f.request.data.password = 'new password'; await f.handlers.update(f.request); assert.equal(f.users.get(student.authUid).password, 'new password');
  assert.equal(f.records.get('S4321'), student); f.request.data.id = 'T1234';
  await assert.rejects(f.handlers.update(f.request), {code: 'not-found'});
});
