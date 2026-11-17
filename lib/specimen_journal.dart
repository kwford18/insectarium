import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

enum SpecimenLocation {
  branches('Branches'),
  leafLitter('Leaf litter');

  const SpecimenLocation(this.label);
  final String label;
}

enum SpecimenActivity {
  resting('Resting'),
  climbing('Climbing'),
  walking('Walking');

  const SpecimenActivity(this.label);
  final String label;
}

class JournalEntry {
  const JournalEntry(this.message, this.recordedAt);

  final String message;
  final DateTime recordedAt;
}

class SpecimenJournal extends ChangeNotifier {
  SpecimenJournal({String? snapshot, this._persist}) {
    if (snapshot != null) _restore(snapshot);
  }

  static const entryLimit = 20;
  final Future<void> Function(String)? _persist;
  final _entries = <JournalEntry>[];
  final _facts = <String, String>{};

  SpecimenLocation _location = SpecimenLocation.branches;
  SpecimenActivity _activity = SpecimenActivity.resting;
  double _branchSeconds = 0;
  double _groundSeconds = 0;
  double _restSeconds = 0;
  double _sinceSave = 0;
  bool _dirty = false;
  bool _saveFailed = false;
  bool _disposed = false;
  Future<void> _pendingSave = Future.value();

  SpecimenLocation get location => _location;
  SpecimenActivity get activity => _activity;
  int get branchSeconds => _branchSeconds.floor();
  int get groundSeconds => _groundSeconds.floor();
  int get restSeconds => _restSeconds.floor();
  bool get canSave => _persist != null && !_saveFailed;
  List<JournalEntry> get recentActivity => List.unmodifiable(_entries);
  List<String> get facts => List.unmodifiable(_facts.values);

  void observe(
    double seconds, {
    required SpecimenLocation location,
    required SpecimenActivity activity,
  }) {
    if (seconds <= 0) return;
    final previous = (
      _location,
      _activity,
      branchSeconds,
      groundSeconds,
      restSeconds,
    );
    if (_location == SpecimenLocation.branches) {
      _branchSeconds += seconds;
    } else {
      _groundSeconds += seconds;
    }
    if (_activity == SpecimenActivity.resting) _restSeconds += seconds;
    _location = location;
    _activity = activity;
    _dirty = true;
    _sinceSave += seconds;

    if (location == SpecimenLocation.leafLitter) {
      learn(
        'visitedLeafLitter',
        'Explores leaf litter as well as branches.',
        activity: 'Reached the leaf litter',
      );
      if (activity == SpecimenActivity.resting) {
        learn('restedOnGround', 'Has rested on the enclosure floor.');
      }
    }
    if (_persist != null && _sinceSave >= 5) unawaited(save());
    if (previous !=
        (location, activity, branchSeconds, groundSeconds, restSeconds)) {
      notifyListeners();
    }
  }

  void learn(String key, String fact, {String? activity}) {
    if (_facts[key] == fact) return;
    _facts[key] = fact;
    if (activity != null) {
      _entries.insert(0, JournalEntry(activity, DateTime.now().toUtc()));
      if (_entries.length > entryLimit) _entries.removeLast();
    }
    _dirty = true;
    unawaited(save());
    notifyListeners();
  }

  Future<void> save() {
    final persist = _persist;
    if (persist == null || !_dirty) return _pendingSave;

    final snapshot = jsonEncode({
      'branchSeconds': _branchSeconds,
      'groundSeconds': _groundSeconds,
      'restSeconds': _restSeconds,
      'facts': _facts,
      'activity': [
        for (final entry in _entries)
          {
            'message': entry.message,
            'recordedAt': entry.recordedAt.toIso8601String(),
          },
      ],
    });
    _dirty = false;
    _sinceSave = 0;
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
    final Object? decoded;
    try {
      decoded = jsonDecode(snapshot);
    } on FormatException {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;

    _branchSeconds = _validSeconds(decoded['branchSeconds']);
    _groundSeconds = _validSeconds(decoded['groundSeconds']);
    _restSeconds = _validSeconds(decoded['restSeconds']);
    final facts = decoded['facts'];
    if (facts is Map<String, dynamic>) {
      for (final entry in facts.entries) {
        final value = entry.value;
        if (value is String) _facts[entry.key] = value;
      }
    }
    final activity = decoded['activity'];
    if (activity is List) {
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

  static double _validSeconds(Object? value) =>
      value is num && value.isFinite && value >= 0 ? value.toDouble() : 0;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
