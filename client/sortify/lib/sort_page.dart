import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'filter_page.dart';
import 'app_state.dart';

class SongButton extends StatelessWidget {
  const SongButton({super.key});

  // final Function() onNext;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton(
        onPressed: () {},
        child: Text("Select"),
      ),
    );
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
      fontSize: 17,
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
      message: "${track.name} of ${track.albumName} by ${track.artistName}\n",
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
                  padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
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
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
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
  const SortPage({super.key});

  @override
  State<SortPage> createState() => _SortPageState();
}

class _SortPageState extends State<SortPage> {
  int sortCount = 1;
  int left = 0;
  int right = tracksToSort.length - 1;

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
                    SongCard(track: tracksToSort[left].track),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            if (right <= 0) {
                              appState.updatePageIndex(7);
                            }
                            setState(() {
                              right -= 1;
                              sortCount++;
                            });
                          },
                          child: Text("Select"),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    SongCard(track: tracksToSort[right].track),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            if (left >= tracksToSort.length - 1) {
                              appState.updatePageIndex(7);
                            }
                            setState(() {
                              left += 1;
                              sortCount++;
                            });
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
