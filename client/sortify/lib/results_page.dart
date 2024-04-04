import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'filter_page.dart';

class ResultsPage extends StatelessWidget {
  ResultsPage({super.key, required this.songsList});

  List<SongRow> songsList;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 800,
        child: ListView(children: [...tracksToSort]),
      ),
    );
  }
}
