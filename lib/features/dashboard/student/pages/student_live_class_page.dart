import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/student/student_provider.dart';
import '../../../../core/services/db_proxy.dart';
import '../../../../widgets/jitsi_embed_view.dart';

class StudentLiveClassPage extends StatefulWidget {
  const StudentLiveClassPage({Key? key}) : super(key: key);

  @override
  State<StudentLiveClassPage> createState() => _StudentLiveClassPageState();
}

class _StudentLiveClassPageState extends State<StudentLiveClassPage> {
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
    final p = context.read<StudentProvider>();
    final classId = p.classId;
    
    try {
      final res = await DbProxy.instance.from('live_classes')
        .select()
        .eq('class_id', classId)
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

  @override
  Widget build(BuildContext context) {
    final p = context.read<StudentProvider>();
    
    if (_isLive) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Class'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton.icon(
              onPressed: () => setState(() => _isLive = false),
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('Leave Class', style: TextStyle(color: Colors.red)),
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: JitsiEmbedView(
              roomName: _roomName,
              userDisplayName: p.studentName,
              schoolName: p.schoolName,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live & Scheduled Classes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () { setState(() => _loading = true); _fetchClasses(); })
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
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
                      const Text('Your teachers have not scheduled any live classes yet.', textAlign: TextAlign.center),
                    ],
                  )
                : ListView.builder(
                    itemCount: _classes.length,
                    itemBuilder: (context, index) {
                      final live = _classes[index];
                      final isLive = live['status'] == 'live';
                      final schedTime = live['scheduled_at'] != null ? DateTime.parse(live['scheduled_at']) : null;
                      
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Icon(isLive ? Icons.live_tv : Icons.event, color: isLive ? Colors.red : Colors.blue, size: 40),
                          title: Text(isLive ? 'Live Now!' : 'Scheduled Class', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(schedTime != null ? DateFormat('EEEE, MMM d - h:mm a').format(schedTime.toLocal()) : ''),
                          trailing: isLive
                            ? ElevatedButton(
                                onPressed: () => setState(() {
                                  _roomName = live['room_name'];
                                  _isLive = true;
                                }),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Join'),
                              )
                            : const Chip(label: Text('Upcoming')),
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
