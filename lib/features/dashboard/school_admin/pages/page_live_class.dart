import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/school_admin_provider.dart';
import '../../../../core/services/db_proxy.dart';
import '../../../../widgets/jitsi_embed_view.dart';

class AdminLiveClassPage extends StatefulWidget {
  const AdminLiveClassPage({Key? key}) : super(key: key);

  @override
  State<AdminLiveClassPage> createState() => _AdminLiveClassPageState();
}

class _AdminLiveClassPageState extends State<AdminLiveClassPage> {
  bool _isLive = false;
  String _roomName = '';
  List<Map<String, dynamic>> _classes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    final p = context.read<SchoolAdminProvider>();
    try {
      final res = await DbProxy.instance.from('live_classes')
        .select()
        .eq('school_id', p.schoolId)
        .inFilter('status', ['scheduled', 'live'])
        .order('scheduled_at', ascending: true)
        .get();
      if (mounted) setState(() {
        _classes = res;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startAdminClass(String audience, String? classId, String? subjectId, DateTime? scheduledTime) async {
    final p = context.read<SchoolAdminProvider>();
    Navigator.pop(context);
    
    setState(() => _loading = true);
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _roomName = 'smartedu_${p.schoolId}_${audience}_$timestamp'.replaceAll('-', '');
    
    try {
      await DbProxy.instance.from('live_classes').insert({
        'school_id': p.schoolId,
        'teacher_id': '00000000-0000-0000-0000-000000000000', 
        'class_id': audience == 'class' ? classId : null,
        'subject_id': audience == 'class' ? subjectId : null,
        'audience': audience,
        'room_name': _roomName,
        'status': scheduledTime == null ? 'live' : 'scheduled',
        'started_at': scheduledTime == null ? DateTime.now().toIso8601String() : null,
        'scheduled_at': scheduledTime?.toIso8601String(),
      });
      
      if (mounted) setState(() {
        _isLive = scheduledTime == null;
        _loading = false;
      });
      _fetchClasses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start: $e')));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deleteClass(String dbId) async {
    try {
      await DbProxy.instance.from('live_classes').eq('id', dbId).delete();
      _fetchClasses();
    } catch (_) {}
  }

  Future<void> _forceEndClass(String dbId, String roomName) async {
    try {
      await DbProxy.instance.from('live_classes')
        .eq('id', dbId)
        .update({
          'status': 'ended',
          'ended_at': DateTime.now().toIso8601String(),
        });
      _fetchClasses();
    } catch (_) {}
  }

  void _showStartDialog() {
    final p = context.read<SchoolAdminProvider>();
    String selectedAudience = 'class';
    String? selectedClassId;
    String? selectedSubjectId;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Start / Schedule Live Class'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedAudience,
                        decoration: const InputDecoration(labelText: 'Audience', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'class', child: Text('Specific Class')),
                          DropdownMenuItem(value: 'students', child: Text('All Students (Assembly)')),
                          DropdownMenuItem(value: 'teachers', child: Text('All Teachers (Staff Meeting)')),
                          DropdownMenuItem(value: 'all', child: Text('Everyone (Students & Teachers)')),
                        ],
                        onChanged: (val) => setDialogState(() {
                          selectedAudience = val!;
                          selectedClassId = null;
                          selectedSubjectId = null;
                        }),
                      ),
                      const SizedBox(height: 16),
                      if (selectedAudience == 'class') ...[
                        DropdownButtonFormField<String>(
                          value: selectedClassId,
                          decoration: const InputDecoration(labelText: 'Select Class', border: OutlineInputBorder()),
                          items: p.classes.map((c) => DropdownMenuItem<String>(
                            value: c['id'] as String?, 
                            child: Text('${c['name']} ${c['section'] ?? ''}')
                          )).toList(),
                          onChanged: (val) => setDialogState(() => selectedClassId = val),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedSubjectId,
                          decoration: const InputDecoration(labelText: 'Select Subject', border: OutlineInputBorder()),
                          items: p.subjects.map((s) => DropdownMenuItem<String>(
                            value: s['id'] as String?, 
                            child: Text(s['name'] ?? 'Unknown')
                          )).toList(),
                          onChanged: (val) => setDialogState(() => selectedSubjectId = val),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text('Leave date/time empty to start LIVE NOW', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(selectedDate == null ? 'Pick Date' : DateFormat('yyyy-MM-dd').format(selectedDate!)),
                              onPressed: () async {
                                final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                                if (d != null) setDialogState(() => selectedDate = d);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.access_time),
                              label: Text(selectedTime == null ? 'Pick Time' : selectedTime!.format(context)),
                              onPressed: () async {
                                final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                if (t != null) setDialogState(() => selectedTime = t);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: (selectedAudience != 'class' || (selectedClassId != null && selectedSubjectId != null)) 
                    ? () {
                        DateTime? scheduledDateTime;
                        if (selectedDate != null && selectedTime != null) {
                          scheduledDateTime = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, selectedTime!.hour, selectedTime!.minute);
                        }
                        _startAdminClass(selectedAudience, selectedClassId, selectedSubjectId, scheduledDateTime);
                      } 
                    : null,
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  String _getMeetingTitle(Map<String, dynamic> live, SchoolAdminProvider p) {
    final audience = live['audience'] as String? ?? 'class';
    if (audience == 'all') return 'Everyone (School-Wide)';
    if (audience == 'students') return 'All Students (Assembly)';
    if (audience == 'teachers') return 'All Teachers (Staff Meeting)';
    
    String className = 'Class';
    try {
      final c = p.classes.firstWhere((c) => c['id'] == live['class_id']);
      className = '${c['name']} ${c['section'] ?? ''}';
    } catch (_) {}
    return className;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<SchoolAdminProvider>();
    
    if (_isLive) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin Live Class'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton.icon(
              onPressed: () async {
                try {
                  await DbProxy.instance.from('live_classes')
                    .eq('room_name', _roomName)
                    .update({'status': 'ended', 'ended_at': DateTime.now().toIso8601String()});
                } catch (_) {}
                setState(() => _isLive = false);
                _fetchClasses();
              },
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('End Class', style: TextStyle(color: Colors.red)),
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: JitsiEmbedView(
              roomName: _roomName,
              userDisplayName: p.schoolName,
              schoolName: p.schoolName,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Class Monitor'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () { setState(() => _loading = true); _fetchClasses(); })
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showStartDialog,
        icon: const Icon(Icons.videocam),
        label: const Text('Start / Schedule'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24),
          child: _loading 
            ? const CircularProgressIndicator()
            : _classes.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_busy, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No Classes Scheduled', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('There are no scheduled or live classes in the school right now.', textAlign: TextAlign.center),
                    ],
                  )
                : ListView.builder(
                    itemCount: _classes.length,
                    itemBuilder: (context, index) {
                      final live = _classes[index];
                      final isLive = live['status'] == 'live';
                      final schedTime = live['scheduled_at'] != null ? DateTime.parse(live['scheduled_at']) : null;
                      final dbId = live['id'] as String;
                      final title = _getMeetingTitle(live, p);

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Icon(isLive ? Icons.live_tv : Icons.event, color: isLive ? Colors.red : Colors.blue, size: 40),
                          title: Text(isLive ? '$title is Live Now' : '$title - Scheduled', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(schedTime != null ? DateFormat('EEEE, MMM d - h:mm a').format(schedTime.toLocal()) : 'Started at: ${live['started_at'] != null ? DateFormat('h:mm a').format(DateTime.parse(live['started_at']).toLocal()) : 'Unknown'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLive)
                                ElevatedButton(
                                  onPressed: () => setState(() {
                                    _roomName = live['room_name'];
                                    _isLive = true;
                                  }),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  child: const Text('Monitor'),
                                )
                              else
                                const Chip(label: Text('Upcoming')),
                              IconButton(
                                icon: Icon(isLive ? Icons.stop_circle_outlined : Icons.delete_outline, color: Colors.red),
                                tooltip: isLive ? 'Force End' : 'Delete',
                                onPressed: () => isLive ? _forceEndClass(dbId, live['room_name']) : _deleteClass(dbId),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
