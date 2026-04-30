import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class MarketingLeadsView extends StatefulWidget {
  const MarketingLeadsView({super.key});

  @override
  State<MarketingLeadsView> createState() => _MarketingLeadsViewState();
}

class _MarketingLeadsViewState extends State<MarketingLeadsView> {
  List<Map<String, dynamic>> _leads = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch both traditional leads and new wishlist items
      final wishlists = await ApiClient.getMarketingWishlists();
      if (mounted) {
        setState(() {
          _leads = wishlists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(int leadId, String status) async {
    try {
      await ApiClient.updateMarketingLeadStatus(leadId, status);
      _loadLeads();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadLeads, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Marketing Leads (Wishlist Expressions)',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: _loadLeads,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _leads.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, size: 64, color: colors.primary.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        const Text('No marketing leads yet. Keep promoting!'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _leads.length,
                    itemBuilder: (context, i) {
                      final lead = _leads[i];
                      return _buildLeadCard(lead, theme, colors);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadCard(Map<String, dynamic> lead, ThemeData theme, ColorScheme colors) {
    final status = lead['status'] ?? 'new';
    final date = lead['created_at'] != null 
        ? DateFormat('MMM d, yyyy').format(DateTime.parse(lead['created_at']))
        : 'N/A';
    
    final interestLevel = lead['interest_level'] ?? 'N/A';
    final intendedStart = lead['intended_start'] ?? 'N/A';
    final country = lead['country_name'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    (lead['user_email'] as String? ?? 'U')[0].toUpperCase(),
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead['user_email'] ?? 'Anonymous',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Interested in: ${lead['title']} (${lead['training_type']})',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.primary, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Region: $country',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(status: status),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(child: _buildLeadInfoRow('Interest Level:', interestLevel.toString().toUpperCase())),
                Expanded(child: _buildLeadInfoRow('Intended Start:', intendedStart)),
              ],
            ),
            const SizedBox(height: 12),
            _buildLeadInfoRow('Notes / Reason:', lead['notes'] ?? lead['goals'] ?? 'No notes provided'),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 12,
              children: [
                Text(
                  'Added on: $date',
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.5)),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    if (status == 'new' || status == 'pending')
                      TextButton.icon(
                        onPressed: () => _updateStatus(lead['id'], 'contacted'),
                        icon: const Icon(Icons.mark_email_read, size: 16),
                        label: const Text('Mark Contacted', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadInfoRow(String label, String? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? 'N/A',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'new':
        color = AppTheme.hosiPeach;
        break;
      case 'contacted':
        color = Colors.blue;
        break;
      case 'converted':
        color = Colors.green;
        break;
      case 'closed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
