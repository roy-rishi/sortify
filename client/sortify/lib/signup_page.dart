import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:http/http.dart' as http;
import 'package:sortify/constants.dart';
import 'package:sortify/login_page.dart';
import 'dart:convert';

import 'app_state.dart';

Future<String> verifyEmail(String email) async {
  final response = await http.post(
    Uri.parse("$HTTP_PROTOCOL$SERVER_BASE_URL/verify-email"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      "email": email,
    }),
  );

  if (response.statusCode == 200) {
    return response.body;
  }
  throw Exception(response.body);
}

Future<String> createUser(String pass, String name, String token) async {
  final response = await http.post(
    Uri.parse("$HTTP_PROTOCOL$SERVER_BASE_URL/create-user"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      HttpHeaders.authorizationHeader: "Bearer $token",
    },
    body: jsonEncode(<String, String>{
      "pass": pass,
      "name": name,
    }),
  );

  print(response.body);

  if (response.statusCode == 200) {
    return response.body;
  } else if (response.statusCode == 401) {
    return response.body;
  } else if (response.statusCode == 400) {
    return response.body;
  } else if (response.statusCode == 422) {
    return response.body;
  }
  throw Exception(response.body);
}

class SendEmailPanel extends StatefulWidget {
  const SendEmailPanel({Key? key, required this.email}) : super(key: key);

  final String email;

  @override
  State<SendEmailPanel> createState() => _SendEmailPanelState();
}

class _SendEmailPanelState extends State<SendEmailPanel> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _emailController.text = widget.email;
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 6),
        child: Text("An email will be sent to"),
      ),
      SizedBox(
        width: 320,
        height: 42,
        child: TextField(
          autofocus: true,
          controller: _emailController,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Email",
          ),
          onSubmitted: (value) {
            print("Sending email");
            verifyEmail(_emailController.text);
            appState.updatePanelIndex(1); // move to next panel
            var snackBar = SnackBar(
              content: Center(child: Text("Email Sent")),
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () {
                  appState.changePage(LoginPage());
                },
                child: Text("Or, Login"),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                print("Sending email");
                verifyEmail(_emailController.text);
                appState.updatePanelIndex(1); // move to next panel

                var snackBar = SnackBar(
                  content: Center(child: Text("Email Sent")),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              child: Text("Send"),
            ),
          ],
        ),
      ),
    ]);
  }
}

class VerifyEmailPanel extends StatefulWidget {
  const VerifyEmailPanel({super.key});

  @override
  State<VerifyEmailPanel> createState() => _VerifyEmailPanelState();
}

class _VerifyEmailPanelState extends State<VerifyEmailPanel> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pass1Controller = TextEditingController();
  final TextEditingController _pass2Controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 6),
          child: Column(
            children: [
              Text("Enter the code sent to your email"),
              Text("It may take up to 2 minutes to arrive"),
            ],
          ),
        ),
        SizedBox(
          width: 320,
          height: 52,
          child: TextField(
            controller: _codeController,
            maxLines: 1,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Code",
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text("Enter your name"),
        ),
        SizedBox(
          width: 320,
          height: 52,
          child: TextField(
            controller: _nameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Name",
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text("Create a password"),
        ),
        SizedBox(
          width: 320,
          height: 52,
          child: TextField(
            obscureText: true,
            controller: _pass1Controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Password",
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text("Reenter password"),
        ),
        SizedBox(
          width: 320,
          height: 52,
          child: TextField(
            obscureText: true,
            controller: _pass2Controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Password",
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  appState.changePage(LoginPage());
                },
                child: Text("Or, Login"),
              ),
              OutlinedButton(
                  onPressed: () async {
                    var errors = "";
                    // code field is empty
                    if (_codeController.text.trim() == "") {
                      errors += "Code field is empty. ";
                    } // code field is empty
                    if (_nameController.text.trim() == "") {
                      errors += "Name field is empty. ";
                    } // 1st password field is empty
                    if (_pass1Controller.text.trim() == "") {
                      errors += "Password field is empty. ";
                    } // 2nd password field is empty
                    if (_pass2Controller.text.trim() == "") {
                      errors += "Password confirmation field is empty. ";
                    } // both password fields have a value, but they do not match
                    if (_pass1Controller.text.trim() !=
                            _pass2Controller.text.trim() &&
                        _pass1Controller.text.trim() != "" &&
                        _pass2Controller.text.trim() != "") {
                      errors += "Passwords do not match. ";
                    }
                    // form has errors
                    if (errors != "") {
                      var snackBar = SnackBar(
                        content: Center(child: Text(errors)),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      return;
                    } else {
                      var status = await createUser(
                          _pass1Controller.text.trim(),
                          _nameController.text.trim(),
                          _codeController.text.trim());
                      if (status.toString() != "Created user") {
                        var snackBar = SnackBar(
                          content: Center(child: Text(status.toString())),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        return;
                      } else {
                        appState.changePage(LoginPage());
                      }
                      return;
                    }
                  },
                  child: Text("Continue")),
            ],
          ),
        )
      ],
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();

    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w900,
    );

    Widget panel;

    switch (appState.panelIndex) {
      case 0:
        panel = SendEmailPanel(email: appState.email);
      case 1:
        panel = VerifyEmailPanel();
      default:
        throw UnimplementedError("No widget for index");
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Sign Up", style: titleStyle),
            SizedBox(child: panel),
          ],
        ),
      ),
    );
  }
}
