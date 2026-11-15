import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Store {
  static const _chatsKey = 'vfree_chats';

  static Future<List<Map<String, dynamic>>> loadChats() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_chatsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> saveChats(List<Map<String, dynamic>> chats) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_chatsKey, jsonEncode(chats));
  }
}
