const crypto = require('node:crypto');
const {saveUniqueProfile} = require('./account_uniqueness');

function createStudentEnrollmentHandlers({db, auth, FieldValue, HttpsError}) {
  const fail = (message, code = 'invalid-argument') => { throw new HttpsError(code, message); };
  const text = (data, key) => typeof data?.[key] === 'string' ? data[key].trim() : '';
  const required = (data, key, max = 200) => {
    const value = text(data, key);
    if (!value || value.length > max || /[\x00-\x1f]/.test(value)) fail(`Enter a valid ${key}.`);
    return value;
  };
  async function teacher(request) {
    if (!request.auth) fail('Sign in with your teacher account.', 'unauthenticated');
    const id = request.auth.token?.name;
    if (typeof id !== 'string' || !id || id.includes('/')) fail('A verified teacher account is required.', 'permission-denied');
    const profile = await db.collection('users').doc(id).get();
    if (!profile.exists || profile.data().role !== 'teacher' || profile.data().authUid !== request.auth.uid)
      fail('A verified teacher account is required.', 'permission-denied');
    return request.auth.uid;
  }
  function personal(data) {
    const firstName = required(data, 'firstName'), middleName = required(data, 'middleName'), lastName = required(data, 'lastName');
    const grade = required(data, 'grade'), gender = required(data, 'gender'), condition = required(data, 'condition');
    if (!/^Grade [1-6]$/.test(grade) || !['Male', 'Female'].includes(gender)) fail('Select a valid grade and gender.');
    const birthday = required(data, 'birthday');
    const date = new Date(birthday + 'T00:00:00.000Z');
    if (!/^\d{4}-\d{2}-\d{2}$/.test(birthday) || !Number.isFinite(date.getTime()) || date.toISOString().slice(0, 10) !== birthday ||
        birthday < '1900-01-01' || birthday > new Date().toISOString().slice(0, 10)) fail('Enter a valid birthday.');
    const now = new Date(); let age = now.getUTCFullYear() - date.getUTCFullYear();
    if (now.getUTCMonth() < date.getUTCMonth() || (now.getUTCMonth() === date.getUTCMonth() && now.getUTCDate() < date.getUTCDate())) age--;
    return {firstName, middleName, lastName, name: [firstName, middleName, lastName].join(' '), grade, gender, condition, birthday, age};
  }
  function family(data) {
    const result = {address: required(data, 'address', 500), contactNumber: required(data, 'contactNumber', 20), relationship: required(data, 'relationship')};
    if (!/^\+?[0-9 ()-]{7,20}$/.test(result.contactNumber)) fail('Enter a valid contact number.');
    for (const prefix of ['mother', 'father', 'guardian']) {
      const name = required(data, prefix + 'Name'); const parts = name.split(/\s+/);
      // Match the split-name fields used by the admin app, preserving the complete name.
      result[prefix + 'FirstName'] = parts.slice(0, -1).join(' ') || parts[0];
      result[prefix + 'LastName'] = parts.length > 1 ? parts.at(-1) : '';
    }
    return result;
  }
  function password(data, optional) {
    const value = typeof data?.password === 'string' ? data.password : '';
    if (optional && value === '') return '';
    if (value.length < 6 || value.length > 128) fail('Password must contain 6 to 128 characters.');
    return value; // Do not trim passwords or store them in Firestore.
  }
  function studentId(data) {
    const id = required(data, 'id', 64);
    if (!/^[A-Z0-9][A-Z0-9_-]{0,63}$/.test(id)) fail('Enter a valid uppercase Student ID or LRN.');
    return id;
  }
  async function enroll(request) {
    const owner = await teacher(request), id = studentId(request.data);
    const pass = password(request.data, false);
    const profile = {...personal(request.data?.profile), ...family(request.data?.profile)};
    const requestId = required(request.data, 'requestId', 32);
    if (!/^[a-f0-9]{32}$/.test(requestId)) fail('Invalid enrollment request.');
    const reference = db.collection('users').doc(id);
    const existing = await reference.get();
    if (existing.exists) {
      if (existing.data().enrollmentRequestId === requestId && existing.data().enrolledBy === owner) return {id};
      fail('This Student ID already exists. Enter another ID.', 'already-exists');
    }
    const uid = 'enroll_' + crypto.createHash('sha256').update(owner + ':' + requestId).digest('hex');
    let created = false;
    try {
      await auth.createUser({uid, email: `${id.toLowerCase()}@users.learnable.app`, password: pass, displayName: id}); created = true;
      await saveUniqueProfile({db, reference, HttpsError, data: {
        ...profile, id, userId: id, schoolId: id, username: id, usernameLower: id.toLowerCase(), authUid: uid,
        role: 'student', status: 'Active', createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
        enrolledBy: owner, enrollmentRequestId: requestId,
      }});
      return {id};
    } catch (error) {
      if (created) await auth.deleteUser(uid).catch(() => undefined);
      if (error instanceof HttpsError) throw error;
      if (['auth/email-already-exists', 'auth/uid-already-exists'].includes(error.code))
        fail('This ID is already in use or enrollment is still processing. Check the student list before retrying.', 'already-exists');
      fail('Unable to create the student account. Please try again.', 'internal');
    }
  }
  async function update(request) {
    const owner = await teacher(request), id = studentId(request.data), section = text(request.data, 'section');
    if (!['personal', 'family', 'account'].includes(section)) fail('Select an information section first.');
    const reference = db.collection('users').doc(id);
    const existing = await reference.get();
    if (!existing.exists || existing.data().role !== 'student') fail('This student account is no longer available.', 'not-found');
    if (section === 'account') {
      const pass = password(request.data, true);
      if (pass) {
        if (!existing.data().authUid) fail('This account has no login. Contact the administrator.', 'failed-precondition');
        await auth.updateUser(existing.data().authUid, {password: pass});
      }
      return {id};
    }
    const patch = section === 'personal' ? personal(request.data?.profile) : family(request.data?.profile);
    await db.runTransaction(async tx => {
      const current = await tx.get(reference);
      if (!current.exists || current.data().role !== 'student') fail('This student account is no longer available.', 'not-found');
      tx.update(reference, {...patch, updatedAt: FieldValue.serverTimestamp(), profileUpdatedBy: owner});
    });
    return {id};
  }
  return {enroll, update};
}
module.exports = {createStudentEnrollmentHandlers};
