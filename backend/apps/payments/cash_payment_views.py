# apps/payments/cash_payment_views.py
"""
Cash Payment Instructions View
Provides pathway-specific cash payment instructions for all enrollment types.
"""

from rest_framework import views
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.utils import timezone
from datetime import timedelta


@method_decorator(csrf_exempt, name='dispatch')
class CashPaymentInstructionsView(views.APIView):
    """
    GET /api/payments/cash-payment-instructions/

    Returns detailed cash payment instructions based on enrollment type.
    Each pathway (Masterclass, Learnership, Industry Training, Custom Selection)
    has specific instructions tailored to its enrollment process.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        enrollment_type = request.query_params.get('enrollment_type', 'masterclass')
        program_id = request.query_params.get('program_id')
        program_title = request.query_params.get('program_title', 'the selected programme')

        instructions = self._get_cash_instructions(
            enrollment_type=enrollment_type,
            program_title=program_title
        )

        return Response(instructions)

    def _get_cash_instructions(self, enrollment_type: str, program_title: str) -> dict:
        """
        Get cash payment instructions specific to enrollment pathway.

        Returns comprehensive instructions including:
        - Process overview
        - Step-by-step guide
        - Required documents
        - Payment locations
        - Timeline and deadlines
        - What happens after payment
        """

        base_instructions = {
            'masterclass': self._get_masterclass_cash_instructions(program_title),
            'learnership': self._get_learnership_cash_instructions(program_title),
            'industry_training': self._get_industry_training_cash_instructions(program_title),
            'custom_selection': self._get_custom_selection_cash_instructions(program_title),
            'role_training': self._get_role_training_cash_instructions(program_title),
        }

        return base_instructions.get(enrollment_type, base_instructions['masterclass'])

    def _get_masterclass_cash_instructions(self, program_title: str) -> dict:
        """Cash payment instructions for Masterclass enrollment"""
        return {
            'enrollment_type': 'masterclass',
            'enrollment_type_display': 'Masterclass',
            'icon': 'class',
            'title': 'Cash Payment for Masterclass',
            'subtitle': f'Pay in person for: {program_title}',
            'overview': {
                'heading': 'How Cash Payment Works for Masterclasses',
                'content': 'Reserve your seat now and pay at our office within 14 days. Your spot is held provisionally until payment is received.',
                'key_points': [
                    'Your seat is reserved for 14 days',
                    'Pay at any of our offices nationwide',
                    'Receive instant confirmation upon payment',
                    'Get access to pre-masterclass materials immediately'
                ]
            },
            'steps': [
                {
                    'step': 1,
                    'title': 'Receive Payment Reference',
                    'description': 'You will receive a unique payment reference code (e.g., HOSI-MCLASS-20260308-001) via email and SMS.',
                    'icon': 'qr_code',
                    'details': 'This reference is valid for 14 days from today.'
                },
                {
                    'step': 2,
                    'title': 'Visit Our Office',
                    'description': 'Visit any of our payment offices with your reference code and ID/passport.',
                    'icon': 'location_on',
                    'details': 'Offices open Monday-Friday, 8:00 AM - 5:00 PM. No appointment needed.'
                },
                {
                    'step': 3,
                    'title': 'Make Payment',
                    'description': 'Pay the full amount at our office via cash, card, or mobile money.',
                    'icon': 'payments',
                    'details': 'We accept M-Pesa, EcoCash, Airtel Money, MTN Mobile Money, and all major cards.'
                },
                {
                    'step': 4,
                    'title': 'Receive Confirmation',
                    'description': 'Get instant confirmation and receipt. Your masterclass enrollment is now confirmed.',
                    'icon': 'check_circle',
                    'details': 'You will receive login credentials for pre-masterclass materials within 24 hours.'
                }
            ],
            'required_documents': [
                'Payment reference code (from email/SMS)',
                'Valid ID or Passport',
                'Proof of email address (optional)'
            ],
            'payment_locations': {
                'heading': 'Where to Pay',
                'content': 'We have payment offices in major cities across Kenya, Zimbabwe, Zambia, and Botswana.',
                'locations': [
                    {'country': 'South Africa', 'cities': ['Johannesburg']},
                    {'country': 'Kenya', 'cities': ['Nairobi']},
                    {'country': 'Zimbabwe', 'cities': ['Harare']},
                    {'country': 'Zambia', 'cities': ['Lusaka']}
                ]
            },
            'timeline': {
                'reservation_period': '14 days',
                'payment_deadline': 'Within 14 days of enrollment OR 3 days before masterclass start date (whichever is earlier)',
                'confirmation': 'Instant upon payment',
                'access_granted': 'Within 24 hours of payment'
            },
            'important_notes': [
                'Your provisional enrollment will expire after 14 days if payment is not received',
                'If the masterclass starts within 14 days, payment must be made at least 3 days before the start date',
                'Seats are limited and allocated on a first-come, first-served basis',
                'Full refund available if cancelled 7 days before the masterclass starts'
            ],
            'benefits': [
                'No transaction fees or payment gateway charges',
                'Immediate assistance from our support team',
                'Get all your questions answered in person',
                'Receive physical receipt for your records'
            ],
            'contact_support': {
                'phone': '+254 700 000 000',
                'email': 'payments@hosi.academy',
                'hours': 'Monday-Friday, 8:00 AM - 5:00 PM'
            }
        }

    def _get_learnership_cash_instructions(self, program_title: str) -> dict:
        """Cash payment instructions for Learnership enrollment"""
        return {
            'enrollment_type': 'learnership',
            'enrollment_type_display': 'Learnership Programme',
            'icon': 'school',
            'title': 'Cash Payment for Learnership',
            'subtitle': f'Pay in person for: {program_title}',
            'overview': {
                'heading': 'How Cash Payment Works for Learnerships',
                'content': 'Learnerships require additional documentation and verification. Reserve your spot and complete payment at our office with all required documents.',
                'key_points': [
                    'Your spot is reserved for 7 days (prerequisites verification)',
                    'Bring all required documents when paying',
                    'SETA compliance documentation handled at office',
                    'Payment plans (debit orders) can be set up in person'
                ]
            },
            'steps': [
                {
                    'step': 1,
                    'title': 'Prepare Required Documents',
                    'description': 'Gather all required documents before visiting our office.',
                    'icon': 'description',
                    'details': 'See "Required Documents" section below for complete list.'
                },
                {
                    'step': 2,
                    'title': 'Receive Payment Reference',
                    'description': 'You will receive a unique payment reference code via email and SMS.',
                    'icon': 'qr_code',
                    'details': 'This reference is valid for 7 days while we verify your prerequisites.'
                },
                {
                    'step': 3,
                    'title': 'Visit Our Office',
                    'description': 'Visit our office with all documents for verification and payment.',
                    'icon': 'location_on',
                    'details': 'Our team will verify your documents and process your enrollment on the spot.'
                },
                {
                    'step': 4,
                    'title': 'Document Verification',
                    'description': 'Submit your documents for prerequisites verification.',
                    'icon': 'fact_check',
                    'details': 'Our team will review your qualifications and ID. This takes 15-30 minutes.'
                },
                {
                    'step': 5,
                    'title': 'Complete Payment & SETA Forms',
                    'description': 'Make payment and sign SETA compliance documentation.',
                    'icon': 'payments',
                    'details': 'We accept cash, card, or mobile money. Debit order setup available.'
                },
                {
                    'step': 6,
                    'title': 'Enrollment Confirmed',
                    'description': 'Receive confirmation and enrollment pack with programme details.',
                    'icon': 'check_circle',
                    'details': 'You will receive login credentials and programme schedule within 48 hours.'
                }
            ],
            'required_documents': [
                'Payment reference code (from email/SMS)',
                'Valid ID or Passport (original + copy)',
                'Highest qualification certificate (original + copy)',
                'Proof of residence (utility bill, not older than 3 months)',
                'Updated CV/Resume',
                'Motivational letter (why you want to join this learnership)',
                'Proof of employment status (if employed: letter from employer)',
                'Bank account details (for debit order if choosing installment plan)'
            ],
            'payment_locations': {
                'heading': 'Where to Pay',
                'content': 'Learnership payments are processed at our main regional offices with SETA accreditation support.',
                'locations': [
                    {'country': 'South Africa', 'cities': ['Johannesburg (Head Office)'], 'note': 'SETA liaison office'},
                    {'country': 'Kenya', 'cities': ['Nairobi (Regional Office)'], 'note': 'Full documentation support'},
                    {'country': 'Zimbabwe', 'cities': ['Harare (Main Office)'], 'note': 'Complete enrollment services'},
                    {'country': 'Zambia', 'cities': ['Lusaka (Regional Office)'], 'note': 'Complete enrollment services'}
                ]
            },
            'timeline': {
                'reservation_period': '7 days (prerequisites verification)',
                'payment_deadline': 'Within 7 days of enrollment OR 3 days before programme start date',
                'verification_time': '15-30 minutes at office',
                'confirmation': 'Same day upon successful verification and payment',
                'access_granted': 'Within 48 hours of enrollment confirmation'
            },
            'important_notes': [
                'All documents must be certified copies (we can certify at office for small fee)',
                'Your provisional enrollment expires after 7 days if documents not submitted',
                'SETA funding applications can be initiated at the office',
                'Payment plans available: 50% deposit + monthly debit orders',
                'Corporate enrollments require company registration documents and purchase order'
            ],
            'seta_compliance': {
                'heading': 'SETA Compliance',
                'content': 'As part of learnership enrollment, we collect demographic and employment data for SETA reporting. This includes:',
                'requirements': [
                    'Race/ethnicity (for employment equity reporting)',
                    'Disability status (optional, for support planning)',
                    'Employment status and income level',
                    'Nationality and residence proof'
                ],
                'note': 'All information is kept confidential and used only for accreditation reporting.'
            },
            'benefits': [
                'Complete enrollment support in one visit',
                'Document certification available on-site',
                'SETA forms completed with assistance',
                'Payment plan setup (debit orders) available',
                'Immediate answers to all programme questions',
                'Physical enrollment pack with programme materials'
            ],
            'contact_support': {
                'phone': '+254 700 000 000',
                'email': 'learnerships@hosi.academy',
                'hours': 'Monday-Friday, 8:00 AM - 5:00 PM'
            }
        }

    def _get_industry_training_cash_instructions(self, program_title: str) -> dict:
        """Cash payment instructions for Industry-Based Training enrollment"""
        return {
            'enrollment_type': 'industry_training',
            'enrollment_type_display': 'Industry-Based Training',
            'icon': 'engineering',
            'title': 'Cash Payment for Industry Training',
            'subtitle': f'Pay in person for: {program_title}',
            'overview': {
                'heading': 'How Cash Payment Works for Industry Training',
                'content': 'Industry-based training enrollments can be paid in person at our offices. Corporate enrollments have additional billing options.',
                'key_points': [
                    'Your enrollment is reserved for 14 days',
                    'Individual and corporate payments accepted',
                    'AICERTS certification included',
                    'Flexible payment plans available'
                ]
            },
            'steps': [
                {
                    'step': 1,
                    'title': 'Receive Payment Reference',
                    'description': 'You will receive a unique payment reference code via email and SMS.',
                    'icon': 'qr_code',
                    'details': 'Reference valid for 14 days from enrollment date.'
                },
                {
                    'step': 2,
                    'title': 'Visit Payment Office',
                    'description': 'Visit any of our payment offices with your reference and ID.',
                    'icon': 'location_on',
                    'details': 'All major cities in Kenya, Zimbabwe, Zambia, and Botswana.'
                },
                {
                    'step': 3,
                    'title': 'Complete Payment',
                    'description': 'Pay via cash, card, or mobile money at our office.',
                    'icon': 'payments',
                    'details': 'Corporate payments can be made via bank transfer or company cheque.'
                },
                {
                    'step': 4,
                    'title': 'AICERTS Enrollment',
                    'description': 'Your AICERTS account is activated upon payment confirmation.',
                    'icon': 'check_circle',
                    'details': 'Access granted to industry training platform within 24 hours.'
                }
            ],
            'required_documents': [
                'Payment reference code',
                'Valid ID or Passport',
                'For corporate: Company purchase order or authorization letter',
                'For corporate: Company registration documents (first time only)'
            ],
            'payment_locations': {
                'heading': 'Where to Pay',
                'content': 'Industry training payments accepted at all our offices and partner locations.',
                'locations': [
                    {'country': 'South Africa', 'cities': ['Johannesburg']},
                    {'country': 'Kenya', 'cities': ['Nairobi']},
                    {'country': 'Zimbabwe', 'cities': ['Harare']},
                    {'country': 'Zambia', 'cities': ['Lusaka']}
                ]
            },
            'timeline': {
                'reservation_period': '14 days',
                'payment_deadline': 'Within 14 days OR 3 days before training start',
                'confirmation': 'Instant upon payment',
                'access_granted': 'Within 24 hours'
            },
            'important_notes': [
                'AICERTS certification is included in the training fee',
                'Corporate enrollments can request invoice billing',
                'Group discounts available for 5+ employees from same company',
                'Training materials provided digitally and physically'
            ],
            'corporate_options': {
                'heading': 'Corporate Payment Options',
                'content': 'For company enrollments, we offer flexible payment arrangements:',
                'options': [
                    'Invoice billing (30-day terms for registered companies)',
                    'Purchase order acceptance',
                    'Direct bank transfer',
                    'Company cheque',
                    'Bulk enrollment discounts (5+ employees)'
                ]
            },
            'benefits': [
                'No online payment fees',
                'Corporate invoicing available',
                'Group discount processing',
                'Physical receipts for accounting',
                'Dedicated corporate support'
            ],
            'contact_support': {
                'phone': '+254 700 000 000',
                'email': 'industry@hosi.academy',
                'hours': 'Monday-Friday, 8:00 AM - 5:00 PM'
            }
        }

    def _get_custom_selection_cash_instructions(self, program_title: str) -> dict:
        """Cash payment instructions for Custom Course Selection enrollment"""
        return {
            'enrollment_type': 'custom_selection',
            'enrollment_type_display': 'Custom Course Selection',
            'icon': 'auto_stories',
            'title': 'Cash Payment for Custom Courses',
            'subtitle': f'Pay in person for: {program_title}',
            'overview': {
                'heading': 'How Cash Payment Works for Custom Course Selection',
                'content': 'Enroll in your selected courses and pay at our office. Perfect for learners who prefer in-person transactions.',
                'key_points': [
                    'Your course bundle is reserved for 14 days',
                    'Pay for multiple courses in one transaction',
                    'All courses from selected bundle activated together',
                    'Self-paced learning with 12-month access'
                ]
            },
            'steps': [
                {
                    'step': 1,
                    'title': 'Receive Payment Reference',
                    'description': 'You will receive a unique payment reference code for your course bundle.',
                    'icon': 'qr_code',
                    'details': 'Reference includes all selected courses in your bundle.'
                },
                {
                    'step': 2,
                    'title': 'Visit Our Office',
                    'description': 'Visit any payment office with your reference code and ID.',
                    'icon': 'location_on',
                    'details': 'All offices accept course bundle payments.'
                },
                {
                    'step': 3,
                    'title': 'Make Payment',
                    'description': 'Pay the total bundle amount via cash, card, or mobile money.',
                    'icon': 'payments',
                    'details': 'Bundle pricing ensures you save compared to individual courses.'
                },
                {
                    'step': 4,
                    'title': 'Access Granted',
                    'description': 'All courses in your bundle are activated immediately.',
                    'icon': 'check_circle',
                    'details': 'Login credentials sent within 24 hours.'
                }
            ],
            'required_documents': [
                'Payment reference code',
                'Valid ID or Passport'
            ],
            'payment_locations': {
                'heading': 'Where to Pay',
                'content': 'Custom course payments accepted at all our offices nationwide.',
                'locations': [
                    {'country': 'South Africa', 'cities': ['Johannesburg']},
                    {'country': 'Kenya', 'cities': ['Nairobi']},
                    {'country': 'Zimbabwe', 'cities': ['Harare']},
                    {'country': 'Zambia', 'cities': ['Lusaka']}
                ]
            },
            'timeline': {
                'reservation_period': '14 days',
                'payment_deadline': 'Within 14 days of enrollment',
                'confirmation': 'Instant upon payment',
                'access_granted': 'Within 24 hours',
                'course_access': '12 months from activation date'
            },
            'important_notes': [
                'Course bundle cannot be split - all courses activated together',
                '12-month access period starts from payment confirmation',
                'Certificate issued for each course upon completion',
                'Self-paced learning - start anytime within 14 days'
            ],
            'benefits': [
                'Save with bundle pricing',
                'No online transaction fees',
                'All courses in one payment',
                'Flexible 12-month access',
                'Individual certificates per course'
            ],
            'contact_support': {
                'phone': '+254 700 000 000',
                'email': 'courses@hosi.academy',
                'hours': 'Monday-Friday, 8:00 AM - 5:00 PM'
            }
        }

    def _get_role_training_cash_instructions(self, program_title: str) -> dict:
        """Cash payment instructions for Role-Based Training enrollment"""
        return {
            'enrollment_type': 'role_training',
            'enrollment_type_display': 'Role-Based Training',
            'icon': 'work',
            'title': 'Cash Payment for Role-Based Training',
            'subtitle': f'Pay in person for: {program_title}',
            'overview': {
                'heading': 'How Cash Payment Works for Role-Based Training',
                'content': 'Role-based training prepares you for specific job roles. Pay at our office and start your career-focused learning journey.',
                'key_points': [
                    'Your role training seat is reserved for 14 days',
                    'Industry-recognized certification included',
                    'Career support services included',
                    'Flexible payment options available'
                ]
            },
            'steps': [
                {
                    'step': 1,
                    'title': 'Receive Payment Reference',
                    'description': 'You will receive a unique payment reference code via email and SMS.',
                    'icon': 'qr_code',
                    'details': 'Reference valid for 14 days.'
                },
                {
                    'step': 2,
                    'title': 'Visit Our Office',
                    'description': 'Visit any payment office with your reference and ID.',
                    'icon': 'location_on',
                    'details': 'Career counselors available at main offices.'
                },
                {
                    'step': 3,
                    'title': 'Complete Payment',
                    'description': 'Pay via cash, card, or mobile money.',
                    'icon': 'payments',
                    'details': 'Payment plans available for selected role trainings.'
                },
                {
                    'step': 4,
                    'title': 'Career Consultation',
                    'description': 'Optional career consultation to discuss your learning path.',
                    'icon': 'career',
                    'details': 'Available at main offices - book when you pay.'
                },
                {
                    'step': 5,
                    'title': 'Training Activated',
                    'description': 'Your role-based training is activated with career support.',
                    'icon': 'check_circle',
                    'details': 'Access granted within 24 hours.'
                }
            ],
            'required_documents': [
                'Payment reference code',
                'Valid ID or Passport',
                'CV/Resume (for career consultation, optional)'
            ],
            'payment_locations': {
                'heading': 'Where to Pay',
                'content': 'Role training payments accepted at all offices. Career consultation available at main offices.',
                'locations': [
                    {'country': 'South Africa', 'cities': ['Johannesburg (Career Center)']},
                    {'country': 'Kenya', 'cities': ['Nairobi (Career Center)']},
                    {'country': 'Zimbabwe', 'cities': ['Harare (Career Center)']},
                    {'country': 'Zambia', 'cities': ['Lusaka (Career Center)']}
                ]
            },
            'timeline': {
                'reservation_period': '14 days',
                'payment_deadline': 'Within 14 days OR 3 days before cohort start',
                'confirmation': 'Instant upon payment',
                'access_granted': 'Within 24 hours',
                'career_consultation': 'Schedule within 7 days of payment'
            },
            'important_notes': [
                'Role-based training includes industry certification',
                'Career support services included for 6 months',
                'Some role trainings have scheduled cohorts - check start dates',
                'Payment plans available for trainings over $500'
            ],
            'career_support': {
                'heading': 'Career Support Included',
                'content': 'Your role training enrollment includes:',
                'services': [
                    'CV review and optimization',
                    'LinkedIn profile optimization guide',
                    'Interview preparation resources',
                    'Job placement assistance',
                    '6 months career coaching access'
                ]
            },
            'benefits': [
                'Industry-recognized certification',
                'Career support services included',
                'Payment plans available',
                'Job placement assistance',
                'No online payment fees'
            ],
            'contact_support': {
                'phone': '+254 700 000 000',
                'email': 'careers@hosi.academy',
                'hours': 'Monday-Friday, 8:00 AM - 5:00 PM'
            }
        }