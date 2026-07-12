enum InstrumentType { piano, strings }

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
  ];

  static InstrumentPreset fromType(InstrumentType type) =>
      presets.firstWhere((p) => p.type == type);
}
