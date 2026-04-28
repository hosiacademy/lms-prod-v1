// lib/src/presentation/pages/instructor/recordings_page.dart
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

/// Page displaying BBB session recordings for instructors
class RecordingsPage extends StatefulWidget {
  const RecordingsPage({super.key});

  @override
  State<RecordingsPage> createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  bool _isLoading = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _recordings = [];

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/api/v1/bbb/recordings/');
      if (mounted && response.data != null) {
        setState(() {
          if (response.data is List) {
             _recordings = List<Map<String, dynamic>>.from(response.data);
          } else if (response.data is Map && response.data['results'] != null) {
             _recordings = List<Map<String, dynamic>>.from(response.data['results']);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load recordings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final mockRecordings = _recordings;

    final filteredRecordings = _searchQuery.isEmpty
        ? mockRecordings
        : mockRecordings.where((rec) {
            return ((rec['name'] ?? rec['session_title'] ?? '') as String)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Recordings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecordings,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to recording settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recording settings coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search recordings...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Recordings List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredRecordings.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredRecordings.length,
                        itemBuilder: (context, index) {
                          final recording = filteredRecordings[index];
                          return _buildRecordingCard(
                            id: recording['id']?.toString() ?? '',
                            title: (recording['name'] ?? recording['session_title'] ?? '') as String,
                            sessionDate: recording['start_time']?.toString().split('T')[0] ?? '',
                            duration: '${recording['duration_minutes'] ?? 0}m',
                            size: '${recording['size_mb']?.toStringAsFixed(1) ?? 0} MB',
                            views: 0,
                            published: recording['published'] == true,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard({
    required String id,
    required String title,
    required String sessionDate,
    required String duration,
    required String size,
    required int views,
    required bool published,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _playRecording(id, title),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail & Play Icon (Placeholder)
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          colors.primary.withValues(alpha: 0.3),
                          colors.secondary.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.video_library,
                      size: 60,
                      color: colors.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      size: 40,
                      color: colors.onPrimary,
                    ),
                  ),
                  // Duration Badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        duration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Published Badge
                  if (!published)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Unpublished',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Metadata
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: colors.onSurface),
                  const SizedBox(width: 4),
                  Text(
                    sessionDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.visibility, size: 14, color: colors.onSurface),
                  const SizedBox(width: 4),
                  Text(
                    '$views views',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.storage, size: 14, color: colors.onSurface),
                  const SizedBox(width: 4),
                  Text(
                    size,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _playRecording(id, title),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _shareRecording(id, title),
                    icon: const Icon(Icons.share),
                    tooltip: 'Share',
                  ),
                  IconButton(
                    onPressed: () => _downloadRecording(id, title),
                    icon: const Icon(Icons.download),
                    tooltip: 'Download',
                  ),
                  IconButton(
                    onPressed: () => _showRecordingOptions(id, title, published),
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'More options',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 80,
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No recordings yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a session with recording enabled\nto see recordings here',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _playRecording(String id, String title) async {
    final recording = _recordings.firstWhere((r) => r['id'].toString() == id, orElse: () => {});
    final url = recording['playback_url'];
    if (url != null && url.toString().isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open playback URL')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Playback URL not available yet')),
        );
      }
    }
  }

  void _shareRecording(String id, String title) {
    // TODO: Generate shareable link
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share link copied to clipboard')),
    );
  }

  void _downloadRecording(String id, String title) {
    // TODO: Download recording file
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading: $title')),
    );
  }

  void _showRecordingOptions(String id, String title, bool published) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(published ? Icons.lock : Icons.public),
              title: Text(published ? 'Unpublish' : 'Publish'),
              onTap: () async {
                Navigator.pop(context);
                final endpoint = published ? 'unpublish' : 'publish';
                try {
                  await ApiClient.post('/api/v1/bbb/recordings/$id/$endpoint/');
                  _loadRecordings();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(published ? 'Recording unpublished' : 'Recording published')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update recording: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Details'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open edit dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('View Analytics'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show recording analytics
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteRecording(id, title);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteRecording(String id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording?'),
        content: Text(
          'Are you sure you want to delete "$title"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Delete recording via API
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recording deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
