// lib/src/data/models/messaging.dart

/// Messaging and Communication Models

/// SMS Campaign Model
class SMSCampaign {
  final int? id;
  final String messageText;
  final List<String> recipientNumbers;
  final List<int>? userIds;
  final String status; // 'draft', 'sending', 'sent', 'failed'
  final int totalRecipients;
  final int successCount;
  final int failureCount;
  final int skippedCount;
  final DateTime? createdAt;
  final DateTime? sentAt;
  final Map<String, dynamic>? metadata;
  final List<SMSDeliveryResult>? results;

  const SMSCampaign({
    this.id,
    required this.messageText,
    required this.recipientNumbers,
    this.userIds,
    required this.status,
    this.totalRecipients = 0,
    this.successCount = 0,
    this.failureCount = 0,
    this.skippedCount = 0,
    this.createdAt,
    this.sentAt,
    this.metadata,
    this.results,
  });

  factory SMSCampaign.fromJson(Map<String, dynamic> json) {
    return SMSCampaign(
      id: json['id'],
      messageText: json['message'] ?? json['message_text'] ?? '',
      recipientNumbers: List<String>.from(json['numbers'] ?? []),
      userIds: json['user_ids'] != null ? List<int>.from(json['user_ids']) : null,
      status: json['status'] ?? 'draft',
      totalRecipients: json['summary']?['total'] ?? 0,
      successCount: json['summary']?['sent'] ?? json['sent_count'] ?? 0,
      failureCount: json['summary']?['failed'] ?? json['failed_count'] ?? 0,
      skippedCount: json['summary']?['skipped'] ?? json['skipped_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      metadata: json['metadata'],
      results: json['details'] != null
          ? (json['details']['sent'] as List?)
              ?.map((r) => SMSDeliveryResult.fromJson(r))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'message': messageText,
        'numbers': recipientNumbers,
        'user_ids': userIds,
        'status': status,
      };

  // Calculate character count for message
  int get characterCount => messageText.length;
  
  // Check if message fits in single SMS (160 chars) or multiple (153 chars per SMS)
  int get smsCount {
    if (characterCount <= 160) return 1;
    return ((characterCount - 160) ~/ 153) + 1;
  }
}

/// SMS Delivery Result (per number)
class SMSDeliveryResult {
  final String number;
  final String? sid;
  final String status; // 'sent', 'failed', 'skipped'
  final String? error;
  final DateTime? sentAt;

  const SMSDeliveryResult({
    required this.number,
    this.sid,
    required this.status,
    this.error,
    this.sentAt,
  });

  factory SMSDeliveryResult.fromJson(Map<String, dynamic> json) {
    return SMSDeliveryResult(
      number: json['number'] ?? '',
      sid: json['sid'],
      status: json['status'] ?? 'unknown',
      error: json['error'] ?? json['reason'],
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
    );
  }
}

/// User with Phone Number (for recipient selection)
class UserPhone {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String country;

  const UserPhone({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.country,
  });

  factory UserPhone.fromJson(Map<String, dynamic> json) {
    final phone = json['phone'] ?? '';
    final country = _extractCountryFromPhone(phone);
    
    return UserPhone(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: phone,
      country: country,
    );
  }

  static String _extractCountryFromPhone(String phone) {
    if (phone.startsWith('+27')) return 'ZA';
    if (phone.startsWith('+254')) return 'KE';
    if (phone.startsWith('+263')) return 'ZW';
    if (phone.startsWith('+260')) return 'ZM';
    return 'Unknown';
  }
}

/// Email Campaign Model
class EmailCampaign {
  final int? id;
  final String subject;
  final String body;
  final String templateType; // 'enrollment_success', 'payment_confirmation', etc.
  final List<String> recipientEmails;
  final List<int>? userIds;
  final String status; // 'draft', 'sending', 'sent', 'failed'
  final int successCount;
  final int failureCount;
  final DateTime? createdAt;
  final DateTime? sentAt;
  final Map<String, dynamic>? metadata;

  const EmailCampaign({
    this.id,
    required this.subject,
    required this.body,
    required this.templateType,
    required this.recipientEmails,
    this.userIds,
    required this.status,
    this.successCount = 0,
    this.failureCount = 0,
    this.createdAt,
    this.sentAt,
    this.metadata,
  });

  factory EmailCampaign.fromJson(Map<String, dynamic> json) {
    return EmailCampaign(
      id: json['id'],
      subject: json['subject'] ?? '',
      body: json['body'] ?? '',
      templateType: json['template_type'] ?? 'custom',
      recipientEmails: List<String>.from(json['emails'] ?? []),
      userIds: json['user_ids'] != null ? List<int>.from(json['user_ids']) : null,
      status: json['status'] ?? 'draft',
      successCount: json['success_count'] ?? 0,
      failureCount: json['failure_count'] ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'body': body,
        'template_type': templateType,
        'emails': recipientEmails,
        'user_ids': userIds,
        'status': status,
      };
}

/// Message Template for quick selection
class MessageTemplate {
  final String id;
  final String name;
  final String category; // 'sms', 'email', 'whatsapp'
  final String content;
  final List<String> variables; // Placeholders like {{name}}, {{amount}}
  final bool isDefault;

  const MessageTemplate({
    required this.id,
    required this.name,
    required this.category,
    required this.content,
    required this.variables,
    this.isDefault = false,
  });

  factory MessageTemplate.fromJson(Map<String, dynamic> json) {
    return MessageTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'sms',
      content: json['content'] ?? '',
      variables: List<String>.from(json['variables'] ?? []),
      isDefault: json['is_default'] ?? false,
    );
  }
}

/// Communication Log Entry
class CommunicationLog {
  final int id;
  final String type; // 'sms', 'email', 'whatsapp'
  final String recipient;
  final String content;
  final String status;
  final String? messageId;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? sentAt;
  final String campaignId;

  const CommunicationLog({
    required this.id,
    required this.type,
    required this.recipient,
    required this.content,
    required this.status,
    this.messageId,
    this.errorMessage,
    required this.createdAt,
    this.sentAt,
    required this.campaignId,
  });

  factory CommunicationLog.fromJson(Map<String, dynamic> json) {
    return CommunicationLog(
      id: json['id'] ?? 0,
      type: json['type'] ?? 'sms',
      recipient: json['recipient'] ?? json['phone'] ?? json['email'] ?? '',
      content: json['content'] ?? json['message'] ?? '',
      status: json['status'] ?? 'pending',
      messageId: json['message_id'] ?? json['sid'],
      errorMessage: json['error_message'] ?? json['error'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      campaignId: json['campaign_id']?.toString() ?? '',
    );
  }
}

/// Campaign Statistics
class CampaignStatistics {
  final int totalRecipients;
  final int successCount;
  final int failureCount;
  final int skippedCount;
  final double successRate;
  final double failureRate;
  final Duration? estimatedTime;

  const CampaignStatistics({
    required this.totalRecipients,
    required this.successCount,
    required this.failureCount,
    required this.skippedCount,
    this.estimatedTime,
  }) : 
    successRate = totalRecipients > 0 ? (successCount / totalRecipients) * 100 : 0,
    failureRate = totalRecipients > 0 ? (failureCount / totalRecipients) * 100 : 0;

  factory CampaignStatistics.fromJson(Map<String, dynamic> json) {
    final total = json['total'] ?? 0;
    final sent = json['sent'] ?? 0;
    final failed = json['failed'] ?? 0;
    final skipped = json['skipped'] ?? 0;

    return CampaignStatistics(
      totalRecipients: total,
      successCount: sent,
      failureCount: failed,
      skippedCount: skipped,
    );
  }
}
