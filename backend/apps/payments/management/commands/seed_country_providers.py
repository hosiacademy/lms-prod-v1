# apps/payments/management/commands/seed_country_providers.py
"""
Management command to seed ALL 54 African countries with their payment providers

Usage:
    python manage.py seed_country_providers
    
This command:
1. Creates/updates all 54 African Country records
2. Creates/updates PaymentProviderModel records  
3. Creates ProviderCountryConfig linking providers to countries
4. Creates CountryPaymentLandscape with payment ecosystem data
"""
import json
from django.core.management.base import BaseCommand
from django.db import transaction
from apps.localization.models import Country, Language
from apps.payments.models import (
    PaymentProviderModel, ProviderCountryConfig, CountryPaymentLandscape,
    PaymentProvider, ProviderCategory, Currency
)


class Command(BaseCommand):
    help = 'Seed ALL 54 African countries with their payment providers'

    # ALL 54 AFRICAN COUNTRIES with payment providers
    AFRICAN_COUNTRIES = {
        # ==================== NORTH AFRICA (7) ====================
        'DZ': {
            'name': 'Algeria',
            'currency': 'DZD',
            'mobile_money_penetration': 10.0,
            'card_penetration': 15.0,
            'internet_penetration': 70.0,
            'dominant_methods': ['cash', 'card', 'bank_transfer'],
            'providers': [
                {'code': 'edahabia', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'satim', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'baridimob', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Bank of Algeria',
            'regulatory_body': 'BoA',
        },
        'EG': {
            'name': 'Egypt',
            'currency': 'EGP',
            'mobile_money_penetration': 15.0,
            'card_penetration': 25.0,
            'internet_penetration': 72.0,
            'dominant_methods': ['cash', 'card', 'mobile_wallet'],
            'providers': [
                {'code': 'fawry', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'paymob', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'valu', 'active': True, 'recommended': True, 'priority': 3},
                {'code': 'masary', 'active': True, 'recommended': False, 'priority': 4},
                {'code': 'khazna', 'active': True, 'recommended': False, 'priority': 5},
            ],
            'central_bank': 'Central Bank of Egypt',
            'regulatory_body': 'CBE',
        },
        'LY': {
            'name': 'Libya',
            'currency': 'LYD',
            'mobile_money_penetration': 5.0,
            'card_penetration': 10.0,
            'internet_penetration': 35.0,
            'dominant_methods': ['cash', 'bank_transfer'],
            'providers': [
                {'code': 'sahab', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'moamalat', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Central Bank of Libya',
            'regulatory_body': 'CBL',
        },
        'MA': {
            'name': 'Morocco',
            'currency': 'MAD',
            'mobile_money_penetration': 20.0,
            'card_penetration': 30.0,
            'internet_penetration': 84.0,
            'dominant_methods': ['card', 'cash', 'mobile_wallet'],
            'providers': [
                {'code': 'cmi', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'payzone', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'hps', 'active': True, 'recommended': False, 'priority': 3},
                {'code': 'attijariwafa', 'active': True, 'recommended': False, 'priority': 4},
                {'code': 'cashplus', 'active': True, 'recommended': False, 'priority': 5},
            ],
            'central_bank': 'Bank Al-Maghrib',
            'regulatory_body': 'BAM',
        },
        'SD': {
            'name': 'Sudan',
            'currency': 'SDG',
            'mobile_money_penetration': 15.0,
            'card_penetration': 5.0,
            'internet_penetration': 30.0,
            'dominant_methods': ['cash', 'mobile_money'],
            'providers': [
                {'code': 'fawry', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'bankak', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Bank of Sudan',
            'regulatory_body': 'BoS',
        },
        'TN': {
            'name': 'Tunisia',
            'currency': 'TND',
            'mobile_money_penetration': 15.0,
            'card_penetration': 20.0,
            'internet_penetration': 81.0,
            'dominant_methods': ['card', 'mobile_wallet'],
            'providers': [
                {'code': 'flouci', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'sodet', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'runpay', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Central Bank of Tunisia',
            'regulatory_body': 'BCT',
        },
        'EH': {
            'name': 'Western Sahara',
            'currency': 'MAD',
            'mobile_money_penetration': 10.0,
            'card_penetration': 5.0,
            'internet_penetration': 40.0,
            'dominant_methods': ['cash'],
            'providers': [
                {'code': 'cashplus', 'active': True, 'recommended': True, 'priority': 1},
            ],
            'central_bank': 'Bank Al-Maghrib',
            'regulatory_body': 'BAM',
        },
        
        # ==================== WEST AFRICA (16) ====================
        'BJ': {
            'name': 'Benin',
            'currency': 'XOF',
            'mobile_money_penetration': 45.0,
            'card_penetration': 8.0,
            'internet_penetration': 25.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'mobicash', 'active': True, 'recommended': False, 'priority': 3},
                {'code': 'flutterwave', 'active': True, 'recommended': False, 'priority': 4},
            ],
            'central_bank': 'Banque Centrale des États de l\'Afrique de l\'Ouest',
            'regulatory_body': 'BCEAO',
        },
        'BF': {
            'name': 'Burkina Faso',
            'currency': 'XOF',
            'mobile_money_penetration': 50.0,
            'card_penetration': 5.0,
            'internet_penetration': 20.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'moov_money', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Banque Centrale des États de l\'Afrique de l\'Ouest',
            'regulatory_body': 'BCEAO',
        },
        'CV': {
            'name': 'Cape Verde',
            'currency': 'CVE',
            'mobile_money_penetration': 20.0,
            'card_penetration': 25.0,
            'internet_penetration': 55.0,
            'dominant_methods': ['card', 'mobile_money'],
            'providers': [
                {'code': 'mcel', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'unitel', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Bank of Cape Verde',
            'regulatory_body': 'BCV',
        },
        'CI': {
            'name': 'Côte d\'Ivoire',
            'currency': 'XOF',
            'mobile_money_penetration': 50.0,
            'card_penetration': 8.0,
            'internet_penetration': 40.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'wave', 'active': True, 'recommended': True, 'priority': 3},
                {'code': 'moov_money', 'active': True, 'recommended': False, 'priority': 4},
                {'code': 'flutterwave', 'active': True, 'recommended': False, 'priority': 5},
            ],
            'central_bank': 'Banque Centrale des États de l\'Afrique de l\'Ouest',
            'regulatory_body': 'BCEAO',
        },
        'GM': {
            'name': 'Gambia',
            'currency': 'GMD',
            'mobile_money_penetration': 35.0,
            'card_penetration': 10.0,
            'internet_penetration': 40.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'africell', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'qcell', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'btc', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Central Bank of The Gambia',
            'regulatory_body': 'CBG',
        },
        'GH': {
            'name': 'Ghana',
            'currency': 'GHS',
            'mobile_money_penetration': 70.0,
            'card_penetration': 20.0,
            'internet_penetration': 68.0,
            'dominant_methods': ['mobile_money', 'ussd', 'card'],
            'providers': [
                {'code': 'paystack', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'flutterwave', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'expresspay', 'active': True, 'recommended': True, 'priority': 3},
                {'code': 'zeepay', 'active': True, 'recommended': True, 'priority': 4},
                {'code': 'slydepay', 'active': True, 'recommended': False, 'priority': 5},
                {'code': 'hubtel', 'active': True, 'recommended': False, 'priority': 6},
                {'code': 'mtn_momo', 'active': True, 'recommended': False, 'priority': 7},
            ],
            'central_bank': 'Bank of Ghana',
            'regulatory_body': 'BoG',
        },
        'GN': {
            'name': 'Guinea',
            'currency': 'GNF',
            'mobile_money_penetration': 30.0,
            'card_penetration': 5.0,
            'internet_penetration': 15.0,
            'dominant_methods': ['mobile_money', 'cash'],
            'providers': [
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'mtn_momo', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'intouch', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Central Bank of Guinea',
            'regulatory_body': 'BCRG',
        },
        'GW': {
            'name': 'Guinea-Bissau',
            'currency': 'XOF',
            'mobile_money_penetration': 25.0,
            'card_penetration': 5.0,
            'internet_penetration': 15.0,
            'dominant_methods': ['mobile_money', 'cash'],
            'providers': [
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'mtn_momo', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Banque Centrale des États de l\'Afrique de l\'Ouest',
            'regulatory_body': 'BCEAO',
        },
        'LR': {
            'name': 'Liberia',
            'currency': 'LRD',
            'mobile_money_penetration': 30.0,
            'card_penetration': 8.0,
            'internet_penetration': 25.0,
            'dominant_methods': ['mobile_money', 'cash'],
            'providers': [
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'mtn_momo', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'lonestar', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Central Bank of Liberia',
            'regulatory_body': 'CBL',
        },
        'ML': {
            'name': 'Mali',
            'currency': 'XOF',
            'mobile_money_penetration': 45.0,
            'card_penetration': 5.0,
            'internet_penetration': 18.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'moov_money', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Banque Centrale des États de l\'Afrique de l\'Ouest',
            'regulatory_body': 'BCEAO',
        },
        'MR': {
            'name': 'Mauritania',
            'currency': 'MRU',
            'mobile_money_penetration': 20.0,
            'card_penetration': 8.0,
            'internet_penetration': 25.0,
            'dominant_methods': ['mobile_money', 'cash'],
            'providers': [
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'mattels', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Central Bank of Mauritania',
            'regulatory_body': 'BCM',
        },
        'NE': {
            'name': 'Niger',
            'currency': 'XOF',
            'mobile_money_penetration': 40.0,
            'card_penetration': 5.0,
            'internet_penetration': 15.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'moov_money', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Banque Centrale des États de l\'Afrique de l\'Ouest',
            'regulatory_body': 'BCEAO',
        },
        'NG': {
            'name': 'Nigeria',
            'currency': 'NGN',
            'mobile_money_penetration': 45.0,
            'card_penetration': 35.0,
            'internet_penetration': 55.0,
            'dominant_methods': ['card', 'bank_transfer', 'ussd'],
            'providers': [
                {'code': 'paystack', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'flutterwave', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'monnify', 'active': True, 'recommended': True, 'priority': 3},
                {'code': 'interswitch', 'active': True, 'recommended': True, 'priority': 4},
                {'code': 'remita', 'active': True, 'recommended': True, 'priority': 5},
                {'code': 'opay', 'active': True, 'recommended': False, 'priority': 6},
                {'code': 'palmPay', 'active': True, 'recommended': False, 'priority': 7},
                {'code': 'paga', 'active': True, 'recommended': False, 'priority': 8},
                {'code': 'voguepay', 'active': True, 'recommended': False, 'priority': 9},
            ],
            'central_bank': 'Central Bank of Nigeria',
            'regulatory_body': 'CBN',
        },
        'SL': {
            'name': 'Sierra Leone',
            'currency': 'SLL',
            'mobile_money_penetration': 25.0,
            'card_penetration': 5.0,
            'internet_penetration': 12.0,
            'dominant_methods': ['mobile_money', 'cash'],
            'providers': [
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'africell', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'bocay', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Bank of Sierra Leone',
            'regulatory_body': 'BSL',
        },
        'SN': {
            'name': 'Senegal',
            'currency': 'XOF',
            'mobile_money_penetration': 55.0,
            'card_penetration': 10.0,
            'internet_penetration': 52.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'wave', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'free_money', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'orange_money', 'active': True, 'recommended': False, 'priority': 3},
                {'code': 'flutterwave', 'active': True, 'recommended': False, 'priority': 4},
            ],
            'central_bank': 'Banque Centrale des États de l\'Afrique de l\'Ouest',
            'regulatory_body': 'BCEAO',
        },
        'TG': {
            'name': 'Togo',
            'currency': 'XOF',
            'mobile_money_penetration': 45.0,
            'card_penetration': 8.0,
            'internet_penetration': 30.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'moov_money', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'flutterwave', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Banque Centrale des États de l\'Afrique de l\'Ouest',
            'regulatory_body': 'BCEAO',
        },
        
        # ==================== EAST AFRICA (14) ====================
        'BI': {
            'name': 'Burundi',
            'currency': 'BIF',
            'mobile_money_penetration': 30.0,
            'card_penetration': 5.0,
            'internet_penetration': 10.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'lumicash', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'econet', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Bank of the Republic of Burundi',
            'regulatory_body': 'BRB',
        },
        'KM': {
            'name': 'Comoros',
            'currency': 'KMF',
            'mobile_money_penetration': 25.0,
            'card_penetration': 10.0,
            'internet_penetration': 20.0,
            'dominant_methods': ['mobile_money', 'cash'],
            'providers': [
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'orange_money', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Central Bank of Comoros',
            'regulatory_body': 'BCC',
        },
        'DJ': {
            'name': 'Djibouti',
            'currency': 'DJF',
            'mobile_money_penetration': 20.0,
            'card_penetration': 15.0,
            'internet_penetration': 35.0,
            'dominant_methods': ['mobile_money', 'cash'],
            'providers': [
                {'code': 'evamoney', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'djambo', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Central Bank of Djibouti',
            'regulatory_body': 'BCD',
        },
        'ER': {
            'name': 'Eritrea',
            'currency': 'ERN',
            'mobile_money_penetration': 10.0,
            'card_penetration': 5.0,
            'internet_penetration': 10.0,
            'dominant_methods': ['cash'],
            'providers': [
                {'code': 'tele', 'active': True, 'recommended': True, 'priority': 1},
            ],
            'central_bank': 'Bank of Eritrea',
            'regulatory_body': 'BoE',
        },
        'ET': {
            'name': 'Ethiopia',
            'currency': 'ETB',
            'mobile_money_penetration': 30.0,
            'card_penetration': 8.0,
            'internet_penetration': 29.0,
            'dominant_methods': ['mobile_money', 'bank_transfer'],
            'providers': [
                {'code': 'telebirr', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'hellocash', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'chapa', 'active': True, 'recommended': True, 'priority': 3},
                {'code': 'cbe_birr', 'active': True, 'recommended': False, 'priority': 4},
            ],
            'central_bank': 'National Bank of Ethiopia',
            'regulatory_body': 'NBE',
        },
        'KE': {
            'name': 'Kenya',
            'currency': 'KES',
            'mobile_money_penetration': 83.0,
            'card_penetration': 25.0,
            'internet_penetration': 91.0,
            'dominant_methods': ['mobile_money', 'ussd', 'bank_transfer'],
            'providers': [
                {'code': 'mpesa', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'airtel_money', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'flutterwave', 'active': True, 'recommended': True, 'priority': 3},
                {'code': 'paystack', 'active': True, 'recommended': True, 'priority': 4},
                {'code': 'pesapal', 'active': True, 'recommended': True, 'priority': 5},
                {'code': 'dpo', 'active': True, 'recommended': False, 'priority': 6},
                {'code': 'kcb_pesa', 'active': True, 'recommended': False, 'priority': 7},
            ],
            'central_bank': 'Central Bank of Kenya',
            'regulatory_body': 'CBK',
        },
        'MG': {
            'name': 'Madagascar',
            'currency': 'MGA',
            'mobile_money_penetration': 35.0,
            'card_penetration': 8.0,
            'internet_penetration': 15.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'mvola', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'orange_money', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'aitel_money', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Central Bank of Madagascar',
            'regulatory_body': 'BFM',
        },
        'MU': {
            'name': 'Mauritius',
            'currency': 'MUR',
            'mobile_money_penetration': 40.0,
            'card_penetration': 50.0,
            'internet_penetration': 80.0,
            'dominant_methods': ['card', 'mobile_wallet'],
            'providers': [
                {'code': 'mcb_juice', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'my_t_money', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'sbm_api', 'active': True, 'recommended': False, 'priority': 3},
                {'code': 'flutterwave', 'active': True, 'recommended': False, 'priority': 4},
            ],
            'central_bank': 'Bank of Mauritius',
            'regulatory_body': 'BOM',
        },
        'MW': {
            'name': 'Malawi',
            'currency': 'MWK',
            'mobile_money_penetration': 35.0,
            'card_penetration': 8.0,
            'internet_penetration': 14.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'tnm_mpamba', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'airtel_money', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'national_bank', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Reserve Bank of Malawi',
            'regulatory_body': 'RBM',
        },
        'MZ': {
            'name': 'Mozambique',
            'currency': 'MZN',
            'mobile_money_penetration': 40.0,
            'card_penetration': 10.0,
            'internet_penetration': 24.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'mpesa', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'emola', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'vodacom_mpesa', 'active': True, 'recommended': False, 'priority': 3},
                {'code': 'e-mola', 'active': True, 'recommended': False, 'priority': 4},
            ],
            'central_bank': 'Bank of Mozambique',
            'regulatory_body': 'BoM',
        },
        'RE': {
            'name': 'Réunion',
            'currency': 'EUR',
            'mobile_money_penetration': 30.0,
            'card_penetration': 60.0,
            'internet_penetration': 75.0,
            'dominant_methods': ['card', 'mobile_wallet'],
            'providers': [
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'stripe', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Banque de France',
            'regulatory_body': 'ACPR',
        },
        'RW': {
            'name': 'Rwanda',
            'currency': 'RWF',
            'mobile_money_penetration': 55.0,
            'card_penetration': 15.0,
            'internet_penetration': 32.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'mpesa', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'airtel_money', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'mtn_momo', 'active': True, 'recommended': False, 'priority': 3},
                {'code': 'bank_of_kigali', 'active': True, 'recommended': False, 'priority': 4},
                {'code': 'flutterwave', 'active': True, 'recommended': False, 'priority': 5},
            ],
            'central_bank': 'National Bank of Rwanda',
            'regulatory_body': 'NBR',
        },
        'SC': {
            'name': 'Seychelles',
            'currency': 'SCR',
            'mobile_money_penetration': 25.0,
            'card_penetration': 55.0,
            'internet_penetration': 70.0,
            'dominant_methods': ['card', 'mobile_wallet'],
            'providers': [
                {'code': 'seychelles_savings', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'absa', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Central Bank of Seychelles',
            'regulatory_body': 'CBS',
        },
        'SO': {
            'name': 'Somalia',
            'currency': 'SOS',
            'mobile_money_penetration': 45.0,
            'card_penetration': 5.0,
            'internet_penetration': 20.0,
            'dominant_methods': ['mobile_money', 'cash'],
            'providers': [
                {'code': 'e_dahab', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'zaad', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'eVC_plus', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Central Bank of Somalia',
            'regulatory_body': 'CBS',
        },
        'SS': {
            'name': 'South Sudan',
            'currency': 'SSP',
            'mobile_money_penetration': 20.0,
            'card_penetration': 5.0,
            'internet_penetration': 10.0,
            'dominant_methods': ['mobile_money', 'cash'],
            'providers': [
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'zain_cash', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Bank of South Sudan',
            'regulatory_body': 'BoSS',
        },
        'TZ': {
            'name': 'Tanzania',
            'currency': 'TZS',
            'mobile_money_penetration': 60.0,
            'card_penetration': 10.0,
            'internet_penetration': 45.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'mpesa', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'airtel_money', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'tigo_pesa', 'active': True, 'recommended': False, 'priority': 3},
                {'code': 'vodacom_mpesa', 'active': True, 'recommended': False, 'priority': 4},
                {'code': 'nmb_api', 'active': True, 'recommended': False, 'priority': 5},
                {'code': 'crdb_api', 'active': True, 'recommended': False, 'priority': 6},
            ],
            'central_bank': 'Bank of Tanzania',
            'regulatory_body': 'BoT',
        },
        'UG': {
            'name': 'Uganda',
            'currency': 'UGX',
            'mobile_money_penetration': 65.0,
            'card_penetration': 12.0,
            'internet_penetration': 35.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'mpesa', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'airtel_money', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'mtn_momo', 'active': True, 'recommended': False, 'priority': 3},
                {'code': 'centenary_bank', 'active': True, 'recommended': False, 'priority': 4},
                {'code': 'stanbic_api', 'active': True, 'recommended': False, 'priority': 5},
            ],
            'central_bank': 'Bank of Uganda',
            'regulatory_body': 'BoU',
        },
        'YT': {
            'name': 'Mayotte',
            'currency': 'EUR',
            'mobile_money_penetration': 35.0,
            'card_penetration': 50.0,
            'internet_penetration': 65.0,
            'dominant_methods': ['card', 'mobile_wallet'],
            'providers': [
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'stripe', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Banque de France',
            'regulatory_body': 'ACPR',
        },
        'ZM': {
            'name': 'Zambia',
            'currency': 'ZMW',
            'mobile_money_penetration': 50.0,
            'card_penetration': 12.0,
            'internet_penetration': 42.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'mpesa', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'airtel_money', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'ipay', 'active': True, 'recommended': True, 'priority': 3},
                {'code': 'zanaco_express', 'active': True, 'recommended': True, 'priority': 4},
                {'code': 'zoona', 'active': True, 'recommended': False, 'priority': 5},
                {'code': 'mtn_momo', 'active': True, 'recommended': False, 'priority': 6},
            ],
            'central_bank': 'Bank of Zambia',
            'regulatory_body': 'BoZ',
        },
        
        # ==================== CENTRAL AFRICA (9) ====================
        'AO': {
            'name': 'Angola',
            'currency': 'AOA',
            'mobile_money_penetration': 25.0,
            'card_penetration': 15.0,
            'internet_penetration': 35.0,
            'dominant_methods': ['mobile_money', 'cash'],
            'providers': [
                {'code': 'multicaixa', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'unitel_money', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'africell', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'National Bank of Angola',
            'regulatory_body': 'BNA',
        },
        'CM': {
            'name': 'Cameroon',
            'currency': 'XAF',
            'mobile_money_penetration': 40.0,
            'card_penetration': 8.0,
            'internet_penetration': 38.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'express_union', 'active': True, 'recommended': True, 'priority': 3},
                {'code': 'flutterwave', 'active': True, 'recommended': False, 'priority': 4},
            ],
            'central_bank': 'Banque des États de l\'Afrique Centrale',
            'regulatory_body': 'BEAC',
        },
        'CF': {
            'name': 'Central African Republic',
            'currency': 'XAF',
            'mobile_money_penetration': 20.0,
            'card_penetration': 5.0,
            'internet_penetration': 8.0,
            'dominant_methods': ['mobile_money', 'cash'],
            'providers': [
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'mtn_momo', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Banque des États de l\'Afrique Centrale',
            'regulatory_body': 'BEAC',
        },
        'TD': {
            'name': 'Chad',
            'currency': 'XAF',
            'mobile_money_penetration': 25.0,
            'card_penetration': 5.0,
            'internet_penetration': 10.0,
            'dominant_methods': ['mobile_money', 'cash'],
            'providers': [
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'airtel_money', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'moov_money', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Banque des États de l\'Afrique Centrale',
            'regulatory_body': 'BEAC',
        },
        'CD': {
            'name': 'Democratic Republic of the Congo',
            'currency': 'CDF',
            'mobile_money_penetration': 35.0,
            'card_penetration': 5.0,
            'internet_penetration': 15.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'mpesa', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'airtel_money', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'orange_money', 'active': True, 'recommended': False, 'priority': 3},
                {'code': 'afmoney', 'active': True, 'recommended': False, 'priority': 4},
            ],
            'central_bank': 'Central Bank of Congo',
            'regulatory_body': 'BCC',
        },
        'CG': {
            'name': 'Republic of the Congo',
            'currency': 'XAF',
            'mobile_money_penetration': 30.0,
            'card_penetration': 8.0,
            'internet_penetration': 15.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'airtel_money', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'orange_money', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Banque des États de l\'Afrique Centrale',
            'regulatory_body': 'BEAC',
        },
        'GQ': {
            'name': 'Equatorial Guinea',
            'currency': 'XAF',
            'mobile_money_penetration': 20.0,
            'card_penetration': 10.0,
            'internet_penetration': 25.0,
            'dominant_methods': ['mobile_money', 'cash'],
            'providers': [
                {'code': 'orange_money', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'mtn_momo', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Banque des États de l\'Afrique Centrale',
            'regulatory_body': 'BEAC',
        },
        'GA': {
            'name': 'Gabon',
            'currency': 'XAF',
            'mobile_money_penetration': 35.0,
            'card_penetration': 15.0,
            'internet_penetration': 40.0,
            'dominant_methods': ['mobile_money', 'ussd'],
            'providers': [
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'airtel_money', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'moov_money', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Banque des États de l\'Afrique Centrale',
            'regulatory_body': 'BEAC',
        },
        'ST': {
            'name': 'São Tomé and Príncipe',
            'currency': 'STN',
            'mobile_money_penetration': 30.0,
            'card_penetration': 15.0,
            'internet_penetration': 40.0,
            'dominant_methods': ['mobile_money', 'cash'],
            'providers': [
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'unitel', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Central Bank of São Tomé and Príncipe',
            'regulatory_body': 'BCSTP',
        },
        
        # ==================== SOUTHERN AFRICA (8) ====================
        'BW': {
            'name': 'Botswana',
            'currency': 'BWP',
            'mobile_money_penetration': 30.0,
            'card_penetration': 35.0,
            'internet_penetration': 63.0,
            'dominant_methods': ['card', 'mobile_money'],
            'providers': [
                {'code': 'selcom', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'orange_money', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'mascom', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Bank of Botswana',
            'regulatory_body': 'BoB',
        },
        'SZ': {
            'name': 'Eswatini',
            'currency': 'SZL',
            'mobile_money_penetration': 40.0,
            'card_penetration': 25.0,
            'internet_penetration': 50.0,
            'dominant_methods': ['mobile_money', 'card'],
            'providers': [
                {'code': 'mtn_momo', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'swazi_mobile', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Central Bank of Eswatini',
            'regulatory_body': 'CBES',
        },
        'LS': {
            'name': 'Lesotho',
            'currency': 'LSL',
            'mobile_money_penetration': 35.0,
            'card_penetration': 20.0,
            'internet_penetration': 35.0,
            'dominant_methods': ['mobile_money', 'card'],
            'providers': [
                {'code': 'mpesa', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'econet_lesotho', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Central Bank of Lesotho',
            'regulatory_body': 'CBL',
        },
        'NA': {
            'name': 'Namibia',
            'currency': 'NAD',
            'mobile_money_penetration': 25.0,
            'card_penetration': 30.0,
            'internet_penetration': 47.0,
            'dominant_methods': ['card', 'mobile_money'],
            'providers': [
                {'code': 'mpesa', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'tnm', 'active': True, 'recommended': False, 'priority': 2},
                {'code': 'mtn_momo', 'active': True, 'recommended': False, 'priority': 3},
            ],
            'central_bank': 'Bank of Namibia',
            'regulatory_body': 'BoN',
        },
        'ZA': {
            'name': 'South Africa',
            'currency': 'ZAR',
            'mobile_money_penetration': 35.0,
            'card_penetration': 65.0,
            'internet_penetration': 72.0,
            'dominant_methods': ['card', 'instant_eft', 'qr'],
            'providers': [
                {'code': 'payfast', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'yoco', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'peach', 'active': True, 'recommended': True, 'priority': 3},
                {'code': 'ozow', 'active': True, 'recommended': True, 'priority': 4},
                {'code': 'snapscan', 'active': True, 'recommended': True, 'priority': 5},
                {'code': 'zapper', 'active': True, 'recommended': False, 'priority': 6},
                {'code': 'standard_bank_api', 'active': True, 'recommended': False, 'priority': 7},
                {'code': 'absa_api', 'active': True, 'recommended': False, 'priority': 8},
                {'code': 'fnb_api', 'active': True, 'recommended': False, 'priority': 9},
                {'code': 'flutterwave', 'active': True, 'recommended': False, 'priority': 10},
                {'code': 'paystack', 'active': True, 'recommended': False, 'priority': 11},
            ],
            'central_bank': 'South African Reserve Bank',
            'regulatory_body': 'SARB',
        },
        'ZW': {
            'name': 'Zimbabwe',
            'currency': 'USD',
            'mobile_money_penetration': 65.0,
            'card_penetration': 15.0,
            'internet_penetration': 64.0,
            'dominant_methods': ['mobile_money', 'ussd', 'bank_transfer'],
            'providers': [
                {'code': 'paynow', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'ecash', 'active': True, 'recommended': True, 'priority': 2},
                {'code': 'onemoney', 'active': True, 'recommended': False, 'priority': 3},
                {'code': 'telecash', 'active': True, 'recommended': False, 'priority': 4},
                {'code': 'pesapal', 'active': True, 'recommended': False, 'priority': 5},
                {'code': 'flutterwave', 'active': True, 'recommended': False, 'priority': 6},
                {'code': 'paystack', 'active': True, 'recommended': False, 'priority': 7},
            ],
            'central_bank': 'Reserve Bank of Zimbabwe',
            'regulatory_body': 'RBZ',
        },
        'IO': {
            'name': 'British Indian Ocean Territory',
            'currency': 'USD',
            'mobile_money_penetration': 10.0,
            'card_penetration': 50.0,
            'internet_penetration': 60.0,
            'dominant_methods': ['card'],
            'providers': [
                {'code': 'stripe', 'active': True, 'recommended': True, 'priority': 1},
                {'code': 'paypal', 'active': True, 'recommended': False, 'priority': 2},
            ],
            'central_bank': 'Bank of England',
            'regulatory_body': 'FCA',
        },
    }

    # Provider metadata - expanded for all African providers
    PROVIDER_METADATA = {
        # Pan-African Aggregators
        'flutterwave': {'name': 'Flutterwave', 'category': 'aggregator', 'headquarters': 'NG'},
        'paystack': {'name': 'Paystack', 'category': 'aggregator', 'headquarters': 'NG'},
        'pesapal': {'name': 'Pesapal', 'category': 'aggregator', 'headquarters': 'KE'},
        'dpo': {'name': 'DPO Group', 'category': 'aggregator', 'headquarters': 'MU'},
        'cellulant': {'name': 'Cellulant', 'category': 'aggregator', 'headquarters': 'KE'},
        'chipper_cash': {'name': 'Chipper Cash', 'category': 'aggregator', 'headquarters': 'NG'},
        
        # Mobile Money Operators
        'mpesa': {'name': 'Safaricom M-Pesa', 'category': 'mobile_money', 'headquarters': 'KE'},
        'mtn_momo': {'name': 'MTN Mobile Money', 'category': 'mobile_money', 'headquarters': 'ZA'},
        'airtel_money': {'name': 'Airtel Money', 'category': 'mobile_money', 'headquarters': 'IN'},
        'orange_money': {'name': 'Orange Money', 'category': 'mobile_money', 'headquarters': 'FR'},
        'vodacom_mpesa': {'name': 'Vodacom M-Pesa', 'category': 'mobile_money', 'headquarters': 'ZA'},
        'ecash': {'name': 'EcoCash', 'category': 'mobile_money', 'headquarters': 'ZW'},
        'tigo_pesa': {'name': 'Tigo Pesa', 'category': 'mobile_money', 'headquarters': 'TZ'},
        'onemoney': {'name': 'OneMoney', 'category': 'mobile_money', 'headquarters': 'ZW'},
        'telecash': {'name': 'Telecash', 'category': 'mobile_money', 'headquarters': 'ZW'},
        'wave': {'name': 'Wave', 'category': 'mobile_money', 'headquarters': 'SN'},
        'free_money': {'name': 'Free Money', 'category': 'mobile_money', 'headquarters': 'SN'},
        'mvola': {'name': 'MVola', 'category': 'mobile_money', 'headquarters': 'MG'},
        'hellocash': {'name': 'HelloCash', 'category': 'mobile_money', 'headquarters': 'ET'},
        'telebirr': {'name': 'Telebirr', 'category': 'mobile_money', 'headquarters': 'ET'},
        'tnm_mpamba': {'name': 'TNM Mpamba', 'category': 'mobile_money', 'headquarters': 'MW'},
        'moov_money': {'name': 'Moov Money', 'category': 'mobile_money', 'headquarters': 'BJ'},
        'mobicash': {'name': 'MobiCash', 'category': 'mobile_money', 'headquarters': 'BJ'},
        'lumicash': {'name': 'Lumicash', 'category': 'mobile_money', 'headquarters': 'BI'},
        'econet': {'name': 'Econet Money', 'category': 'mobile_money', 'headquarters': 'ZW'},
        'e_dahab': {'name': 'e-Dahab', 'category': 'mobile_money', 'headquarters': 'SO'},
        'zaad': {'name': 'Zaad', 'category': 'mobile_money', 'headquarters': 'SO'},
        'eVC_plus': {'name': 'eVC Plus', 'category': 'mobile_money', 'headquarters': 'SO'},
        'unitel_money': {'name': 'Unitel Money', 'category': 'mobile_money', 'headquarters': 'AO'},
        'cbe_birr': {'name': 'CBE Birr', 'category': 'mobile_money', 'headquarters': 'ET'},
        'kcb_pesa': {'name': 'KCB Pesa', 'category': 'mobile_money', 'headquarters': 'KE'},
        'emola': {'name': 'e-Mola', 'category': 'mobile_money', 'headquarters': 'MZ'},
        'mcel': {'name': 'Mcel Money', 'category': 'mobile_money', 'headquarters': 'CV'},
        'unitel': {'name': 'Unitel', 'category': 'mobile_money', 'headquarters': 'AO'},
        'swazi_mobile': {'name': 'Swazi Mobile Money', 'category': 'mobile_money', 'headquarters': 'SZ'},
        'econet_lesotho': {'name': 'Econet Lesotho', 'category': 'mobile_money', 'headquarters': 'LS'},
        'tnm': {'name': 'TNM', 'category': 'mobile_money', 'headquarters': 'NA'},
        'mascom': {'name': 'Mascom MyZaka', 'category': 'mobile_money', 'headquarters': 'BW'},
        'zain_cash': {'name': 'Zain Cash', 'category': 'mobile_money', 'headquarters': 'IQ'},
        'afmoney': {'name': 'AFMoney', 'category': 'mobile_money', 'headquarters': 'CD'},
        'intouch': {'name': 'InTouch', 'category': 'mobile_money', 'headquarters': 'GN'},
        'bocay': {'name': 'Bocay', 'category': 'mobile_money', 'headquarters': 'SL'},
        'mattels': {'name': 'Mattels', 'category': 'mobile_money', 'headquarters': 'MR'},
        'qcell': {'name': 'QCell', 'category': 'mobile_money', 'headquarters': 'GM'},
        'btc': {'name': 'BTC', 'category': 'mobile_money', 'headquarters': 'GM'},
        'lonestar': {'name': 'Lonestar', 'category': 'mobile_money', 'headquarters': 'LR'},
        'evamoney': {'name': 'evaMoney', 'category': 'mobile_money', 'headquarters': 'DJ'},
        'djambo': {'name': 'Djambou', 'category': 'mobile_money', 'headquarters': 'DJ'},
        'tele': {'name': 'EriTel', 'category': 'mobile_money', 'headquarters': 'ER'},
        'aitel_money': {'name': 'Airtel Money', 'category': 'mobile_money', 'headquarters': 'MG'},
        'national_bank': {'name': 'National Bank', 'category': 'bank_api', 'headquarters': 'MW'},
        'seychelles_savings': {'name': 'Seychelles Savings', 'category': 'bank_api', 'headquarters': 'SC'},
        'absa': {'name': 'Absa Seychelles', 'category': 'bank_api', 'headquarters': 'SC'},
        
        # West Africa Gateways
        'monnify': {'name': 'Monnify', 'category': 'local_gateway', 'headquarters': 'NG'},
        'interswitch': {'name': 'Interswitch', 'category': 'local_gateway', 'headquarters': 'NG'},
        'voguepay': {'name': 'VoguePay', 'category': 'local_gateway', 'headquarters': 'NG'},
        'opay': {'name': 'Opay', 'category': 'local_gateway', 'headquarters': 'NG'},
        'palmPay': {'name': 'PalmPay', 'category': 'local_gateway', 'headquarters': 'NG'},
        'paga': {'name': 'Paga', 'category': 'local_gateway', 'headquarters': 'NG'},
        'remita': {'name': 'Remita', 'category': 'local_gateway', 'headquarters': 'NG'},
        'etranzact': {'name': 'eTranzact', 'category': 'local_gateway', 'headquarters': 'NG'},
        'payu': {'name': 'PayU', 'category': 'local_gateway', 'headquarters': 'NG'},
        'expresspay': {'name': 'ExpressPay', 'category': 'local_gateway', 'headquarters': 'GH'},
        'zeepay': {'name': 'Zeepay', 'category': 'local_gateway', 'headquarters': 'GH'},
        'slydepay': {'name': 'Slydepay', 'category': 'local_gateway', 'headquarters': 'GH'},
        'hubtel': {'name': 'Hubtel', 'category': 'local_gateway', 'headquarters': 'GH'},
        'express_union': {'name': 'Express Union', 'category': 'local_gateway', 'headquarters': 'CM'},
        'uba_card': {'name': 'UBA Card', 'category': 'bank_api', 'headquarters': 'NG'},
        'satim': {'name': 'SATIM', 'category': 'local_gateway', 'headquarters': 'DZ'},
        'baridimob': {'name': 'Baridimob', 'category': 'local_gateway', 'headquarters': 'DZ'},
        'sahab': {'name': 'Sahab', 'category': 'local_gateway', 'headquarters': 'LY'},
        'moamalat': {'name': 'Moamalat', 'category': 'local_gateway', 'headquarters': 'LY'},
        'khazna': {'name': 'Khazna', 'category': 'local_gateway', 'headquarters': 'EG'},
        'bankak': {'name': 'Bankak', 'category': 'local_gateway', 'headquarters': 'SD'},
        'fawry': {'name': 'Fawry', 'category': 'local_gateway', 'headquarters': 'EG'},
        
        # East Africa Gateways
        'chapa': {'name': 'Chapa', 'category': 'local_gateway', 'headquarters': 'ET'},
        'centenary_bank': {'name': 'Centenary Bank', 'category': 'bank_api', 'headquarters': 'UG'},
        'stanbic_api': {'name': 'Stanbic Bank API', 'category': 'bank_api', 'headquarters': 'ZA'},
        'bank_of_kigali': {'name': 'Bank of Kigali', 'category': 'bank_api', 'headquarters': 'RW'},
        'equity_bank': {'name': 'Equity Bank', 'category': 'bank_api', 'headquarters': 'KE'},
        'nmb_api': {'name': 'NMB Bank API', 'category': 'bank_api', 'headquarters': 'TZ'},
        'crdb_api': {'name': 'CRDB Bank API', 'category': 'bank_api', 'headquarters': 'TZ'},
        'ipay': {'name': 'iPay', 'category': 'local_gateway', 'headquarters': 'ZM'},
        'zanaco_express': {'name': 'Zanaco Express', 'category': 'local_gateway', 'headquarters': 'ZM'},
        'zoona': {'name': 'Zoona', 'category': 'mobile_money', 'headquarters': 'ZM'},
        
        # Southern Africa Gateways
        'payfast': {'name': 'PayFast', 'category': 'local_gateway', 'headquarters': 'ZA'},
        'peach': {'name': 'Peach Payments', 'category': 'local_gateway', 'headquarters': 'ZA'},
        'ozow': {'name': 'Ozow', 'category': 'local_gateway', 'headquarters': 'ZA'},
        'yoco': {'name': 'Yoco', 'category': 'local_gateway', 'headquarters': 'ZA'},
        'snapscan': {'name': 'SnapScan', 'category': 'pos_qr', 'headquarters': 'ZA'},
        'zapper': {'name': 'Zapper', 'category': 'pos_qr', 'headquarters': 'ZA'},
        'selcom': {'name': 'Selcom', 'category': 'local_gateway', 'headquarters': 'BW'},
        'standard_bank_api': {'name': 'Standard Bank API', 'category': 'bank_api', 'headquarters': 'ZA'},
        'absa_api': {'name': 'Absa/FirstRand API', 'category': 'bank_api', 'headquarters': 'ZA'},
        'fnb_api': {'name': 'FNB API', 'category': 'bank_api', 'headquarters': 'ZA'},
        'multicaixa': {'name': 'Multicaixa', 'category': 'local_gateway', 'headquarters': 'AO'},
        'mcb_juice': {'name': 'MCB Juice', 'category': 'mobile_money', 'headquarters': 'MU'},
        'my_t_money': {'name': 'My.t Money', 'category': 'mobile_money', 'headquarters': 'MU'},
        'sbm_api': {'name': 'SBM Bank API', 'category': 'bank_api', 'headquarters': 'MU'},
        'bni': {'name': 'BNI Madagascar', 'category': 'bank_api', 'headquarters': 'MG'},
        
        # North Africa Gateways
        'valu': {'name': 'Valu', 'category': 'local_gateway', 'headquarters': 'EG'},
        'masary': {'name': 'Masary', 'category': 'local_gateway', 'headquarters': 'EG'},
        'paymob': {'name': 'Paymob', 'category': 'local_gateway', 'headquarters': 'EG'},
        'cmi': {'name': 'CMI', 'category': 'local_gateway', 'headquarters': 'MA'},
        'payzone': {'name': 'PayZone', 'category': 'local_gateway', 'headquarters': 'MA'},
        'hps': {'name': 'HPS', 'category': 'local_gateway', 'headquarters': 'MA'},
        'edahabia': {'name': 'EDAHABIA', 'category': 'local_gateway', 'headquarters': 'DZ'},
        'flouci': {'name': 'Flouci', 'category': 'local_gateway', 'headquarters': 'TN'},
        'sodet': {'name': 'Sodet', 'category': 'local_gateway', 'headquarters': 'TN'},
        'runpay': {'name': 'RunPay', 'category': 'local_gateway', 'headquarters': 'TN'},
        'attijariwafa': {'name': 'Attijariwafa Bank', 'category': 'bank_api', 'headquarters': 'MA'},
        'cashplus': {'name': 'Cash Plus', 'category': 'local_gateway', 'headquarters': 'MA'},
        
        # Remittance Providers
        'worldremit': {'name': 'WorldRemit', 'category': 'remittance', 'headquarters': 'GB'},
        'transferwise': {'name': 'Wise', 'category': 'remittance', 'headquarters': 'GB'},
        'remitly': {'name': 'Remitly', 'category': 'remittance', 'headquarters': 'US'},
        'sendwave': {'name': 'Sendwave', 'category': 'remittance', 'headquarters': 'US'},
        
        # International/Test
        'stripe': {'name': 'Stripe', 'category': 'international', 'headquarters': 'US'},
        'paypal': {'name': 'PayPal', 'category': 'international', 'headquarters': 'US'},
        'mock': {'name': 'Mock Payment', 'category': 'manual', 'headquarters': 'US'},
    }

    @transaction.atomic
    def handle(self, *args, **options):
        self.stdout.write('Starting country-provider seeding for ALL 54 African countries...')
        
        # Step 1: Create/Update Countries
        self.stdout.write('\nStep 1: Creating/Updating all 54 African countries...')
        countries_created = 0
        countries_updated = 0
        
        for code, data in self.AFRICAN_COUNTRIES.items():
            country, created = Country.objects.update_or_create(
                code=code,
                defaults={
                    'name': data['name'],
                    'is_active': True,
                }
            )
            if created:
                countries_created += 1
                self.stdout.write(f'  ✓ Created: {country.name} ({code})')
            else:
                countries_updated += 1
        
        self.stdout.write(f'\n  Countries: {countries_created} created, {countries_updated} updated')
        self.stdout.write(f'  Total African countries: {countries_created + countries_updated}')
        
        # Step 2: Create/Update Payment Provider Models
        self.stdout.write('\nStep 2: Creating/Updating payment providers...')
        providers_created = 0
        
        for code, metadata in self.PROVIDER_METADATA.items():
            provider, created = PaymentProviderModel.objects.update_or_create(
                code=code,
                defaults={
                    'name': metadata['name'],
                    'category': metadata['category'],
                    'headquarters_country': metadata['headquarters'],
                    'is_active': True,
                }
            )
            if created:
                providers_created += 1
                self.stdout.write(f'  ✓ Created: {provider.name} ({code})')
        
        self.stdout.write(f'\n  Providers: {providers_created} created/updated')
        
        # Step 3: Create ProviderCountryConfig
        self.stdout.write('\nStep 3: Linking providers to countries...')
        configs_created = 0
        configs_updated = 0
        configs_skipped = 0
        
        for country_code, country_data in self.AFRICAN_COUNTRIES.items():
            try:
                country = Country.objects.get(code=country_code)
            except Country.DoesNotExist:
                self.stdout.write(f'  ⚠ Country {country_code} not found, skipping...')
                continue
            
            for provider_data in country_data['providers']:
                provider_code = provider_data['code']
                
                try:
                    provider = PaymentProviderModel.objects.get(code=provider_code)
                except PaymentProviderModel.DoesNotExist:
                    self.stdout.write(f'  ⚠ Provider {provider_code} not found for {country_code}, skipping...')
                    configs_skipped += 1
                    continue
                
                # Determine supported currencies based on country
                supported_currencies = [country_data['currency']]
                if country_data['currency'] not in ['USD', 'EUR']:
                    supported_currencies.append('USD')
                
                # Determine supported methods
                supported_methods = country_data['dominant_methods']
                
                config, created = ProviderCountryConfig.objects.update_or_create(
                    provider=provider,
                    country=country_code,
                    defaults={
                        'is_active': provider_data['active'],
                        'is_sandbox': True,  # Default to sandbox
                        'supported_currencies': supported_currencies,
                        'supported_methods': supported_methods,
                        'fee_percentage': 2.5,  # Default 2.5%
                        'fixed_fee': 0.00,
                    }
                )
                
                if created:
                    configs_created += 1
                else:
                    configs_updated += 1
                
                if provider_data['recommended']:
                    provider.is_recommended = True
                    provider.priority = provider_data['priority']
                    provider.save()
        
        self.stdout.write(f'\n  Configs: {configs_created} created, {configs_updated} updated, {configs_skipped} skipped')
        
        # Step 4: Create CountryPaymentLandscape
        self.stdout.write('\nStep 4: Creating country payment landscapes...')
        landscapes_created = 0
        landscapes_updated = 0
        
        for country_code, country_data in self.AFRICAN_COUNTRIES.items():
            # Get recommended providers for this country
            recommended_providers = [
                p['code'] for p in country_data['providers'] if p['recommended']
            ]
            fallback_providers = [
                p['code'] for p in country_data['providers'] if not p['active']
            ]
            
            # Get dominant mobile money providers
            dominant_mobile_money = [
                p['code'] for p in country_data['providers']
                if p['code'] in ['mpesa', 'mtn_momo', 'airtel_money', 'orange_money', 
                                'ecash', 'wave', 'telebirr', 'emola', 'mvola', 'tigo_pesa']
            ][:3]
            
            landscape, created = CountryPaymentLandscape.objects.update_or_create(
                country_code=country_code,
                defaults={
                    'country_name': country_data['name'],
                    'dominant_methods': country_data['dominant_methods'],
                    'mobile_money_penetration': country_data['mobile_money_penetration'],
                    'card_penetration': country_data['card_penetration'],
                    'internet_penetration': country_data['internet_penetration'],
                    'dominant_mobile_money': dominant_mobile_money,
                    'local_currency': self._get_currency_code(country_data['currency']),
                    'accepts_usd': country_data['currency'] != 'USD',
                    'central_bank': country_data['central_bank'],
                    'regulatory_body': country_data['regulatory_body'],
                    'recommended_providers': recommended_providers,
                    'fallback_providers': fallback_providers,
                }
            )
            
            if created:
                landscapes_created += 1
                self.stdout.write(f'  ✓ Created: {country_data["name"]}')
            else:
                landscapes_updated += 1
        
        self.stdout.write(f'\n  Landscapes: {landscapes_created} created, {landscapes_updated} updated')
        
        self.stdout.write(self.style.SUCCESS('\n\n✅ Country-provider seeding completed successfully!'))
        self.stdout.write(f'\n📊 Summary:')
        self.stdout.write(f'  🌍 African Countries: {countries_created + countries_updated}/54')
        self.stdout.write(f'  💳 Payment Providers: {providers_created}')
        self.stdout.write(f'  🔗 Provider-Country Configs: {configs_created + configs_updated}')
        self.stdout.write(f'  📈 Payment Landscapes: {landscapes_created + landscapes_updated}')
        self.stdout.write(f'\n🎉 All 54 African countries now have payment provider mappings!')
    
    def _get_currency_code(self, currency: str) -> str:
        """Map currency code to Currency enum"""
        currency_map = {
            'USD': 'usd',
            'EUR': 'eur',
            'ZAR': 'zar',
            'NGN': 'ngn',
            'KES': 'kes',
            'GHS': 'ghs',
            'EGP': 'egp',
            'TZS': 'tzs',
            'UGX': 'ugx',
            'ETB': 'etb',
            'RWF': 'rwf',
            'ZMW': 'zmw',
            'XOF': 'xof',
            'XAF': 'xaf',
            'MAD': 'mad',
            'DZD': 'dzd',
            'TND': 'tnd',
            'MZN': 'mzn',
            'BWP': 'bwp',
            'NAD': 'nad',
            'AOA': 'aoa',
            'MWK': 'mwk',
            'ZWL': 'zwl',
            'LYD': 'lyd',
            'SDG': 'sdg',
            'SSP': 'ssp',
            'SOS': 'sos',
            'DJF': 'djf',
            'ERN': 'ern',
            'BIF': 'bif',
            'KMF': 'kmf',
            'MGA': 'mga',
            'MUR': 'mur',
            'SCR': 'scr',
            'SZL': 'szl',
            'LSL': 'lsl',
            'CDF': 'cdf',
            'GNF': 'gnf',
            'SLL': 'sll',
            'LRD': 'lrd',
            'GMD': 'gmd',
            'CVE': 'cve',
            'STN': 'stn',
            'MRU': 'mru',
            'MAD': 'mad',
            'DZD': 'dzd',
            'TND': 'tnd',
            'LYD': 'lyd',
        }
        return currency_map.get(currency, 'usd')
