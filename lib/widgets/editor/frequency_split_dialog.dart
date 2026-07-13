import 'package:flutter/material.dart';
import 'dart:math';
import '../../services/fft_service.dart';

class _BandConfig {
  String label;
  double lowFreq;
  double highFreq;
  double crossfadeHz;

  _BandConfig({
    required this.label,
    required this.lowFreq,
    required this.highFreq,
    this.crossfadeHz = 50,
  });

  _BandConfig copy() => _BandConfig(label: label, lowFreq: lowFreq, highFreq: highFreq, crossfadeHz: crossfadeHz);
}

Future<List<FreqBand>?> showFrequencySplitDialog(
    BuildContext context, double totalDuration) {
  return showDialog<List<FreqBand>>(
    context: context,
    builder: (ctx) => _FrequencySplitDialog(totalDuration: totalDuration),
  );
}

class _FrequencySplitDialog extends StatefulWidget {
  final double totalDuration;
  const _FrequencySplitDialog({required this.totalDuration});

  @override
  State<_FrequencySplitDialog> createState() => _FrequencySplitDialogState();
}

class _FrequencySplitDialogState extends State<_FrequencySplitDialog> {
  String _preset = 'lowMidHigh';
  final List<_BandConfig> _bands = [];

  static const _presets = {
    'lowMidHigh': 'Low / Mid / High',
    'lowHigh': 'Low / High',
    'custom': 'Custom',
  };

  @override
  void initState() {
    super.initState();
    _applyPreset();
  }

  void _applyPreset() {
    _bands.clear();
    switch (_preset) {
      case 'lowMidHigh':
        _bands.add(_BandConfig(label: 'Low', lowFreq: 20, highFreq: 250));
        _bands.add(_BandConfig(label: 'Mid', lowFreq: 250, highFreq: 4000));
        _bands.add(_BandConfig(label: 'High', lowFreq: 4000, highFreq: 20000));
        break;
      case 'lowHigh':
        _bands.add(_BandConfig(label: 'Low', lowFreq: 20, highFreq: 800));
        _bands.add(_BandConfig(label: 'High', lowFreq: 800, highFreq: 20000));
        break;
      case 'custom':
        _bands.add(_BandConfig(label: 'Band 1', lowFreq: 20, highFreq: 1000));
        break;
    }
  }

  static double _freqToNorm(double f) => log(f / 20) / log(20000 / 20);
  static double _normToFreq(double n) => 20 * pow(20000 / 20, n) as double;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Frequency Split'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Preset:', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _preset,
                  isDense: true,
                  underline: const SizedBox(),
                  items: _presets.entries.map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) => setState(() { _preset = v!; _applyPreset(); }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_bands.length, (i) {
              final band = _bands[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(band.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
                        const Spacer(),
                        Text('${band.lowFreq.round()} Hz – ${band.highFreq.round()} Hz',
                            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                      ],
                    ),
                    RangeSlider(
                      values: RangeValues(_freqToNorm(band.lowFreq), _freqToNorm(band.highFreq)),
                      min: 0, max: 1,
                      divisions: 200,
                      labels: RangeLabels(
                        '${band.lowFreq.round()} Hz',
                        '${band.highFreq.round()} Hz',
                      ),
                      onChanged: (v) => setState(() {
                        band.lowFreq = _normToFreq(v.start);
                        band.highFreq = _normToFreq(v.end);
                      }),
                    ),
                    if (_preset == 'custom' && _bands.length > 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.remove, size: 14),
                          label: const Text('Remove', style: TextStyle(fontSize: 10)),
                          onPressed: () => setState(() => _bands.removeAt(i)),
                        ),
                      ),
                  ],
                ),
              );
            }),
            if (_preset == 'custom')
              TextButton.icon(
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Band', style: TextStyle(fontSize: 11)),
                onPressed: () => setState(() {
                  _bands.add(_BandConfig(label: 'Band ${_bands.length + 1}', lowFreq: 100, highFreq: 2000));
                }),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final bands = _bands.map((b) => FreqBand(
              lowFreq: b.lowFreq, highFreq: b.highFreq, crossfadeHz: b.crossfadeHz,
            )).toList();
            Navigator.of(context).pop(bands);
          },
          child: const Text('Split'),
        ),
      ],
    );
  }
}
