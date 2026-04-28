# apps/learnerships/services/cybersecurity_pricing.py
"""
2026 Cybersecurity Learnership - Certification Cost Breakdown Per Role
Platform: $20/student/month × 12 = $240
Instructor: $50/student/month × 12 = $600
Sales Price = Total Cost × 1.5 (50% Markup)
April 2026 Intake
"""

CYBERSECURITY_LEARNERSHIPS = {
    'soc_analyst': {
        'title': 'SOC Analyst',
        'role': 'Security Operations Center Analyst',
        'total_cert_cost': 6900,
        'platform_cost': 240,
        'instructor_cost': 600,
        'total_cost': 7740,
        'phases': {
            'phase_1': {
                'name': 'Phase 1 – Foundation',
                'certifications': [
                    {'name': 'CompTIA A+', 'description': 'Core hardware & OS', 'cost': 246},
                    {'name': 'CompTIA Network+', 'description': 'Networking fundamentals', 'cost': 358},
                    {'name': 'CompTIA Security+', 'description': 'Security concepts', 'cost': 392},
                    {'name': 'AI+ Security Level 1™', 'description': 'Intro AI in cybersecurity', 'cost': 400},
                    {'name': 'TryHackMe Premium (1 yr)', 'description': 'Lab platform', 'cost': 99},
                    {'name': 'Study Materials – Phase 1', 'description': 'Digital resources', 'cost': 200},
                ],
                'phase_total': 1695,
            },
            'phase_2': {
                'name': 'Phase 2 – Vendor Spec',
                'certifications': [
                    {'name': 'CompTIA CySA+', 'description': 'Threat & vulnerability analysis', 'cost': 392},
                    {'name': 'AI+ Security Level 2™', 'description': 'Intermediate AI security', 'cost': 500},
                    {'name': 'Microsoft SC-200', 'description': 'MS Sentinel / Defender', 'cost': 165},
                    {'name': 'CrowdStrike CCFR', 'description': 'Falcon platform', 'cost': 250},
                    {'name': 'Study Materials – Phase 2', 'description': 'Digital resources', 'cost': 300},
                ],
                'phase_total': 1607,
            },
            'phase_3': {
                'name': 'Phase 3 – Practical/Readiness',
                'certifications': [
                    {'name': 'AI+ Security Level 3™', 'description': 'Expert AI security', 'cost': 600},
                    {'name': 'TryHackMe SOC Level 2', 'description': 'Advanced SOC labs', 'cost': 99},
                    {'name': 'GIAC GCIH', 'description': 'Incident handler cert', 'cost': 2499},
                    {'name': 'Study Materials – Phase 3', 'description': 'Digital resources', 'cost': 400},
                ],
                'phase_total': 3598,
            },
        },
    },
    'security_engineer': {
        'title': 'Security Engineer',
        'role': 'Security Infrastructure Engineer',
        'total_cert_cost': 5871,
        'platform_cost': 240,
        'instructor_cost': 600,
        'total_cost': 6711,
        'phases': {
            'phase_1': {
                'name': 'Phase 1 – Foundation',
                'certifications': [
                    {'name': 'CompTIA A+', 'description': 'Core hardware & OS', 'cost': 246},
                    {'name': 'CompTIA Network+', 'description': 'Networking fundamentals', 'cost': 358},
                    {'name': 'CompTIA Security+', 'description': 'Security concepts', 'cost': 392},
                    {'name': 'AI+ Security Level 1™', 'description': 'Intro AI in cybersecurity', 'cost': 400},
                    {'name': 'AI+ Network™', 'description': 'AI-powered network security', 'cost': 500},
                    {'name': 'TryHackMe Premium (1 yr)', 'description': 'Lab platform', 'cost': 99},
                    {'name': 'Study Materials – Phase 1', 'description': 'Digital resources', 'cost': 200},
                ],
                'phase_total': 2195,
            },
            'phase_2': {
                'name': 'Phase 2 – Vendor Spec',
                'certifications': [
                    {'name': 'CompTIA CySA+', 'description': 'Threat & vulnerability analysis', 'cost': 392},
                    {'name': 'AI+ Security Level 2™', 'description': 'Intermediate AI security', 'cost': 500},
                    {'name': 'Microsoft AZ-500', 'description': 'Azure Security Engineer', 'cost': 165},
                    {'name': 'Palo Alto PCCET', 'description': 'Cybersecurity entry-level', 'cost': 150},
                    {'name': 'Study Materials – Phase 2', 'description': 'Digital resources', 'cost': 300},
                ],
                'phase_total': 1507,
            },
            'phase_3': {
                'name': 'Phase 3 – Practical/Readiness',
                'certifications': [
                    {'name': 'CompTIA CASP+', 'description': 'Advanced security practitioner', 'cost': 494},
                    {'name': 'AI+ Security Level 3™', 'description': 'Expert AI security', 'cost': 600},
                    {'name': 'Fortinet NSE 4', 'description': 'Network security professional', 'cost': 400},
                    {'name': 'Zscaler ZCCA-IA', 'description': 'Zero Trust cloud security', 'cost': 275},
                    {'name': 'Study Materials – Phase 3', 'description': 'Digital resources', 'cost': 400},
                ],
                'phase_total': 2169,
            },
        },
    },
    'security_consultant': {
        'title': 'Security Consultant',
        'role': 'Security Consultant / Architect',
        'total_cert_cost': 7087,
        'platform_cost': 240,
        'instructor_cost': 600,
        'total_cost': 7927,
        'phases': {
            'phase_1': {
                'name': 'Phase 1 – Foundation',
                'certifications': [
                    {'name': 'CompTIA A+', 'description': 'Core hardware & OS', 'cost': 246},
                    {'name': 'CompTIA Network+', 'description': 'Networking fundamentals', 'cost': 358},
                    {'name': 'CompTIA Security+', 'description': 'Security concepts', 'cost': 392},
                    {'name': 'AI+ Security Level 1™', 'description': 'Intro AI in cybersecurity', 'cost': 400},
                    {'name': 'AI+ Security Compliance™', 'description': 'AI compliance & governance', 'cost': 500},
                    {'name': 'TryHackMe Premium (1 yr)', 'description': 'Lab platform', 'cost': 99},
                    {'name': 'Study Materials – Phase 1', 'description': 'Digital resources', 'cost': 200},
                ],
                'phase_total': 2195,
            },
            'phase_2': {
                'name': 'Phase 2 – Vendor Spec',
                'certifications': [
                    {'name': 'CompTIA CySA+', 'description': 'Threat & vulnerability analysis', 'cost': 392},
                    {'name': 'CompTIA PenTest+', 'description': 'Penetration testing', 'cost': 392},
                    {'name': 'AI+ Security Level 2™', 'description': 'Intermediate AI security', 'cost': 500},
                    {'name': 'AWS Security Specialty', 'description': 'AWS cloud security', 'cost': 300},
                    {'name': 'Microsoft SC-100', 'description': 'MS Cybersecurity Architect', 'cost': 165},
                    {'name': 'Study Materials – Phase 2', 'description': 'Digital resources', 'cost': 400},
                ],
                'phase_total': 2149,
            },
            'phase_3': {
                'name': 'Phase 3 – Practical/Readiness',
                'certifications': [
                    {'name': 'CompTIA CASP+', 'description': 'Advanced security practitioner', 'cost': 494},
                    {'name': 'AI+ Security Level 3™', 'description': 'Expert AI security', 'cost': 600},
                    {'name': 'Executive Intro to RSAIF', 'description': 'Risk & security framework', 'cost': 400},
                    {'name': 'CISSP', 'description': 'Gold standard security cert', 'cost': 749},
                    {'name': 'Study Materials – Phase 3', 'description': 'Digital resources', 'cost': 500},
                ],
                'phase_total': 2743,
            },
        },
    },
    'red_teamer': {
        'title': 'Red Teamer',
        'role': 'Offensive Security Specialist',
        'total_cert_cost': 9577,
        'platform_cost': 240,
        'instructor_cost': 600,
        'total_cost': 10417,
        'phases': {
            'phase_1': {
                'name': 'Phase 1 – Foundation',
                'certifications': [
                    {'name': 'CompTIA A+', 'description': 'Core hardware & OS', 'cost': 246},
                    {'name': 'CompTIA Network+', 'description': 'Networking fundamentals', 'cost': 358},
                    {'name': 'CompTIA Security+', 'description': 'Security concepts', 'cost': 392},
                    {'name': 'AI+ Security Level 1™', 'description': 'Intro AI in cybersecurity', 'cost': 400},
                    {'name': 'TryHackMe Premium (1 yr)', 'description': 'Lab platform', 'cost': 99},
                    {'name': 'Study Materials – Phase 1', 'description': 'Digital resources', 'cost': 200},
                ],
                'phase_total': 1695,
            },
            'phase_2': {
                'name': 'Phase 2 – Vendor Spec',
                'certifications': [
                    {'name': 'CompTIA PenTest+', 'description': 'Penetration testing', 'cost': 392},
                    {'name': 'AI+ Ethical Hacker™', 'description': 'AI-powered ethical hacking', 'cost': 600},
                    {'name': 'OSCP', 'description': 'Offensive Security cert', 'cost': 1599},
                    {'name': 'Burp Suite Certified Practitioner', 'description': 'Web app security', 'cost': 99},
                    {'name': 'Study Materials – Phase 2', 'description': 'Digital resources', 'cost': 400},
                ],
                'phase_total': 3090,
            },
            'phase_3': {
                'name': 'Phase 3 – Practical/Readiness',
                'certifications': [
                    {'name': 'CompTIA CASP+', 'description': 'Advanced security practitioner', 'cost': 494},
                    {'name': 'AI+ Security Level 3™', 'description': 'Expert AI security', 'cost': 600},
                    {'name': 'OSWE', 'description': 'Web expert cert', 'cost': 1599},
                    {'name': 'OSED', 'description': 'Exploit dev cert', 'cost': 1599},
                    {'name': 'Study Materials – Phase 3', 'description': 'Digital resources', 'cost': 500},
                ],
                'phase_total': 4792,
            },
        },
    },
    'blue_teamer': {
        'title': 'Blue Teamer',
        'role': 'Defensive Security Specialist',
        'total_cert_cost': 8095,
        'platform_cost': 240,
        'instructor_cost': 600,
        'total_cost': 8935,
        'phases': {
            'phase_1': {
                'name': 'Phase 1 – Foundation',
                'certifications': [
                    {'name': 'CompTIA A+', 'description': 'Core hardware & OS', 'cost': 246},
                    {'name': 'CompTIA Network+', 'description': 'Networking fundamentals', 'cost': 358},
                    {'name': 'CompTIA Security+', 'description': 'Security concepts', 'cost': 392},
                    {'name': 'AI+ Security Level 1™', 'description': 'Intro AI in cybersecurity', 'cost': 400},
                    {'name': 'TryHackMe Premium (1 yr)', 'description': 'Lab platform', 'cost': 99},
                    {'name': 'Study Materials – Phase 1', 'description': 'Digital resources', 'cost': 200},
                ],
                'phase_total': 1695,
            },
            'phase_2': {
                'name': 'Phase 2 – Vendor Spec',
                'certifications': [
                    {'name': 'CompTIA CySA+', 'description': 'Threat & vulnerability analysis', 'cost': 392},
                    {'name': 'AI+ Security Level 2™', 'description': 'Intermediate AI security', 'cost': 500},
                    {'name': 'AI+ Network™', 'description': 'AI-powered network security', 'cost': 500},
                    {'name': 'Microsoft SC-200', 'description': 'MS Sentinel / Defender', 'cost': 165},
                    {'name': 'CrowdStrike CCFR', 'description': 'Falcon platform', 'cost': 250},
                    {'name': 'Study Materials – Phase 2', 'description': 'Digital resources', 'cost': 300},
                ],
                'phase_total': 2107,
            },
            'phase_3': {
                'name': 'Phase 3 – Practical/Readiness',
                'certifications': [
                    {'name': 'CompTIA CASP+', 'description': 'Advanced security practitioner', 'cost': 494},
                    {'name': 'AI+ Security Level 3™', 'description': 'Expert AI security', 'cost': 600},
                    {'name': 'GIAC GCIH', 'description': 'Incident handler cert', 'cost': 2499},
                    {'name': 'Tenable TCSE', 'description': 'Vulnerability management', 'cost': 300},
                    {'name': 'Study Materials – Phase 3', 'description': 'Digital resources', 'cost': 400},
                ],
                'phase_total': 4293,
            },
        },
    },
    'bug_hunter': {
        'title': 'Bug Hunter',
        'role': 'Vulnerability Researcher',
        'total_cert_cost': 7983,
        'platform_cost': 240,
        'instructor_cost': 600,
        'total_cost': 8823,
        'phases': {
            'phase_1': {
                'name': 'Phase 1 – Foundation',
                'certifications': [
                    {'name': 'CompTIA A+', 'description': 'Core hardware & OS', 'cost': 246},
                    {'name': 'CompTIA Network+', 'description': 'Networking fundamentals', 'cost': 358},
                    {'name': 'CompTIA Security+', 'description': 'Security concepts', 'cost': 392},
                    {'name': 'AI+ Security Level 1™', 'description': 'Intro AI in cybersecurity', 'cost': 400},
                    {'name': 'TryHackMe Premium (1 yr)', 'description': 'Lab platform', 'cost': 99},
                    {'name': 'Study Materials – Phase 1', 'description': 'Digital resources', 'cost': 200},
                ],
                'phase_total': 1695,
            },
            'phase_2': {
                'name': 'Phase 2 – Vendor Spec',
                'certifications': [
                    {'name': 'CompTIA PenTest+', 'description': 'Penetration testing', 'cost': 392},
                    {'name': 'AI+ Ethical Hacker™', 'description': 'AI-powered ethical hacking', 'cost': 600},
                    {'name': 'Burp Suite Certified Practitioner', 'description': 'Web app security', 'cost': 99},
                    {'name': 'eLearnSecurity eWPT', 'description': 'Web pen testing', 'cost': 499},
                    {'name': 'Study Materials – Phase 2', 'description': 'Digital resources', 'cost': 400},
                ],
                'phase_total': 1990,
            },
            'phase_3': {
                'name': 'Phase 3 – Practical/Readiness',
                'certifications': [
                    {'name': 'AI+ Security Level 3™', 'description': 'Expert AI security', 'cost': 600},
                    {'name': 'OSWE', 'description': 'Web expert cert', 'cost': 1599},
                    {'name': 'OSEP', 'description': 'Evasion techniques cert', 'cost': 1599},
                    {'name': 'Study Materials – Phase 3', 'description': 'Digital resources', 'cost': 500},
                ],
                'phase_total': 4298,
            },
        },
    },
}

# Exchange rate: USD to ZAR (update as needed)
USD_TO_ZAR_RATE = 18.50


def get_cybersecurity_learnership(role_slug: str) -> dict:
    """
    Get cybersecurity learnership details by role slug
    
    Args:
        role_slug: One of 'soc_analyst', 'security_engineer', 'security_consultant', 
                   'red_teamer', 'blue_teamer', 'bug_hunter'
    
    Returns:
        Dict with learnership details or None if not found
    """
    return CYBERSECURITY_LEARNERSHIPS.get(role_slug)


def get_localized_cost_breakdown(role_slug: str, currency: str = 'ZAR') -> dict:
    """
    Get localized cost breakdown for a cybersecurity learnership
    
    Args:
        role_slug: Role type
        currency: 'USD' or 'ZAR'
    
    Returns:
        Dict with localized costs
    """
    learnership = get_cybersecurity_learnership(role_slug)
    if not learnership:
        return None
    
    rate = USD_TO_ZAR_RATE if currency == 'ZAR' else 1
    currency_symbol = 'R' if currency == 'ZAR' else '$'
    
    # Convert all costs
    localized = {
        'title': learnership['title'],
        'role': learnership['role'],
        'currency': currency,
        'currency_symbol': currency_symbol,
        'total_cert_cost': learnership['total_cert_cost'] * rate,
        'platform_cost': learnership['platform_cost'] * rate,
        'instructor_cost': learnership['instructor_cost'] * rate,
        'total_cost': learnership['total_cost'] * rate,
        'phases': {},
    }
    
    # Convert phase costs
    for phase_key, phase_data in learnership['phases'].items():
        localized['phases'][phase_key] = {
            'name': phase_data['name'],
            'phase_total': phase_data['phase_total'] * rate,
            'certifications': [
                {
                    'name': cert['name'],
                    'description': cert['description'],
                    'cost': cert['cost'] * rate,
                }
                for cert in phase_data['certifications']
            ],
        }
    
    return localized


def get_all_cybersecurity_roles() -> list:
    """Get list of all available cybersecurity roles"""
    return [
        {'slug': 'soc_analyst', 'title': 'SOC Analyst'},
        {'slug': 'security_engineer', 'title': 'Security Engineer'},
        {'slug': 'security_consultant', 'title': 'Security Consultant'},
        {'slug': 'red_teamer', 'title': 'Red Teamer'},
        {'slug': 'blue_teamer', 'title': 'Blue Teamer'},
        {'slug': 'bug_hunter', 'title': 'Bug Hunter'},
    ]
