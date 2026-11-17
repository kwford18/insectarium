import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'specimen.dart';
import 'specimen_journal.dart';
import 'specimen_journal_view.dart';
import 'stick_insect.dart';
import 'woodland_enclosure.dart';

const _journalOverlay = 'specimenJournal';
const _legacyJournalKey = 'woodland.stickInsect.journal.v1';

/// Loads the saved specimen history before mounting the game
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = SharedPreferencesAsync();
  const specimen = woodlandStickInsect;
  final journalKey = 'specimen.journal.v2.${specimen.id}';
  final SpecimenJournal journal;
  try {
    var snapshot = await preferences.getString(journalKey);
    if (snapshot == null) {
      // The original prototype stored its single journal under a fixed key
      snapshot = migrateWoodlandJournal(
        await preferences.getString(_legacyJournalKey),
      );
      if (snapshot != null) {
        try {
          await preferences.setString(journalKey, snapshot);
        } catch (error) {
          debugPrint('Could not save the migrated specimen journal: $error');
        }
      }
    }
    journal = SpecimenJournal(
      specimen: specimen,
      snapshot: snapshot,
      persist: (snapshot) => preferences.setString(journalKey, snapshot),
    );
  } catch (error) {
    // Local storage failures still allow a playable session with a live journal
    debugPrint('Could not load the specimen journal: $error');
    runApp(SanctuaryApp(journal: SpecimenJournal(specimen: specimen)));
    return;
  }
  runApp(SanctuaryApp(journal: journal));
}

/// Hosts the Flame scene and its Flutter journal overlay
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
    // Split enclosure art across layers so foliage can partly hide the insect
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
    // Flush dirty journal state when the app loses focus, including failed saves
    if (state != AppLifecycleState.resumed) unawaited(journal.save());
  }
}
