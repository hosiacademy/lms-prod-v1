# Generated migration for Quotation System
from django.db import migrations, models
import django.db.models.deletion
from decimal import Decimal


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0033_add_smatpay_fee_fields'),  # Update with your latest migration
        ('users', '0001_initial'),  # Adjust as needed
    ]

    operations = [
        migrations.CreateModel(
            name='ClientQuotation',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('quotation_number', models.CharField(max_length=20, unique=True, verbose_name='Quotation Number')),
                ('client_name', models.CharField(max_length=255, verbose_name='Client Name')),
                ('client_email', models.EmailField(max_length=254, verbose_name='Client Email')),
                ('client_phone', models.CharField(blank=True, max_length=20, verbose_name='Client Phone')),
                ('client_company', models.CharField(blank=True, max_length=255, verbose_name='Company/Organization')),
                ('client_country', models.CharField(default='ZW', max_length=2, verbose_name='Country Code')),
                ('training_type', models.CharField(choices=[('course', 'AI Certs Course'), ('masterclass', 'Professional Masterclass'), ('learnership', 'Learnership Program')], max_length=20, verbose_name='Training Type')),
                ('course_id', models.IntegerField(blank=True, null=True, verbose_name='Course ID (if type=course)')),
                ('course_name', models.CharField(blank=True, max_length=255, verbose_name='Course Name')),
                ('masterclass_id', models.IntegerField(blank=True, null=True, verbose_name='Masterclass ID (if type=masterclass)')),
                ('masterclass_name', models.CharField(blank=True, max_length=255, verbose_name='Masterclass Name')),
                ('learnership_id', models.IntegerField(blank=True, null=True, verbose_name='Learnership ID (if type=learnership)')),
                ('learnership_name', models.CharField(blank=True, max_length=255, verbose_name='Learnership Name')),
                ('base_price', models.DecimalField(decimal_places=2, max_digits=12, verbose_name='Base Price (USD)')),
                ('local_currency', models.CharField(default='USD', max_length=3, verbose_name='Local Currency')),
                ('local_amount', models.DecimalField(decimal_places=2, max_digits=12, verbose_name='Amount in Local Currency')),
                ('exchange_rate', models.DecimalField(decimal_places=6, default=Decimal('1.0'), max_digits=10, verbose_name='Exchange Rate')),
                ('discount_percentage', models.DecimalField(decimal_places=2, default=Decimal('0.00'), max_digits=5, verbose_name='Discount %')),
                ('discount_amount', models.DecimalField(decimal_places=2, default=Decimal('0.00'), max_digits=12, verbose_name='Discount Amount')),
                ('subtotal', models.DecimalField(decimal_places=2, max_digits=12, verbose_name='Subtotal')),
                ('vat_amount', models.DecimalField(decimal_places=2, default=Decimal('0.00'), max_digits=12, verbose_name='VAT/Tax Amount')),
                ('total_amount', models.DecimalField(decimal_places=2, max_digits=12, verbose_name='Total Amount')),
                ('quantity', models.PositiveIntegerField(default=1, verbose_name='Number of Participants')),
                ('description', models.TextField(blank=True, verbose_name='Description/Notes')),
                ('validity_days', models.PositiveIntegerField(default=30, verbose_name='Validity (Days)')),
                ('status', models.CharField(choices=[('draft', 'Draft'), ('sent', 'Sent to Client'), ('viewed', 'Viewed by Client'), ('accepted', 'Accepted'), ('paid', 'Paid via SmatPay'), ('expired', 'Expired'), ('cancelled', 'Cancelled')], default='draft', max_length=20, verbose_name='Status')),
                ('smatpay_payment_link', models.URLField(blank=True, verbose_name='SmatPay Payment URL')),
                ('smatpay_reference', models.CharField(blank=True, max_length=100, verbose_name='SmatPay Reference')),
                ('email_sent', models.BooleanField(default=False, verbose_name='Email Sent')),
                ('email_sent_at', models.DateTimeField(blank=True, null=True, verbose_name='Email Sent At')),
                ('sms_sent', models.BooleanField(default=False, verbose_name='SMS Sent')),
                ('sms_sent_at', models.DateTimeField(blank=True, null=True, verbose_name='SMS Sent At')),
                ('viewed_at', models.DateTimeField(blank=True, null=True, verbose_name='First Viewed At')),
                ('viewed_count', models.PositiveIntegerField(default=0, verbose_name='View Count')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('expires_at', models.DateTimeField(blank=True, null=True, verbose_name='Expiration Date')),
                ('created_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='quotations_created', to='users.user', verbose_name='Created By')),
            ],
            options={
                'verbose_name': 'Client Quotation',
                'verbose_name_plural': 'Client Quotations',
                'db_table': 'client_quotations',
                'ordering': ['-created_at'],
            },
        ),
        migrations.CreateModel(
            name='QuotationTemplate',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=255, verbose_name='Template Name')),
                ('training_type', models.CharField(choices=[('course', 'AI Certs Course'), ('masterclass', 'Professional Masterclass'), ('learnership', 'Learnership Program')], max_length=20, verbose_name='Training Type')),
                ('course_id', models.IntegerField(blank=True, null=True, verbose_name='Course ID')),
                ('masterclass_id', models.IntegerField(blank=True, null=True, verbose_name='Masterclass ID')),
                ('learnership_id', models.IntegerField(blank=True, null=True, verbose_name='Learnership ID')),
                ('default_description', models.TextField(blank=True, verbose_name='Default Description')),
                ('validity_days', models.PositiveIntegerField(default=30, verbose_name='Default Validity (Days)')),
                ('is_active', models.BooleanField(default=True, verbose_name='Is Active')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'verbose_name': 'Quotation Template',
                'verbose_name_plural': 'Quotation Templates',
                'db_table': 'quotation_templates',
            },
        ),
        migrations.CreateModel(
            name='QuotationItem',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('description', models.CharField(max_length=255, verbose_name='Item Description')),
                ('quantity', models.PositiveIntegerField(default=1, verbose_name='Quantity')),
                ('unit_price', models.DecimalField(decimal_places=2, max_digits=12, verbose_name='Unit Price (USD)')),
                ('total_price', models.DecimalField(decimal_places=2, max_digits=12, verbose_name='Total Price')),
                ('quotation', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='additional_items', to='payments.clientquotation', verbose_name='Quotation')),
            ],
            options={
                'verbose_name': 'Quotation Item',
                'verbose_name_plural': 'Quotation Items',
                'db_table': 'quotation_items',
            },
        ),
        migrations.CreateModel(
            name='QuotationActivityLog',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('activity_type', models.CharField(max_length=50, verbose_name='Activity Type')),
                ('description', models.TextField(verbose_name='Description')),
                ('ip_address', models.GenericIPAddressField(blank=True, null=True, verbose_name='IP Address')),
                ('user_agent', models.TextField(blank=True, verbose_name='User Agent')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('performed_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to='users.user', verbose_name='Performed By')),
                ('quotation', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='activity_logs', to='payments.clientquotation', verbose_name='Quotation')),
            ],
            options={
                'verbose_name': 'Quotation Activity Log',
                'ordering': ['-created_at'],
                'db_table': 'quotation_activity_logs',
            },
        ),
        migrations.AddIndex(
            model_name='clientquotation',
            index=models.Index(fields=['quotation_number'], name='idx_quotation_number'),
        ),
        migrations.AddIndex(
            model_name='clientquotation',
            index=models.Index(fields=['client_email'], name='idx_quotation_client_email'),
        ),
        migrations.AddIndex(
            model_name='clientquotation',
            index=models.Index(fields=['status', 'created_at'], name='idx_quotation_status_created'),
        ),
        migrations.AddIndex(
            model_name='clientquotation',
            index=models.Index(fields=['training_type', 'status'], name='idx_quotation_type_status'),
        ),
    ]
