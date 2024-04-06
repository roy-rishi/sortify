import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sortify/filter_page.dart';

import 'app_state.dart';

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
    const double paddingDist = 18;

    return Padding(
      padding: const EdgeInsets.only(
          top: paddingDist, bottom: paddingDist, right: paddingDist / 2, left: paddingDist / 2),
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displayLarge!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
      fontSize: 80,
    );
    final heading2Style = theme.textTheme.headlineMedium;


    return Center(
      child: SizedBox(
        width: 670,
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
                        CardRowItem(
                            text: "Start Round",
                            icon: Icons.play_arrow_outlined,
                            nextPage: FilterPage()),
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
                            nextPage: const Text("Your Sortszes")),
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
                                IconButton(
                                  onPressed: () {
                                    print("Pressed");
                                  },
                                  icon: Icon(Icons.settings_outlined),
                                  color: theme.colorScheme.primary,
                                ),
                                IconButton(
                                  onPressed: () {
                                    print("Pressed");
                                  },
                                  icon: Icon(Icons.logout_rounded),
                                  color: theme.colorScheme.primary,
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
