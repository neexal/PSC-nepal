import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'pdf_viewer_screen.dart';

class StudyMaterialsScreen extends StatefulWidget {
  const StudyMaterialsScreen({super.key});

  @override
  State<StudyMaterialsScreen> createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends State<StudyMaterialsScreen> {
  List<dynamic> materials = [];
  bool isLoading = true;
  String? selectedCategory;

  final List<String> categories = [
    'All',
    'GK',
    'Nepali',
    'English',
    'IT',
    'Math',
    'Science',
    'History',
    'Geography',
  ];

  @override
  void initState() {
    super.initState();
    fetchMaterials();
  }

  Future<void> fetchMaterials({String? category}) async {
    setState(() {
      isLoading = true;
      selectedCategory = category == 'All' ? null : category;
    });

    try {
      final data = await ApiService.getStudyMaterials(
        category: selectedCategory,
      );
      setState(() {
        materials = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> openMaterial(Map<String, dynamic> material) async {
    try {
      await ApiService.incrementDownload(material['id']);

      final url = material['file_url'];
      if (url != null && url.isNotEmpty) {
        // For PDFs, open in PDF viewer screen
        if (material['material_type'] == 'PDF') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(
                pdfUrl: url,
                title: material['title'],
                materialId: material['id'],
              ),
            ),
          );
        } else {
          // For links, open in browser
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(
              Uri.parse(url),
              mode: LaunchMode.inAppWebView,
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No file URL available for this material'),
              backgroundColor: AppTheme.warningOrange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  IconData getMaterialIcon(String type) {
    switch (type) {
      case 'PDF':
        return Icons.picture_as_pdf_rounded;
      case 'Link':
        return Icons.link_rounded;
      case 'Note':
        return Icons.note_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  Color getCategoryColor(String category) {
    final colors = {
      'GK': AppTheme.primaryBlue,
      'Nepali': AppTheme.errorRed,
      'English': AppTheme.successGreen,
      'IT': AppTheme.accentTeal,
      'Math': AppTheme.accentOrange,
      'Science': AppTheme.successGreen,
      'History': Colors.brown,
      'Geography': Colors.indigo,
    };
    return colors[category] ?? AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Materials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => fetchMaterials(category: selectedCategory ?? 'All'),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category ||
                    (selectedCategory == null && category == 'All');

                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => fetchMaterials(category: category),
                    selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          // Materials List
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading materials...',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : materials.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book_rounded,
                              size: 80,
                              color: AppTheme.textSecondary.withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No materials available',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            fetchMaterials(category: selectedCategory ?? 'All'),
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: materials.length,
                          itemBuilder: (context, index) {
                            final material = materials[index];
                            return AnimatedCard(
                              onTap: () => openMaterial(material),
                              padding: EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: getCategoryColor(material['category'])
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      getMaterialIcon(material['material_type']),
                                      color: getCategoryColor(material['category']),
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          material['title'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        if (material['topic'] != null &&
                                            material['topic'].isNotEmpty)
                                          Text(
                                            material['topic'],
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppTheme.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: getCategoryColor(
                                                        material['category'])
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                material['category'],
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: getCategoryColor(
                                                      material['category']),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '${material['download_count']} views',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                ],
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
