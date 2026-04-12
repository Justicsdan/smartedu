import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatBotWidget extends StatefulWidget {
  final String role;
  final String apiKey;

  const ChatBotWidget({
    super.key, 
    required this.role, 
    this.apiKey = '',
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

  void _initializeAI() {
    if (widget.apiKey.isEmpty) {
      setState(() => _isKeyMissing = true);
      _addBotMessage("AI Configuration Error: API Key is missing.");
      return;
    }

    String systemPrompt = '';
    if (widget.role == 'School Admin') {
      systemPrompt = 'You are a helpful internal AI Assistant for a School Administrator. '
          'CRITICAL RULE: NEVER mention the name of the software platform, app developer, or any external branding. '
          'Act strictly as a built-in feature of their specific school.';
    } else if (widget.role == 'Teacher') {
      systemPrompt = 'You are a helpful internal AI Assistant for a Teacher. '
          'CRITICAL RULE: NEVER mention the name of the software platform, app developer, or any external branding. '
          'Act strictly as a built-in feature of their specific school.';
    } else {
      systemPrompt = 'You are a helpful internal AI Assistant for a Student. '
          'CRITICAL RULE: NEVER mention the name of the software platform, app developer, or any external branding. '
          'Act strictly as a built-in feature of their specific school.';
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: widget.apiKey,
        systemInstruction: Content.text(systemPrompt), 
      );
      _addBotMessage("Hello! I'm your School AI Assistant. How can I help you today?");
    } catch (e) {
      _addBotMessage("Failed to initialize AI.");
    }
  }

  void _addBotMessage(String text) {
    setState(() { _chatHistory.add({'role': 'bot', 'text': text}); });
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
        if (m['role'] == 'user') {
          return Content.text(m['text']!);
        } else {
          return Content.model([TextPart(m['text']!)]);
        }
      }).toList();

      // [FIX] Added null assertion (!) since we verified _model != null above
      final response = await _model!.generateContent(history);
      if (mounted) {
        _addBotMessage(response.text ?? "I couldn't understand that.");
      }
    } catch (e) {
      if (mounted) {
        _addBotMessage("Error: Please check your internet connection or AI quota.");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
        ]
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isKeyMissing 
                        ? Colors.red.withOpacity(0.1) 
                        : const Color(0xFF1A237E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Icon(
                    Icons.smart_toy, 
                    color: _isKeyMissing ? Colors.red : const Color(0xFF1A237E)
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'School AI (${widget.role})',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: _isKeyMissing ? Colors.red : const Color(0xFF1A237E)
                    )
                  )
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey), 
                  onPressed: () => Navigator.pop(context)
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
                      maxWidth: MediaQuery.of(context).size.width * 0.8
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF1A237E) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: SelectableText(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87, 
                        fontSize: 14
                      )
                    )
                  )
                );
              }
            )
          ),
          if (_isLoading) 
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "AI is typing...", 
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)
                )
              )
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200))
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
                        hintText: _isKeyMissing ? 'AI Disabled (Key missing)' : 'Ask me anything...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24), 
                          borderSide: BorderSide.none
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)
                      ),
                      onSubmitted: (_) => _sendMessage()
                    )
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _isKeyMissing ? Colors.grey : const Color(0xFF1A237E), 
                      shape: BoxShape.circle
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: (_isLoading || _isKeyMissing) ? null : _sendMessage
                    )
                  ),
                ]
              )
            )
          ),
        ],
      ),
    );
  }
}
