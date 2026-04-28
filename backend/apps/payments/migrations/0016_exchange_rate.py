# Generated manually for exchange rate models

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0014_admincountryaccess'),
    ]

    operations = [
        migrations.CreateModel(
            name='ExchangeRate',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('currency_code', models.CharField(db_index=True, max_length=3, unique=True)),
                ('rate', models.DecimalField(decimal_places=6, help_text='1 USD = X local currency', max_digits=12)),
                ('currency_name', models.CharField(max_length=100)),
                ('currency_symbol', models.CharField(blank=True, max_length=10)),
                ('country_code', models.CharField(db_index=True, max_length=2)),
                ('country_name', models.CharField(max_length=100)),
                ('fetched_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('expires_at', models.DateTimeField(help_text='Rate expires after 24 hours')),
                ('source', models.CharField(default='exchangerate-api', help_text='API source for the rate', max_length=50)),
                ('is_active', models.BooleanField(default=True)),
            ],
            options={
                'verbose_name_plural': 'Exchange Rates',
                'ordering': ['currency_code'],
            },
        ),
        migrations.CreateModel(
            name='ExchangeRateLog',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('fetched_at', models.DateTimeField(auto_now_add=True)),
                ('source', models.CharField(max_length=50)),
                ('status', models.CharField(choices=[('success', 'Success'), ('failed', 'Failed'), ('partial', 'Partial')], max_length=10)),
                ('rates_fetched', models.IntegerField(default=0)),
                ('error_message', models.TextField(blank=True)),
                ('raw_response', models.JSONField(blank=True, null=True)),
            ],
            options={
                'ordering': ['-fetched_at'],
            },
        ),
    ]
