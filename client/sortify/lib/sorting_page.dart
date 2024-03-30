import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'dart:convert';

import 'app_state.dart';

final storage = FlutterSecureStorage();

Future<void> populateSongs(List<SortParameter> filters) async {
  SongManager selections = SongManager();

  // load names of selections into object
  for (int i = 0; i < filters.length; i++) {
    SortParameter filter = filters[i];
    if (filter.typeSelected == "Artist") {
      selections.addArtist(Artist(name: filter.valueController.text));
    } else if (filter.typeSelected == "Album") {
      selections.addAlbum(Album(name: filter.valueController.text));
    }
  }
  // fetch and parse api data for artists
  for (final artist in selections.artists) {
    final artistData =
        jsonDecode(await querySpotify(artist.name, "artist", 1, 0))
            as Map<String, dynamic>;
    artist.id = artistData["artists"]["items"][0]["uri"];
    artist.followers = artistData["artists"]["items"][0]["followers"]["total"];
    artist.imageUrl = artistData["artists"]["items"][0]["images"][0]["url"];
  }
  // fetch and parse api data for artists
  for (final album in selections.albums) {
    final albumData = jsonDecode(await querySpotify(album.name, "album", 1, 0))
        as Map<String, dynamic>;
    album.id = albumData["albums"]["items"][0]["id"];
    album.imageUrl = albumData["albums"]["items"][0]["images"][0]["url"];
    album.releaseDate = albumData["albums"]["items"][0]["release_date"];
    // fetch and parse album tracks
  }
}

// track holding classes
class SongManager {
  List<Artist> artists = [];
  List<Album> albums = [];

  void addArtist(Artist artist) {
    artists.add(artist);
  }

  void addAlbum(Album album) {
    albums.add(album);
  }
}

class Artist {
  String name;
  int followers = -1;
  String _imageUrl = "";
  String id = "";
  List<Album> _albums = [];

  Artist({
    required this.name,
  });

  set imageUrl(String url) {
    if (_validateUrl(url)) {
      _imageUrl = url;
      return;
    }
    throw ArgumentError("Image URL is not valid");
  }

  static bool _validateUrl(String url) {
    // TODO: VERIFY REGEX MATCHING
    final RegExp urlRegex =
        RegExp(r"^(?:https:|http:)\/\/i\.scdn\.co\/image\/[\w]+$");
    return urlRegex.hasMatch(url);
  }
}

class Album {
  String name;
  String releaseDate = "";
  String imageUrl = "";
  String id = "";
  List<Track> tracks = [];

  Album({
    required this.name,
  });
}

class Track {
  String name;
  String releaseDate;
  String imageUrl;
  String id;

  Track({
    required this.name,
    required this.releaseDate,
    required this.imageUrl,
    required this.id,
  });
}

// list of filter widgets
List<SortParameter> filterWidgets = [];
// search for artist, album, or track
// name: name of item, type: "artist", "album", or "track"
Future<String> querySpotify(
    String name, String type, int limit, int offset) async {
  final queryParameters = {
    "query": "$type:$name",
    "type": type,
    "limit": limit.toString(),
    "offset": offset.toString(),
  };
  // USE Uri.https FOR HTTPS
  final uri = Uri.http("localhost:3004", "/spotify/search/", queryParameters);
  final storedJwt = await storage.read(key: "jwt");
  final response = await http.post(
    uri,
    headers: <String, String>{
      HttpHeaders.authorizationHeader: "Bearer $storedJwt",
    },
  );

  if (response.statusCode == 200) {
    return response.body;
  }
  if (response.statusCode == 401) {
    throw UnimplementedError("Login Popup");
  }
  throw Exception(response.body);
}

// filter widget
class SortParameter extends StatefulWidget {
  SortParameter({super.key, required this.id, required this.onDelete});
  final int id;
  final Function(int) onDelete;

  final TextEditingController valueController = TextEditingController();
  String typeSelected = "Artist";
  String actionSelected = "Include";

  @override
  State<SortParameter> createState() => _SortParameterState();
}

class _SortParameterState extends State<SortParameter> {
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
                            width: 230,
                            child: TextField(
                              controller: widget.valueController,
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
                            value: widget.typeSelected,
                            onChanged: (String? newValue) {
                              setState(() {
                                widget.typeSelected = newValue!;
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
                            value: widget.actionSelected,
                            onChanged: (String? newValue) {
                              setState(() {
                                widget.actionSelected = newValue!;
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
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displayLarge!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
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
                              height: 98,
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
                      ...filterWidgets, // dynamically updated by list
                      if (filterWidgets.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                height: 45,
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(theme
                                              .colorScheme.primaryContainer)),
                                  onPressed: () {
                                    // final result = await querySpotify(
                                    //     "Lorde", "artist", 10, 0);
                                    // print(result.toString());
                                    populateSongs(filterWidgets);
                                  },
                                  child: Text("Use Filters"),
                                ),
                              ),
                            ),
                          ],
                        )
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
