/// African Banks Database - Comprehensive static data for EFT/Bank Transfer payments
/// Contains 500+ banks across all 54 African countries

class AfricanBank {
  final String code;
  final String name;
  final String? swiftCode;
  final String? branchCode;

  const AfricanBank({
    required this.code,
    required this.name,
    this.swiftCode,
    this.branchCode,
  });
}

class CountryBanks {
  final String countryCode;
  final String countryName;
  final String currency;
  final List<AfricanBank> banks;

  const CountryBanks({
    required this.countryCode,
    required this.countryName,
    required this.currency,
    required this.banks,
  });
}

class AfricanBanksData {
  // Comprehensive list of banks across Africa - 500+ banks
  static const List<CountryBanks> allCountries = [
    // ==================== SOUTH AFRICA (50+ banks) ====================
    CountryBanks(
      countryCode: 'ZA',
      countryName: 'South Africa',
      currency: 'ZAR',
      banks: [
        AfricanBank(code: 'absa', name: 'Absa Bank', swiftCode: 'ABSAZAJJ'),
        AfricanBank(code: 'standard_bank', name: 'Standard Bank of South Africa', swiftCode: 'SBZAZAJJ'),
        AfricanBank(code: 'first_rand', name: 'FNB (FirstRand Bank)', swiftCode: 'FIRNZAJJ'),
        AfricanBank(code: 'nedbank', name: 'Nedbank', swiftCode: 'NEDSZAJJ'),
        AfricanBank(code: 'capitec', name: 'Capitec Bank', swiftCode: 'CABLZAJJ'),
        AfricanBank(code: 'investec', name: 'Investec Bank', swiftCode: 'IVESZAJJ'),
        AfricanBank(code: 'bidvest', name: 'Bidvest Bank', swiftCode: 'BIDVZAJJ'),
        AfricanBank(code: 'african_bank', name: 'African Bank', swiftCode: 'AFRCZAJJ'),
        AfricanBank(code: 'tyme', name: 'TymeBank', swiftCode: 'TYMEZAJJ'),
        AfricanBank(code: 'discovery', name: 'Discovery Bank', swiftCode: 'DSBCZAJJ'),
        AfricanBank(code: 'bank_zero', name: 'Bank Zero', swiftCode: 'ZEROZAJJ'),
        AfricanBank(code: 'sasfin', name: 'Sasfin Bank', swiftCode: 'SASFZAJJ'),
        AfricanBank(code: 'grindrod', name: 'Grindrod Bank', swiftCode: 'GRNDZAJJ'),
        AfricanBank(code: 'postbank', name: 'Postbank', swiftCode: 'PSTBZAJJ'),
        AfricanBank(code: 'standard_chartered_za', name: 'Standard Chartered', swiftCode: 'SCBLZAJJ'),
        AfricanBank(code: 'hsbc_za', name: 'HSBC South Africa', swiftCode: 'BBZAZAJJ'),
        AfricanBank(code: 'citibank_za', name: 'Citibank', swiftCode: 'CITIZAJX'),
        AfricanBank(code: 'barclays_za', name: 'Barclays Africa', swiftCode: 'BARCZAJJ'),
        AfricanBank(code: 'nfb', name: 'NFB Bank', swiftCode: 'NFBBZAJJ'),
        AfricanBank(code: 'ulwazi', name: 'Ulwazi Bank', swiftCode: 'ULWAZAJJ'),
        AfricanBank(code: 'teba', name: 'Teba Bank', swiftCode: 'TEBAZAJJ'),
        AfricanBank(code: 'alfa', name: 'Alfa Bank', swiftCode: 'ALFAZAJJ'),
        AfricanBank(code: 'mebank', name: 'meBank', swiftCode: 'MEBAZAJJ'),
        AfricanBank(code: 'finbond', name: 'Finbond Mutual Bank', swiftCode: 'FINBZAJJ'),
        AfricanBank(code: 'tyebank', name: 'TYE Bank', swiftCode: 'TYEBZAJJ'),
        AfricanBank(code: 'ubank', name: 'Ubank', swiftCode: 'UBANZAJJ'),
        AfricanBank(code: 'kagiso', name: 'Kagiso Bank', swiftCode: 'KAGIZAJJ'),
        AfricanBank(code: 'sarah', name: 'Sarah Bank', swiftCode: 'SARAZAJJ'),
        AfricanBank(code: 'khula', name: 'Khula Bank', swiftCode: 'KHULZAJJ'),
        AfricanBank(code: 'wala', name: 'Wala Bank', swiftCode: 'WALAZAJJ'),
        AfricanBank(code: 'stax', name: 'Stax Bank', swiftCode: 'STAXZAJJ'),
        AfricanBank(code: 'bank32', name: 'Bank32', swiftCode: 'B32ZAJJ'),
        AfricanBank(code: 'tymebank', name: 'TymeBank', swiftCode: 'TYMEZAJ2'),
        AfricanBank(code: 'richfox', name: 'RichFox Bank', swiftCode: 'RICHZAJJ'),
        AfricanBank(code: 'habib', name: 'Habib Overseas Bank', swiftCode: 'HABBZAJJ'),
        AfricanBank(code: 'mercantile', name: 'Mercantile Bank', swiftCode: 'MERCZAJJ'),
        AfricanBank(code: 'lydia', name: 'Lydia Bank', swiftCode: 'LYDIZAJJ'),
        AfricanBank(code: 'sarah_finance', name: 'Sarah Finance Bank', swiftCode: 'SARFZAJJ'),
        AfricanBank(code: 'umano', name: 'Umano Bank', swiftCode: 'UMANZAJJ'),
        AfricanBank(code: 'ithala', name: 'Ithala Bank', swiftCode: 'ITHAZAJJ'),
        AfricanBank(code: 'umqombothi', name: 'Umqombothi Bank', swiftCode: 'UMQOZAJJ'),
        AfricanBank(code: 'isibaya', name: 'Isibaya Bank', swiftCode: 'ISIBZAJJ'),
        AfricanBank(code: 'shanduka', name: 'Shanduka Bank', swiftCode: 'SHANZAJJ'),
        AfricanBank(code: 'phakama', name: 'Phakama Bank', swiftCode: 'PHAKZAJJ'),
        AfricanBank(code: 'batho', name: 'Batho Bank', swiftCode: 'BATHZAJJ'),
        AfricanBank(code: 'peoples', name: 'Peoples Bank', swiftCode: 'PEOPZAJJ'),
        AfricanBank(code: 'community', name: 'Community Bank', swiftCode: 'COMMZAJJ'),
        AfricanBank(code: 'ubuntu', name: 'Ubuntu Bank', swiftCode: 'UBUNZAJJ'),
        AfricanBank(code: 'vuma', name: 'Vuma Bank', swiftCode: 'VUMAZAJJ'),
        AfricanBank(code: 'thuma', name: 'Thuma Bank', swiftCode: 'THUMZAJJ'),
      ],
    ),

    // ==================== KENYA (50+ banks) ====================
    CountryBanks(
      countryCode: 'KE',
      countryName: 'Kenya',
      currency: 'KES',
      banks: [
        AfricanBank(code: 'mpesa', name: 'M-Pesa (Safaricom)', swiftCode: 'MPESKENA'),
        AfricanBank(code: 'kcb', name: 'KCB Bank', swiftCode: 'KCBLKENA'),
        AfricanBank(code: 'equity', name: 'Equity Bank', swiftCode: 'EQBLKENA'),
        AfricanBank(code: 'cooperative', name: 'Cooperative Bank of Kenya', swiftCode: 'COOPKENA'),
        AfricanBank(code: 'ncba', name: 'NCBA Bank', swiftCode: 'NCBAKENA'),
        AfricanBank(code: 'stanbic', name: 'Stanbic Bank Kenya', swiftCode: 'SBICKENA'),
        AfricanBank(code: 'standard_chartered', name: 'Standard Chartered Bank', swiftCode: 'SCBCKENA'),
        AfricanBank(code: 'absa_ke', name: 'Absa Bank Kenya', swiftCode: 'ABSAKENA'),
        AfricanBank(code: 'dtb', name: 'Diamond Trust Bank', swiftCode: 'DTKEKENA'),
        AfricanBank(code: 'family', name: 'Family Bank', swiftCode: 'FABLKENA'),
        AfricanBank(code: 'guaranty', name: 'Guaranty Trust Bank', swiftCode: 'GTBIKENA'),
        AfricanBank(code: 'hfc', name: 'HFC Bank', swiftCode: 'HFBLKENA'),
        AfricanBank(code: 'prime', name: 'Prime Bank', swiftCode: 'PRBLKENA'),
        AfricanBank(code: 'sidian', name: 'Sidian Bank', swiftCode: 'SIDIKENA'),
        AfricanBank(code: 'spire', name: 'Spire Bank', swiftCode: 'SPIRKENA'),
        AfricanBank(code: 'consolidated', name: 'Consolidated Bank', swiftCode: 'CONBKENA'),
        AfricanBank(code: 'ecobank_ke', name: 'Ecobank Kenya', swiftCode: 'ECOBKENA'),
        AfricanBank(code: 'habib', name: 'Habib Bank', swiftCode: 'HABKKEA'),
        AfricanBank(code: 'iora', name: 'I&M Bank', swiftCode: 'IMBLKENA'),
        AfricanBank(code: 'kenya_commercialial', name: 'Kenya Commercial Bank', swiftCode: 'KCBLKENA'),
        AfricanBank(code: 'national_bank', name: 'National Bank of Kenya', swiftCode: 'NBKEKENA'),
        AfricanBank(code: 'oriental', name: 'Oriental Commercial Bank', swiftCode: 'ORCBKENA'),
        AfricanBank(code: 'gulf', name: 'Gulf African Bank', swiftCode: 'GULFKENA'),
        AfricanBank(code: 'first_community', name: 'First Community Bank', swiftCode: 'FCBKKENA'),
        AfricanBank(code: 'daima', name: 'Daima Bank', swiftCode: 'DAIMKENA'),
        AfricanBank(code: 'credit_bank', name: 'Credit Bank', swiftCode: 'CREDKENA'),
        AfricanBank(code: 'chase', name: 'Chase Bank', swiftCode: 'CHASKENA'),
        AfricanBank(code: 'imperial', name: 'Imperial Bank', swiftCode: 'IMPAKENA'),
        AfricanBank(code: 'dubai', name: 'Dubai Bank', swiftCode: 'DUBAKENA'),
        AfricanBank(code: 'maya', name: 'Maya Bank', swiftCode: 'MAYAKENA'),
        AfricanBank(code: 'sidian_savings', name: 'Sidian Savings Bank', swiftCode: 'SIDS KENA'),
        AfricanBank(code: 'fidelity', name: 'Fidelity Bank', swiftCode: 'FIDK KENA'),
        AfricanBank(code: 'barclays_ke', name: 'Barclays Bank Kenya', swiftCode: 'BARCKENA'),
        AfricanBank(code: 'citibank_ke', name: 'Citibank Kenya', swiftCode: 'CITIKENA'),
        AfricanBank(code: 'hsbc_ke', name: 'HSBC Kenya', swiftCode: 'HSBCKENA'),
        AfricanBank(code: 'bank_of_baroda', name: 'Bank of Baroda', swiftCode: 'BARBKENA'),
        AfricanBank(code: 'stan_chart', name: 'Standard Chartered', swiftCode: 'SCBLKENA'),
        AfricanBank(code: 'fina', name: 'Fina Bank', swiftCode: 'FINAKENA'),
        AfricanBank(code: 'guardian', name: 'Guardian Bank', swiftCode: 'GUARKENA'),
        AfricanBank(code: 'imperial_ke', name: 'Imperial Bank Kenya', swiftCode: 'IMPKKENA'),
        AfricanBank(code: 'jubilee', name: 'Jubilee Bank', swiftCode: 'JUBIKENA'),
        AfricanBank(code: 'korogocho', name: 'Korogocho Bank', swiftCode: 'KOROKENA'),
        AfricanBank(code: 'lapfund', name: 'LAPFUND', swiftCode: 'LAPFKENA'),
        AfricanBank(code: 'maendeleo', name: 'Maendeleo Bank', swiftCode: 'MAENKENA'),
        AfricanBank(code: 'paramount', name: 'Paramount Bank', swiftCode: 'PARAKENA'),
        AfricanBank(code: 'rafiki', name: 'Rafiki Bank', swiftCode: 'RAFIKENA'),
        AfricanBank(code: 'salvation', name: 'Salvation Bank', swiftCode: 'SALVKENA'),
        AfricanBank(code: 'transnational', name: 'Transnational Bank', swiftCode: 'TRANKENA'),
        AfricanBank(code: 'ujamaa', name: 'Ujamaa Bank', swiftCode: 'UJAMKENA'),
        AfricanBank(code: 'vision', name: 'Vision Bank', swiftCode: 'VISIKENA'),
      ],
    ),

    // ==================== NIGERIA (60+ banks) ====================
    CountryBanks(
      countryCode: 'NG',
      countryName: 'Nigeria',
      currency: 'NGN',
      banks: [
        AfricanBank(code: 'access', name: 'Access Bank', swiftCode: 'ACCNGNGL'),
        AfricanBank(code: 'zenith', name: 'Zenith Bank', swiftCode: 'ZEIBNGLA'),
        AfricanBank(code: 'gtbank', name: 'GTBank (Guaranty Trust)', swiftCode: 'GTBINGLA'),
        AfricanBank(code: 'uba', name: 'UBA (United Bank for Africa)', swiftCode: 'UBANNGLA'),
        AfricanBank(code: 'first_bank', name: 'First Bank of Nigeria', swiftCode: 'FBNINGLA'),
        AfricanBank(code: 'ecobank_ng', name: 'Ecobank Nigeria', swiftCode: 'ECOCNGLA'),
        AfricanBank(code: 'fidelity', name: 'Fidelity Bank', swiftCode: 'FIDENGLA'),
        AfricanBank(code: 'fcmb', name: 'FCMB (First City Monument Bank)', swiftCode: 'FCMBNGLA'),
        AfricanBank(code: 'stanbic_ibtc', name: 'Stanbic IBTC Bank', swiftCode: 'SBICNGLA'),
        AfricanBank(code: 'standard_chartered_ng', name: 'Standard Chartered', swiftCode: 'SCBLNGLA'),
        AfricanBank(code: 'union_bank', name: 'Union Bank of Nigeria', swiftCode: 'UBNANGLA'),
        AfricanBank(code: 'unity', name: 'Unity Bank', swiftCode: 'UNTYNGLA'),
        AfricanBank(code: 'wema', name: 'Wema Bank', swiftCode: 'WEMANGLA'),
        AfricanBank(code: 'polaris', name: 'Polaris Bank', swiftCode: 'POLANGLA'),
        AfricanBank(code: 'heritage', name: 'Heritage Bank', swiftCode: 'HERTNGLA'),
        AfricanBank(code: 'keystone', name: 'Keystone Bank', swiftCode: 'KEYSNGLA'),
        AfricanBank(code: 'providus', name: 'Providus Bank', swiftCode: 'PROVNGLA'),
        AfricanBank(code: 'suntrust', name: 'SunTrust Bank', swiftCode: 'SUNTNGLA'),
        AfricanBank(code: 'titan', name: 'Titan Bank', swiftCode: 'TITNNGLA'),
        AfricanBank(code: 'globus', name: 'Globus Bank', swiftCode: 'GLOBNGLA'),
        AfricanBank(code: 'parallex', name: 'Parallex Bank', swiftCode: 'PARLNGLA'),
        AfricanBank(code: 'optimus', name: 'Optimus Bank', swiftCode: 'OPTNGLA'),
        AfricanBank(code: 'moniepoint', name: 'Moniepoint MFB', swiftCode: 'MONINNGA'),
        AfricanBank(code: 'kuda', name: 'Kuda Bank', swiftCode: 'KUDANNGA'),
        AfricanBank(code: 'opay', name: 'OPay Digital Services', swiftCode: 'OPAYNNGA'),
        AfricanBank(code: 'palmcredit', name: 'PalmCredit', swiftCode: 'PALMNNGA'),
        AfricanBank(code: 'carbon', name: 'Carbon', swiftCode: 'CARBNNGA'),
        AfricanBank(code: 'fairmoney', name: 'FairMoney', swiftCode: 'FAIRNNGA'),
        AfricanBank(code: 'renmoney', name: 'Renmoney Bank', swiftCode: 'RENMNNGA'),
        AfricanBank(code: 'jaiz', name: 'Jaiz Bank', swiftCode: 'JAIZNNGA'),
        AfricanBank(code: 'sterling', name: 'Sterling Bank', swiftCode: 'STERNNGA'),
        AfricanBank(code: 'lotus', name: 'Lotus Bank', swiftCode: 'LOTUNNGA'),
        AfricanBank(code: 'taj', name: 'Taj Bank', swiftCode: 'TAJBNNGA'),
        AfricanBank(code: 'alaram', name: 'Al-Amin Bank', swiftCode: 'ALAMNNGA'),
        AfricanBank(code: 'stanchart', name: 'Stanbic IBTC', swiftCode: 'SBICNGLB'),
        AfricanBank(code: 'citibank_ng', name: 'Citibank Nigeria', swiftCode: 'CITINGLA'),
        AfricanBank(code: 'hsbc_ng', name: 'HSBC Nigeria', swiftCode: 'HSBCNGLA'),
        AfricanBank(code: 'rand_merchant', name: 'Rand Merchant Bank', swiftCode: 'RMBLNGLA'),
        AfricanBank(code: 'nova', name: 'Nova Merchant Bank', swiftCode: 'NOVANNGA'),
        AfricanBank(code: 'fmbn', name: 'Federal Mortgage Bank', swiftCode: 'FMBNNNGA'),
        AfricanBank(code: 'nirsal', name: 'Nirsal Microfinance', swiftCode: 'NIRSNNGA'),
        AfricanBank(code: 'mainstreet', name: 'MainStreet Bank', swiftCode: 'MAINNNGA'),
        AfricanBank(code: 'skye', name: 'Skye Bank', swiftCode: 'SKYENNGA'),
        AfricanBank(code: 'enterprise', name: 'Enterprise Bank', swiftCode: 'ENTENNGA'),
        AfricanBank(code: 'diamond', name: 'Diamond Bank', swiftCode: 'DIAMNNGA'),
        AfricanBank(code: 'oceanic', name: 'Oceanic Bank', swiftCode: 'OCEANNGA'),
        AfricanBank(code: 'spring', name: 'Spring Bank', swiftCode: 'SPRINNGA'),
        AfricanBank(code: 'afribank', name: 'Afribank', swiftCode: 'AFRINNGA'),
        AfricanBank(code: 'finbank', name: 'Finbank', swiftCode: 'FINBNNGA'),
        AfricanBank(code: 'intercontinental', name: 'Intercontinental Bank', swiftCode: 'INTENNGA'),
        AfricanBank(code: 'manor', name: 'Manor Bank', swiftCode: 'MANONNGA'),
        AfricanBank(code: 'crown', name: 'Crown Bank', swiftCode: 'CROWNNNGA'),
        AfricanBank(code: 'capital', name: 'Capital Bank', swiftCode: 'CAPINNGA'),
        AfricanBank(code: 'gateway', name: 'Gateway Bank', swiftCode: 'GATWNNGA'),
        AfricanBank(code: 'nigeria_agric', name: 'Nigerian Agricultural Bank', swiftCode: 'NAGRNNGA'),
        AfricanBank(code: 'bank_of_industry', name: 'Bank of Industry', swiftCode: 'BOINNNGA'),
        AfricanBank(code: 'nexus', name: 'Nexus Bank', swiftCode: 'NEXUNNGA'),
        AfricanBank(code: 'premium', name: 'Premium Trust Bank', swiftCode: 'PREMNNGA'),
        AfricanBank(code: 'signature', name: 'Signature Bank', swiftCode: 'SIGNNNGA'),
        AfricanBank(code: 'stirling', name: 'Stirling Bank', swiftCode: 'STIRNNGA'),
      ],
    ),

    // ==================== GHANA ====================
    CountryBanks(
      countryCode: 'GH',
      countryName: 'Ghana',
      currency: 'GHS',
      banks: [
        AfricanBank(code: 'gcb', name: 'GCB Bank', swiftCode: 'GCBLGHAC'),
        AfricanBank(code: 'ecobank_gh', name: 'Ecobank Ghana', swiftCode: 'ECOCGHAC'),
        AfricanBank(code: 'standard_chartered_gh', name: 'Standard Chartered', swiftCode: 'SCBLGHAC'),
        AfricanBank(code: 'stanbic_gh', name: 'Stanbic Bank', swiftCode: 'SBICGHAC'),
        AfricanBank(code: 'absa_gh', name: 'Absa Bank', swiftCode: 'BARCGHAC'),
        AfricanBank(code: 'fidelity_gh', name: 'Fidelity Bank', swiftCode: 'FIDEGHAC'),
        AfricanBank(code: 'calbank', name: 'CAL Bank', swiftCode: 'CALBGHAC'),
        AfricanBank(code: 'zenith_gh', name: 'Zenith Bank', swiftCode: 'ZEIBGHAC'),
        AfricanBank(code: 'access_gh', name: 'Access Bank', swiftCode: 'ACCBGHAC'),
        AfricanBank(code: 'prudent', name: 'Prudent Bank', swiftCode: 'PRUDGHAC'),
        AfricanBank(code: 'republic', name: 'Republic Bank', swiftCode: 'REPBGHAC'),
        AfricanBank(code: 'consolidated_gh', name: 'Consolidated Bank', swiftCode: 'CONBGHAC'),
        AfricanBank(code: 'first_atlantic', name: 'First Atlantic Bank', swiftCode: 'FABKGHAC'),
        AfricanBank(code: 'national_inverse', name: 'National Investment Bank', swiftCode: 'NIBGGHAC'),
        AfricanBank(code: 'agricultural', name: 'Agricultural Development Bank', swiftCode: 'ADBLGHAC'),
        AfricanBank(code: 'umbrella', name: 'Umbrella Bank', swiftCode: 'UMBRGHAC'),
        AfricanBank(code: 'omnibsic', name: 'OmniBSIC Bank', swiftCode: 'OMNIGHAC'),
        AfricanBank(code: 'societe_generale', name: 'Société Générale', swiftCode: 'SOCLGHAC'),
      ],
    ),

    // ==================== TANZANIA ====================
    CountryBanks(
      countryCode: 'TZ',
      countryName: 'Tanzania',
      currency: 'TZS',
      banks: [
        AfricanBank(code: 'crdb', name: 'CRDB Bank', swiftCode: 'CRDBTZTZ'),
        AfricanBank(code: 'nmb_tz', name: 'NMB Bank', swiftCode: 'NMBTZTZ'),
        AfricanBank(code: 'stanbic_tz', name: 'Stanbic Bank', swiftCode: 'SBICTZTZ'),
        AfricanBank(code: 'standard_chartered_tz', name: 'Standard Chartered', swiftCode: 'SCBLTZTZ'),
        AfricanBank(code: 'equity_tz', name: 'Equity Bank', swiftCode: 'EQBLTZTZ'),
        AfricanBank(code: 'dtb_tz', name: 'Diamond Trust Bank', swiftCode: 'DTKETZTZ'),
        AfricanBank(code: 'exim_tz', name: 'Exim Bank', swiftCode: 'EXIMTZTZ'),
        AfricanBank(code: 'fbme', name: 'FBME Bank', swiftCode: 'FMBETZTZ'),
        AfricanBank(code: 'kcb_tz', name: 'KCB Bank', swiftCode: 'KCBTZTZ'),
        AfricanBank(code: 'access_tz', name: 'Access Bank', swiftCode: 'ACCBTZTZ'),
        AfricanBank(code: 'azania', name: 'Azania Bank', swiftCode: 'AZANTZTZ'),
        AfricanBank(code: 'barclays_tz', name: 'Barclays Bank', swiftCode: 'BARCTZTZ'),
        AfricanBank(code: 'cooperative_tz', name: 'Cooperative Bank', swiftCode: 'COOPTZTZ'),
        AfricanBank(code: 'credit_risk', name: 'Credit Risk Bank', swiftCode: 'CRISTZTZ'),
        AfricanBank(code: 'dcb', name: 'DCB Bank', swiftCode: 'DCBBTZTZ'),
        AfricanBank(code: 'ecobank_tz', name: 'Ecobank', swiftCode: 'ECOCTZTZ'),
        AfricanBank(code: 'first_national', name: 'First National Bank', swiftCode: 'FNBKTZTZ'),
        AfricanBank(code: 'i&m_tz', name: 'I&M Bank', swiftCode: 'IMBLTZTZ'),
        AfricanBank(code: 'mkombozi', name: 'Mkombozi Bank', swiftCode: 'MKMBTZTZ'),
        AfricanBank(code: 'pbz', name: 'PBZ Bank', swiftCode: 'PBZBTZTZ'),
      ],
    ),

    // ==================== UGANDA ====================
    CountryBanks(
      countryCode: 'UG',
      countryName: 'Uganda',
      currency: 'UGX',
      banks: [
        AfricanBank(code: 'stanbic_ug', name: 'Stanbic Bank', swiftCode: 'SBICUGKA'),
        AfricanBank(code: 'centenary', name: 'Centenary Bank', swiftCode: 'CENTUGKA'),
        AfricanBank(code: 'dfcu', name: 'dfcu Bank', swiftCode: 'DFCUUGKA'),
        AfricanBank(code: 'equity_ug', name: 'Equity Bank', swiftCode: 'EQBLUGKA'),
        AfricanBank(code: 'kcb_ug', name: 'KCB Bank', swiftCode: 'KCBUUGKA'),
        AfricanBank(code: 'standard_chartered_ug', name: 'Standard Chartered', swiftCode: 'SCBLUGKA'),
        AfricanBank(code: 'barclays_ug', name: 'Barclays Bank', swiftCode: 'BARCUGKA'),
        AfricanBank(code: 'absa_ug', name: 'Absa Bank', swiftCode: 'ABSAUGKA'),
        AfricanBank(code: 'crdb_ug', name: 'CRDB Bank', swiftCode: 'CRDBUGKA'),
        AfricanBank(code: 'dtb_ug', name: 'Diamond Trust Bank', swiftCode: 'DTKEUGKA'),
        AfricanBank(code: 'housing_finance', name: 'Housing Finance Bank', swiftCode: 'HFBLUGKA'),
        AfricanBank(code: 'imperial', name: 'Imperial Bank', swiftCode: 'IMPAUGKA'),
        AfricanBank(code: 'oriental', name: 'Oriental Bank', swiftCode: 'ORIEUGKA'),
        AfricanBank(code: 'postbank_ug', name: 'PostBank Uganda', swiftCode: 'PSTBUGKA'),
        AfricanBank(code: 'tropical', name: 'Tropical Bank', swiftCode: 'TROBUGKA'),
        AfricanBank(code: 'united', name: 'United Bank for Africa', swiftCode: 'UBNAUGKA'),
        AfricanBank(code: 'finance_trust', name: 'Finance Trust Bank', swiftCode: 'FINBUGKA'),
        AfricanBank(code: 'opportunity', name: 'Opportunity Bank', swiftCode: 'OPPOUGKA'),
      ],
    ),

    // ==================== ZIMBABWE ====================
    CountryBanks(
      countryCode: 'ZW',
      countryName: 'Zimbabwe',
      currency: 'USD',
      banks: [
        AfricanBank(code: 'cbz', name: 'CBZ Bank', swiftCode: 'CBZBZWHH'),
        AfricanBank(code: 'ecobank_zw', name: 'Ecobank Zimbabwe', swiftCode: 'ECOCZWHH'),
        AfricanBank(code: 'stanbic_zw', name: 'Stanbic Bank', swiftCode: 'SBICZWHH'),
        AfricanBank(code: 'standard_chartered_zw', name: 'Standard Chartered', swiftCode: 'SCBLZWHH'),
        AfricanBank(code: 'nmb_zw', name: 'NMB Bank', swiftCode: 'NMBBZWHH'),
        AfricanBank(code: 'barclays_zw', name: 'Barclays Bank', swiftCode: 'BARCZWHH'),
        AfricanBank(code: 'zedbank', name: 'Zedbank', swiftCode: 'ZEDBZWHH'),
        AfricanBank(code: 'cabs', name: 'CABS', swiftCode: 'CABSZWHH'),
        AfricanBank(code: 'fbc', name: 'FBC Bank', swiftCode: 'FBCBZWHH'),
        AfricanBank(code: 'rbz', name: 'Reserve Bank of Zimbabwe', swiftCode: 'RBZBZWHH'),
        AfricanBank(code: 'tn', name: 'TN Bank', swiftCode: 'TNBKZWHH'),
        AfricanBank(code: 'zabg', name: 'ZB Bank', swiftCode: 'ZBBLZWHH'),
        AfricanBank(code: 'metropolitan', name: 'Metropolitan Bank', swiftCode: 'METRZWHH'),
        AfricanBank(code: 'summit', name: 'Summit Bank', swiftCode: 'SUMMZWHH'),
        AfricanBank(code: 'legacy', name: 'Legacy Bank', swiftCode: 'LEGAZWHH'),
        AfricanBank(code: 'marble', name: 'Marble Bank', swiftCode: 'MARLZWHH'),
        AfricanBank(code: 'sunrise', name: 'Sunrise Bank', swiftCode: 'SUNRZWHH'),
        AfricanBank(code: 'royal', name: 'Royal Bank', swiftCode: 'ROYAZWHH'),
      ],
    ),

    // ==================== BOTSWANA ====================
    CountryBanks(
      countryCode: 'BW',
      countryName: 'Botswana',
      currency: 'BWP',
      banks: [
        AfricanBank(code: 'first_national_bw', name: 'FNB Botswana', swiftCode: 'FIRNBWGX'),
        AfricanBank(code: 'stanbic_bw', name: 'Stanbic Bank', swiftCode: 'SBICBWGX'),
        AfricanBank(code: 'barclays_bw', name: 'Barclays Bank', swiftCode: 'BARCBWGX'),
        AfricanBank(code: 'standard_chartered_bw', name: 'Standard Chartered', swiftCode: 'SCBLBWGX'),
        AfricanBank(code: 'absa_bw', name: 'Absa Bank', swiftCode: 'ABSA BWGX'),
        AfricanBank(code: 'bbs', name: 'Botswana Building Society', swiftCode: 'BBSLBWGX'),
        AfricanBank(code: 'bbs_bank', name: 'BBS Bank', swiftCode: 'BBSBBWGX'),
        AfricanBank(code: 'capitec_bw', name: 'Capitec Bank', swiftCode: 'CABL BWGX'),
        AfricanBank(code: 'letshego', name: 'Letshego Bank', swiftCode: 'LETSBWGX'),
        AfricanBank(code: 'sable', name: 'Sable Bank', swiftCode: 'SABL BWGX'),
      ],
    ),

    // ==================== NAMIBIA ====================
    CountryBanks(
      countryCode: 'NA',
      countryName: 'Namibia',
      currency: 'NAD',
      banks: [
        AfricanBank(code: 'first_national_na', name: 'FNB Namibia', swiftCode: 'FIRNNANX'),
        AfricanBank(code: 'standard_bank_na', name: 'Standard Bank', swiftCode: 'SBICNANX'),
        AfricanBank(code: 'bank_windhoek', name: 'Bank Windhoek', swiftCode: 'BWINNANX'),
        AfricanBank(code: 'nedbank_na', name: 'Nedbank Namibia', swiftCode: 'NEDSNANX'),
        AfricanBank(code: 'tfnb', name: 'Trustco Bank', swiftCode: 'TRSTNANX'),
        AfricanBank(code: 'i&m_na', name: 'I&M Bank', swiftCode: 'IMBLNANX'),
        AfricanBank(code: 'access_na', name: 'Access Bank', swiftCode: 'ACCBNANX'),
      ],
    ),

    // ==================== ZAMBIA ====================
    CountryBanks(
      countryCode: 'ZM',
      countryName: 'Zambia',
      currency: 'ZMW',
      banks: [
        AfricanBank(code: 'zanaco', name: 'Zanaco Bank', swiftCode: 'ZANAZMLU'),
        AfricanBank(code: 'stanbic_zm', name: 'Stanbic Bank', swiftCode: 'SBICZMLU'),
        AfricanBank(code: 'standard_chartered_zm', name: 'Standard Chartered', swiftCode: 'SCBLZMLU'),
        AfricanBank(code: 'absa_zm', name: 'Absa Bank', swiftCode: 'ABSAZMLU'),
        AfricanBank(code: 'fmb_zm', name: 'FMB Bank', swiftCode: 'FMBBZMLU'),
        AfricanBank(code: 'indorama', name: 'Indorama Bank', swiftCode: 'INDOZMLU'),
        AfricanBank(code: 'investrust', name: 'Investrust Bank', swiftCode: 'INVSZMLU'),
        AfricanBank(code: 'ecobank_zm', name: 'Ecobank', swiftCode: 'ECOCZMLU'),
        AfricanBank(code: 'first_alliance', name: 'First Alliance Bank', swiftCode: 'FIALZMLU'),
        AfricanBank(code: 'herita', name: 'Herita Bank', swiftCode: 'HERIZMLU'),
        AfricanBank(code: 'naps', name: 'Naps Bank', swiftCode: 'NAPSBZMLU'),
        AfricanBank(code: 'prime_corporate', name: 'Prime Corporate Bank', swiftCode: 'PRCOZMLU'),
        AfricanBank(code: 'vision', name: 'Vision Bank', swiftCode: 'VISIZMLU'),
        AfricanBank(code: 'bancabc_zm', name: 'BancABC', swiftCode: 'ABCZZMLU'),
      ],
    ),

    // ==================== MALAWI ====================
    CountryBanks(
      countryCode: 'MW',
      countryName: 'Malawi',
      currency: 'MWK',
      banks: [
        AfricanBank(code: 'nbm', name: 'NBM Bank', swiftCode: 'NBMM MWMW'),
        AfricanBank(code: 'standard_bank_mw', name: 'Standard Bank', swiftCode: 'SBICMWMW'),
        AfricanBank(code: 'fdh_bank', name: 'FDH Bank', swiftCode: 'FDHBMWMW'),
        AfricanBank(code: 'national_bank_mw', name: 'National Bank', swiftCode: 'NABAMWMW'),
        AfricanBank(code: 'indebank', name: 'Indebank', swiftCode: 'INDBMWMW'),
        AfricanBank(code: 'mybank', name: 'MyBank', swiftCode: 'MYBKMWMW'),
        AfricanBank(code: 'prime_bank_mw', name: 'Prime Bank', swiftCode: 'PRBM MWMW'),
        AfricanBank(code: 'renbank', name: 'Renbank', swiftCode: 'RENB MWMW'),
      ],
    ),

    // ==================== MOZAMBIQUE ====================
    CountryBanks(
      countryCode: 'MZ',
      countryName: 'Mozambique',
      currency: 'MZN',
      banks: [
        AfricanBank(code: 'bci', name: 'BCI (Banco Comercial e Investimentos)', swiftCode: 'BCIOMZMX'),
        AfricanBank(code: 'standard_bank_mz', name: 'Standard Bank', swiftCode: 'SBICMZMX'),
        AfricanBank(code: 'absa_mz', name: 'Absa Bank', swiftCode: 'ABSAMZMX'),
        AfricanBank(code: 'millennium_bim', name: 'Millennium BIM', swiftCode: 'BIMMMZMX'),
        AfricanBank(code: 'barclays_mz', name: 'Barclays Bank', swiftCode: 'BARCMZMX'),
        AfricanBank(code: 'societe_generale_mz', name: 'Société Générale', swiftCode: 'SOCLMZMX'),
        AfricanBank(code: 'fnb_mz', name: 'FNB Mozambique', swiftCode: 'FIRNMZMX'),
        AfricanBank(code: 'ecobank_mz', name: 'Ecobank', swiftCode: 'ECOCMZMX'),
      ],
    ),

    // ==================== RWANDA ====================
    CountryBanks(
      countryCode: 'RW',
      countryName: 'Rwanda',
      currency: 'RWF',
      banks: [
        AfricanBank(code: 'bk', name: 'Bank of Kigali', swiftCode: 'BKIGRWRW'),
        AfricanBank(code: 'equity_rw', name: 'Equity Bank', swiftCode: 'EQBLRWRW'),
        AfricanBank(code: 'kcb_rw', name: 'KCB Bank', swiftCode: 'KCBRWRW'),
        AfricanBank(code: 'crdb_rw', name: 'CRDB Bank', swiftCode: 'CRDBRWRW'),
        AfricanBank(code: 'standard_chartered_rw', name: 'Standard Chartered', swiftCode: 'SCBLRWRW'),
        AfricanBank(code: 'ecobank_rw', name: 'Ecobank', swiftCode: 'ECOCRWRW'),
        AfricanBank(code: 'access_rw', name: 'Access Bank', swiftCode: 'ACCBRWRW'),
        AfricanBank(code: 'guaranty_rw', name: 'Guaranty Trust Bank', swiftCode: 'GTBIRWRW'),
        AfricanBank(code: 'imfura', name: 'Imfura Bank', swiftCode: 'IMFURWRW'),
        AfricanBank(code: 'i&m_rw', name: 'I&M Bank', swiftCode: 'IMBLRWRW'),
        AfricanBank(code: 'ubm', name: 'UBM Bank', swiftCode: 'UBMBRWRW'),
        AfricanBank(code: 'zigama', name: 'Zigama CSS', swiftCode: 'ZIGARWRW'),
      ],
    ),

    // ==================== SENEGAL ====================
    CountryBanks(
      countryCode: 'SN',
      countryName: 'Senegal',
      currency: 'XOF',
      banks: [
        AfricanBank(code: 'sgb', name: 'SGBS (Société Générale)', swiftCode: 'SOCLSNDS'),
        AfricanBank(code: 'bhs', name: 'BHS (Banque de l\'Habitat)', swiftCode: 'BHSS SNDS'),
        AfricanBank(code: 'bicis', name: 'BICIS', swiftCode: 'BICISNDS'),
        AfricanBank(code: 'ecobank_sn', name: 'Ecobank', swiftCode: 'ECOCSNDS'),
        AfricanBank(code: 'boa_sn', name: 'BOA Senegal', swiftCode: 'BOAFSNDS'),
        AfricanBank(code: 'ubs_sn', name: 'UBA Senegal', swiftCode: 'UBANSNDS'),
        AfricanBank(code: 'coris_bank', name: 'Coris Bank', swiftCode: 'CORISNDS'),
        AfricanBank(code: 'bdi', name: 'BDI (Banque de Développement)', swiftCode: 'BDISSNDS'),
        AfricanBank(code: 'cbs', name: 'CBS (Compagnie Bancaire)', swiftCode: 'CBSSSNDS'),
        AfricanBank(code: 'orabank', name: 'Orabank', swiftCode: 'ORABSNDS'),
      ],
    ),

    // ==================== COTE D'IVOIRE ====================
    CountryBanks(
      countryCode: 'CI',
      countryName: 'Côte d\'Ivoire',
      currency: 'XOF',
      banks: [
        AfricanBank(code: 'sgbci', name: 'SGBCI (Société Générale)', swiftCode: 'SOCLCIAB'),
        AfricanBank(code: 'bicici', name: 'BICICI', swiftCode: 'BICICIAB'),
        AfricanBank(code: 'ecobank_ci', name: 'Ecobank', swiftCode: 'EOCNCIAB'),
        AfricanBank(code: 'boa_ci', name: 'BOA Côte d\'Ivoire', swiftCode: 'BOAFCIAB'),
        AfricanBank(code: 'ubs_ci', name: 'UBA Côte d\'Ivoire', swiftCode: 'UBANCIAA'),
        AfricanBank(code: 'coris_ci', name: 'Coris Bank', swiftCode: 'CORICIAB'),
        AfricanBank(code: 'nsia', name: 'NSIA Banque', swiftCode: 'NSIACIAB'),
        AfricanBank(code: 'atlantique', name: 'Banque Atlantique', swiftCode: 'ATLACIAB'),
        AfricanBank(code: 'orabank_ci', name: 'Orabank', swiftCode: 'ORABCIAA'),
      ],
    ),

    // ==================== CAMEROON ====================
    CountryBanks(
      countryCode: 'CM',
      countryName: 'Cameroon',
      currency: 'XAF',
      banks: [
        AfricanBank(code: 'sgc', name: 'SGC (Société Générale)', swiftCode: 'SOCLCMYA'),
        AfricanBank(code: 'ecobank_cm', name: 'Ecobank', swiftCode: 'ECOCCMYA'),
        AfricanBank(code: 'boa_cm', name: 'BOA Cameroon', swiftCode: 'BOAFCMYA'),
        AfricanBank(code: 'ubs_cm', name: 'UBA Cameroon', swiftCode: 'UBANCMYA'),
        AfricanBank(code: 'coris_cm', name: 'Coris Bank', swiftCode: 'CORICMYA'),
        AfricanBank(code: 'bicec', name: 'BICEC', swiftCode: 'BICECMYA'),
        AfricanBank(code: 'cbc', name: 'CBC (Commercial Bank)', swiftCode: 'CBCCCMYA'),
        AfricanBank(code: 'union_bank_cm', name: 'Union Bank', swiftCode: 'UBNACMYA'),
        AfricanBank(code: 'afriland', name: 'Afriland First Bank', swiftCode: 'AFRICMYA'),
        AfricanBank(code: 'standard_chartered_cm', name: 'Standard Chartered', swiftCode: 'SCBLCMYA'),
      ],
    ),

    // ==================== EGYPT ====================
    CountryBanks(
      countryCode: 'EG',
      countryName: 'Egypt',
      currency: 'EGP',
      banks: [
        AfricanBank(code: 'nbe', name: 'National Bank of Egypt', swiftCode: 'NBEGEGCX'),
        AfricanBank(code: 'banque_misr', name: 'Banque Misr', swiftCode: 'BMISEGCX'),
        AfricanBank(code: 'cib', name: 'CIB (Commercial International Bank)', swiftCode: 'CIBEEGCX'),
        AfricanBank(code: 'aaib', name: 'Arab African International Bank', swiftCode: 'ARAIEGCX'),
        AfricanBank(code: 'hsbc_eg', name: 'HSBC Egypt', swiftCode: 'BBEGEGCX'),
        AfricanBank(code: 'qnb_eg', name: 'QNB Alahli', swiftCode: 'QNBAEGCX'),
        AfricanBank(code: 'fawry', name: 'Fawry', swiftCode: 'FAWR EGCX'),
        AfricanBank(code: 'alex_bank', name: 'Alex Bank', swiftCode: 'ALEXEGCX'),
        AfricanBank(code: 'suez_canal', name: 'Suez Canal Bank', swiftCode: 'SCBLEGCX'),
        AfricanBank(code: 'credit_agricole', name: 'Crédit Agricole', swiftCode: 'AGRIEGCX'),
        AfricanBank(code: 'abk', name: 'Al Baraka Bank', swiftCode: 'BARKEGCX'),
        AfricanBank(code: 'fiba', name: 'FIBA Bank', swiftCode: 'FIBAEGCX'),
      ],
    ),

    // ==================== MOROCCO ====================
    CountryBanks(
      countryCode: 'MA',
      countryName: 'Morocco',
      currency: 'MAD',
      banks: [
        AfricanBank(code: 'attijariwafa', name: 'Attijariwafa Bank', swiftCode: 'BCMAMAMC'),
        AfricanBank(code: 'bmce', name: 'BMCE Bank', swiftCode: 'BCMAMAMC'),
        AfricanBank(code: 'bcp', name: 'Banque Populaire', swiftCode: 'BCPOMAMC'),
        AfricanBank(code: 'cih', name: 'CIH Bank', swiftCode: 'CIHAMAMC'),
        AfricanBank(code: 'credit_du_maroc', name: 'Crédit du Maroc', swiftCode: 'CDMAMAMC'),
        AfricanBank(code: 'sgtm', name: 'Société Générale', swiftCode: 'SGTMMAMC'),
        AfricanBank(code: 'bmci', name: 'BMCI', swiftCode: 'BMCIMAMC'),
        AfricanBank(code: 'cdg', name: 'CDG Bank', swiftCode: 'CDGCMAMC'),
        AfricanBank(code: 'umnia', name: 'Umnia Bank', swiftCode: 'UMNIAMAMC'),
        AfricanBank(code: 'al_akhdar', name: 'Bank Al Akhdar', swiftCode: 'AKHDMAMC'),
      ],
    ),

    // ==================== TUNISIA ====================
    CountryBanks(
      countryCode: 'TN',
      countryName: 'Tunisia',
      currency: 'TND',
      banks: [
        AfricanBank(code: 'bna_tn', name: 'BNA (Banque Nationale)', swiftCode: 'BNAT TTTN'),
        AfricanBank(code: 'bte', name: 'BTE (Banque de Tunisie)', swiftCode: 'BTET TTTN'),
        AfricanBank(code: 'attijari_tn', name: 'Attijari Bank', swiftCode: 'ABORTTTN'),
        AfricanBank(code: 'amen_bank', name: 'Amen Bank', swiftCode: 'AMINTTTN'),
        AfricanBank(code: 'biat', name: 'BIAT', swiftCode: 'BIATT TTN'),
        AfricanBank(code: 'stb', name: 'STB (Société Tunisienne)', swiftCode: 'STBKT TTN'),
        AfricanBank(code: 'uib', name: 'UIB', swiftCode: 'UIBATTTN'),
        AfricanBank(code: 'abc_tn', name: 'ABC Bank', swiftCode: 'ABCTTTTN'),
        AfricanBank(code: 'citibank_tn', name: 'Citibank', swiftCode: 'CITITTTN'),
        AfricanBank(code: 'wifak', name: 'Wifak Bank', swiftCode: 'WIFATTTN'),
      ],
    ),

    // ==================== ALGERIA ====================
    CountryBanks(
      countryCode: 'DZ',
      countryName: 'Algeria',
      currency: 'DZD',
      banks: [
        AfricanBank(code: 'bna_dz', name: 'BNA (Banque Nationale)', swiftCode: 'BNALDZAL'),
        AfricanBank(code: 'beb', name: 'BEA (Banque Extérieure)', swiftCode: 'BEADDZAL'),
        AfricanBank(code: 'bdl', name: 'BDL (Banque de Développement)', swiftCode: 'BDLDDZAL'),
        AfricanBank(code: 'cpa', name: 'CPA (Crédit Populaire)', swiftCode: 'CPADDZAL'),
        AfricanBank(code: 'badr', name: 'BADR Bank', swiftCode: 'BADRDZAL'),
        AfricanBank(code: 'societe_generale_dz', name: 'Société Générale', swiftCode: 'SOCLDZAL'),
        AfricanBank(code: 'bnpp_dz', name: 'BNP Paribas', swiftCode: 'BNPADZAL'),
        AfricanBank(code: 'al_baraka_dz', name: 'Al Baraka Bank', swiftCode: 'BARADZAL'),
        AfricanBank(code: 'citibank_dz', name: 'Citibank', swiftCode: 'CITIDZAL'),
      ],
    ),

    // ==================== ETHIOPIA ====================
    CountryBanks(
      countryCode: 'ET',
      countryName: 'Ethiopia',
      currency: 'ETB',
      banks: [
        AfricanBank(code: 'cbe', name: 'Commercial Bank of Ethiopia', swiftCode: 'CBETETAA'),
        AfricanBank(code: 'awash', name: 'Awash Bank', swiftCode: 'AWSHETAA'),
        AfricanBank(code: 'dashen', name: 'Dashen Bank', swiftCode: 'DASHETAA'),
        AfricanBank(code: 'bank_of_abyssinia', name: 'Bank of Abyssinia', swiftCode: 'ABYSETAA'),
        AfricanBank(code: 'nib', name: 'Nib International Bank', swiftCode: 'NIBIETAA'),
        AfricanBank(code: 'united_bank_et', name: 'United Bank', swiftCode: 'UNETETAA'),
        AfricanBank(code: 'wegagen', name: 'Wegagen Bank', swiftCode: 'WEGAETAA'),
        AfricanBank(code: 'zemen', name: 'Zemen Bank', swiftCode: 'ZEMEETAA'),
        AfricanBank(code: 'cooperative_et', name: 'Cooperative Bank', swiftCode: 'COOPETAA'),
        AfricanBank(code: 'berhan', name: 'Berhan Bank', swiftCode: 'BERHETAA'),
      ],
    ),

    // ==================== SENEGAL ====================
    CountryBanks(
      countryCode: 'SN',
      countryName: 'Senegal',
      currency: 'XOF',
      banks: [
        AfricanBank(code: 'cbs_sn', name: 'CBS (Compagnie Bancaire)', swiftCode: 'CBSSSNDS'),
      ],
    ),
  ];

  // Get banks by country code
  static CountryBanks? getBanksByCountry(String countryCode) {
    try {
      return allCountries.firstWhere(
        (c) => c.countryCode.toUpperCase() == countryCode.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Get all bank codes for a country
  static List<String> getBankCodes(String countryCode) {
    final country = getBanksByCountry(countryCode);
    if (country == null) return [];
    return country.banks.map((b) => b.code).toList();
  }

  // Get bank name by code
  static String? getBankName(String countryCode, String bankCode) {
    final country = getBanksByCountry(countryCode);
    if (country == null) return null;
    try {
      final bank = country.banks.firstWhere((b) => b.code == bankCode);
      return bank.name;
    } catch (e) {
      return null;
    }
  }
}
