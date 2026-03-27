import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/logger_provider.dart';
import '../widgets/recording_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = context.watch<LoggerProvider>();

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
            icon: Icon(logger.isRecording ? Icons.stop : Icons.play_arrow),
            label: Text(
              logger.isRecording ? 'Stop Recording' : 'Start Recording',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: logger.isRecording ? Colors.red : Colors.black87,
            ),
            onPressed: () async {
              if (logger.isRecording) {
                await logger.stopRecording();
              } else if (logger.currentlyPlayingPath == null) {
                await logger.startRecording();
              }
            },
          ),
          const SizedBox(height: 16),
          // Recordings list
          Expanded(
            child: ListView.separated(
              itemCount: logger.recordings.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return RecordingTile(log: logger.recordings[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
