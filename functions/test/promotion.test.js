const test = require('node:test');
const assert = require('node:assert/strict');
const {createPromotionHandler} = require('../promotion');

class HttpsError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
function fixture() {
  const records = new Map([
    ['adminSettings/schoolYear', {currentSchoolYear: '2026-2027'}],
    ['archivedStudents/2024-2025_S1', {schoolYear: '2024-2025', studentId: 'S1', grade: 'Grade 2', overallAverage: 100}],
    ['archivedStudents/2024-2025_S2', {schoolYear: '2024-2025', studentId: 'S2', grade: 'Grade 6'}],
    ['users/S1', {role: 'student', grade: 'Grade 3', username: 'alexis', authUid: 'uid1'}],
    ['users/S2', {role: 'student', grade: 'Grade 6', username: 'bigstar'}],
  ]);
  function reference(collection, id) { return {path: `${collection}/${id}`, id}; }
  function snapshot(ref) { return {id: ref.id, exists: records.has(ref.path), data: () => structuredClone(records.get(ref.path))}; }
  const db = {
    collection(name) { return {
      doc(id) { return reference(name, id); },
      where(field, op, value) { return {name, field, value, limit(n) { return {...this, max: n}; }}; },
    }; },
    async runTransaction(callback) {
      const writes = [];
      const result = await callback({
        async get(ref) {
          assert.equal(writes.length, 0, 'Reads must precede writes');
          if (ref.path) return snapshot(ref);
          return {docs: [...records].filter(([path, data]) => path.startsWith(ref.name + '/') && data[ref.field] === ref.value)
            .slice(0, ref.max).map(([path]) => snapshot({path, id: path.split('/')[1]}))};
        },
        async getAll(...refs) { assert.equal(writes.length, 0); return refs.map(snapshot); },
        update(ref, data) { writes.push([ref, data]); },
      });
      for (const [ref, data] of writes) {
        const existing = records.get(ref.path);
        for (const [key, value] of Object.entries(data)) {
          existing[key] = value?.union ? [...new Set([...(existing[key] || []), ...value.union])] : value;
        }
      }
      return result;
    },
  };
  const handler = createPromotionHandler({db, HttpsError,
    FieldValue: {arrayUnion: (...values) => ({union: values}), serverTimestamp: () => 'server-time'},
    requireAdmin: async (request) => { if (!request.auth?.token.admin) throw new HttpsError('permission-denied', 'Admin only'); },
  });
  const call = (data, auth = {uid: 'admin', token: {admin: true}}) => handler({auth,
    data: {operation: 'preview', sourceYear: '2024-2025', ...data}});
  const promote = (students = [{id: 'S1', grade: 'Grade 3'}, {id: 'S2', grade: 'Grade 6'}]) =>
    call({operation: 'promote', targetYear: '2026-2027', students});
  return {records, call, promote};
}

test('preview uses current grade, not an old archived grade; no writes', async () => {
  const {records, call} = fixture();
  const before = structuredClone(records);
  const result = await call({});
  assert.equal(result.activeYear, '2026-2027');
  assert.equal(result.candidates[0].nextGrade, 'Grade 4');
  assert.equal(result.candidates[1].nextGrade, 'Grade 7');
  assert.deepEqual(records, before);
});
test('bulk promotion enrolls and increments once, preserves archives and login', async () => {
  const {records, promote, call} = fixture();
  const archive = structuredClone(records.get('archivedStudents/2024-2025_S1'));
  await promote();
  assert.equal(records.get('users/S1').grade, 'Grade 4');
  assert.equal(records.get('users/S2').grade, 'Grade 7');
  assert.equal(records.get('users/S1').schoolYear, '2026-2027');
  assert.equal(records.get('users/S1').status, 'Active');
  assert.equal(records.get('users/S1').authUid, 'uid1');
  assert.deepEqual(records.get('archivedStudents/2024-2025_S1'), archive);
  assert.equal((await call({})).candidates[0].enrolled, true);
  await assert.rejects(promote(), /Already enrolled/);
  assert.equal(records.get('users/S1').grade, 'Grade 4');
});
test('one missing student rejects the entire group', async () => {
  const {records, promote} = fixture(); records.delete('users/S2');
  await assert.rejects(promote(), /unavailable/);
  assert.equal(records.get('users/S1').grade, 'Grade 3');
});
test('changed grade or target year requires another review', async () => {
  const {records, promote} = fixture(); records.get('users/S2').grade = 'Grade 7';
  await assert.rejects(promote(), /current grade changed/);
  assert.equal(records.get('users/S1').grade, 'Grade 3');
  records.get('adminSettings/schoolYear').currentSchoolYear = '2027-2028';
  await assert.rejects(promote(), /active school year changed/);
});
test('missing, archived, earlier and reopened source years cannot be used', async () => {
  const {records, call, promote} = fixture(); const settings = records.get('adminSettings/schoolYear');
  settings.currentSchoolYear = '';
  assert.match((await call({})).issue, /Set an active/);
  await assert.rejects(promote(), /Set an active/);
  settings.currentSchoolYear = '2023-2024';
  assert.match((await call({})).issue, /later than/);
  settings.currentSchoolYear = '2026-2027'; settings.archivedSchoolYears = ['2026-2027'];
  assert.match((await call({})).issue, /Set an active/);
  settings.unarchivedSchoolYears = ['2026-2027'];
  assert.equal((await call({})).issue, '');
  settings.unarchivedSchoolYears.push('2024-2025');
  await assert.rejects(promote(), /no longer archived/);
});
test('rejects unauthorized calls, duplicates and students outside the archive', async () => {
  const {call, promote} = fixture();
  await assert.rejects(call({}, null), /Admin only/);
  await assert.rejects(promote([{id: 'S1', grade: 'Grade 3'}, {id: 'S1', grade: 'Grade 3'}]), /distinct/);
  await assert.rejects(promote([{id: 'S3', grade: 'Grade 3'}]), /no longer in this archive/);
});
test('invalid grades and later enrollments are ineligible', async () => {
  const {records, call, promote} = fixture();
  records.get('users/S1').grade = 'Unknown';
  records.get('users/S2').schoolYear = '2028-2029';
  const {candidates} = await call({});
  assert.match(candidates[0].reason, /Update this student/);
  assert.match(candidates[1].reason, /later school year/);
  await assert.rejects(promote(), /Update this student/);
});
