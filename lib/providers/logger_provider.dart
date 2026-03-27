import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/recording_log.dart';
import 'package:path_provider/path_provider.dart';

class LoggerProvider extends ChangeNotifier {
  // --- State ---
  final List<RecordingLog> recordings = [];
  bool isRecording = false;
  String? currentlyPlayingPath;

  // --- Private internals ---
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  StreamSubscription? _accelSub;
  StreamSubscription? _locationSub;
  StreamSubscription? _playerSub;

  final List<double> _motionReadings = [];
  Position? _currentPosition;

  // --- Recording ---

  Future<void> startRecording() async {
    if (isRecording) return;

    _motionReadings.clear();

    // Permission Check
    final hasPermissions = await _recorder.hasPermission();
    if (!hasPermissions) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    // --- Location ---
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      _currentPosition = null;
    }

    _locationSub = Geolocator.getPositionStream().listen((pos) {
      _currentPosition = pos;
    });

    // Start accelerometer sampling every 250 ms
    _accelSub =
        accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 250),
        ).listen((event) {
          final magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );
          _motionReadings.add(magnitude);
        });

    // Start audio recording
    final dir = await getApplicationDocumentsDirectory();
    final path =
        '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    isRecording = true;
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;
    // Stop recording and get file path
    final path = await _recorder.stop();

    // If recording failed, just reset state
    if (path == null) {
      isRecording = false;
      notifyListeners();
      return;
    }
    // Stop sensors
    await _accelSub?.cancel();
    await _locationSub?.cancel();

    final avgIntensity = _motionReadings.isEmpty
        ? 0.0
        : _motionReadings.reduce((a, b) => a + b) / _motionReadings.length;

    if (_currentPosition != null) {
      recordings.add(
        RecordingLog(
          filePath: path,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          averageMotionIntensity: avgIntensity,
        ),
      );
    }

    isRecording = false;
    notifyListeners();
  }

  // --- Playback ---

  Future<void> togglePlayback(String filePath) async {
    if (isRecording) return; // block overlap

    if (currentlyPlayingPath == filePath) {
      await _player.stop();
      currentlyPlayingPath = null;
      notifyListeners();
      return;
    }

    // Stop anything already playing
    await _player.stop();
    currentlyPlayingPath = filePath;
    notifyListeners();

    await _player.setFilePath(filePath);
    _player.play();

    // Auto-stop when finished
    _playerSub?.cancel();
    _playerSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        currentlyPlayingPath = null;
        notifyListeners();
      }
    });
  }

  @override // Clean up resources
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _accelSub?.cancel();
    _locationSub?.cancel();
    _playerSub?.cancel();
    super.dispose();
  }
}
