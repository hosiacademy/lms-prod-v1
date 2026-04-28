import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class AdminRoleRequestPanel extends StatefulWidget {
  const AdminRoleRequestPanel({super.key});

  @override
  State<AdminRoleRequestPanel> createState() => _AdminRoleRequestPanelState();
}

class _AdminRoleRequestPanelState extends State<AdminRoleRequestPanel> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _justificationController = TextEditingController();
  
  String _selectedRole = 'hr_admin';
  int? _selectedCountryId;
  List<Map<String, dynamic>> _countries = [];
  bool _isLoadingCountries = false;
  bool _isSubmitting = false;

  final List<Map<String, String>> _roles = [
    {'value': 'hr_admin', 'label': 'HR Administrator'},
    {'value': 'payment_admin', 'label': 'Payment Administrator'},
    {'value': 'marketing_admin', 'label': 'Marketing Administrator'},
    {'value': 'executive_admin', 'label': 'Executive Administrator'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoadingCountries = true);
    try {
      final response = await ApiClient.get('/api/v1/auth/countries/');
      if (response.statusCode == 200) {
        setState(() {
          _countries = List<Map<String, dynamic>>.from(response.data);
        });
      }
    } catch (e) {
      print('Error loading countries: $e');
    } finally {
      setState(() => _isLoadingCountries = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await ApiClient.post(
        '/api/v1/payments/admin-role-requests/',
        data: {
          'candidate_name': _nameController.text.trim(),
          'candidate_email': _emailController.text.trim(),
          'proposed_role': _selectedRole,
          'target_country': _selectedCountryId,
          'justification': _justificationController.text.trim(),
        },
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin role request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Request New Administrator Role',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'HR and Regional Admins can use this form to propose new staff members for specific administrative roles. Requests will be reviewed by System Administrators.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Candidate Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Candidate Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (!value.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Proposed Role',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem(
                    value: role['value'],
                    child: Text(role['label']!),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<int>(
                value: _selectedCountryId,
                decoration: InputDecoration(
                  labelText: 'Target Country (Scope)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.public),
                  suffixIcon: _isLoadingCountries ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                ),
                hint: const Text('Select Country'),
                items: _countries.map((country) {
                  return DropdownMenuItem<int>(
                    value: country['id'],
                    child: Text(country['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCountryId = val),
                validator: (value) => value == null ? 'Please select a country' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _justificationController,
                decoration: const InputDecoration(
                  labelText: 'Justification / Notes',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Request to System Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
