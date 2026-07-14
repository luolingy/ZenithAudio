import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/audio_clip.dart';
import '../../models/track.dart';

import '../../providers/project_provider.dart';
import '../../providers/playback_provider.dart';
import '../../services/audio_service.dart';
import '../../services/audio_converter.dart';
import '../../services/fft_service.dart';
import '../../services/audio_processing_service.dart';
import '../../core/utils/logger.dart';
import 'waveform_painter.dart';
import 'generator_panel.dart';
import 'waveform_cards.dart';
import 'frequency_split_dialog.dart';

/// Open the audio clip editor for a given track.
/// Desktop: full-screen dialog. Mobile: Navigator push.
Future<void> openAudioClipEditor(BuildContext context, String trackId) {
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AudioClipEditor(trackId: trackId),
      ),
    );
  }
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    builder: (_) => Dialog(
      insetPadding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AudioClipEditor(trackId: trackId),
      ),
    ),
  );
}

/// Open the audio clip editor for a new generated track.
Future<void> openAudioClipEditorForNew(
    BuildContext context, Float64List samples, int sampleRate, String genType) {
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AudioClipEditor(
          initialSamples: samples,
          initialSampleRate: sampleRate,
          initialGenType: genType,
        ),
      ),
    );
  }
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    builder: (_) => Dialog(
      insetPadding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AudioClipEditor(
          initialSamples: samples,
          initialSampleRate: sampleRate,
          initialGenType: genType,
        ),
      ),
    ),
  );
}

class AudioClipEditor extends ConsumerStatefulWidget {
  final String? trackId;
  final Float64List? initialSamples;
  final int? initialSampleRate;
  final String? initialGenType;

  const AudioClipEditor({
    super.key,
    this.trackId,
    this.initialSamples,
    this.initialSampleRate,
    this.initialGenType,
  });

  @override
  ConsumerState<AudioClipEditor> createState() => _AudioClipEditorState();
}

class _AudioClipEditorState extends ConsumerState<AudioClipEditor> {
  Track? _track;
  AudioClip? _clip;
  bool _loading = true;
  bool _disposed = false;
  String? _loadError;

  double _zoom = 2.0;
  double get _pps => (_basePps * _zoom).clamp(20, 600);
  static const double _basePps = 40;

  final ScrollController _hScrollCtrl = ScrollController();
  double _playheadSec = 0;
  bool _isPlaying = false;
  bool _showGenerator = false;

  // Selection
  double? _dragStartSec;
  double? _dragCurrentSec;

  @override
  void initState() {
    super.initState();
    _loadAudio();
  }

  @override
  void dispose() {
    _disposed = true;
    _hScrollCtrl.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) setState(fn);
  }

  Future<void> _loadAudio() async {
    if (widget.initialSamples != null) {
      _clip = AudioClip(
        samples: widget.initialSamples!,
        sampleRate: widget.initialSampleRate ?? 44100,
        genParams: widget.initialGenType != null
            ? WaveformGenParams(type: widget.initialGenType!, frequency: 440)
            : null,
      );
      _loadError = null;
      _safeSetState(() => _loading = false);
      return;
    }

    if (widget.trackId == null) {
      _safeSetState(() => _loading = false);
      return;
    }

    final project = ref.read(projectProvider);
    final track = project.tracks.where((t) => t.id == widget.trackId).firstOrNull;
    if (track == null) {
      _safeSetState(() => _loading = false);
      return;
    }
    _track = track;

    if (track.audioFilePath != null && await File(track.audioFilePath!).exists()) {
      final originalPath = track.audioFilePath!;
      var samples = await _readWavFile(originalPath);
      var sourceFile = originalPath;
      if (samples == null) {
        final converted = await convertToWav(originalPath);
        if (converted != null) {
          sourceFile = converted;
          samples = await _readWavFile(sourceFile);
        }
      }
      if (samples != null) {
        _clip = AudioClip(samples: samples, sampleRate: widget.initialSampleRate ?? 44100, sourceFile: sourceFile);
        _loadError = null;
      } else {
        _loadError = '无法读取音频文件（格式不支持或文件损坏）。请使用 WAV 格式。';
      }
    } else {
      _loadError = '音频文件未找到。';
    }

    _safeSetState(() => _loading = false);
  }

  /// Read PCM samples from a WAV file.
  Future<Float64List?> _readWavFile(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      if (bytes.length < 12) return null;

      // RIFF header: "RIFF" + fileSize + "WAVE"
      final riff = String.fromCharCodes(bytes.sublist(0, 4));
      if (riff != 'RIFF') return null;
      final wave = String.fromCharCodes(bytes.sublist(8, 12));
      if (wave != 'WAVE') return null;

      // Parse sub-chunks to find "fmt " and "data"
      int channels = 1;
      int bitsPerSample = 16;
      int dataOffset = 0;
      int dataSize = 0;
      int offset = 12;
      while (offset + 8 <= bytes.length) {
        final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
        final chunkSize = ByteData.sublistView(bytes, offset + 4, offset + 8).getUint32(0, Endian.little);
        if (chunkId == 'fmt ') {
          if (chunkSize >= 16) {
            final audioFormat = ByteData.sublistView(bytes, offset + 8, offset + 10).getUint16(0, Endian.little);
            if (audioFormat != 1) return null; // Only PCM supported
            channels = ByteData.sublistView(bytes, offset + 10, offset + 12).getUint16(0, Endian.little);
            bitsPerSample = ByteData.sublistView(bytes, offset + 22, offset + 24).getUint16(0, Endian.little);
          }
        } else if (chunkId == 'data') {
          dataOffset = offset + 8;
          dataSize = chunkSize.toInt();
        }
        offset += 8 + chunkSize + (chunkSize % 2); // Skip padding byte if odd-sized
      }

      if (dataSize <= 0) return null;

      final int bytesPerSample = bitsPerSample ~/ 8;
      final int totalSamples = dataSize ~/ bytesPerSample;
      final int numSamples = totalSamples ~/ channels; // De-interleave to mono
      final result = Float64List(numSamples);

      if (bitsPerSample == 16) {
        for (int i = 0; i < numSamples; i++) {
          final srcIdx = dataOffset + i * channels * 2;
          final int sample = ByteData.sublistView(bytes, srcIdx, srcIdx + 2).getInt16(0, Endian.little);
          result[i] = sample / 32768.0;
        }
      } else if (bitsPerSample == 24) {
        for (int i = 0; i < numSamples; i++) {
          final srcIdx = dataOffset + i * channels * 3;
          final int b0 = bytes[srcIdx];
          final int b1 = bytes[srcIdx + 1];
          final int b2 = bytes[srcIdx + 2];
          int sample = b0 | (b1 << 8) | (b2 << 16);
          if (sample >= 0x800000) sample -= 0x1000000;
          result[i] = sample / 8388608.0;
        }
      } else if (bitsPerSample == 32) {
        for (int i = 0; i < numSamples; i++) {
          final srcIdx = dataOffset + i * channels * 4;
          final int sample = ByteData.sublistView(bytes, srcIdx, srcIdx + 4).getInt32(0, Endian.little);
          result[i] = sample / 2147483648.0;
        }
      } else {
        AppLogger.w('Unsupported WAV bit depth: $bitsPerSample');
        return null;
      }
      return result;
    } catch (e) {
      AppLogger.e('Failed to read WAV', e);
      return null;
    }
  }

  /// Save clip to WAV file and update track.
  Future<String> _saveToWav(Float64List samples, {String? prefix}) async {
    final dir = Directory.systemTemp;
    final name = prefix ?? 'clip_${const Uuid().v4().substring(0, 8)}';
    final path = '${dir.path}/$name.wav';
    final wav = _encodeWav(samples);
    await File(path).writeAsBytes(wav);
    return path;
  }

  Uint8List _encodeWav(Float64List buffer) {
    final numSamples = buffer.length;
    final sampleRate = 44100;
    final bytesPerSample = 2;
    final dataSize = numSamples * bytesPerSample;
    final fileSize = 44 + dataSize;
    final data = List<int>.filled(fileSize, 0);
    int offset = 0;
    void w4(int v) {
      data[offset] = v & 0xFF; data[offset + 1] = (v >> 8) & 0xFF;
      data[offset + 2] = (v >> 16) & 0xFF; data[offset + 3] = (v >> 24) & 0xFF;
      offset += 4;
    }
    void w2(int v) {
      data[offset] = v & 0xFF; data[offset + 1] = (v >> 8) & 0xFF;
      offset += 2;
    }
    void ws(String s) {
      for (int i = 0; i < s.length; i++) data[offset++] = s.codeUnitAt(i);
    }
    ws('RIFF'); w4(fileSize - 8); ws('WAVE');
    ws('fmt '); w4(16); w2(1); w2(1); w4(sampleRate);
    w4(sampleRate * bytesPerSample); w2(bytesPerSample); w2(16);
    ws('data'); w4(dataSize);
    for (int i = 0; i < numSamples; i++) {
      final clamped = buffer[i].clamp(-1.0, 1.0);
      final sample = (clamped * 32767).round().clamp(-32768, 32767);
      w2(sample);
    }
    return Uint8List.fromList(data);
  }

  void _togglePlayback() {
    final notifier = ref.read(playbackProvider.notifier);
    if (_isPlaying) {
      notifier.stop();
      _safeSetState(() => _isPlaying = false);
    } else {
      // Load the track into audio service and play
      _startPlayback();
    }
  }

  Future<void> _startPlayback() async {
    if (_clip == null) return;
    final audio = ref.read(audioServiceProvider);
    await audio.unloadAll();

    // Generate a WAV for the current clip
    final path = await _saveToWav(_clip!.samples, prefix: 'editor_play');
    await audio.loadTrackFromPath('editor_play', path, volume: 1.0);

    audio.onPositionChanged = (pos) {
      _safeSetState(() => _playheadSec = pos);
      // Auto-scroll to follow playhead
      if (_hScrollCtrl.hasClients) {
        final viewportWidth = _hScrollCtrl.position.viewportDimension;
        final playheadX = pos * _pps;
        if (playheadX < _hScrollCtrl.offset || playheadX > _hScrollCtrl.offset + viewportWidth * 0.8) {
          _hScrollCtrl.jumpTo(max(0, playheadX - viewportWidth * 0.2));
        }
      }
    };
    audio.onCompleted = () {
      _safeSetState(() => _isPlaying = false);
    };

    await audio.play();
    _safeSetState(() => _isPlaying = true);
  }

  void _stopPlayback() {
    ref.read(audioServiceProvider).stop();
    _safeSetState(() {
      _isPlaying = false;
      _playheadSec = 0;
    });
  }

  void _onWaveformTap(TapUpDetails details) {
    if (_clip == null) return;
    final sec = (details.localPosition.dx + _hScrollCtrl.offset) / _pps;
    _safeSetState(() => _playheadSec = sec.clamp(0, _clip!.duration));
  }

  void _onWaveformPanStart(DragStartDetails details) {
    if (_clip == null) return;
    final sec = (details.localPosition.dx + _hScrollCtrl.offset) / _pps;
    _safeSetState(() {
      _dragStartSec = sec.clamp(0, _clip!.duration);
      _dragCurrentSec = _dragStartSec;
    });
  }

  void _onWaveformPanUpdate(DragUpdateDetails details) {
    if (_clip == null || _dragStartSec == null) return;
    final sec = (details.localPosition.dx + _hScrollCtrl.offset) / _pps;
    _safeSetState(() {
      _dragCurrentSec = sec.clamp(0, _clip!.duration);
      final start = min(_dragStartSec!, _dragCurrentSec!);
      final end = max(_dragStartSec!, _dragCurrentSec!);
      _clip!.selection = Selection(startSec: start, endSec: end);
    });
  }

  void _onWaveformPanEnd(DragEndDetails details) {
    // Selection is already set
  }

  void _clearSelection() {
    _safeSetState(() {
      _clip?.selection = null;
      _dragStartSec = null;
      _dragCurrentSec = null;
    });
  }

  void _applyToSelection(Float64List Function(Float64List) processor) {
    if (_clip?.selection == null || !_clip!.selection!.isValid) return;
    final sel = _clip!.selection!;
    final startSample = (sel.startSec * _clip!.sampleRate).round();
    final endSample = (sel.endSec * _clip!.sampleRate).round().clamp(0, _clip!.samples.length);
    final region = _clip!.samples.sublist(startSample, endSample);
    final processed = processor(Float64List.fromList(region));
    for (int i = 0; i < processed.length && startSample + i < _clip!.samples.length; i++) {
      _clip!.samples[startSample + i] = processed[i];
    }
    _safeSetState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS;

    if (_loading) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: _buildAppBar(cs, isDesktop),
      body: ClipRect(
        child: Stack(
          children: [
            if (_clip != null)
              Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(child: _buildWaveformArea(cs)),
                        _buildWaveformCards(cs),
                      ],
                    ),
                  ),
                  _buildTransportBar(cs),
                ],
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.audio_file_outlined, size: 48, color: cs.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text(_loadError ?? 'No audio data', style: TextStyle(color: _loadError != null ? cs.error : cs.onSurfaceVariant)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Generate Waveform'),
                      onPressed: () => _safeSetState(() => _showGenerator = !_showGenerator),
                    ),
                  ],
                ),
              ),
            if (_showGenerator)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GeneratorPanel(
                  onGenerate: (samples, type) {
                    _safeSetState(() {
                      _clip = AudioClip(samples: samples, sampleRate: 44100,
                          genParams: WaveformGenParams(type: type, frequency: 440));
                      _loadError = null;
                      _showGenerator = false;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme cs, bool isDesktop) {
    return AppBar(
      backgroundColor: cs.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        _track?.name ?? (widget.initialGenType != null ? 'New ${widget.initialGenType}' : 'Audio Editor'),
        style: const TextStyle(fontSize: 14),
      ),
      actions: [
        if (_clip != null) ...[
          PopupMenuButton<String>(
            icon: const Icon(Icons.auto_fix_high, size: 18),
            tooltip: 'Process',
            onSelected: (action) => _handleProcess(action),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'normalize', child: Text('Normalize', style: TextStyle(fontSize: 12))),
              const PopupMenuItem(value: 'reverse', child: Text('Reverse', style: TextStyle(fontSize: 12))),
              const PopupMenuItem(value: 'removeDc', child: Text('Remove DC Offset', style: TextStyle(fontSize: 12))),
              const PopupMenuItem(value: 'fadeIn', child: Text('Fade In', style: TextStyle(fontSize: 12))),
              const PopupMenuItem(value: 'fadeOut', child: Text('Fade Out', style: TextStyle(fontSize: 12))),
              const PopupMenuItem(value: 'distort', child: Text('Distort', style: TextStyle(fontSize: 12))),
              const PopupMenuItem(value: 'delay', child: Text('Delay', style: TextStyle(fontSize: 12))),
              const PopupMenuItem(value: 'reverb', child: Text('Reverb', style: TextStyle(fontSize: 12))),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.call_split, size: 18),
            tooltip: 'Frequency Split',
            onSelected: (action) => _handleSplit(context),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'split', child: Text('Split Frequencies...', style: TextStyle(fontSize: 12))),
            ],
          ),
          IconButton(
            icon: Icon(_showGenerator ? Icons.expand_more : Icons.expand_less, size: 18),
            tooltip: 'Generator',
            onPressed: () => _safeSetState(() => _showGenerator = !_showGenerator),
          ),
        ],
        SizedBox(
          width: 100,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              value: _zoom,
              min: 0.5, max: 10,
              onChanged: (v) => _safeSetState(() => _zoom = v),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text('${(_zoom * 100).round()}%',
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        ),
      ],
    );
  }

  Widget _buildWaveformArea(ColorScheme cs) {
    if (_clip == null) return const SizedBox();
    return DragTarget<Float64List>(
      onAcceptWithDetails: (details) => _onWaveformDropped(details.data),
      builder: (context, candidateData, rejectedData) {
        final isDragOver = candidateData.isNotEmpty;
        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              final ctrl = HardwareKeyboard.instance.logicalKeysPressed.any(
                (k) => k == LogicalKeyboardKey.controlLeft || k == LogicalKeyboardKey.controlRight,
              );
              if (ctrl) {
                _safeSetState(() {
                  _zoom = (_zoom * (event.scrollDelta.dy < 0 ? 1.15 : 0.85)).clamp(0.5, 10.0);
                });
              }
            }
          },
          child: Container(
            decoration: isDragOver
                ? BoxDecoration(
                    border: Border.all(color: cs.primary.withAlpha(150), width: 2),
                  )
                : null,
            child: GestureDetector(
              onTapUp: _onWaveformTap,
              onPanStart: _onWaveformPanStart,
              onPanUpdate: _onWaveformPanUpdate,
              onPanEnd: _onWaveformPanEnd,
              child: SingleChildScrollView(
                controller: _hScrollCtrl,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _clip!.duration * _pps,
                  child: CustomPaint(
                    size: Size(_clip!.duration * _pps, 300),
                    painter: WaveformPainter(
                      samples: _clip!.samples,
                      sampleRate: _clip!.sampleRate,
                      pps: _pps,
                      playheadSec: _isPlaying ? _playheadSec : -1,
                      selection: _clip!.selection,
                      waveformColor: _track?.color ?? cs.primary,
                      scrollOffset: _hScrollCtrl.hasClients ? _hScrollCtrl.offset : 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onWaveformDropped(Float64List samples) {
    if (_clip == null) return;
    final insertSample = (_playheadSec * _clip!.sampleRate).round().clamp(0, _clip!.samples.length);
    final endSample = (insertSample + samples.length).clamp(0, _clip!.samples.length);
    final mixLen = endSample - insertSample;
    if (mixLen <= 0) return;

    final newSamples = Float64List.fromList(_clip!.samples);
    for (int i = 0; i < mixLen && i < samples.length; i++) {
      newSamples[insertSample + i] = (newSamples[insertSample + i] + samples[i] * 0.5).clamp(-1.0, 1.0);
    }
    _safeSetState(() {
      _clip = AudioClip(
        samples: newSamples,
        sampleRate: _clip!.sampleRate,
        sourceFile: _clip!.sourceFile,
        genParams: _clip!.genParams,
      );
    });
  }

  Widget _buildWaveformCards(ColorScheme cs) {
    return WaveformCards(onWaveformDropped: _onWaveformDropped);
  }

  Widget _buildTransportBar(ColorScheme cs) {
    final selText = _clip?.selection != null && _clip!.selection!.isValid
        ? 'Sel: ${_clip!.selection!.startSec.toStringAsFixed(1)}–${_clip!.selection!.endSec.toStringAsFixed(1)}s'
        : '';
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          _MiniBtn(
            icon: Icons.skip_previous_rounded,
            onTap: () => _safeSetState(() => _playheadSec = 0),
          ),
          const SizedBox(width: 4),
          _MiniBtn(
            icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            isPrimary: true,
            onTap: _togglePlayback,
          ),
          const SizedBox(width: 4),
          _MiniBtn(
            icon: Icons.stop_rounded,
            onTap: _stopPlayback,
          ),
          const SizedBox(width: 4),
          _MiniBtn(
            icon: Icons.skip_next_rounded,
            onTap: () => _clip != null
                ? _safeSetState(() => _playheadSec = _clip!.duration)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            '${_formatTime(_playheadSec)} / ${_formatTime(_clip?.duration ?? 0)}',
            style: TextStyle(color: cs.primary, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          if (selText.isNotEmpty)
            Text(selText, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          if (selText.isNotEmpty) const SizedBox(width: 8),
          if (_clip?.selection != null)
            TextButton.icon(
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Clear', style: TextStyle(fontSize: 10)),
              onPressed: _clearSelection,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
  }

  void _handleProcess(String action) {
    if (_clip == null) return;

    void applyAll(Float64List Function(Float64List) fn) {
      if (_clip!.selection != null && _clip!.selection!.isValid) {
        _applyToSelection(fn);
      } else {
        _clip!.samples.setAll(0, fn(Float64List.fromList(_clip!.samples)));
        _safeSetState(() {});
      }
    }

    switch (action) {
      case 'normalize':
        applyAll((s) => AudioProcessingService.normalizePeak(s));
        break;
      case 'reverse':
        applyAll((s) => AudioProcessingService.reverse(s));
        break;
      case 'removeDc':
        applyAll((s) => AudioProcessingService.removeDCOffset(s));
        break;
      case 'fadeIn':
        applyAll((s) => AudioProcessingService.fadeIn(s, 0.5, _clip!.sampleRate));
        break;
      case 'fadeOut':
        applyAll((s) => AudioProcessingService.fadeOut(s, 0.5, _clip!.sampleRate));
        break;
      case 'distort':
        applyAll((s) => AudioProcessingService.distort(s, 0.3));
        break;
      case 'delay':
        applyAll((s) => AudioProcessingService.delay(s, _clip!.sampleRate));
        break;
      case 'reverb':
        applyAll((s) => AudioProcessingService.reverb(s, _clip!.sampleRate));
        break;
    }
  }

  Future<void> _handleSplit(BuildContext context) async {
    if (_clip == null) return;
    final bands = await showFrequencySplitDialog(context, _clip!.duration);
    if (bands == null || bands.isEmpty) return;

    final results = FftService.splitBands(_clip!.samples, _clip!.sampleRate, bands);
    final projectNotifier = ref.read(projectProvider.notifier);

    for (int i = 0; i < results.length && i < bands.length; i++) {
      final band = bands[i];
      final label = '${_track?.name ?? "Split"}_${band.lowFreq.round()}-${band.highFreq.round()}Hz';
      final path = await _saveToWav(results[i], prefix: 'split_${i}_${DateTime.now().millisecondsSinceEpoch}');
      projectNotifier.addAudioTrack(name: label, audioFilePath: path);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Split into ${results.length} bands')),
      );
    }
  }

  String _formatTime(double seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toStringAsFixed(1).padLeft(4, '0');
    return '$m:$s';
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _MiniBtn({required this.icon, this.onTap, this.isPrimary = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: isPrimary ? cs.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(isPrimary ? 16 : 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isPrimary ? 16 : 4),
        child: Container(
          width: 32, height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 20,
              color: isPrimary ? Theme.of(context).scaffoldBackgroundColor : cs.onSurfaceVariant),
        ),
      ),
    );
  }
}
