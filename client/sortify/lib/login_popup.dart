import 'package:flutter/material.dart';

import 'dart:async';

class LoginPopup {
  static Future<void> displayLogin(BuildContext context) async {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.headlineMedium!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text("Login", style: titleStyle)),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("You have been logged out. Reload, then try again."),
            ],
          ),
          actions: <Widget>[],
        );
      },
    );
  }
}
