import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartedu/core/teacher_provider.dart';

class TeacherAnnouncementsPage extends StatefulWidget {
  const TeacherAnnouncementsPage({super.key});
  @override
  State<TeacherAnnouncementsPage> createState() =>
      _TeacherAnnouncementsPageState();
}

class _TeacherAnnouncementsPageState
    extends State<TeacherAnnouncementsPage> {
  final _titleController = TextEditingController();
  final _msgController = TextEditingController();
  String? _selectedClassId;
  List<Map<String, String>> _announcements = [
    {
      "title": "Mid-term Test",
      "msg":
          "Please note that the mid-term test starts next week Tuesday.",
      "time": "2 hours ago",
      "class": "JSS 1A",
    },
  ];

  List<Map<String, dynamic>> _getClasses(TeacherProvider p) {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];
    for (final a in p.mySubjectAssignments) {
      final c = a['classes'];
      if (c is Map<String, dynamic> &&
          c['id'] != null &&
          !seen.contains(c['id'])) {
        seen.add(c['id'] as String);
        out.add(c);
      }
    }
    final ft = p.getFormTeacherClass();
    if (ft != null && ft['id'] != null && !seen.contains(ft['id'])) {
      seen.add(ft['id'] as String);
      out.add(ft);
    }
    return out;
  }

  String _cl(Map<String, dynamic> c) =>
      '${c['name'] ?? ''} ${c['section'] ?? ''}'.trim();

  void _post() {
    if (_msgController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a message'),
        backgroundColor: Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final p = context.read<TeacherProvider>();
    final cls = _getClasses(p);
    String target = 'All Classes';
    if (_selectedClassId != null) {
      final found = cls.firstWhere(
        (c) => c['id'] == _selectedClassId,
        orElse: () => {},
      );
      final lbl = _cl(found);
      if (lbl.isNotEmpty) target = lbl;
    }
    setState(() {
      _announcements.insert(0, {
        "title": _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : "General Announcement",
        "msg": _msgController.text.trim(),
        "time": "Just now",
        "class": target,
      });
    });
    _titleController.clear();
    _msgController.clear();
    setState(() => _selectedClassId = null);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Announcement sent successfully!'),
      backgroundColor: Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      shape: StadiumBorder(),
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TeacherProvider>();
    final cls = _getClasses(p);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Announcements',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Post and view announcements for your classes',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        size: 18,
                        color: Color(0xFFF57F17),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'New Announcement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (cls.length > 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedClassId != null
                            ? const Color(0xFFF57F17)
                            : const Color(0xFFE8EAED),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedClassId,
                        hint: const Text(
                          'Send to all classes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'All Classes',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          ...cls.map((c) => DropdownMenuItem<String?>(
                                value: c['id'] as String?,
                                child: Text(
                                  _cl(c),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              )),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedClassId = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title (optional)',
                    labelStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                    hintText: 'e.g., Exam Date',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFBFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE8EAED)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE8EAED)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFF57F17)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _msgController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    labelStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                    hintText: 'Type your announcement...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFBFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE8EAED)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE8EAED)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFF57F17)),
                    ),
                    alignLabelWithHint: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A237E),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _post,
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.send_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Send to Class',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Previous Announcements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_announcements.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_announcements.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.campaign_outlined,
                        size: 32,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No announcements yet',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Post your first announcement above.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_announcements.length, (i) {
              final a = _announcements[i];
              final isNew = i == 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isNew
                      ? const Color(0xFFFFF8E1)
                      : const Color(0xFFFAFBFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isNew
                        ? const Color(0xFFFFE082)
                        : const Color(0xFFE8EAED),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF57F17)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF57F17),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            a["title"]!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Color(0xFF111827),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          a["time"]!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a["msg"]!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF555555),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.class_outlined,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          a["class"] ?? 'All Classes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
