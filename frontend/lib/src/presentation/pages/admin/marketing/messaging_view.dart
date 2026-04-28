// lib/src/presentation/pages/admin/marketing/messaging_view_v2.dart
import 'package:flutter/material.dart';
import 'package:frontend/src/core/api/api_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/src/presentation/widgets/common/searchable_user_dropdown.dart';
import 'package:frontend/src/core/services/marketing_service.dart';
import 'package:frontend/src/core/utils/responsive_helper.dart';

class MessagingView extends StatefulWidget {
  final String? selectedCountry;
  const MessagingView({super.key, this.selectedCountry});

  @override
  State<MessagingView> createState() => _MessagingViewState();
}

class _MessagingViewState extends State<MessagingView> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _sending = false;

  // Configuration
  String _commMethod = 'sms'; // 'sms' or 'email'
  String _targetMode = 'numbers'; // 'numbers', 'users', or 'mailing_list'
  
  final _messageCtrl = TextEditingController();
  final _numbersCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _singleMsgCtrl = TextEditingController();

  List<Map<String, dynamic>> _users = [];
  final List<Map<String, dynamic>> _selectedUsers = [];
  List<Map<String, dynamic>> _mailingLists = [];
  List<Map<String, dynamic>> _oldCampaigns = [];
  int? _selectedMailingListId;
  bool _loadingData = false;
  bool _saveAsCampaign = false;
  PlatformFile? _attachedMedia;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadMailingLists();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    try {
      final resp = await ApiClient.get('/api/v1/payments/admin/marketing/campaigns/');
      if (mounted) {
        setState(() {
          _oldCampaigns = List<Map<String, dynamic>>.from(resp.data['campaigns'] ?? []);
        });
      }
    } catch (_) {}
  }

  void _reuseCampaign(Map<String, dynamic> c) {
    setState(() {
      _messageCtrl.text = c['message'] ?? '';
      _commMethod = c['method'] ?? 'sms';
    });
    _snack('Loaded campaign: ${c['name']}');
  }

  @override
  void dispose() {
    _tabs.dispose();
    _messageCtrl.dispose();
    _numbersCtrl.dispose();
    _phoneCtrl.dispose();
    _singleMsgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loadingData = true);
    try {
      final response = await ApiClient.get('/api/v1/payments/admin/bulk-sms/users/');
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response.data['users'] ?? []);
          _loadingData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  Future<void> _loadMailingLists() async {
    setState(() => _loadingData = true);
    try {
      final resp = await ApiClient.get('/api/v1/payments/admin/mailing-lists/');
      if (mounted) {
        setState(() {
          _mailingLists = List<Map<String, dynamic>>.from(resp.data['mailing_lists'] ?? []);
          _loadingData = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  Future<void> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov'],
    );
    if (result != null) {
      setState(() => _attachedMedia = result.files.first);
    }
  }

  void _shareOnSocial(String platform) async {
    String text = _messageCtrl.text;
    String url = "https://hosiacademy.africa"; 
    
    String shareUrl = "";
    if (platform == 'whatsapp') {
      shareUrl = "https://wa.me/?text=${Uri.encodeComponent("$text $url")}";
    } else if (platform == 'telegram') {
      shareUrl = "https://t.me/share/url?url=${Uri.encodeComponent(url)}&text=${Uri.encodeComponent(text)}";
    }
    
    if (shareUrl.isNotEmpty && await canLaunchUrl(Uri.parse(shareUrl))) {
      await launchUrl(Uri.parse(shareUrl));
    }
  }

  Future<void> _saveAsMailingList() async {
    final contacts = _targetMode == 'numbers' 
      ? _numbersCtrl.text.split('\n').where((s) => s.isNotEmpty).toList()
      : _selectedUsers.map((u) => u['email'] ?? u['phone'] ?? u['name']).toList();
      
    if (contacts.isEmpty) {
      _snack('No contacts to save');
      return;
    }

    final nameCtrl = TextEditingController();
    final bool? saveToDb = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Mailing List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'List Name')),
            const SizedBox(height: 12),
            const Text('Would you like to sync this to the database as well?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('LOCAL ONLY')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SYNC TO DB')),
        ],
      ),
    );

    if (saveToDb == null) return;

    try {
      final name = nameCtrl.text.isEmpty ? 'Mailing List ${DateTime.now()}' : nameCtrl.text;
      
      // Save locally (Frontend Persistence)
      await MarketingService.saveLocalMailingList(name, List<String>.from(contacts));
      
      if (saveToDb) {
        await ApiClient.post('/api/v1/payments/admin/mailing-lists/', data: {
          'name': name,
          'contacts': contacts,
        });
      }
      
      _snack('✅ Mailing list saved ${saveToDb ? 'and synced' : 'locally'}');
      _loadMailingLists();
    } catch (e) {
      _snack('Error saving: $e');
    }
  }

  Future<void> _dispatch() async {
    final msg = _messageCtrl.text.trim();
    if (msg.isEmpty) {
      _snack('Please enter a message');
      return;
    }

    setState(() => _sending = true);
    try {
      final Map<String, dynamic> payload = {
        'message': msg,
        'method': _commMethod,
      };
      
      if (_targetMode == 'numbers') {
        payload['phone_numbers'] = _numbersCtrl.text.split('\n').where((s) => s.isNotEmpty).toList();
      } else if (_targetMode == 'users') {
        payload['user_ids'] = _selectedUsers.map((u) => u['id']).toList();
      } else if (_targetMode == 'mailing_list') {
        payload['mailing_list_id'] = _selectedMailingListId;
      }

      await ApiClient.post('/api/v1/payments/admin/bulk-sms/send/', data: payload);
      _snack('✅ Campaign dispatched successfully');
      _messageCtrl.clear();
      setState(() {
        _attachedMedia = null;
        _selectedUsers.clear();
      });
    } catch (e) {
      _snack('Error: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      children: [
        _buildHeader(theme, colors),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Outreach Blast'), Tab(text: 'Direct Link')],
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurface.withValues(alpha: 0.6),
          indicatorColor: colors.primary,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              ResponsiveHelper.fluidScroll(
                context: context,
                child: _buildBulkFlow(theme, colors),
              ),
              ResponsiveHelper.fluidScroll(
                context: context,
                child: _buildDirectFlow(theme, colors),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Marketing Communications', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text('Multi-channel outreach with media attachments', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
              ],
            ),
          ),
          _buildMethodToggle(colors),
        ],
      ),
    );
  }

  Widget _buildMethodToggle(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _methodButton('sms', Icons.sms_outlined, colors),
          _methodButton('email', Icons.alternate_email, colors),
        ],
      ),
    );
  }

  Widget _methodButton(String method, IconData icon, ColorScheme colors) {
    final isActive = _commMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _commMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isActive ? [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : colors.onSurface),
            const SizedBox(width: 8),
            Text(method.toUpperCase(), style: TextStyle(color: isActive ? Colors.white : colors.onSurface, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkFlow(ThemeData theme, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildCampaignHistory(theme, colors),
          const SizedBox(height: 20),
          _buildTargetCard(theme, colors),
          const SizedBox(height: 20),
          _buildMessageCard(theme, colors),
        ],
      ),
    );
  }

  Widget _buildCampaignHistory(ThemeData theme, ColorScheme colors) {
    if (_oldCampaigns.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reuse Past Campaigns', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: colors.primary)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _oldCampaigns.map((c) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ActionChip(
                label: Text(c['name'] ?? 'Campaign'),
                avatar: const Icon(Icons.history_rounded, size: 16),
                onPressed: () => _reuseCampaign(c),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetCard(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_outline, color: colors.primary),
                const SizedBox(width: 12),
                Text('Target Audience', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'numbers', label: Text('Manual'), icon: Icon(Icons.dialpad)),
                ButtonSegment(value: 'users', label: Text('Students'), icon: Icon(Icons.school)),
                ButtonSegment(value: 'mailing_list', label: Text('Lists'), icon: Icon(Icons.list_alt)),
              ],
              selected: {_targetMode},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _targetMode = newSelection.first;
                  if (_targetMode == 'users' && _users.isEmpty) _loadUsers();
                  if (_targetMode == 'mailing_list' && _mailingLists.isEmpty) _loadMailingLists();
                });
              },
            ),
            const SizedBox(height: 20),
            if (_targetMode == 'numbers')
              TextField(
                controller: _numbersCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Enter phone numbers or emails (one per line)...',
                  filled: true,
                  fillColor: colors.surfaceContainerLowest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              )
            else if (_targetMode == 'users')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchableUserDropdown(
                    label: 'Select Students (Search by Name or Email)',
                    onSelected: (u) {
                      setState(() {
                        if (!_selectedUsers.any((element) => element['id'] == u['id'])) {
                          _selectedUsers.add(u);
                        }
                      });
                    },
                  ),
                  if (_selectedUsers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedUsers.map((u) => Chip(
                        label: Text(u['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        avatar: Icon(Icons.person, size: 14, color: colors.primary),
                        onDeleted: () => setState(() => _selectedUsers.remove(u)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        backgroundColor: colors.primary.withValues(alpha: 0.05),
                        side: BorderSide(color: colors.primary.withValues(alpha: 0.1)),
                      )).toList(),
                    ),
                  ],
                ],
              )
            else if (_targetMode == 'mailing_list')
              DropdownButtonFormField<int>(
                value: _selectedMailingListId,
                items: _mailingLists.map((l) => DropdownMenuItem<int>(value: l['id'], child: Text(l['name']))).toList(),
                onChanged: (v) => setState(() => _selectedMailingListId = v),
                decoration: InputDecoration(
                  hintText: 'Select a saved list',
                  filled: true,
                  fillColor: colors.surfaceContainerLowest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _saveAsMailingList,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save as Persistent Mailing List'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(ThemeData theme, ColorScheme colors) {
    final isSms = _commMethod == 'sms';
    final charCount = _messageCtrl.text.length;
    final limit = isSms ? 160 : 2000;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)), borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_outlined, color: colors.primary),
                const SizedBox(width: 12),
                Text('Campaign Content', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _messageCtrl,
              maxLines: 6,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: isSms ? 'Type your concise marketing message...' : 'Compose your full HTML email campaign...',
                filled: true,
                fillColor: colors.surfaceContainerLowest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                counterText: '$charCount / $limit characters',
                counterStyle: TextStyle(color: charCount > limit ? Colors.red : colors.onSurfaceVariant, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            _buildMediaPicker(colors),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [colors.primary, colors.primary.withValues(alpha: 0.8)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: FilledButton.icon(
                      onPressed: _sending ? null : _dispatch,
                      icon: _sending 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.rocket_launch_outlined),
                      label: Text(_sending ? 'Dispatching...' : 'Blast Campaign'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildSocialShareMenu(colors),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPicker(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.attachment, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_attachedMedia?.name ?? 'No media attached', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                if (_attachedMedia == null)
                  const Text('JPG, PNG, MP4 supported', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          TextButton(
            onPressed: _pickMedia,
            child: Text(_attachedMedia == null ? 'Browse' : 'Replace'),
          ),
          if (_attachedMedia != null)
            IconButton(onPressed: () => setState(() => _attachedMedia = null), icon: const Icon(Icons.cancel_outlined, size: 20, color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildSocialShareMenu(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.share_outlined, color: colors.secondary),
        tooltip: 'Share on Social Media',
        onSelected: _shareOnSocial,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (context) => [
          PopupMenuItem(value: 'whatsapp', child: Row(children: [Icon(Icons.chat_bubble_outline, color: Colors.green[600]), const SizedBox(width: 12), const Text('WhatsApp')])),
          PopupMenuItem(value: 'telegram', child: Row(children: [Icon(Icons.telegram, color: Colors.blue[600]), const SizedBox(width: 12), const Text('Telegram')])),
        ],
      ),
    );
  }

  Widget _buildDirectFlow(ThemeData theme, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bolt, size: 64, color: colors.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('Direct outreach tools for individual leads', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('Share marketing materials directly via Social APIs', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
