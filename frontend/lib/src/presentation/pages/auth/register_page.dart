// lib/src/presentation/pages/auth/register_page.dart
import 'dart:convert';
import 'package:crypto/crypto.dart'; // Add to pubspec.yaml: crypto: ^3.0.3
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  final String courseId;

  const RegisterPage({super.key, required this.courseId});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Replace these with your actual values from backend/config/env
  final String _wstoken = 'YOUR_REAL_WSTOKEN_HERE';
  final String _partnerId = 'YOUR_REAL_PARTNER_ID_HERE';
  final String _secretKey =
      'YOUR_REAL_HMAC_SECRET_KEY_HERE'; // From AICERTs team

  String _generateSignature(String data) {
    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key); // Correct: use sha256 from crypto
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _registerAndEnroll() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final email = _emailController.text.trim();

    // Step 1: Signature for user creation
    final userData = "$email:$timestamp";
    final userSignature = _generateSignature(userData);

    try {
      // Create user
      final createResponse = await Dio().post(
        'https://learn.aicerts.io/webservice/rest/server.php',
        data: {
          'wstoken': _wstoken,
          'wsfunction': 'core_user_create_users',
          'moodlewsrestformat': 'json',
          'users[0][firstname]': _firstNameController.text.trim(),
          'users[0][lastname]': _lastNameController.text.trim(),
          'users[0][email]': email,
          'users[0][username]': email,
          'timestamp': timestamp,
          'signature': userSignature,
          'users[0][partner_id]': _partnerId,
          'users[0][source]': 'sso',
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      if (createResponse.data is List && createResponse.data.isNotEmpty) {
        final responseData = createResponse.data[0];
        if (responseData['status'] == 'success') {
          final userId = responseData['id'];

          // Step 2: Signature for enrollment (adjust data string as per your API requirements)
          final enrollData = "$userId:$timestamp";
          final enrollSignature = _generateSignature(enrollData);

          final enrollResponse = await Dio().post(
            'https://learn.aicerts.io/webservice/rest/server.php',
            data: {
              'wstoken': _wstoken,
              'wsfunction': 'enrol_manual_enrol_users',
              'moodlewsrestformat': 'json',
              'enrolments[0][roleid]': 5, // Student role - confirm with AICERTs
              'enrolments[0][courseid]': widget.courseId,
              'enrolments[0][userid]': userId,
              'enrolments[0][enrollmentsourcefrom]': 'hosi',
              'timestamp': timestamp,
              'signature': enrollSignature,
              'enrolments[0][partner_id]': _partnerId,
            },
            options: Options(contentType: Headers.formUrlEncodedContentType),
          );

          if (enrollResponse.data['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Registration & Enrollment Successful!')),
            );
            context.go('/'); // Redirect to dashboard/home
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Enrollment failed: ${enrollResponse.data['message'] ?? 'Unknown error'}')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Registration failed: ${responseData['message'] ?? 'Unknown error'}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unexpected response from server')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register for Course ${widget.courseId}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                    labelText: 'First Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                    labelText: 'Last Name', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains('@')
                    ? 'Valid email required'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                    labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) =>
                    value!.length < 6 ? 'At least 6 characters' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerAndEnroll,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Register & Enroll'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
