"""
Unit tests for User model.
"""
import pytest
from django.contrib.auth import get_user_model
from django.db import IntegrityError

User = get_user_model()


@pytest.mark.unit
@pytest.mark.django_db
class TestUserModel:
    """Tests for the User model."""

    def test_create_user(self):
        """Test creating a regular user."""
        user = User.objects.create_user(
            email='test@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User'
        )

        assert user.email == 'test@example.com'
        assert user.first_name == 'Test'
        assert user.last_name == 'User'
        assert user.is_active is True
        assert user.is_staff is False
        assert user.is_superuser is False
        assert user.check_password('testpass123') is True

    def test_create_superuser(self):
        """Test creating a superuser."""
        user = User.objects.create_superuser(
            email='admin@example.com',
            password='adminpass123',
            first_name='Admin',
            last_name='User'
        )

        assert user.email == 'admin@example.com'
        assert user.is_active is True
        assert user.is_staff is True
        assert user.is_superuser is True

    def test_email_required(self):
        """Test that email is required."""
        with pytest.raises(ValueError):
            User.objects.create_user(
                email='',
                password='testpass123'
            )

    def test_email_unique(self):
        """Test that email must be unique."""
        User.objects.create_user(
            email='test@example.com',
            password='testpass123'
        )

        with pytest.raises(IntegrityError):
            User.objects.create_user(
                email='test@example.com',
                password='testpass456'
            )

    def test_email_normalized(self):
        """Test that email domain is normalized."""
        user = User.objects.create_user(
            email='test@EXAMPLE.COM',
            password='testpass123'
        )

        assert user.email == 'test@example.com'

    def test_user_string_representation(self):
        """Test the string representation of User."""
        user = User.objects.create_user(
            email='test@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User'
        )

        assert str(user) == 'test@example.com' or 'Test User' in str(user)

    def test_password_hashing(self):
        """Test that passwords are hashed."""
        password = 'testpass123'
        user = User.objects.create_user(
            email='test@example.com',
            password=password
        )

        assert user.password != password
        assert user.check_password(password) is True
        assert user.check_password('wrongpassword') is False
