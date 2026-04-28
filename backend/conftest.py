"""
Pytest configuration and shared fixtures for LMS tests.
"""
import pytest
from django.contrib.auth import get_user_model
from django.test import Client
from rest_framework.test import APIClient
from faker import Faker

User = get_user_model()
fake = Faker()


@pytest.fixture
def api_client():
    """Return an API client for testing."""
    return APIClient()


@pytest.fixture
def authenticated_client(db, test_user):
    """Return an authenticated API client."""
    client = APIClient()
    client.force_authenticate(user=test_user)
    return client


@pytest.fixture
def admin_client(db, admin_user):
    """Return an authenticated admin API client."""
    client = APIClient()
    client.force_authenticate(user=admin_user)
    return client


@pytest.fixture
def test_user(db):
    """Create and return a test user."""
    return User.objects.create_user(
        email='test@example.com',
        password='testpass123',
        first_name='Test',
        last_name='User',
        is_active=True
    )


@pytest.fixture
def admin_user(db):
    """Create and return an admin user."""
    return User.objects.create_superuser(
        email='admin@example.com',
        password='adminpass123',
        first_name='Admin',
        last_name='User'
    )


@pytest.fixture
def test_users(db):
    """Create and return multiple test users."""
    users = []
    for i in range(5):
        user = User.objects.create_user(
            email=f'user{i}@example.com',
            password='testpass123',
            first_name=fake.first_name(),
            last_name=fake.last_name(),
            is_active=True
        )
        users.append(user)
    return users


@pytest.fixture
def mock_payment_response():
    """Return a mock successful payment response."""
    return {
        'status': 'success',
        'message': 'Payment processed successfully',
        'data': {
            'transaction_id': fake.uuid4(),
            'amount': 10000,
            'currency': 'USD',
            'status': 'successful',
            'reference': fake.uuid4(),
        }
    }


@pytest.fixture
def mock_failed_payment_response():
    """Return a mock failed payment response."""
    return {
        'status': 'error',
        'message': 'Payment failed',
        'data': {
            'transaction_id': fake.uuid4(),
            'amount': 10000,
            'currency': 'USD',
            'status': 'failed',
            'reference': fake.uuid4(),
        }
    }


@pytest.fixture(autouse=True)
def enable_db_access_for_all_tests(db):
    """Enable database access for all tests."""
    pass


@pytest.fixture
def faker():
    """Return a Faker instance."""
    return fake


# Marker for skipping slow tests
def pytest_addoption(parser):
    parser.addoption(
        "--runslow", action="store_true", default=False, help="run slow tests"
    )


def pytest_configure(config):
    config.addinivalue_line("markers", "slow: marks tests as slow (deselect with '-m \"not slow\"')")


def pytest_collection_modifyitems(config, items):
    if config.getoption("--runslow"):
        # --runslow given in cli: do not skip slow tests
        return
    skip_slow = pytest.mark.skip(reason="need --runslow option to run")
    for item in items:
        if "slow" in item.keywords:
            item.add_marker(skip_slow)
