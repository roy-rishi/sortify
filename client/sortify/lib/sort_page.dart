import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sortify/home_page.dart';
import 'package:sortify/results_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'filter_page.dart';
import 'app_state.dart';
import 'constants.dart';

final storage = FlutterSecureStorage();

// display loading icon until sort data is acquired from server
class SortPageLoader extends StatelessWidget {
  final int sortKey;

  const SortPageLoader({Key? key, required this.sortKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: loadSort(sortKey),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        } else {
          Map<String, dynamic> data = json.decode(snapshot.data!);
          List<dynamic> tracksJson = json.decode(data["Songs"]);
          List<Track> tracks =
              tracksJson.map((element) => Track.fromJson(element)).toList();

          List<bool> comparisons = [];

          if (data["Comparisons"] != null) {
            List<dynamic> comparisonsData = json.decode(data["Comparisons"]);
            comparisons =
                comparisonsData.map((element) => element == "true").toList();
          }

          return SortPage(
            sortKey: sortKey,
            tracks: tracks,
            initialComparisons: comparisons,
          );
        }
      },
    );
  }
}

Future<String> loadSort(int sortKey) async {
  final storedJwt = await storage.read(key: "jwt");
  final response = await http.get(
      Uri.parse(
          "$HTTP_PROTOCOL$SERVER_BASE_URL/get-incomplete-sort?key=$sortKey"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: "Bearer $storedJwt",
      });

  if (response.statusCode == 200) {
    return response.body;
  }
  if (response.statusCode == 401) {
    throw Exception("Need to login");
  }
  throw Exception(response.body);
}

class Sort {
  final List<Track> songs;
  List<bool> comparisons = [];
  // int _index = 0;
  int _index = 0;

  Sort({
    required this.songs,
    required this.comparisons,
  });

  // add the result of a comparison use submits
  void addComparisonResult(bool result) {
    comparisons.add(result);
  }

  // get next pair of comparisons, return full list if sorted
  List<Track> nextPair() {
    _index = 0;
    List<Track> copy = List.from(songs);

    int width = 1;
    int n = copy.length;
    while (width < n) {
      int l = 0;
      while (l < n) {
        int r = min(l + (width * 2 - 1), n - 1);
        int m = min(l + width - 1, n - 1);
        List<Track>? nextPair = merge(copy, l, m, r);
        if (nextPair != null) {
          return nextPair;
        }
        l += width * 2;
      }
      width *= 2;
    }
    return copy;
    // return arr;
  }

  // merge handler, return next comparison set, if no more, return null
  List<Track>? merge(List<Track> copy, int l, int m, int r) {
    int n1 = m - l + 1;
    int n2 = r - m;
    List<Track> L = List.from(copy.sublist(l, m + 1));
    List<Track> R = List.from(copy.sublist(m + 1, r + 1));

    int i = 0, j = 0, k = l;
    while (i < n1 && j < n2) {
      if (_index >= comparisons.length || comparisons.isEmpty) {
        return [L[i], R[j]];
      }

      if (comparisons[_index]) {
        copy[k] = L[i];
        i++;
      } else {
        copy[k] = R[j];
        j++;
      }
      k++;
      _index++;
    }

    while (i < n1) {
      copy[k] = L[i];
      i++;
      k++;
    }

    while (j < n2) {
      copy[k] = R[j];
      j++;
      k++;
    }
    return null;
  }
}

class SongCard extends StatelessWidget {
  const SongCard({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameStyle = theme.textTheme.labelLarge!.copyWith(
      // color: theme.colorScheme.secondary,
      fontWeight: FontWeight.w700,
      fontSize: 17.5,
    );
    final albumStyle = theme.textTheme.labelLarge!.copyWith(
      // color: theme.colorScheme.secondary,
      fontWeight: FontWeight.w400,
      fontSize: 16.5,
    );
    final artistSyle = theme.textTheme.bodySmall!.copyWith(
      fontSize: 13.5,
    );

    return Tooltip(
      message: "${track.name} - ${track.albumName}, ${track.artistName}\n",
      child: SizedBox(
        width: 300,
        child: Card(
          clipBehavior: Clip.hardEdge,
          // color: theme.colorScheme.secondaryContainer,
          child: Center(
            child: Column(
              children: [
                Image.network(track.imageUrl, fit: BoxFit.fitWidth),
                Padding(
                  padding: const EdgeInsets.only(top: 14, left: 12, right: 12),
                  child: RichText(
                    // Restrict to single line
                    overflow: TextOverflow.fade,
                    maxLines: 1,
                    softWrap: false,
                    text: TextSpan(
                      children: <TextSpan>[
                        TextSpan(text: track.name, style: nameStyle),
                        TextSpan(
                            text: " – ${track.albumName}", style: albumStyle),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 18),
                  child: Text(track.artistName, style: artistSyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SortPage extends StatefulWidget {
  const SortPage(
      {super.key,
      required this.sortKey,
      required this.tracks,
      required this.initialComparisons});

  final int sortKey;
  final List<Track> tracks;
  final List<bool> initialComparisons;

  @override
  State<SortPage> createState() => _SortPageState();
}

class _SortPageState extends State<SortPage> {
  // List<Track> sortingList = [];
  late final Sort sortStates;
  // tracks to display on sorting page
  late Track left;
  late Track right;
  // sync status
  String syncStatus = "";
  bool isSyncing = false;
  // need to redirect home
  bool goHome = false;

  Future<String> uploadComparison(
      {required int sortKey, required bool value, required int size}) async {
    // prevent simultaneous requests by preventing repeated button clicks
    setState(() {
      syncStatus = "Saving...";
      isSyncing = true;
    });
    final storedJwt = await storage.read(key: "jwt");

    final response = await http.post(
      Uri.parse("$HTTP_PROTOCOL$SERVER_BASE_URL/add-comparison"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: "Bearer $storedJwt"
      },
      body: jsonEncode(<String, dynamic>{
        "key": sortKey,
        "value": value,
        "size": size,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        syncStatus = response.body;
        isSyncing = false;
      });
      return response.body;
    }
    if (response.body == "This incomplete no longer exists") {
      _deletedSortAlert();
      return "";
    }
    if (response.body ==
        "Unable to add comparison; this sorting session is behind the database") {
      // the client is behind the server, need to download progress
      Map<String, dynamic> data = json.decode(await loadSort(sortKey));
      setState(() {
        // convert to List<bool>
        sortStates.comparisons =
            (json.decode(data["Comparisons"]) as List<dynamic>).map((element) {
          if (element is bool) {
            return element;
          } else if (element is String) {
            if (element.toLowerCase() == "true") {
              return true;
            } else if (element.toLowerCase() == "false") {
              return false;
            }
          }
          throw FormatException('Invalid boolean value: $element');
        }).toList();
        syncStatus = "Restored";
        isSyncing = false;

        List<Track> nextPair = sortStates.nextPair();
        left = nextPair[0];
        right = nextPair[1];
      });
      _refreshedContentAlert();
      return response.body;
    }
    throw Exception(response.body);
  }

  Future<void> _refreshedContentAlert() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Restored Content"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("Your progress from other devices has been restored."),
                Text(
                    "You are now on Battle ${sortStates.comparisons.length + 1}"),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Continue"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletedSortAlert() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Sort No Longer Exists"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("This sort may have been deleted or completed."),
                Text("Create a new sort, or view your past results."),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Continue"),
              onPressed: () {
                setState(() {
                  goHome = true;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> saveCompletedSort(List<Track> songs) async {
    final storedJwt = await storage.read(key: "jwt");

    List<Map<String, dynamic>> trackMaps = [];
    for (Track track in songs) {
      trackMaps.add(track.toMap());
    }

    final response = await http.post(
      Uri.parse("$HTTP_PROTOCOL$SERVER_BASE_URL/add-completed-sort"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: "Bearer $storedJwt"
      },
      body: jsonEncode(<String, dynamic>{
        "songs": jsonEncode(trackMaps),
      }),
    );

    if (response.statusCode == 200) {
      return response.body;
    }
    throw Exception(response.body);
  }

  Future<String> deleteIncompleteSort(int sortKey) async {
    final storedJwt = await storage.read(key: "jwt");

    final response = await http.post(
      Uri.parse("$HTTP_PROTOCOL$SERVER_BASE_URL/delete-incomplete-sort"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        HttpHeaders.authorizationHeader: "Bearer $storedJwt"
      },
      body: jsonEncode(<String, dynamic>{
        "key": sortKey,
      }),
    );

    if (response.statusCode == 200) {
      return response.body;
    }
    throw Exception(response.body);
  }

  @override
  void initState() {
    super.initState();
    sortStates =
        Sort(songs: widget.tracks, comparisons: widget.initialComparisons);
    List<Track>? firstPair = sortStates.nextPair();
    left = firstPair[0];
    right = firstPair[1];
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displayLarge!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
    );
    final syncStyle = theme.textTheme.headlineSmall!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w300,
      fontSize: 19,
    );

    // redirect to home page
    if (goHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.changePage(HomePage());
      });
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Text("Battle", style: titleStyle),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(syncStatus, style: syncStyle),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    SongCard(track: left),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          // disable button while syncing
                          onPressed: isSyncing
                              ? null
                              : () {
                                  sortStates.addComparisonResult(true);
                                  List<Track> nextPair = sortStates.nextPair();
                                  // if not a set of two, sorting is done
                                  if (nextPair.length >=
                                      sortStates.songs.length) {
                                    saveCompletedSort(nextPair);
                                    appState.changePage(ResultsLoader());
                                  } else {
                                    setState(() {
                                      left = nextPair[0];
                                      right = nextPair[1];
                                    });
                                    // sync with server
                                    uploadComparison(
                                        sortKey: widget.sortKey,
                                        value: true,
                                        size: sortStates.comparisons.length);
                                  }
                                },
                          child: Text("Select"),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    SongCard(track: right),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          // disable button while syncing
                          onPressed: isSyncing
                              ? null
                              : () {
                                  sortStates.addComparisonResult(false);
                                  List<Track> nextPair = sortStates.nextPair();
                                  // if not a set of two, sorting is done
                                  if (nextPair.length >=
                                      sortStates.songs.length) {
                                    saveCompletedSort(nextPair);
                                    appState.changePage(ResultsLoader());
                                  } else {
                                    setState(() {
                                      left = nextPair[0];
                                      right = nextPair[1];
                                    });
                                    // sync with server
                                    uploadComparison(
                                        sortKey: widget.sortKey,
                                        value: false,
                                        size: sortStates.comparisons.length);
                                  }
                                },
                          child: Text("Select"),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Tooltip(
              message: "Save and Exit",
              child: IconButton(
                color: theme.colorScheme.secondary,
                onPressed: () {
                  setState(() {
                    goHome = true;
                  });
                },
                icon: Icon(Icons.arrow_back_ios_new_rounded),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: Card.outlined(
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 12, right: 12, top: 8, bottom: 8),
                  child: Text("Set ${sortStates.comparisons.length + 1}",
                      style: theme.textTheme.bodyLarge),
                ),
              ),
            ),
            Tooltip(
              message: "Delete Permanently",
              child: IconButton(
                color: theme.colorScheme.secondary,
                onPressed: () async {
                  final res = await deleteIncompleteSort(widget.sortKey);
                  setState(() {
                    goHome = true;
                  });
                },
                icon: Icon(Icons.delete_outline_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
