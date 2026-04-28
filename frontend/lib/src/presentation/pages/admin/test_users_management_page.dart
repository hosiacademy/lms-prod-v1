// lib/src/presentation/pages/admin/test_users_management_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/aicerts_api_client.dart';

/// Test Users Management Page
///
/// **Purpose**: Create and manage test accounts for AICERTS integration testing
/// **Users**: Admin only
///
/// **Features**:
/// 1. Create test student accounts (HOSI backend)
/// 2. Create test instructor accounts (HOSI backend)
/// 3. Create AICERTS test accounts (calls AICERTS API)
/// 4. View existing test accounts
/// 5. Copy credentials for easy testing
/// 6. Delete test accounts when done
class TestUsersManagementPage extends StatefulWidget {
  const TestUsersManagementPage({super.key});

  @override
  State<TestUsersManagementPage> createState() =>
      _TestUsersManagementPageState();
}

class _TestUsersManagementPageState extends State<TestUsersManagementPage> {
  List<Map<String, dynamic>> _testUsers = [];
  bool _isLoading = false;
  String? _error;

  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTestUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadTestUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await ApiClient.getTestUsers();
      if (mounted) {
        setState(() {
          _testUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load test users: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createTestStudent() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.createTestStudent(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showCreatedDialog('Test Student Created', response, 'learner');
        _clearForm();
        _loadTestUsers();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Failed to create test student: $e', isError: true);
      }
    }
  }

  Future<void> _createTestInstructor() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.createTestInstructor(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showCreatedDialog('Test Instructor Created', response, 'instructor');
        _clearForm();
        _loadTestUsers();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showMessage('Failed to create test instructor: $e', isError: true);
      }
    }
  }

  Future<void> _createAICERTSStudent() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final response = await AICERTSApiClient.createTestStudent(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showAICERTSCreatedDialog('AICERTS Test Student Created', response);
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _handleAICERTSError(e);
      }
    }
  }

  Future<void> _createAICERTSInstructor() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final response = await AICERTSApiClient.createTestInstructor(
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showAICERTSCreatedDialog('AICERTS Test Instructor Created', response);
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _handleAICERTSError(e);
      }
    }
  }

  Future<void> _deleteTestUser(String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test User'),
        content: Text('Are you sure you want to delete test user:\n$email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.deleteTestUser(email);
      _showMessage('Test user deleted');
      _loadTestUsers();
    } catch (e) {
      _showMessage('Failed to delete test user: $e', isError: true);
    }
  }

  bool _validateForm() {
    if (_emailController.text.trim().isEmpty ||
        _firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty) {
      _showMessage('Please fill in all fields', isError: true);
      return false;
    }
    return true;
  }

  void _clearForm() {
    _emailController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _showCreatedDialog(
    String title,
    Map<String, dynamic> response,
    String role,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCredentialRow('Email', response['email'] ?? 'N/A'),
              _buildCredentialRow(
                'Password',
                response['password'] ?? response['temporary_password'] ?? 'N/A',
              ),
              _buildCredentialRow('Role', role),
              _buildCredentialRow(
                  'User ID', response['user_id']?.toString() ?? 'N/A'),
              const SizedBox(height: 16),
              Text(
                'Use these credentials to login and test ${role == 'learner' ? 'student' : role} functionality.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAICERTSCreatedDialog(String title, Map<String, dynamic> response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCredentialRow('Email', response['email'] ?? 'N/A'),
              _buildCredentialRow('Username', response['username'] ?? 'N/A'),
              _buildCredentialRow(
                'Password',
                response['temporary_password'] ?? 'N/A',
              ),
              _buildCredentialRow('Role', response['role'] ?? 'N/A'),
              if (response['lms_access_url'] != null)
                _buildCredentialRow('LMS URL', response['lms_access_url']),
              if (response['lms_admin_url'] != null)
                _buildCredentialRow('Admin URL', response['lms_admin_url']),
              const SizedBox(height: 16),
              Text(
                'Login to AICERTS LMS using these credentials.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleAICERTSError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('CORS')) {
      _showCORSErrorDialog();
    } else if (errorStr.contains('not found') || errorStr.contains('404')) {
      _showEndpointNotFoundDialog();
    } else {
      _showMessage('Failed to create AICERTS user: $e', isError: true);
    }
  }

  void _showCORSErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text('CORS Error'),
          ],
        ),
        content: const Text(
          'AICERTS server has not configured CORS headers to allow requests from HOSI domain.\n\n'
          'Please share AICERTS_INTEGRATION_REQUIREMENTS.md with AICERTS team.\n\n'
          'They need to add Access-Control-Allow-Origin headers to their API.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEndpointNotFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            const Text('Endpoint Not Found'),
          ],
        ),
        content: const Text(
          'AICERTS API endpoint for test user creation does not exist yet.\n\n'
          'Please share AICERTS_INTEGRATION_REQUIREMENTS.md with AICERTS team.\n\n'
          'They need to implement:\n'
          '- POST /wp-json/aicerts-api/v1/test-users/student\n'
          '- POST /wp-json/aicerts-api/v1/test-users/instructor',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(value),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              _showMessage('Copied to clipboard');
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Users Management'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Test accounts are for development and testing only. '
                            'Do not use in production environment.',
                            style: TextStyle(color: Colors.orange[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create test user form
                  Text(
                    'Create Test User',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'test-user@hosiafrica.com',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _createTestStudent,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Create HOSI Student'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _createTestInstructor,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Create HOSI Instructor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.secondary,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _createAICERTSStudent,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Create AICERTS Student'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _createAICERTSInstructor,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Create AICERTS Instructor'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Existing test users
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Existing Test Users',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _loadTestUsers,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_error!, style: TextStyle(color: Colors.red)),
                    )
                  else if (_testUsers.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No test users found',
                          style: TextStyle(color: colors.onSurface),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _testUsers.length,
                      itemBuilder: (context, index) {
                        final user = _testUsers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user['role'] == 'learner'
                                  ? colors.primary
                                  : colors.secondary,
                              child: Icon(
                                user['role'] == 'learner'
                                    ? Icons.person
                                    : Icons.school,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(user['email'] ?? 'N/A'),
                            subtitle: Text(
                              '${user['first_name'] ?? ''} ${user['last_name'] ?? ''} - ${user['role'] ?? 'N/A'}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTestUser(user['email']),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}
