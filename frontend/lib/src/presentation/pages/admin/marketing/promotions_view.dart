// lib/src/presentation/pages/admin/marketing/promotions_view.dart
import 'package:flutter/material.dart';
import 'package:frontend/src/core/api/api_client.dart';
import 'package:intl/intl.dart';

class PromotionsView extends StatefulWidget {
  const PromotionsView({super.key});

  @override
  State<PromotionsView> createState() => _PromotionsViewState();
}

class _PromotionsViewState extends State<PromotionsView> {
  List<Map<String, dynamic>> _coupons = [];
  List<dynamic> _pathways = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/api/v1/payments/admin/marketing/promotions/');
      if (mounted) {
        setState(() {
          _coupons = List<Map<String, dynamic>>.from(response.data['coupons'] ?? []);
          _pathways = response.data['pathways'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createPromotion() async {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    String? selectedPathway = 'all';
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Promotion'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Coupon Code*', hintText: 'e.g. SUMMER25'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Promotion Name', hintText: 'e.g. Summer AI Special'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Discount Value (%)', hintText: 'e.g. 15'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedPathway,
                  decoration: const InputDecoration(labelText: 'Target Stream / Category'),
                  items: _pathways.map<DropdownMenuItem<String>>((p) {
                    return DropdownMenuItem<String>(
                      value: p[0],
                      child: Text(p[1]),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedPathway = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Launch Promotion'),
            ),
          ],
        ),
      ),
    );

    if (result == true && codeCtrl.text.isNotEmpty) {
      try {
        await ApiClient.post('/api/v1/payments/admin/marketing/promotions/', data: {
          'code': codeCtrl.text.toUpperCase(),
          'name': nameCtrl.text,
          'discount_value': double.tryParse(valueCtrl.text) ?? 0,
          'product_pathway': selectedPathway,
          'discount_type': 'percentage',
        });
        _loadData();
        _snack('Promotion created successfully');
      } catch (e) {
        _snack('Error: $e');
      }
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Promotions', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Manage discount codes and stream-specific campaigns', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurface.withValues(alpha: 0.6))),
                ],
              ),
              FilledButton.icon(
                onPressed: _createPromotion,
                icon: const Icon(Icons.add),
                label: const Text('New Promotion'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _coupons.isEmpty
                    ? _buildEmptyState(colors)
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          mainAxisExtent: 180,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _coupons.length,
                        itemBuilder: (context, i) {
                          final coupon = _coupons[i];
                          final isCyber = coupon['product_pathway'] == 'cybersecurity';
                          final isAI = coupon['product_pathway'] == 'ai_blockchain';
                          
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: colors.primaryContainer.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(coupon['code'], style: TextStyle(fontWeight: FontWeight.bold, color: colors.primary, fontSize: 14)),
                                      ),
                                      Switch(
                                        value: coupon['is_active'] ?? true,
                                        onChanged: (v) {}, // TODO: Toggle status
                                        activeColor: colors.primary,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(coupon['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pathway: ${coupon['product_pathway'].toString().toUpperCase()}',
                                    style: TextStyle(fontSize: 12, color: (isCyber || isAI) ? Colors.deepPurple : Colors.grey),
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${coupon['discount_value']}% OFF', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.green)),
                                      Text(
                                        'Expires: ${coupon['valid_until'] != null ? DateFormat('MMM d, yyyy').format(DateTime.parse(coupon['valid_until'])) : "Never"}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: colors.onSurface.withValues(alpha: 0.1)),
          const SizedBox(height: 20),
          const Text('No promotions set yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Create a coupon code to boost enrollment in specific training streams.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          FilledButton(onPressed: _createPromotion, child: const Text('Create First Coupon')),
        ],
      ),
    );
  }
}
