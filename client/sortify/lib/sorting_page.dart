import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';

class SortingPage extends StatefulWidget {
  const SortingPage({super.key});

  @override
  State<SortingPage> createState() => _SortingPageState();
}

class _SortingPageState extends State<SortingPage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displayLarge!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w400,
    );

    return Center(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(40),
            child: Text("Configure Sort", style: titleStyle),
          ),
          Expanded(
            child: Row(
              children: [
                // LEFT PANEL
                Flexible(
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: <Widget>[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 30),
                          child: Text(
                            "Filters",
                            style: theme.textTheme.headlineMedium,
                          ),
                        ),
                      ),
                      Center(
                        child: Text("Add filters to select the songs for sorting"),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top:12, bottom:12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 100,
                              child: AspectRatio(
                                aspectRatio: 1 / 1,
                                child: Card(
                                  clipBehavior: Clip.hardEdge,
                                  color: theme.colorScheme.primaryContainer,
                                  child: InkWell(
                                      splashColor: theme.colorScheme.primary,
                                      onTap: () {},
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text("+",
                                              style: theme.textTheme.headlineMedium),
                                          Text("Add Filter"),
                                        ],
                                      )),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // RIGHT PANEL
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: <Widget>[
                      SizedBox(
                        height: 60,
                        child: Card(
                          clipBehavior: Clip.hardEdge,
                          color: theme.colorScheme.secondaryContainer,
                          child: Column(
                            children: [
                              Text("The Lovue"),
                              Text("Lorde")
                            ],
                          )
                        ),
                      ),
                      SizedBox(
                        height: 60,
                        child: Card(
                          clipBehavior: Clip.hardEdge,
                          color: theme.colorScheme.secondaryContainer,
                          child: Column(
                            children: [
                              Text("Bite Me"),
                              Text("Avril Lavigne")
                            ],
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
