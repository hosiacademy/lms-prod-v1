# backend/apps/payments/services/flutterwave_oauth.py
"""
Flutterwave OAuth 2.0 Service

Handles OAuth 2.0 authentication for Flutterwave API v4
Token management with automatic refresh
"""

import requests
import time
import logging
from typing import Optional, Dict
from django.conf import settings
from django.core.cache import cache

logger = logging.getLogger(__name__)


class FlutterwaveOAuth:
    """
    Flutterwave OAuth 2.0 authentication service
    
    Manages access tokens with automatic refresh
    Tokens expire in 10 minutes (600 seconds)
    Auto-refreshes 1 minute before expiry
    """
    
    TOKEN_URL = "https://idp.flutterwave.com/realms/flutterwave/protocol/openid-connect/token"
    CACHE_KEY = "flutterwave_access_token"
    CACHE_TIMEOUT = 540  # Refresh 1 minute before 600s expiry
    
    def __init__(self):
        self.client_id = getattr(settings, 'FLUTTERWAVE_CLIENT_ID', None)
        self.client_secret = getattr(settings, 'FLUTTERWAVE_CLIENT_SECRET', None)
        self._token_cache = None
        self._expires_at = 0
    
    def get_access_token(self, force_refresh: bool = False) -> Optional[str]:
        """
        Get valid access token
        
        Args:
            force_refresh: Force token refresh even if current token is valid
            
        Returns:
            Access token string or None if authentication fails
        """
        # Check cache first
        if not force_refresh:
            cached_token = cache.get(self.CACHE_KEY)
            if cached_token:
                logger.debug("Using cached Flutterwave access token")
                return cached_token
        
        # Check if we have a valid token in memory
        current_time = time.time()
        if self._token_cache and current_time < self._expires_at:
            logger.debug("Using in-memory Flutterwave access token")
            return self._token_cache
        
        # Request new token
        return self._request_new_token()
    
    def _request_new_token(self) -> Optional[str]:
        """
        Request new access token from Flutterwave
        
        Returns:
            Access token or None if request fails
        """
        if not self.client_id or not self.client_secret:
            logger.error("Flutterwave Client ID or Secret not configured")
            return None
        
        payload = {
            'client_id': self.client_id,
            'client_secret': self.client_secret,
            'grant_type': 'client_credentials'
        }
        
        headers = {
            'Content-Type': 'application/x-www-form-urlencoded'
        }
        
        try:
            response = requests.post(
                self.TOKEN_URL,
                data=payload,
                headers=headers,
                timeout=30
            )
            response.raise_for_status()
            
            data = response.json()
            
            if 'access_token' in data:
                access_token = data['access_token']
                expires_in = data.get('expires_in', 600)
                
                # Store in memory
                self._token_cache = access_token
                self._expires_at = time.time() + expires_in - 60  # Refresh 1 min early
                
                # Store in cache for other processes
                cache.set(self.CACHE_KEY, access_token, timeout=expires_in - 60)
                
                logger.info("Successfully obtained Flutterwave access token")
                return access_token
            else:
                logger.error(f"Invalid response from Flutterwave: {data}")
                return None
                
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to get Flutterwave access token: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error getting Flutterwave token: {e}")
            return None
    
    def get_headers(self) -> Dict[str, str]:
        """
        Get headers for API requests with OAuth token
        
        Returns:
            Headers dict with Authorization token
        """
        token = self.get_access_token()
        
        if not token:
            # Fallback to secret key if OAuth fails
            secret_key = getattr(settings, 'FLUTTERWAVE_SECRET_KEY', '')
            if secret_key:
                logger.warning("Using fallback secret key for Flutterwave")
                return {
                    'Authorization': f'Bearer {secret_key}',
                    'Content-Type': 'application/json',
                }
            raise Exception("No valid Flutterwave authentication available")
        
        return {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json',
        }
    
    def verify_token(self) -> bool:
        """
        Verify if current token is valid
        
        Returns:
            True if token is valid, False otherwise
        """
        token = self.get_access_token()
        return token is not None
    
    def revoke_token(self):
        """Revoke current token (force refresh on next request)"""
        self._token_cache = None
        self._expires_at = 0
        cache.delete(self.CACHE_KEY)
        logger.info("Flutterwave access token revoked")


# Singleton instance
flutterwave_oauth = FlutterwaveOAuth()
