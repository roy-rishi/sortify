import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:sortify/app_state.dart';
import 'filter_page.dart';
import 'constants.dart';
import 'home_page.dart';
import 'login_popup.dart';

final storage = FlutterSecureStorage();

Future<List<dynamic>> loadResults(BuildContext context) async {
  final storedJwt = await storage.read(key: "jwt");

  final response = await http.get(
      Uri.parse("$HTTP_PROTOCOL$SERVER_BASE_URL/all-sorts"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: "Bearer $storedJwt",
      });

  if (response.statusCode == 200) {
    return json.decode(response.body);
  }
  if (response.statusCode == 401 || response.body == "Jwt is expired") {
    await LoginPopup.displayLogin(context);
  }
  throw Exception(response.body);
}

class ResultCard extends StatefulWidget {
  const ResultCard(
      {super.key,
      required this.date,
      required this.songs,
      required this.filters});

  final String date;
  final List<SongRow> songs;
  final List<dynamic> filters;

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
  Future<void> _songsListPopup() async {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.headlineMedium!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text("Your Sort", style: titleStyle)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                SizedBox(
                  width: 600,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...widget.songs,
                    ],
                  ),
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Go Back"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStyle = theme.textTheme.headlineMedium!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    final timeStyle = theme.textTheme.bodyLarge!.copyWith(
      color: theme.colorScheme.secondary,
      fontWeight: FontWeight.w600,
    );
    final includedStyle = theme.textTheme.bodyLarge!.copyWith(
      color: theme.colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );
    final excludedStyle = theme.textTheme.bodyLarge!.copyWith(
      color: theme.colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.w500,
      fontSize: 14,
      decoration: TextDecoration.lineThrough,
    );

    // load filters into spans with styles
    List<TextSpan> spans = [];
    for (int i = 0; i < widget.filters.length; i++) {
      Map<String, dynamic> filter = widget.filters[i];
      // for (Map<String, dynamic> filter in widget.filters) {
      String name = filter["name"];
      bool included = filter["included"];
      TextSpan span =
          TextSpan(text: name, style: included ? includedStyle : excludedStyle);
      spans.add(span);

      // add comma behind, if not last filter
      if (i < widget.filters.length - 1) {
        TextSpan commaSpan = TextSpan(text: ", ", style: includedStyle);
        spans.add(commaSpan);
      }
    }

    return Center(
      child: SizedBox(
        width: 440,
        child: Card.filled(
          color: theme.colorScheme.primaryContainer,
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            splashColor: theme.colorScheme.primary,
            onTap: () {
              _songsListPopup();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 20, top: 12, bottom: 12),
                        child: Text(widget.date.split(", ")[0], style: dateStyle),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: RichText(
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                            softWrap: false,
                            text: TextSpan(
                              children: <TextSpan>[
                                ...spans,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(widget.date.split(", ")[1], style: timeStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ResultsLoader extends StatelessWidget {
  const ResultsLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: loadResults(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          } else if (snapshot.data == null) {
            throw Exception("No data");
          }

          List<ResultCard> results = [];

          List<dynamic> rows = snapshot.data as List<dynamic>;
          // loop over each row, in order of most recent first
          for (int i = rows.length - 1; i >= 0; i--) {
            Map<String, dynamic> row = rows[i];
            // create date string
            DateTime date = DateTime.fromMillisecondsSinceEpoch(
                json.decode(row["Date"]).round());
            DateFormat formatter = DateFormat('MMM d, h:mm a');
            String formattedDate = formatter.format(date);
            List<SongRow> songRows = [];
            // get filters
            if (row["Filters"] == null) {
              print("Filters are missing");
              continue;
            }
            List<dynamic> filters = json.decode(row["Filters"]);

            try {
              List<dynamic> tracks = json.decode(row["Songs"]);
              // loop over each sorted track
              for (Map<String, dynamic> track in tracks) {
                final String name = track["name"];
                final String albumName = track["albumName"];
                final String artistName = track["artistName"];
                final String releaseDate = track["releaseDate"];
                final String id = track["id"];
                final String imageUrl = track["imageUrl"];

                final Image image = Image.network(imageUrl);
                Track t = Track(
                  name: name,
                  albumName: albumName,
                  artistName: artistName,
                  releaseDate: releaseDate,
                  imageUrl: imageUrl,
                  id: id,
                );
                final SongRow songRow = SongRow(image: image, track: t);
                songRows.add(songRow);
              }

              results.add(ResultCard(
                date: formattedDate,
                songs: songRows,
                filters: filters,
              ));
            } on FormatException {
              // if one of the table's rows cannot be parsed, skip it
              print("Could not parse row");
              continue;
            }
          }
          return ResultsPage(results: results);
        });
  }
}

class ResultsPage extends StatefulWidget {
  ResultsPage({super.key, required this.results});

  List<ResultCard> results;

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late List<SongRow> songRows = [];

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displayLarge!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    return ListView(
      physics: BouncingScrollPhysics(),
      children: <Widget>[
        Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40, bottom: 40),
                child: Text("Results", style: titleStyle),
              ),
            ),
            Positioned(
              top: 55, // Adjust this value as needed
              left: MediaQuery.of(context).size.width / 2 -
                  200, // Adjust this value as needed
              child: IconButton(
                onPressed: () {
                  appState.changePage(HomePage());
                },
                icon: Icon(Icons.arrow_back_ios_new_rounded),
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        if (widget.results.isNotEmpty) ...widget.results,
        if (widget.results.isEmpty)
          Center(child: Text("You haven't completed any sorts"))
      ],
    );
  }
}
