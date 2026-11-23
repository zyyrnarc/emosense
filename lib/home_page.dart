import 'package:flutter/material.dart';

import 'auth_store.dart';
import 'main.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user});

  final UserAccount user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EmoSense'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed:
                () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomePage()),
                  (_) => false,
                ),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Halo, ${user.name} 👋', style: headline()),
            const SizedBox(height: 6),
            Text(
              'Bagaimana perasaanmu hari ini?',
              style: bodyMd(C.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: C.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: shadowMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny_outlined, color: C.secondary),
                      const SizedBox(width: 8),
                      Text('Ringkasan hari ini', style: labelLg()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('😊', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text('Mood kamu: Bahagia', style: headline(C.secondary)),
                  const SizedBox(height: 6),
                  Text(
                    'Catat perasaanmu secara berkala untuk melihat pola suasana hati.',
                    style: bodyMd(C.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Menu', style: labelLg()),
            const SizedBox(height: 10),
            _HomeTile(
              icon: Icons.add_reaction_outlined,
              title: 'Catat suasana hati',
              subtitle: 'Tambahkan catatan mood hari ini',
            ),
            _HomeTile(
              icon: Icons.insights_outlined,
              title: 'Riwayat mood',
              subtitle: 'Lihat perkembangan suasana hati',
            ),
            _HomeTile(
              icon: Icons.camera_alt_outlined,
              title: 'Deteksi ekspresi',
              subtitle: 'Fitur kamera akan tersedia setelah integrasi',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: C.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: C.primaryFixed,
          child: Icon(icon, color: C.primary),
        ),
        title: Text(title, style: labelLg()),
        subtitle: Text(subtitle, style: bodySm(C.onSurfaceVariant)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
