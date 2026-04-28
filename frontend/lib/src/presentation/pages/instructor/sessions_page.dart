// lib/src/presentation/pages/instructor/sessions_page.dart
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import 'package:go_router/go_router.dart';
import 'bbb_session_viewer.dart';
import 'start_session_modal.dart';

/// Page displaying instructor's BBB sessions (upcoming, live, and past)
class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _upcomingSessions = [];
  List<Map<String, dynamic>> _liveSessions = [];
  List<Map<String, dynamic>> _pastSessions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/api/v1/bbb/sessions/my_sessions/');
      if (mounted && response.data != null) {
        setState(() {
          _upcomingSessions = List<Map<String, dynamic>>.from(response.data['upcoming'] ?? []);
          _liveSessions = List<Map<String, dynamic>>.from(response.data['live'] ?? []);
          _pastSessions = List<Map<String, dynamic>>.from(response.data['past'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load sessions: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showStartSessionModal() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const StartSessionModal(),
    );

    // Refresh sessions list if a new session was created
    if (result == true && mounted) {
      _loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming', icon: Icon(Icons.schedule)),
            Tab(text: 'Live Now', icon: Icon(Icons.live_tv)),
            Tab(text: 'Past', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingSessions(),
                _buildLiveSessions(),
                _buildPastSessions(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStartSessionModal(),
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
    );
  }

  Widget _buildUpcomingSessions() {
    final mockSessions = _upcomingSessions;

    if (mockSessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event,
        message: 'No upcoming sessions',
        actionLabel: 'Create Session',
        onAction: () => _showStartSessionModal(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockSessions.length,
      itemBuilder: (context, index) {
        final session = mockSessions[index];
        return _buildSessionCard(
          title: session['title'] as String,
          date: session['scheduled_start']?.toString().split('T')[0] ?? '',
          time: session['scheduled_start']?.toString().split('T')[1].substring(0, 5) ?? '',
          participants: (session['max_participants'] ?? 0) as int,
          recordEnabled: session['record'] == true,
          status: 'upcoming',
        );
      },
    );
  }

  Widget _buildLiveSessions() {
    final mockSessions = _liveSessions;

    if (mockSessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.videocam_off,
        message: 'No live sessions right now',
        actionLabel: 'Start Session',
        onAction: () => _showStartSessionModal(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockSessions.length,
      itemBuilder: (context, index) {
        final session = mockSessions[index];
        return _buildSessionCard(
          title: session['title'] as String,
          date: session['scheduled_start']?.toString().split('T')[0] ?? '',
          time: session['scheduled_start']?.toString().split('T')[1].substring(0, 5) ?? '',
          participants: (session['max_participants'] ?? 0) as int,
          recordEnabled: session['record'] == true,
          status: 'live',
          currentAttendees: null,
        );
      },
    );
  }

  Widget _buildPastSessions() {
    final mockSessions = _pastSessions;

    if (mockSessions.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        message: 'No past sessions yet',
        actionLabel: 'Create Session',
        onAction: () => _showStartSessionModal(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockSessions.length,
      itemBuilder: (context, index) {
        final session = mockSessions[index];
        return _buildSessionCard(
          title: session['title'] as String,
          date: session['scheduled_start']?.toString().split('T')[0] ?? '',
          time: session['scheduled_start']?.toString().split('T')[1].substring(0, 5) ?? '',
          participants: (session['max_participants'] ?? 0) as int,
          recordEnabled: session['record'] == true,
          status: 'past',
          actualAttendees: null,
          duration: null,
        );
      },
    );
  }

  Widget _buildSessionCard({
    required String title,
    required String date,
    required String time,
    required int participants,
    required bool recordEnabled,
    required String status,
    int? currentAttendees,
    int? actualAttendees,
    String? duration,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'live':
        statusColor = Colors.red;
        statusText = 'LIVE NOW';
        statusIcon = Icons.fiber_manual_record;
        break;
      case 'upcoming':
        statusColor = Colors.green;
        statusText = 'Upcoming';
        statusIcon = Icons.schedule;
        break;
      case 'past':
      default:
        statusColor = Colors.grey;
        statusText = 'Completed';
        statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to session details or join session
          if (status == 'live') {
            _joinSession('temp_id', title);
          } else if (status == 'past' && recordEnabled) {
            context.go('/instructor/recordings');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (recordEnabled)
                    Icon(Icons.videocam, size: 16, color: colors.primary),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Date & Time
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: colors.onSurface),
                  const SizedBox(width: 4),
                  Text(
                    date,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: colors.onSurface),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Participants Info
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: colors.onSurface),
                  const SizedBox(width: 4),
                  Text(
                    status == 'live'
                        ? '$currentAttendees/$participants attendees'
                        : status == 'past'
                            ? '$actualAttendees/$participants attended'
                            : '$participants registered',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  if (duration != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.timer, size: 14, color: colors.onSurface),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Action Button
              if (status == 'live')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _joinSession('temp_id', title),
                    icon: const Icon(Icons.login),
                    label: const Text('Join Session'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              else if (status == 'past' && recordEnabled)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/instructor/recordings'),
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('View Recording'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: colors.onSurface.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  void _joinSession(String sessionId, String sessionTitle) {
    // Show BBB session in modal overlay dialog
    // Session will be displayed as popup within the instructor portal
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal during live session
      builder: (context) => Dialog.fullscreen(
        child: BBBSessionViewer(
          sessionId: sessionId,
          sessionTitle: sessionTitle,
          // Join URL will be fetched from backend API: /api/bbb/sessions/{id}/join/
        ),
      ),
    );
  }
}
