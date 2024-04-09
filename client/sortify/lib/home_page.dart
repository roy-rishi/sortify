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
import 'login_popup.dart';

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
    final buttonLabelStyle = theme.textTheme.titleMedium!.copyWith(
      color: theme.colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.w500,
      fontSize: 17,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 14),
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
                  Icon(icon,
                      size: 30, color: theme.colorScheme.onPrimaryContainer),
                  Text(text, style: buttonLabelStyle),
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
  Future<bool> incompletesExist(BuildContext context) async {
    final storedJwt = await storage.read(key: "jwt");
    final response = await http.get(
        Uri.parse("$HTTP_PROTOCOL$SERVER_BASE_URL/all-incomplete-sorts"),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          HttpHeaders.authorizationHeader: "Bearer $storedJwt",
        });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print(data);

      if (data is List) {
        return data.isNotEmpty; // if incomplete tests exist
      } else {
        throw Exception("No data");
      }
    }
    if (response.statusCode == 401 || response.body == "Jwt is expired") {
      await LoginPopup.displayLogin(context);
    }
    throw Exception(response.body);
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displayLarge!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
      fontSize: 80,
    );
    final heading2Style = theme.textTheme.headlineLarge!.copyWith(
      color: theme.colorScheme.onBackground,
      fontWeight: FontWeight.w500,
      fontSize: 34,
    );

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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 18, right: 18),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Sorting", style: heading2Style),
                              Icon(
                                Icons.sports_esports_outlined,
                                color: theme.colorScheme.onBackground,
                                size: 30,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: FutureBuilder(
                            future: incompletesExist(context),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      left: 65, right: 65),
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Text("${snapshot.error}");
                              }
                              if (snapshot.data == null) {
                                return Text("No data");
                              }
                              if (snapshot.data == false) {
                                // there are no incomplete tests
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
                            },
                          ),
                        ),
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
                        Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: CardRowItem(
                              text: "Your Sorts",
                              icon: Icons.person_2_outlined,
                              nextPage: ResultsLoader()),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 18, right: 18),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Results", style: heading2Style),
                              Icon(
                                Icons.history,
                                color: theme.colorScheme.onBackground,
                                size: 30,
                              ),
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
                                Tooltip(
                                  message: "Sign Out",
                                  child: IconButton(
                                    onPressed: () async {
                                      print("Signing out...");
                                      await storage.write(
                                          key: "jwt", value: "lol");
                                      appState.changePage(LoadingPage());
                                    },
                                    icon: Icon(Icons.logout_rounded),
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
