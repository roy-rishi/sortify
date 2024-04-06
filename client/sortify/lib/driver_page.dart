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

    Widget page = appState.page;

    return Scaffold(
      body: page,
    );
  }
}
