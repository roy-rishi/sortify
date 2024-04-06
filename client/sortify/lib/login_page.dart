import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sortify/constants.dart';
import 'package:sortify/home_page.dart';
import 'package:sortify/signup_page.dart';

import 'app_state.dart';

final storage = FlutterSecureStorage();

Future<String> emailStatus(String email) async {
  final response = await http.post(
    Uri.parse("$HTTP_PROTOCOL$SERVER_BASE_URL/email-status"),
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

Future<bool> attemptLogin(String email, String password) async {
  final response = await http.post(
    Uri.parse("$HTTP_PROTOCOL$SERVER_BASE_URL/login"),
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
    return true;
  } else if (response.statusCode == 401) {
    print("Authorization not successful");
    return false;
  }
  throw Exception(response.body);
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Future<String> futureEmailStatus = Future.value(""); // Initialize here
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String emailRegStatus = "Unverified";

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displayLarge!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
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
                    appState.email = _emailController.text.trim();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      appState.changePage(SignUpPage());
                    });
                  }
                } else if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
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
                      setState(() {
                        futureEmailStatus =
                            emailStatus(_emailController.text.trim());
                      });
                      print(_emailController.text.trim());
                    } else if (emailRegStatus == "Email is registered") {
                      attemptLogin(_emailController.text.trim(),
                              _passwordController.text.trim())
                          .then((loginStatus) {
                        if (loginStatus) {
                          appState.changePage(HomePage());
                        } else {
                          print("Login failed");

                          var snackBar = SnackBar(
                            content: Center(child: Text("Invalid Login Credentials")),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        }
                      }).catchError((error) {
                        print(error);
                      });
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
