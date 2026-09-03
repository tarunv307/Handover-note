import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../models/user.dart';
import '../models/task.dart';
import 'handover_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AppProvider>();
      p.fetchUsers();
      p.fetchTasks();
    });
  }

  void _showCreateTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int? selectedAssignee;

    final users = context.read<AppProvider>().users;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create New Task'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Task Title *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedAssignee,
                  decoration: const InputDecoration(labelText: 'Assign To Employee', border: OutlineInputBorder()),
                  items: users
                      .map((u) => DropdownMenuItem(
                            value: u.id,
                            child: Text('${u.name} (${u.employeeId ?? u.role})'),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => selectedAssignee = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final success = await context.read<AppProvider>().createTask(
                      titleCtrl.text.trim(),
                      descCtrl.text.trim(),
                      selectedAssignee,
                    );
                if (success && mounted) Navigator.pop(ctx);
              },
              child: const Text('Create Task'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(TaskItem task) {
    if (task.submission == null) return;
    final notesCtrl = TextEditingController(text: task.submission?.adminNotes ?? '');
    String status = 'completed';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Review Submission: ${task.title}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Submitted By: ${task.submission?.submitterName}'),
                const SizedBox(height: 8),
                if (task.submission?.link != null)
                  InkWell(
                    onTap: () => launchUrl(Uri.parse(task.submission!.link!)),
                    child: Text('🔗 Link: ${task.submission!.link}', style: const TextStyle(color: Colors.blue)),
                  ),
                if (task.submission?.hasFile == true) ...[
                  const SizedBox(height: 8),
                  Text('📦 Attached File: ${task.submission?.zipPath}'),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Admin Review Notes', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Update Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'completed', child: Text('Mark Complete (Approved)')),
                    DropdownMenuItem(value: 'pending', child: Text('Reject (Set Pending)')),
                  ],
                  onChanged: (val) => setState(() => status = val ?? 'completed'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final success = await context.read<AppProvider>().reviewSubmission(
                      task.submission!.id,
                      status,
                      notesCtrl.text.trim(),
                    );
                if (success && mounted) Navigator.pop(ctx);
              },
              child: const Text('Save Review'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('ShiftOps — Admin Portal', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 24),
            SizedBox(
              width: 280,
              height: 40,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => provider.performSearch(val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search people or tasks...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Text(user?.name.substring(0, 1) ?? 'A'),
                ),
                const SizedBox(width: 8),
                Text('${user?.name} (Admin)'),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => provider.logout(),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Employees & Users'),
            Tab(icon: Icon(Icons.task), text: 'All Tasks'),
            Tab(icon: Icon(Icons.rate_review), text: 'Submissions'),
            Tab(icon: Icon(Icons.note_alt), text: 'Shift Handover'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Users Tab
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Team Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add User'),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    child: ListView.separated(
                      itemCount: provider.users.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (ctx, idx) {
                        final u = provider.users[idx];
                        return ListTile(
                          leading: CircleAvatar(child: Text(u.name.substring(0, 1))),
                          title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${u.email}  •  ID: ${u.employeeId ?? "N/A"}'),
                          trailing: Chip(label: Text(u.role.toUpperCase())),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tasks Tab
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Assigned Work Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_task),
                      label: const Text('Create Task'),
                      onPressed: _showCreateTaskDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.tasks.length,
                    itemBuilder: (ctx, idx) {
                      final t = provider.tasks[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Assigned: ${t.assignedEmployeeName} (${t.assignedEmployeeId ?? ""})\n${t.description ?? ""}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Chip(label: Text(t.status.toUpperCase())),
                            ],
                          ),
                          onTap: t.submission != null ? () => _showReviewDialog(t) : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Submissions Tab
          Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: provider.tasks
                  .where((t) => t.submission != null)
                  .map((t) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Submitter: ${t.submission?.submitterName}\nLink: ${t.submission?.link ?? "Zip uploaded"}'),
                          trailing: ElevatedButton(
                            onPressed: () => _showReviewDialog(t),
                            child: const Text('Review'),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Handover Tab
          const HandoverScreen(),
        ],
      ),
    );
  }
}
