import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatApi {
  static Future<({String content, String? reasoning})> send({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required List<Map<String, String>> history,
  }) async {
    final clean = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final url = Uri.parse('$clean/chat/completions');
    final messages = <Map<String, String>>[
      if (systemPrompt.trim().isNotEmpty)
        {'role': 'system', 'content': systemPrompt.trim()},
      ...history,
    ];
    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'model': model, 'messages': messages}),
    );
    if (res.statusCode != 200) {
      final body = res.body.length > 300 ? res.body.substring(0, 300) : res.body;
      throw Exception('HTTP ${res.statusCode}: $body');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    final msg = data['choices'][0]['message'];
    return (
      content: (msg['content'] ?? '') as String,
      reasoning: msg['reasoning_content'] as String?,
    );
  }
}
