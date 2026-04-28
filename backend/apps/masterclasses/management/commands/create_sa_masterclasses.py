from django.core.management.base import BaseCommand
from apps.masterclasses.models import Masterclass

class Command(BaseCommand):
    help = 'Create South Africa masterclasses schedule 2026/2027'
    
    def handle(self, *args, **kwargs):
        sa_schedule = [
            ('AI+ Finance™', 'AI Business', '2026-04-15', '2026-04-17', 'professional'),
            ('AI+ Developer™', 'AI Development', '2026-04-20', '2026-04-25', 'technical'),
            ('AI+ Human Resources™', 'AI Business', '2026-05-06', '2026-05-08', 'professional'),
            ('AI+ Engineer™', 'AI Development', '2026-05-11', '2026-05-15', 'technical'),
            ('AI+ Supply Chain™', 'AI Business', '2026-06-03', '2026-06-05', 'professional'),
            ('AI+ Vibe Coder™', 'AI Development', '2026-06-08', '2026-06-12', 'technical'),
            ('AI+ Project Manager™', 'AI Business', '2026-07-01', '2026-07-03', 'professional'),
            ('AI+ Project Management Practitioner™', 'AI Business', '2026-07-08', '2026-07-10', 'professional'),
            ('AI+ Prompt Engineer Level 2™', 'AI Development', '2026-07-20', '2026-07-24', 'technical'),
            ('AI+ Agile Project Management Fundamentals™', 'AI Business', '2026-08-05', '2026-08-07', 'professional'),
            ('AI+ Program Director – Practitioner™', 'AI Business', '2026-08-19', '2026-08-21', 'professional'),
            ('AI+ Context Engineering™', 'AI Development', '2026-08-24', '2026-08-28', 'technical'),
            ('AI+ Legal™', 'AI Business', '2026-09-02', '2026-09-04', 'professional'),
            ('AI+ Real Estate™', 'AI Business', '2026-09-09', '2026-09-11', 'professional'),
            ('AI+ Security Level 1™', 'AI Security', '2026-09-14', '2026-09-18', 'technical'),
            ('AI+ Sales™', 'AI Business', '2026-10-07', '2026-10-09', 'professional'),
            ('AI+ Marketing™', 'AI Business', '2026-10-14', '2026-10-16', 'professional'),
            ('AI+ Security Level 2™', 'AI Security', '2026-10-19', '2026-10-23', 'technical'),
            ('AI+ Customer Service™', 'AI Business', '2026-11-04', '2026-11-06', 'professional'),
            ('AI+ Product Manager™', 'AI Business', '2026-11-11', '2026-11-13', 'professional'),
            ('AI+ Security Level 3™', 'AI Security', '2026-11-16', '2026-11-20', 'technical'),
            ('AI+ Ethics™', 'AI Business', '2026-12-02', '2026-12-04', 'professional'),
            ('AI+ Writer™', 'AI Business', '2026-12-07', '2026-12-09', 'professional'),
            ('AI+ Security Compliance™', 'AI Security', '2027-01-11', '2027-01-15', 'technical'),
            ('AI+ Researcher™', 'AI Business', '2027-01-20', '2027-01-22', 'professional'),
            ('AI+ Chief AI Officer™', 'AI Business', '2027-01-20', '2027-01-22', 'professional'),
            ('AI+ Network™', 'AI Security', '2027-01-25', '2027-01-29', 'technical'),
            ('AI+ Government™', 'AI Specialisation', '2027-02-03', '2027-02-05', 'professional'),
            ('AI+ Policy Maker™', 'AI Specialisation', '2027-02-10', '2027-02-12', 'professional'),
            ('AI+ Ethical Hacker™', 'AI Security', '2027-02-15', '2027-02-19', 'technical'),
            ('AI+ Mining™', 'AI Specialisation', '2027-03-03', '2027-03-05', 'professional'),
            ('AI+ Telecommunications™', 'AI Specialisation', '2027-03-10', '2027-03-12', 'professional'),
            ('Executive Introduction to RSAIF', 'AI Security', '2027-03-15', '2027-03-19', 'technical'),
        ]
        
        prices = {'professional': (500, 700), 'technical': (750, 1100)}
        created = 0
        
        for title, category, start, end, stream in sa_schedule:
            online, physical = prices[stream]
            mc, mc_created = Masterclass.objects.get_or_create(
                title=title, start_date=start, country_code='ZA',
                defaults={
                    'slug': title.lower().replace('+', '').replace('™', '').replace(' ', '-'),
                    'description': '',
                    'category': category,
                    'country_name': 'South Africa',
                    'end_date': end,
                    'stream_type': stream,
                    'tier': 'standard',
                    'price_physical': physical,
                    'price_online': online,
                    'currency': 'USD',
                    'status': 'scheduled',
                    'max_participants': 35,
                    'current_participants': 0,
                    'has_online_option': True,
                    'is_featured': False,
                }
            )
            if mc_created:
                created += 1
                self.stdout.write(f'✅ Created: {title} ({start})')
            else:
                self.stdout.write(f'⚠️  Exists: {title} ({start})')
        
        self.stdout.write(f'\n✅ Created {created} SA masterclasses')
