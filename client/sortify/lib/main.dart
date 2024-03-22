import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'color_schemes.dart';
import "verify_req.dart";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: "Sortify",
        theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
        darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
        home: DriverPage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var pageIndex = 0;

  void updatePageIndex(newIndex) {
    pageIndex = newIndex;
    notifyListeners();
  }
}

class DriverPage extends StatefulWidget {
  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    Widget page;
    switch (appState.pageIndex) {
      case 0:
        page = LoadingPage();
      case 1:
        page = const Placeholder();
      default:
        throw UnimplementedError("No widget for $appState.pageIndex");
    }

    return Scaffold(
      body: page,
    );
  }
}

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  late Future<String> futureValidReq;

  @override
  void initState() {
    super.initState();
    futureValidReq = verifyReq();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displayLarge!.copyWith(
      color: theme.colorScheme.primary,
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Text('Sortify', style: titleStyle),
            ),
            FutureBuilder<String>(
              future: futureValidReq,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data.toString() == "Password required") {
                    WidgetsBinding.instance!.addPostFrameCallback((_) {
                      appState.updatePageIndex(1);
                    });
                  } else {
                    return Text(snapshot.data.toString());
                  }
                }
                return SizedBox(
                  width: 230,
                  child: LinearProgressIndicator(
                    value: null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
