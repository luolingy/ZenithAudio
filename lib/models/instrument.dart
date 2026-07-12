import 'package:flutter/material.dart';

enum InstrumentType {
  piano,
  strings,
  organ,
  guitar,
  bass,
  brass,
  synth,
  pad,
}

class InstrumentPreset {
  final InstrumentType type;
  final String name;
  final int programNumber;
  final int bankNumber;

  const InstrumentPreset({
    required this.type,
    required this.name,
    required this.programNumber,
    this.bankNumber = 0,
  });

  static const List<InstrumentPreset> presets = [
    InstrumentPreset(type: InstrumentType.piano, name: 'Acoustic Grand Piano', programNumber: 0),
    InstrumentPreset(type: InstrumentType.strings, name: 'String Ensemble', programNumber: 48),
    InstrumentPreset(type: InstrumentType.organ, name: 'Church Organ', programNumber: 19),
    InstrumentPreset(type: InstrumentType.guitar, name: 'Acoustic Guitar (nylon)', programNumber: 24),
    InstrumentPreset(type: InstrumentType.bass, name: 'Acoustic Bass', programNumber: 32),
    InstrumentPreset(type: InstrumentType.brass, name: 'Brass Section', programNumber: 61),
    InstrumentPreset(type: InstrumentType.synth, name: 'Synth Lead', programNumber: 80),
    InstrumentPreset(type: InstrumentType.pad, name: 'Synth Pad', programNumber: 88),
  ];

  static InstrumentPreset fromType(InstrumentType type) =>
      presets.firstWhere((p) => p.type == type);
}

/// Shows a dialog to pick an instrument. Returns the [InstrumentType.name] or null.
Future<String?> showInstrumentPicker(BuildContext context, {String? current}) async {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Select Instrument'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final preset in InstrumentPreset.presets)
            _InstrumentTile(
              name: preset.name,
              value: preset.type.name,
              selected: current,
              onTap: () => Navigator.of(ctx).pop(preset.type.name),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

class _InstrumentTile extends StatelessWidget {
  final String name;
  final String value;
  final String? selected;
  final VoidCallback onTap;

  const _InstrumentTile({
    required this.name,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return ListTile(
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        size: 18,
      ),
      title: Text(name, style: const TextStyle(fontSize: 13)),
      selected: isSelected,
      dense: true,
      onTap: onTap,
    );
  }
}
