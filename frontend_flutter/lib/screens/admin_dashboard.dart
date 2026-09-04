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
  bool _showSearch = false;

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Create New Task'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
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
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Assign To Employee', border: OutlineInputBorder()),
                    items: users
                        .map((u) => DropdownMenuItem(
                              value: u.id,
                              child: Text(
                                '${u.name} (${u.employeeId ?? u.role})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => selectedAssignee = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Review: ${task.title}', overflow: TextOverflow.ellipsis),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Submitted By: ${task.submission?.submitterName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (task.submission?.link != null) ...[
                    InkWell(
                      onTap: () => launchUrl(Uri.parse(task.submission!.link!)),
                      child: Text('🔗 ${task.submission!.link}', style: const TextStyle(color: Color(0xFF4F46E5))),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (task.submission?.hasFile == true) ...[
                    Text('📦 Attached File: ${task.submission?.zipPath}', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Admin Review Notes', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    isExpanded: true,
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
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
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
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 0,
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => provider.performSearch(val.trim()),
                decoration: const InputDecoration(
                  hintText: 'Search people or tasks...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : const Text('ShiftOps Admin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchCtrl.clear();
                  provider.performSearch('');
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => provider.logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_outlined), text: 'Users'),
            Tab(icon: Icon(Icons.task_alt_outlined), text: 'Tasks'),
            Tab(icon: Icon(Icons.rate_review_outlined), text: 'Reviews'),
            Tab(icon: Icon(Icons.description_outlined), text: 'Handover'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Users Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Team Directory (${provider.users.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Add User'),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: provider.users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final u = provider.users[idx];
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: u.role == 'admin' ? const Color(0xFF4F46E5) : Colors.teal,
                            foregroundColor: Colors.white,
                            child: Text(u.name.substring(0, 1).toUpperCase()),
                          ),
                          title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${u.email}\nID: ${u.employeeId ?? "N/A"}', style: const TextStyle(fontSize: 12)),
                          isThreeLine: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: u.role == 'admin' ? Colors.indigo.shade50 : Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              u.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: u.role == 'admin' ? const Color(0xFF4F46E5) : Colors.teal.shade800,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 2. Tasks Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('All Tasks (${provider.tasks.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.add_task, size: 18),
                      label: const Text('Create Task'),
                      onPressed: _showCreateTaskDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: provider.tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final t = provider.tasks[idx];
                      Color badgeColor = Colors.orange;
                      if (t.status == 'completed') badgeColor = Colors.green;
                      if (t.status == 'submitted') badgeColor = Colors.blue;

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.title,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      t.status.toUpperCase(),
                                      style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('👤 Assigned to: ${t.assignedEmployeeName}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              if (t.description != null && t.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(t.description!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                              if (t.submission != null) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF4F46E5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.rate_review_outlined, size: 16),
                                    label: const Text('Review Submission'),
                                    onPressed: () => _showReviewDialog(t),
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

          // 3. Reviews Tab
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: provider.tasks.where((t) => t.submission != null).isEmpty
                  ? [
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No pending submissions to review.', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    ]
                  : provider.tasks
                      .where((t) => t.submission != null)
                      .map((t) => Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      ),
                                      Chip(
                                        label: Text(t.status.toUpperCase(), style: const TextStyle(fontSize: 10)),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Submitter: ${t.submission?.submitterName}', style: const TextStyle(fontSize: 12)),
                                  if (t.submission?.link != null)
                                    Text('Link: ${t.submission?.link}', style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5)), overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4F46E5),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _showReviewDialog(t),
                                      child: const Text('Open Review Dialog'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
            ),
          ),

          // 4. Handover Tab
          const HandoverScreen(),
        ],
      ),
    );
  }
}
