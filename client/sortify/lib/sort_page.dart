import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sortify/results_page.dart';

import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'filter_page.dart';
import 'app_state.dart';
import 'constants.dart';

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
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        } else {
          List<Track> tracks = parseTracks(snapshot.data!);
          return SortPage(sortKey: sortKey, tracks: tracks);
        }
      },
    );
  }

  List<Track> parseTracks(String songsJson) {
    // Parse the JSON and convert it to a List<Track>
    List<dynamic> tracksJson = json.decode(songsJson);
    List<Track> tracks =
        tracksJson.map((json) => Track.fromJson(json)).toList();
    return tracks;
  }
}

Future<String> loadSort(int sortKey) async {
  final response = await http.get(
      Uri.parse("$HTTP_PROTOCOL$SERVER_BASE_URL/get-sort?key=$sortKey"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      });

  if (response.statusCode == 200) {
    return response.body;
  }
  throw Exception(response.body);
}

class Sort {
  final List<Track> songs;
  List<bool> _comparisons = [];
  int _index = 0;

  Sort({
    required this.songs,
  });

  // add the result of a comparison use submits
  void addComparisonResult(bool result) {
    _comparisons.add(result);
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
          print(_comparisons);
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
      if (_index >= _comparisons.length || _comparisons.isEmpty) {
        return [L[i], R[j]];
      }

      if (_comparisons[_index]) {
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
  const SortPage({super.key, required this.sortKey, required this.tracks});

  final int sortKey;
  final List<Track> tracks;

  @override
  State<SortPage> createState() => _SortPageState();
}

class _SortPageState extends State<SortPage> {
  int sortCount = 1;
  List<Track> sortingList = [];
  late final Sort sortStates;
  // tracks to display on sorting page
  late Track left;
  late Track right;

  @override
  void initState() {
    super.initState();
    sortStates = Sort(songs: widget.tracks);
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text("Battle", style: titleStyle),
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
                          onPressed: () {
                            sortStates.addComparisonResult(true);
                            List<Track> nextPair = sortStates.nextPair();
                            // if not a set of two, sorting is done
                            if (nextPair.length == tracksToSort.length) {
                              appState
                                  .changePage(ResultsPage(tracks: nextPair));
                            } else {
                              setState(() {
                                left = nextPair[0];
                                right = nextPair[1];
                                sortCount++;
                              });
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
                          onPressed: () {
                            sortStates.addComparisonResult(false);
                            List<Track> nextPair = sortStates.nextPair();
                            // if not a set of two, sorting is done
                            if (nextPair.length == tracksToSort.length) {
                              appState
                                  .changePage(ResultsPage(tracks: nextPair));
                            } else {
                              setState(() {
                                left = nextPair[0];
                                right = nextPair[1];
                                sortCount++;
                              });
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
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Set $sortCount", style: theme.textTheme.bodyLarge),
          ),
        ),
      ],
    );
  }
}
