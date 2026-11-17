import 'package:flutter/material.dart';

import 'specimen_journal.dart';

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
                        builder: (context, _) => _contents(context),
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

  Widget _contents(BuildContext context) {
    final facts = journal.facts;
    final entries = journal.recentActivity;
    final localizations = MaterialLocalizations.of(context);

    return DefaultTextStyle.merge(
      style: const TextStyle(color: _ink, height: 1.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: const Text(
              'Stick insect',
              style: TextStyle(fontFamily: 'YoungSerif', fontSize: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text('${journal.activity.label} · ${journal.location.label}'),
          const SizedBox(height: 16),
          _heading('Metrics'),
          _metric('On branches', journal.branchSeconds),
          _metric('In leaf litter', journal.groundSeconds),
          _metric('Resting', journal.restSeconds),
          const SizedBox(height: 16),
          _heading('What we’ve learned'),
          if (facts.isEmpty)
            const Text('Discoveries appear as this specimen explores.')
          else
            for (final fact in facts)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(fact),
              ),
          const Divider(height: 24),
          ExpansionTile(
            key: const PageStorageKey('recent-specimen-activity'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 2),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: _heading('Recent activity'),
            subtitle: entries.isEmpty
                ? const Text('No entries yet')
                : Text('${entries.length} recorded'),
            children: [
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.message),
                      Text(
                        '${localizations.formatShortDate(entry.recordedAt.toLocal())} · '
                        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(entry.recordedAt.toLocal()))}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
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

  static Widget _metric(String label, int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    final value = minutes == 0 ? '${remainder}s' : '${minutes}m ${remainder}s';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(value),
        ],
      ),
    );
  }
}
