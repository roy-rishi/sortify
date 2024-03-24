import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  String email = "";

  var pageIndex = 0;
  void updatePageIndex(newIndex) {
    pageIndex = newIndex;
    notifyListeners();
  }

  var panelIndex = 0;
  void updatePanelIndex(newIndex) {
    panelIndex = newIndex;
    notifyListeners();
  }
}
