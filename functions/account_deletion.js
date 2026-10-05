// Keep deletion resumable: a retry still removes student records after the
// profile has gone, and authentication failures must not be reported as success.
function createAccountDeletionHandler({db, auth, FieldValue, requireAdmin, requiredString}) {
  async function removeMatches(collection, field, id) {
    while (true) {
      const snapshot = await db.collection(collection).where(field, '==', id).limit(200).get();
      if (snapshot.empty) return;
      for (const doc of snapshot.docs) await db.recursiveDelete(doc.ref);
    }
  }

  async function unlinkParents(id) {
    while (true) {
      const snapshot = await db.collection('users').where('childrenId', '==', id).limit(200).get();
      if (snapshot.empty) return;
      for (const doc of snapshot.docs) {
        await db.runTransaction(async (tx) => {
          const current = await tx.get(doc.ref);
          if (current.exists && current.data().childrenId === id) {
            tx.update(doc.ref, {childrenId: '', updatedAt: FieldValue.serverTimestamp()});
          }
        });
      }
    }
  }

  return async (request) => {
    await requireAdmin(request);
    const id = requiredString(request.data, 'id');
    const reference = db.collection('users').doc(id);
    const existing = await reference.get();
    const uid = existing.data()?.authUid;
    if (uid) {
      try {
        await auth.deleteUser(uid);
      } catch (error) {
        if (error.code !== 'auth/user-not-found') throw error;
      }
    }
    // Removing the profile also prevents existing game sessions from saving
    // more activity records under the Firestore ownership rules.
    await db.recursiveDelete(reference);
    if (!existing.exists || existing.data().role === 'student') {
      await removeMatches('activityScores', 'userId', id);
      await removeMatches('activityScores', 'studentId', id);
      await removeMatches('studentPerformance', 'studentId', id);
      await removeMatches('archivedStudents', 'studentId', id);
      await unlinkParents(id);
    }
    return {id};
  };
}

module.exports = {createAccountDeletionHandler};
