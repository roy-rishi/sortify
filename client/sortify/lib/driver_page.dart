import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'loading_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'filter_page.dart';
import 'sort_page.dart';
import 'results_page.dart';

class DriverPage extends StatefulWidget {
  @override
  State<DriverPage> createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    Widget page;
    switch (appState.pageIndex) {
      case 0:
        page = LoadingPage();
      case 1:
        page = LoginPage();
      case 2:
        page = SignUpPage();
      case 3:
        page = HomePage();
      case 4:
        page = FilterPage();
      case 5:
        page = const Text("Your Sorts");
      case 6:
        page = SortPage();
      case 7:
        page = ResultsPage(songsList: tracksToSort, );
      default:
        throw UnimplementedError("No widget for $appState.pageIndex");
    }

    return Scaffold(
      body: page,
    );
  }
}
