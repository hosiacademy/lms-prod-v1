// lib/src/presentation/pages/payment/cash_payment_instructions_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';

/// Cash Payment Instructions Page
/// 
/// Displays pathway-specific cash payment instructions based on enrollment type.
/// Each enrollment pathway (Masterclass, Learnership, Industry Training, etc.)
/// has detailed, tailored instructions for the cash payment process.
class CashPaymentInstructionsPage extends StatefulWidget {
  final String enrollmentType;
  final String programId;
  final String programTitle;
  final String reference;
  final double amount;
  final String currency;
  final bool isDialog;

  const CashPaymentInstructionsPage({
    super.key,
    required this.enrollmentType,
    required this.programId,
    required this.programTitle,
    required this.reference,
    required this.amount,
    required this.currency,
    this.isDialog = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String enrollmentType,
    required String programId,
    required String programTitle,
    required String reference,
    required double amount,
    required String currency,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 900),
          child: CashPaymentInstructionsPage(
            enrollmentType: enrollmentType,
            programId: programId,
            programTitle: programTitle,
            reference: reference,
            amount: amount,
            currency: currency,
            isDialog: true,
          ),
        ),
      ),
    );
  }

  @override
  State<CashPaymentInstructionsPage> createState() =>
      _CashPaymentInstructionsPageState();
}

class _CashPaymentInstructionsPageState
    extends State<CashPaymentInstructionsPage> {
  bool _isLoading = true;
  bool _isLoadingError = false;
  String? _error;
  Map<String, dynamic>? _instructions;
  bool _showLocations = false;
  bool _showDocuments = false;
  bool _copyingReference = false;

  @override
  void initState() {
    super.initState();
    _loadInstructions();
  }

  Future<void> _loadInstructions() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isLoadingError = false;
    });

    try {
      final response = await ApiClient.getCashPaymentInstructions(
        enrollmentType: widget.enrollmentType,
        programId: widget.programId,
        programTitle: widget.programTitle,
      );

      setState(() {
        _instructions = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load payment instructions: $e';
        _isLoadingError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _copyReference() async {
    setState(() => _copyingReference = true);
    
    await Clipboard.setData(ClipboardData(text: widget.reference));
    
    if (mounted) {
      setState(() => _copyingReference = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reference code ${widget.reference} copied!'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _callSupport() async {
    if (_instructions == null) return;
    
    final contact = _instructions!['contact_support'] as Map<String, dynamic>?;
    final phone = contact?['phone'] ?? '';
    
    if (phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _emailSupport() async {
    if (_instructions == null) return;
    
    final contact = _instructions!['contact_support'] as Map<String, dynamic>?;
    final email = contact?['email'] ?? '';
    
    if (email.isNotEmpty) {
      final uri = Uri(
        scheme: 'mailto',
        path: email,
        query: 'subject=Payment Inquiry - ${widget.reference}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(theme, colors),

          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator(theme, colors)
                : _isLoadingError
                    ? _buildErrorView(theme, colors)
                    : _buildInstructionsContent(theme, colors),
          ),

          // Action Buttons
          _buildActionButtons(theme, colors),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.onPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForType(_instructions?['icon'] ?? 'payments'),
                    color: colors.onPrimary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _instructions?['title'] ?? 'Cash Payment Instructions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _instructions?['subtitle'] ?? widget.programTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onPrimary.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (widget.isDialog)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Reference Code Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.onPrimary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.onPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.qr_code, color: colors.onPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Your Payment Reference',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.reference,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _copyReference,
                        icon: Icon(
                          _copyingReference
                              ? Icons.check
                              : Icons.content_copy,
                          size: 18,
                        ),
                        label: Text(_copyingReference ? 'Copied!' : 'Copy'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.onPrimary,
                          foregroundColor: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Show this reference at the payment office',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colors.primary),
          const SizedBox(height: 24),
          Text(
            'Loading payment instructions...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme, ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colors.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Instructions',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loadInstructions,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsContent(ThemeData theme, ColorScheme colors) {
    if (_instructions == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Section
          _buildOverviewSection(theme, colors),

          const SizedBox(height: 32),

          // Steps Section
          _buildStepsSection(theme, colors),

          const SizedBox(height: 32),

          // Required Documents (Expandable)
          _buildDocumentsSection(theme, colors),

          const SizedBox(height: 32),

          // Payment Locations (Expandable)
          _buildLocationsSection(theme, colors),

          const SizedBox(height: 32),

          // Timeline
          _buildTimelineSection(theme, colors),

          const SizedBox(height: 32),

          // Important Notes
          _buildImportantNotesSection(theme, colors),

          const SizedBox(height: 32),

          // Benefits
          _buildBenefitsSection(theme, colors),

          const SizedBox(height: 32),

          // Special Sections (SETA, Corporate, Career Support)
          if (_instructions!['seta_compliance'] != null)
            _buildSpecialSection(
              theme,
              colors,
              _instructions!['seta_compliance'] as Map<String, dynamic>,
            ),

          if (_instructions!['corporate_options'] != null)
            _buildSpecialSection(
              theme,
              colors,
              _instructions!['corporate_options'] as Map<String, dynamic>,
            ),

          if (_instructions!['career_support'] != null)
            _buildSpecialSection(
              theme,
              colors,
              _instructions!['career_support'] as Map<String, dynamic>,
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(ThemeData theme, ColorScheme colors) {
    final overview = _instructions!['overview'] as Map<String, dynamic>;

    return Card(
      color: colors.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: colors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  overview['heading'] as String,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              overview['content'] as String,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (overview['key_points'] as List<dynamic>)
                  .map((point) => Chip(
                        avatar: Icon(
                          Icons.check_circle,
                          size: 18,
                          color: colors.onPrimaryContainer,
                        ),
                        label: Text(
                          point as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                        backgroundColor: colors.primaryContainer,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsSection(ThemeData theme, ColorScheme colors) {
    final steps = _instructions!['steps'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Process',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value as Map<String, dynamic>;
          final isLast = index == steps.length - 1;
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step Number & Line
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: colors.outline.withValues(alpha: 0.3),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Step Content
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getIconForType(step['icon'] as String? ?? 'info'),
                            size: 20,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              step['title'] as String,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step['description'] as String,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (step['details'] != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 18,
                                color: colors.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step['details'] as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDocumentsSection(ThemeData theme, ColorScheme colors) {
    final documents = _instructions!['required_documents'] as List<dynamic>? ?? [];

    return Card(
      child: ExpansionTile(
        leading: Icon(
          Icons.description,
          color: colors.primary,
          size: 28,
        ),
        title: Text(
          'Required Documents',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('${documents.length} documents required'),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: documents
                  .map((doc) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: colors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                doc as String,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsSection(ThemeData theme, ColorScheme colors) {
    final locations = _instructions!['payment_locations'] as Map<String, dynamic>?;

    if (locations == null) return const SizedBox.shrink();

    return Card(
      child: ExpansionTile(
        leading: Icon(
          Icons.location_on,
          color: colors.primary,
          size: 28,
        ),
        title: Text(
          'Payment Locations',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(locations['content'] as String? ?? ''),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...(locations['locations'] as List<dynamic>?)?.map((loc) {
                  final location = loc as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              location['country'] as String,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                            if (location['note'] != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  location['note'] as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colors.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: (location['cities'] as List<dynamic>)
                              .map((city) => Chip(
                                    label: Text(city as String),
                                    avatar: const Icon(Icons.location_city, size: 18),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  );
                }) ?? [],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(ThemeData theme, ColorScheme colors) {
    final timeline = _instructions!['timeline'] as Map<String, dynamic>?;

    if (timeline == null) return const SizedBox.shrink();

    return Card(
      color: colors.tertiaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: colors.tertiary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Timeline & Deadlines',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: timeline.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTimelineLabel(entry.key),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value as String,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantNotesSection(ThemeData theme, ColorScheme colors) {
    final notes = _instructions!['important_notes'] as List<dynamic>? ?? [];

    return Card(
      color: colors.errorContainer.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: colors.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Important Notes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...notes.map((note) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          note as String,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection(ThemeData theme, ColorScheme colors) {
    final benefits = _instructions!['benefits'] as List<dynamic>? ?? [];

    return Card(
      color: colors.secondaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.card_giftcard,
                  color: colors.secondary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Benefits of Cash Payment',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: benefits
                  .map((benefit) => Chip(
                        avatar: Icon(
                          Icons.verified_user,
                          size: 18,
                          color: colors.onSecondaryContainer,
                        ),
                        label: Text(
                          benefit as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                        backgroundColor: colors.secondaryContainer,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialSection(
    ThemeData theme,
    ColorScheme colors,
    Map<String, dynamic> section,
  ) {
    final heading = section['heading'] as String?;
    final content = section['content'] as String?;
    final requirements = section['requirements'] as List<dynamic>?;
    final options = section['options'] as List<dynamic>?;
    final services = section['services'] as List<dynamic>?;

    return Card(
      color: colors.tertiaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_outline,
                  color: colors.tertiary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  heading ?? '',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.tertiary,
                  ),
                ),
              ],
            ),
            if (content != null) ...[
              const SizedBox(height: 12),
              Text(
                content,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (requirements != null) ...[
              const SizedBox(height: 12),
              ...requirements.map((req) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.assignment,
                          color: colors.tertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            req as String,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (options != null) ...[
              const SizedBox(height: 12),
              ...options.map((opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: colors.tertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            opt as String,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (services != null) ...[
              const SizedBox(height: 12),
              ...services.map((svc) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.support_agent,
                          color: colors.tertiary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            svc as String,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Contact Support Button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _callSupport,
                icon: const Icon(Icons.phone),
                label: const Text('Call Support'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Proceed to Office Button
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.location_on),
                label: const Text('I\'ll Visit Office'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'class':
        return Icons.class_;
      case 'school':
        return Icons.school;
      case 'engineering':
        return Icons.engineering;
      case 'auto_stories':
        return Icons.auto_stories;
      case 'work':
        return Icons.work;
      case 'career':
        return Icons.business_center;
      case 'qr_code':
        return Icons.qr_code;
      case 'location_on':
        return Icons.location_on;
      case 'payments':
        return Icons.payments;
      case 'check_circle':
        return Icons.check_circle;
      case 'description':
        return Icons.description;
      case 'fact_check':
        return Icons.fact_check;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.payments;
    }
  }

  String _formatTimelineLabel(String key) {
    switch (key) {
      case 'reservation_period':
        return 'Reservation Period';
      case 'payment_deadline':
        return 'Payment Deadline';
      case 'confirmation':
        return 'Confirmation Time';
      case 'access_granted':
        return 'Access Granted';
      case 'verification_time':
        return 'Verification Time';
      case 'course_access':
        return 'Course Access Period';
      case 'career_consultation':
        return 'Career Consultation';
      default:
        return key.replaceAll('_', ' ').split(' ').map((word) {
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
    }
  }
}
