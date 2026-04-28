import 'package:flutter/material.dart';
import 'package:frontend/src/core/api/api_client.dart';

class PartnerProgramModal extends StatefulWidget {
  const PartnerProgramModal({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const PartnerProgramModal(),
        );
      },
    );
  }

  @override
  State<PartnerProgramModal> createState() => _PartnerProgramModalState();
}

class _PartnerProgramModalState extends State<PartnerProgramModal> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _reachController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _otpController = TextEditingController();
  
  List<TextEditingController> _socialLinkControllers = [TextEditingController()];
  
  bool _isSubmitting = false;
  bool _isLoadingCountries = true;
  List<Map<String, dynamic>> _countries = [];
  
  int? _selectedCountryId;
  List<int> _selectedInfluenceCountryIds = [];

  // OTP States
  bool _isEmailVerified = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _fetchCountries();
  }

  Future<void> _fetchCountries() async {
    try {
      final countries = await ApiClient.getAfricanCountries();
      if (mounted) {
        setState(() {
          _countries = countries;
          _isLoadingCountries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCountries = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load countries. Please check your connection.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _reachController.dispose();
    _businessNameController.dispose();
    _notesController.dispose();
    _otpController.dispose();
    for (var controller in _socialLinkControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSocialLink() {
    setState(() {
      _socialLinkControllers.add(TextEditingController());
    });
  }

  void _removeSocialLink(int index) {
    setState(() {
      _socialLinkControllers[index].dispose();
      _socialLinkControllers.removeAt(index);
    });
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address first.')),
      );
      return;
    }

    setState(() => _isSendingOtp = true);
    try {
      await ApiClient.sendContactOTP(contact: email, contactType: 'email');
      if (mounted) {
        setState(() {
          _otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code sent! Please check your email.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP code.')),
      );
      return;
    }

    setState(() => _isVerifyingOtp = true);
    try {
      await ApiClient.verifyContactOTP(contact: email, contactType: 'email', otp: otp);
      if (mounted) {
        setState(() {
          _isEmailVerified = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifyingOtp = false);
    }
  }

  void _showInfluenceCountriesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Countries of Influence'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _countries.length,
                  itemBuilder: (context, index) {
                    final country = _countries[index];
                    final countryId = country['id'] as int;
                    final isSelected = _selectedInfluenceCountryIds.contains(countryId);
                    
                    return CheckboxListTile(
                      title: Text(country['name']),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedInfluenceCountryIds.add(countryId);
                          } else {
                            _selectedInfluenceCountryIds.remove(countryId);
                          }
                        });
                        setState(() {}); // Update parent UI
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must verify your email address before submitting.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      // Build social media handles dictionary
      Map<String, String> socialMedia = {};
      for (int i = 0; i < _socialLinkControllers.length; i++) {
        final link = _socialLinkControllers[i].text.trim();
        if (link.isNotEmpty) {
          socialMedia['link_${i + 1}'] = link;
        }
      }

      final payload = {
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'partner_type': 'INDIVIDUAL', // default
        'country': _selectedCountryId,
        'influence_countries': _selectedInfluenceCountryIds,
        'estimated_reach': int.tryParse(_reachController.text.trim()) ?? 0,
        'business_name': _businessNameController.text.trim(),
        'social_media_handles': socialMedia,
        'notes': _notesController.text.trim(),
      };

      await ApiClient.submitPartnerApplication(payload);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully! Our team will review it and get back to you.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit application. Please try again. \n$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Become a Marketing Partner',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Leverage your social media presence and network to market our courses for an agreed commission. Apply below!',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                      validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // --- EMAIL OTP SECTION ---
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email Address *', 
                              border: const OutlineInputBorder(),
                              suffixIcon: _isEmailVerified 
                                ? const Icon(Icons.check_circle, color: Colors.green) 
                                : null,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isEmailVerified,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required field';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                        ),
                        if (!_isEmailVerified) ...[
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isSendingOtp ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            child: _isSendingOtp 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                              : Text(_otpSent ? 'Resend' : 'Send OTP'),
                          ),
                        ]
                      ],
                    ),
                    
                    if (_otpSent && !_isEmailVerified) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _otpController,
                              decoration: const InputDecoration(
                                labelText: 'Enter OTP Code', 
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isVerifyingOtp ? null : _verifyOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            child: _isVerifyingOtp 
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                              : const Text('Verify', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // --- COUNTRY SELECTION ---
                    if (_isLoadingCountries)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Country of Origin *',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedCountryId,
                        items: _countries.map((country) {
                          return DropdownMenuItem<int>(
                            value: country['id'] as int,
                            child: Text(country['name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCountryId = value;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a country' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // INFLUENCE COUNTRIES
                      InkWell(
                        onTap: _showInfluenceCountriesDialog,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Countries of Influence',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedInfluenceCountryIds.isEmpty 
                                    ? 'Select where you have reach...' 
                                    : '${_selectedInfluenceCountryIds.length} countries selected',
                                  style: TextStyle(
                                    color: _selectedInfluenceCountryIds.isEmpty ? Colors.grey[600] : Colors.black87,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      
                      if (_selectedInfluenceCountryIds.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedInfluenceCountryIds.map((id) {
                            final country = _countries.firstWhere((c) => c['id'] == id);
                            return Chip(
                              label: Text(country['name']),
                              onDeleted: () {
                                setState(() {
                                  _selectedInfluenceCountryIds.remove(id);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(labelText: 'Business / Brand Name (Optional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    const Text('Social Media & Reach', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Add links to your social profiles, blogs, or platforms so we can evaluate your reach.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 12),
                    ...List.generate(_socialLinkControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _socialLinkControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Social Link ${index + 1}',
                                  border: const OutlineInputBorder(),
                                  hintText: 'e.g. https://instagram.com/yourhandle',
                                ),
                              ),
                            ),
                            if (_socialLinkControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => _removeSocialLink(index),
                              ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: _addSocialLink,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Another Link'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _reachController,
                      decoration: const InputDecoration(labelText: 'Total Estimated Reach (Followers/Subscribers)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(labelText: 'Why do you want to partner with us?', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitApplication,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit Application', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
