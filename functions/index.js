const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {FieldValue, getFirestore} = require('firebase-admin/firestore');
const {createPromotionHandler} = require('./promotion');
const {parentProfile} = require('./parent_account');
const {saveUniqueProfile} = require('./account_uniqueness');
const {createAccountDeletionHandler} = require('./account_deletion');
const {createOrphanStudentCleanupHandler} = require('./orphan_student_cleanup');

initializeApp();

const db = getFirestore();
const auth = getAuth();
const managedDomain = 'users.learnable.app';
const allowedRoles = new Set(['student', 'teacher', 'parent']);
exports.cleanupOrphanStudentData = onCall({timeoutSeconds: 540}, createOrphanStudentCleanupHandler({
  db, FieldValue, requireAdmin,
}));

const studentEnrollment = require('./student_enrollment').createStudentEnrollmentHandlers({db, auth, FieldValue, HttpsError});
exports.enrollStudent = onCall(studentEnrollment.enroll);
exports.updateStudentEnrollment = onCall(studentEnrollment.update);

exports.promoteArchivedStudents = onCall(createPromotionHandler({
  db, FieldValue, HttpsError, requireAdmin,
}));

function managedEmail(username) {
  const safe = username.trim().toLowerCase().replace(/[^a-z0-9._-]/g, '-');
  return `${safe}@${managedDomain}`;
}

async function requireAdmin(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first.');
  if (request.auth.token.admin === true) return;
  const direct = await db.collection('users').doc(request.auth.uid).get();
  if (direct.data()?.role === 'admin') return;
  const profiles = await db.collection('users')
      .where('authUid', '==', request.auth.uid).limit(1).get();
  if (!profiles.docs.some((profile) => profile.data().role === 'admin')) {
    throw new HttpsError('permission-denied', 'Administrator access is required.');
  }
}

function requiredString(data, field) {
  const value = data?.[field];
  if (typeof value !== 'string' || !value.trim()) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return value.trim();
}

async function assertUniqueUsername(username, exceptId) {
  const match = await db.collection('users')
      .where('usernameLower', '==', username.toLowerCase()).limit(2).get();
  if (match.docs.some((doc) => doc.id !== exceptId)) {
    throw new HttpsError('already-exists', 'This username is already in use.');
  }
}

exports.createManagedAccount = onCall(async (request) => {
  await requireAdmin(request);
  const id = requiredString(request.data, 'id');
  const username = requiredString(request.data, 'username');
  const password = requiredString(request.data, 'password');
  const role = requiredString(request.data, 'role').toLowerCase();
  let profile = request.data?.profile;
  if (!allowedRoles.has(role) || !profile || typeof profile !== 'object' || Array.isArray(profile)) {
    throw new HttpsError('invalid-argument', 'Invalid account profile.');
  }
  if (password.length < 6) {
    throw new HttpsError('invalid-argument', 'Password must contain at least 6 characters.');
  }
  if (role === 'parent') {
    profile = parentProfile(id, username, profile, HttpsError);
    const child = await db.collection('users').doc(profile.childrenId).get();
    if (!child.exists || child.data().role !== 'student') {
      throw new HttpsError('failed-precondition', 'Children ID must belong to an existing student.');
    }
  }
  if ((await db.collection('users').doc(id).get()).exists) {
    throw new HttpsError('already-exists', 'This account ID already exists.');
  }
  await assertUniqueUsername(username);

  let user;
  try {
    user = await auth.createUser({email: managedEmail(username), password, displayName: id});
    const data = {
      ...profile,
      id,
      userId: id,
      authUid: user.uid,
      schoolId: id,
      username,
      usernameLower: username.toLowerCase(),
      role,
      ...(role === 'parent' ? {createdAt: FieldValue.serverTimestamp()} : {}),
      updatedAt: FieldValue.serverTimestamp(),
    };
    const reference = db.collection('users').doc(id);
    await saveUniqueProfile({db, reference, data, HttpsError});
    return {id, uid: user.uid};
  } catch (error) {
    if (user) await auth.deleteUser(user.uid).catch(() => undefined);
    if (error instanceof HttpsError) throw error;
    if (error.code === 'auth/email-already-exists') throw new HttpsError('already-exists', 'This login is already in use.');
    throw new HttpsError('internal', error.message || 'Unable to create account.');
  }
});

exports.updateManagedAccount = onCall(async (request) => {
  await requireAdmin(request);
  const id = requiredString(request.data, 'id');
  const username = requiredString(request.data, 'username');
  const profile = request.data?.profile;
  if (typeof profile !== 'object' || Array.isArray(profile)) {
    throw new HttpsError('invalid-argument', 'Invalid account profile.');
  }
  const reference = db.collection('users').doc(id);
  const existing = await reference.get();
  if (!existing.exists) throw new HttpsError('not-found', 'Account not found.');
  await assertUniqueUsername(username, id);
  const uid = existing.data().authUid;
  if (uid && username.toLowerCase() !== existing.data().usernameLower) {
    await auth.updateUser(uid, {email: managedEmail(username)});
  }
  await reference.set({
    ...profile,
    id,
    username,
    usernameLower: username.toLowerCase(),
    role: existing.data().role,
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return {id};
});

exports.deleteManagedAccount = onCall({timeoutSeconds: 540}, createAccountDeletionHandler({
  db, auth, FieldValue, requireAdmin, requiredString,
}));
