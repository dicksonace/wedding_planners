import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/api_config.dart';
import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'create_plan_screen.dart';

class MediaGalleryScreen extends StatefulWidget {
  const MediaGalleryScreen({super.key, required this.type, required this.title});

  final String type;
  final String title;

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  final _picker = ImagePicker();
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final store = context.read<AppStore>();
    await store.refreshDashboard();
    if (store.hasPlan) {
      await store.fetchWeddingMedia(type: widget.type);
    }
  }

  Future<void> _upload() async {
    final store = context.read<AppStore>();
    if (!store.hasPlan) {
      final created = await openCreatePlanScreen(context);
      if (created == true && mounted) await _load();
      return;
    }

    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      await store.uploadWeddingMedia(filePath: picked.path, type: widget.type);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded')));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.richRed),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _imageUrl(Map<String, dynamic> item) {
    final url = item['url'] as String?;
    if (url != null && url.isNotEmpty) {
      if (url.contains('10.0.2.2') || url.contains('127.0.0.1')) return url;
      return url.replaceFirst(RegExp(r'https?://[^/]+'), ApiConfig.assetBaseUrl);
    }
    return ApiConfig.mediaUrl(item['file_path'] as String?);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final items = store.weddingMedia.where((m) => m['type'] == widget.type).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      floatingActionButton: _uploading
          ? const Padding(
              padding: EdgeInsets.only(bottom: 72),
              child: FloatingActionButton(onPressed: null, child: CircularProgressIndicator(color: Colors.white)),
            )
          : AppAddFab(tooltip: 'Upload image', onPressed: _upload),
      body: !store.hasPlan
          ? ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                EmptyState(
                  icon: Icons.photo_library_rounded,
                  title: 'Create a plan first',
                  subtitle: 'You need a wedding plan before uploading invitations or photos.',
                ),
              ],
            )
          : store.weddingMediaLoading
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        EmptyState(
                          icon: widget.type == 'invitation' ? Icons.mail_rounded : Icons.photo_library_rounded,
                          title: 'No images yet',
                          subtitle: widget.type == 'invitation'
                              ? 'Upload your wedding invitation designs here.'
                              : 'Upload engagement and wedding photos here.',
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(label: 'Upload Image', icon: Icons.upload_rounded, onPressed: _upload),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        final url = _imageUrl(item);
                        return GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (ctx) => Dialog(
                              child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain)),
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: AppDecor.radiusLg,
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.softGreen,
                                    child: const Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                                    onPressed: () async {
                                      await store.deleteWeddingMedia(item['id'] as int);
                                      if (mounted) await _load();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
