from django.db import models

from django.utils.translation import gettext_lazy as _
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType

# import uuid  # Removed - using BigAutoField instead



# Module constants for course types

COURSE_TYPE_AICERTS = "aicerts_courses"

COURSE_TYPE_LEARNERSHIPS = "learnerships"

COURSE_TYPE_CHOICES = [

    (COURSE_TYPE_AICERTS, "AI Certs Course"),

    (COURSE_TYPE_LEARNERSHIPS, "Learnership"),

]



# ==================== PAYMENT ENUMS ====================

class ProviderCategory(models.TextChoices):

    """Categories of payment providers"""

    AGGREGATOR = 'aggregator', 'Pan-African Aggregator'

    MOBILE_MONEY = 'mobile_money', 'Mobile Money Operator'

    LOCAL_GATEWAY = 'local_gateway', 'Country-Specific Gateway'

    BANK_API = 'bank_api', 'Bank API/Virtual Account'

    REMITTANCE = 'remittance', 'Remittance Provider'

    POS_QR = 'pos_qr', 'POS/QR/Agent Network'

    INTERNATIONAL = 'international', 'International Gateway'

    MANUAL = 'manual', 'Manual/Offline'





class PaymentProvider(models.TextChoices):

    """Complete list of African payment providers - 100+ providers"""

    

    # ===== PAN-AFRICAN AGGREGATORS (6) =====

    FLUTTERWAVE = 'flutterwave', 'Flutterwave'

    PAYSTACK = 'paystack', 'Paystack'

    MFS_AFRICA = 'mfs_africa', 'MFS Africa'

    PESAPAL = 'pesapal', 'Pesapal'

    DPO = 'dpo', 'DPO Group'

    CELLULANT = 'cellulant', 'Cellulant'

    CHIPPER_CASH = 'chipper_cash', 'Chipper Cash'

    

    # ===== MOBILE MONEY OPERATORS (15) =====

    MPESA = 'mpesa', 'Safaricom M-Pesa'

    MTN_MOMO = 'mtn_momo', 'MTN Mobile Money'

    AIRTEL_MONEY = 'airtel_money', 'Airtel Money'

    ORANGE_MONEY = 'orange_money', 'Orange Money'

    VODACOM_MPESA = 'vodacom_mpesa', 'Vodacom M-Pesa'

    ECASH = 'ecash', 'EcoCash (Zimbabwe)'

    TIGO_PESA = 'tigo_pesa', 'Tigo Pesa'

    TIGO_CASH = 'tigo_cash', 'Tigo Cash'

    ONEMONEY = 'onemoney', 'OneMoney (Zimbabwe)'

    TELECASH = 'telecash', 'Telecash (Zimbabwe)'

    WAVE = 'wave', 'Wave (Senegal)'

    FREE_MONEY = 'free_money', 'Free Money (Senegal)'

    MVOLA = 'mvola', 'MVola (Madagascar)'

    HELLOCASH = 'hellocash', 'HelloCash (Ethiopia)'

    TELEBIRR = 'telebirr', 'Telebirr (Ethiopia)'

    TNM_MPAMBA = 'tnm_mpamba', 'TNM Mpamba (Malawi)'

    

    # ===== WEST AFRICA GATEWAYS (15) =====

    MONNIFY = 'monnify', 'Monnify (Nigeria)'

    INTERSWITCH = 'interswitch', 'Interswitch (Nigeria)'

    VOGUEPAY = 'voguepay', 'VoguePay (Nigeria)'

    OPAY = 'opay', 'Opay (Nigeria)'

    PALMPAY = 'palmPay', 'PalmPay (Nigeria)'

    PAGA = 'paga', 'Paga (Nigeria)'

    REMITA = 'remita', 'Remita (Nigeria)'

    ETRAZACT = 'etranzact', 'eTranzact (West Africa)'

    PAYU = 'payu', 'PayU (Nigeria/Ghana)'

    EXPRESSPAY = 'expresspay', 'ExpressPay (Ghana)'

    ZEEPAY = 'zeepay', 'Zeepay (Ghana)'

    SLYDEPAY = 'slydepay', 'Slydepay (Ghana)'

    HUBTEL = 'hubtel', 'Hubtel (Ghana)'

    EXPRESS_UNION = 'express_union', 'Express Union (Cameroon)'

    UBA_CARD = 'uba_card', 'UBA Card'

    

    # ===== SPECIAL / TESTING =====

    MOCK = 'mock', 'Mock Payment (Test)'

    IPAY = 'ipay', 'iPay (Zambia)'

    ZANACO_EXPRESS = 'zanaco_express', 'Zanaco Express (Zambia)'

    ZOONA = 'zoona', 'Zoona (Zambia)'

    NMB_API = 'nmb_api', 'NMB Bank API (Tanzania)'

    CRDB_API = 'crdb_api', 'CRDB Bank API (Tanzania)'

    

    # ===== EAST AFRICA GATEWAYS (5) =====

    CHAPA = 'chapa', 'Chapa (Ethiopia)'

    CENTENARY_BANK = 'centenary_bank', 'Centenary Bank (Uganda)'

    STANBIC_API = 'stanbic_api', 'Stanbic Bank API'

    BANK_OF_KIGALI = 'bank_of_kigali', 'Bank of Kigali'

    EQUITY_BANK = 'equity_bank', 'Equity Bank'

    

    # ===== SOUTHERN AFRICA GATEWAYS (12) =====

    PAYFAST = 'payfast', 'PayFast (South Africa)'

    PEACH = 'peach', 'Peach Payments (South Africa)'

    OZOW = 'ozow', 'Ozow (South Africa)'

    YOCO = 'yoco', 'Yoco (South Africa)'

    SNAPSCAN = 'snapscan', 'SnapScan (South Africa)'

    ZAPPER = 'zapper', 'Zapper (South Africa)'

    SELCOM = 'selcom', 'Selcom (Botswana)'

    STANDARD_BANK_API = 'standard_bank_api', 'Standard Bank API'

    ABSA_API = 'absa_api', 'Absa/FirstRand API'

    FNB_API = 'fnb_api', 'FNB API'

    MULTICAIXA = 'multicaixa', 'Multicaixa (Angola)'

    EMOLA = 'emola', 'e-Mola (Mozambique)'

    

    # ===== NORTH AFRICA GATEWAYS (10) =====

    FAWRY = 'fawry', 'Fawry (Egypt)'

    VALU = 'valu', 'Valu (Egypt)'

    MASARY = 'masary', 'Masary (Egypt)'

    PAYMOB = 'paymob', 'Paymob (Egypt)'

    CMI = 'cmi', 'CMI (Morocco)'

    PAYZONE = 'payzone', 'PayZone (Morocco)'

    HPS = 'hps', 'HPS (Morocco)'

    EDAHABIA = 'edahabia', 'EDAHABIA (Algeria)'

    FLOUCI = 'flouci', 'Flouci (Tunisia)'

    ATTIJARIWAFA = 'attijariwafa', 'Attijariwafa Bank'

    

    # ===== ISLAND NATIONS (4) =====

    MCB_JUICE = 'mcb_juice', 'MCB Juice (Mauritius)'

    MY_T_MONEY = 'my_t_money', 'My.t Money (Mauritius)'

    SBM_API = 'sbm_api', 'SBM Bank API (Mauritius)'

    BNI = 'bni', 'BNI Madagascar'

    

    # ===== REMITTANCE PROVIDERS (5) =====

    WORLDREMIT = 'worldremit', 'WorldRemit'

    TRANSFERWISE = 'transferwise', 'Wise (TransferWise)'

    REMITLY = 'remitly', 'Remitly'

    SENDWAVE = 'sendwave', 'Sendwave'

    WESTERN_UNION = 'western_union', 'Western Union'

    

    # ===== BANK APIS (15) =====

    ZENITH_API = 'zenith_api', 'Zenith Bank API'

    GTBANK_API = 'gtbank_api', 'GTBank API'

    ECOBANK_API = 'ecobank_api', 'Ecobank API'

    COMMERCIAL_BANK_ETHIOPIA = 'cbe', 'Commercial Bank of Ethiopia'

    BMCE = 'bmce', 'BMCE Bank'

    BNA = 'bna', 'BNA (Algeria)'

    BIA_NIGER = 'bia_niger', 'BIA Niger'

    BICIGUI = 'bicigui', 'BICIGUI (Guinea)'

    BFV = 'bfv', 'BFV Madagascar'

    BCM = 'bcm', 'BCM Mauritania'

    ROYAL_BANK = 'royal_bank', 'Royal Bank (Malawi)'

    BAI = 'bai', 'BAI Angola'

    BFA = 'bfa', 'BFA Angola'

    BANK_WINDHOEK = 'bank_windhoek', 'Bank Windhoek (Namibia)'

    ROKEL_BANK = 'rokel_bank', 'Rokel Bank (Sierra Leone)'

    

    # ===== POS/QR/AGENT NETWORKS (4) =====

    YOCO_POS = 'yoco_pos', 'Yoco POS'

    POYNT = 'poynt', 'Poynt'

    SHOPRITE_CHECKOUT = 'shoprite_checkout', 'Shoprite Checkout'

    AGENT_NETWORK = 'agent_network', 'Agent Network'

    

    # ===== INTERNATIONAL (6) =====

    STRIPE = 'stripe', 'Stripe'

    PAYPAL = 'paypal', 'PayPal'

    BANK_TRANSFER = 'bank_transfer', 'Bank Transfer'

    CASH = 'cash', 'Cash'

    MANUAL = 'manual', 'Manual/Offline'

    CRYPTO = 'crypto', 'Cryptocurrency'





class PaymentMethod(models.TextChoices):

    """Payment methods/types"""

    CARD = 'card', 'Credit/Debit Card'

    MOBILE_MONEY = 'mobile_money', 'Mobile Money'

    BANK_TRANSFER = 'bank_transfer', 'Bank Transfer'

    USSD = 'ussd', 'USSD'

    BANK_REDIRECT = 'bank_redirect', 'Bank Redirect'

    QR_CODE = 'qr_code', 'QR Code'

    CASH = 'cash', 'Cash Deposit'

    WALLET = 'wallet', 'Digital Wallet'

    POS = 'pos', 'Point of Sale'

    AGENT = 'agent', 'Agent Network'

    CHEQUE = 'cheque', 'Cheque'

    EFT = 'eft', 'Electronic Funds Transfer'





class Currency(models.TextChoices):

    """African and international currencies"""

    # West Africa

    NGN = 'NGN', 'Nigerian Naira'

    GHS = 'GHS', 'Ghanaian Cedi'

    XOF = 'XOF', 'West African CFA Franc'

    SLL = 'SLL', 'Sierra Leonean Leone'

    GMD = 'GMD', 'Gambian Dalasi'

    LRD = 'LRD', 'Liberian Dollar'

    

    # East Africa

    KES = 'KES', 'Kenyan Shilling'

    TZS = 'TZS', 'Tanzanian Shilling'

    UGX = 'UGX', 'Ugandan Shilling'

    RWF = 'RWF', 'Rwandan Franc'

    ETB = 'ETB', 'Ethiopian Birr'

    SOS = 'SOS', 'Somali Shilling'

    BIF = 'BIF', 'Burundian Franc'

    DJF = 'DJF', 'Djiboutian Franc'

    

    # Southern Africa

    ZAR = 'ZAR', 'South African Rand'

    ZMW = 'ZMW', 'Zambian Kwacha'

    ZWL = 'ZWL', 'Zimbabwean Dollar'

    MWK = 'MWK', 'Malawian Kwacha'

    MZN = 'MZN', 'Mozambican Metical'

    AOA = 'AOA', 'Angolan Kwanza'

    SZL = 'SZL', 'Swazi Lilangeni'

    LSL = 'LSL', 'Lesotho Loti'

    NAD = 'NAD', 'Namibian Dollar'

    BWP = 'BWP', 'Botswana Pula'

    MGA = 'MGA', 'Malagasy Ariary'

    SCR = 'SCR', 'Seychellois Rupee'

    MUR = 'MUR', 'Mauritian Rupee'

    

    # North Africa

    EGP = 'EGP', 'Egyptian Pound'

    MAD = 'MAD', 'Moroccan Dirham'

    DZD = 'DZD', 'Algerian Dinar'

    TND = 'TND', 'Tunisian Dinar'

    LYD = 'LYD', 'Libyan Dinar'

    SDG = 'SDG', 'Sudanese Pound'

    MRU = 'MRU', 'Mauritanian Ouguiya'

    

    # Central Africa

    XAF = 'XAF', 'Central African CFA Franc'  # Keep only this one

    CDF = 'CDF', 'Congolese Franc'

    

    # International

    USD = 'USD', 'US Dollar'

    EUR = 'EUR', 'Euro'

    GBP = 'GBP', 'British Pound'

    CNY = 'CNY', 'Chinese Yuan'

    INR = 'INR', 'Indian Rupee'

    AED = 'AED', 'UAE Dirham'

    

class PaymentStatus(models.TextChoices):

    """Payment transaction statuses"""

    PENDING = 'pending', 'Pending'

    PROCESSING = 'processing', 'Processing'

    SUCCESSFUL = 'successful', 'Successful'

    FAILED = 'failed', 'Failed'

    CANCELLED = 'cancelled', 'Cancelled'

    REFUNDED = 'refunded', 'Refunded'

    DISPUTED = 'disputed', 'Disputed'

    EXPIRED = 'expired', 'Expired'

    PARTIALLY_REFUNDED = 'partially_refunded', 'Partially Refunded'





class TransactionType(models.TextChoices):

    """Types of financial transactions"""

    DEPOSIT = 'deposit', 'Deposit'

    WITHDRAWAL = 'withdrawal', 'Withdrawal'

    PURCHASE = 'purchase', 'Purchase'

    REFUND = 'refund', 'Refund'

    PAYOUT = 'payout', 'Payout'

    SUBSCRIPTION = 'subscription', 'Subscription'

    COMMISSION = 'commission', 'Commission'

    TRANSFER = 'transfer', 'Transfer'

    FEE = 'fee', 'Fee'

    CHARGEBACK = 'chargeback', 'Chargeback'





class CountryCode(models.TextChoices):

    """ISO Country codes for Africa"""

    # West Africa

    NG = 'NG', 'Nigeria'

    GH = 'GH', 'Ghana'

    CI = 'CI', "Côte d'Ivoire"

    SN = 'SN', 'Senegal'

    GN = 'GN', 'Guinea'

    ML = 'ML', 'Mali'

    BF = 'BF', 'Burkina Faso'

    BJ = 'BJ', 'Benin'

    NE = 'NE', 'Niger'

    TG = 'TG', 'Togo'

    LR = 'LR', 'Liberia'

    SL = 'SL', 'Sierra Leone'

    GM = 'GM', 'Gambia'

    GW = 'GW', 'Guinea-Bissau'

    CV = 'CV', 'Cabo Verde'

    

    # East Africa

    KE = 'KE', 'Kenya'

    TZ = 'TZ', 'Tanzania'

    UG = 'UG', 'Uganda'

    RW = 'RW', 'Rwanda'

    ET = 'ET', 'Ethiopia'

    SS = 'SS', 'South Sudan'

    SO = 'SO', 'Somalia'

    DJ = 'DJ', 'Djibouti'

    ER = 'ER', 'Eritrea'

    

    # Southern Africa

    ZA = 'ZA', 'South Africa'

    ZM = 'ZM', 'Zambia'

    ZW = 'ZW', 'Zimbabwe'

    MW = 'MW', 'Malawi'

    MZ = 'MZ', 'Mozambique'

    AO = 'AO', 'Angola'

    SZ = 'SZ', 'Eswatini'

    LS = 'LS', 'Lesotho'

    NA = 'NA', 'Namibia'

    BW = 'BW', 'Botswana'

    MG = 'MG', 'Madagascar'

    MU = 'MU', 'Mauritius'

    SC = 'SC', 'Seychelles'

    KM = 'KM', 'Comoros'

    

    # North Africa

    EG = 'EG', 'Egypt'

    MA = 'MA', 'Morocco'

    DZ = 'DZ', 'Algeria'

    TN = 'TN', 'Tunisia'

    LY = 'LY', 'Libya'

    SD = 'SD', 'Sudan'

    MR = 'MR', 'Mauritania'

    

    # Central Africa

    CM = 'CM', 'Cameroon'

    CD = 'CD', 'DR Congo'

    CG = 'CG', 'Republic of Congo'

    GA = 'GA', 'Gabon'

    TD = 'TD', 'Chad'

    CF = 'CF', 'Central African Republic'

    GQ = 'GQ', 'Equatorial Guinea'

    ST = 'ST', 'São Tomé and Príncipe'



# ==================== ORDER MODELS (DEFINED FIRST) ====================

class Order(models.Model):

    """Order model for course purchases"""

    id = models.BigAutoField(primary_key=True)

    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='orders', null=True, blank=True)

    tracking = models.CharField(max_length=100, unique=True, verbose_name=_("Tracking ID"))

    amount = models.DecimalField(max_digits=10, decimal_places=2, verbose_name=_("Amount"))

    currency = models.CharField(max_length=5, choices=Currency.choices, default=Currency.USD,

                               verbose_name=_("Currency"))

    status = models.CharField(max_length=20, default='pending', choices=[

        ('pending', 'Pending'),

        ('processing', 'Processing'),

        ('completed', 'Completed'),

        ('cancelled', 'Cancelled'),

        ('refunded', 'Refunded'),

    ], verbose_name=_("Status"))

    payment_method = models.CharField(max_length=50, blank=True, verbose_name=_("Payment Method"))

    metadata = models.JSONField(default=dict, blank=True, verbose_name=_("Metadata"))

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))

    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    

    class Meta:

        db_table = 'orders'

        verbose_name = _("Order")

        verbose_name_plural = _("Orders")

        ordering = ['-created_at']

    

    def __str__(self):

        return f"Order {self.tracking} - {self.amount} {self.currency}"





class Cart(models.Model):

    """Shopping cart for users"""

    id = models.BigAutoField(primary_key=True)

    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='carts')

    total_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0.00, verbose_name=_("Total Amount"))

    currency = models.CharField(max_length=5, choices=Currency.choices, default=Currency.USD,

                               verbose_name=_("Currency"))

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))

    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    

    class Meta:

        db_table = 'carts'

        verbose_name = _("Cart")

        verbose_name_plural = _("Carts")

        ordering = ['-created_at']

    

    def __str__(self):

        return f"Cart {self.id} - {self.user}"





class CartItem(models.Model):

    """Items in shopping cart"""

    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name='items')

    course = models.ForeignKey('courses.Course', on_delete=models.CASCADE, null=True, blank=True, verbose_name=_("Course"))

    description = models.CharField(max_length=255, verbose_name=_("Description"))

    amount = models.DecimalField(max_digits=10, decimal_places=2, verbose_name=_("Amount"))

    quantity = models.IntegerField(default=1, verbose_name=_("Quantity"))

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))

    

    class Meta:

        db_table = 'cart_items'

        verbose_name = _("Cart Item")

        verbose_name_plural = _("Cart Items")

    

    def __str__(self):

        return f"{self.description} - {self.amount} x {self.quantity}"



# ==================== PAYMENT PROVIDER MODELS ====================

class PaymentProviderModel(models.Model):

    """Complete provider model with all metadata"""

    code = models.CharField(max_length=50, unique=True, verbose_name=_("Provider Code"))

    name = models.CharField(max_length=100, verbose_name=_("Provider Name"))

    category = models.CharField(max_length=20, choices=ProviderCategory.choices,

                               verbose_name=_("Category"))

    

    # Provider metadata

    website = models.URLField(blank=True, verbose_name=_("Website"))

    api_docs = models.URLField(blank=True, verbose_name=_("API Documentation"))

    support_email = models.EmailField(blank=True, verbose_name=_("Support Email"))

    support_phone = models.CharField(max_length=20, blank=True, verbose_name=_("Support Phone"))

    

    # Capabilities

    supports_cards = models.BooleanField(default=False, verbose_name=_("Supports Cards"))

    supports_mobile_money = models.BooleanField(default=False, verbose_name=_("Supports Mobile Money"))

    supports_bank_transfer = models.BooleanField(default=False, verbose_name=_("Supports Bank Transfer"))

    supports_ussd = models.BooleanField(default=False, verbose_name=_("Supports USSD"))

    supports_qr = models.BooleanField(default=False, verbose_name=_("Supports QR"))

    supports_tokenization = models.BooleanField(default=False, verbose_name=_("Supports Tokenization"))

    supports_recurring = models.BooleanField(default=False, verbose_name=_("Supports Recurring Payments"))

    supports_payouts = models.BooleanField(default=False, verbose_name=_("Supports Payouts"))

    supports_refunds = models.BooleanField(default=False, verbose_name=_("Supports Refunds"))

    

    # Regional coverage

    supported_countries = models.JSONField(default=list, verbose_name=_("Supported Countries"))

    headquarters_country = models.CharField(max_length=2, blank=True, 

                                          verbose_name=_("Headquarters Country"))

    

    # Compliance

    pci_dss_compliant = models.BooleanField(default=False, verbose_name=_("PCI DSS Compliant"))

    requires_kyc = models.BooleanField(default=True, verbose_name=_("Requires KYC"))

    

    # Status

    is_active = models.BooleanField(default=True, verbose_name=_("Active"))

    is_recommended = models.BooleanField(default=False, verbose_name=_("Recommended"))

    priority = models.IntegerField(default=0, verbose_name=_("Priority"))

    

    # Description

    description = models.TextField(blank=True, verbose_name=_("Description"))

    setup_instructions = models.TextField(blank=True, verbose_name=_("Setup Instructions"))

    

    # Timestamps

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))

    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    

    class Meta:

        db_table = 'payment_providers'

        verbose_name = _("Payment Provider")

        verbose_name_plural = _("Payment Providers")

        ordering = ['priority', 'name']

    

    def __str__(self):

        return f"{self.name} ({self.category})"

    

    def get_supported_methods(self, country=None):

        """Get supported methods for a country"""

        if country:

            return self.provider_methods.filter(country=country, is_active=True)

        return self.provider_methods.filter(is_active=True)





class ProviderCountryConfig(models.Model):

    """Provider configuration per country"""

    provider = models.ForeignKey(PaymentProviderModel, on_delete=models.CASCADE,

                                related_name='country_configs', verbose_name=_("Provider"))

    country = models.CharField(max_length=2, choices=CountryCode.choices,

                              verbose_name=_("Country"))

    

    # Country-specific settings

    is_active = models.BooleanField(default=False, verbose_name=_("Active"))

    is_sandbox = models.BooleanField(default=True, verbose_name=_("Sandbox Mode"))

    min_amount = models.DecimalField(max_digits=10, decimal_places=2, default=1.00,

                                    verbose_name=_("Minimum Amount"))

    max_amount = models.DecimalField(max_digits=10, decimal_places=2, default=100000.00,

                                    verbose_name=_("Maximum Amount"))

    supported_currencies = models.JSONField(default=list, verbose_name=_("Supported Currencies"))

    supported_methods = models.JSONField(default=list, verbose_name=_("Supported Methods"))

    

    # Fee structure

    fee_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0.00,

                                        verbose_name=_("Fee Percentage"))

    fixed_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0.00,

                                   verbose_name=_("Fixed Fee"))

    tax_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0.00,

                                        verbose_name=_("Tax Percentage"))

    

    # Country-specific endpoints

    api_url = models.URLField(blank=True, verbose_name=_("API URL"))

    webhook_url = models.URLField(blank=True, verbose_name=_("Webhook URL"))

    callback_url = models.URLField(blank=True, verbose_name=_("Callback URL"))

    

    # Country-specific credentials

    api_key = models.CharField(max_length=500, blank=True, verbose_name=_("API Key"))

    secret_key = models.CharField(max_length=500, blank=True, verbose_name=_("Secret Key"))

    merchant_id = models.CharField(max_length=500, blank=True, verbose_name=_("Merchant ID"))

    

    # Settlement

    settlement_days = models.IntegerField(default=1, verbose_name=_("Settlement Days"))

    supports_instant_settlement = models.BooleanField(default=False,

                                                     verbose_name=_("Instant Settlement"))

    

    # Metadata

    metadata = models.JSONField(default=dict, blank=True, verbose_name=_("Metadata"))

    last_sync = models.DateTimeField(null=True, blank=True, verbose_name=_("Last Sync"))

    

    class Meta:

        db_table = 'provider_country_configs'

        verbose_name = _("Provider Country Config")

        verbose_name_plural = _("Provider Country Configs")

        unique_together = ['provider', 'country']

        ordering = ['country', 'provider']

    

    def __str__(self):

        return f"{self.provider.name} - {self.get_country_display()}"

    

    def get_country_name(self):

        """Get country name from code"""

        return dict(CountryCode.choices).get(self.country, self.country)





class ProviderPaymentMethod(models.Model):

    """Which payment methods a provider supports in which countries"""

    provider = models.ForeignKey(PaymentProviderModel, on_delete=models.CASCADE,

                                related_name='payment_methods', verbose_name=_("Provider"))

    country = models.CharField(max_length=2, choices=CountryCode.choices,

                              verbose_name=_("Country"))

    method = models.CharField(max_length=20, choices=PaymentMethod.choices,

                             verbose_name=_("Payment Method"))

    

    # Method-specific config

    is_active = models.BooleanField(default=True, verbose_name=_("Active"))

    requires_phone = models.BooleanField(default=False, verbose_name=_("Requires Phone"))

    requires_bank = models.BooleanField(default=False, verbose_name=_("Requires Bank"))

    requires_ussd_code = models.BooleanField(default=False, verbose_name=_("Requires USSD Code"))

    requires_bvn = models.BooleanField(default=False, verbose_name=_("Requires BVN"))

    

    # Limits

    min_amount = models.DecimalField(max_digits=10, decimal_places=2, default=1.00,

                                    verbose_name=_("Minimum Amount"))

    max_amount = models.DecimalField(max_digits=10, decimal_places=2, default=100000.00,

                                    verbose_name=_("Maximum Amount"))

    daily_limit = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True,

                                     verbose_name=_("Daily Limit"))

    monthly_limit = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True,

                                       verbose_name=_("Monthly Limit"))

    

    # Fees

    fee_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0.00,

                                        verbose_name=_("Fee Percentage"))

    fixed_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0.00,

                                   verbose_name=_("Fixed Fee"))

    

    # Processing

    processing_time = models.CharField(max_length=20, default='instant', choices=[

        ('instant', 'Instant'),

        ('minutes', 'Minutes'),

        ('hours', 'Hours'),

        ('days', 'Days'),

    ], verbose_name=_("Processing Time"))

    

    # Metadata

    metadata = models.JSONField(default=dict, blank=True, verbose_name=_("Metadata"))

    

    class Meta:

        db_table = 'provider_payment_methods'

        verbose_name = _("Provider Payment Method")

        verbose_name_plural = _("Provider Payment Methods")

        unique_together = ['provider', 'country', 'method']

        ordering = ['country', 'provider', 'method']

    

    def __str__(self):

        return f"{self.provider.name} - {self.get_country_display()} - {self.get_method_display()}"





class CountryPaymentLandscape(models.Model):

    """Complete payment landscape for each African country"""

    country_code = models.CharField(max_length=2, choices=CountryCode.choices,

                                   unique=True, verbose_name=_("Country Code"))

    country_name = models.CharField(max_length=100, verbose_name=_("Country Name"))

    

    # Dominant payment methods

    dominant_methods = models.JSONField(default=list, verbose_name=_("Dominant Methods"))

    emerging_methods = models.JSONField(default=list, verbose_name=_("Emerging Methods"))

    

    # Penetration rates

    mobile_money_penetration = models.DecimalField(max_digits=5, decimal_places=2, null=True,

                                                  verbose_name=_("Mobile Money Penetration %"))

    card_penetration = models.DecimalField(max_digits=5, decimal_places=2, null=True,

                                          verbose_name=_("Card Penetration %"))

    bank_account_penetration = models.DecimalField(max_digits=5, decimal_places=2, null=True,

                                                  verbose_name=_("Bank Account Penetration %"))

    internet_penetration = models.DecimalField(max_digits=5, decimal_places=2, null=True,

                                              verbose_name=_("Internet Penetration %"))

    smartphone_penetration = models.DecimalField(max_digits=5, decimal_places=2, null=True,

                                                verbose_name=_("Smartphone Penetration %"))

    

    # Dominant providers

    dominant_mobile_money = models.JSONField(default=list, verbose_name=_("Dominant Mobile Money"))

    dominant_card_networks = models.JSONField(default=list, verbose_name=_("Dominant Card Networks"))

    dominant_banks = models.JSONField(default=list, verbose_name=_("Dominant Banks"))

    popular_gateways = models.JSONField(default=list, verbose_name=_("Popular Gateways"))

    

    # Currency information

    local_currency = models.CharField(max_length=5, choices=Currency.choices,

                                     verbose_name=_("Local Currency"))

    accepts_usd = models.BooleanField(default=False, verbose_name=_("Accepts USD"))

    accepts_eur = models.BooleanField(default=False, verbose_name=_("Accepts EUR"))

    forex_restrictions = models.BooleanField(default=False, verbose_name=_("Forex Restrictions"))

    

    # Regulatory

    central_bank = models.CharField(max_length=100, blank=True, verbose_name=_("Central Bank"))

    requires_psp_license = models.BooleanField(default=True, verbose_name=_("Requires PSP License"))

    tax_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0.0,

                                        verbose_name=_("Tax Percentage"))

    regulatory_body = models.CharField(max_length=100, blank=True, verbose_name=_("Regulatory Body"))

    

    # Recommendations for Hosi Academy

    recommended_providers = models.JSONField(default=list, verbose_name=_("Recommended Providers"))

    fallback_providers = models.JSONField(default=list, verbose_name=_("Fallback Providers"))

    priority_level = models.IntegerField(default=0, verbose_name=_("Priority Level"))

    

    # Statistics

    population = models.IntegerField(null=True, verbose_name=_("Population"))

    gdp_per_capita = models.DecimalField(max_digits=12, decimal_places=2, null=True,

                                        verbose_name=_("GDP Per Capita"))

    estimated_edtech_market = models.DecimalField(max_digits=12, decimal_places=2, null=True,

                                                 verbose_name=_("Estimated EdTech Market (USD)"))

    english_speaking = models.BooleanField(default=False, verbose_name=_("English Speaking"))

    

    # Market notes

    market_notes = models.TextField(blank=True, verbose_name=_("Market Notes"))

    opportunities = models.TextField(blank=True, verbose_name=_("Opportunities"))

    challenges = models.TextField(blank=True, verbose_name=_("Challenges"))

    

    # Timestamps

    last_updated = models.DateTimeField(auto_now=True, verbose_name=_("Last Updated"))

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))

    

    class Meta:

        db_table = 'country_payment_landscapes'

        verbose_name = _("Country Payment Landscape")

        verbose_name_plural = _("Country Payment Landscapes")

        ordering = ['-priority_level', 'country_name']

    

    def __str__(self):

        return f"{self.country_name} - {self.local_currency}"

    

    def get_payment_penetration_summary(self):

        """Get summary of payment penetration"""

        return {

            'mobile_money': self.mobile_money_penetration,

            'cards': self.card_penetration,

            'bank_accounts': self.bank_account_penetration,

            'internet': self.internet_penetration,

        }





class PaymentProviderIntegration(models.Model):

    """Track which providers are integrated and their status"""

    provider = models.ForeignKey(PaymentProviderModel, on_delete=models.CASCADE,

                                related_name='integrations', verbose_name=_("Provider"))

    

    # Integration status

    integration_status = models.CharField(max_length=20, choices=[

        ('not_started', 'Not Started'),

        ('planned', 'Planned'),

        ('in_progress', 'In Progress'),

        ('testing', 'Testing'),

        ('live', 'Live'),

        ('paused', 'Paused'),

        ('deprecated', 'Deprecated'),

    ], default='not_started', verbose_name=_("Integration Status"))

    

    # Implementation details

    implemented_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True,

                                     related_name='implemented_integrations', verbose_name=_("Implemented By"))

    implementation_date = models.DateField(null=True, blank=True, verbose_name=_("Implementation Date"))

    planned_live_date = models.DateField(null=True, blank=True, verbose_name=_("Planned Live Date"))

    

    # Technical details

    adapter_class = models.CharField(max_length=100, blank=True, verbose_name=_("Adapter Class"))

    webhook_url = models.URLField(blank=True, verbose_name=_("Webhook URL"))

    callback_url = models.URLField(blank=True, verbose_name=_("Callback URL"))

    api_version = models.CharField(max_length=20, blank=True, verbose_name=_("API Version"))

    

    # Coverage

    implemented_countries = models.JSONField(default=list, verbose_name=_("Implemented Countries"))

    implemented_methods = models.JSONField(default=list, verbose_name=_("Implemented Methods"))

    

    # Performance metrics

    success_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0.0,

                                      verbose_name=_("Success Rate %"))

    avg_settlement_time = models.IntegerField(default=0, verbose_name=_("Avg Settlement Time (hours)"))

    total_volume = models.DecimalField(max_digits=15, decimal_places=2, default=0.0,

                                      verbose_name=_("Total Volume"))

    total_transactions = models.IntegerField(default=0, verbose_name=_("Total Transactions"))

    

    # Operational

    requires_reconciliation = models.BooleanField(default=True, verbose_name=_("Requires Reconciliation"))

    reconciliation_frequency = models.CharField(max_length=20, default='daily', choices=[

        ('hourly', 'Hourly'),

        ('daily', 'Daily'),

        ('weekly', 'Weekly'),

        ('monthly', 'Monthly'),

    ], verbose_name=_("Reconciliation Frequency"))

    

    # Support

    support_contact = models.EmailField(blank=True, verbose_name=_("Support Contact"))

    escalation_contact = models.EmailField(blank=True, verbose_name=_("Escalation Contact"))

    sla_agreement = models.URLField(blank=True, verbose_name=_("SLA Agreement"))

    

    # Documentation

    integration_docs = models.URLField(blank=True, verbose_name=_("Integration Docs"))

    troubleshooting_guide = models.URLField(blank=True, verbose_name=_("Troubleshooting Guide"))

    

    # Notes

    notes = models.TextField(blank=True, verbose_name=_("Notes"))

    known_issues = models.TextField(blank=True, verbose_name=_("Known Issues"))

    

    # Timestamps

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))

    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    

    class Meta:

        db_table = 'payment_provider_integrations'

        verbose_name = _("Payment Provider Integration")

        verbose_name_plural = _("Payment Provider Integrations")

        ordering = ['integration_status', 'provider']

    

    def __str__(self):

        return f"{self.provider.name} - {self.integration_status}"

    

    def get_implemented_countries_display(self):

        """Get formatted country names"""

        country_names = dict(CountryCode.choices)

        return [country_names.get(code, code) for code in self.implemented_countries]



# ==================== PAYMENT TRANSACTION MODELS ====================

class PaymentTransaction(models.Model):

    """

    Master payment transaction model for all payment providers

    """

    id = models.BigAutoField(primary_key=True)

    

    # User & Order references

    user = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True, related_name='payment_transactions')

    order = models.ForeignKey(Order, on_delete=models.SET_NULL, null=True, blank=True, 

                             related_name='payment_transactions')

    

    # Transaction details

    amount = models.DecimalField(max_digits=12, decimal_places=2, verbose_name=_("Amount"))

    currency = models.CharField(max_length=5, choices=Currency.choices, default=Currency.USD,

                               verbose_name=_("Currency"))

    transaction_type = models.CharField(max_length=20, choices=TransactionType.choices,

                                       default=TransactionType.PURCHASE, verbose_name=_("Transaction Type"))

    

    # Provider details

    provider = models.CharField(max_length=50, choices=PaymentProvider.choices,

                               verbose_name=_("Payment Provider"))

    provider_reference = models.CharField(max_length=255, db_index=True, unique=True,

                                         verbose_name=_("Provider Reference"))

    provider_method = models.CharField(max_length=20, choices=PaymentMethod.choices,
                                      null=True, blank=True, verbose_name=_("Payment Method"))

    # Transaction metadata
    description = models.TextField(null=True, blank=True, verbose_name=_("Description"))

    status = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.PENDING,

                             verbose_name=_("Status"))

    metadata = models.JSONField(default=dict, blank=True, verbose_name=_("Metadata"))

    

    # Webhook & reconciliation

    webhook_received = models.BooleanField(default=False, verbose_name=_("Webhook Received"))

    webhook_processed_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Webhook Processed At"))

    reconciled = models.BooleanField(default=False, verbose_name=_("Reconciled"))

    reconciliation_date = models.DateField(null=True, blank=True, verbose_name=_("Reconciliation Date"))

    

    # Technical details

    ip_address = models.GenericIPAddressField(null=True, blank=True, verbose_name=_("IP Address"))

    user_agent = models.TextField(blank=True, null=True, verbose_name=_("User Agent"))

    callback_url = models.URLField(null=True, blank=True, verbose_name=_("Callback URL"))

    redirect_url = models.URLField(null=True, blank=True, verbose_name=_("Redirect URL"))

    

    # Country information

    country = models.CharField(max_length=2, choices=CountryCode.choices, blank=True,

                              verbose_name=_("Country Code"))

    phone_number = models.CharField(max_length=20, blank=True, null=True, verbose_name=_("Phone Number"))

    # Billing Type info
    is_corporate = models.BooleanField(default=False, verbose_name=_("Corporate Payment"), 
                                     help_text=_("Whether this is a corporate/company payment"))
    
    # Corporate details
    company_name = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Company Name"))
    company_address = models.TextField(blank=True, null=True, verbose_name=_("Company Address"))
    company_email = models.EmailField(blank=True, null=True, verbose_name=_("Company Email"))
    company_phone = models.CharField(max_length=50, blank=True, null=True, verbose_name=_("Company Phone"))
    vat_number = models.CharField(max_length=50, blank=True, null=True, verbose_name=_("VAT/Tax Number"))

    # Individual details
    individual_name = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Individual Name"))
    individual_email = models.EmailField(blank=True, null=True, verbose_name=_("Individual Email"))
    individual_phone = models.CharField(max_length=50, blank=True, null=True, verbose_name=_("Individual Phone"))

    # Related enrollment info
    enrollment_type = models.CharField(
        max_length=20, 
        choices=[
            ('masterclass', 'Masterclass'), 
            ('learnership', 'Learnership'), 
            ('industry', 'Industry Training'), 
            ('custom_selection', 'Custom Selection')
        ], 
        blank=True, null=True, 
        verbose_name=_("Enrollment Type"), 
        help_text=_("Type of enrollment this payment is for")
    )

    

    # Timestamps

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))

    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    completed_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Completed At"))

    

    # Audit fields

    initiated_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True,

                                   related_name='initiated_payments', verbose_name=_("Initiated By"))

    

    # Link to provider config

    provider_config = models.ForeignKey(ProviderCountryConfig, on_delete=models.SET_NULL,

                                       null=True, blank=True, related_name='transactions',

                                       verbose_name=_("Provider Config"))

    

    class Meta:

        db_table = 'payment_transactions'

        verbose_name = _("Payment Transaction")

        verbose_name_plural = _("Payment Transactions")

        ordering = ['-created_at']

    

    def __str__(self):

        return f"{self.provider_reference} - {self.amount} {self.currency}"





class PaymentWebhookLog(models.Model):

    """Log of payment provider webhooks"""

    id = models.BigAutoField(primary_key=True)

    provider = models.CharField(max_length=50, choices=PaymentProvider.choices, verbose_name=_("Provider"))

    event_type = models.CharField(max_length=100, verbose_name=_("Event Type"))

    payload = models.JSONField(default=dict, verbose_name=_("Payload"))

    headers = models.JSONField(default=dict, verbose_name=_("Headers"))

    raw_body = models.TextField(blank=True, verbose_name=_("Raw Body"))

    processed = models.BooleanField(default=False, verbose_name=_("Processed"))

    processing_error = models.TextField(blank=True, verbose_name=_("Processing Error"))

    signature_valid = models.BooleanField(default=True, verbose_name=_("Signature Valid"))

    transaction = models.ForeignKey(PaymentTransaction, on_delete=models.SET_NULL, null=True, blank=True,

                                   related_name='webhook_logs', verbose_name=_("Transaction"))

    provider_config = models.ForeignKey(ProviderCountryConfig, on_delete=models.SET_NULL, null=True, blank=True,

                                       related_name='webhook_logs', verbose_name=_("Provider Config"))

    received_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Received At"))

    processed_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Processed At"))

    

    class Meta:

        db_table = 'payment_webhook_logs'

        verbose_name = _("Payment Webhook Log")

        verbose_name_plural = _("Payment Webhook Logs")

        ordering = ['-received_at']

    

    def __str__(self):

        return f"Webhook {self.provider} - {self.event_type}"





class PaymentRefund(models.Model):

    """Refund records for payments"""

    id = models.BigAutoField(primary_key=True)

    original_transaction = models.ForeignKey(PaymentTransaction, on_delete=models.PROTECT,

                                            related_name='refunds', verbose_name=_("Original Transaction"))

    refund_amount = models.DecimalField(max_digits=10, decimal_places=2, verbose_name=_("Refund Amount"))

    refund_reason = models.TextField(blank=True, verbose_name=_("Refund Reason"))

    refund_reference = models.CharField(max_length=100, unique=True, verbose_name=_("Refund Reference"))

    status = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.PENDING,

                             verbose_name=_("Status"))

    provider_response = models.JSONField(default=dict, blank=True, verbose_name=_("Provider Response"))

    provider_refund_id = models.CharField(max_length=100, blank=True, verbose_name=_("Provider Refund ID"))

    provider_config = models.ForeignKey(ProviderCountryConfig, on_delete=models.SET_NULL, null=True, blank=True,

                                       related_name='refunds', verbose_name=_("Provider Config"))

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))

    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    completed_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Completed At"))

    initiated_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True,

                                   related_name='initiated_refunds', verbose_name=_("Initiated By"))

    

    class Meta:

        db_table = 'payment_refunds'

        verbose_name = _("Payment Refund")

        verbose_name_plural = _("Payment Refunds")

        ordering = ['-created_at']

    

    def __str__(self):

        return f"Refund {self.refund_reference} - {self.refund_amount}"





class PaymentReconciliation(models.Model):

    """Payment reconciliation records"""

    id = models.BigAutoField(primary_key=True)

    reconciliation_date = models.DateField(verbose_name=_("Reconciliation Date"))

    status = models.CharField(max_length=20, default='pending', choices=[

        ('pending', 'Pending'),

        ('in_progress', 'In Progress'),

        ('completed', 'Completed'),

        ('failed', 'Failed'),

    ], verbose_name=_("Status"))

    provider = models.CharField(max_length=50, choices=PaymentProvider.choices, verbose_name=_("Provider"))

    transactions_count = models.IntegerField(default=0, verbose_name=_("Transactions Count"))

    total_amount = models.DecimalField(max_digits=12, decimal_places=2, default=0.00, verbose_name=_("Total Amount"))

    discrepancies = models.IntegerField(default=0, verbose_name=_("Discrepancies"))

    report_file = models.FileField(upload_to='reconciliation_reports/', null=True, blank=True,

                                  verbose_name=_("Report File"))

    notes = models.TextField(blank=True, verbose_name=_("Notes"))

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))

    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    

    class Meta:

        db_table = 'payment_reconciliations'

        verbose_name = _("Payment Reconciliation")

        verbose_name_plural = _("Payment Reconciliations")

        ordering = ['-reconciliation_date']

    

    def __str__(self):

        return f"Reconciliation {self.reconciliation_date} - {self.provider}"





class DepositRecord(models.Model):

    """Deposit records for wallet top-ups"""

    id = models.BigAutoField(primary_key=True)

    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='deposits')

    amount = models.DecimalField(max_digits=10, decimal_places=2, verbose_name=_("Amount"))

    currency = models.CharField(max_length=5, choices=Currency.choices, default=Currency.USD,

                               verbose_name=_("Currency"))

    status = models.CharField(max_length=20, choices=PaymentStatus.choices, default=PaymentStatus.PENDING,

                             verbose_name=_("Status"))

    payment_method = models.CharField(max_length=50, choices=PaymentMethod.choices, verbose_name=_("Payment Method"))

    provider = models.CharField(max_length=50, choices=PaymentProvider.choices, blank=True,

                               verbose_name=_("Provider"))

    provider_reference = models.CharField(max_length=255, blank=True, verbose_name=_("Provider Reference"))

    metadata = models.JSONField(default=dict, blank=True, verbose_name=_("Metadata"))

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))

    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    completed_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Completed At"))

    

    class Meta:

        db_table = 'deposit_records'

        verbose_name = _("Deposit Record")

        verbose_name_plural = _("Deposit Records")

        ordering = ['-created_at']

    

    def __str__(self):

        return f"Deposit {self.id} - {self.amount} {self.currency}"


class PaymentReference(models.Model):
    reference = models.CharField(max_length=50, unique=True, db_index=True, verbose_name=_("Reference Number"), help_text=_("Unique payment reference (e.g., HOSI-MCLASS-20270204-001)"))
    training_type = models.CharField(max_length=50, verbose_name=_("Training Type"), help_text=_("masterclass, learnership, industry_training, custom_selection"))
    training_id = models.IntegerField(verbose_name=_("Training ID"), help_text=_("ID of the training program"))
    training_title = models.CharField(max_length=255, verbose_name=_("Training Title"))
    training_date = models.DateField(null=True, blank=True, verbose_name=_("Training Start Date"), help_text=_("When the training begins (if applicable)"))
    learner_name = models.CharField(max_length=255, verbose_name=_("Learner Name"))
    learner_email = models.EmailField(verbose_name=_("Learner Email"))
    learner_phone = models.CharField(max_length=20, verbose_name=_("Learner Phone"))
    amount = models.DecimalField(max_digits=10, decimal_places=2, verbose_name=_("Amount"))
    currency = models.CharField(max_length=5, choices=Currency.choices, default=Currency.USD, verbose_name=_("Currency"))
    generated_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Generated At"))
    payment_deadline = models.DateTimeField(verbose_name=_("Payment Deadline"), help_text=_("7 working days from generation OR before training start date"))
    status = models.CharField(max_length=20, default='pending', choices=[
        ('pending', 'Pending Payment'),
        ('paid', 'Payment Received'),
        ('verified', 'Payment Verified'),
        ('expired', 'Expired'),
        ('cancelled', 'Cancelled'),
    ], verbose_name=_("Status"))
    company_name = models.CharField(max_length=255, blank=True, verbose_name=_("Company Name"))
    company_registration = models.CharField(max_length=100, blank=True, verbose_name=_("Company Registration Number"))
    company_tax_number = models.CharField(max_length=100, blank=True, verbose_name=_("Tax/VAT Number"))
    company_address = models.TextField(blank=True, verbose_name=_("Company Address"))
    company_postal_code = models.CharField(max_length=20, blank=True, verbose_name=_("Postal Code"))
    billing_contact_name = models.CharField(max_length=255, blank=True, verbose_name=_("Billing Contact Name"))
    billing_contact_email = models.EmailField(blank=True, verbose_name=_("Billing Contact Email"))
    billing_contact_phone = models.CharField(max_length=20, blank=True, verbose_name=_("Billing Contact Phone"))
    metadata = models.JSONField(default=dict, blank=True, verbose_name=_("Metadata"), help_text=_("Additional payment reference data"))
    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))
    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    class Meta:
        db_table = 'payment_references'
        verbose_name = _("Payment Reference")
        verbose_name_plural = _("Payment References")
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['reference']),
            models.Index(fields=['status', 'payment_deadline']),
            models.Index(fields=['learner_email']),
        ]

    def __str__(self):
        return f"{self.reference} - {self.learner_email}"


class AdminRole(models.Model):
    role_type = models.CharField(max_length=50, choices=[
        ('system_admin', 'System Administrator'),
        ('payment_admin', 'Payment Operations Admin'),
        ('marketing_admin', 'Sales & Marketing Admin'),
        ('payment_sales_marketing_admin', 'Unified Payment & Marketing Admin'),
        ('hr_admin', 'HR Admin'),
        ('executive_admin', 'Executive Admin'),
    ], verbose_name=_("Role Type"))
    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='admin_roles', verbose_name=_("User"))
    is_active = models.BooleanField(default=True, verbose_name=_("Active"), help_text=_("Whether this admin role is currently active"))
    permissions = models.JSONField(default=dict, blank=True, verbose_name=_("Custom Permissions"), help_text=_("Additional role-specific permissions"))
    assigned_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Assigned At"))
    assigned_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True, related_name='assigned_admin_roles', verbose_name=_("Assigned By"))
    revoked_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Revoked At"))
    revoked_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True, related_name='revoked_admin_roles', verbose_name=_("Revoked By"))
    revocation_reason = models.TextField(blank=True, verbose_name=_("Revocation Reason"))
    notes = models.TextField(blank=True, verbose_name=_("Notes"))
    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))
    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    class Meta:
        db_table = 'admin_roles'
        verbose_name = _("Admin Role")
        verbose_name_plural = _("Admin Roles")
        unique_together = ['user', 'role_type']
        ordering = ['role_type', 'user']
        indexes = [
            models.Index(fields=['user', 'role_type', 'is_active']),
        ]

    def __str__(self):
        return f"{self.user} - {self.get_role_type_display()}"

    @classmethod
    def is_payment_admin(cls, user):
        """Check if user has payment admin access (includes unified role)"""
        if not user.is_authenticated:
            return False
        if user.is_superuser:
            return True
        return cls.objects.filter(
            user=user,
            is_active=True,
            role_type__in=['payment_admin', 'payment_sales_marketing_admin']
        ).exists()

    @classmethod
    def is_hr_admin(cls, user):
        """Check if user has HR admin access"""
        if not user.is_authenticated:
            return False
        if user.is_superuser:
            return True
        return cls.objects.filter(user=user, role_type='hr_admin', is_active=True).exists()

    @classmethod
    def is_executive_admin(cls, user):
        """Check if user has executive admin access"""
        if not user.is_authenticated:
            return False
        if user.is_superuser:
            return True
        return cls.objects.filter(user=user, role_type='executive_admin', is_active=True).exists()

    @classmethod
    def is_payment_sales_marketing_admin(cls, user):
        """Check if user has unified payment/sales/marketing admin access"""
        if not user.is_authenticated:
            return False
        if user.is_superuser:
            return True
        return cls.objects.filter(
            user=user,
            is_active=True,
            role_type__in=['payment_admin', 'payment_sales_marketing_admin']
        ).exists()

    @classmethod
    def is_system_admin(cls, user):
        """Check if user has system administrator (universal) access"""
        if not user.is_authenticated:
            return False
        if user.is_superuser:
            return True
        return cls.objects.filter(
            user=user,
            is_active=True,
            role_type='system_admin'
        ).exists()

    @classmethod
    def get_admin_role(cls, user, role_type):
        """Get the admin role object for a user and role type"""
        if not user or not user.is_authenticated:
            return None
        if user.is_superuser:
            return None  # Superusers don't need admin role entries
        
        # Support legacy payment_admin role type
        if role_type == 'payment_admin':
            return cls.objects.filter(
                user=user,
                is_active=True,
                role_type__in=['payment_admin', 'payment_sales_marketing_admin']
            ).first()
        
        return cls.objects.filter(user=user, role_type=role_type, is_active=True).first()

    def get_allowed_countries(self):
        """
        Get all countries this admin role has access to.
        Returns all active countries if no specific countries are assigned.
        """
        from apps.localization.models import Country
        country_accesses = self.country_accesses.filter(is_active=True).select_related('country')
        if country_accesses.exists():
            return Country.objects.filter(
                id__in=country_accesses.values_list('country_id', flat=True),
                is_active=True
            )
        # If no specific countries assigned, return all active countries
        return Country.objects.filter(is_active=True)

    def has_country_access(self, country_id):
        """Check if this admin role has access to a specific country"""
        if self.country_accesses.filter(country_id=country_id, is_active=True).exists():
            return True
        # If no countries are assigned, assume access to all
        return not self.country_accesses.exists()

    def get_role_display_name(self):
        """Get human-readable role name"""
        role_display = {
            'payment_admin': 'Payment Admin',
            'payment_sales_marketing_admin': 'Payment, Sales & Marketing Admin',
            'hr_admin': 'HR Admin',
            'executive_admin': 'Executive Admin',
        }
        return role_display.get(self.role_type, self.role_type)

    def get_dashboard_scope(self):
        """Get dashboard scope based on role type"""
        if self.role_type == 'payment_sales_marketing_admin':
            return {
                'payments': True,
                'sales': True,
                'marketing': True,
            }
        elif self.role_type == 'payment_admin':
            # Legacy - also include all for backward compatibility
            return {
                'payments': True,
                'sales': True,
                'marketing': True,
            }
        elif self.role_type == 'hr_admin':
            return {
                'hr': True,
                'instructors': True,
                'payroll': True,
            }
        elif self.role_type == 'executive_admin':
            return {
                'executive': True,
                'all_analytics': True,
            }
        return {}


class AdminCountryAccess(models.Model):
    """
    Many-to-many relationship between AdminRole and Country.
    Allows assigning specific countries to admin roles.
    If no countries are assigned, admin has access to all countries.
    """
    admin_role = models.ForeignKey(
        'payments.AdminRole',
        on_delete=models.CASCADE,
        related_name='country_accesses',
        verbose_name=_("Admin Role")
    )
    country = models.ForeignKey(
        'localization.Country',
        on_delete=models.CASCADE,
        related_name='admin_role_accesses',
        verbose_name=_("Country")
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name=_("Active"),
        help_text=_("Whether this country access is currently active")
    )
    granted_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Granted At"))
    granted_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='granted_country_accesses',
        verbose_name=_("Granted By")
    )
    revoked_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Revoked At"))
    revoked_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='revoked_country_accesses',
        verbose_name=_("Revoked By")
    )
    notes = models.TextField(blank=True, verbose_name=_("Notes"))
    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))
    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    class Meta:
        db_table = 'admin_country_access'
        verbose_name = _("Admin Country Access")
        verbose_name_plural = _("Admin Country Accesses")
        unique_together = ['admin_role', 'country']
        ordering = ['country__name', 'admin_role']
        indexes = [
            models.Index(fields=['admin_role', 'is_active']),
            models.Index(fields=['country', 'is_active']),
        ]

    def __str__(self):
        return f"{self.admin_role} - {self.country.name} ({'Active' if self.is_active else 'Inactive'})"

    def save(self, *args, **kwargs):
        if self.pk is None and not self.granted_by:
            # Setting granted_by on creation if not set
            from django.contrib.auth import get_user_model
            User = get_user_model()
            # Try to get the user who assigned the admin role
            if self.admin_role.assigned_by:
                self.granted_by = self.admin_role.assigned_by
        super().save(*args, **kwargs)


class EnrollmentType(models.TextChoices):
    MASTERCLASS = 'masterclass', 'Masterclass'
    LEARNERSHIP = 'learnership', 'Learnership'
    INDUSTRY_TRAINING = 'industry_training', 'Industry-Based Training'
    ROLE_TRAINING = 'role_training', 'Role-Based Training'
    CUSTOM_SELECTION = 'custom_selection', 'Custom Course Selection'


class EnrollmentStatus(models.TextChoices):
    PENDING_INFO = 'pending_info', 'Pending Information'
    PENDING_PAYMENT = 'pending_payment', 'Pending Payment'
    PAYMENT_PROCESSING = 'payment_processing', 'Payment Processing'
    ENROLLED = 'enrolled', 'Enrolled'
    CANCELLED = 'cancelled', 'Cancelled'
    COMPLETED = 'completed', 'Completed'


class BulkEnrollmentStatus(models.TextChoices):
    DRAFT = 'draft', 'Draft'
    PENDING_PAYMENT = 'pending_payment', 'Pending Payment'
    COMPLETED = 'completed', 'Completed'
    CANCELLED = 'cancelled', 'Cancelled'


class BulkEnrollment(models.Model):
    bulk_code = models.CharField(max_length=50, unique=True, verbose_name=_("Bulk Enrollment Code"))
    enrollment_type = models.CharField(max_length=20, choices=EnrollmentType.choices, verbose_name=_("Enrollment Type"))
    
    # ContentType relation for the training object
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE, limit_choices_to={'model__in': ('masterclass', 'learnershipprogramme', 'aicertscourse', 'offering')})
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey('content_type', 'object_id')
    
    company = models.ForeignKey('organizations.Company', on_delete=models.CASCADE, related_name='bulk_enrollments', verbose_name=_("Company"))
    total_learners = models.PositiveIntegerField(verbose_name=_("Total Learners"))
    total_amount = models.DecimalField(max_digits=12, decimal_places=2, verbose_name=_("Total Amount"))
    currency = models.CharField(max_length=5, default='USD', verbose_name=_("Currency")) # Simplification: use string or Currency.choices if available
    
    status = models.CharField(max_length=20, choices=BulkEnrollmentStatus.choices, default=BulkEnrollmentStatus.DRAFT, verbose_name=_("Status"))
    order = models.ForeignKey(Order, on_delete=models.SET_NULL, null=True, blank=True, related_name='bulk_enrollments', verbose_name=_("Order"))
    
    # Contact info
    contact_name = models.CharField(max_length=255, verbose_name=_("Contact Person Name"))
    contact_email = models.EmailField(max_length=255, verbose_name=_("Contact Person Email"))
    contact_phone = models.CharField(max_length=20, verbose_name=_("Contact Person Phone"))
    
    notes = models.TextField(blank=True, null=True, verbose_name=_("Notes"))
    created_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, related_name='created_bulk_enrollments', verbose_name=_("Created By"))
    
    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))
    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    class Meta:
        db_table = 'bulk_enrollments'
        verbose_name = _("Bulk Enrollment")
        verbose_name_plural = _("Bulk Enrollments")
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['company', 'status']),
            models.Index(fields=['bulk_code']),
            models.Index(fields=['content_type', 'object_id']),
        ]

    def __str__(self):
        return f"{self.bulk_code} - {self.company}"


class Enrollment(models.Model):
    enrollment_id = models.BigAutoField(primary_key=True, verbose_name=_("Enrollment ID"))

    enrollment_type = models.CharField(max_length=20, choices=EnrollmentType.choices, verbose_name=_("Enrollment Type"))

    # ContentType relation
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE, limit_choices_to={'model__in': ('masterclass', 'learnershipprogramme', 'aicertscourse', 'offering')})
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey('content_type', 'object_id')

    enrollment_code = models.CharField(max_length=50, unique=True, verbose_name=_("Enrollment Code"), help_text=_("Unique enrollment reference code"))
    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='enrollments', verbose_name=_("Learner"))
    status = models.CharField(max_length=20, choices=EnrollmentStatus.choices, default=EnrollmentStatus.PENDING_INFO, verbose_name=_("Status"))

    # Student & Instructor linkage
    student_id = models.BigIntegerField(null=True, blank=True, verbose_name=_("Student ID"), help_text=_("Unique student identifier across all enrollment pathways"))
    instructor_id = models.BigIntegerField(null=True, blank=True, verbose_name=_("Instructor ID"), help_text=_("Instructor teaching this course"))

    # Pathway-specific foreign keys (link to specific enrollment pathway tables)
    # Default=0 means "no enrollment" - null allows empty values in DB
    learnership_enrollment_id = models.IntegerField(null=True, blank=True, default=None, verbose_name=_("Learnership Enrollment ID"), help_text=_("FK to learnerships_learnershipenrollment.id"))
    masterclass_enrollment_id = models.IntegerField(null=True, blank=True, default=None, verbose_name=_("Masterclass Enrollment ID"), help_text=_("FK to masterclasses_masterclassenrollment.id"))
    aicerts_enrollment_id = models.IntegerField(null=True, blank=True, default=None, verbose_name=_("AICerts Enrollment ID"), help_text=_("FK to aicerts_enrollments.id"))
    industry_enrollment_id = models.IntegerField(null=True, blank=True, default=None, verbose_name=_("Industry Enrollment ID"), help_text=_("FK to industry_based_training_industrytrainingenrollment.id"))
    
    # Learner details snapshot
    learner_full_name = models.CharField(max_length=255, verbose_name=_("Full Name"))
    learner_email = models.EmailField(max_length=255, verbose_name=_("Email"))
    learner_phone = models.CharField(max_length=20, verbose_name=_("Phone Number"))
    learner_id_number = models.CharField(max_length=50, blank=True, null=True, verbose_name=_("ID/Passport Number"))
    learner_dob = models.DateField(blank=True, null=True, verbose_name=_("Date of Birth"))
    learner_gender = models.CharField(max_length=20, blank=True, null=True, verbose_name=_("Gender"))
    learner_address = models.TextField(blank=True, null=True, verbose_name=_("Address"))
    learner_city = models.CharField(max_length=100, blank=True, null=True, verbose_name=_("City"))
    learner_country = models.CharField(max_length=100, verbose_name=_("Country"))
    learner_postal_code = models.CharField(max_length=20, blank=True, null=True, verbose_name=_("Postal Code"))
    
    # Professional details
    current_occupation = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Current Occupation"))
    education_level = models.CharField(max_length=100, blank=True, null=True, verbose_name=_("Highest Education Level"))
    institution = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Institution/Company"))
    company = models.ForeignKey('organizations.Company', on_delete=models.SET_NULL, null=True, blank=True, related_name='enrollments', verbose_name=_("Company"), help_text=_("Company paying for this enrollment (optional)"))
    
    # Emergency contact
    emergency_contact_name = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Emergency Contact Name"))
    emergency_contact_phone = models.CharField(max_length=20, blank=True, null=True, verbose_name=_("Emergency Contact Phone"))
    emergency_contact_relationship = models.CharField(max_length=50, blank=True, null=True, verbose_name=_("Relationship to Emergency Contact"))
    
    # Requirements
    dietary_requirements = models.TextField(blank=True, null=True, verbose_name=_("Dietary Requirements"), help_text=_("Any dietary restrictions or allergies"))
    accessibility_needs = models.TextField(blank=True, null=True, verbose_name=_("Accessibility Needs"), help_text=_("Any accessibility requirements"))
    additional_notes = models.TextField(blank=True, null=True, verbose_name=_("Additional Notes"))

    # Financials
    enrollment_fee = models.DecimalField(max_digits=12, decimal_places=2, default=0, verbose_name=_("Enrollment Fee"))
    discount_applied = models.DecimalField(max_digits=12, decimal_places=2, default=0, verbose_name=_("Discount Applied"))
    final_amount = models.DecimalField(max_digits=12, decimal_places=2, db_column='final_amount', null=True, blank=True, default=0, verbose_name=_("Total Amount"))
    currency = models.CharField(max_length=5, default='USD', verbose_name=_("Currency"))
    order = models.ForeignKey(Order, on_delete=models.SET_NULL, null=True, blank=True, related_name='enrollments', verbose_name=_("Order"))

    # Employment & Qualifications
    highest_qualification = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Highest Qualification"))
    qualification_institution = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Institution"))
    qualification_year = models.CharField(max_length=10, blank=True, null=True, verbose_name=_("Qualification Year"))
    employer = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Employer"))
    job_title = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Job Title"))
    employment_status = models.CharField(max_length=50, blank=True, null=True, verbose_name=_("Employment Status"))
    monthly_income = models.CharField(max_length=50, blank=True, null=True, verbose_name=_("Monthly Income"))
    existing_skills = models.TextField(blank=True, null=True, verbose_name=_("Existing Skills"))

    # Demographics
    race = models.CharField(max_length=50, blank=True, null=True, verbose_name=_("Race"))
    disability = models.CharField(max_length=10, blank=True, null=True, verbose_name=_("Disability"))
    nationality = models.CharField(max_length=100, blank=True, null=True, verbose_name=_("Nationality"))

    # Next of Kin
    next_of_kin_name = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Next of Kin Name"))
    next_of_kin_phone = models.CharField(max_length=50, blank=True, null=True, verbose_name=_("Next of Kin Phone"))
    next_of_kin_relationship = models.CharField(max_length=100, blank=True, null=True, verbose_name=_("Next of Kin Relationship"))
    next_of_kin_email = models.EmailField(blank=True, null=True, verbose_name=_("Next of Kin Email"))
    next_of_kin_address = models.TextField(blank=True, null=True, verbose_name=_("Next of Kin Address"))

    # Medical & Accessibility
    medical_conditions = models.TextField(blank=True, null=True, verbose_name=_("Medical Conditions"))
    allergies = models.TextField(blank=True, null=True, verbose_name=_("Allergies"))
    medications = models.TextField(blank=True, null=True, verbose_name=_("Medications"))

    # Learning Support
    requires_learning_support = models.CharField(max_length=10, blank=True, null=True, verbose_name=_("Requires Learning Support"))
    learning_support_details = models.TextField(blank=True, null=True, verbose_name=_("Learning Support Details"))
    has_previous_learnership_experience = models.CharField(max_length=10, blank=True, null=True, verbose_name=_("Previous Learnership Experience"))
    previous_learnership_details = models.TextField(blank=True, null=True, verbose_name=_("Previous Learnership Details"))

    # Documentation Checklist
    has_id_copy = models.BooleanField(default=False, verbose_name=_("Has ID Copy"))
    has_qualification_certificates = models.BooleanField(default=False, verbose_name=_("Has Qualification Certificates"))
    has_proof_of_residence = models.BooleanField(default=False, verbose_name=_("Has Proof of Residence"))
    has_cv = models.BooleanField(default=False, verbose_name=_("Has CV"))
    has_motivational_letter = models.BooleanField(default=False, verbose_name=_("Has Motivational Letter"))

    # Funding & Banking
    funding_source = models.CharField(max_length=50, blank=True, null=True, verbose_name=_("Funding Source"))
    company_vat_number = models.CharField(max_length=100, blank=True, null=True, verbose_name=_("Company VAT Number"))
    purchase_order_number = models.CharField(max_length=100, blank=True, null=True, verbose_name=_("Purchase Order Number"))
    requires_debit_order = models.CharField(max_length=10, blank=True, null=True, verbose_name=_("Requires Debit Order"))
    bank_name = models.CharField(max_length=100, blank=True, null=True, verbose_name=_("Bank Name"))
    bank_account_number = models.CharField(max_length=50, blank=True, null=True, verbose_name=_("Bank Account Number"))
    bank_branch_code = models.CharField(max_length=20, blank=True, null=True, verbose_name=_("Bank Branch Code"))
    bank_account_type = models.CharField(max_length=20, blank=True, null=True, verbose_name=_("Bank Account Type"))
    bank_account_holder_name = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Bank Account Holder Name"))

    # Declarations
    data_protection_accepted = models.BooleanField(default=False, verbose_name=_("Data Protection Accepted"))
    certification_declaration_accepted = models.BooleanField(default=False, verbose_name=_("Certification Declaration Accepted"))
    seta_declaration_accepted = models.BooleanField(default=False, verbose_name=_("SETA Declaration Accepted"))
    referral_source = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Referral Source"))

    # Verification Workflow
    prerequisites_verified = models.BooleanField(default=False, verbose_name=_("Prerequisites Verified"))
    verification_notes = models.TextField(blank=True, null=True, verbose_name=_("Verification Notes"))
    verified_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, blank=True, related_name='verified_enrollments', db_column='verified_by_id', verbose_name=_("Verified By"))
    verified_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Verified At"))
    confirmed_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Confirmed At"))
    dropped_out_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Dropped Out At"))

    # Provider
    provider_id = models.BigIntegerField(null=True, blank=True, verbose_name=_("Provider ID"))

    # Metadata
    enrollment_data = models.JSONField(default=dict, blank=True, verbose_name=_("Enrollment Data"))
    ip_address = models.GenericIPAddressField(blank=True, null=True, verbose_name=_("IP Address"))
    user_agent = models.TextField(blank=True, verbose_name=_("User Agent"))

    # Terms
    terms_accepted = models.BooleanField(default=False, verbose_name=_("Terms & Conditions Accepted"))
    terms_accepted_at = models.DateTimeField(blank=True, null=True, verbose_name=_("Terms Accepted At"))

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))
    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))
    enrolled_at = models.DateTimeField(blank=True, null=True, verbose_name=_("Enrolled At"))
    completed_at = models.DateTimeField(blank=True, null=True, verbose_name=_("Completed At"))

    class Meta:
        db_table = 'enrollments'
        verbose_name = _("Enrollment")
        verbose_name_plural = _("Enrollments")
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['company', 'status']),
            models.Index(fields=['enrollment_type', 'status']),
            models.Index(fields=['enrollment_code']),
            models.Index(fields=['content_type', 'object_id']),
            models.Index(fields=['student_id']),
            models.Index(fields=['instructor_id']),
            models.Index(fields=['learnership_enrollment_id']),
            models.Index(fields=['masterclass_enrollment_id']),
            models.Index(fields=['aicerts_enrollment_id']),
            models.Index(fields=['industry_enrollment_id']),
        ]

    def __str__(self):
        return f"{self.enrollment_code} - {self.learner_full_name}"
"""
Django model for African Banks - Comprehensive database for EFT/Bank Transfer payments
"""
from django.db import models
from django.utils.translation import gettext_lazy as _


class AfricanCountry(models.Model):
    """African countries with their payment landscapes"""
    code = models.CharField(max_length=2, unique=True, help_text="ISO 3166-1 alpha-2 country code")
    name = models.CharField(max_length=100)
    currency_code = models.CharField(max_length=3, help_text="ISO 4217 currency code")
    currency_symbol = models.CharField(max_length=5, blank=True)
    is_active = models.BooleanField(default=True)
    priority = models.IntegerField(default=0, help_text="Sort order for dropdown")
    
    class Meta:
        verbose_name = _("African Country")
        verbose_name_plural = _("African Countries")
        ordering = ['priority', 'name']
    
    def __str__(self):
        return f"{self.name} ({self.code})"


class AfricanBank(models.Model):
    """
    Comprehensive database of African banks for EFT/Bank Transfer payments
    Links to payment providers that serve each bank
    """
    country = models.ForeignKey(
        AfricanCountry,
        on_delete=models.CASCADE,
        related_name='banks',
        help_text="Country where bank operates"
    )
    
    # Basic Info
    name = models.CharField(max_length=200)
    code = models.CharField(max_length=50, help_text="Internal bank code (e.g., 'absa', 'kcb')")
    swift_code = models.CharField(max_length=11, blank=True, help_text="SWIFT/BIC code")
    bank_code = models.CharField(max_length=20, blank=True, help_text="Local bank/branch code")
    
    # Payment Provider Integration
    payment_providers = models.ManyToManyField(
        'payments.PaymentProviderModel',
        blank=True,
        related_name='banks',
        help_text="Payment providers that can process transfers from this bank"
    )
    
    # Contact Info
    website = models.URLField(blank=True)
    phone = models.CharField(max_length=50, blank=True)
    email = models.EmailField(blank=True)
    
    # Address
    headquarters = models.CharField(max_length=200, blank=True)
    address_line1 = models.CharField(max_length=200, blank=True)
    address_line2 = models.CharField(max_length=200, blank=True)
    city = models.CharField(max_length=100, blank=True)
    
    # Status
    is_active = models.BooleanField(default=True)
    is_recommended = models.BooleanField(default=False, help_text="Show as recommended option")
    priority = models.IntegerField(default=0, help_text="Sort order within country")

    # Category and Type (for payment providers)
    category = models.CharField(max_length=50, default='commercial_bank', help_text="Bank category (commercial_bank, payment_gateway, mobile_money, etc.)")
    provider_type = models.CharField(max_length=50, default='bank', help_text="Type: bank or payment_provider")
    api_integration_code = models.CharField(max_length=50, blank=True, help_text="API integration code for payment provider")
    supports_card = models.BooleanField(default=False)
    supports_mobile_money = models.BooleanField(default=False)
    supports_eft = models.BooleanField(default=False)
    supports_qr = models.BooleanField(default=False)
    logo_url = models.URLField(blank=True, help_text="Logo URL for the bank/provider")

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = _("African Bank")
        verbose_name_plural = _("African Banks")
        ordering = ['country', 'priority', 'name']
        unique_together = [['country', 'code']]
        indexes = [
            models.Index(fields=['country', 'is_active']),
            models.Index(fields=['country', 'is_recommended']),
            models.Index(fields=['swift_code']),
        ]
    
    def __str__(self):
        return f"{self.name} ({self.country.code})"
    
    def get_full_name(self):
        return f"{self.name} - {self.country.name}"


class BankAccountTemplate(models.Model):
    """
    Templates for bank account creation across African countries.
    """
    
    bank = models.ForeignKey(
        "payments.AfricanBank",
        on_delete=models.CASCADE,
        related_name="account_templates",
        verbose_name=_("Bank"),
    )
    account_number_pattern = models.CharField(
        max_length=100, blank=True,
        help_text="Regex pattern for validation"
    )
    
    # Account Types
    supports_savings = models.BooleanField(default=True)
    supports_current = models.BooleanField(default=True)
    supports_business = models.BooleanField(default=True)
    
    # Transfer Limits
    min_transfer_amount = models.DecimalField(
        max_digits=12, decimal_places=2,
        null=True, blank=True,
        help_text="Minimum transfer amount in local currency"
    )
    max_transfer_amount = models.DecimalField(
        max_digits=12, decimal_places=2,
        null=True, blank=True,
        help_text="Maximum transfer amount per transaction"
    )
    max_daily_amount = models.DecimalField(
        max_digits=12, decimal_places=2,
        null=True, blank=True,
        help_text="Maximum daily transfer limit"
    )
    
    # Fees
    transfer_fee_fixed = models.DecimalField(
        max_digits=10, decimal_places=2,
        default=0.00,
        help_text="Fixed fee per transfer"
    )
    transfer_fee_percentage = models.DecimalField(
        max_digits=5, decimal_places=2,
        default=0.00,
        help_text="Percentage fee of transfer amount"
    )
    
    class Meta:
        verbose_name = _("Bank Account Template")
        verbose_name_plural = _("Bank Account Templates")
    
    def __str__(self):
        return f"Template for {self.bank.name}"


class CompanyBankAccount(models.Model):
    """
    Company's bank account details per country for receiving EFT payments
    Stores HosiTech's actual bank accounts in different African countries
    """
    country = models.ForeignKey(
        AfricanCountry,
        on_delete=models.CASCADE,
        related_name='company_accounts',
        help_text="Country where account is held"
    )
    
    # Bank Information
    bank_name = models.CharField(max_length=200)
    branch_name = models.CharField(max_length=200, blank=True)
    branch_code = models.CharField(max_length=50, blank=True)
    swift_code = models.CharField(max_length=11, blank=True)
    bank_code = models.CharField(max_length=20, blank=True)
    
    # Account Information
    account_number = models.CharField(max_length=50)
    account_name = models.CharField(max_length=200)
    account_type = models.CharField(max_length=50, default='Current Account')
    
    # Currency
    currency = models.CharField(max_length=3, help_text="Account currency (e.g., ZAR, USD)")
    
    # Operational
    is_active = models.BooleanField(default=True)
    is_default = models.BooleanField(default=False, help_text="Default account for this country")
    priority = models.IntegerField(default=0, help_text="Sort order")
    
    # Metadata
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = _("Company Bank Account")
        verbose_name_plural = _("Company Bank Accounts")
        ordering = ['country', 'priority', 'bank_name']
        unique_together = [['country', 'bank_name', 'account_number']]
        indexes = [
            models.Index(fields=['country', 'is_active']),
            models.Index(fields=['country', 'is_default']),
        ]
    
    def __str__(self):
        return f"{self.bank_name} - {self.account_name} ({self.country.code})"
    
    def get_bank_details_dict(self):
        """Return bank details as dict for API response"""
        return {
            'bank_name': self.bank_name,
            'branch_name': self.branch_name,
            'branch_code': self.branch_code,
            'swift_code': self.swift_code,
            'account_number': self.account_number,
            'account_name': self.account_name,
            'account_type': self.account_type,
            'currency': self.currency,
            'country_code': self.country.code,
            'country_name': self.country.name,
        }


# Import admin chat system models
from .models_admin import (
    Administrator,
    ExecutiveCountryAssignment,
    SalesMarketingCountryAssignment,
    AdminChatRelationship,
    SystemAdminChatAccess,
)


# ==================== PAYMENT OTP VERIFICATION ====================

class PaymentOTPVerification(models.Model):
    """
    OTP verification for payment security
    Users must verify email OTP before initiating payment
    """
    email = models.EmailField(db_index=True)
    otp = models.CharField(max_length=6)
    
    # Payment details
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    currency = models.CharField(max_length=3, default='USD')
    country = models.CharField(max_length=2, default='ZA')
    
    # Verification status
    verified = models.BooleanField(default=False)
    is_valid = models.BooleanField(default=True)  # Can be invalidated
    verified_at = models.DateTimeField(null=True, blank=True)
    
    # Payment token (generated after OTP verification)
    payment_token = models.CharField(max_length=64, unique=True, null=True, blank=True)
    
    # Expiry
    expires_at = models.DateTimeField()
    
    # Tracking
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = _("Payment OTP Verification")
        verbose_name_plural = _("Payment OTP Verifications")
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['email', 'verified']),
            models.Index(fields=['payment_token']),
            models.Index(fields=['expires_at']),
        ]
    
    def __str__(self):
        return f"OTP for {self.email} - {'Verified' if self.verified else 'Pending'}"
    
    def is_expired(self):
        """Check if OTP has expired"""
        from django.utils import timezone
        return timezone.now() > self.expires_at
    
    def mark_as_used(self):
        """Mark OTP as used/invalidated"""
        self.is_valid = False
        self.save()


# ==================== CONTACT VERIFICATION OTP ====================

class ContactVerificationOTP(models.Model):
    """
    OTP verification for enrollment form contacts (email + phone).
    Separate from payment OTP — purely for confirming the contact
    details a learner typed are real and reachable.
    """
    CONTACT_TYPE_EMAIL = 'email'
    CONTACT_TYPE_PHONE = 'phone'
    CONTACT_TYPE_CHOICES = [
        (CONTACT_TYPE_EMAIL, 'Email'),
        (CONTACT_TYPE_PHONE, 'Phone'),
    ]

    contact = models.CharField(max_length=255, db_index=True)
    contact_type = models.CharField(max_length=10, choices=CONTACT_TYPE_CHOICES)
    otp = models.CharField(max_length=6)
    verified = models.BooleanField(default=False)
    is_valid = models.BooleanField(default=True)
    expires_at = models.DateTimeField()
    verified_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _("Contact Verification OTP")
        verbose_name_plural = _("Contact Verification OTPs")
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['contact', 'contact_type', 'verified']),
        ]

    def __str__(self):
        return f"{self.contact_type} OTP for {self.contact} – {'✓' if self.verified else '…'}"


# ==================== COUPON SYSTEM ====================

class CouponDiscountType(models.TextChoices):
    PERCENTAGE = 'percentage', 'Percentage Discount'
    FIXED = 'fixed', 'Fixed Amount Discount'
    CAPPED_PERCENTAGE = 'capped_percentage', 'Percentage with Cap'


class CouponPathway(models.TextChoices):
    ALL = 'all', 'All Products'
    MASTERCLASS = 'masterclass', 'Masterclasses'
    LEARNERSHIP = 'learnership', 'Learnerships'
    INDUSTRY_TRAINING = 'industry_training', 'Industry-Based Training'
    AICERTS = 'aicerts', 'AICERTS Courses'
    CUSTOM = 'custom', 'Custom Selection'
    AICERTS_CUSTOM_INDUSTRY = 'aicerts_custom_industry', 'AICERTS + Custom + Industry Training'


class CouponClientType(models.TextChoices):
    ALL = 'all', 'All Clients'
    PUBLIC = 'public', 'Public / Individual'
    CORPORATE = 'corporate', 'Corporate'
    PRIVATE = 'private', 'Private'


class CouponPromotionType(models.TextChoices):
    DISCOUNT = 'discount', 'Discount/Sale'
    FREE_COURSE = 'free_course', 'Free Course'
    BUNDLE = 'bundle', 'Bundle Offer'
    LIMITED_TIME = 'limited_time', 'Limited Time Offer'
    SEASONAL = 'seasonal', 'Seasonal Campaign'
    PARTNERSHIP = 'partnership', 'Partnership Offer'
    REFERRAL = 'referral', 'Referral Program'
    OTHER = 'other', 'Other'


class CouponCode(models.Model):
    """
    Unified promotion + coupon code.
    Every promotion is a coupon — global (no country restriction) or localised.
    Display fields (background_color, icon, etc.) power the promo flyer and strip.
    Functional fields (code, discount_value, valid_until, etc.) power checkout discounts.
    """

    code = models.CharField(max_length=50, unique=True, db_index=True)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)

    # Discount definition
    discount_type = models.CharField(
        max_length=20, choices=CouponDiscountType.choices,
        default=CouponDiscountType.PERCENTAGE)
    discount_value = models.DecimalField(max_digits=10, decimal_places=2,
        help_text='Percentage (0–100) or fixed USD amount')
    max_discount_amount = models.DecimalField(max_digits=10, decimal_places=2,
        null=True, blank=True,
        help_text='Max cap in USD for capped_percentage type')

    # Targeting
    product_pathway = models.CharField(
        max_length=30, choices=CouponPathway.choices,
        default=CouponPathway.ALL)
    country_restriction = models.CharField(
        max_length=2, blank=True,
        help_text='ISO-2 code for single-country coupon validation. Leave blank for all.')
    countries = models.ManyToManyField(
        'localization.Country', blank=True, related_name='coupon_promotions',
        help_text='Countries where this promotion is displayed. Empty = all countries.')
    client_type = models.CharField(
        max_length=20, choices=CouponClientType.choices,
        default=CouponClientType.ALL)
    min_purchase_amount = models.DecimalField(
        max_digits=10, decimal_places=2, default=0,
        help_text='Minimum order amount in USD to apply this coupon')

    # Usage limits
    usage_limit = models.PositiveIntegerField(
        null=True, blank=True,
        help_text='Max total redemptions. Leave blank for unlimited.')
    per_user_limit = models.PositiveIntegerField(
        default=1, help_text='Max redemptions per email address')
    times_used = models.PositiveIntegerField(default=0)

    # Validity
    valid_from = models.DateTimeField()
    valid_until = models.DateTimeField()
    is_active = models.BooleanField(default=True)

    # Promotion display (powers PromoFlyerWidget and CurrentPromotionsSection)
    promotion_type = models.CharField(
        max_length=50, choices=CouponPromotionType.choices,
        default=CouponPromotionType.DISCOUNT)
    background_color = models.CharField(
        max_length=7, default='#172E3D',
        help_text='Banner background color (hex code)')
    text_color = models.CharField(
        max_length=7, default='#FFFFFF',
        help_text='Text color (hex code)')
    icon = models.CharField(
        max_length=50, blank=True,
        help_text='Emoji or icon for promotion (e.g. 🎉, 💰, 🎓)')
    image_url = models.URLField(blank=True, help_text='Optional banner image URL')
    cta_text = models.CharField(
        max_length=100, default='Enroll Now',
        help_text='Call-to-action button text on promo flyer')
    cta_url = models.URLField(blank=True, help_text='Link when user taps the flyer CTA')
    priority = models.IntegerField(default=0, help_text='Higher = shown first (0–100)')
    show_on_onboarding = models.BooleanField(default=True)
    show_on_home = models.BooleanField(default=True)
    show_on_splash = models.BooleanField(default=False)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'users.User', null=True, blank=True,
        on_delete=models.SET_NULL, related_name='coupons_created')

    class Meta:
        verbose_name = _('Coupon Code')
        verbose_name_plural = _('Coupon Codes')
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.code} — {self.name}'

    @property
    def is_currently_valid(self):
        from django.utils import timezone
        now = timezone.now()
        if not self.is_active:
            return False
        if now < self.valid_from or now > self.valid_until:
            return False
        if self.usage_limit and self.times_used >= self.usage_limit:
            return False
        return True

    def compute_discount(self, amount_usd):
        """Return the discount amount in USD for a given order amount."""
        amount = float(amount_usd)
        val = float(self.discount_value)
        if self.discount_type == CouponDiscountType.PERCENTAGE:
            return round(amount * val / 100, 2)
        elif self.discount_type == CouponDiscountType.FIXED:
            return round(min(val, amount), 2)
        elif self.discount_type == CouponDiscountType.CAPPED_PERCENTAGE:
            raw = amount * val / 100
            cap = float(self.max_discount_amount) if self.max_discount_amount else raw
            return round(min(raw, cap), 2)
        return 0.0


class CouponRedemption(models.Model):
    """Audit trail of every coupon use."""

    coupon = models.ForeignKey(
        CouponCode, on_delete=models.PROTECT, related_name='redemptions')
    email = models.EmailField(db_index=True)
    user = models.ForeignKey(
        'users.User', null=True, blank=True,
        on_delete=models.SET_NULL, related_name='coupon_redemptions')
    order = models.ForeignKey(
        'payments.Order', null=True, blank=True,
        on_delete=models.SET_NULL, related_name='coupon_redemptions')
    original_amount = models.DecimalField(max_digits=10, decimal_places=2)
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2)
    final_amount = models.DecimalField(max_digits=10, decimal_places=2)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    redeemed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _('Coupon Redemption')
        verbose_name_plural = _('Coupon Redemptions')
        ordering = ['-redeemed_at']

    def __str__(self):
        return f'{self.coupon.code} by {self.email} on {self.redeemed_at:%Y-%m-%d}'


class AdminRoleRequest(models.Model):
    """
    Model for tracking requests to add new administrators.
    Allows HR/Regional admins to propose new staff members for administrative access.
    """
    ROLE_CHOICES = [
        ('system_admin', _('System Administrator')),
        ('payment_admin', _('Payment Operations Admin')),
        ('marketing_admin', _('Sales & Marketing Admin')),
        ('hr_admin', _('HR Administrator')),
        ('executive_admin', _('Executive Administrator')),
    ]
    
    STATUS_CHOICES = [
        ('pending', _('Pending Review')),
        ('approved', _('Approved')),
        ('rejected', _('Rejected')),
    ]

    requested_by = models.ForeignKey(
        'users.User', 
        on_delete=models.CASCADE, 
        related_name='submitted_role_requests',
        verbose_name=_("Requested By")
    )
    candidate_name = models.CharField(max_length=191, verbose_name=_("Candidate Full Name"))
    candidate_email = models.EmailField(verbose_name=_("Candidate Email"))
    proposed_role = models.CharField(
        max_length=50, 
        choices=ROLE_CHOICES, 
        verbose_name=_("Proposed Role")
    )
    target_country = models.ForeignKey(
        'localization.Country', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        verbose_name=_("Target Country")
    )
    justification = models.TextField(blank=True, verbose_name=_("Justification/Notes"))
    status = models.CharField(
        max_length=20, 
        choices=STATUS_CHOICES, 
        default='pending', 
        verbose_name=_("Status")
    )
    processed_by = models.ForeignKey(
        'users.User', 
        on_delete=models.SET_NULL, 
        null=True, 
        blank=True, 
        related_name='processed_role_requests',
        verbose_name=_("Processed By")
    )
    processed_at = models.DateTimeField(null=True, blank=True, verbose_name=_("Processed At"))
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'payments_adminrolerequest'
        verbose_name = _("Admin Role Request")
        verbose_name_plural = _("Admin Role Requests")
        ordering = ['-created_at']

    def __str__(self):
        return f"Request for {self.candidate_email} ({self.get_proposed_role_display()})"

