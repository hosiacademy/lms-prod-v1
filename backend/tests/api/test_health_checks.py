"""
API tests for health check endpoints.
"""
import pytest
from django.urls import reverse
from rest_framework import status


@pytest.mark.api
@pytest.mark.django_db
class TestHealthCheckEndpoints:
    """Tests for health check endpoints."""

    def test_simple_health_check(self, api_client):
        """Test simple health check endpoint."""
        url = reverse('health-simple')
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert response.json()['status'] == 'ok'
        assert 'timestamp' in response.json()

    def test_detailed_health_check(self, api_client):
        """Test detailed health check endpoint."""
        url = reverse('health-detailed')
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert data['status'] in ['healthy', 'unhealthy']
        assert 'timestamp' in data
        assert 'environment' in data
        assert 'components' in data
        assert 'database' in data['components']

    def test_health_check_components(self, api_client):
        """Test that all expected components are checked."""
        url = reverse('health-detailed')
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        components = response.json()['components']

        # Check database component
        assert 'database' in components
        assert components['database']['status'] in ['healthy', 'unhealthy']

        # Other components may or may not be present depending on configuration
        if 'redis' in components:
            assert components['redis']['status'] in ['healthy', 'unhealthy', 'skipped']

    def test_readiness_check(self, api_client):
        """Test Kubernetes readiness probe."""
        url = reverse('readiness')
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert response.json()['ready'] is True
        assert 'timestamp' in response.json()

    def test_liveness_check(self, api_client):
        """Test Kubernetes liveness probe."""
        url = reverse('liveness')
        response = api_client.get(url)

        assert response.status_code == status.HTTP_200_OK
        assert response.json()['alive'] is True
        assert 'timestamp' in response.json()

    def test_health_check_no_authentication_required(self, api_client):
        """Test that health checks don't require authentication."""
        # All health check endpoints should work without authentication
        endpoints = [
            reverse('health-simple'),
            reverse('health-detailed'),
            reverse('readiness'),
            reverse('liveness'),
        ]

        for url in endpoints:
            response = api_client.get(url)
            assert response.status_code in [status.HTTP_200_OK, status.HTTP_503_SERVICE_UNAVAILABLE]
            assert response.status_code != status.HTTP_401_UNAUTHORIZED
            assert response.status_code != status.HTTP_403_FORBIDDEN
