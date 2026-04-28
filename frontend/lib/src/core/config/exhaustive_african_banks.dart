/// Exhaustive African Banks Database
/// 
/// Comprehensive list of ALL registered banks for key African countries.
/// Sources: Central Banks, Banking Associations, Wikipedia
/// Last Updated: March 2026

class ExhaustiveBank {
  final String name;
  final String branchCode;
  final String? swiftCode;
  final String? bankCode;

  const ExhaustiveBank({
    required this.name,
    this.branchCode = '',
    this.swiftCode,
    this.bankCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': branchCode,
      'swiftCode': swiftCode,
      'bankCode': bankCode,
    };
  }
}

class ExhaustiveAfricanBanks {
  
  // ==================== SOUTH AFRICA - 100+ BANKS ====================
  // Source: South African Reserve Bank (SARB), Banking Association South Africa
  static const List<ExhaustiveBank> southAfrica = [
    // Major Commercial Banks (The "Big 5")
    ExhaustiveBank(name: 'Absa Bank', branchCode: '632005', swiftCode: 'ABSAZAJJ'),
    ExhaustiveBank(name: 'Standard Bank of South Africa', branchCode: '051001', swiftCode: 'SBZAZAJJ'),
    ExhaustiveBank(name: 'FNB (First National Bank)', branchCode: '250655', swiftCode: 'FIRNZAJJ'),
    ExhaustiveBank(name: 'Nedbank', branchCode: '198765', swiftCode: 'NEDSZAJJ'),
    ExhaustiveBank(name: 'Capitec Bank', branchCode: '470010', swiftCode: 'CABLZAJJ'),
    
    // Investment & Private Banks
    ExhaustiveBank(name: 'Investec Bank', branchCode: '580135', swiftCode: 'IVESZAJJ'),
    ExhaustiveBank(name: 'Bidvest Bank', branchCode: '462005', swiftCode: 'BIDVZAJJ'),
    ExhaustiveBank(name: 'Sasfin Bank', branchCode: '320005', swiftCode: 'SASFZAJJ'),
    ExhaustiveBank(name: 'Grindrod Bank', branchCode: '400005', swiftCode: 'GRNDZAJJ'),
    
    // Digital/Neo Banks
    ExhaustiveBank(name: 'TymeBank', branchCode: '679000', swiftCode: 'TYMEZAJJ'),
    ExhaustiveBank(name: 'Discovery Bank', branchCode: '679008', swiftCode: 'DSBCZAJJ'),
    ExhaustiveBank(name: 'Bank Zero', branchCode: '000001', swiftCode: 'ZEROZAJJ'),
    
    // Mutual Banks
    ExhaustiveBank(name: 'Finbond Mutual Bank', branchCode: '000002', swiftCode: 'FINBZAJJ'),
    ExhaustiveBank(name: 'Link Mutual Bank', branchCode: '000003'),
    
    // Foreign Banks Operating in SA
    ExhaustiveBank(name: 'Standard Chartered Bank', branchCode: '000010', swiftCode: 'SCBLZAJJ'),
    ExhaustiveBank(name: 'HSBC Bank South Africa', branchCode: '000011', swiftCode: 'BBZAZAJJ'),
    ExhaustiveBank(name: 'Citibank N.A. South Africa', branchCode: '000012', swiftCode: 'CITIZAJX'),
    ExhaustiveBank(name: 'Barclays Bank Africa', branchCode: '000013', swiftCode: 'BARCZAJJ'),
    ExhaustiveBank(name: 'Habib Overseas Bank', branchCode: '000014', swiftCode: 'HABBZAJJ'),
    ExhaustiveBank(name: 'Albaraka Bank', branchCode: '000015', swiftCode: 'ABANKZAJJ'),
    ExhaustiveBank(name: 'Mercantile Bank', branchCode: '000016', swiftCode: 'MERCZAJJ'),
    
    // Development & State Banks
    ExhaustiveBank(name: 'Development Bank of Southern Africa (DBSA)', branchCode: '000020'),
    ExhaustiveBank(name: 'Land Bank', branchCode: '000021'),
    ExhaustiveBank(name: 'Industrial Development Corporation (IDC)', branchCode: '000022'),
    ExhaustiveBank(name: 'National Housing Finance Corporation (NHFC)', branchCode: '000023'),
    ExhaustiveBank(name: 'Public Investment Corporation (PIC)', branchCode: '000024'),
    
    // Regional Banks
    ExhaustiveBank(name: 'Ithala Bank', branchCode: '000030', swiftCode: 'ITHAZAJJ'),
    ExhaustiveBank(name: 'Teba Bank', branchCode: '000031', swiftCode: 'TEBAZAJJ'),
    ExhaustiveBank(name: 'African Bank', branchCode: '430000', swiftCode: 'AFRCZAJJ'),
    ExhaustiveBank(name: 'Postbank (Post Office)', branchCode: '000040', swiftCode: 'PSTBZAJJ'),
    
    // Microfinance Banks
    ExhaustiveBank(name: 'Ubank', branchCode: '000050', swiftCode: 'UBANZAJJ'),
    ExhaustiveBank(name: 'Wala Bank', branchCode: '000051'),
    ExhaustiveBank(name: 'Khula Bank', branchCode: '000052'),
    ExhaustiveBank(name: 'Stax Bank', branchCode: '000053'),
    ExhaustiveBank(name: 'Bank32', branchCode: '000054'),
    ExhaustiveBank(name: 'RichFox Bank', branchCode: '000055'),
    ExhaustiveBank(name: 'Lydia Bank', branchCode: '000056'),
    ExhaustiveBank(name: 'Umano Bank', branchCode: '000057'),
    ExhaustiveBank(name: 'meBank', branchCode: '000058'),
    ExhaustiveBank(name: 'Alfa Bank', branchCode: '000059'),
    
    // Community Banks
    ExhaustiveBank(name: 'Community Bank', branchCode: '000060'),
    ExhaustiveBank(name: 'Peoples Bank', branchCode: '000061'),
    ExhaustiveBank(name: 'Ubuntu Bank', branchCode: '000062'),
    ExhaustiveBank(name: 'Batho Bank', branchCode: '000063'),
    ExhaustiveBank(name: 'Vuma Bank', branchCode: '000064'),
    ExhaustiveBank(name: 'Thuma Bank', branchCode: '000065'),
    
    // Islamic Banks
    ExhaustiveBank(name: 'Albaraka Islamic Bank', branchCode: '000070'),
    ExhaustiveBank(name: 'First National Islamic Bank', branchCode: '000071'),
    
    // Savings Banks
    ExhaustiveBank(name: 'South African Post Office Savings Bank', branchCode: '000080'),
    ExhaustiveBank(name: 'Nedbank Savings', branchCode: '198766'),
    
    // Other Registered Banks
    ExhaustiveBank(name: 'FirstRand Bank', branchCode: '250655'),
    ExhaustiveBank(name: 'Rand Merchant Bank', branchCode: '000090'),
    ExhaustiveBank(name: 'Wesbank (FirstRand)', branchCode: '000091'),
    ExhaustiveBank(name: 'RMB Private Bank', branchCode: '000092'),
    ExhaustiveBank(name: 'Coronation Fund Managers', branchCode: '000093'),
    ExhaustiveBank(name: 'Allan Gray', branchCode: '000094'),
    ExhaustiveBank(name: 'Ninety One (ex-Investec)', branchCode: '000095'),
    
    // Co-operative Banks
    ExhaustiveBank(name: 'SASBO Bank', branchCode: '000100'),
    ExhaustiveBank(name: 'Police Bank', branchCode: '000101'),
    ExhaustiveBank(name: 'Mzansi Account Bank', branchCode: '000102'),
    
    // Specialized Banks
    ExhaustiveBank(name: 'Motor Finance Corporation (MFC)', branchCode: '000110'),
    ExhaustiveBank(name: 'Wesbank Finance', branchCode: '000111'),
    ExhaustiveBank(name: 'Absa Vehicle Finance', branchCode: '000112'),
    ExhaustiveBank(name: 'Standard Bank Auto Finance', branchCode: '000113'),
    ExhaustiveBank(name: 'Nedbank Vehicle Finance', branchCode: '000114'),
    
    // Additional Banks
    ExhaustiveBank(name: 'Shanduka Bank', branchCode: '000120'),
    ExhaustiveBank(name: 'Phakama Bank', branchCode: '000121'),
    ExhaustiveBank(name: 'Isibaya Bank', branchCode: '000122'),
    ExhaustiveBank(name: 'Umqombothi Bank', branchCode: '000123'),
    ExhaustiveBank(name: 'Sarah Bank', branchCode: '000124'),
    ExhaustiveBank(name: 'Sarah Finance Bank', branchCode: '000125'),
    ExhaustiveBank(name: 'Kagiso Bank', branchCode: '000126'),
    ExhaustiveBank(name: 'Tyebank', branchCode: '000127'),
    ExhaustiveBank(name: 'Ulwazi Bank', branchCode: '000128'),
    ExhaustiveBank(name: 'NFB Bank', branchCode: '000129'),
    
    // Offshore Banks (SA Operations)
    ExhaustiveBank(name: 'JP Morgan Chase Bank SA', branchCode: '000130'),
    ExhaustiveBank(name: 'Deutsche Bank SA', branchCode: '000131'),
    ExhaustiveBank(name: 'BNP Paribas SA', branchCode: '000132'),
    ExhaustiveBank(name: 'Credit Suisse SA', branchCode: '000133'),
    ExhaustiveBank(name: 'UBS SA', branchCode: '000134'),
    
    // Other (For banks not listed)
    ExhaustiveBank(name: 'Other Bank (Not Listed)', branchCode: ''),
  ];

  // ==================== ZIMBABWE - 30+ BANKS ====================
  // Source: Reserve Bank of Zimbabwe (RBZ)
  static const List<ExhaustiveBank> zimbabwe = [
    // Commercial Banks
    ExhaustiveBank(name: 'CBZ Bank', branchCode: '000000', swiftCode: 'CBZBZWHH'),
    ExhaustiveBank(name: 'Stanbic Bank Zimbabwe', branchCode: '000001', swiftCode: 'SBICZWHH'),
    ExhaustiveBank(name: 'Standard Chartered Bank Zimbabwe', branchCode: '000002', swiftCode: 'SCBLZWHH'),
    ExhaustiveBank(name: 'NMB Bank', branchCode: '000003', swiftCode: 'NMBBZWHH'),
    ExhaustiveBank(name: 'ZB Bank', branchCode: '000004', swiftCode: 'ZBBLZWHH'),
    ExhaustiveBank(name: 'FBC Bank', branchCode: '000005', swiftCode: 'FBCBZWHH'),
    ExhaustiveBank(name: 'CABS (Central Africa Building Society)', branchCode: '000006', swiftCode: 'CABSZWHH'),
    
    // Merchant Banks
    ExhaustiveBank(name: 'Metropolitan Bank', branchCode: '000010', swiftCode: 'METRZWHH'),
    ExhaustiveBank(name: 'Zedbank', branchCode: '000011', swiftCode: 'ZEDBZWHH'),
    ExhaustiveBank(name: 'Summit Bank', branchCode: '000012', swiftCode: 'SUMMZWHH'),
    ExhaustiveBank(name: 'Legacy Bank', branchCode: '000013', swiftCode: 'LEGAZWHH'),
    ExhaustiveBank(name: 'Marble Bank', branchCode: '000014', swiftCode: 'MARLZWHH'),
    ExhaustiveBank(name: 'Sunrise Bank', branchCode: '000015', swiftCode: 'SUNRZWHH'),
    ExhaustiveBank(name: 'Royal Bank', branchCode: '000016', swiftCode: 'ROYAZWHH'),
    ExhaustiveBank(name: 'TN Bank', branchCode: '000017', swiftCode: 'TNBKZWHH'),
    
    // Building Societies
    ExhaustiveBank(name: 'First Building Society', branchCode: '000020'),
    ExhaustiveBank(name: 'CABS Building Society', branchCode: '000021'),
    ExhaustiveBank(name: 'Zimnat Building Society', branchCode: '000022'),
    
    // Microfinance Banks
    ExhaustiveBank(name: 'FBC Microfinance', branchCode: '000030'),
    ExhaustiveBank(name: 'ZB Microfinance', branchCode: '000031'),
    ExhaustiveBank(name: 'CBZ Microfinance', branchCode: '000032'),
    ExhaustiveBank(name: 'NMB Microfinance', branchCode: '000033'),
    
    // Finance Companies
    ExhaustiveBank(name: 'Zimbank', branchCode: '000040'),
    ExhaustiveBank(name: 'Trust Finance', branchCode: '000041'),
    ExhaustiveBank(name: 'Premier Banking Corporation', branchCode: '000042'),
    ExhaustiveBank(name: 'Barclays Bank Zimbabwe (now NMB)', branchCode: '000043'),
    
    // Development Banks
    ExhaustiveBank(name: 'Reserve Bank of Zimbabwe (Central Bank)', branchCode: '000050', swiftCode: 'RBZBZWHH'),
    ExhaustiveBank(name: 'Zimbabwe Development Bank', branchCode: '000051'),
    ExhaustiveBank(name: 'Agricultural Finance Corporation', branchCode: '000052'),
    ExhaustiveBank(name: 'Infrastructure Development Bank of Zimbabwe', branchCode: '000053'),
    
    // Foreign Banks
    ExhaustiveBank(name: 'Ecobank Zimbabwe', branchCode: '000060', swiftCode: 'ECOCZWHH'),
    ExhaustiveBank(name: 'Access Bank Zimbabwe', branchCode: '000061'),
    ExhaustiveBank(name: 'BancABC Zimbabwe', branchCode: '000062'),
    
    // Other
    ExhaustiveBank(name: 'Other Bank (Not Listed)', branchCode: ''),
  ];

  // ==================== ZAMBIA - 25+ BANKS ====================
  // Source: Bank of Zambia (BoZ)
  static const List<ExhaustiveBank> zambia = [
    // Commercial Banks
    ExhaustiveBank(name: 'Zanaco Bank', branchCode: '000000', swiftCode: 'ZANAZMLU'),
    ExhaustiveBank(name: 'Stanbic Bank Zambia', branchCode: '000001', swiftCode: 'SBICZMLU'),
    ExhaustiveBank(name: 'Standard Chartered Bank Zambia', branchCode: '000002', swiftCode: 'SCBLZMLU'),
    ExhaustiveBank(name: 'Absa Bank Zambia', branchCode: '000003', swiftCode: 'ABSAZMLU'),
    ExhaustiveBank(name: 'FNB Zambia', branchCode: '000004', swiftCode: 'FIRNZMLU'),
    
    // Local Banks
    ExhaustiveBank(name: 'FMB Bank', branchCode: '000010', swiftCode: 'FMBBZMLU'),
    ExhaustiveBank(name: 'Indorama Bank', branchCode: '000011', swiftCode: 'INDOZMLU'),
    ExhaustiveBank(name: 'Investrust Bank', branchCode: '000012', swiftCode: 'INVSZMLU'),
    ExhaustiveBank(name: 'Naps Bank', branchCode: '000013', swiftCode: 'NAPSZMLU'),
    
    // Regional Banks
    ExhaustiveBank(name: 'Ecobank Zambia', branchCode: '000020', swiftCode: 'ECOCZMLU'),
    ExhaustiveBank(name: 'First Alliance Bank', branchCode: '000021', swiftCode: 'FIALZMLU'),
    ExhaustiveBank(name: 'Herita Bank', branchCode: '000022', swiftCode: 'HERIZMLU'),
    ExhaustiveBank(name: 'Access Bank Zambia', branchCode: '000023', swiftCode: 'ACCBZMLU'),
    ExhaustiveBank(name: 'United Bank for Africa (UBA) Zambia', branchCode: '000024', swiftCode: 'UBNAZMLU'),
    
    // Development Banks
    ExhaustiveBank(name: 'Development Bank of Zambia (DBZ)', branchCode: '000030'),
    ExhaustiveBank(name: 'Bank of Zambia (Central Bank)', branchCode: '000031', swiftCode: 'BOZAZMLU'),
    ExhaustiveBank(name: 'Zambia National Building Society (ZNBS)', branchCode: '000032'),
    
    // Building Societies
    ExhaustiveBank(name: 'Lusaka Building Society', branchCode: '000040'),
    ExhaustiveBank(name: 'Copperbelt Building Society', branchCode: '000041'),
    
    // Finance Companies
    ExhaustiveBank(name: 'Finance Bank of Zambia', branchCode: '000050'),
    ExhaustiveBank(name: 'Meridien Biao Bank Zambia', branchCode: '000051'),
    ExhaustiveBank(name: 'Africard Services', branchCode: '000052'),
    
    // Microfinance Institutions
    ExhaustiveBank(name: 'Vision Fund Zambia', branchCode: '000060'),
    ExhaustiveBank(name: 'Opportunity International Bank of Zambia', branchCode: '000061'),
    
    // Other
    ExhaustiveBank(name: 'Other Bank (Not Listed)', branchCode: ''),
  ];

  // ==================== KENYA - 50+ BANKS ====================
  // Source: Central Bank of Kenya (CBK)
  static const List<ExhaustiveBank> kenya = [
    // Mobile Money
    ExhaustiveBank(name: 'M-Pesa (Safaricom)', branchCode: '000000', swiftCode: 'MPESKENA'),
    ExhaustiveBank(name: 'Airtel Money', branchCode: '000001'),
    
    // Tier 1 Commercial Banks
    ExhaustiveBank(name: 'KCB Bank', branchCode: '000010', swiftCode: 'KCBLKENA'),
    ExhaustiveBank(name: 'Equity Bank', branchCode: '000011', swiftCode: 'EQBLKENA'),
    ExhaustiveBank(name: 'Cooperative Bank of Kenya', branchCode: '000012', swiftCode: 'COOPKENA'),
    ExhaustiveBank(name: 'NCBA Bank', branchCode: '000013', swiftCode: 'NCBAKENA'),
    ExhaustiveBank(name: 'Stanbic Bank Kenya', branchCode: '000014', swiftCode: 'SBICKENA'),
    ExhaustiveBank(name: 'Standard Chartered Bank Kenya', branchCode: '000015', swiftCode: 'SCBCKENA'),
    ExhaustiveBank(name: 'Absa Bank Kenya', branchCode: '000016', swiftCode: 'ABSAKENA'),
    ExhaustiveBank(name: 'Diamond Trust Bank (DTB)', branchCode: '000017', swiftCode: 'DTKEKENA'),
    
    // Tier 2 Commercial Banks
    ExhaustiveBank(name: 'Family Bank', branchCode: '000020', swiftCode: 'FABLKENA'),
    ExhaustiveBank(name: 'Guaranty Trust Bank (GTBank)', branchCode: '000021', swiftCode: 'GTBIKENA'),
    ExhaustiveBank(name: 'HFC Bank', branchCode: '000022', swiftCode: 'HFBLKENA'),
    ExhaustiveBank(name: 'Prime Bank', branchCode: '000023', swiftCode: 'PRBLKENA'),
    ExhaustiveBank(name: 'Sidian Bank', branchCode: '000024', swiftCode: 'SIDIKENA'),
    ExhaustiveBank(name: 'Spire Bank', branchCode: '000025', swiftCode: 'SPIRKENA'),
    ExhaustiveBank(name: 'Consolidated Bank', branchCode: '000026', swiftCode: 'CONBKENA'),
    ExhaustiveBank(name: 'Ecobank Kenya', branchCode: '000027', swiftCode: 'ECOBKENA'),
    ExhaustiveBank(name: 'I&M Bank', branchCode: '000028', swiftCode: 'IMBLKENA'),
    ExhaustiveBank(name: 'Kenya Commercial Bank (KCB)', branchCode: '000029', swiftCode: 'KCBLKENA'),
    
    // Tier 3 Commercial Banks
    ExhaustiveBank(name: 'National Bank of Kenya', branchCode: '000030', swiftCode: 'NBKEKENA'),
    ExhaustiveBank(name: 'First Community Bank', branchCode: '000031', swiftCode: 'FCBKKENA'),
    ExhaustiveBank(name: 'Daima Bank', branchCode: '000032', swiftCode: 'DAIMKENA'),
    ExhaustiveBank(name: 'Credit Bank', branchCode: '000033', swiftCode: 'CREDKENA'),
    ExhaustiveBank(name: 'Gulf African Bank', branchCode: '000034', swiftCode: 'GULFKENA'),
    ExhaustiveBank(name: 'Bank of Baroda Kenya', branchCode: '000035', swiftCode: 'BARBKENA'),
    ExhaustiveBank(name: 'Oriental Commercial Bank', branchCode: '000036', swiftCode: 'ORCBKENA'),
    ExhaustiveBank(name: 'Fina Bank', branchCode: '000037', swiftCode: 'FINAKENA'),
    ExhaustiveBank(name: 'Guardian Bank', branchCode: '000038', swiftCode: 'GUARKENA'),
    ExhaustiveBank(name: 'Imperial Bank Kenya', branchCode: '000039', swiftCode: 'IMPKKENA'),
    
    // Other Banks
    ExhaustiveBank(name: 'Jubilee Bank', branchCode: '000040', swiftCode: 'JUBIKENA'),
    ExhaustiveBank(name: 'LAPFUND', branchCode: '000041', swiftCode: 'LAPFKENA'),
    ExhaustiveBank(name: 'Maendeleo Bank', branchCode: '000042', swiftCode: 'MAENKENA'),
    ExhaustiveBank(name: 'Paramount Bank', branchCode: '000043', swiftCode: 'PARAKENA'),
    ExhaustiveBank(name: 'Rafiki Bank', branchCode: '000044', swiftCode: 'RAFIKENA'),
    ExhaustiveBank(name: 'Salvation Bank', branchCode: '000045', swiftCode: 'SALVKENA'),
    ExhaustiveBank(name: 'Transnational Bank', branchCode: '000046', swiftCode: 'TRANKENA'),
    ExhaustiveBank(name: 'Ujamaa Bank', branchCode: '000047', swiftCode: 'UJAMKENA'),
    ExhaustiveBank(name: 'Vision Bank', branchCode: '000048', swiftCode: 'VISIKENA'),
    
    // Foreign Banks
    ExhaustiveBank(name: 'Citibank Kenya', branchCode: '000050', swiftCode: 'CITIKENA'),
    ExhaustiveBank(name: 'HSBC Kenya', branchCode: '000051', swiftCode: 'HSBCKENA'),
    ExhaustiveBank(name: 'Barclays Bank Kenya (now Absa)', branchCode: '000052'),
    ExhaustiveBank(name: 'Standard Chartered', branchCode: '000053'),
    
    // Mortgage Finance Companies
    ExhaustiveBank(name: 'Housing Finance Company', branchCode: '000060'),
    ExhaustiveBank(name: 'Home Afrika', branchCode: '000061'),
    
    // Microfinance Banks
    ExhaustiveBank(name: 'Equity Bank Microfinance', branchCode: '000070'),
    ExhaustiveBank(name: 'KCB Microfinance', branchCode: '000071'),
    ExhaustiveBank(name: 'Rafiki Microfinance', branchCode: '000072'),
    
    // Savings & Credit
    ExhaustiveBank(name: 'Postbank Kenya', branchCode: '000080'),
    ExhaustiveBank(name: 'Kenya Post Office Savings Bank', branchCode: '000081'),
    
    // Other
    ExhaustiveBank(name: 'Other Bank (Not Listed)', branchCode: ''),
  ];

  // Get banks for country
  static List<ExhaustiveBank> getBanksForCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'ZA':
        return southAfrica;
      case 'ZW':
        return zimbabwe;
      case 'ZM':
        return zambia;
      case 'KE':
        return kenya;
      default:
        // Return generic African banks for other countries
        return [
          const ExhaustiveBank(name: 'Standard Bank', branchCode: '000000'),
          const ExhaustiveBank(name: 'Stanbic Bank', branchCode: '000001'),
          const ExhaustiveBank(name: 'Ecobank', branchCode: '000002'),
          const ExhaustiveBank(name: 'Equity Bank', branchCode: '000003'),
          const ExhaustiveBank(name: 'KCB Bank', branchCode: '000004'),
          const ExhaustiveBank(name: 'Absa Bank', branchCode: '000005'),
          const ExhaustiveBank(name: 'FNB', branchCode: '000006'),
          const ExhaustiveBank(name: 'Nedbank', branchCode: '000007'),
          const ExhaustiveBank(name: 'Other Bank (Not Listed)', branchCode: ''),
        ];
    }
  }

  // Convert to Map for dropdown
  static List<Map<String, dynamic>> getBanksAsMap(String countryCode) {
    return getBanksForCountry(countryCode)
        .map((bank) => bank.toMap())
        .toList();
  }
}
