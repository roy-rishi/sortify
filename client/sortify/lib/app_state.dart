import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  var pageIndex = 0;

  void updatePageIndex(newIndex) {
    pageIndex = newIndex;
    notifyListeners();
  }
}
