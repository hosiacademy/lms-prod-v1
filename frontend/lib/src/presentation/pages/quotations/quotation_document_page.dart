// lib/src/presentation/pages/quotations/quotation_document_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/currency_service.dart';

class QuotationDocumentPage extends StatefulWidget {
  final String quotationNumber;

  const QuotationDocumentPage({
    super.key,
    required this.quotationNumber,
  });

  @override
  State<QuotationDocumentPage> createState() => _QuotationDocumentPageState();
}

class _QuotationDocumentPageState extends State<QuotationDocumentPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _quotation;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuotation();
  }

  Future<void> _loadQuotation() async {
    try {
      final response = await ApiClient.get('/api/v1/payments/quotations/public/${widget.quotationNumber}/');
      setState(() {
        _quotation = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _quotation == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: ${_error ?? "Quotation not found"}'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _quotation!;
    final client = data['client'] ?? {};
    final pricing = data['pricing'] ?? {};

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Quotation ${widget.quotationNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              // Browser print
              // In production we'd use a real print service or JS interop
            },
            tooltip: 'Print Quotation',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header (Brand + Title)
                _buildHeader(colors),

                Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Quote Summary (Metadata)
                      _buildQuoteSummary(data),
                      const SizedBox(height: 48),

                      // 3. Client Information
                      _buildClientInfo(client),
                      const SizedBox(height: 48),

                      // 4. Line Items Table
                      _buildLineItemsTable(data, pricing, colors),
                      const SizedBox(height: 48),

                      // 5. Product/Service Description (Long-form)
                      _buildDetailedDescription(data),
                      const SizedBox(height: 48),

                      // 6. Pricing Summary
                      _buildPricingSummary(pricing, colors),
                      const SizedBox(height: 48),

                      // 7. Payment Status
                      _buildPaymentStatus(pricing),
                      
                      const SizedBox(height: 80),
                      _buildFooter(colors),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(48),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hosi Academy Zimbabwe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'QUOTE',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: colors.primary,
              letterSpacing: 2.0,
            ),
          ),
          Container(
            height: 4,
            width: 80,
            color: colors.primary,
            margin: const EdgeInsets.only(top: 8),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteSummary(Map<String, dynamic> data) {
    final createdAt = data['created_at'] != null 
        ? DateTime.parse(data['created_at']) 
        : DateTime.now();
    final expiresAt = data['expires_at'] != null 
        ? DateTime.parse(data['expires_at']) 
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMetaField('Quote Number', data['quotation_number'] ?? 'N/A'),
        const SizedBox(width: 48),
        _buildMetaField('Quote Date', DateFormat('dd/MMM/yyyy').format(createdAt)),
        const SizedBox(width: 48),
        if (expiresAt != null)
          _buildMetaField('Valid Until', DateFormat('dd/MMM/yyyy').format(expiresAt)),
        const Spacer(),
        _buildMetaField(
          'Total', 
          '${data['pricing']['local_currency']} ${NumberFormat("#,##0.00").format(double.tryParse(data['pricing']['local_amount'].toString()) ?? 0.0)}',
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildMetaField(String label, String value, {bool isLarge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isLarge ? 18 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildClientInfo(Map<String, dynamic> client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BILL TO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          client['company'] ?? client['name'] ?? 'Guest Client',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (client['reference_code'] != null && client['reference_code'].toString().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Code: ${client['reference_code']}',
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
        const SizedBox(height: 12),
        if (client['address'] != null && client['address'].toString().isNotEmpty)
          Text(
            client['address'],
            style: const TextStyle(height: 1.5, fontSize: 13),
          ),
        const SizedBox(height: 8),
        Text(
          client['email'] ?? 'N/A',
          style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildLineItemsTable(Map<String, dynamic> data, Map<String, dynamic> pricing, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(4),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1.5),
          },
          children: [
            // Header Row
            TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 2)),
              ),
              children: [
                _buildTableCell('Item', isHeader: true),
                _buildTableCell('Description', isHeader: true),
                _buildTableCell('Unit Cost', isHeader: true, alignRight: true),
                _buildTableCell('Qty', isHeader: true, alignCenter: true),
                _buildTableCell('Total', isHeader: true, alignRight: true),
              ],
            ),
            // Data Row
            TableRow(
              children: [
                _buildTableCell(data['training_type'] == 'course' ? '601' : '701'), // Example item codes
                _buildTableCell('${data['training_type'].toString().toUpperCase()} - ${data['training_item']}'),
                _buildTableCell(
                  CurrencyService.instance.formatPrice(double.tryParse(pricing['base_price'].toString()) ?? 0.0),
                  alignRight: true,
                ),
                _buildTableCell(pricing['quantity'].toString(), alignCenter: true),
                _buildTableCell(
                  CurrencyService.instance.formatPrice(
                    (double.tryParse(pricing['base_price'].toString()) ?? 0.0) * (pricing['quantity'] ?? 1),
                  ),
                  alignRight: true,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, bool alignRight = false, bool alignCenter = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : (alignCenter ? TextAlign.center : TextAlign.left),
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 12 : 14,
          color: isHeader ? Colors.grey[700] : Colors.black,
        ),
      ),
    );
  }

  Widget _buildDetailedDescription(Map<String, dynamic> data) {
    // This would typically come from the training item's metadata
    // For now we use the description field or a placeholder based on type
    final description = data['description'] ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRODUCT / SERVICE DESCRIPTION',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        
        // Introduction
        const Text(
          'Introduction',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          description.isNotEmpty ? description : 'This professional certification program is designed to equip individuals with world-class skills in modern Artificial Intelligence. The curriculum covers foundational concepts, advanced neural networks, and industry-standard deployment strategies across major cloud platforms including AWS, Azure, and Google Cloud.',
          style: const TextStyle(height: 1.6, fontSize: 14),
        ),
        
        const SizedBox(height: 32),
        
        // Topics List
        const Text(
          'Key Learning Areas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopicItem('Foundations of Artificial Intelligence & Data Science'),
            _TopicItem('Machine Learning: Supervised and Unsupervised Models'),
            _TopicItem('Deep Learning Architecture & Neural Networks'),
            _TopicItem('Natural Language Processing (NLP) & Generative AI'),
            _TopicItem('AI Ethics, Governance & Enterprise Implementation'),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Prerequisites
        const Text(
          'Prerequisites',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildPrerequisiteItem('Basic Mathematics', 'Comfort with statistics and foundational algebra for model evaluation.'),
        _buildPrerequisiteItem('Computer Science', 'Understanding of basic algorithms and data structures.'),
        _buildPrerequisiteItem('Python Programming', 'Working knowledge of Python syntax and library management.'),
      ],
    );
  }

  Widget _buildPrerequisiteItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSummary(Map<String, dynamic> pricing, ColorScheme colors) {
    final subtotal = (double.tryParse(pricing['base_price'].toString()) ?? 0.0) * (pricing['quantity'] ?? 1);
    final discountPct = double.tryParse(pricing['discount_percentage'].toString()) ?? 0.0;
    final discountAmount = double.tryParse(pricing['discount_amount'].toString()) ?? 0.0;
    final total = double.tryParse(pricing['total_amount'].toString()) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildPriceLine('Net (USD):', CurrencyService.instance.formatPrice(total)),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        _buildPriceLine('Subtotal:', CurrencyService.instance.formatPrice(subtotal)),
        if (discountPct > 0)
          _buildPriceLine(
            'Discount (${discountPct.toStringAsFixed(0)}%):', 
            '- ${CurrencyService.instance.formatPrice(discountAmount)}',
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: _buildPriceLine(
            'TOTAL AMOUNT (USD):', 
            CurrencyService.instance.formatPrice(total),
            isBold: true,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Equiv: ${pricing['local_currency']} ${NumberFormat("#,##0.00").format(double.tryParse(pricing['local_amount'].toString()) ?? 0.0)}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildPriceLine(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? Colors.grey[700],
          ),
        ),
        const SizedBox(width: 48),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatus(Map<String, dynamic> pricing) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'PAYMENT STATUS',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          Text(
            'Paid to Date: ${pricing['local_currency']} 0.00',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme colors) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Thank you for your business!',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
            Text(
              'www.hosi-academy.com',
              style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

class _TopicItem extends StatelessWidget {
  final String text;
  const _TopicItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 12.0),
            child: CircleAvatar(radius: 3, backgroundColor: Colors.black),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
