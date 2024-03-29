import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';

class SortParameter extends StatefulWidget {
  const SortParameter({super.key, required this.id, required this.onDelete});

  final int id;
  final Function(int) onDelete;

  @override
  State<SortParameter> createState() => _SortParameterState();
}

class _SortParameterState extends State<SortParameter> {
  final TextEditingController nameController = TextEditingController();
  var typeSelected = "Artist";
  var actionSelected = "Include";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                child: Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 25),
                          child: SizedBox(
                            width: 280,
                            child: TextField(
                              controller: nameController,
                              decoration: InputDecoration(labelText: "Name"),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 30, top: 8, bottom: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Type"),
                          DropdownButton<String>(
                            value: typeSelected,
                            onChanged: (String? newValue) {
                              setState(() {
                                typeSelected = newValue!;
                              });
                            },
                            items: <String>["Artist", "Album"]
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Action"),
                          DropdownButton<String>(
                            value: actionSelected,
                            onChanged: (String? newValue) {
                              setState(() {
                                actionSelected = newValue!;
                              });
                            },
                            items: <String>["Include", "Exclude"]
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15, right: 15),
                      child: IconButton(
                          onPressed: () {
                            print("yo ${widget.id}");
                            widget.onDelete(widget.id);
                          },
                          icon: Icon(Icons.delete_outlined)),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SortingPage extends StatefulWidget {
  const SortingPage({super.key});

  @override
  State<SortingPage> createState() => _SortingPageState();
}

class _SortingPageState extends State<SortingPage> {
  List<SortParameter> filterWidgets = [];

  @override
  void initState() {
    super.initState();

    // filterWidgets.add(SortParameter(id: 0, onDelete: _deleteFilterWidget));
  }

  // prevent duplicate IDs
  var maxId = 0;
  // remove filter widget
  void _deleteFilterWidget(int id) {
    setState(() {
    filterWidgets.removeWhere((widget) => widget.id == id);
  });
  }

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
            padding: const EdgeInsets.only(top: 40, bottom: 60),
            child: Text("Configure Sort", style: titleStyle),
          ),
          Expanded(
            child: Row(
              children: [
                // LEFT PANEL
                Flexible(
                  child: ListView(
                    addAutomaticKeepAlives: true,
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
                        child:
                            Text("Add filters to select the songs for sorting"),
                      ),
                      // ADD FILTER BUTTON
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 12),
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
                                      onTap: () {
                                        // add a new SortParameter widget to list
                                        setState(() {
                                          filterWidgets.add(SortParameter(
                                            key: UniqueKey(),
                                            id: maxId + 1, // create unused ID
                                            onDelete: _deleteFilterWidget,
                                          ));
                                        });
                                        maxId++;
                                        print(maxId);
                                      },
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text("+",
                                              style: theme
                                                  .textTheme.headlineMedium),
                                          Text("Add Filter"),
                                        ],
                                      )),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...filterWidgets,
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
                              children: [Text("The Lovue"), Text("Lorde")],
                            )),
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
                            )),
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
