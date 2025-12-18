import 'dart:developer' as developer;
import 'package:flutter/cupertino.dart';
import 'search_page.dart';
import 'downloads_page.dart';

void main() {
  try {
    runApp(const MyApp());
  } catch (e, s) {
    developer.log('Error al iniciar la app', error: e, stackTrace: s);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'YouTube Downloader',
      theme: CupertinoThemeData(primaryColor: CupertinoColors.systemRed),
      home: MainTabs(),
    );
  }
}

class MainTabs extends StatelessWidget {
  const MainTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.down_arrow),
            label: 'Descargas',
          ),
        ],
      ),
      tabBuilder: (BuildContext context, int index) {
        switch (index) {
          case 0:
            return CupertinoTabView(
              builder: (context) {
                return const SearchPage();
              },
            );
          case 1:
            return CupertinoTabView(
              builder: (context) {
                return const DownloadsPage();
              },
            );
          default:
            return CupertinoTabView(
              builder: (context) {
                return const SearchPage();
              },
            );
        }
      },
    );
  }
}
