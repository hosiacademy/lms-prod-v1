import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from apps.payments.services.currency_service import CurrencyConversionService
from apps.masterclasses.models import Masterclass

def run():
    # 1. Get Exchange Rate
    rates = CurrencyConversionService.get_exchange_rates('USD', use_cache=False)
    zar_rate = rates.get('ZAR')
    print(f"ZAR Exchange Rate: {zar_rate}")

    # 2. Get 3 Unique Masterclass Prices
    all_mcs = Masterclass.objects.all()
    seen = set()
    masterclasses = []
    for mc in all_mcs:
        if mc.title not in seen:
            seen.add(mc.title)
            masterclasses.append(mc)
        if len(masterclasses) == 3:
            break
    if not masterclasses:
        print("No Masterclasses found.")
        return
    
    for mc in masterclasses:
        price_usd = mc.price
        print(f"\\nMasterclass: {mc.title}")
        print(f"Price (USD): {price_usd}")
        
        # 3. Convert to ZAR
        converted = CurrencyConversionService.convert_amount(price_usd, 'USD', 'ZAR', use_cache=True)
        print(f"Price in ZAR: {converted}")

if __name__ == "__main__":
    run()
