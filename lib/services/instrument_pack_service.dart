import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import '../models/instrument.dart';

class InstrumentPack {
  final String name;
  final String version;
  final List<InstrumentPreset> instruments;

  const InstrumentPack({
    required this.name,
    this.version = '1.0',
    required this.instruments,
  });
}

class InstrumentPackService {
  static const _iconMap = <String, IconData>{
    'piano': Icons.piano,
    'music_note': Icons.music_note_outlined,
    'audiotrack': Icons.audiotrack,
    'toc': Icons.toc,
    'electric_bolt': Icons.electric_bolt,
    'waves': Icons.waves,
    'hearing': Icons.hearing,
    'mic': Icons.mic,
    'toys': Icons.toys,
    'star': Icons.star,
  };

  static const _catMap = <String, InstrumentCategory>{
    'keyboard': InstrumentCategory.keyboard,
    'string': InstrumentCategory.string,
    'wind': InstrumentCategory.wind,
    'synth': InstrumentCategory.synth,
    'percussion': InstrumentCategory.percussion,
  };

  static Future<List<InstrumentPreset>> loadFromAsset(String path) async {
    final jsonStr = await rootBundle.loadString(path);
    return _parseJson(jsonStr);
  }

  static Future<List<InstrumentPreset>> loadFromZip(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final presets = <InstrumentPreset>[];

    for (final file in archive) {
      if (file.isFile && file.name.endsWith('.json')) {
        final jsonStr = utf8.decode(file.content as List<int>);
        presets.addAll(_parseJson(jsonStr));
      }
    }
    return presets;
  }

  static List<InstrumentPreset> _parseJson(String jsonStr) {
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final list = <InstrumentPreset>[];
    for (final entry in data['instruments'] as List) {
      final inst = entry as Map<String, dynamic>;
      final iconName = inst['icon'] as String? ?? 'music_note';
      final catName = inst['category'] as String? ?? 'synth';
      final harmonics = (inst['harmonics'] as List).map((e) => (e as num).toDouble()).toList();

      list.add(InstrumentPreset(
        id: inst['id'] as String,
        name: inst['name'] as String,
        description: inst['description'] as String? ?? '',
        icon: _iconMap[iconName] ?? Icons.music_note_outlined,
        category: _catMap[catName] ?? InstrumentCategory.synth,
        programNumber: inst['programNumber'] as int? ?? 0,
        harmonics: harmonics,
        attack: (inst['attack'] as num?)?.toDouble() ?? 0.01,
        decay: (inst['decay'] as num?)?.toDouble() ?? 0.2,
        sustain: (inst['sustain'] as num?)?.toDouble() ?? 0.7,
        release: (inst['release'] as num?)?.toDouble() ?? 0.1,
        detuneCents: (inst['detuneCents'] as num?)?.toDouble() ?? 0,
        noiseAttack: (inst['noiseAttack'] as num?)?.toDouble() ?? 0,
        brightnessFactor: (inst['brightnessFactor'] as num?)?.toDouble() ?? 0.3,
      ));
    }
    return list;
  }

  static String serializeToJson({
    required String name,
    required List<InstrumentPreset> presets,
  }) {
    final list = presets.map((p) => {
      'id': p.id,
      'name': p.name,
      'description': p.description,
      'icon': _reverseIcon(p.icon),
      'category': _reverseCat(p.category),
      'programNumber': p.programNumber,
      'harmonics': p.harmonics,
      'attack': p.attack,
      'decay': p.decay,
      'sustain': p.sustain,
      'release': p.release,
      'detuneCents': p.detuneCents,
      'noiseAttack': p.noiseAttack,
      'brightnessFactor': p.brightnessFactor,
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'name': name,
      'version': '1.0',
      'instruments': list,
    });
  }

  static String _reverseIcon(IconData icon) {
    return _iconMap.entries.firstWhere(
      (e) => e.value == icon,
      orElse: () => const MapEntry('music_note', Icons.music_note_outlined),
    ).key;
  }

  static String _reverseCat(InstrumentCategory cat) {
    return _catMap.entries.firstWhere(
      (e) => e.value == cat,
      orElse: () => const MapEntry('synth', InstrumentCategory.synth),
    ).key;
  }
}
