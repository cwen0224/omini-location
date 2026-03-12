import 'handover_state.dart';
import 'localization_state.dart';
import 'measurement.dart';
import 'quality_scores.dart';

class EkfLocalizationService {
  LocalizationState _state = LocalizationState.initial();

  LocalizationState get state => _state;

  void reset() {
    _state = LocalizationState.initial();
  }

  LocalizationState predict({
    required DateTime timestamp,
    required double dtSeconds,
    required double accelForward,
    required double yawRateDegPerSec,
    required SensorQualityScores qualityScores,
    required HandoverState handoverState,
  }) {
    final nextYaw = _state.yawDeg + yawRateDegPerSec * dtSeconds;
    final speedX = _state.velocityX + accelForward * dtSeconds;
    final predictedX = _state.positionX + speedX * dtSeconds;
    final predictedY = _state.positionY + _state.velocityY * dtSeconds;

    _state = _state.copyWith(
      timestamp: timestamp,
      positionX: predictedX,
      positionY: predictedY,
      velocityX: speedX,
      yawDeg: nextYaw,
      qualityScores: qualityScores,
      handoverState: handoverState,
      confidence: _computeConfidence(qualityScores, handoverState.mode),
      metadata: <String, dynamic>{
        ..._state.metadata,
        'last_step': 'predict',
      },
    );

    return _state;
  }

  LocalizationState update(LocalizationMeasurement measurement) {
    final qualityWeight = measurement.quality.clamp(0.0, 1.0);

    switch (measurement.type) {
      case MeasurementType.gps:
      case MeasurementType.cameraPose:
      case MeasurementType.bleRange:
      case MeasurementType.bleZone:
        _state = _state.copyWith(
          timestamp: measurement.timestamp,
          positionX: _blend(_state.positionX, measurement.positionX, qualityWeight),
          positionY: _blend(_state.positionY, measurement.positionY, qualityWeight),
          positionZ: _blend(_state.positionZ, measurement.positionZ, qualityWeight),
          yawDeg: measurement.headingDeg == null
              ? _state.yawDeg
              : _blend(_state.yawDeg, measurement.headingDeg, qualityWeight),
          metadata: <String, dynamic>{
            ..._state.metadata,
            'last_step': 'update_${measurement.type.name}',
          },
        );
      case MeasurementType.compass:
        _state = _state.copyWith(
          timestamp: measurement.timestamp,
          yawDeg: _blend(_state.yawDeg, measurement.headingDeg, qualityWeight),
          metadata: <String, dynamic>{
            ..._state.metadata,
            'last_step': 'update_compass',
          },
        );
    }

    return _state;
  }

  double _computeConfidence(
    SensorQualityScores scores,
    EnvironmentMode mode,
  ) {
    final scoreMap = scores.toMap();
    final base = switch (mode) {
      EnvironmentMode.outdoor => scoreMap['gps']! * 0.5 + scoreMap['imu']! * 0.2 + scoreMap['camera']! * 0.1 + scoreMap['ble']! * 0.1 + scoreMap['compass']! * 0.1,
      EnvironmentMode.transition => scoreMap['gps']! * 0.25 + scoreMap['imu']! * 0.2 + scoreMap['camera']! * 0.2 + scoreMap['ble']! * 0.2 + scoreMap['compass']! * 0.15,
      EnvironmentMode.indoor => scoreMap['gps']! * 0.05 + scoreMap['imu']! * 0.25 + scoreMap['camera']! * 0.3 + scoreMap['ble']! * 0.25 + scoreMap['compass']! * 0.15,
    };
    return base.clamp(0.0, 1.0);
  }

  double _blend(double current, double? observed, double weight) {
    if (observed == null) {
      return current;
    }
    return current * (1 - weight) + observed * weight;
  }
}
