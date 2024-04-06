import 'package:flutter/material.dart';
import 'package:sortify/loading_page.dart';

class AppState extends ChangeNotifier {
  String email = "";

  Widget page = LoadingPage();
  void changePage(nextPage) {
    page = nextPage;
    notifyListeners();
  }

  var panelIndex = 0;
  void updatePanelIndex(newIndex) {
    panelIndex = newIndex;
    notifyListeners();
  }
}
