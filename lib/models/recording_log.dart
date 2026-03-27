class RecordingLog {
  final String filePath;
  final double latitude;
  final double longitude;
  final double averageMotionIntensity;

  const RecordingLog({
    required this.filePath,
    required this.latitude,
    required this.longitude,
    required this.averageMotionIntensity,
  });

  String get fileName => filePath.split('/').last;

  bool get isHighIntensity => averageMotionIntensity >= 15.0;

  @override
  String toString() =>
      'RecordingLog(file: $fileName, lat: $latitude, lon: $longitude, '
      'intensity: ${averageMotionIntensity.toStringAsFixed(2)})';
}
