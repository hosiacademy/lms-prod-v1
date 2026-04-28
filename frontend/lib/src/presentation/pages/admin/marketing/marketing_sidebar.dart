// lib/src/presentation/pages/admin/marketing/marketing_sidebar.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MarketingSidebar extends StatelessWidget {
  final String selectedSection;
  final ValueChanged<String> onSectionChanged;
  final String userName;
  final bool isInDrawer;

  const MarketingSidebar({
    super.key,
    required this.selectedSection,
    required this.onSectionChanged,
    required this.userName,
    this.isInDrawer = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        // User Profile Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: colors.outline.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colors.primary,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'M',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Marketing Admin',
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            children: [
              _buildNavItem(context, 'summary', Icons.dashboard_outlined, Icons.dashboard, 'Summary'),
              _buildNavItem(context, 'leads', Icons.people_outline, Icons.people, 'Leads'),
              _buildNavItem(context, 'revenue', Icons.payments_outlined, Icons.payments, 'Revenue'),
              _buildNavItem(context, 'quotations', Icons.request_quote_outlined, Icons.request_quote, 'Quotations'),
              _buildNavItem(context, 'messaging', Icons.sms_outlined, Icons.sms, 'Messaging'),
              _buildNavItem(context, 'mailing_lists', Icons.contact_mail_outlined, Icons.contact_mail, 'Mailing Lists'),
              _buildNavItem(context, 'partners', Icons.handshake_outlined, Icons.handshake, 'Partners'),
              
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text('DIRECT OUTREACH', 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              _buildSocialItem(context, 'Facebook', 'https://facebook.com', Icons.facebook),
              _buildSocialItem(context, 'LinkedIn', 'https://linkedin.com', Icons.business),
              _buildSocialItem(context, 'Twitter/X', 'https://twitter.com', Icons.alternate_email),
              _buildSocialItem(context, 'Instagram', 'https://instagram.com', Icons.camera_alt),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialItem(BuildContext context, String label, String url, IconData icon) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: colors.primary.withValues(alpha: 0.7), size: 20),
      title: Text(label, style: theme.textTheme.bodyMedium),
      trailing: const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
      dense: true,
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
    );
  }

  Widget _buildNavItem(BuildContext context, String key, IconData icon, IconData activeIcon, String label) {
    final isSelected = selectedSection == key;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListTile(
      leading: Icon(isSelected ? activeIcon : icon,
          color: isSelected ? colors.primary : colors.onSurface, size: 22),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isSelected ? colors.primary : colors.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colors.primary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: () {
        onSectionChanged(key);
        if (isInDrawer && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}
