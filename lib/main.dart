import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myapp/audio_handler.dart';
import 'package:myapp/downloads_page.dart';
import 'package:myapp/search_page.dart';

// Handler de audio global para acceder desde cualquier parte de la app
late AudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa el servicio de audio y espera a que esté listo
  audioHandler = await initAudioService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'YouTube Downloader',
      theme: CupertinoThemeData(primaryColor: CupertinoColors.systemRed),
      // Añade los delegados de localización para que los widgets de Material funcionen
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', ''), // Inglés
        Locale('es', ''), // Español
      ],
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
