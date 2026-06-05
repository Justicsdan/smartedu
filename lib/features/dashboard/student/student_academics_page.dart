import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/providers/student/student_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../utils/pdf_download_utils.dart';

class StudentAcademicsPage extends StatefulWidget {
  const StudentAcademicsPage({super.key});

  @override
  State<StudentAcademicsPage> createState() => _StudentAcademicsPageState();
}

class _StudentAcademicsPageState extends State<StudentAcademicsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedTerm = "First Term";
  bool isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generatePdf(Map<String, Map<String, dynamic>> grades, String studentName, String className) async {
    setState(() => isGeneratingPdf = true);

    try {
      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text("STUDENT TERMLY REPORT CARD",
                        style: const pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Divider(thickness: 2),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("Name: $studentName",
                            style: const pw.TextStyle(fontSize: 14)),
                        pw.Text("Class: $className",
                            style: const pw.TextStyle(fontSize: 14)),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text("Term: $selectedTerm",
                        style: const pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 20),
                    pw.Divider(thickness: 1),
                    pw.SizedBox(height: 10),
                  ],
                ),
              ),
              pw.TableHelper.fromTextArray(
                headerStyle: const pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blue800),
                cellAlignment: pw.Alignment.center,
                data: [
                  ["Subject", "Total Score", "Grade", "Remark"],
                  ...grades.entries
                      .map((entry) => [
                            entry.key,
                            "${entry.value["total"] ?? 0}",
                            "${entry.value["grade"] ?? "-"}",
                            "${entry.value["meaning"] ?? "-"}",
                          ]),
                ],
              ),
              pw.SizedBox(height: 40),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      downloadPdfBytes(bytes, '${studentName}_results.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final myName = provider.fullName;
    final myClass = provider.className;

    final Map<String, Map<String, dynamic>> myGrades = {};
    for (final score in provider.scores) {
      final subjectName = (score['subjectName'] ?? score['subject_name'] ?? '').toString();
      final total = (score['total'] ?? 0).toDouble();
      final grade = (score['grade'] ?? '').toString();
      final isPass = total >= 40;

      myGrades[subjectName] = {
        'total': total,
        'grade': grade,
        'isCredit': isPass,
        'meaning': isPass ? 'Passed' : 'Failed',
      };
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Academics"),
        backgroundColor: const Color(0xFF1E3C72),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "My Results"),
            Tab(text: "Assignments"),
            Tab(text: "Timetable"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResultsTab(myGrades, myName, myClass),
          _buildAssignmentsTab(),
          _buildTimetableTab(),
        ],
      ),
    );
  }

  Widget _buildResultsTab(
      Map<String, Map<String, dynamic>> myGrades, String myName, String myClass) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                    child: Text("Student: $myName",
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                Expanded(
                    child: Text("Class: $myClass",
                        style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedTerm,
                  decoration: const InputDecoration(
                    labelText: "Select Term",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_month),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: ["First Term", "Second Term", "Third Term"]
                      .map((term) =>
                          DropdownMenuItem(value: term, child: Text(term)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedTerm = val!),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: myGrades.isEmpty || isGeneratingPdf
                    ? null
                    : () => _generatePdf(myGrades, myName, myClass),
                icon: isGeneratingPdf
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf),
                label: const Text("Print PDF"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          myGrades.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Icon(Icons.hourglass_empty, size: 50, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text("No results for $selectedTerm yet.",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text("Your teacher hasn't submitted scores.",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowHeight: 50,
                    dataRowHeight: 56,
                    border: TableBorder.all(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12)),
                    columns: const [
                      DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Center(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)))),
                      DataColumn(label: Center(child: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold)))),
                      DataColumn(label: Center(child: Text('Remark', style: TextStyle(fontWeight: FontWeight.bold)))),
                    ],
                    rows: myGrades.entries.map((entry) {
                      String subject = entry.key;
                      Map<String, dynamic> data = entry.value;
                      bool isCredit = data["isCredit"] ?? false;

                      return DataRow(
                        cells: [
                          DataCell(Text(subject, style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(
                            Center(
                              child: Text("${data["total"] ?? 0}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3C72))),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCredit ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isCredit ? Colors.green : Colors.red),
                                ),
                                child: Text("${data["grade"] ?? "-"}", style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? Colors.green : Colors.red)),
                              ),
                            ),
                          ),
                          DataCell(
                            Center(
                              child: Text("${data["meaning"] ?? "-"}", style: TextStyle(fontSize: 13, color: isCredit ? Colors.green.shade700 : Colors.red.shade700)),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab() {
    final assignments = [
      {"title": "Chapter 5 Exercises", "subject": "Mathematics", "due": "Friday, Nov 22", "status": "Pending"},
      {"title": "Essay Writing: My Country", "subject": "English", "due": "Next Monday", "status": "Pending"},
      {"title": "Draw the Solar System", "subject": "Basic Science", "due": "Last Wednesday", "status": "Submitted"},
      {"title": "Solve Problems 1-20", "subject": "Mathematics", "due": "Last Friday", "status": "Graded"},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignments.length,
      itemBuilder: (context, index) {
        final assign = assignments[index];
        String status = assign["status"]!;
        bool isPending = status == "Pending";
        bool isGraded = status == "Graded";
        Color statusColor = isPending ? Colors.orange : isGraded ? Colors.green : Colors.grey;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF1E3C72).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.assignment, color: Color(0xFF1E3C72), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(assign["title"]!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(assign["subject"]!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor)),
                      child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text("Due: ${assign["due"]}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                    if (isPending)
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Assignment submitted!"), backgroundColor: Colors.green));
                        },
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: const Text("Submit"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      )
                    else if (isGraded)
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Score: 85/100 - Excellent!"), backgroundColor: Color(0xFF1E3C72)));
                        },
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text("View Score"),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E3C72)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimetableTab() {
    final timetable = [
      {"time": "8:00 - 8:45", "mon": "Mathematics", "tue": "English", "wed": "Physics", "thu": "Chemistry", "fri": "Biology"},
      {"time": "8:45 - 9:30", "mon": "English", "tue": "Mathematics", "wed": "English", "thu": "Mathematics", "fri": "Physics"},
      {"time": "9:30 - 10:15", "mon": "Physics", "tue": "Chemistry", "wed": "Mathematics", "thu": "English", "fri": "English"},
      {"time": "10:15 - 10:45", "mon": "BREAK", "tue": "BREAK", "wed": "BREAK", "thu": "BREAK", "fri": "BREAK"},
      {"time": "10:45 - 11:30", "mon": "Chemistry", "tue": "Biology", "wed": "Chemistry", "thu": "Physics", "fri": "Mathematics"},
      {"time": "11:30 - 12:15", "mon": "Biology", "tue": "Physics", "wed": "Biology", "thu": "Biology", "fri": "Chemistry"},
      {"time": "12:15 - 1:00", "mon": "Computer", "tue": "Computer", "wed": "Computer", "thu": "Computer", "fri": "Computer"},
      {"time": "1:00 - 1:45", "mon": "BREAK", "tue": "BREAK", "wed": "BREAK", "thu": "BREAK", "fri": "BREAK"},
      {"time": "1:45 - 2:30", "mon": "PHE", "tue": "Arts", "wed": "PHE", "thu": "Arts", "fri": "PHE"},
    ];

    final days = ["MON", "TUE", "WED", "THU", "FRI"];
    final daysLower = ["mon", "tue", "wed", "thu", "fri"];
    final dayColors = [Colors.blue.shade50, Colors.green.shade50, Colors.orange.shade50, Colors.purple.shade50, Colors.red.shade50];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E3C72).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.calendar_today, color: Color(0xFF1E3C72)),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Class Timetable", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3C72), fontSize: 16)),
                    Text("2024/2025 Academic Session", style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF1E3C72), borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                const SizedBox(width: 90, child: Center(child: Text("TIME", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)))),
                ...days.asMap().entries.map((entry) => Expanded(
                      child: Center(child: Text(entry.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...timetable.map((row) {
            bool isBreak = row["mon"] == "BREAK";
            return Container(
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                color: isBreak ? Colors.amber.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isBreak ? Colors.amber.shade200 : Colors.grey.shade200),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: Text(row["time"]!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isBreak ? Colors.amber.shade800 : Colors.grey.shade700)),
                    ),
                  ),
                  ...days.asMap().entries.map((dayEntry) {
                    String subject = row[daysLower[dayEntry.key]]!;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        decoration: BoxDecoration(
                          color: isBreak ? Colors.transparent : dayColors[dayEntry.key],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(subject, style: TextStyle(fontSize: 11, fontWeight: isBreak ? FontWeight.bold : FontWeight.w500, color: isBreak ? Colors.amber.shade800 : const Color(0xFF1E3C72)), textAlign: TextAlign.center),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
