import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recording_log.dart';
import '../providers/logger_provider.dart';

class RecordingTile extends StatelessWidget {
  final RecordingLog log;
  const RecordingTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final logger = context.watch<LoggerProvider>();
    final isPlaying = logger.currentlyPlayingPath == log.filePath;

    return ListTile(
      tileColor: isPlaying ? Colors.pink[50] : null,
      title: Text(
        log.fileName,
        style: TextStyle(
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
          color: isPlaying ? Colors.pink[900] : null,
        ),
      ),
      subtitle: Text(
        '(${log.latitude.toStringAsFixed(7)}, ${log.longitude.toStringAsFixed(7)})\n'
        'Motion intensity: ${log.averageMotionIntensity.toStringAsFixed(5)}',
        style: TextStyle(color: isPlaying ? Colors.pink[700] : null),
      ),
      isThreeLine: true,
      trailing: IconButton(
        icon: Icon(
          isPlaying ? Icons.stop : Icons.play_arrow,
          color: isPlaying ? Colors.pink[700] : null,
        ),
        onPressed: logger.isRecording
            ? null // can't play while recording
            : () => logger.togglePlayback(log.filePath),
      ),
    );
  }
}
