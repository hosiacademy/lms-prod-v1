# apps/users/services/masterclass_curricula.py
"""
Pre-defined curricula for each AI Masterclass type
"""

MASTERCLASS_CURRICULA = {
    'ai_finance': {
        'title': 'AI+ Finance™ Masterclass',
        'certification': 'AI+ Finance™',
        'target_audience': 'Finance Professionals, Executives, Analysts',
        'duration_days': '3',
        'daily_schedule_text': '''08:30 - 09:00: Arrival & Registration / Platform Login
09:00 - 10:30: Module 1
10:30 - 11:00: Coffee Break
11:00 - 12:30: Module 2
12:30 - 13:30: Lunch Break
13:30 - 15:00: Module 3 & Practical Exercise
15:00 - 15:30: Coffee Break
15:30 - 17:00: Module 4 & Group Discussion''',
        'curriculum_text': '''DAY 1: AI in Financial Operations
• Module 1: Introduction to AI in the Financial Sector
• Module 2: AI for Fraud Detection and Risk Management
• Module 3: Automating Financial Reporting with AI
• Module 4: Case Study: Implementing an AI-Powered Auditing System

DAY 2: AI for Investment and Analysis
• Module 5: Algorithmic Trading and AI Models
• Module 6: AI-Powered Portfolio Management
• Module 7: Natural Language Processing (NLP) for Market Sentiment Analysis
• Module 8: Practical Lab: Building a Simple Predictive Model
• Module 9: Developing an AI Strategy for a Financial Institution

DAY 3: AI Strategy and Certification
• Module 10: AI Ethics and Governance in Finance
• Module 11: The Future of FinTech and AI
• Module 12: Certification Exam Preparation & Final Q&A
• Exam Writing
• Present Certificates''',
    },
    'ai_healthcare': {
        'title': 'AI+ Healthcare™ Masterclass',
        'certification': 'AI+ Healthcare™',
        'target_audience': 'Healthcare Professionals, Medical Practitioners, Administrators',
        'duration_days': '3',
        'daily_schedule_text': '''08:30 - 09:00: Arrival & Registration / Platform Login
09:00 - 10:30: Module 1
10:30 - 11:00: Coffee Break
11:00 - 12:30: Module 2
12:30 - 13:30: Lunch Break
13:30 - 15:00: Module 3 & Practical Exercise
15:00 - 15:30: Coffee Break
15:30 - 17:00: Module 4 & Group Discussion''',
        'curriculum_text': '''DAY 1: AI in Healthcare Operations
• Module 1: Introduction to AI in Healthcare
• Module 2: AI for Diagnostic Imaging and Pathology
• Module 3: Predictive Analytics for Patient Outcomes
• Module 4: Case Study: AI-Powered Hospital Management System

DAY 2: AI for Clinical Decision Support
• Module 5: Machine Learning for Disease Prediction
• Module 6: Natural Language Processing for Medical Records
• Module 7: AI in Drug Discovery and Development
• Module 8: Practical Lab: Building a Diagnostic Support Tool
• Module 9: Developing an AI Strategy for Healthcare Institutions

DAY 3: AI Ethics and Certification
• Module 10: AI Ethics and Patient Privacy in Healthcare
• Module 11: The Future of Digital Health and AI
• Module 12: Certification Exam Preparation & Final Q&A
• Exam Writing
• Present Certificates''',
    },
    'ai_education': {
        'title': 'AI+ Education™ Masterclass',
        'certification': 'AI+ Education™',
        'target_audience': 'Educators, Training Professionals, EdTech Specialists',
        'duration_days': '3',
        'daily_schedule_text': '''08:30 - 09:00: Arrival & Registration / Platform Login
09:00 - 10:30: Module 1
10:30 - 11:00: Coffee Break
11:00 - 12:30: Module 2
12:30 - 13:30: Lunch Break
13:30 - 15:00: Module 3 & Practical Exercise
15:00 - 15:30: Coffee Break
15:30 - 17:00: Module 4 & Group Discussion''',
        'curriculum_text': '''DAY 1: AI in Educational Settings
• Module 1: Introduction to AI in Education
• Module 2: Personalized Learning with AI
• Module 3: AI for Student Assessment and Feedback
• Module 4: Case Study: Implementing AI-Powered Learning Management

DAY 2: AI for Teaching and Learning
• Module 5: Intelligent Tutoring Systems
• Module 6: AI for Curriculum Design and Content Creation
• Module 7: Learning Analytics and Student Success Prediction
• Module 8: Practical Lab: Building an AI Teaching Assistant
• Module 9: Developing an AI Strategy for Educational Institutions

DAY 3: AI Ethics and Certification
• Module 10: AI Ethics and Data Privacy in Education
• Module 11: The Future of EdTech and AI
• Module 12: Certification Exam Preparation & Final Q&A
• Exam Writing
• Present Certificates''',
    },
    'ai_marketing': {
        'title': 'AI+ Marketing™ Masterclass',
        'certification': 'AI+ Marketing™',
        'target_audience': 'Marketing Professionals, Brand Managers, Digital Strategists',
        'duration_days': '3',
        'daily_schedule_text': '''08:30 - 09:00: Arrival & Registration / Platform Login
09:00 - 10:30: Module 1
10:30 - 11:00: Coffee Break
11:00 - 12:30: Module 2
12:30 - 13:30: Lunch Break
13:30 - 15:00: Module 3 & Practical Exercise
15:00 - 15:30: Coffee Break
15:30 - 17:00: Module 4 & Group Discussion''',
        'curriculum_text': '''DAY 1: AI in Marketing Operations
• Module 1: Introduction to AI in Marketing
• Module 2: Customer Segmentation with AI
• Module 3: Predictive Analytics for Campaign Performance
• Module 4: Case Study: AI-Powered Marketing Automation

DAY 2: AI for Customer Engagement
• Module 5: Personalization at Scale with AI
• Module 6: Chatbots and Conversational Marketing
• Module 7: AI for Content Creation and Optimization
• Module 8: Practical Lab: Building a Customer Journey Predictor
• Module 9: Developing an AI Strategy for Marketing Teams

DAY 3: AI Ethics and Certification
• Module 10: AI Ethics and Consumer Privacy
• Module 11: The Future of MarTech and AI
• Module 12: Certification Exam Preparation & Final Q&A
• Exam Writing
• Present Certificates''',
    },
    'ai_hr': {
        'title': 'AI+ Human Resources™ Masterclass',
        'certification': 'AI+ HR™',
        'target_audience': 'HR Professionals, Talent Managers, Recruiters',
        'duration_days': '3',
        'daily_schedule_text': '''08:30 - 09:00: Arrival & Registration / Platform Login
09:00 - 10:30: Module 1
10:30 - 11:00: Coffee Break
11:00 - 12:30: Module 2
12:30 - 13:30: Lunch Break
13:30 - 15:00: Module 3 & Practical Exercise
15:00 - 15:30: Coffee Break
15:30 - 17:00: Module 4 & Group Discussion''',
        'curriculum_text': '''DAY 1: AI in HR Operations
• Module 1: Introduction to AI in Human Resources
• Module 2: AI for Talent Acquisition and Recruitment
• Module 3: Predictive Analytics for Employee Retention
• Module 4: Case Study: AI-Powered Performance Management

DAY 2: AI for Talent Management
• Module 5: Skills Mapping and Career Path Prediction
• Module 6: AI for Learning and Development
• Module 7: Sentiment Analysis for Employee Engagement
• Module 8: Practical Lab: Building a Recruitment Screening Tool
• Module 9: Developing an AI Strategy for HR Departments

DAY 3: AI Ethics and Certification
• Module 10: AI Ethics and Bias in HR Decisions
• Module 11: The Future of Work and AI
• Module 12: Certification Exam Preparation & Final Q&A
• Exam Writing
• Present Certificates''',
    },
}


def get_masterclass_curriculum(masterclass_type: str) -> dict:
    """
    Get curriculum for a specific masterclass type
    
    Args:
        masterclass_type: One of 'ai_finance', 'ai_healthcare', 'ai_education', 'ai_marketing', 'ai_hr'
    
    Returns:
        Dict with curriculum details or default if not found
    """
    return MASTERCLASS_CURRICULA.get(masterclass_type, MASTERCLASS_CURRICULA['ai_finance'])


def get_all_masterclass_types() -> list:
    """Get list of all available masterclass types"""
    return list(MASTERCLASS_CURRICULA.keys())
