import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'store.dart';

const kYellow = Color(0xFFFFD600);
const kSurface = Color(0xFF101010);

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    this.reasoning,
    this.fileName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        role: j['role'],
        content: j['content'] ?? '',
        reasoning: j['reasoning'],
        fileName: j['fileName'],
      );

  final String role;
  final String content;
  final String? reasoning;
  final String? fileName;

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        if (reasoning != null) 'reasoning': reasoning,
        if (fileName != null) 'fileName': fileName,
      };
}

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  String? _currentChatId;
  bool _busy = false;
  String? _error;
  String? _attached;
  List<ChatMessage> _messages = [];
  bool _showThinking = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    _showThinking = p.getBool('vfree_think') ?? true;
    final chats = await Store.loadChats();
    if (chats.isNotEmpty && mounted) {
      setState(() => _loadChat(chats.last));
    }
  }

  void _loadChat(Map<String, dynamic> chat) {
    setState(() {
      _currentChatId = chat['id'] as String?;
      _messages = ((chat['messages'] as List?) ?? [])
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList();
    });
    _jumpBottom();
  }

  void _jumpBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<Map<String, String>> _prefs() async {
    final p = await SharedPreferences.getInstance();
    return {
      'api': p.getString('vfree_api') ?? '',
      'url': p.getString('vfree_url') ?? 'https://api.openai.com/v1',
      'model': p.getString('vfree_model') ?? 'gpt-4o-mini',
      'system': p.getString('vfree_system') ?? '',
    };
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if ((text.isEmpty && _attached == null) || _busy) return;
    final cfg = await _prefs();
    if (cfg['api']!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Once AYARLAR dan API anahtari gir'),
          backgroundColor: Colors.black));
      return;
    }
    _controller.clear();
    final userMsg = ChatMessage(
        role: 'user', content: text, fileName: _attached);
    setState(() {
      _attached = null;
      _error = null;
      _busy = true;
      _messages.add(userMsg);
      _messages.add(ChatMessage(role: 'assistant', content: ''));
    });
    _jumpBottom();
    try {
      final res = await ChatApi.send(
        baseUrl: cfg['url']!,
        apiKey: cfg['api']!,
        model: cfg['model']!,
        systemPrompt: cfg['system']!,
        history: _messages
            .where((m) => m.content.isNotEmpty)
            .map((m) => {'role': m.role, 'content': m.content})
            .toList(),
      );
      setState(() {
        _messages.last = ChatMessage(
            role: 'assistant',
            content: res.content,
            reasoning: res.reasoning);
      });
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _error = e.toString();
      });
    } finally {
      setState(() => _busy = false);
      _jumpBottom();
      await _persist();
    }
  }

  Future<void> _persist() async {
    if (_messages.isEmpty) return;
    final chats = await Store.loadChats();
    final title = _messages.first.content.isEmpty
        ? (_messages.first.fileName ?? 'Sohbet')
        : _messages.first.content;
    final data = _messages.map((m) => m.toJson()).toList();
    if (_currentChatId == null) {
      _currentChatId = DateTime.now().millisecondsSinceEpoch.toString();
    }
    chats.removeWhere((c) => c['id'] == _currentChatId);
    chats.add({'id': _currentChatId, 'title': title, 'messages': data});
    await Store.saveChats(chats);
  }

  Future<void> _attach() async {
    final r = await FilePicker.platform.pickFiles();
    if (r != null && r.files.isNotEmpty) {
      setState(() => _attached = r.files.single.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_messages.isEmpty && _error == null) _welcome(),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _messages.length + (_error != null ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == _messages.length && _error != null) {
                return _errorBox(_error!);
              }
              final m = _messages[i];
              if (m.role == 'assistant' && m.content.isEmpty && _busy) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(children: [
                    SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: kYellow)),
                    SizedBox(width: 8),
                    Text(' dusunuyor...',
                        style: TextStyle(color: Colors.white38)),
                  ]),
                );
              }
              return _bubble(m);
            },
          ),
        ),
        _input(),
      ],
    );
  }

  Widget _welcome() => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: const [
            SizedBox(height: 20),
            Text('VFREE',
                style: TextStyle(
                    color: kYellow,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6)),
            SizedBox(height: 8),
            Text('Video araclari + AI asistan\nAyarlardan API anahtarini gir, sonra yaz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24)),
          ],
        ),
      );

  Widget _bubble(ChatMessage m) {
    final isUser = m.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: isUser ? kYellow : kSurface,
          border: Border.all(color: kYellow, width: 1),
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m.fileName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('DOSYA: ${m.fileName}',
                    style: TextStyle(
                        fontSize: 11,
                        color: isUser ? Colors.black54 : kYellow)),
              ),
            if (!isUser && _showThinking && m.reasoning != null)
              _thinkingBox(m.reasoning!),
            SelectableText(m.content,
                style: TextStyle(
                    color: isUser ? Colors.black : Colors.white, height: 1.35)),
          ],
        ),
      ),
    );
  }

  Widget _thinkingBox(String text) => Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          iconColor: Colors.white24,
          collapsedIconColor: Colors.white24,
          title: const Text('DUSUNCESI',
              style: TextStyle(
                  color: Colors.white24, fontSize: 11, letterSpacing: 2)),
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.zero),
              child: SelectableText(text,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12, height: 1.3)),
            ),
          ],
        ),
      );

  Widget _errorBox(String e) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 1)),
        child: SelectableText('HATA: $e',
            style: const TextStyle(color: Colors.red, fontSize: 12)),
      );

  Widget _input() => SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: kYellow, width: 2))),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              if (_attached != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Chip(
                    backgroundColor: kSurface,
                    label: Text(_attached!,
                        style: const TextStyle(color: kYellow, fontSize: 11)),
                    deleteIconColor: kYellow,
                    onDeleted: () => setState(() => _attached = null),
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Prompt yaz...',
                    hintStyle: TextStyle(color: Colors.white24),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: kYellow, width: 2)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: kYellow, width: 2)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: kYellow, width: 2)),
                  ),
                ),
              ),
              IconButton(
                  onPressed: _attach,
                  icon: const Icon(Icons.attach_file, color: kYellow)),
              IconButton(
                  onPressed: _busy ? null : _send,
                  icon: const Icon(Icons.send, color: kYellow)),
            ],
          ),
        ),
      );
}
