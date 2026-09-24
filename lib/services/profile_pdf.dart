import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/profile_report.dart';

/// Three scene-inspired sections, with automatic continuation pages for long lists.
Future<Uint8List> buildProfilePdf(ProfileReport report) async {
  final board = pw.MemoryImage(
    (await rootBundle.load(
      'assets/images/profile_board.png',
    )).buffer.asUint8List(),
  );
  final logo = pw.MemoryImage(
    (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
  );
  final regular = pw.Font.ttf(
    await rootBundle.load('assets/fonts/LiberationSans.ttf'),
  );
  final bold = pw.Font.ttf(
    await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
  );
  final brown = PdfColor.fromHex('#781500');
  final document = pw.Document(
    title: '${report.student.name} - Student Profile',
    author: 'LearnAble',
  );
  final year = report.year.isEmpty
      ? 'School year not assigned'
      : 'School Year ${report.year}';
  pw.Widget table(
    List<String> headers,
    List<List<String>> rows,
  ) => pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    border: pw.TableBorder.all(color: PdfColor.fromHex('#C78C43'), width: .5),
    headerStyle: pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
      fontSize: 10,
    ),
    headerDecoration: pw.BoxDecoration(color: brown),
    cellStyle: pw.TextStyle(fontSize: 10, color: brown),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 10),
    rowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFE8B5)),
    oddRowDecoration: const pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFFFF2D6),
    ),
    cellAlignments: {0: pw.Alignment.centerLeft},
    cellAlignment: pw.Alignment.center,
    columnWidths: {
      for (var i = 0; i < headers.length; i++)
        i: pw.FlexColumnWidth(
          i == 0
              ? 2.5
              : headers[i] == 'Remarks'
              ? 1.7
              : 1,
        ),
    },
  );
  void section(String title, List<pw.Widget> content) {
    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(42),
          buildBackground: (_) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Image(board, fit: pw.BoxFit.fill),
          ),
          theme: pw.ThemeData.withFont(base: regular, bold: bold),
        ),
        maxPages: 1000,
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(logo, width: 65, height: 45),
                pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 24,
                    color: brown,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'STUDENT PROFILE',
                  style: pw.TextStyle(fontSize: 9, color: brown),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              report.student.name.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 18,
                color: brown,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              '${report.student.id}  |  ${report.student.enrollments[report.year] ?? ''}  |  $year',
              style: pw.TextStyle(fontSize: 11, color: brown),
            ),
            if (report.hasCurrentGrades &&
                '${report.student.data['section'] ?? ''}'.trim().isNotEmpty)
              pw.Text(
                'Section: ${report.student.data['section']}',
                style: pw.TextStyle(fontSize: 10, color: brown),
              ),
            pw.SizedBox(height: 16),
          ],
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'LearnAble  /  $title',
                style: pw.TextStyle(fontSize: 9, color: brown),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(fontSize: 9, color: brown),
              ),
            ],
          ),
        ),
        build: (_) => content,
      ),
    );
  }

  pw.Widget note(String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 12),
    child: pw.Text(value, style: pw.TextStyle(fontSize: 11, color: brown)),
  );
  section('Profile', [
    if (report.summaryRows.isEmpty)
      note('No activities recorded for this school year.')
    else
      table([
        'Activity',
        'Level',
        'Attempts',
        'Time used',
        'Highest score',
        'Lowest score',
      ], report.summaryRows),
    if (report.unassignedActivities.isNotEmpty) ...[
      note(
        'Activities without a school year - all-time game history, not attributed to this batch.',
      ),
      table([
        'Activity',
        'Level',
        'Attempts',
        'Time used',
        'Highest score',
        'Lowest score',
      ], report.unassignedSummaryRows),
    ],
  ]);
  section('Recent Activity', [
    if (report.activities.isEmpty)
      note('No recent activities recorded for this school year.')
    else
      table([
        'Activity',
        'Level',
      ], report.activities.map((a) => [a.activityName, a.level]).toList()),
    if (report.unassignedActivities.isNotEmpty) ...[
      note(
        'Activities without a school year - most recent first; not attributed to this batch.',
      ),
      table(
        ['Activity', 'Level'],
        report.unassignedActivities
            .map((a) => [a.activityName, a.level])
            .toList(),
      ),
    ],
  ]);
  section('Grades', [
    if (!report.hasCurrentGrades)
      note(
        'Historical quarterly grades were not saved for this school year. Current grades are not included.',
      ),
    table([
      'Subject',
      '1st',
      '2nd',
      '3rd',
      '4th',
      'Final Grade',
      'Remarks',
    ], report.gradeRows),
    note('General Average: ${ProfileReport.number(report.generalAverage)}'),
    note("Teacher's Remark:"),
    // Bound each block so long remarks can continue on subsequent pages.
    ...((report.teacherRemark.isEmpty
            ? 'No remark recorded.'
            : report.teacherRemark)
        .split('\n')
        .expand(
          (line) => [
            for (var start = 0; start < line.length; start += 600)
              line.substring(
                start,
                start + 600 < line.length ? start + 600 : line.length,
              ),
          ],
        )
        .map((line) => note(line))),
  ]);
  return document.save();
}
