import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/teacher/teacher_provider.dart';
import '../../../../core/services/db_proxy.dart';
import '../../../../widgets/jitsi_embed_view.dart';

class TeacherLiveClassPage extends StatefulWidget {
  const TeacherLiveClassPage({Key? key}) : super(key: key);

  @override
  State<TeacherLiveClassPage> createState() => _TeacherLiveClassPageState();
}

class _TeacherLiveClassPageState extends State<TeacherLiveClassPage> {
  String? _selectedClassId;
  String? _selectedSubjectId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isSaving = false;
  bool _isLive = false;
  String _roomName = '';
  
  List<Map<String, dynamic>> _myClasses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchScheduledClasses();
  }

  Future<void> _fetchScheduledClasses() async {
    final p = context.read<TeacherProvider>();
    setState(() => _loading = true);
    try {
      final res = await DbProxy.instance.from('live_classes')
        .select()
        .eq('school_id', p.schoolId)
        .inFilter('status', ['scheduled', 'live'])
        .order('scheduled_at', ascending: true)
        .get();

      final visibleClasses = res.where((live) {
        final audience = live['audience'] as String? ?? 'class';
        return audience == 'teachers' || audience == 'all' || live['teacher_id']?.toString() == p.teacherId;
      }).toList();

      if (mounted) setState(() {
        _myClasses = visibleClasses;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scheduleClass() async {
    final p = context.read<TeacherProvider>();
    if (_selectedClassId == null || _selectedSubjectId == null || _selectedDate == null || _selectedTime == null) return;
    
    setState(() => _isSaving = true);
    
    final scheduledDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _selectedTime!.hour, _selectedTime!.minute,
    );

    final timestamp = scheduledDateTime.millisecondsSinceEpoch;
    _roomName = 'smartedu_${p.schoolId}_class_$_selectedClassId$_selectedSubjectId$timestamp'.replaceAll('-', '');
    
    try {
      await DbProxy.instance.from('live_classes').insert({
        'school_id': p.schoolId,
        'teacher_id': p.teacherId,
        'class_id': _selectedClassId,
        'subject_id': _selectedSubjectId,
        'audience': 'class',
        'room_name': _roomName,
        'status': 'scheduled',
        'scheduled_at': scheduledDateTime.toIso8601String(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class scheduled successfully!'), backgroundColor: Colors.green));
      
      setState(() {
        _isSaving = false;
        _selectedClassId = null;
        _selectedSubjectId = null;
        _selectedDate = null;
        _selectedTime = null;
      });
      _fetchScheduledClasses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to schedule: $e')));
      setState(() => _isSaving = false);
    }
  }

  Future<void> _startScheduledClass(String roomId, String dbId) async {
    try {
      await DbProxy.instance.from('live_classes')
        .eq('id', dbId)
        .update({
          'status': 'live',
          'started_at': DateTime.now().toIso8601String(),
        });
    } catch (_) {}
    _joinClass(roomId);
    _fetchScheduledClasses();
  }

  void _joinClass(String roomId) {
    setState(() {
      _isLive = true;
      _roomName = roomId;
    });
  }

  void _leaveLiveClass() {
    setState(() => _isLive = false);
    _fetchScheduledClasses();
  }

  Future<void> _endLiveClass(String dbId) async {
    try {
      await DbProxy.instance.from('live_classes')
        .eq('id', dbId)
        .update({
          'status': 'ended',
          'ended_at': DateTime.now().toIso8601String(),
        });
    } catch (_) {}
    _fetchScheduledClasses();
  }

  Future<void> _deleteScheduledClass(String dbId) async {
    try {
      await DbProxy.instance.from('live_classes').eq('id', dbId).delete();
      _fetchScheduledClasses();
    } catch (_) {}
  }

  String _getSubjectName(TeacherProvider p, String? subjectId) {
    if (subjectId == null) return 'Staff Meeting';
    try {
      final subj = p.mySubjectAssignments.firstWhere((s) => s['subject_id']?.toString() == subjectId);
      return subj['subjects']?['name'] ?? 'Subject';
    } catch (_) {
      return 'Subject';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<TeacherProvider>();
    
    if (_isLive) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Class In Session'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton.icon(
              onPressed: _leaveLiveClass,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Leave Room', style: TextStyle(color: Colors.red)),
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: JitsiEmbedView(
              roomName: _roomName,
              userDisplayName: p.teacherName,
              schoolName: p.schoolName,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Live Classes')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Schedule a Live Class', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: _selectedClassId,
                      decoration: const InputDecoration(labelText: 'Select Class', border: OutlineInputBorder()),
                      items: p.myClasses.map((c) => DropdownMenuItem<String>(
                        value: c['id'] as String?, 
                        child: Text('${c['name']} ${c['section'] ?? ''}')
                      )).toList(),
                      onChanged: (val) => setState(() {
                        _selectedClassId = val;
                        _selectedSubjectId = null;
                      }),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSubjectId,
                      decoration: const InputDecoration(labelText: 'Select Subject', border: OutlineInputBorder()),
                      items: p.mySubjectAssignments.where((s) => s['class_id']?.toString() == _selectedClassId).map((s) {
                        final subjName = s['subjects']?['name'] ?? 'Subject';
                        return DropdownMenuItem<String>(
                          value: s['subject_id'] as String?, 
                          child: Text(subjName)
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedSubjectId = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_selectedDate == null ? 'Pick Date' : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
                            onPressed: () async {
                              final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                              if (d != null) setState(() => _selectedDate = d);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(_selectedTime == null ? 'Pick Time' : _selectedTime!.format(context)),
                            onPressed: () async {
                              final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                              if (t != null) setState(() => _selectedTime = t);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: (_selectedClassId != null && _selectedSubjectId != null && _selectedDate != null && _selectedTime != null && !_isSaving) 
                        ? _scheduleClass 
                        : null,
                      icon: _isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.schedule_send),
                      label: Text(_isSaving ? 'Scheduling...' : 'Schedule Class'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Upcoming & Active Classes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _loading 
                      ? const Center(child: CircularProgressIndicator())
                      : _myClasses.isEmpty
                          ? const Center(child: Text('No classes scheduled.'))
                          : ListView.builder(
                              itemCount: _myClasses.length,
                              itemBuilder: (context, index) {
                                final live = _myClasses[index];
                                final isLive = live['status'] == 'live';
                                final schedTime = live['scheduled_at'] != null ? DateTime.parse(live['scheduled_at']) : null;
                                final audience = live['audience'] as String? ?? 'class';
                                final isOwner = live['teacher_id']?.toString() == p.teacherId;
                                final dbId = live['id'] as String;
                                
                                String title = _getSubjectName(p, live['subject_id']?.toString());
                                if (audience == 'teachers') title = 'Staff Meeting';
                                if (audience == 'all') title = 'School-Wide Meeting';

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(schedTime != null ? DateFormat('MMM d, y - h:mm a').format(schedTime.toLocal()) : 'No time set'),
                                    trailing: isLive
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () => _joinClass(live['room_name']),
                                              icon: const Icon(Icons.videocam),
                                              label: const Text('Join Live'),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                            ),
                                            if (isOwner)
                                              IconButton(
                                                icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                                                tooltip: 'End Class',
                                                onPressed: () => _endLiveClass(dbId),
                                              ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isOwner) ...[
                                              IconButton(
                                                icon: const Icon(Icons.play_arrow, color: Colors.green),
                                                tooltip: 'Start Class',
                                                onPressed: () => _startScheduledClass(live['room_name'], dbId),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                tooltip: 'Delete Class',
                                                onPressed: () => _deleteScheduledClass(dbId),
                                              ),
                                            ] else 
                                              const Chip(label: Text('Upcoming')),
                                          ],
                                        ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
