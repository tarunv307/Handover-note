class HandoverItem {
  final String section;
  final String item;
  final String source;
  final String recordId;
  final String? timestamp;
  final String? timestampUtc;
  final String? status;
  final String? assignee;
  final Map<String, dynamic>? raw;

  HandoverItem({
    required this.section,
    required this.item,
    required this.source,
    required this.recordId,
    this.timestamp,
    this.timestampUtc,
    this.status,
    this.assignee,
    this.raw,
  });

  factory HandoverItem.fromJson(Map<String, dynamic> json) {
    return HandoverItem(
      section: json['section'] ?? 'Watch-List',
      item: json['item'] ?? '',
      source: json['source'] ?? '',
      recordId: json['record_id'] ?? '',
      timestamp: json['timestamp'],
      timestampUtc: json['timestamp_utc'],
      status: json['status'],
      assignee: json['assignee'],
      raw: json['raw'],
    );
  }
}

class HandoverNote {
  final String id;
  final String summary;
  final String generatedAtUtc;
  final int totalItems;
  final String? slackMarkdown;
  final String? downloadUrl;
  final Map<String, List<HandoverItem>> sections;

  HandoverNote({
    required this.id,
    required this.summary,
    required this.generatedAtUtc,
    required this.totalItems,
    this.slackMarkdown,
    this.downloadUrl,
    required this.sections,
  });

  factory HandoverNote.fromJson(Map<String, dynamic> json, {String? downloadUrl}) {
    final noteMap = json['note'] ?? json;
    final sectionsMap = <String, List<HandoverItem>>{};
    
    if (noteMap['sections'] != null) {
      (noteMap['sections'] as Map<String, dynamic>).forEach((key, val) {
        if (val is List) {
          sectionsMap[key] = val.map((i) => HandoverItem.fromJson(i)).toList();
        }
      });
    }

    return HandoverNote(
      id: noteMap['id'] ?? '',
      summary: noteMap['summary'] ?? '',
      generatedAtUtc: noteMap['generated_at_utc'] ?? '',
      totalItems: noteMap['total_items'] ?? 0,
      slackMarkdown: noteMap['slack_markdown'],
      downloadUrl: downloadUrl ?? json['download_url'],
      sections: sectionsMap,
    );
  }
}
