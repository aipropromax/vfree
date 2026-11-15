import 'package:flutter/material.dart';

import 'store.dart';

class VfreeDrawer extends StatefulWidget {
  const VfreeDrawer({super.key, this.onLoadChat, this.currentChatId});

  final void Function(Map<String, dynamic> chat)? onLoadChat;
  final String? currentChatId;

  @override
  State<VfreeDrawer> createState() => _VfreeDrawerState();
}

class _VfreeDrawerState extends State<VfreeDrawer>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<Map<String, dynamic>> _chats = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _refresh();
  }

  Future<void> _refresh() async {
    _chats = await Store.loadChats();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      shape: const Border(
          right: BorderSide(color: Color(0xFFFFD600), width: 2)),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('VFREE',
                    style: TextStyle(
                        color: Color(0xFFFFD600),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3)),
              ),
            ),
            TabBar(
              controller: _tabs,
              indicatorColor: const Color(0xFFFFD600),
              labelColor: const Color(0xFFFFD600),
              unselectedLabelColor: Colors.white38,
              tabs: const [
                Tab(text: 'PROJELER'),
                Tab(text: 'SOHBETLER'),
                Tab(text: 'GORSELLER'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _placeholder('Projeler v2 surumunde gelecek.\nVideo projeleri burada listelenecek.'),
                  _chatList(),
                  _placeholder('Gorseller v2 surumunde gelecek.\nAI ile urettigin resimler burada olacak.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(String text) => Center(
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white24)),
      );

  Widget _chatList() {
    if (_chats.isEmpty) {
      return _placeholder('Henuz sohbet yok.\nBir mesaj gonder, burada birikir.');
    }
    return ListView.builder(
      itemCount: _chats.length,
      itemBuilder: (context, i) {
        final chat = _chats[_chats.length - 1 - i];
        final selected = chat['id'] == widget.currentChatId;
        return ListTile(
          leading: const Icon(Icons.chat_bubble_outline,
              color: Color(0xFFFFD600), size: 20),
          title: Text(
            (chat['title'] ?? 'Sohbet') as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? const Color(0xFFFFD600) : Colors.white70,
            ),
          ),
          subtitle: Text('${(chat['messages'] as List?)?.length ?? 0} mesaj',
              style: const TextStyle(color: Colors.white24, fontSize: 11)),
          onTap: () {
            widget.onLoadChat?.call(chat);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
