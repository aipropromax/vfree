import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _api = TextEditingController();
  final _url = TextEditingController(text: 'https://api.openai.com/v1');
  final _model = TextEditingController(text: 'gpt-4o-mini');
  final _system = TextEditingController();
  bool _showThinking = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _api.text = p.getString('vfree_api') ?? '';
      _url.text = p.getString('vfree_url') ?? 'https://api.openai.com/v1';
      _model.text = p.getString('vfree_model') ?? 'gpt-4o-mini';
      _system.text = p.getString('vfree_system') ?? '';
      _showThinking = p.getBool('vfree_think') ?? true;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('vfree_api', _api.text.trim());
    await p.setString('vfree_url', _url.text.trim());
    await p.setString('vfree_model', _model.text.trim());
    await p.setString('vfree_system', _system.text);
    await p.setBool('vfree_think', _showThinking);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AYARLAR KAYDEDILDI'), backgroundColor: Colors.black),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field(String label, String help, TextEditingController c,
        {bool obscure = false, int maxLines = 1}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFFFFD600),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const SizedBox(height: 6),
            TextField(
              controller: c,
              obscureText: obscure,
              maxLines: maxLines,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Color(0xFFFFD600), width: 2)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Color(0xFFFFD600), width: 2)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Color(0xFFFFD600), width: 2)),
              ),
            ),
            const SizedBox(height: 4),
            Text(help,
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('AYARLAR',
            style: TextStyle(
                color: Color(0xFFFFD600),
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          field('API anahtari',
              'OpenAI uyumlu anahtar. Sadece cihazinda saklanir, hicbir yere gonderilmez.', _api,
              obscure: true),
          field('Sunucu adresi (base url)',
              'OpenAI uyumlu sunucu. Ornek: https://api.openai.com/v1', _url),
          field('Model', 'Ornek: gpt-4o-mini, deepseek-chat, gemini-2.0-flash', _model),
          field('System prompt', 'Asistanin karakteri ve kurallari. Bos birakabilirsin.', _system,
              maxLines: 3),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFFFFD600),
            title: const Text('DUSUNME SURECINI GOSTER',
                style: TextStyle(
                    color: Color(0xFFFFD600),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            subtitle: const Text(
                'Modelin ara dusuncelerini gorunur yapar. Destekleyen modellerde calisir (reasoning_content).',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
            value: _showThinking,
            onChanged: (v) => setState(() => _showThinking = v),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD600),
              foregroundColor: Colors.black,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _save,
            child: const Text('KAYDET',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
        ],
      ),
    );
  }
}
