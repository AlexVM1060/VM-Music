import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/audio_handler.dart';
import 'package:myapp/downloads_page.dart';
import 'package:myapp/router.dart'; // Importa la configuración del router
import 'package:myapp/search_page.dart';
import 'package:myapp/video_player_manager.dart';
import 'package:myapp/video_player_page.dart';
import 'package:provider/provider.dart';

late AudioHandler audioHandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  audioHandler = await initAudioService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VideoPlayerManager()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primarySeedColor = Colors.deepPurple;

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.robotoTextTheme(),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.robotoTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Cambia a MaterialApp.router y usa la configuración de go_router
        return MaterialApp.router(
          routerConfig: router, // Asigna el router importado
          title: 'VM Player',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
        );
      },
    );
  }
}

class AppShell extends StatelessWidget {
  const AppShell({super.key});

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

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    SearchPage(),
    DownloadsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isFullScreen = context.watch<VideoPlayerManager>().isFullScreen;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('VM Player', style: GoogleFonts.oswald(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          IconButton(
            icon: Icon(themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Cambiar tema',
          ),
        ],
      ),
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: isFullScreen
          ? null
          : BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
                BottomNavigationBarItem(icon: Icon(Icons.download), label: 'Descargas'),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
    );
  }
}
