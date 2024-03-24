import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_state.dart';

final storage = FlutterSecureStorage();

Future<String> verifyReq() async {
  final storedJwt = await storage.read(key: "jwt");
  print(storedJwt);

  final response = await http.get(
    Uri.parse("http://localhost:3004/verify"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      HttpHeaders.authorizationHeader: "Bearer $storedJwt",
    },
  );

  if (response.statusCode == 200) {
    return response.body;
  }
  if (response.statusCode == 401 ||
      response.body == "Missing authorization" ||
      response.body == "Poor authentication") {
    return "Password required";
  }
  throw Exception(response.body);
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
    var appState = context.watch<AppState>();

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
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      appState.updatePageIndex(1);
                    });
                  } else if (snapshot.data.toString() == "Verified jwt") {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      appState.updatePageIndex(3);
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
