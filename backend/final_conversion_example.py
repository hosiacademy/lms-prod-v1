import os
import django
from decimal import Decimal

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from apps.payments.services.currency_service import CurrencyConversionService
from apps.masterclasses.models import Masterclass

def run():
    # 1. Get Live ZAR Rate
    rates = CurrencyConversionService.get_exchange_rates('USD', use_cache=True)
    zar_rate = rates.get('ZAR', Decimal('16.53'))
    print(f"Live ZAR Rate: {zar_rate}\n")

    # 2. Get the specific Masterclasses from the correct table
    masterclasses = Masterclass.objects.filter(id__in=[82, 83, 85])
    
    print(f"{'Title':<25} | {'Type':<10} | {'USD':<10} | {'ZAR':<10}")
    print("-" * 65)
    
    for mc in masterclasses:
        # Physical
        phys_zar = CurrencyConversionService.convert_amount(mc.price_physical, 'USD', 'ZAR')
        print(f"{mc.title:<25} | Physical   | ${mc.price_physical:<9} | R {phys_zar:,}")
        
        # Online
        onl_zar = CurrencyConversionService.convert_amount(mc.price_online, 'USD', 'ZAR')
        print(f"{'':<25} | Online     | ${mc.price_online:<9} | R {onl_zar:,}")
        print("-" * 65)

if __name__ == "__main__":
    run()
