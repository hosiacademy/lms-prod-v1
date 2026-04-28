// lib/src/presentation/pages/admin/widgets/marketing_assets_view.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/src/core/api/api_client.dart';
import 'package:frontend/src/data/models/marketing_asset.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketingAssetsView extends StatefulWidget {
  const MarketingAssetsView({super.key});

  @override
  State<MarketingAssetsView> createState() => _MarketingAssetsViewState();
}

class _MarketingAssetsViewState extends State<MarketingAssetsView> {
  List<MarketingAsset> _assets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.getMarketingAssets();
      setState(() {
        _assets = data.map((e) => MarketingAsset.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading assets: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'svg'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final file = result.files.single;
      
      // Show dialog to enter details
      if (!mounted) return;
      final details = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) => _UploadDetailsDialog(fileName: file.name),
      );

      if (details != null) {
        setState(() => _isLoading = true);
        try {
          String assetType = 'IMAGE';
          if (file.name.toLowerCase().endsWith('.mp4')) assetType = 'VIDEO';
          if (file.name.toLowerCase().endsWith('.svg')) assetType = 'SVG';

          await ApiClient.uploadMarketingAsset(
            title: details['title']!,
            description: details['description']!,
            assetType: assetType,
            fileBytes: file.bytes!,
            fileName: file.name,
            suggestedCaption: details['caption'],
          );

          _loadAssets();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Asset uploaded successfully')),
            );
          }
        } catch (e) {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: $e')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _pickAndUploadFile,
        label: const Text('Upload Asset'),
        icon: const Icon(Icons.upload),
        backgroundColor: Colors.orange,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAssets,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Marketing Assets & Social Sharing',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload images, videos, and SVGs to share on social media with embedded referral links.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              if (_isLoading && _assets.isEmpty)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: _assets.isEmpty
                      ? const Center(child: Text('No assets found. Upload one to get started.'))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount = 3;
                            if (constraints.maxWidth < 600) { crossAxisCount = 1; }
                            else if (constraints.maxWidth < 900) { crossAxisCount = 2; }
                            
                            return GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: crossAxisCount == 1 ? 1.2 : 0.85,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                              ),
                              itemCount: _assets.length,
                              itemBuilder: (context, index) {
                                return _AssetCard(
                                  asset: _assets[index],
                                  onDelete: () => _deleteAsset(_assets[index].id),
                                  onShare: (platform) => _shareAsset(_assets[index], platform),
                                );
                              },
                            );
                          }
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAsset(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Asset'),
        content: const Text('Are you sure you want to delete this asset?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiClient.deleteMarketingAsset(id);
        _loadAssets();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }

  Future<void> _shareAsset(MarketingAsset asset, String platform) async {
    // Generate referral link
    final lmsLink = "https://hosiacademy.africa/enroll?ref=MKTG_${asset.id}";
    
    String shareUrl = "";
    String caption = asset.suggestedCaption ?? "Check out this program at Hosi Academy!";
    String encodedCaption = Uri.encodeComponent('$caption $lmsLink');

    switch (platform) {
      case 'facebook':
        shareUrl = "https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(lmsLink)}&quote=${Uri.encodeComponent(caption)}";
        break;
      case 'twitter':
        shareUrl = "https://twitter.com/intent/tweet?text=$encodedCaption";
        break;
      case 'linkedin':
        shareUrl = "https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(lmsLink)}";
        break;
      case 'whatsapp':
        shareUrl = "https://wa.me/?text=$encodedCaption";
        break;
    }

    if (shareUrl.isNotEmpty) {
      final uri = Uri.parse(shareUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Log the share event
        try {
          await ApiClient.logAssetShare(
            assetId: asset.id,
            platform: platform,
            referralLink: lmsLink,
          );
          _loadAssets(); // Refresh counts
        } catch (e) {
          debugPrint('Error logging share: $e');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch sharing app')));
        }
      }
    }
  }
}

class _UploadDetailsDialog extends StatefulWidget {
  final String fileName;
  const _UploadDetailsDialog({required this.fileName});

  @override
  State<_UploadDetailsDialog> createState() => _UploadDetailsDialogState();
}

class _UploadDetailsDialogState extends State<_UploadDetailsDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.fileName.split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asset Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            TextField(
              controller: _captionController,
              decoration: const InputDecoration(labelText: 'Suggested Social Caption'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              Navigator.pop(context, {
                'title': _titleController.text,
                'description': _descController.text,
                'caption': _captionController.text,
              });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
          child: const Text('Upload'),
        ),
      ],
    );
  }
}

class _AssetCard extends StatelessWidget {
  final MarketingAsset asset;
  final VoidCallback onDelete;
  final Function(String) onShare;

  const _AssetCard({
    required this.asset,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildPreview(),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      asset.assetType.name,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.share, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${asset.shareCount}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 16),
                    const Icon(Icons.touch_app, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${asset.totalClicks}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Share to:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _ShareButton(
                          icon: Icons.facebook,
                          color: const Color(0xFF1877F2),
                          onPressed: () => onShare('facebook'),
                        ),
                        const SizedBox(width: 8),
                        _ShareButton(
                          icon: Icons.alternate_email,
                          color: Colors.black,
                          onPressed: () => onShare('twitter'),
                        ),
                        const SizedBox(width: 8),
                        _ShareButton(
                          icon: Icons.business,
                          color: const Color(0xFF0A66C2),
                          onPressed: () => onShare('linkedin'),
                        ),
                        const SizedBox(width: 8),
                        _ShareButton(
                          icon: Icons.chat,
                          color: const Color(0xFF25D366),
                          onPressed: () => onShare('whatsapp'),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                      onPressed: onDelete,
                      tooltip: 'Delete Asset',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (asset.assetType == AssetType.VIDEO) {
      return Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: const Center(
          child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
        ),
      );
    }
    
    if (asset.fileUrl == null) {
      return _buildPlaceholder();
    }

    final imageUrl = asset.fileUrl!;
    final isSvg = asset.assetType == AssetType.SVG || 
                  imageUrl.toLowerCase().endsWith('.svg') || 
                  imageUrl.contains('format=svg');

    if (isSvg) {
      // Use SvgPicture.network or AuthenticatedSvgImage if it's proxied
      // The proxy URL works with Image.network only if served as bitmap.
      // But SvgPicture is safer for actual SVGs.
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      height: double.infinity,
      child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ShareButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
