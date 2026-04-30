// lib/src/presentation/pages/payment/cash_payment_instructions_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';

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
        _error = e.toString();
        _isLoading = false;
        _isLoadingError = true;
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
        ),
      );
    }
  }

  void _contactSupport() {
    if (_instructions == null) return;
    final contact = _instructions!['contact_support'] as Map<String, dynamic>?;
    if (contact != null && contact['email'] != null) {
      launchUrl(Uri.parse('mailto:${contact['email']}'));
    }
  }

  void _callSupport() {
    if (_instructions == null) return;
    final contact = _instructions!['contact_support'] as Map<String, dynamic>?;
    if (contact != null && contact['phone'] != null) {
      launchUrl(Uri.parse('tel:${contact['phone']}'));
    }
  }

  void _emailSupport() {
    if (_instructions == null) return;
    final contact = _instructions!['contact_support'] as Map<String, dynamic>?;
    if (contact != null && contact['email'] != null) {
      final email = contact['email'];
      final subject = 'Payment Inquiry - ${widget.reference}';
      launchUrl(Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject)}'));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isLoadingError) {
      return Scaffold(
        appBar: widget.isDialog ? null : AppBar(title: const Text('Cash Payment Instructions')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load instructions: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInstructions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_instructions == null) {
      return const Scaffold(
        body: Center(child: Text('No instructions available')),
      );
    }

    final contact = _instructions!['contact_support'] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: widget.isDialog ? Colors.transparent : Colors.grey[100],
      appBar: widget.isDialog ? null : AppBar(
        title: const Text('Cash Payment Instructions'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.green.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    _getIconForType(_instructions?['icon'] ?? 'payments'),
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _instructions?['title'] ?? 'Cash Payment Instructions',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _instructions?['subtitle'] ?? widget.programTitle,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Reference Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Payment Reference',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.reference,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _copyReference,
                            icon: Icon(
                              _copyingReference ? Icons.check : Icons.copy,
                              color: _copyingReference ? Colors.green : Colors.grey,
                            ),
                            tooltip: 'Copy reference',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Amount: ${widget.currency} ${widget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (widget.isDialog)
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Close'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildOverview(),
            const SizedBox(height: 24),
            _buildSteps(),
            const SizedBox(height: 24),
            _buildDocuments(),
            const SizedBox(height: 24),
            _buildPaymentLocations(),
            const SizedBox(height: 24),
            _buildTimeline(),
            const SizedBox(height: 24),
            _buildImportantNotes(),
            const SizedBox(height: 24),
            _buildBenefits(),
            const SizedBox(height: 24),

            if (contact != null) _buildContactSupport(contact),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'class': return Icons.class_;
      case 'school': return Icons.school;
      case 'engineering': return Icons.engineering;
      case 'auto_stories': return Icons.auto_stories;
      case 'work': return Icons.work;
      case 'qr_code': return Icons.qr_code;
      case 'location_on': return Icons.location_on;
      case 'payments': return Icons.payments;
      case 'check_circle': return Icons.check_circle;
      case 'description': return Icons.description;
      case 'fact_check': return Icons.fact_check;
      default: return Icons.payments;
    }
  }

  Widget _buildOverview() {
    final overview = _instructions!['overview'] as Map<String, dynamic>?;
    if (overview == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              overview['heading'] ?? 'How It Works',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(overview['content'] ?? ''),
            if (overview['key_points'] != null) ...[
              const SizedBox(height: 12),
              ...(overview['key_points'] as List<dynamic>).map(
                (point) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(point.toString())),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSteps() {
    final steps = _instructions!['steps'] as List<dynamic>? ?? [];
    if (steps.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step-by-Step Process',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...steps.map((step) => _buildStepItem(step as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(Map<String, dynamic> step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${step['step']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step['title'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(step['description'] ?? ''),
                if (step['details'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    step['details'],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocuments() {
    final documents = _instructions!['required_documents'] as List<dynamic>? ?? [];
    if (documents.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Required Documents',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...documents.map((doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(doc.toString())),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentLocations() {
    final locations = _instructions!['payment_locations'] as Map<String, dynamic>?;
    if (locations == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  locations['heading'] ?? 'Payment Locations',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(locations['content'] ?? ''),
            const SizedBox(height: 12),
            ...(locations['locations'] as List<dynamic>? ?? []).map((loc) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📍 ${loc['country']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Cities: ${(loc['cities'] as List).join(', ')}'),
                      if (loc['note'] != null)
                        Text('Note: ${loc['note']}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final timeline = _instructions!['timeline'] as Map<String, dynamic>?;
    if (timeline == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Timeline & Deadlines',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...timeline.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${entry.key}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.value.toString())),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantNotes() {
    final notes = _instructions!['important_notes'] as List<dynamic>? ?? [];
    if (notes.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Important Notes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...notes.map((note) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(note.toString())),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefits() {
    final benefits = _instructions!['benefits'] as List<dynamic>? ?? [];
    if (benefits.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.celebration, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Benefits',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...benefits.map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(child: Text(benefit.toString())),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSupport(Map<String, dynamic> contact) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Need Help?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (contact['phone'] != null)
              GestureDetector(
                onTap: _callSupport,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.phone, size: 20, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(contact['phone']),
                    ],
                  ),
                ),
              ),
            if (contact['email'] != null)
              GestureDetector(
                onTap: _emailSupport,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.email, size: 20, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(contact['email']),
                    ],
                  ),
                ),
              ),
            if (contact['hours'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  contact['hours'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
