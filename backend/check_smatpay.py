from apps.payments.models import PaymentProviderModel, ProviderCountryConfig

def check_and_create_smatpay():
    provider, created = PaymentProviderModel.objects.get_or_create(
        code='smatpay',
        defaults={
            'name': 'SmatPay',
            'category': 'aggregator'
        }
    )
    print(f"SmatPay Provider: {'Created' if created else 'Already exists'}")

    # Create SmatPay config for South Africa (ZA)
    za_config, created = ProviderCountryConfig.objects.get_or_create(
        provider=provider,
        country='ZA',
        defaults={
            'is_active': True,
            'is_sandbox': False,
            'min_amount': 1.00,
            'max_amount': 100000.00,
        }
    )
    print(f"SmatPay ZA Config: {'Created' if created else 'Already exists'}")

    # Create SmatPay config for Zimbabwe (ZW)
    zw_config, created = ProviderCountryConfig.objects.get_or_create(
        provider=provider,
        country='ZW',
        defaults={
            'is_active': True,
            'is_sandbox': False,
            'min_amount': 1.00,
            'max_amount': 100000.00,
        }
    )
    print(f"SmatPay ZW Config: {'Created' if created else 'Already exists'}")

if __name__ == "__main__":
    check_and_create_smatpay()
