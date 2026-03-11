class UpdateManifest {
  const UpdateManifest({
    required this.appVersion,
    required this.buildNumber,
    required this.releaseNotes,
    required this.apkUrl,
    required this.downloadPageUrl,
    required this.forceUpdate,
    required this.publishedAt,
    required this.contentVersion,
  });

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    return UpdateManifest(
      appVersion: json['app_version'] as String? ?? '0.0.0',
      buildNumber: json['build_number'] as int? ?? 0,
      releaseNotes: (json['release_notes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      apkUrl: json['apk_url'] as String? ?? '',
      downloadPageUrl: json['download_page_url'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
      publishedAt: json['published_at'] as String? ?? '',
      contentVersion: json['content_version'] as String? ?? '',
    );
  }

  final String appVersion;
  final int buildNumber;
  final List<String> releaseNotes;
  final String apkUrl;
  final String downloadPageUrl;
  final bool forceUpdate;
  final String publishedAt;
  final String contentVersion;
}

