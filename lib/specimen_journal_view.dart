import 'package:flutter/material.dart';

import 'specimen_journal.dart';

/// Displays the journal over the enclosure while the simulation keeps running
class SpecimenJournalView extends StatelessWidget {
  const SpecimenJournalView({
    super.key,
    required this.journal,
    required this.onClose,
  });

  final SpecimenJournal journal;
  final VoidCallback onClose;

  static const _paper = Color(0xFFFBF0D7);
  static const _ink = Color(0xFF324437);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            color: _paper,
            elevation: 6,
            shadowColor: const Color(0x443C3020),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              side: BorderSide(color: Color(0xFFCCBA93)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 12, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Specimen journal')),
                      TextButton(
                        onPressed: onClose,
                        style: TextButton.styleFrom(foregroundColor: _ink),
                        child: const Text('Close journal'),
                      ),
                    ],
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 6),
                      child: ListenableBuilder(
                        listenable: journal,
                        builder: (context, _) => _contents(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contents() {
    final facts = journal.facts;
    final entries = journal.recentActivity;
    final species = journal.species;
    final stage = species.stages[journal.stageId]!.label;
    final stagesSeen = journal.stagesSeen;
    final behavior = journal.behaviorLabel;

    return DefaultTextStyle.merge(
      style: const TextStyle(color: _ink, height: 1.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              species.name,
              style: const TextStyle(fontFamily: 'YoungSerif', fontSize: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(stage),
          if (behavior != null) Text(behavior),
          for (final morph in journal.morphs) Text('Morph · $morph'),
          if (stagesSeen.length > 1)
            Text(stagesSeen.map((id) => species.stages[id]!.label).join(' → ')),
          const SizedBox(height: 16),
          _heading('What we’ve learned'),
          if (facts.isEmpty &&
              stagesSeen.every((id) => journal.foodEatenIn(id).isEmpty))
            const Text('Discoveries appear as this specimen explores.')
          else
            for (final fact in facts)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(fact),
              ),
          for (final stageId in stagesSeen)
            for (final food in journal.foodEatenIn(stageId).values)
              Text(
                '${food.name} · ${species.stages[stageId]!.label} · ${food.count} feedings',
              ),
          const Divider(height: 24),
          ExpansionTile(
            key: ValueKey(journal.specimen.id),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 2),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: _heading('Recent activity'),
            subtitle: entries.isEmpty
                ? const Text('No entries yet')
                : Text('${entries.length} recorded'),
            children: [_ActivityEntries(entries: entries)],
          ),
          if (!journal.canSave)
            const Text(
              'This journal is available for this session. Local saving is unavailable.',
              style: TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }

  static Widget _heading(String label) =>
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600));
}

// The tile mounts this widget on expansion, so opening the journal skips timestamp formatting
class _ActivityEntries extends StatelessWidget {
  const _ActivityEntries({required this.entries});

  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((entry) {
        final recordedAt = entry.recordedAt.toLocal();
        final date = localizations.formatShortDate(recordedAt);
        final time = localizations.formatTimeOfDay(
          TimeOfDay.fromDateTime(recordedAt),
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.message),
              Text('$date · $time', style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
