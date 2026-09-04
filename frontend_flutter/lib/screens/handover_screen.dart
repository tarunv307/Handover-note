import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';

class HandoverScreen extends StatefulWidget {
  const HandoverScreen({super.key});

  @override
  State<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends State<HandoverScreen> {
  final _startCtrl = TextEditingController(text: '2026-09-03T14:00:00');
  final _endCtrl = TextEditingController(text: '2026-09-03T22:00:00');
  String _timezone = 'Asia/Kolkata';

  void _generate() async {
    final provider = context.read<AppProvider>();
    final success = await provider.generateShiftNote(
      _startCtrl.text.trim(),
      _endCtrl.text.trim(),
      _timezone,
    );
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Generation failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final note = provider.currentHandoverNote;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Generation Settings Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: Color(0xFF4F46E5), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Generate Shift Handover',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _startCtrl,
                    decoration: InputDecoration(
                      labelText: 'Shift Start (ISO)',
                      hintText: '2026-09-03T14:00:00',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _endCtrl,
                    decoration: InputDecoration(
                      labelText: 'Shift End (ISO)',
                      hintText: '2026-09-03T22:00:00',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _timezone,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Timezone',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Asia/Kolkata', child: Text('Asia/Kolkata (IST)')),
                      DropdownMenuItem(value: 'UTC', child: Text('UTC (Universal)')),
                      DropdownMenuItem(value: 'America/New_York', child: Text('New York (EDT)')),
                      DropdownMenuItem(value: 'Europe/London', child: Text('London (BST)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _timezone = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _generate,
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(provider.isLoading ? 'Generating...' : 'Generate Grounded Note'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Generated Note Display
          if (note != null) ...[
            Card(
              elevation: 1,
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Executive Shift Overview',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4F46E5)),
                    ),
                    const SizedBox(height: 8),
                    Text(note.summary, style: const TextStyle(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4F46E5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copy Slack Note'),
                          onPressed: () {
                            if (note.slackMarkdown != null) {
                              Clipboard.setData(ClipboardData(text: note.slackMarkdown!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Copied Slack markdown!')),
                              );
                            }
                          },
                        ),
                        if (note.downloadUrl != null)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                            label: const Text('Export PDF'),
                            onPressed: () {
                              launchUrl(Uri.parse(note.downloadUrl!));
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 4 Grounded Sections
            ...note.sections.entries.map((entry) {
              final secTitle = entry.key;
              final items = entry.value;

              Color sectionBadgeColor = Colors.green;
              if (secTitle.contains('Progress')) sectionBadgeColor = Colors.blue;
              if (secTitle.contains('Blockers')) sectionBadgeColor = Colors.red;
              if (secTitle.contains('Watch')) sectionBadgeColor = Colors.purple;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            secTitle,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: sectionBadgeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${items.length} items',
                              style: TextStyle(color: sectionBadgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      if (items.isEmpty)
                        const Text(
                          '• Nothing to report',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                        )
                      else
                        ...items.map((it) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(color: Colors.black87, fontSize: 12.5, height: 1.3),
                                        children: [
                                          TextSpan(text: it.item),
                                          TextSpan(
                                            text: '  [${it.source}]',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4F46E5),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
