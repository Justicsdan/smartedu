import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatBotWidget extends StatefulWidget {
  final String role;
  final String apiKey;
  final Map<String, dynamic> schoolContext;

  const ChatBotWidget({
    super.key,
    required this.role,
    this.apiKey = '',
    this.schoolContext = const {},
  });

  @override
  State<ChatBotWidget> createState() => _ChatBotWidgetState();
}

class _ChatBotWidgetState extends State<ChatBotWidget> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, String>> _chatHistory = [];
  bool _isLoading = false;
  bool _isKeyMissing = false;

  late final GenerativeModel? _model;

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  String _buildContextBlock() {
    final ctx = widget.schoolContext;
    if (ctx.isEmpty) return '';

    final schoolName = ctx['schoolName']?.toString() ?? 'the school';
    final session = ctx['currentSession']?.toString() ?? 'N/A';
    final term = ctx['currentTerm']?.toString() ?? 'N/A';
    final studentCount = ctx['studentCount']?.toString() ?? '0';
    final teacherCount = ctx['teacherCount']?.toString() ?? '0';
    final classCount = ctx['classCount']?.toString() ?? '0';
    final subjectCount = ctx['subjectCount']?.toString() ?? '0';
    final gradingStandard = ctx['gradingStandard']?.toString() ?? 'Nigerian';
    final classList = (ctx['classList'] as List?) ?? [];

    final buffer = StringBuffer();
    buffer.writeln('SCHOOL DATA CONTEXT:');
    buffer.writeln('- School Name: $schoolName');
    buffer.writeln('- Current Session: $session');
    buffer.writeln('- Current Term: $term');
    buffer.writeln('- Total Students: $studentCount');
    buffer.writeln('- Total Teachers: $teacherCount');
    buffer.writeln('- Total Classes: $classCount');
    buffer.writeln('- Total Subjects: $subjectCount');
    buffer.writeln('- Grading Standard: $gradingStandard');

    if (classList.isNotEmpty) {
      buffer.writeln('- Classes breakdown:');
      for (final c in classList) {
        final name = c['name'] as String? ?? '?';
        final count = c['student_count'] as int? ?? 0;
        final tier = c['tier'] as String? ?? '';
        buffer.writeln('  * $name${tier.isNotEmpty ? ' ($tier)' : ''}: $count students');
      }
    }

    return buffer.toString();
  }

  void _initializeAI() {
    final key = widget.apiKey.isNotEmpty ? widget.apiKey : 'AIzaSyBBFhpL1zsiDe-V9bFSVCk5HHuYjNYhHe8';
    if (key.isEmpty) {
      setState(() => _isKeyMissing = true);
      _addBotMessage("AI Configuration Error: API Key is missing.");
      return;
    }

    final contextBlock = _buildContextBlock();

    String systemPrompt = '';
    if (widget.role == 'School Admin') {
      systemPrompt = 'You are a helpful AI Assistant for a School Administrator at their school. '
          'You help with school management tasks, answer questions about school data, provide guidance on using the system, '
          'and assist with educational administration matters.\n\n';
    } else if (widget.role == 'Teacher') {
      systemPrompt = 'You are a helpful AI Assistant for a Teacher at their school. '
          'You help with teaching tasks, classroom management, student data queries, score entry guidance, '
          'lesson planning ideas, and educational best practices.\n\n';
    } else {
      systemPrompt = 'You are a helpful AI Assistant for a Student at their school. '
          'You help with academic questions, study tips, and general student concerns.\n\n';
    }

    systemPrompt += 'CRITICAL RULES:\n'
        '1. NEVER mention the name of the software platform, app developer, or any external branding. '
        'Act strictly as a built-in feature of their specific school.\n'
        '2. If asked about data not provided in the context below, say you do not have that information available right now.\n'
        '3. Be concise and practical in your answers.\n';

    if (contextBlock.isNotEmpty) {
      systemPrompt += '\n$contextBlock\n'
          'Use the above data to answer questions accurately when relevant. '
          'When giving counts, use the exact numbers provided. '
          'When listing classes, use the exact names provided.\n';
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: key,
        systemInstruction: Content.text(systemPrompt),
      );
      _addBotMessage("Hello! I'm your School AI Assistant. How can I help you today?");
    } catch (e) {
      debugPrint('AI INIT ERROR: $e');
      _addBotMessage("Failed to initialize AI: $e");
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _chatHistory.add({'role': 'bot', 'text': text});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isLoading || _isKeyMissing || _model == null) return;

    _msgCtrl.clear();
    setState(() {
      _chatHistory.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final history = _chatHistory.map((m) {
        return Content.text(m['text']!);
      }).toList();

      final response = await _model!.generateContent(history);
      if (mounted) {
        _addBotMessage(response.text ?? "I couldn't understand that.");
      }
    } catch (e) {
      debugPrint('AI SEND ERROR: $e');
      if (mounted) {
        _addBotMessage("Error: ${_friendlyError(e.toString())}");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('PERMISSION_DENIED') || raw.contains('403')) {
      return 'API key does not have access to Generative Language API. Enable it at aistudio.google.com → API Keys → your key.';
    }
    if (raw.contains('RESOURCE_EXHAUSTED') || raw.contains('429') || raw.contains('quota')) {
      return 'API quota exceeded. Wait a moment or check your Google AI quota.';
    }
    if (raw.contains('INVALID_ARGUMENT') || raw.contains('400')) {
      return 'Invalid request. The model may not be available. Try again.';
    }
    if (raw.contains('network') || raw.contains('socket') || raw.contains('fetch') || raw.contains('Connection')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'AI error: ${raw.length > 100 ? raw.substring(0, 100) : raw}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isKeyMissing
                        ? Colors.red.withOpacity(0.1)
                        : const Color(0xFF1A237E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: _isKeyMissing ? Colors.red : const Color(0xFF1A237E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'School AI (${widget.role})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isKeyMissing ? Colors.red : const Color(0xFF1A237E),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final msg = _chatHistory[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF1A237E) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "AI is typing...",
                  style:
                      TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      enabled: !_isKeyMissing,
                      decoration: InputDecoration(
                        hintText: _isKeyMissing
                            ? 'AI Disabled (Key missing)'
                            : 'Ask me anything...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _isKeyMissing
                          ? Colors.grey
                          : const Color(0xFF1A237E),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: (_isLoading || _isKeyMissing)
                          ? null
                          : _sendMessage,
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
