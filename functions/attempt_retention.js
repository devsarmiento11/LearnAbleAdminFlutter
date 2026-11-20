const ATTEMPT_LIMIT = 50;
const DELETE_BATCH_SIZE = 400;

function completionTime(document) {
  const value = document.get('completedAt');
  if (value && typeof value.toMillis === 'function') return value.toMillis();
  const milliseconds = typeof value === 'string' ? Date.parse(value) : NaN;
  return Number.isFinite(milliseconds) ? milliseconds : Number.NEGATIVE_INFINITY;
}

async function trimStudentAttempts(db, userId) {
  const attempts = db.collection('activityScores').where('userId', '==', userId);
  let deleted;
  do {
    deleted = await db.runTransaction(async transaction => {
      const snapshot = await transaction.get(attempts);
      if (snapshot.size <= ATTEMPT_LIMIT) return 0;

      const ordered = snapshot.docs
          .map(document => ({document, time: completionTime(document)}))
          .sort((a, b) => (b.time - a.time) || (a.document.id < b.document.id ? 1 : -1));
      const overflow = ordered.slice(-Math.min(DELETE_BATCH_SIZE, ordered.length - ATTEMPT_LIMIT));
      for (const {document} of overflow) transaction.delete(document.ref);
      return overflow.length;
    });
  } while (deleted === DELETE_BATCH_SIZE);
}

module.exports = {trimStudentAttempts};
