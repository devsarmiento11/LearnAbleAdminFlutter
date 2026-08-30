# LearnAble Admin Final

This is the active admin application for `LearnAbleGame`. The older
`learnable_admin` and `LearnAbleAdmin` applications are no longer required at
runtime.

The app connects to Firebase project `learnable-fb251`, shared with Unity:

- `users` — student and teacher accounts used by the game's ID + username login
- `activityScores` — activity results written by Unity and read by this dashboard
- `adminSettings/schoolYear` — active school year
- `archivedStudents` — year-end student summaries
- `studentPerformance` — optional saved performance snapshots

Run the app with `flutter pub get` followed by `flutter run`.

The migration retains the old temporary admin credentials (`admin` /
`admin123`). This is not secure server-side authentication. Before publishing
the app, enable Firebase Authentication for administrators and restrict
Firestore security rules to authenticated admins. Student/teacher passwords are
not written to Firestore; the current Unity game authenticates those profiles
using their generated ID and game username.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
