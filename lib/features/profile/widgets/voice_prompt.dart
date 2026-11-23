import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../app/theme/colors.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/state/providers.dart';
import '../../../core/ui/api_errors.dart';
import '../../../core/widgets/app_toast.dart';

/// Record, play and remove the voice prompt (up to 30 s). Recorded as m4a,
/// uploaded to the private `audio-prompts` bucket, saved with `PUT /me/audio`.
class VoicePrompt extends ConsumerStatefulWidget {
  const VoicePrompt({super.key});
  @override
  ConsumerState<VoicePrompt> createState() => _VoicePromptState();
}

class _VoicePromptState extends ConsumerState<VoicePrompt> {
  static const _max = 30;
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  Timer? _tick;
  int _seconds = 0;
  bool _recording = false;
  bool _busy = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      final done = s.processingState == ProcessingState.completed;
      setState(() => _playing = s.playing && !done);
      if (done) _player.stop();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) showToast(context, 'Allow microphone access in Settings to record.', error: true);
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 96000), path: path);
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
      if (_seconds >= _max) _stop();
    });
  }

  Future<void> _stop() async {
    _tick?.cancel();
    final path = await _recorder.stop();
    setState(() => _recording = false);
    if (path == null || _seconds < 2) {
      if (mounted) showToast(context, 'That was a bit short — hold on for a few seconds.');
      return;
    }
    setState(() => _busy = true);
    try {
      final bytes = await File(path).readAsBytes();
      final stored = await ref.read(storageServiceProvider).upload(bucket: 'audio-prompts', bytes: bytes, ext: 'm4a');
      ref.read(meProvider.notifier).replace(await ref.read(apiClientProvider).put('/me/audio', data: {'path': stored}));
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      await _player.stop();
      ref.read(meProvider.notifier).replace(await ref.read(apiClientProvider).put('/me/audio', data: {'path': null}));
    } catch (e) {
      if (mounted) handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _togglePlay(String url) async {
    if (_playing) return _player.pause();
    try {
      await _player.setUrl(url);
      await _player.play();
    } catch (_) {
      if (mounted) showToast(context, 'Could not play the recording.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = ref.watch(meProvider).valueOrNull?.audioUrl;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(children: [
        IconButton.filled(
          style: IconButton.styleFrom(backgroundColor: _recording ? AppColors.error : AppColors.gold, foregroundColor: Colors.black),
          onPressed: _busy
              ? null
              : _recording
                  ? _stop
                  : url != null
                      ? () => _togglePlay(url)
                      : _start,
          icon: Icon(_recording
              ? Icons.stop_rounded
              : url != null
                  ? (_playing ? Icons.pause_rounded : Icons.play_arrow_rounded)
                  : Icons.mic_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _busy
                ? 'Saving…'
                : _recording
                    ? 'Recording… ${_max - _seconds}s left'
                    : url != null
                        ? 'Your voice prompt'
                        : 'Record a voice prompt (up to 30 s)',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        if (url != null && !_recording && !_busy) ...[
          IconButton(tooltip: 'Record again', onPressed: _start, icon: const Icon(Icons.refresh_rounded, color: Colors.white60)),
          IconButton(tooltip: 'Remove', onPressed: _remove, icon: const Icon(Icons.delete_outline_rounded, color: Colors.white60)),
        ],
      ]),
    );
  }
}
