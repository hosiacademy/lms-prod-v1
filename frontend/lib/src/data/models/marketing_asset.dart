// lib/src/data/models/marketing_asset.dart

enum AssetType { IMAGE, VIDEO, SVG }

class MarketingAsset {
  final int id;
  final String title;
  final String description;
  final AssetType assetType;
  final String? fileUrl;
  final String? thumbnailUrl;
  final String? suggestedCaption;
  final int totalClicks;
  final int totalShares;
  final int shareCount;
  final DateTime createdAt;

  MarketingAsset({
    required this.id,
    required this.title,
    required this.description,
    required this.assetType,
    this.fileUrl,
    this.thumbnailUrl,
    this.suggestedCaption,
    this.totalClicks = 0,
    this.totalShares = 0,
    this.shareCount = 0,
    required this.createdAt,
  });

  factory MarketingAsset.fromJson(Map<String, dynamic> json) {
    return MarketingAsset(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      assetType: _parseAssetType(json['asset_type']),
      fileUrl: json['file_url'],
      thumbnailUrl: json['thumbnail_url'],
      suggestedCaption: json['suggested_caption'],
      totalClicks: json['total_clicks'] ?? 0,
      totalShares: json['total_shares'] ?? 0,
      shareCount: json['share_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static AssetType _parseAssetType(String type) {
    switch (type.toUpperCase()) {
      case 'VIDEO':
        return AssetType.VIDEO;
      case 'SVG':
        return AssetType.SVG;
      case 'IMAGE':
      default:
        return AssetType.IMAGE;
    }
  }
}
