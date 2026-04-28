# apps/users/views.py

import requests
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.views import APIView
from django.conf import settings
from datetime import datetime
import hmac
import hashlib

from .models import User
from .serializers import UserSerializer, UserCreateSerializer

# AiCerts (Moodle) Web Service Settings
AICERTS_BASE_URL = settings.AICERTS_SSO_BASE_URL
AICERTS_WSTOKEN = settings.AICERTS_WSTOKEN
AICERTS_SECRET = settings.AICERTS_SECRET_KEY  # Used for HMAC signature in create


class UserListView(generics.ListAPIView):
    """
    GET: Fetch users from AiCerts/Moodle using core_user_get_users.
    Supports search by key (e.g., email, id, username).
    Syncs matched users to local Infix LMS database.
    """
    serializer_class = UserSerializer
    permission_classes = [AllowAny]

    def get(self, request):
        # Support basic filtering by role_id if provided (instead of Moodle sync)
        role_id = request.query_params.get('role_id')
        if role_id:
            users = User.objects.filter(role_id=role_id)
            serializer = self.get_serializer(users, many=True)
            return Response(serializer.data)

        criteria_key = request.query_params.get('key', 'email')  # Default to email
        criteria_value = request.query_params.get('value')
        
        if not criteria_value:
            # If no value and no role_id, return empty list or error
            # But let's return all users if admin? No, safer to require filter.
            return Response(
                {"error": "Missing 'value' or 'role_id' parameter"},
                status=status.HTTP_400_BAD_REQUEST
            )

        params = {
            'wstoken': AICERTS_WSTOKEN,
            'wsfunction': 'core_user_get_users',
            'moodlewsrestformat': 'json',
            'criteria[0][key]': criteria_key,
            'criteria[0][value]': f"%{criteria_value}%"  # Partial match (Moodle supports % wildcard)
        }

        response = requests.get(AICERTS_BASE_URL, params=params, timeout=10)

        if response.status_code != 200:
            return Response(
                {"error": "Failed to connect to AiCerts API", "detail": response.text},
                status=status.HTTP_502_BAD_GATEWAY
            )

        data = response.json()

        if 'exception' in data:
            return Response(data, status=status.HTTP_400_BAD_REQUEST)

        if 'users' not in data:
            return Response({"users": []})

        synced_users = []
        for api_user in data['users']:
            # Map AiCerts/Moodle fields → Local Infix LMS User fields
            local_user, created = User.objects.update_or_create(
                email=api_user.get('email'),
                defaults={
                    'username': api_user.get('username', api_user.get('email', '').split('@')[0]),
                    'name': f"{api_user.get('firstname', '')} {api_user.get('lastname', '')}".strip(),
                    'email': api_user.get('email'),
                    'phone': api_user.get('phone1'),
                    'city': api_user.get('city'),
                    'country': api_user.get('country'),
                    'about': api_user.get('description'),
                    'lang': api_user.get('lang', 'en'),
                    'timezone': api_user.get('timezone', 'UTC'),
                    'profileimageurl': api_user.get('profileimageurl'),
                    'profileimageurlsmall': api_user.get('profileimageurlsmall'),
                    # Optional AiCerts-specific fields (if you want to store them)
                    'partner_id': api_user.get('customfields', {})
                                 .get('partner_id'),  # depends on custom field setup
                    'source': 'aicerts_sync',
                    'is_active': not api_user.get('suspended', False),
                }
            )
            synced_users.append(local_user)

        serializer = UserSerializer(synced_users, many=True)
        return Response(serializer.data)


class UserCreateView(generics.CreateAPIView):
    """
    POST: Create a new user via AiCerts API (core_user_create_users).
    Then sync the created user back to local Infix LMS database.
    Uses HMAC signature with timestamp for secure creation.
    """
    serializer_class = UserCreateSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        validated_data = serializer.validated_data

        # Generate timestamp and HMAC signature
        timestamp = int(datetime.now().timestamp())
        data_str = f"{validated_data['email']}:{timestamp}"
        signature = hmac.new(
            AICERTS_SECRET.encode('utf-8'),
            data_str.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()

        # Prepare Moodle create user parameters
        moodle_params = {
            'wstoken': AICERTS_WSTOKEN,
            'wsfunction': 'core_user_create_users',
            'moodlewsrestformat': 'json',
            'users[0][username]': validated_data['username'],
            'users[0][firstname]': validated_data.get('first_name', validated_data.get('name', 'Student').split()[0]),
            'users[0][lastname]': validated_data.get('last_name', validated_data.get('name', ' ').split()[-1] if len(validated_data.get('name', '').split()) > 1 else ''),
            'users[0][email]': validated_data['email'],
            'users[0][password]': validated_data['password'],
            'users[0][auth]': 'manual',
            'timestamp': timestamp,
            'signature': signature,
        }

        response = requests.post(AICERTS_BASE_URL, data=moodle_params, timeout=15)

        if response.status_code != 200:
            return Response(
                {"error": "Failed to connect to AiCerts", "detail": response.text},
                status=status.HTTP_502_BAD_GATEWAY
            )

        api_response = response.json()

        if isinstance(api_response, list) and len(api_response) > 0:
            created_user_data = api_response[0]
            if 'id' in created_user_data:
                # Successfully created in AiCerts → now sync to local DB
                local_user, _ = User.objects.update_or_create(
                    email=validated_data['email'],
                    defaults={
                        'username': validated_data['username'],
                        'name': validated_data['name'],
                        'email': validated_data['email'],
                        'source': 'aicerts',
                        'is_active': True,
                    }
                )
                local_user.set_password(validated_data['password'])
                local_user.save()

                return Response(
                    UserSerializer(local_user).data,
                    status=status.HTTP_201_CREATED
                )

        # Fallback: return AiCerts raw response if something went wrong
        return Response(api_response, status=status.HTTP_400_BAD_REQUEST)


class CheckEmailView(APIView):
    """
    GET /api/v1/users/check-email/?email=<email>
    Public endpoint used by the enrollment wizard (step 3) to determine
    whether the submitted email already has an account.
    Returns {"exists": true/false, "email": "<email>"}
    """
    permission_classes = [AllowAny]

    def get(self, request):
        email = request.query_params.get('email', '').strip().lower()
        if not email:
            return Response(
                {'error': 'email query parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        exists = User.objects.filter(email__iexact=email).exists()
        return Response({'exists': exists, 'email': email})