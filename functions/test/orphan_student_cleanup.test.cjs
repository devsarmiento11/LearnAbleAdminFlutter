const test = require('node:test');
const assert = require('node:assert/strict');
const {createOrphanStudentCleanupHandler} = require('../orphan_student_cleanup');

test('cleans absent accounts across years and preserves existing students and parent accounts', async () => {
  const records = new Map([
    ['users/001234567899', {role: 'student'}],
    ['users/P1', {role: 'parent', childrenId: 'gone'}],
    ['users/P2', {role: 'parent', childrenId: '001234567899'}],
    ['archivedStudents/old', {studentId: 'gone'}],
    ['archivedStudents/new', {studentId: 'gone'}],
    ['archivedStudents/keep', {studentId: '001234567899'}],
    ['studentPerformance/old', {studentId: 'gone'}],
    ['activityScores/legacy', {studentId: 'gone'}],
    ...Array.from({length: 205}, (_, n) => [`activityScores/a${n}`, {userId: 'gone'}]),
  ]);
  const ref = path => ({path});
  const snapshot = path => {
    const data = records.get(path);
    return {exists: data != null, data: () => data, ref: ref(path)};
  };
  const collection = (name, filter = () => true) => ({
    doc: id => ref(`${name}/${id}`),
    where: (field, op, value) => collection(name, data => data[field] === value),
    get: async () => ({docs: [...records].filter(([path, data]) => path.startsWith(`${name}/`) && filter(data)).map(([path]) => snapshot(path))}),
  });
  const db = {collection, runTransaction: async fn => fn({
    get: async reference => snapshot(reference.path),
    delete: reference => records.delete(reference.path),
    update: (reference, data) => records.set(reference.path, {...records.get(reference.path), ...data}),
  })};
  const handler = createOrphanStudentCleanupHandler({db, FieldValue: {serverTimestamp: () => 'now'}, requireAdmin: async () => {}});
  assert.equal((await handler({})).removed, 209);
  assert.equal(records.get('users/P1').childrenId, '');
  assert.equal(records.get('users/P2').childrenId, '001234567899');
  assert.ok(records.has('archivedStudents/keep'));
  assert.equal((await handler({})).removed, 0);
});

test('rejects unauthorized cleanup before reading or deleting records', async () => {
  const handler = createOrphanStudentCleanupHandler({db: {}, requireAdmin: async () => {throw new Error('denied');}});
  await assert.rejects(handler({}), /denied/);
});
