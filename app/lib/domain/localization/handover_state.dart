enum EnvironmentMode {
  outdoor,
  transition,
  indoor,
}

class HandoverState {
  const HandoverState({
    required this.mode,
    required this.startedAt,
    this.reason = '',
  });

  final EnvironmentMode mode;
  final DateTime startedAt;
  final String reason;
}
