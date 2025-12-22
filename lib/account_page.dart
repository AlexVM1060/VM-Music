
import 'package:flutter/material.dart';
import 'package:myapp/history_page.dart';
import 'package:myapp/playlists_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi Cuenta'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Historial'),
              Tab(text: 'Playlists'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HistoryPage(),
            PlaylistsPage(),
          ],
        ),
      ),
    );
  }
}
