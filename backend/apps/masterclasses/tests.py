from django.test import TestCase
from .models import Masterclass
from datetime import date, timedelta

class MasterclassModelTests(TestCase):
    def setUp(self):
        self.masterclass = Masterclass.objects.create(
            title="Test Masterclass",
            slug="test-masterclass",
            description="Test description",
            city="Nairobi",
            country_name="Kenya",
            start_date=date.today() + timedelta(days=7),
            end_date=date.today() + timedelta(days=9),
            price=999.99,
            currency="KES",
            status="scheduled",
            max_participants=35,
            current_participants=10,
        )
    
    def test_masterclass_creation(self):
        self.assertEqual(self.masterclass.title, "Test Masterclass")
        self.assertEqual(self.masterclass.slug, "test-masterclass")
        self.assertEqual(self.masterclass.status, "scheduled")
    
    def test_duration_days(self):
        self.assertEqual(self.masterclass.duration_days, 3)
    
    def test_seats_remaining(self):
        self.assertEqual(self.masterclass.seats_remaining, 25)
    
    def test_is_full(self):
        self.assertFalse(self.masterclass.is_full)
        
        # Make it full
        self.masterclass.current_participants = 35
        self.assertTrue(self.masterclass.is_full)
    
    def test_location_display(self):
        self.assertEqual(self.masterclass.location_display, "Nairobi, Kenya")
        
        # With venue
        self.masterclass.venue = "Serena Hotel"
        self.assertEqual(self.masterclass.location_display, "Nairobi, Kenya (Serena Hotel)")
