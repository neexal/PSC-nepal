import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> leaderboard = [];
  bool loading = true;
  bool categoriesLoading = true;
  String? error;
  String? selectedCategory;
  String? selectedPeriod;
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadSavedFilters();
    await Future.wait([_fetchCategories(), _fetchLeaderboard()]);
  }

  Future<void> _loadSavedFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cat = prefs.getString('leaderboard_filter_category');
      final per = prefs.getString('leaderboard_filter_period');
      if (mounted) {
        setState(() {
          selectedCategory = cat == '' ? null : cat;
          selectedPeriod = per == '' ? null : per;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchCategories() async {
    setState(() { categoriesLoading = true; });
    try {
      final quizzes = await ApiService.getQuizzes();
      final set = <String>{};
      for (var q in quizzes) {
        final cat = q['category'];
        if (cat is String && cat.trim().isNotEmpty) set.add(cat.trim());
      }
      if (!mounted) return;
      setState(() { categories = set.toList()..sort(); categoriesLoading = false; });
    } catch (_) {
      if (mounted) setState(() { categoriesLoading = false; });
    }
  }

  Future<void> _fetchLeaderboard() async {
    setState(() { loading = true; error = null; });
    try {
      List<dynamic> data;
      if (selectedCategory != null || selectedPeriod != null) {
        data = await ApiService.getLeaderboardFiltered(category: selectedCategory, period: selectedPeriod);
      } else {
        data = await ApiService.getLeaderboard();
      }
      if (!mounted) return;
      setState(() { leaderboard = data; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); loading = false; });
    }
  }

  void _clearFilters() async {
    setState(() {
      selectedCategory = null;
      selectedPeriod = null;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('leaderboard_filter_category', '');
    await prefs.setString('leaderboard_filter_period', '');
    _fetchLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loading ? null : _fetchLeaderboard,
          )
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchLeaderboard,
              child: loading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Colors.blue.shade400)),
                          ),
                          const SizedBox(height: 16),
                          Text('Loading leaderboard...', style: TextStyle(color: Colors.grey.shade600)),
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
                                'Unable to load rankings',
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
                                onPressed: _fetchLeaderboard,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : leaderboard.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.leaderboard_outlined, size: 64, color: Colors.blue.shade300),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'No rankings available',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Be the first to take a quiz!',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: leaderboard.length,
                              itemBuilder: (context, index) {
                                final user = leaderboard[index];
                                final isCurrentUser = user['is_current_user'] ?? false;
                                final rank = user['rank'];
                                Color? cardColor;
                                Color? borderColor;
                                if (rank == 1) {
                                  cardColor = Colors.amber.shade50;
                                  borderColor = Colors.amber.shade300;
                                } else if (rank == 2) {
                                  cardColor = Colors.grey.shade50;
                                  borderColor = Colors.grey.shade400;
                                } else if (rank == 3) {
                                  cardColor = Colors.orange.shade50;
                                  borderColor = Colors.orange.shade300;
                                }
                                if (isCurrentUser) {
                                  cardColor = Colors.blue.shade50;
                                  borderColor = Colors.blue.shade300;
                                }
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: cardColor ?? Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: borderColor != null ? Border.all(color: borderColor, width: 2) : null,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (borderColor ?? Colors.grey).withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: _buildRankBadge(rank),
                                    title: Text(
                                      user['username'] ?? 'User',
                                      style: TextStyle(fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal),
                                    ),
                                    subtitle: Text('${user['quizzes_taken']} quizzes • Avg ${(user['average_score'] ?? 0).toString()}%'),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('${user['total_score']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const Text('Points', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('All Categories')),
                        ...categories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))),
                      ],
                      onChanged: (val) async {
                        setState(() => selectedCategory = val);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('leaderboard_filter_category', val ?? '');
                        _fetchLeaderboard();
                      },
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    ),
                    if (categoriesLoading)
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedPeriod,
                  items: const [
                    DropdownMenuItem<String>(value: null, child: Text('All Time')),
                    DropdownMenuItem<String>(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem<String>(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem<String>(value: 'monthly', child: Text('Monthly')),
                  ],
                  onChanged: (val) async {
                    setState(() => selectedPeriod = val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('leaderboard_filter_period', val ?? '');
                    _fetchLeaderboard();
                  },
                  decoration: const InputDecoration(labelText: 'Period', border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: (selectedCategory != null || selectedPeriod != null) ? _clearFilters : null,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade300, Colors.amber.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.emoji_events, color: Colors.white, size: 28),
      );
    } else if (rank == 2) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade300, Colors.grey.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.emoji_events, color: Colors.white, size: 26),
      );
    } else if (rank == 3) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade300, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.emoji_events, color: Colors.white, size: 24),
      );
    }
    return CircleAvatar(
      backgroundColor: Colors.blue.shade100,
      child: Text(
        rank.toString(),
        style: TextStyle(
          color: Colors.blue.shade800,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
