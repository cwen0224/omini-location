import 'package:flutter/material.dart';

import 'sensor_models.dart';

class SensorPageScaffold extends StatelessWidget {
  const SensorPageScaffold({
    super.key,
    required this.title,
    required this.summary,
    required this.status,
    required this.readings,
    this.actions = const [],
    this.footer,
  });

  final String title;
  final String summary;
  final SensorStatus status;
  final List<Widget> actions;
  final List<SensorReading> readings;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HeroCard(
            title: title,
            summary: summary,
            status: status,
            actions: actions,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: readings
                    .map(
                      (reading) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                reading.label,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Flexible(
                              child: Text(
                                reading.value,
                                textAlign: TextAlign.right,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 16),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.summary,
    required this.status,
    required this.actions,
  });

  final String title;
  final String summary;
  final SensorStatus status;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      SensorStatus.ready => Colors.green,
      SensorStatus.pending => Colors.orange,
      SensorStatus.blocked => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.95),
            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.92),
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Chip(
                label: Text(
                  switch (status) {
                    SensorStatus.ready => 'ready',
                    SensorStatus.pending => 'pending',
                    SensorStatus.blocked => 'blocked',
                  },
                ),
                backgroundColor: Colors.white,
                side: BorderSide(color: color),
              ),
              ...actions,
            ],
          ),
        ],
      ),
    );
  }
}

