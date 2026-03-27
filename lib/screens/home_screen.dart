import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/logger_provider.dart';
import '../widgets/recording_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Only rebuild the button row when isRecording / currentlyPlayingPath change
    final isRecording = context.select<LoggerProvider, bool>(
      (p) => p.isRecording,
    );
    final isPlaying = context.select<LoggerProvider, bool>(
      (p) => p.currentlyPlayingPath != null,
    );
    final recordingCount = context.select<LoggerProvider, int>(
      (p) => p.recordings.length,
    );

    // The record button is blocked while audio is playing to avoid overlapping
    // streams. isPlaying && !isRecording means we're in playback.
    final canRecord = !isPlaying || isRecording;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambience Logger'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),
          // Record / Stop button
          OutlinedButton.icon(
            icon: Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
            label: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isRecording
                  ? Colors.red
                  : canRecord
                  ? Colors.black87
                  : Colors.grey,
              side: BorderSide(
                color: isRecording
                    ? Colors.red
                    : canRecord
                    ? Colors.black45
                    : Colors.grey.shade300,
              ),
            ),
            onPressed: canRecord
                ? () async {
                    final logger = context.read<LoggerProvider>();
                    if (isRecording) {
                      await logger.stopRecording();
                    } else {
                      await logger.startRecording();
                    }
                  }
                : null,
          ),
          if (isPlaying && !isRecording)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Stop playback before recording',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          const SizedBox(height: 16),
          // Recordings list
          Expanded(
            child: recordingCount == 0
                ? Center(
                    child: Text(
                      'No recordings yet.\nTap Start Recording to begin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.separated(
                    itemCount: recordingCount,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      // Access provider directly so RecordingTile gets the log
                      final log = context
                          .read<LoggerProvider>()
                          .recordings[index];
                      return RecordingTile(
                        key: ValueKey(log.filePath),
                        log: log,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
