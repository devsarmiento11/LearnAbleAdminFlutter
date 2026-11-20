const gradeKeys = ['ENGLISH', 'MATH', 'SCIENCE'].flatMap(
    subject => ['1ST', '2ND', '3RD'].map(quarter => subject + '_' + quarter));

function createAcademicPromotionHandler({db, FieldValue, HttpsError}) {
  return async request => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in as a teacher first.');
    const validId = value => typeof value === 'string' && value.trim() === value &&
      value.length > 0 && value !== '.' && value !== '..' && !value.includes('/');
    const teacherId = request.auth.token.name;
    const {studentId, expectedGrade} = request.data || {};
    if (!validId(teacherId)) throw new HttpsError('permission-denied', 'A verified teacher is required.');
    if (!validId(studentId) || !Number.isInteger(expectedGrade) || expectedGrade < 1 || expectedGrade > 5) {
      throw new HttpsError('invalid-argument', 'Select a student in Grades 1 to 5.');
    }

    const users = db.collection('users');
    const student = users.doc(studentId);
    const scores = db.collection('activityScores');
    return db.runTransaction(async tx => {
      const [teacherSnapshot, studentSnapshot] = await tx.getAll(users.doc(teacherId), student);
      const teacher = teacherSnapshot.data();
      if (teacher?.role !== 'teacher' || teacher.authUid !== request.auth.uid) {
        throw new HttpsError('permission-denied', 'A verified teacher is required.');
      }
      const profile = studentSnapshot.data();
      if (profile?.role !== 'student' || profile.status !== 'Active') {
        throw new HttpsError('failed-precondition', 'The student account must be active.');
      }
      const level = Number(/^(?:Grade\s*)?([1-6])$/i.exec(String(profile.grade).trim())?.[1]);
      const year = profile.schoolYear ?? '';
      const nextGrade = 'Grade ' + (expectedGrade + 1);
      if (level === expectedGrade + 1 && profile.academicPromotionSchoolYear === year &&
          profile.academicGrades === undefined) return {studentId, grade: nextGrade};
      if (level !== expectedGrade || profile.academicPromotionSchoolYear === year) {
        throw new HttpsError('failed-precondition', 'This grade level changed or was already promoted this school year.');
      }
      const grades = gradeKeys.map(key => profile.academicGrades?.[key]);
      if (!grades.every(value => Number.isInteger(value) && value >= 0 && value <= 100) ||
          grades.reduce((sum, value) => sum + value, 0) < 75 * gradeKeys.length) {
        throw new HttpsError('failed-precondition', 'All nine grades and a general average of at least 75 are required.');
      }

      const [activity, legacyActivity, performance] = await Promise.all([
        tx.get(scores.where('userId', '==', studentId)),
        tx.get(scores.where('studentId', '==', studentId)),
        tx.get(db.collection('studentPerformance').where('studentId', '==', studentId)),
      ]);
      const records = new Map();
      for (const doc of [...activity.docs, ...performance.docs]) records.set(doc.ref.path, doc.ref);
      for (const doc of legacyActivity.docs) {
        if (doc.data().userId == null) records.set(doc.ref.path, doc.ref);
      }
      for (const ref of records.values()) tx.delete(ref);
      tx.delete(db.collection('leaderboardStarts').doc(studentId));
      tx.update(student, {
        grade: nextGrade,
        academicPromotionSchoolYear: year,
        academicGrades: FieldValue.delete(),
        teacherRemark: FieldValue.delete(),
        gradesUpdatedAt: FieldValue.delete(),
        gradesUpdatedBy: FieldValue.delete(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return {studentId, grade: nextGrade};
    });
  };
}

module.exports = {createAcademicPromotionHandler};
