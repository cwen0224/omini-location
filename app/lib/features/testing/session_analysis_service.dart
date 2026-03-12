import '../../domain/localization/quality_scores.dart';
import 'session_replay_models.dart';

class SessionAnalysisResult {
  const SessionAnalysisResult({
    required this.qualityScores,
    required this.gpsSampleCount,
    required this.feedbackCount,
    required this.unstableFeedbackCount,
    required this.averageGpsAccuracy,
    required this.averageBleVisibleCount,
    required this.cameraReadyRatio,
  });

  final SensorQualityScores qualityScores;
  final int gpsSampleCount;
  final int feedbackCount;
  final int unstableFeedbackCount;
  final double averageGpsAccuracy;
  final double averageBleVisibleCount;
  final double cameraReadyRatio;
}

class SessionAnalysisService {
  const SessionAnalysisService();

  SessionAnalysisResult analyze(SessionReplayBundle bundle) {
    final gpsSamples =
        bundle.samples.where((sample) => sample.gpsLat != null && sample.gpsLng != null).toList();
    final gpsAccuracies = gpsSamples
        .map((sample) => sample.gpsAccuracy)
        .whereType<double>()
        .toList();
    final bleCounts = bundle.samples
        .map((sample) => sample.bleVisibleCount)
        .whereType<int>()
        .toList();
    final cameraReadyCount = bundle.samples
        .where((sample) => sample.cameraTrackingState == 'ready')
        .length;
    final unstableFeedbackCount = bundle.feedback
        .where((item) => item.value == 'unstable')
        .length;

    final averageGpsAccuracy = gpsAccuracies.isEmpty
        ? 0.0
        : gpsAccuracies.reduce((left, right) => left + right) / gpsAccuracies.length;
    final averageBleVisibleCount = bleCounts.isEmpty
        ? 0.0
        : bleCounts.reduce((left, right) => left + right) / bleCounts.length;
    final cameraReadyRatio = bundle.samples.isEmpty
        ? 0.0
        : cameraReadyCount / bundle.samples.length;

    final gpsQuality = gpsAccuracies.isEmpty
        ? 0.0
        : (1 / (1 + averageGpsAccuracy / 5)).clamp(0.0, 1.0);
    final bleQuality = (averageBleVisibleCount / 5).clamp(0.0, 1.0);
    final cameraQuality = cameraReadyRatio.clamp(0.0, 1.0);
    final compassQuality = bundle.samples.any((sample) => sample.heading != null) ? 0.7 : 0.0;
    final imuQuality = bundle.samples.isNotEmpty ? 0.6 : 0.0;

    return SessionAnalysisResult(
      qualityScores: SensorQualityScores(
        gps: gpsQuality,
        imu: imuQuality,
        compass: compassQuality,
        ble: bleQuality,
        camera: cameraQuality,
      ),
      gpsSampleCount: gpsSamples.length,
      feedbackCount: bundle.feedback.length,
      unstableFeedbackCount: unstableFeedbackCount,
      averageGpsAccuracy: averageGpsAccuracy,
      averageBleVisibleCount: averageBleVisibleCount,
      cameraReadyRatio: cameraReadyRatio,
    );
  }
}
