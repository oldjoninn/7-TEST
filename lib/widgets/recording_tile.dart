import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recording_log.dart';
import '../providers/logger_provider.dart';

class RecordingTile extends StatelessWidget {
  final RecordingLog log;
  const RecordingTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    // Use select so this tile only rebuilds when its own play state changes,
    // not whenever any other tile starts/stops.
    final isPlaying = context.select<LoggerProvider, bool>(
      (p) => p.currentlyPlayingPath == log.filePath,
    );
    final isRecording = context.select<LoggerProvider, bool>(
      (p) => p.isRecording,
    );

    final activeColor = Colors.pink[700]!;
    final activeBg = Colors.pink[50]!;

    return ListTile(
      tileColor: isPlaying ? activeBg : null,
      title: Text(
        log.fileName,
        style: TextStyle(
          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
          color: isPlaying ? Colors.pink[900] : null,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${log.latitude.toStringAsFixed(7)}, '
            '${log.longitude.toStringAsFixed(7)}',
            style: TextStyle(color: isPlaying ? activeColor : null),
          ),
          Row(
            children: [
              Text(
                'Motion: ${log.averageMotionIntensity.toStringAsFixed(2)}',
                style: TextStyle(color: isPlaying ? activeColor : null),
              ),
              if (log.isHighIntensity) ...[
                const SizedBox(width: 6),
                Icon(Icons.directions_run, size: 14, color: Colors.orange[700]),
                Text(
                  ' High',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      isThreeLine: true,
      trailing: IconButton(
        tooltip: isPlaying ? 'Stop' : 'Play',
        icon: Icon(
          isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline,
          color: isPlaying ? activeColor : null,
          size: 28,
        ),
        // Disable during recording; also disable other tiles while one plays
        // (but allow the currently-playing tile to be stopped).
        onPressed: isRecording
            ? null
            : () => context.read<LoggerProvider>().togglePlayback(log.filePath),
      ),
    );
  }
}
