import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sortify/home_page.dart';
import 'package:sortify/sort_page.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:collection';

import 'app_state.dart';
import 'constants.dart';

final storage = FlutterSecureStorage();

// create a sort, return server-provided id
Future<int> createSort(String tracksJson) async {
  final storedJwt = await storage.read(key: "jwt");
  final response = await http.post(
    Uri.parse("$HTTP_PROTOCOL$SERVER_BASE_URL/create-sort"),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      HttpHeaders.authorizationHeader: "Bearer $storedJwt",
    },
    body: jsonEncode(<String, String>{
      "songs": tracksJson,
    }),
  );

  if (response.statusCode == 200) {
    return int.parse(response.body);
  }
  if (response.statusCode == 401) {
    throw Exception("Login page");
  }
  throw Exception(response.body);
}

List<SongRow> tracksToSort = [];

class SongRow extends StatelessWidget {
  const SongRow({
    super.key,
    required this.track,
    required this.image,
  });

  final Track track;
  final Image image;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nameStyle = theme.textTheme.labelLarge!.copyWith(
      // color: theme.colorScheme.secondary,
      fontWeight: FontWeight.w500,
      fontSize: 16,
    );
    final bodyStyle = theme.textTheme.bodySmall!.copyWith(
      fontSize: 13,
    );

    final String name = track.name;
    final String artist = track.artistName;
    final String albumName = track.albumName;
    final String releaseDate = track.releaseDate;

    return SizedBox(
      height: 65,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 40),
        child: Card(
          clipBehavior: Clip.antiAlias,
          // color: theme.colorScheme.secondaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 9),
                    child: Tooltip(
                        message: "$name - $albumName, $artist", child: image),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // align text
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: nameStyle),
                      Text(artist, style: bodyStyle),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 50, right: 50),
                  child: Center(
                    child: Text(albumName,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: bodyStyle),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 30),
                child: Text(releaseDate, style: bodyStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<List<SongRow>> calculateSongs(List<SortParameter> filters) async {
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
    artist.id = artistData["artists"]["items"][0]["id"];
    artist.followers = artistData["artists"]["items"][0]["followers"]["total"];
    artist.imageUrl = artistData["artists"]["items"][0]["images"][0]["url"];
    // fetch and parse api data for artist albums
    final artistAlbumData =
        jsonDecode(await artistAlbumsSpotify(artist.id, 50, 0))
            as Map<String, dynamic>;
    for (int i = 0; i < artistAlbumData["items"].length; i++) {
      bool sameArtist = false;
      for (int j = 0; j < artistAlbumData["items"][i]["artists"].length; j++) {
        if (artistAlbumData["items"][i]["artists"][j]["id"] == artist.id) {
          sameArtist = true;
        }
      }
      if (!sameArtist) {
        break;
      }
      final newAlbum = Album(name: artistAlbumData["items"][i]["name"]);
      newAlbum.id = artistAlbumData["items"][i]["id"];
      newAlbum.artistName = artist.name;
      newAlbum.imageUrl = artistAlbumData["items"][i]["images"][0]["url"];
      newAlbum.releaseDate = artistAlbumData["items"][i]["release_date"];
      artist.albums.add(newAlbum);
    }
  }
  // fetch and parse api data for albums
  for (final album in selections.albums) {
    final albumData = jsonDecode(await querySpotify(album.name, "album", 1, 0))
        as Map<String, dynamic>;
    album.id = albumData["albums"]["items"][0]["id"];
    album.artistName = albumData["albums"]["items"][0]["artists"][0]["name"];
    album.imageUrl = albumData["albums"]["items"][0]["images"][0]["url"];
    album.releaseDate = albumData["albums"]["items"][0]["release_date"];
  }
  // fetch and parse album tracks
  List<Album> allAlbums = selections.albums;
  for (final artist in selections.artists) {
    for (final album in artist.albums) {
      allAlbums.add(album);
    }
  }
  for (final album in allAlbums) {
    final tracksData = jsonDecode(await albumTracksSpotify(album.id, 50, 0))
        as Map<String, dynamic>;

    for (int i = 0; i < tracksData["items"].length; i++) {
      final track = tracksData["items"][i];
      album.tracks.add(Track(
          name: track["name"],
          albumName: album.name,
          artistName: album.artistName,
          id: track["id"],
          releaseDate: album.releaseDate,
          imageUrl: album.imageUrl));
    }
  }

  List<Track> finalTracks = selections.computeAllTracks();
  // remove duplicates
  finalTracks = LinkedHashSet<Track>.from(finalTracks).toList();

  List<SongRow> songRows = [];
  for (final track in finalTracks) {
    final image = Image.network(track.imageUrl);
    songRows.add(SongRow(track: track, image: image));
  }
  return songRows;
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

  List<Track> computeAllTracks() {
    List<Track> allTracks = [];

    for (final artist in artists) {
      for (final album in artist.albums) {
        for (final track in album.tracks) {
          allTracks.add(track);
        }
      }
    }
    for (final album in albums) {
      for (final track in album.tracks) {
        allTracks.add(track);
      }
    }
    return allTracks;
  }
}

class Artist {
  String name;
  int followers = -1;
  String _imageUrl = "";
  String id = "";
  List<Album> albums = [];

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
  String artistName = "";
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
  String albumName;
  String artistName;
  String releaseDate;
  String imageUrl;
  String id;

  Track({
    required this.name,
    required this.albumName,
    required this.artistName,
    required this.releaseDate,
    required this.imageUrl,
    required this.id,
  });

  @override
  bool operator ==(Object other) =>
      other is Track && name == other.name && artistName == other.artistName;

  @override
  int get hashCode => Object.hash(name, artistName);

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "albumName": albumName,
      "artistName": artistName,
      "releaseDate": releaseDate,
      "imageUrl": imageUrl,
      "id": id,
    };
  }

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      name: json["name"] as String,
      albumName: json["albumName"] as String,
      artistName: json["artistName"] as String,
      imageUrl: json["imageUrl"] as String,
      releaseDate: json["releaseDate"] as String,
      id: json["id"] as String,
    );
  }
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
  final uri = Uri.https(SERVER_BASE_URL, "/spotify/search/", queryParameters);
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

Future<String> artistAlbumsSpotify(String id, int limit, int offset) async {
  final queryParameters = {
    "id": id,
    "limit": limit.toString(),
    "offset": offset.toString(),
  };
  // USE Uri.https FOR HTTPS
  final uri =
      Uri.https(SERVER_BASE_URL, "/spotify/artist-albums/", queryParameters);
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

Future<String> albumTracksSpotify(String id, int limit, int offset) async {
  final queryParameters = {
    "id": id,
    "limit": limit.toString(),
    "offset": offset.toString(),
  };
  // USE Uri.https FOR HTTPS
  final uri =
      Uri.https(SERVER_BASE_URL, "/spotify/album-tracks/", queryParameters);
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
                            width: 180,
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

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  // prevent duplicate IDs
  var maxId = 0;
  // remove filter widget
  void _deleteFilterWidget(int id) {
    setState(() {
      filterWidgets.removeWhere((widget) => widget.id == id);
    });
  }

  bool calculatingTracksToSort = false;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displayLarge!.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    return Center(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  appState.changePage(HomePage());
                },
                icon: Icon(Icons.arrow_back_ios_new_rounded),
                color: theme.colorScheme.secondary,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 40, bottom: 50),
                child: Text("Configure Sort", style: titleStyle),
              ),
            ],
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
                                  onPressed: () async {
                                    setState(() {
                                      tracksToSort.clear();
                                      calculatingTracksToSort = true;
                                    });
                                    final songs =
                                        await calculateSongs(filterWidgets);
                                    setState(() {
                                      for (final song in songs) {
                                        tracksToSort.add(song);
                                      }
                                      calculatingTracksToSort = false;
                                    });
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
                    physics: BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    children: <Widget>[
                      // if loading icon should be displayed
                      if (calculatingTracksToSort)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                SizedBox(
                                  // height: 40,
                                  // width: 40,
                                  child: CircularProgressIndicator(
                                    value: null,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Text("Getting songs from Spotify"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      if (!calculatingTracksToSort && tracksToSort.isEmpty)
                        Center(
                            child: Text("Edit your filters to include songs")),
                      // if continue button should be displayed
                      if (!calculatingTracksToSort && tracksToSort.isNotEmpty)
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 45,
                                  child: ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                theme.colorScheme
                                                    .primaryContainer)),
                                    onPressed: () async {
                                      List<Map<String, dynamic>> trackMaps = [];
                                      for (SongRow songRow in tracksToSort) {
                                        Track track = songRow.track;
                                        trackMaps.add(track.toMap());
                                      }
                                      final int key = (await createSort(jsonEncode(trackMaps)));
                                      appState
                                          .changePage(SortPageLoader(sortKey: key));
                                    },
                                    child: Text("Start Sorting"),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                  "${tracksToSort.length} Results, Approximately ${(tracksToSort.length * log(tracksToSort.length)).round()} Battles"),
                            ),
                          ],
                        ),
                      ...tracksToSort, // populate the right panel of songs
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
