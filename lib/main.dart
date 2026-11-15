import 'package:flutter/material.dart';

import 'chat_view.dart';
import 'settings_page.dart';
import 'vfree_drawer.dart';

const kYellow = Color(0xFFFFD600);
const kBlack = Color(0xFF000000);

void main() => runApp(const VfreeApp());

class VfreeApp extends StatelessWidget {
  const VfreeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Vfree',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: kBlack,
          colorScheme: const ColorScheme.dark(
              primary: kYellow, secondary: kYellow, surface: kBlack),
        ),
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBlack,
      drawer: const VfreeDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _header(context),
            _videoTools(),
            const Divider(color: kYellow, thickness: 2, height: 2),
            const Expanded(child: ChatView()),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsPage())),
              icon: const Icon(Icons.settings, color: kYellow),
            ),
            const Text('VFREE',
                style: TextStyle(
                    color: kYellow,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4)),
            const Spacer(),
            const _MiniStar(),
          ],
        ),
      );

  Widget _videoTools() => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: const [
            Expanded(child: ToolCard(icon: Icons.download, label: 'INDIR')),
            SizedBox(width: 8),
            Expanded(child: ToolCard(icon: Icons.content_cut, label: 'DUZENLE')),
            SizedBox(width: 8),
            Expanded(child: ToolCard(icon: Icons.outbound, label: 'CIKTI')),
          ],
        ),
      );
}

class _MiniStar extends StatelessWidget {
  const _MiniStar();

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 26,
        height: 26,
        child: CustomPaint(painter: _StarPainter()),
      );
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = s / 2;
    final outer = s * 0.48;
    final mid = s * 0.14;
    final colors = [
      const Color(0xFFFF0040),
      const Color(0xFFFF8000),
      const Color(0xFFFFD600),
      const Color(0xFF22DD55),
      const Color(0xFF00C8FF),
      const Color(0xFF4040FF),
      const Color(0xFFC000FF),
      Colors.white,
    ];
    for (var i = 0; i < colors.length; i++) {
      final k = 1 - 0.14 * i;
      final p = Path();
      const xs = [0, 1, 2, 1, 0, -1, -2, -1];
      const ys = [-2, -1, 0, 1, 2, 1, 0, -1];
      p.moveTo(c + xs[0] * mid * k, c + ys[0] * outer * k);
      for (var j = 1; j < 8; j++) {
        p.lineTo(c + xs[j] * mid * k, c + ys[j] * outer * k);
      }
      p.close();
      canvas.drawPath(p, Paint()..color = colors[i]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ToolCard extends StatelessWidget {
  const ToolCard({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$label v2 surumunde gelecek'),
            backgroundColor: Colors.black)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF101010),
            border: Border.all(color: kYellow, width: 2),
            borderRadius: BorderRadius.zero,
          ),
          child: Column(
            children: [
              Icon(icon, color: kYellow, size: 30),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(
                      color: kYellow,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 12)),
            ],
          ),
        ),
      );
}
