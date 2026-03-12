import 'handover_state.dart';
import 'quality_scores.dart';

class LocalizationState {
  const LocalizationState({
    required this.timestamp,
    required this.positionX,
    required this.positionY,
    required this.positionZ,
    required this.velocityX,
    required this.velocityY,
    required this.velocityZ,
    required this.yawDeg,
    required this.confidence,
    required this.qualityScores,
    required this.handoverState,
    this.metadata = const <String, dynamic>{},
  });

  factory LocalizationState.initial() {
    return LocalizationState(
      timestamp: DateTime.now(),
      positionX: 0,
      positionY: 0,
      positionZ: 0,
      velocityX: 0,
      velocityY: 0,
      velocityZ: 0,
      yawDeg: 0,
      confidence: 0,
      qualityScores: const SensorQualityScores(
        gps: 0,
        imu: 0,
        compass: 0,
        ble: 0,
        camera: 0,
      ),
      handoverState: HandoverState(
        mode: EnvironmentMode.transition,
        startedAt: DateTime.now(),
        reason: 'initial_state',
      ),
    );
  }

  final DateTime timestamp;
  final double positionX;
  final double positionY;
  final double positionZ;
  final double velocityX;
  final double velocityY;
  final double velocityZ;
  final double yawDeg;
  final double confidence;
  final SensorQualityScores qualityScores;
  final HandoverState handoverState;
  final Map<String, dynamic> metadata;

  LocalizationState copyWith({
    DateTime? timestamp,
    double? positionX,
    double? positionY,
    double? positionZ,
    double? velocityX,
    double? velocityY,
    double? velocityZ,
    double? yawDeg,
    double? confidence,
    SensorQualityScores? qualityScores,
    HandoverState? handoverState,
    Map<String, dynamic>? metadata,
  }) {
    return LocalizationState(
      timestamp: timestamp ?? this.timestamp,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      positionZ: positionZ ?? this.positionZ,
      velocityX: velocityX ?? this.velocityX,
      velocityY: velocityY ?? this.velocityY,
      velocityZ: velocityZ ?? this.velocityZ,
      yawDeg: yawDeg ?? this.yawDeg,
      confidence: confidence ?? this.confidence,
      qualityScores: qualityScores ?? this.qualityScores,
      handoverState: handoverState ?? this.handoverState,
      metadata: metadata ?? this.metadata,
    );
  }
}
