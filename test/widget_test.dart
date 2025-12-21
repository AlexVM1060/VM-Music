import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:provider/provider.dart';
import 'package:myapp/video_player_manager.dart';

void main() {
  testWidgets('Muestra las pestañas Buscar y Descargas', (WidgetTester tester) async {
    // Construye la app con los providers necesarios
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => VideoPlayerManager()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Espera a que la UI se estabilice.
    await tester.pumpAndSettle();

    // Verifica que la barra de navegación inferior está presente.
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verifica que las pestañas "Buscar" y "Descargas" existen.
    expect(find.text('Buscar'), findsOneWidget);
    expect(find.text('Descargas'), findsOneWidget);

    // Verifica que los iconos de búsqueda y descarga están presentes.
    expect(find.byIcon(Icons.search), findsWidgets);
    expect(find.byIcon(Icons.download), findsWidgets);
  });
}
