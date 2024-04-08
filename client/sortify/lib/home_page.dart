import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sortify/filter_page.dart';

import 'package:http/http.dart' as http;
import 'package:sortify/loading_page.dart';
import 'package:sortify/sort_page.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_state.dart';
import 'constants.dart';
import 'results_page.dart';

final storage = FlutterSecureStorage();

class CardRowItem extends StatelessWidget {
  const CardRowItem(
      {super.key,
      required this.text,
      required this.icon,
      required this.nextPage});

  final String text;
  final IconData icon;
  final Widget nextPage;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Card(
          clipBehavior: Clip.hardEdge,
          color: theme.colorScheme.primaryContainer,
          child: InkWell(
              splashColor: theme.colorScheme.primary,
              onTap: () {
                appState.changePage(nextPage);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 26),
                  Text(text),
                ],
              )),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<int> incompletesExist() async {
    final storedJwt = await storage.read(key: "jwt");
    final response = await http.get(
        Uri.parse("$HTTP_PROTOCOL$SERVER_BASE_URL/all-incomplete-sorts"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          HttpHeaders.authorizationHeader: "Bearer $storedJwt",
        });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data is List && data.isEmpty) {
        return -1; // there are no incomplete tests
      } else if (data is List && data.isNotEmpty) {
        return data[0]["Key"];
      } else {
        throw Exception("An error occured");
      }
    }
    if (response.statusCode == 401) {
      throw Exception("Need to login");
    }
    throw Exception(response.body);
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displayLarge!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
      fontSize: 80,
    );
    final heading2Style = theme.textTheme.headlineMedium;

    return Center(
      child: SizedBox(
        width: 700,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: Text("Sortify", style: titleStyle),
            ),
            // ROW 1
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  Card.outlined(
                    child: Row(
                      children: [
                        AspectRatio(
                          aspectRatio: 1 / 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Sorting", style: heading2Style),
                              Icon(Icons.sports_esports_outlined),
                            ],
                          ),
                        ),
                        FutureBuilder(
                            future: incompletesExist(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 65, right: 65),
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Text("${snapshot.error}");
                              }
                              if (snapshot.data == null) {
                                return Text("No data");
                              }
                              if (snapshot.data == -1) {
                                return CardRowItem(
                                  text: "Start Round",
                                  icon: Icons.play_arrow_outlined,
                                  nextPage: FilterPage(),
                                );
                              } else {
                                return CardRowItem(
                                  text: "Resume Round",
                                  icon: Icons.play_arrow_outlined,
                                  nextPage: SortPageLoader(),
                                );
                              }
                            }),
                        // CardRowItem(
                        //     text: "Start Round",
                        //     icon: Icons.play_arrow_outlined,
                        //     nextPage: FilterPage()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ROW 2
            SizedBox(
              height: 160,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Card.outlined(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CardRowItem(
                            text: "Your Sorts",
                            icon: Icons.person_2_outlined,
                            nextPage: ResultsLoader()),
                        AspectRatio(
                          aspectRatio: 1 / 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Results", style: heading2Style),
                              Icon(Icons.history),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ROW 3
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: SizedBox(
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Card.outlined(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("User Settings",
                                style: theme.textTheme.titleMedium),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // IconButton(
                                //   onPressed: () {
                                //     print("Pressed");
                                //   },
                                //   icon: Icon(Icons.settings_outlined),
                                //   color: theme.colorScheme.primary,
                                // ),
                                Tooltip(
                                  message: "Sign Out",
                                  child: IconButton(
                                    onPressed: () async {
                                      print("Signing out...");
                                      await storage.write(key: "jwt", value: "lol");
                                      appState.changePage(LoadingPage());
                                    },
                                    icon: Icon(Icons.logout_rounded),
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
