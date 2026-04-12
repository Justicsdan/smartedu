import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageSubjectsPage extends StatefulWidget {
  final int? schoolId;
  final String? schoolName;
  const ManageSubjectsPage({super.key, this.schoolId, this.schoolName});

  @override
  State<ManageSubjectsPage> createState() => _ManageSubjectsPageState();
}

class _ManageSubjectsPageState extends State<ManageSubjectsPage> {
  final _subjectController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('subjects')
          .select()
          .eq('school_id', widget.schoolId.toString());
      setState(() {
        _subjects = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching subjects: $e')),
        );
      }
    }
  }

  Future<void> _addSubject() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      final exists = await Supabase.instance.client
          .from('subjects')
          .select()
          .eq('school_id', widget.schoolId.toString())
          .eq('name', _subjectController.text.trim())
          .maybeSingle();
      
      if (exists != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subject already exists!')),
          );
        }
        return;
      }

      await Supabase.instance.client.from('subjects').insert({
        'name': _subjectController.text.trim(),
        'school_id': widget.schoolId,
      });

      _subjectController.clear();
      _fetchSubjects();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding subject: $e')),
        );
      }
    }
  }

  Future<void> _deleteSubject(String id) async {
    try {
      await Supabase.instance.client.from('subjects').delete().eq('id', id);
      _fetchSubjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subject deleted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting subject: $e')),
        );
      }
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Subject'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Subject Name',
              border: OutlineInputBorder(),
            ),
            validator: (val) => val!.isEmpty ? 'Please enter subject name' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addSubject();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3C72)),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schoolName != null ? 'Subjects - ${widget.schoolName}' : 'Manage Subjects', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E3C72),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddDialog,
            tooltip: 'Add Subject',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.menu_book, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No subjects found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showAddDialog,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3C72)),
                        child: const Text('Add Subject', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E3C72),
                          child: Text(
                            subject['name']?.toString().substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(subject['name'] ?? 'Unknown'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSubject(subject['id'].toString()),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF1E3C72),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
