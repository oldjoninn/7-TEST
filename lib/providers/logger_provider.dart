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
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<Position>? _locationSub;
  StreamSubscription<PlayerState>? _playerSub;

  final List<double> _motionReadings = [];
  Position? _currentPosition;

  // --- Recording ---

  Future<void> startRecording() async {
    if (isRecording) return;

    _motionReadings.clear();
    _currentPosition = null;

    // Permission check
    final hasPermissions = await _recorder.hasPermission();
    if (!hasPermissions) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    // Fetch initial position with a timeout to avoid hanging
    try {
      _currentPosition = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 10),
      );
    } catch (_) {
      _currentPosition = null;
    }

    // Stream live location updates
    _locationSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen(
          (pos) => _currentPosition = pos,
          onError: (_) {}, // silently ignore stream errors
        );

    // Accelerometer sampling every 250 ms
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

    // Stop sensors first so final readings are captured cleanly
    await _accelSub?.cancel();
    _accelSub = null;
    await _locationSub?.cancel();
    _locationSub = null;

    final path = await _recorder.stop();

    isRecording = false;

    if (path != null && _currentPosition != null) {
      final avgIntensity = _motionReadings.isEmpty
          ? 0.0
          : _motionReadings.reduce((a, b) => a + b) / _motionReadings.length;

      recordings.add(
        RecordingLog(
          filePath: path,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          averageMotionIntensity: avgIntensity,
        ),
      );
    }

    notifyListeners();
  }

  // --- Playback ---

  Future<void> togglePlayback(String filePath) async {
    if (isRecording) return;

    // Stop current playback regardless
    await _playerSub?.cancel();
    _playerSub = null;
    await _player.stop();

    if (currentlyPlayingPath == filePath) {
      // Tapping the same tile stops it
      currentlyPlayingPath = null;
      notifyListeners();
      return;
    }

    currentlyPlayingPath = filePath;
    notifyListeners();

    try {
      await _player.setFilePath(filePath);
      _player.play(); // fire-and-forget; state tracked via stream below

      _playerSub = _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          currentlyPlayingPath = null;
          notifyListeners();
        }
      });
    } catch (_) {
      // File unreadable or codec error — reset state gracefully
      currentlyPlayingPath = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    _accelSub?.cancel();
    _locationSub?.cancel();
    _playerSub?.cancel();
    super.dispose();
  }
}
