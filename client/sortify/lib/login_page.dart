import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_state.dart';

final storage = FlutterSecureStorage();

Future<String> emailStatus(String email) async {
  final response = await http.post(
    Uri.parse("http://localhost:3004/email-status"),
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

void attemptLogin(String email, String password) async {
  final response = await http.post(
    Uri.parse("http://localhost:3004/login"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      HttpHeaders.authorizationHeader:
          "Basic ${base64Encode(utf8.encode("$email:$password"))}",
    },
  );

  if (response.statusCode == 200) {
    print(response.body);
    await storage.write(key: "jwt", value: response.body.toString());
    print("Authorization successful");
    return;
  } else if (response.statusCode == 401) {
    print("Authorization not successful");
    return;
  }
  throw Exception(response.body);
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  late Future<String> futureEmailStatus = Future.value(""); // Initialize here
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String emailRegStatus = "Unverified";

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.primary,
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text("Login", style: titleStyle),
            ),
            SizedBox(
              width: 320,
              height: 42,
              child: TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Email",
                ),
              ),
            ),
            FutureBuilder<String>(
              future: futureEmailStatus,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  if (snapshot.data == "Email is registered") {
                    emailRegStatus = snapshot.data.toString();

                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: 320,
                        height: 42,
                        child: TextField(
                          obscureText: true,
                          controller: _passwordController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Password",
                          ),
                        ),
                      ),
                    );
                  } else if (snapshot.data == "Email not registered") {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      appState.updatePageIndex(2);
                    });
                  }
                } else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                // Return an empty Container as a fallback
                return Container();
              },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                height: 40,
                child: OutlinedButton(
                  onPressed: () {
                    if (emailRegStatus == "Unverified") {
                      setState(
                        () {
                          futureEmailStatus =
                              emailStatus(_emailController.text.trim());
                        },
                      );
                      print(_emailController.text.trim());
                    } else if (emailRegStatus == "Email not registered") {
                    } else if (emailRegStatus == "Email is registered") {
                      attemptLogin(_emailController.text.trim(),
                          _passwordController.text.trim());
                    }
                  },
                  child: Text("Continue"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
