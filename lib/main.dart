import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'specimen_journal.dart';
import 'specimen_journal_view.dart';
import 'stick_insect.dart';
import 'woodland_enclosure.dart';

const _journalOverlay = 'specimenJournal';
const _journalKey = 'woodland.stickInsect.journal.v1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = SharedPreferencesAsync();
  final SpecimenJournal journal;
  try {
    journal = SpecimenJournal(
      snapshot: await preferences.getString(_journalKey),
      persist: (snapshot) => preferences.setString(_journalKey, snapshot),
    );
  } catch (error) {
    debugPrint('Could not load the specimen journal: $error');
    runApp(SanctuaryApp(journal: SpecimenJournal()));
    return;
  }
  runApp(SanctuaryApp(journal: journal));
}

class SanctuaryApp extends StatelessWidget {
  SanctuaryApp({super.key, required SpecimenJournal journal})
    : _game = _TerrariumGame(journal);

  final _TerrariumGame _game;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Insect Sanctuary',
      debugShowCheckedModeBanner: false,
      home: GameWidget(
        game: _game,
        overlayBuilderMap: {
          _journalOverlay: (_, _) => SpecimenJournalView(
            journal: _game.journal,
            onClose: () => _game.overlays.remove(_journalOverlay),
          ),
        },
      ),
    );
  }
}

class _TerrariumGame extends FlameGame {
  _TerrariumGame(this.journal) {
    addAll([
      WoodlandEnclosure(),
      StickInsect(
        trailPath: woodlandTrail,
        journal: journal,
        onObserve: () => overlays.add(_journalOverlay),
      ),
      WoodlandEnclosure(foreground: true),
    ]);
  }

  final SpecimenJournal journal;

  @override
  void lifecycleStateChange(AppLifecycleState state) {
    super.lifecycleStateChange(state);
    if (state != AppLifecycleState.resumed) unawaited(journal.save());
  }
}
