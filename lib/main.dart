import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myapp/audio_handler.dart';
import 'package:myapp/downloads_page.dart';
import 'package:myapp/search_page.dart';
import 'package:myapp/video_player_manager.dart';
import 'package:myapp/video_player_page.dart';
import 'package:provider/provider.dart';

late AudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  audioHandler = await initAudioService();
  runApp(
    ChangeNotifierProvider(
      create: (_) => VideoPlayerManager(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'YouTube Downloader',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', ''),
        Locale('es', ''),
      ],
      home: AppStructure(),
    );
  }
}

class AppStructure extends StatelessWidget {
  const AppStructure({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        MainTabs(),
        OverlayVideoPlayer(),
      ],
    );
  }
}

class OverlayVideoPlayer extends StatelessWidget {
  const OverlayVideoPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoPlayerManager>(
      builder: (context, manager, child) {
        if (manager.currentVideoId == null) {
          return const SizedBox.shrink();
        }
        return VideoPlayerPage(videoId: manager.currentVideoId!);
      },
    );
  }
}

// SOLUCIÓN DEFINITIVA: TabBar invisible. Se elimina 'const' y se añade un
// comentario para ignorar el aviso del analizador, ya que el constructor
// de la superclase impide el uso de 'const'.
// ignore: prefer_const_constructors_in_immutables
class _EmptyTabBar extends CupertinoTabBar {
  _EmptyTabBar()
      : super(items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: SizedBox(), label: ''),
          BottomNavigationBarItem(icon: SizedBox(), label: ''),
        ]);

  @override
  Size get preferredSize => Size.zero;
}

class MainTabs extends StatelessWidget {
  const MainTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final isFullScreen = context.watch<VideoPlayerManager>().isFullScreen;

    return CupertinoTabScaffold(
      tabBar: isFullScreen
          ? _EmptyTabBar()
          : CupertinoTabBar(
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
            return CupertinoTabView(builder: (context) => const SearchPage());
          case 1:
            return CupertinoTabView(builder: (context) => const DownloadsPage());
          default:
            return CupertinoTabView(builder: (context) => const SearchPage());
        }
      },
    );
  }
}
