import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'filter_page.dart';

class ResultsPage extends StatefulWidget {
  ResultsPage({super.key, required this.tracks});

  List<Track> tracks;

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late List<SongRow> songRows = [];

  @override
  void initState() {
    super.initState();

    for (Track track in widget.tracks) {
      Image image = Image.network(track.imageUrl);
      final songRow = SongRow(image: image, track: track);
      songRows.add(songRow);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 800,
        child: ListView(children: [...songRows]),
      ),
    );
  }
}
