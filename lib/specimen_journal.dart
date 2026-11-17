import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'specimen.dart';
import 'specimen_observation.dart';

/// A dated observation shown in the specimen's recent activity
class JournalEntry {
  const JournalEntry(this.message, this.recordedAt);

  final String message;
  final DateTime recordedAt;
}

/// The number of times a specimen ate a particular food during one stage
typedef FoodRecord = ({String name, int count});

/// Keeps the live status and accumulated observations for one specimen
///
/// Discoveries and feeding records have their own storage in the journal so
/// they remain available after their activity entries roll off the list
class SpecimenJournal extends ChangeNotifier {
  SpecimenJournal({required this.specimen, String? snapshot, this._persist})
    : _stageId = specimen.species.initialStageId {
    _stagesSeen.add(_stageId);
    if (snapshot != null) _restore(snapshot);
  }

  static const entryLimit = 20;
  final Specimen specimen;
  final Future<void> Function(String)? _persist;
  final _entries = <JournalEntry>[];
  final _facts = <String, String>{};
  final _morphs = <String, String>{};
  final _stagesSeen = <String>{};
  final _foodByStage = <String, Map<String, FoodRecord>>{};

  String _stageId;
  String? _behaviorId;
  bool _dirty = false;
  bool _saveFailed = false;
  bool _disposed = false;
  Future<void> _pendingSave = Future.value();

  SpeciesDefinition get species => specimen.species;
  String get stageId => _stageId;
  List<String> get stagesSeen => List.unmodifiable(_stagesSeen);
  String? get behaviorLabel => species.behaviors[_behaviorId];
  bool get canSave => _persist != null && !_saveFailed;
  List<JournalEntry> get recentActivity => List.unmodifiable(_entries);
  List<String> get facts => List.unmodifiable(_facts.values);
  List<String> get morphs => List.unmodifiable(_morphs.values);

  Map<String, FoodRecord> foodEatenIn(String stageId) =>
      Map.unmodifiable(_foodByStage[stageId] ?? const {});

  /// Applies an observation for this individual and its current stage
  ///
  /// Returns whether it changed the journal. Durable changes schedule a save
  bool observe(SpecimenObservation observation) {
    if (observation.specimenId != specimen.id ||
        observation.stageId != _stageId) {
      return false;
    }
    final bool accepted;
    switch (observation) {
      case BehaviorChanged():
        // The simulation supplies this live status again after a restart
        return _recordBehavior(observation);
      case DiscoveryObserved():
        accepted = _recordDiscovery(observation);
      case FoodEaten():
        accepted = _recordFood(observation);
      case LifeStageChanged():
        accepted = _changeStage(observation);
      case MorphIdentified():
        accepted = _identifyMorph(observation);
    }
    if (accepted) {
      _dirty = true;
      unawaited(save());
      notifyListeners();
    }
    return accepted;
  }

  bool _recordBehavior(BehaviorChanged event) {
    if (_behaviorId == event.behaviorId ||
        !species.behaviors.containsKey(event.behaviorId)) {
      return false;
    }
    _behaviorId = event.behaviorId;
    notifyListeners();
    return true;
  }

  bool _recordDiscovery(DiscoveryObserved event) {
    if (_facts[event.id] == event.description) return false;
    _facts[event.id] = event.description;
    final message = event.activityMessage;
    if (message != null) _addEntry(message, event.recordedAt);
    return true;
  }

  bool _recordFood(FoodEaten event) {
    final foods = _foodByStage.putIfAbsent(event.stageId, () => {});
    final prior = foods[event.foodId];
    foods[event.foodId] = (
      name: event.foodName,
      count: (prior?.count ?? 0) + 1,
    );
    // Keep repeated feedings in the count and reserve the log for firsts
    if (prior == null) {
      final stage = species.stages[event.stageId]!.label;
      _addEntry('Ate ${event.foodName} · $stage', event.recordedAt);
    }
    return true;
  }

  bool _changeStage(LifeStageChanged event) {
    final next = species.stages[event.nextStageId];
    if (next == null ||
        !species.stages[_stageId]!.nextStages.contains(event.nextStageId)) {
      return false;
    }
    _stageId = event.nextStageId;
    _stagesSeen.add(_stageId);
    _behaviorId = null;
    _addEntry(
      'Entered the ${next.label.toLowerCase()} stage',
      event.recordedAt,
    );
    return true;
  }

  bool _identifyMorph(MorphIdentified event) {
    if (_morphs.containsKey(event.morphId)) return false;
    _morphs[event.morphId] = event.label;
    _addEntry('Identified morph · ${event.label}', event.recordedAt);
    return true;
  }

  void _addEntry(String message, DateTime at) {
    _entries.insert(0, JournalEntry(message, at.toUtc()));
    if (_entries.length > entryLimit) _entries.removeLast();
  }

  /// Waits for queued writes and schedules a snapshot if the journal is dirty
  Future<void> save() {
    final persist = _persist;
    if (persist == null || !_dirty) return _pendingSave;

    final snapshot = jsonEncode({
      'version': 2,
      'specimenId': specimen.id,
      'speciesId': species.id,
      'stageId': _stageId,
      'stagesSeen': _stagesSeen.toList(),
      'facts': _facts,
      'morphs': _morphs,
      'foodByStage': {
        for (final stage in _foodByStage.entries)
          stage.key: {
            for (final food in stage.value.entries)
              food.key: {'name': food.value.name, 'count': food.value.count},
          },
      },
      'activity': [
        for (final entry in _entries)
          {
            'message': entry.message,
            'recordedAt': entry.recordedAt.toIso8601String(),
          },
      ],
    });
    _dirty = false;
    // Write in observation order so an older snapshot cannot overwrite a newer one
    _pendingSave = _pendingSave.then((_) async {
      final previouslyFailed = _saveFailed;
      try {
        await persist(snapshot);
        _saveFailed = false;
      } catch (error) {
        debugPrint('Could not save the specimen journal: $error');
        _dirty = true;
        _saveFailed = true;
      }
      if (!_disposed && previouslyFailed != _saveFailed) notifyListeners();
    });
    return _pendingSave;
  }

  void _restore(String snapshot) {
    final state = _decodeSnapshot(snapshot);
    if (state == null ||
        state['version'] != 2 ||
        state['specimenId'] != specimen.id ||
        state['speciesId'] != species.id) {
      return;
    }

    final stage = state['stageId'];
    if (stage is String && species.stages.containsKey(stage)) _stageId = stage;
    final seen = state['stagesSeen'];
    if (seen is List) {
      _stagesSeen.addAll(
        seen.whereType<String>().where(species.stages.containsKey),
      );
    }
    _stagesSeen.add(_stageId);
    _restoreFields(
      state['facts'],
      _facts,
      (value) => value is String ? value : null,
    );
    _restoreFields(
      state['morphs'],
      _morphs,
      (value) => value is String ? value : null,
    );

    final foodByStage = state['foodByStage'];
    if (foodByStage is Map<String, dynamic>) {
      for (final stage in foodByStage.entries) {
        if (!species.stages.containsKey(stage.key)) continue;
        final foods = <String, FoodRecord>{};
        _restoreFields(stage.value, foods, (value) {
          if (value is! Map<String, dynamic>) return null;
          final name = value['name'];
          final count = value['count'];
          return name is String && count is int && count > 0
              ? (name: name, count: count)
              : null;
        });
        if (foods.isNotEmpty) _foodByStage[stage.key] = foods;
      }
    }

    final activity = state['activity'];
    if (activity is List) {
      // Snapshots store entries newest first, so the cap retains recent events
      for (final entry in activity.whereType<Map<String, dynamic>>()) {
        final message = entry['message'];
        final timestamp = entry['recordedAt'];
        if (message is! String || timestamp is! String) continue;
        final date = DateTime.tryParse(timestamp);
        if (date == null) continue;
        _entries.add(JournalEntry(message, date));
        if (_entries.length == entryLimit) break;
      }
    }
  }

  static void _restoreFields<T>(
    Object? source,
    Map<String, T> target,
    T? Function(Object?) parse,
  ) {
    if (source is! Map<String, dynamic>) return;
    for (final entry in source.entries) {
      final value = parse(entry.value);
      if (value != null) target[entry.key] = value;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

Map<String, dynamic>? _decodeSnapshot(String snapshot) {
  try {
    final Object? decoded = jsonDecode(snapshot);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// Carries the original woodland discoveries and activity into a specimen save
String? migrateWoodlandJournal(String? snapshot) {
  if (snapshot == null) return null;
  final old = _decodeSnapshot(snapshot);
  if (old == null) return null;

  final specimen = woodlandStickInsect;
  final stage = specimen.species.initialStageId;
  return jsonEncode({
    'version': 2,
    'specimenId': specimen.id,
    'speciesId': specimen.species.id,
    'stageId': stage,
    'stagesSeen': [stage],
    'facts': old['facts'],
    'activity': old['activity'],
  });
}
