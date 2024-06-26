import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_schemes.dart';
import 'driver_page.dart';
import 'app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: "Sortify",
        theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            brightness: Brightness.light,
            textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: darkColorScheme,
          brightness: Brightness.dark,
          textTheme:
              GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
            displayColor: darkColorScheme.onBackground,
            bodyColor: darkColorScheme.onBackground,
            decorationColor: darkColorScheme.onBackground,
          ),
        ),
        home: DriverPage(),
      ),
    );
  }
}
