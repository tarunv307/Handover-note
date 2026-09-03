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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Config Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shift Handover Generator',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: 240,
                        child: TextField(
                          controller: _startCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Shift Start (ISO)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 240,
                        child: TextField(
                          controller: _endCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Shift End (ISO)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String>(
                          value: _timezone,
                          decoration: const InputDecoration(
                            labelText: 'Timezone',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Asia/Kolkata', child: Text('Asia/Kolkata (IST)')),
                            DropdownMenuItem(value: 'UTC', child: Text('UTC')),
                            DropdownMenuItem(value: 'America/New_York', child: Text('New York (EDT)')),
                            DropdownMenuItem(value: 'Europe/London', child: Text('London (BST)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _timezone = val);
                          },
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: provider.isLoading ? null : _generate,
                        icon: const Icon(Icons.flash_on),
                        label: const Text('Generate Note'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Generated Note Display
          if (note != null) ...[
            Card(
              color: Colors.indigo.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Executive Shift Summary',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy Slack Markdown'),
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
                                icon: const Icon(Icons.picture_as_pdf, size: 16),
                                label: const Text('Download PDF'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                onPressed: () {
                                  launchUrl(Uri.parse(note.downloadUrl!));
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(note.summary, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...note.sections.entries.map((entry) {
              final secTitle = entry.key;
              final items = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$secTitle (${items.length} items)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      if (items.isEmpty)
                        const Text(
                          '• Nothing to report',
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        )
                      else
                        ...items.map((it) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• '),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(color: Colors.black87, fontSize: 13),
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
