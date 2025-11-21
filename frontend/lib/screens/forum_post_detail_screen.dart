import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForumPostDetailScreen extends StatefulWidget {
  final int postId;
  final String title;
  const ForumPostDetailScreen({super.key, required this.postId, required this.title});

  @override
  State<ForumPostDetailScreen> createState() => _ForumPostDetailScreenState();
}

class _ForumPostDetailScreenState extends State<ForumPostDetailScreen> {
  List<dynamic> comments = [];
  bool loading = true;
  String? error;
  final _commentCtrl = TextEditingController();
  final Set<int> liking = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await ApiService.getForumComments(widget.postId);
      if (!mounted) return;
      setState(() { comments = data; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _addComment() async {
    final content = _commentCtrl.text.trim();
    if (content.isEmpty) return;
    try {
      await ApiService.createForumComment(postId: widget.postId, content: content);
      _commentCtrl.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Comment failed: $e')));
    }
  }

  Future<void> _toggleLike(int commentId) async {
    if (liking.contains(commentId)) return;
    setState(() { liking.add(commentId); });
    try {
      await ApiService.likeForumComment(commentId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Like failed: $e')));
    } finally {
      if (mounted) setState(() { liking.remove(commentId); });
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? ListView(children:[Padding(padding: const EdgeInsets.all(16), child: Text(error!, style: const TextStyle(color: Colors.red)))])
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: comments.length,
                          itemBuilder: (context, i) {
                            final c = comments[i];
                            final likes = c['like_count'] ?? c['likes']?.length ?? 0;
                            final id = c['id'] ?? 0;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                title: Text(c['content'] ?? ''),
                                subtitle: Text('By: ${c['user'] ?? 'User'}'),
                                trailing: IconButton(
                                  icon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [const Icon(Icons.thumb_up_alt_outlined, size:18), const SizedBox(width:4), Text(likes.toString())],
                                  ),
                                  onPressed: () => _toggleLike(id),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addComment,
                  child: const Text('Send'),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
