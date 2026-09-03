import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/task.dart';
import 'handover_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchTasks();
    });
  }

  void _showSubmitDialog(TaskItem task) {
    final linkCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Submit Work: ${task.title}'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Provide your GitHub pull request / repository URL, Google Drive folder, or deployment link:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: linkCtrl,
                decoration: const InputDecoration(
                  labelText: 'Work / Submission Link *',
                  hintText: 'https://github.com/org/repo/pull/123',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (linkCtrl.text.trim().isEmpty) return;
              final success = await context.read<AppProvider>().submitTask(
                    task.id,
                    link: linkCtrl.text.trim(),
                  );
              if (success && mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Work submitted successfully!')),
                );
              }
            },
            child: const Text('Submit Work'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user?.name} (EMP ID: ${user?.employeeId ?? "N/A"})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => provider.logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.assignment), text: 'My Assigned Tasks'),
            Tab(icon: Icon(Icons.note_alt), text: 'Shift Handover Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tasks Tab
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Assigned Work Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: provider.tasks.isEmpty
                      ? const Center(child: Text('No tasks currently assigned to you.'))
                      : ListView.builder(
                          itemCount: provider.tasks.length,
                          itemBuilder: (ctx, idx) {
                            final t = provider.tasks[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(t.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        ),
                                        Chip(label: Text(t.status.toUpperCase())),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(t.description ?? 'No description provided.', style: const TextStyle(color: Colors.black87)),
                                    const SizedBox(height: 12),
                                    if (t.submission != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Submitted Link: ${t.submission?.link ?? ""}'),
                                            if (t.submission?.adminNotes != null)
                                              Text(
                                                'Admin Feedback: ${t.submission?.adminNotes}',
                                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.upload),
                                          label: const Text('Submit Work'),
                                          onPressed: () => _showSubmitDialog(t),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Handover Screen Tab
          const HandoverScreen(),
        ],
      ),
    );
  }
}
