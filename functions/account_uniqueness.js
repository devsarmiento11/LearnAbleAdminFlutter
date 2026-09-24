const normalize = value => String(value ?? '').normalize('NFKC').trim().replace(/\s+/g, ' ').toLowerCase();
function identity(profile) {
  const name = ['firstName', 'middleName', 'lastName'].map(k => normalize(profile[k]));
  if (!name[0] || !name[2]) return null;
  let detail;
  if (profile.role === 'student') {
    const birthday = profile.birthday?.toDate ? profile.birthday.toDate().toISOString() : String(profile.birthday || '');
    detail = birthday.slice(0, 10);
  } else detail = normalize(profile.email);
  return detail ? JSON.stringify([profile.role, ...name, detail]) : null;
}
async function saveUniqueProfile({db, reference, data, HttpsError}) {
  await db.runTransaction(async tx => {
    const existing = await tx.get(reference);
    const accounts = await tx.get(db.collection('users').where('role', '==', data.role));
    const key = identity(data);
    if (existing.exists || (key && accounts.docs.some(doc => identity(doc.data()) === key))) {
      throw new HttpsError('already-exists', 'This account already exists. Check Registered Accounts before creating another.');
    }
    if (data.role === 'parent') {
      const child = await tx.get(db.collection('users').doc(data.childrenId));
      if (!child.exists || child.data().role !== 'student') throw new HttpsError('failed-precondition', 'Children ID must belong to an existing student.');
    }
    tx.create(reference, data);
  });
}
module.exports = {identity, saveUniqueProfile};
