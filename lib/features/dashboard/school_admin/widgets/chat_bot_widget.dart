import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatBotWidget extends StatefulWidget {
  final String role;
  final String apiKey;
  final String schoolContext;
  const ChatBotWidget({super.key, required this.role, this.apiKey = '', required this.schoolContext});
  @override
  State<ChatBotWidget> createState() => _ChatBotWidgetState();
}

class _ChatBotWidgetState extends State<ChatBotWidget> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({'role': 'assistant', 'text': 'Hello! I am your school AI assistant. How can I help you today?'});
  }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isLoading) return;
    setState(() { _messages.add({'role': 'user', 'text': text}); _isLoading = true; });
    _msgCtrl.clear();
    _scrollToBottom();
    final systemPrompt = 'You are a helpful AI assistant for a school management system. Role: ' + widget.role + '. School: ' + widget.schoolContext + '. Be concise. Keep under 3 paragraphs.';
    final messages = <Map<String, String>>[{'role': 'system', 'content': systemPrompt}];
    for (final msg in _messages) { messages.add({'role': msg['role'] == 'user' ? 'user' : 'assistant', 'content': msg['text']!}); }
    try {
      final response = await http.post(
        Uri.parse('https://tcjsmkhmfjigutfhjtem.supabase.co/functions/v1/chat-ai'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer sb_publishable_zWDvjhEldcV8eutnlRypGA_LGpOUhkg'},
        body: jsonEncode({'messages': messages}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] ?? 'No reply';
        setState(() { _messages.add({'role': 'assistant', 'text': reply.toString().trim()}); });
      } else {
        final errData = jsonDecode(response.body);
        setState(() { _messages.add({'role': 'assistant', 'text': 'Error (' + response.statusCode.toString() + '): ' + (errData['error'] ?? 'Unknown')}); });
      }
    } catch (e) {
      setState(() { _messages.add({'role': 'assistant', 'text': 'Error: ' + e.toString()}); });
    } finally { setState(() => _isLoading = false); _scrollToBottom(); }
  }

  @override
  Widget build(BuildContext context) {
    return Container(width: 360, height: 480, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))]), clipBehavior: Clip.antiAlias, child: Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: const BoxDecoration(color: Color(0xFF1A237E)), child: Row(children: [Expanded(child: Text('School AI (' + widget.role + ')', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))), IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 20), onPressed: () => Navigator.of(context).pop())])),
      Expanded(child: _messages.isEmpty ? const Center(child: Text('No messages')) : ListView.builder(controller: _scrollCtrl, padding: const EdgeInsets.all(12), itemCount: _messages.length, itemBuilder: (context, index) { final msg = _messages[index]; final isUser = msg['role'] == 'user'; return Align(alignment: isUser ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75), decoration: BoxDecoration(color: isUser ? const Color(0xFF1A237E) : Colors.grey.shade100, borderRadius: BorderRadius.only(topLeft: const Radius.circular(12), topRight: const Radius.circular(12), bottomLeft: Radius.circular(isUser ? 12 : 4), bottomRight: Radius.circular(isUser ? 4 : 12))), child: Text(msg['text'] ?? '', style: TextStyle(fontSize: 13, color: isUser ? Colors.white : Colors.grey.shade800)))); })),
      if (_isLoading) const Padding(padding: EdgeInsets.only(bottom: 12), child: Align(alignment: Alignment.centerLeft, child: Text('AI is typing...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: Colors.grey.shade50, border: Border(top: BorderSide(color: Colors.grey.shade200))), child: Row(children: [Expanded(child: TextField(controller: _msgCtrl, decoration: InputDecoration(hintText: 'Ask me anything...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)), onSubmitted: (_) => _sendMessage())), const SizedBox(width: 8), Container(decoration: const BoxDecoration(color: Color(0xFF1A237E), shape: BoxShape.circle), child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white), onPressed: _isLoading ? null : _sendMessage))]))
    ]));
  }
}
