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
  pw.Widget learningProgress() {
    const widths = <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(5),
      1: pw.FlexColumnWidth(.85),
      2: pw.FlexColumnWidth(.85),
      3: pw.FlexColumnWidth(.85),
      4: pw.FlexColumnWidth(1),
      5: pw.FlexColumnWidth(1.4),
    };
    final lineColor = PdfColor.fromHex('#A76529');
    final border = pw.TableBorder.all(color: lineColor, width: .5);
    pw.Widget cell(String text, {bool left = false, double height = 16}) =>
        pw.Container(
          height: height,
          alignment: left ? pw.Alignment.centerLeft : pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6),
          child: pw.Text(text, style: pw.TextStyle(fontSize: 9, color: brown)),
        );
    return pw.Center(
      child: pw.Container(
        width: 475,
        padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: pw.Column(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              child: pw.Text(
                'REPORT ON LEARNING PROGRESS AND ACHIEVEMENT',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: brown,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: border,
              columnWidths: const {
                0: pw.FlexColumnWidth(5),
                1: pw.FlexColumnWidth(2.55),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F4C578'),
                  ),
                  children: [
                    cell('Learning Areas', height: 30),
                    pw.Column(
                      children: [
                        cell('Term', height: 15),
                        pw.Table(
                          defaultColumnWidth: const pw.FlexColumnWidth(),
                          border: pw.TableBorder(
                            top: pw.BorderSide(color: lineColor, width: .5),
                            verticalInside: pw.BorderSide(
                              color: lineColor,
                              width: .5,
                            ),
                          ),
                          children: [
                            pw.TableRow(
                              children: [
                                for (var term = 1; term <= 3; term++)
                                  cell('$term', height: 15),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    cell('Final\nGrade', height: 30),
                    cell('Remarks', height: 30),
                  ],
                ),
              ],
            ),
            pw.Table(
              border: border,
              columnWidths: widths,
              children: [
                for (final row in report.gradeRows)
                  pw.TableRow(
                    children: [
                      for (var i = 0; i < row.length; i++)
                        cell(row[i] == '-' ? '' : row[i], left: i == 0),
                    ],
                  ),
                // Preserve the reference form's unused writing rows.
                for (var row = report.gradeRows.length; row < 13; row++)
                  pw.TableRow(
                    children: [
                      for (var column = 0; column < 6; column++) cell(''),
                    ],
                  ),
              ],
            ),
            pw.Table(
              border: border,
              columnWidths: const {
                0: pw.FlexColumnWidth(7.55),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  children: [
                    cell('General Average'),
                    cell(
                      report.generalAverage == null
                          ? ''
                          : ProfileReport.number(report.generalAverage),
                    ),
                    cell(''),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
    learningProgress(),
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
