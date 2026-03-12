import 'dart:math' as math;

import '../../domain/localization/ekf_localization_service.dart';
import '../../domain/localization/handover_state.dart';
import '../../domain/localization/localization_state.dart';
import '../../domain/localization/measurement.dart';
import '../../domain/localization/quality_scores.dart';
import 'session_replay_models.dart';

class ReplayTimelinePoint {
  const ReplayTimelinePoint({
    required this.sampleTime,
    required this.positionX,
    required this.positionY,
    required this.headingDeg,
    required this.confidence,
    required this.mode,
  });

  final String sampleTime;
  final double positionX;
  final double positionY;
  final double headingDeg;
  final double confidence;
  final EnvironmentMode mode;
}

class SessionAnalysisResult {
  const SessionAnalysisResult({
    required this.qualityScores,
    required this.gpsSampleCount,
    required this.feedbackCount,
    required this.unstableFeedbackCount,
    required this.averageGpsAccuracy,
    required this.averageBleVisibleCount,
    required this.cameraReadyRatio,
    required this.segmentCount,
    required this.completedSegmentCount,
    required this.groundTruthCount,
    required this.derivedMetricCount,
    required this.recommendedMode,
    required this.finalState,
    required this.timeline,
  });

  final SensorQualityScores qualityScores;
  final int gpsSampleCount;
  final int feedbackCount;
  final int unstableFeedbackCount;
  final double averageGpsAccuracy;
  final double averageBleVisibleCount;
  final double cameraReadyRatio;
  final int segmentCount;
  final int completedSegmentCount;
  final int groundTruthCount;
  final int derivedMetricCount;
  final EnvironmentMode recommendedMode;
  final LocalizationState finalState;
  final List<ReplayTimelinePoint> timeline;

  double get segmentCompletionRatio =>
      segmentCount == 0 ? 0 : completedSegmentCount / segmentCount;
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
    final cameraScores = bundle.samples
        .map((sample) => sample.cameraFeatureScore)
        .whereType<double>()
        .toList();
    final cameraReadyCount = bundle.samples
        .where((sample) => sample.cameraTrackingState == 'ready')
        .length;
    final unstableFeedbackCount = bundle.feedback
        .where((item) => item.value == 'unstable')
        .length;
    final completedSegmentCount = bundle.segments
        .where((segment) => segment.operatorConfirmed)
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
    final averageCameraScore = cameraScores.isEmpty
        ? 0.0
        : cameraScores.reduce((left, right) => left + right) / cameraScores.length;

    final gpsQuality = gpsAccuracies.isEmpty
        ? 0.0
        : (1 / (1 + averageGpsAccuracy / 5)).clamp(0.0, 1.0);
    final bleQuality = (averageBleVisibleCount / 5).clamp(0.0, 1.0);
    final cameraQuality = ((cameraReadyRatio * 0.6) + (averageCameraScore * 0.4)).clamp(0.0, 1.0);
    final compassQuality = _computeCompassQuality(bundle);
    final imuQuality = _computeImuQuality(bundle);
    final qualityScores = SensorQualityScores(
      gps: gpsQuality,
      imu: imuQuality,
      compass: compassQuality,
      ble: bleQuality,
      camera: cameraQuality,
    );
    final recommendedMode = _inferEnvironmentMode(
      gpsQuality: gpsQuality,
      bleQuality: bleQuality,
      cameraQuality: cameraQuality,
    );
    final replayResult = _runReplay(bundle, qualityScores, recommendedMode);

    return SessionAnalysisResult(
      qualityScores: qualityScores,
      gpsSampleCount: gpsSamples.length,
      feedbackCount: bundle.feedback.length,
      unstableFeedbackCount: unstableFeedbackCount,
      averageGpsAccuracy: averageGpsAccuracy,
      averageBleVisibleCount: averageBleVisibleCount,
      cameraReadyRatio: cameraReadyRatio,
      segmentCount: bundle.segments.length,
      completedSegmentCount: completedSegmentCount,
      groundTruthCount: bundle.groundTruthPoints.length,
      derivedMetricCount: bundle.derivedMetrics.length,
      recommendedMode: recommendedMode,
      finalState: replayResult.$1,
      timeline: replayResult.$2,
    );
  }

  double _computeImuQuality(SessionReplayBundle bundle) {
    final accelTriples = bundle.samples
        .where(
          (sample) => sample.accelX != null && sample.accelY != null && sample.accelZ != null,
        )
        .length;
    if (bundle.samples.isEmpty) {
      return 0.0;
    }
    return (accelTriples / bundle.samples.length).clamp(0.0, 1.0);
  }

  double _computeCompassQuality(SessionReplayBundle bundle) {
    final headingSamples = bundle.samples.where((sample) => sample.heading != null).length;
    if (bundle.samples.isEmpty) {
      return 0.0;
    }
    return (headingSamples / bundle.samples.length).clamp(0.0, 1.0);
  }

  EnvironmentMode _inferEnvironmentMode({
    required double gpsQuality,
    required double bleQuality,
    required double cameraQuality,
  }) {
    if (gpsQuality >= 0.65 && bleQuality < 0.4) {
      return EnvironmentMode.outdoor;
    }
    if (bleQuality >= 0.45 || cameraQuality >= 0.55) {
      return EnvironmentMode.indoor;
    }
    return EnvironmentMode.transition;
  }

  (LocalizationState, List<ReplayTimelinePoint>) _runReplay(
    SessionReplayBundle bundle,
    SensorQualityScores qualityScores,
    EnvironmentMode mode,
  ) {
    final service = EkfLocalizationService();
    final timeline = <ReplayTimelinePoint>[];
    final gpsOrigin = bundle.samples.firstWhere(
      (sample) => sample.gpsLat != null && sample.gpsLng != null,
      orElse: () => const SensorSampleRecord(sampleTime: ''),
    );
    final originLat = gpsOrigin.gpsLat;
    final originLng = gpsOrigin.gpsLng;
    final handoverState = HandoverState(
      mode: mode,
      startedAt: DateTime.now(),
      reason: 'session_replay',
    );
    DateTime? previousTime;

    for (final sample in bundle.samples) {
      final timestamp = DateTime.tryParse(sample.sampleTime) ?? DateTime.now();
      final dtSeconds = previousTime == null
          ? 1.0
          : timestamp.difference(previousTime!).inMilliseconds / 1000.0;
      previousTime = timestamp;

      final accelForward = sample.accelY ?? sample.accelX ?? 0.0;
      final yawRate = sample.gyroZ ?? 0.0;
      service.predict(
        timestamp: timestamp,
        dtSeconds: dtSeconds <= 0 ? 1.0 : dtSeconds.clamp(0.02, 2.0),
        accelForward: accelForward,
        yawRateDegPerSec: yawRate,
        qualityScores: qualityScores,
        handoverState: handoverState,
      );

      if (originLat != null &&
          originLng != null &&
          sample.gpsLat != null &&
          sample.gpsLng != null) {
        final projected = _projectGpsToLocalMeters(
          originLat: originLat,
          originLng: originLng,
          lat: sample.gpsLat!,
          lng: sample.gpsLng!,
        );
        service.update(
          LocalizationMeasurement(
            type: MeasurementType.gps,
            timestamp: timestamp,
            quality: qualityScores.gps,
            positionX: projected.$1,
            positionY: projected.$2,
            headingDeg: sample.heading,
            metadata: <String, dynamic>{
              'gps_accuracy': sample.gpsAccuracy,
            },
          ),
        );
      }

      if (sample.heading != null) {
        service.update(
          LocalizationMeasurement(
            type: MeasurementType.compass,
            timestamp: timestamp,
            quality: qualityScores.compass,
            headingDeg: sample.heading,
          ),
        );
      }

      if (sample.cameraTrackingState == 'ready' &&
          sample.cameraFeatureScore != null &&
          sample.cameraFeatureScore! > 0.5 &&
          bundle.groundTruthPoints.isNotEmpty) {
        final point = bundle.groundTruthPoints.lastWhere(
          (item) => item.mapX != null && item.mapY != null,
          orElse: () => const GroundTruthPointRecord(pointLabel: '', source: ''),
        );
        if (point.mapX != null && point.mapY != null) {
          service.update(
            LocalizationMeasurement(
              type: MeasurementType.cameraPose,
              timestamp: timestamp,
              quality: qualityScores.camera,
              positionX: point.mapX,
              positionY: point.mapY,
              positionZ: point.mapZ,
              headingDeg: point.headingDeg ?? sample.heading,
            ),
          );
        }
      }

      final state = service.state;
      timeline.add(
        ReplayTimelinePoint(
          sampleTime: sample.sampleTime,
          positionX: state.positionX,
          positionY: state.positionY,
          headingDeg: state.yawDeg,
          confidence: state.confidence,
          mode: state.handoverState.mode,
        ),
      );
    }

    return (service.state, timeline);
  }

  (double, double) _projectGpsToLocalMeters({
    required double originLat,
    required double originLng,
    required double lat,
    required double lng,
  }) {
    const earthRadius = 6378137.0;
    final dLat = (lat - originLat) * 3.141592653589793 / 180.0;
    final dLng = (lng - originLng) * 3.141592653589793 / 180.0;
    final meanLat = ((lat + originLat) / 2) * 3.141592653589793 / 180.0;
    final x = dLng * earthRadius * math.cos(meanLat);
    final y = dLat * earthRadius;
    return (x, y);
  }
}
