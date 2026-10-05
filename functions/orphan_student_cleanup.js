function createOrphanStudentCleanupHandler({db, FieldValue, requireAdmin}) {
  return async request => {
    await requireAdmin(request);
    const candidates = new Map();
    function add(id, ref, unlink = false) {
      if (typeof id !== 'string' || !id || id.includes('/') || id === '.' || id === '..') return;
      if (!candidates.has(id)) candidates.set(id, new Map());
      candidates.get(id).set(ref.path, {ref, unlink});
    }
    for (const name of ['archivedStudents', 'studentPerformance', 'activityScores']) {
      const snapshot = await db.collection(name).get();
      for (const doc of snapshot.docs) {
        const data = doc.data();
        add(name === 'activityScores' ? (data.userId ?? data.studentId) : data.studentId, doc.ref);
      }
    }
    const parents = await db.collection('users').where('role', '==', 'parent').get();
    for (const doc of parents.docs) add(doc.data().childrenId, doc.ref, true);
    let removed = 0;
    for (const [id, records] of candidates) {
      const entries = [...records.values()];
      for (let offset = 0; offset < entries.length; offset += 200) {
        const chunk = entries.slice(offset, offset + 200);
        // Checking the account in the transaction protects existing students,
        // including accounts created while this cleanup is running.
        removed += await db.runTransaction(async tx => {
          const account = await tx.get(db.collection('users').doc(id));
          if (account.exists) return 0;
          const links = [];
          for (const entry of chunk.filter(entry => entry.unlink)) {
            links.push({entry, snapshot: await tx.get(entry.ref)});
          }
          for (const entry of chunk.filter(entry => !entry.unlink)) tx.delete(entry.ref);
          for (const {entry, snapshot} of links) {
            if (snapshot.exists && snapshot.data().childrenId === id) {
              tx.update(entry.ref, {childrenId: '', updatedAt: FieldValue.serverTimestamp()});
            }
          }
          return chunk.filter(entry => !entry.unlink).length;
        });
      }
    }
    return {removed};
  };
}
module.exports = {createOrphanStudentCleanupHandler};
