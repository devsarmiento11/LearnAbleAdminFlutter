// The same validation is used for review and commit; all selected profiles are
// committed together so a failed request cannot leave a half-promoted group.
function createPromotionHandler({db, FieldValue, HttpsError, requireAdmin}) {
  const validYear = (year) => typeof year === 'string' &&
    /^(\d{4})-(\d{4})$/.test(year) && Number(year.slice(5)) === Number(year.slice(0, 4)) + 1;
  return async (request) => {
    await requireAdmin(request);
    const {sourceYear, targetYear, students, operation} = request.data || {};
    if (!validYear(sourceYear) || !['preview', 'promote'].includes(operation)) {
      throw new HttpsError('invalid-argument', 'Choose an archived school year.');
    }
    if (operation === 'promote' && (!validYear(targetYear) ||
      !Array.isArray(students) || students.length < 1 || students.length > 200 ||
      students.some((s) => !s || typeof s.id !== 'string' || !s.id || s.id.includes('/') ||
        typeof s.grade !== 'string') || new Set(students.map((s) => s.id)).size !== students.length)) {
      throw new HttpsError('invalid-argument', 'Select between 1 and 200 distinct students.');
    }

    return db.runTransaction(async (transaction) => {
      const settings = (await transaction.get(db.collection('adminSettings').doc('schoolYear'))).data() || {};
      const source = await transaction.get(db.collection('archivedStudents').where('schoolYear', '==', sourceYear));
      const reopened = settings.unarchivedSchoolYears || [];
      const activeYear = settings.currentSchoolYear;
      const sourceIds = new Set(source.docs.map((doc) => doc.data().studentId).filter((id) =>
        typeof id === 'string' && id && !id.includes('/')));
      let issue = '';
      if (reopened.includes(sourceYear) || (!source.docs.length && !(settings.archivedSchoolYears || []).includes(sourceYear))) {
        issue = 'This school year is no longer archived. Refresh the archived students list.';
      } else if (!validYear(activeYear)) {
        issue = 'Set an active school year on the Dashboard before promoting students.';
      } else {
        const activeArchive = await transaction.get(db.collection('archivedStudents').where('schoolYear', '==', activeYear).limit(1));
        if (!reopened.includes(activeYear) &&
          ((settings.archivedSchoolYears || []).includes(activeYear) || activeArchive.docs.length)) {
          issue = 'Set an active school year on the Dashboard before promoting students.';
        } else if (activeYear <= sourceYear) {
          issue = 'The active school year must be later than the archived school year.';
        }
      }
      if (operation === 'promote' && (issue || activeYear !== targetYear)) {
        throw new HttpsError('failed-precondition', issue || 'The active school year changed. Review your selection again.');
      }
      if (issue) return {activeYear: null, issue, candidates: []};

      const ids = operation === 'promote' ? students.map((s) => s.id) : [...sourceIds];
      if (ids.some((id) => !sourceIds.has(id))) {
        throw new HttpsError('failed-precondition', 'A selected student is no longer in this archive. Refresh and try again.');
      }
      const profiles = ids.length ? await transaction.getAll(...ids.map((id) => db.collection('users').doc(id))) : [];
      const candidates = profiles.map((doc) => {
        const profile = doc.data() || {};
        const grade = typeof profile.grade === 'string' ? profile.grade.trim() : '';
        const match = /^Grade\s+(\d+)$/i.exec(grade);
        const nextGrade = match && Number(match[1]) > 0 && Number(match[1]) < 99 ? `Grade ${Number(match[1]) + 1}` : null;
        const enrolled = profile.schoolYear === activeYear ||
          (Array.isArray(profile.enrolledSchoolYears) && profile.enrolledSchoolYears.includes(activeYear));
        const reason = !doc.exists || profile.role !== 'student' ? 'Student account is unavailable.' :
          enrolled ? `Already enrolled in ${activeYear}` :
          validYear(profile.schoolYear) && profile.schoolYear > activeYear ? 'Student is enrolled in a later school year.' :
          !nextGrade ? 'Update this student’s grade before promoting.' : '';
        return {id: doc.id, grade, nextGrade, enrolled, reason};
      });
      if (operation === 'preview') return {activeYear, issue: '', candidates};

      for (const candidate of candidates) {
        if (candidate.reason) throw new HttpsError('failed-precondition', `${candidate.id}: ${candidate.reason}`);
        if (students.find((s) => s.id === candidate.id).grade !== candidate.grade) {
          throw new HttpsError('failed-precondition', `${candidate.id}: The current grade changed. Review your selection again.`);
        }
      }
      for (const candidate of candidates) {
        transaction.update(db.collection('users').doc(candidate.id), {
          grade: candidate.nextGrade,
          schoolYear: activeYear,
          status: 'Active',
          enrolledSchoolYears: FieldValue.arrayUnion(activeYear),
          [`promotions.${activeYear}`]: {
            sourceYear, previousGrade: candidate.grade, grade: candidate.nextGrade,
            promotedAt: FieldValue.serverTimestamp(), promotedBy: request.auth.uid,
          },
          updatedAt: FieldValue.serverTimestamp(),
        });
      }
      return {activeYear, promotedIds: ids};
    });
  };
}

module.exports = {createPromotionHandler};
