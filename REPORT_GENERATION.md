# Report Generation

Open the admin menu and select **Report Generation**, below Registered Accounts.
Select a saved school-year batch, search by student name or ID, then select
**Print Profile**. The PDF preview provides print and download actions.

The PDF reproduces the wooden board, colors, and information from Unity's
ProfilePanel, RecentActivityPanel, and GradesPanel. All implementation changes
are in this Flutter project; Unity assets were only copied as references.

## Local review

Sample data, without signing in or connecting to Firebase:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8779 -t tool/report_preview.dart
```

Real accounts, using the normal admin sign-in:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8778
```

These commands run locally and do not deploy. The sample preview deliberately
disables navigation into live account screens.

## Data behavior

- Batch membership comes from saved student enrollment years and archived
  enrollment summaries. Only existing student accounts are listed.
- Students without recorded enrollment years have a separate unassigned option.
- Activity records explicitly tagged with a school year appear in that batch.
  Untagged Unity activity history appears separately, marked as unassigned,
  without attributing it to a particular school year.
- Quarterly grades and teacher remarks use the same fields and calculations as
  Unity. Missing grades are not counted as zero. Current grades are not reused
  for older school years because historical quarterly snapshots are not stored.
- Reports only read Firebase data. They do not change enrollment or grades.
- Long tables continue over extra pages; fonts are bundled for accented names.

## Checks

```powershell
flutter test
flutter build web --output build/report-review-live
```

PDF tests generate sample files in the ignored `tmp/pdfs/` folder for visual QA.
