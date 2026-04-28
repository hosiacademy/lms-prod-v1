from django.test import TestCase, Client
from django.urls import reverse
from django.conf import settings
from apps.payments.models import Checkout, PesapalPayment
import json
import hmac, hashlib


class PesapalWebhookTests(TestCase):
    def setUp(self):
        self.client = Client()
        self.checkout = Checkout.objects.create(tracking='test123', user_id=1, purchase_price=10.0, price=10.0)
        self.url = reverse('payments:pesapal-webhook')
        self.secret = getattr(settings, 'PESAPAL_SECRET', 'testsecret')

    def _sign(self, payload_bytes):
        return hmac.new(self.secret.encode(), payload_bytes, hashlib.sha256).hexdigest()

    def test_pesapal_webhook_creates_payment_and_order(self):
        data = {
            'reference': 'ref_abc123',
            'amount': '10.00',
            'currency': 'USD',
            'status': 'completed',
            'tracking_id': 'test123',
            'first_name': 'Test',
            'last_name': 'User',
            'email': 'test@example.com'
        }
        payload = json.dumps(data).encode()
        signature = self._sign(payload)
        resp = self.client.post(self.url, data=payload, content_type='application/json', **{'HTTP_X_PESAPAL_SIGNATURE': signature})
        self.assertEqual(resp.status_code, 200)
        p = PesapalPayment.objects.filter(reference='ref_abc123').first()
        self.assertIsNotNone(p)
        self.assertEqual(p.status, 'processed')
        c = Checkout.objects.get(tracking='test123')
        self.assertTrue(c.status)
