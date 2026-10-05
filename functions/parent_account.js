function parentProfile(id, username, profile, HttpsError) {
  if (!/^P[0-9]{4}$/.test(id) || id === 'P0000' || username !== id) {
    throw new HttpsError('invalid-argument', 'Use a generated Parents ID (e.g. P0001).');
  }
  const text = (key) => typeof profile[key] === 'string' ? profile[key].trim() : '';
  const childrenId = text('childrenId').toUpperCase();
  if (!/^(S[0-9]{4}|[0-9]{1,12})$/.test(childrenId)) {
    throw new HttpsError('invalid-argument', 'Enter an existing Student ID or LRN in Children ID or LRN.');
  }
  if (!text('firstName') || !text('lastName') || !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(text('email'))) {
    throw new HttpsError('invalid-argument', 'First name, last name and a valid email are required.');
  }
  if (!['', 'Male', 'Female'].includes(text('gender'))) {
    throw new HttpsError('invalid-argument', 'Select a valid gender.');
  }
  return {firstName: text('firstName'), middleName: text('middleName'), lastName: text('lastName'),
    email: text('email'), gender: text('gender'), childrenId, status: 'Active'};
}

async function saveParentProfile({db, reference, data, HttpsError}) {
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(reference);
    const child = await transaction.get(db.collection('users').doc(data.childrenId));
    if (existing.exists) throw new HttpsError('already-exists', 'This Parents ID already exists. Generate another ID.');
    if (!child.exists || child.data().role !== 'student') {
      throw new HttpsError('failed-precondition', 'Children ID must belong to an existing student.');
    }
    transaction.create(reference, data);
  });
}
module.exports = {parentProfile, saveParentProfile};
