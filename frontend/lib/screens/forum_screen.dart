import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'forum_post_detail_screen.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  List<dynamic> posts = [];
  bool loading = true;
  String? error;
  bool creating = false;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await ApiService.getForumPosts();
      if (!mounted) return;
      setState(() { posts = data; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> _createPost() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title & content required')));
      return;
    }
    setState(() { creating = true; });
    try {
      await ApiService.createForumPost(title: title, content: content);
      _titleCtrl.clear();
      _contentCtrl.clear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post created')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Create failed: $e')));
    } finally {
      if (mounted) setState(() { creating = false; });
    }
  }

  Future<void> _toggleLike(int postId) async {
    try {
      await ApiService.likeForumPost(postId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Like failed: $e')));
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forum')), 
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _contentCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Content'),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: creating ? null : _createPost,
                    icon: const Icon(Icons.send),
                    label: Text(creating ? 'Posting...' : 'Post'),
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? ListView(children:[Padding(padding: const EdgeInsets.all(16), child: Text(error!, style: const TextStyle(color: Colors.red)))])
                      : ListView.builder(
                          itemCount: posts.length,
                          itemBuilder: (context, i) {
                            final p = posts[i];
                            final likes = p['like_count'] ?? p['likes']?.length ?? 0;
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForumPostDetailScreen(postId: p['id'] ?? 0, title: p['title'] ?? 'Post'))),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.brown.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(Icons.forum_rounded, color: Colors.brown.shade700, size: 20),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                p['title'] ?? 'Post',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          (p['content'] ?? '').toString().length > 120
                                              ? (p['content'] as String).substring(0, 120) + '…'
                                              : p['content'] ?? '',
                                          style: TextStyle(color: Colors.grey.shade700),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            InkWell(
                                              onTap: () => _toggleLike(p['id'] ?? 0),
                                              borderRadius: BorderRadius.circular(8),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.thumb_up_alt_outlined, size: 16, color: Colors.blue.shade700),
                                                    const SizedBox(width: 4),
                                                    Text(likes.toString(), style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
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
}
