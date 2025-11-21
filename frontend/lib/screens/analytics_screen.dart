import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? analytics;
  bool loading = true;
  String? error;
  bool recalculating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final dataList = await ApiService.getUserAnalytics();
      final data = dataList.isNotEmpty ? dataList.first : <String, dynamic>{};
      if (!mounted) return;
      setState(() { analytics = data; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _recalculate() async {
    if (recalculating) return;
    setState(() { recalculating = true; });
    try {
      await ApiService.recalcUserAnalytics();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recalculate failed: $e')));
    } finally {
      if (mounted) setState(() { recalculating = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = analytics;
    return Scaffold(
      appBar: AppBar(title: const Text('Your Analytics')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Colors.purple.shade400)),
                    ),
                    const SizedBox(height: 16),
                    Text('Analyzing your progress...', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              )
            : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load analytics',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            error!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reload'),
                        ),
                      ],
                    ),
                  )
                : analytics == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.analytics_outlined, size: 64, color: Colors.purple.shade300),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No analytics data yet',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Take quizzes to see your progress!',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Updated Rank & Stats',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: recalculating ? null : _recalculate,
                            icon: const Icon(Icons.refresh),
                            label: Text(recalculating ? 'Updating...' : 'Recalculate'),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (a != null) ...[
                        _metricTile('Global Rank', a['global_rank']?.toString() ?? '—', Icons.leaderboard),
                        _metricTile('Average Score', (a['average_score'] ?? 0).toString(), Icons.score),
                        _metricTile('Total Quizzes', (a['total_quizzes'] ?? 0).toString(), Icons.quiz),
                        _metricTile('Current Streak', (a['current_streak'] ?? 0).toString(), Icons.local_fire_department),
                        const SizedBox(height: 20),
                        Text('Category Performance', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        _buildCategoryStats(a['category_stats']),
                        const SizedBox(height: 20),
                        Text('Badges', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (a['badges'] as List? ?? [])
                              .map((b) => Chip(label: Text(b.toString())))
                              .toList(),
                        ),
                      ]
                    ],
                  ),
      ),
    );
  }

  Widget _metricTile(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildCategoryStats(dynamic stats) {
    if (stats == null || stats is! Map) {
      return const Text('No category data');
    }
    final entries = stats.entries.toList();
    return Column(
      children: entries.map((e) {
        final val = e.value;
        final avg = (val is Map) ? val['average'] ?? 0 : 0;
        final count = (val is Map) ? val['count'] ?? 0 : 0;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(e.key),
            subtitle: Text('Attempts: $count'),
            trailing: Text('Avg: ${avg.toString()}'),
          ),
        );
      }).toList(),
    );
  }
}
