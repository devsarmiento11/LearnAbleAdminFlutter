const test = require('node:test');
const assert = require('node:assert/strict');
const {createAccountDeletionHandler} = require('../account_deletion');

function fixture({profile = {role: 'student', authUid: 'auth-student'}, failPath, authError, denied = false} = {}) {
  const records = new Map([
    ['users/S1234', profile],
    ['users/S1234/progress/a', {value: 1}],
    ['users/S9999', {role: 'student'}],
    ['users/P1234', {role: 'parent', childrenId: 'S1234'}],
    ['users/P9999', {role: 'parent', childrenId: 'S9999'}],
    ...Array.from({length: 205}, (_, n) => [`activityScores/a${n}`, {userId: 'S1234'}]),
    ['activityScores/legacy', {studentId: 'S1234'}],
    ['activityScores/other', {userId: 'S9999'}],
    ['studentPerformance/2025_S1234', {studentId: 'S1234'}],
    ['archivedStudents/2024_S1234', {studentId: 'S1234'}],
    ['archivedStudents/2025_S1234', {studentId: 'S1234'}],
    ['archivedStudents/other', {studentId: 'S9999'}],
  ].filter(([, data]) => data != null));
  const deletedAuth = [];
  let failOnce = failPath;
  const snapshot = path => {
    const data = records.get(path);
    return {exists: data != null, data: () => data, ref: ref(path)};
  };
  const ref = path => ({path, get: async () => snapshot(path)});
  const db = {
    collection: name => ({
      doc: id => ref(`${name}/${id}`),
      where: (field, op, id) => ({limit: limit => ({get: async () => {
        const docs = [...records].filter(([path, data]) => path.split('/').length === 2 && path.startsWith(`${name}/`) && data[field] === id)
          .slice(0, limit).map(([path]) => snapshot(path));
        return {empty: docs.length === 0, docs};
      }})}),
    }),
    recursiveDelete: async reference => {
      if (reference.path === failOnce) { failOnce = null; throw new Error('temporary failure'); }
      for (const path of records.keys()) {
        if (path === reference.path || path.startsWith(`${reference.path}/`)) records.delete(path);
      }
    },
    runTransaction: async fn => fn({get: async reference => snapshot(reference.path),
      update: (reference, data) => records.set(reference.path, {...records.get(reference.path), ...data})}),
  };
  const handler = createAccountDeletionHandler({db,
    auth: {deleteUser: async uid => { if (authError) throw authError; deletedAuth.push(uid); }},
    FieldValue: {serverTimestamp: () => 'now'},
    requireAdmin: async () => { if (denied) throw new Error('permission-denied'); },
    requiredString: (data, field) => data[field],
  });
  return {records, deletedAuth, remove: () => handler({data: {id: 'S1234'}})};
}

test('deletes login, nested profile data, scores in both formats, all years and parent links', async () => {
  const f = fixture();
  assert.deepEqual(await f.remove(), {id: 'S1234'});
  assert.deepEqual(f.deletedAuth, ['auth-student']);
  assert.equal(f.records.get('users/P1234').childrenId, '');
  assert.equal(f.records.get('users/P9999').childrenId, 'S9999');
  assert.ok(f.records.has('users/S9999'));
  assert.ok(f.records.has('activityScores/other'));
  assert.ok(f.records.has('archivedStudents/other'));
  assert.equal([...f.records].some(([path, data]) => path.includes('S1234') || data.userId === 'S1234' || data.studentId === 'S1234'), false);
  await f.remove(); // Repeating a completed deletion is safe.
});

test('retry finishes cleanup when the profile was deleted before a failure', async () => {
  const f = fixture({failPath: 'studentPerformance/2025_S1234'});
  await assert.rejects(f.remove(), /temporary failure/);
  assert.equal(f.records.has('users/S1234'), false);
  await f.remove();
  assert.equal(f.records.has('studentPerformance/2025_S1234'), false);
  assert.equal(f.records.has('archivedStudents/2024_S1234'), false);
  assert.equal(f.records.get('users/P1234').childrenId, '');
});

test('authorization and auth service failures do not delete stored data', async () => {
  for (const options of [{denied: true}, {authError: new Error('auth unavailable')}]) {
    const f = fixture(options);
    await assert.rejects(f.remove());
    assert.ok(f.records.has('users/S1234'));
    assert.ok(f.records.has('activityScores/a0'));
  }
});

test('an already removed Auth user does not block cleanup', async () => {
  const f = fixture({authError: Object.assign(new Error('missing'), {code: 'auth/user-not-found'})});
  await f.remove();
  assert.equal(f.records.has('users/S1234'), false);
});

test('deleting a teacher does not run student data cleanup', async () => {
  const f = fixture({profile: {role: 'teacher', authUid: 'auth-teacher'}});
  await f.remove();
  assert.ok(f.records.has('activityScores/a0'));
  assert.equal(f.records.get('users/P1234').childrenId, 'S1234');
});
