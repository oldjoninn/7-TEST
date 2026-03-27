class RecordingLog {
  final String filePath;
  final double latitude;
  final double longitude;
  final double averageMotionIntensity;

  // Constructor
  RecordingLog({
    required this.filePath,
    required this.latitude,
    required this.longitude,
    required this.averageMotionIntensity,
  });
  // Getters
  String get fileName => filePath.split('/').last;

  bool get isHighIntensity => averageMotionIntensity >= 15;
}
