import 'package:flutter/material.dart';

class PageCbt extends StatelessWidget {
  final List<Map<String, dynamic>> exams, classes, subjects;
  final void Function(Map<String, dynamic>) onAdd;
  final void Function(String) onToggle;
  final void Function(String) onDelete;

  const PageCbt({super.key, required this.exams, required this.classes, required this.subjects, required this.onAdd, required this.onToggle, required this.onDelete});

  void _showAddDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    String? classId, subjectId;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setSt) => AlertDialog(title: const Text("Create CBT Exam"), content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Exam Title", border: OutlineInputBorder())),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(value: classId, decoration: const InputDecoration(labelText: "Class", border: OutlineInputBorder()), items: classes.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text("${c['name']} - ${c['section']}"))).toList(), onChanged: (v) => setSt(() => classId = v)),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: subjectId, decoration: const InputDecoration(labelText: "Subject", border: OutlineInputBorder()), items: subjects.map((s) => DropdownMenuItem(value: s['id'].toString(), child: Text(s['name']))).toList(), onChanged: (v) => setSt(() => subjectId = v)),
    ]), actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
      ElevatedButton(onPressed: () {
        if (titleCtrl.text.isNotEmpty && classId != null && subjectId != null) {
          onAdd({'id': DateTime.now().millisecondsSinceEpoch.toString(), 'title': titleCtrl.text.trim(), 'classId': classId, 'subjectId': subjectId, 'isActive': false});
          Navigator.pop(ctx);
        }
      }, child: const Text("Create")),
    ])));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      if (exams.isEmpty)
        const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.quiz_outlined, size: 80, color: Colors.grey), SizedBox(height: 16), Text("No CBT exams created yet", style: TextStyle(fontSize: 16, color: Colors.grey))]))
      else
        ListView.builder(padding: const EdgeInsets.all(24), itemCount: exams.length, itemBuilder: (context, index) {
          final e = exams[index];
          final isActive = e['isActive'] == true;
          return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)), child: Row(children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isActive ? Colors.green.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.quiz, color: isActive ? Colors.green : Colors.grey)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e['title'] ?? 'CBT Exam', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B2A4A))), Text("Class: ${e['classId']} • Subject: ${e['subjectId']}", style: const TextStyle(fontSize: 12, color: Colors.grey))])),
            GestureDetector(onTap: () => onToggle(e['id']), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: isActive ? Colors.green : Colors.red.shade100, borderRadius: BorderRadius.circular(20)), child: Text(isActive ? "Active" : "Inactive", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.red)))),
            const SizedBox(width: 12),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: () => onDelete(e['id'])),
          ]));
        }),
      Positioned(bottom: 30, right: 30, child: FloatingActionButton.extended(onPressed: () => _showAddDialog(context), backgroundColor: const Color(0xFF1A237E), icon: const Icon(Icons.add, color: Colors.white), label: const Text("Create CBT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
    ]);
  }
}
