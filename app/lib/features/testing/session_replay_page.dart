import 'package:flutter/material.dart';

import '../../core/remote_sync_service.dart';
import '../../domain/localization/handover_state.dart';
import 'session_analysis_service.dart';
import 'session_replay_models.dart';

class SessionReplayPage extends StatefulWidget {
  const SessionReplayPage({super.key});

  @override
  State<SessionReplayPage> createState() => _SessionReplayPageState();
}

class _SessionReplayPageState extends State<SessionReplayPage> {
  final SessionAnalysisService _analysisService = const SessionAnalysisService();
  List<SessionReplayRecord> _sessions = const <SessionReplayRecord>[];
  SessionReplayBundle? _bundle;
  SessionAnalysisResult? _analysis;
  String _status = '載入中...';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _loading = true;
      _status = '載入最近 session...';
    });

    try {
      final sessions = await RemoteSyncService.instance.fetchRecentSessions();
      SessionReplayBundle? bundle;
      SessionAnalysisResult? analysis;
      if (sessions.isNotEmpty) {
        bundle = await RemoteSyncService.instance.fetchSessionReplayBundle(
          sessions.first.sessionId,
        );
        analysis = _analysisService.analyze(bundle);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _sessions = sessions;
        _bundle = bundle;
        _analysis = analysis;
        _loading = false;
        _status = sessions.isEmpty ? '目前沒有 session' : '已載入最新 session';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _status = '載入失敗：$error';
      });
    }
  }

  Future<void> _openSession(SessionReplayRecord session) async {
    setState(() {
      _loading = true;
      _status = '載入指定 session...';
    });

    try {
      final bundle = await RemoteSyncService.instance.fetchSessionReplayBundle(
        session.sessionId,
      );
      final analysis = _analysisService.analyze(bundle);

      if (!mounted) {
        return;
      }
      setState(() {
        _bundle = bundle;
        _analysis = analysis;
        _loading = false;
        _status = '已載入 ${session.sessionName}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _status = '載入失敗：$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom + 24;

    return Scaffold(
      appBar: AppBar(title: const Text('Session Replay / 分析')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_status, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loading ? null : _loadSessions,
                      child: Text(_loading ? '載入中...' : '重新整理'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('最近 Sessions',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ..._sessions.map(
                      (session) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(session.sessionName),
                        subtitle: Text('${session.testType} | ${session.createdAt}'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openSession(session),
                      ),
                    ),
                    if (_sessions.isEmpty)
                      const Text('尚未取得任何 session'),
                  ],
                ),
              ),
            ),
            if (_bundle != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session 摘要',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('名稱：${_bundle!.session.sessionName}'),
                      Text('類型：${_bundle!.session.testType}'),
                      Text('樣本數：${_bundle!.samples.length}'),
                      Text('回饋數：${_bundle!.feedback.length}'),
                      Text('動作段數：${_bundle!.segments.length}'),
                      Text('真值點數：${_bundle!.groundTruthPoints.length}'),
                      Text('衍生指標數：${_bundle!.derivedMetrics.length}'),
                    ],
                  ),
                ),
              ),
            ],
            if (_analysis != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quality Scores',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('GPS: ${_analysis!.qualityScores.gps.toStringAsFixed(2)}'),
                      Text('IMU: ${_analysis!.qualityScores.imu.toStringAsFixed(2)}'),
                      Text(
                        'Compass: ${_analysis!.qualityScores.compass.toStringAsFixed(2)}',
                      ),
                      Text('BLE: ${_analysis!.qualityScores.ble.toStringAsFixed(2)}'),
                      Text(
                        'Camera: ${_analysis!.qualityScores.camera.toStringAsFixed(2)}',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '平均 GPS 精度：${_analysis!.averageGpsAccuracy.toStringAsFixed(2)} m',
                      ),
                      Text(
                        '平均 BLE 可見數：${_analysis!.averageBleVisibleCount.toStringAsFixed(2)}',
                      ),
                      Text(
                        'Camera ready 比例：${(_analysis!.cameraReadyRatio * 100).toStringAsFixed(0)}%',
                      ),
                      Text('不穩定回饋數：${_analysis!.unstableFeedbackCount}'),
                      Text(
                        'Segment 完成率：${(_analysis!.segmentCompletionRatio * 100).toStringAsFixed(0)}%',
                      ),
                      Text('建議模式：${_modeLabel(_analysis!.recommendedMode)}'),
                      Text(
                        '最終信心：${(_analysis!.finalState.confidence * 100).toStringAsFixed(0)}%',
                      ),
                      Text(
                        '最終位置：(${_analysis!.finalState.positionX.toStringAsFixed(1)}, ${_analysis!.finalState.positionY.toStringAsFixed(1)})',
                      ),
                      Text(
                        '最終朝向：${_analysis!.finalState.yawDeg.toStringAsFixed(1)}°',
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_bundle != null && _bundle!.segments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Action Segments',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._bundle!.segments.map(
                        (segment) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(segment.metadata['title']?.toString() ?? segment.actionType),
                          subtitle: Text(
                            '${segment.actionType} | ${segment.startedAt}'
                            '${segment.targetDistanceM == null ? '' : ' | ${segment.targetDistanceM}m'}'
                            '${segment.targetHeadingDeg == null ? '' : ' | ${segment.targetHeadingDeg}°'}',
                          ),
                          trailing: Icon(
                            segment.operatorConfirmed
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: segment.operatorConfirmed
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_bundle != null && _bundle!.groundTruthPoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ground Truth',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._bundle!.groundTruthPoints.map(
                        (point) => Text(
                          '${point.pointLabel} | ${point.source} | '
                          '(${point.mapX?.toStringAsFixed(1) ?? '-'}, ${point.mapY?.toStringAsFixed(1) ?? '-'})'
                          '${point.headingDeg == null ? '' : ' | ${point.headingDeg!.toStringAsFixed(1)}°'}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_analysis != null && _analysis!.timeline.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Replay Timeline',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._analysis!.timeline.take(12).map(
                        (point) => Text(
                          '${point.sampleTime} | ${_modeLabel(point.mode)} | '
                          'XY=(${point.positionX.toStringAsFixed(1)}, ${point.positionY.toStringAsFixed(1)}) | '
                          'Heading=${point.headingDeg.toStringAsFixed(1)}° | '
                          'Conf=${(point.confidence * 100).toStringAsFixed(0)}%',
                        ),
                      ),
                      if (_analysis!.timeline.length > 12)
                        Text('... 共 ${_analysis!.timeline.length} 筆回放點'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _modeLabel(EnvironmentMode mode) {
    return switch (mode) {
      EnvironmentMode.outdoor => 'Outdoor',
      EnvironmentMode.transition => 'Transition',
      EnvironmentMode.indoor => 'Indoor',
    };
  }
}
