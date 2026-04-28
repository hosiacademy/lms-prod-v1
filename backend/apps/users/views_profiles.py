# apps/users/views_profiles.py
"""
Profile API endpoints for LMS
- List user profiles
- Get user's own profile
- Update profile picture
- User theme preferences
"""

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from rest_framework.views import APIView
from django.contrib.auth import get_user_model
from .serializers import UserSerializer, UserUpdateSerializer, UserThemePreferenceSerializer
from .models import UserThemePreference
from django.db.models import Q

User = get_user_model()


class ThemePreferenceView(APIView):
    """
    GET /api/v1/user/theme/ - Get current user's theme preference
    POST /api/v1/user/theme/ - Set current user's theme preference
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """Get user's theme preference"""
        try:
            theme_pref, created = UserThemePreference.objects.get_or_create(
                user=request.user,
                defaults={'theme_mode': 'dark'}
            )
            serializer = UserThemePreferenceSerializer(theme_pref)
            return Response(serializer.data)
        except Exception as e:
            return Response(
                {'error': 'Failed to fetch theme preference', 'detail': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    def post(self, request):
        """Set user's theme preference"""
        try:
            theme_mode = request.data.get('theme_mode', 'dark')
            
            # Validate theme_mode
            valid_modes = ['light', 'dark', 'system']
            if theme_mode not in valid_modes:
                return Response(
                    {'error': f'Invalid theme_mode. Must be one of: {valid_modes}'},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # Get or create theme preference
            theme_pref, created = UserThemePreference.objects.get_or_create(
                user=request.user,
                defaults={'theme_mode': theme_mode}
            )

            if not created:
                theme_pref.theme_mode = theme_mode
                theme_pref.save()

            serializer = UserThemePreferenceSerializer(theme_pref)
            return Response(serializer.data)
        except Exception as e:
            return Response(
                {'error': 'Failed to set theme preference', 'detail': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


class ProfilePagination(PageNumberPagination):
    """Custom pagination for profiles"""
    page_size = 20
    page_size_query_param = 'limit'
    max_page_size = 100


@api_view(['GET'])
@permission_classes([AllowAny])
def list_profiles(request):
    """
    List all user profiles

    Query params:
    - page: Page number (default: 1)
    - limit: Results per page (default: 20, max: 100)
    - role_id: Filter by role (1=Admin, 2=Instructor, 3=Student)
    """
    users = User.objects.all().order_by('-date_joined')

    # Filters
    role_id = request.query_params.get('role_id')
    if role_id:
        users = users.filter(role_id=role_id)

    # Paginate
    paginator = ProfilePagination()
    page = paginator.paginate_queryset(users, request)

    if page is not None:
        serializer = UserSerializer(
            page,
            many=True,
            context={'request': request}
        )
        return paginator.get_paginated_response(serializer.data)

    # Fallback without pagination
    serializer = UserSerializer(
        users,
        many=True,
        context={'request': request}
    )
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_my_profile(request):
    """
    Get current user's profile with all details
    """
    serializer = UserSerializer(request.user, context={'request': request})
    return Response(serializer.data)


@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def update_my_profile(request):
    """
    Update current user's profile
    """
    serializer = UserUpdateSerializer(
        request.user,
        data=request.data,
        partial=True,
        context={'request': request}
    )

    if serializer.is_valid():
        serializer.save()
        # Return updated profile
        updated = UserSerializer(request.user, context={'request': request})
        return Response(updated.data)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_profile_picture(request):
    """
    Upload or update profile picture
    """
    image_file = request.FILES.get('image')

    if not image_file:
        return Response(
            {'error': 'No image file provided'},
            status=status.HTTP_400_BAD_REQUEST
        )

    # Save image
    request.user.image = image_file
    request.user.save()

    # Return updated profile
    serializer = UserSerializer(request.user, context={'request': request})

    return Response({
        'message': 'Profile picture updated successfully',
        'profile_picture': serializer.data['profile_picture'],
        'user': serializer.data
    })


@api_view(['GET'])
@permission_classes([AllowAny])
def test_images(request):
    """
    Test endpoint to verify all images are loading correctly
    Returns first 10 users with their image URLs
    """
    users = User.objects.all()[:10]

    results = []
    for user in users:
        profile_pic = user.get_profile_picture_url(request)

        results.append({
            'id': user.id,
            'username': user.username,
            'gender': user.gender,
            'image_field': user.image,
            'profile_picture_url': profile_pic,
            'has_image_field': bool(user.image),
        })

    return Response({
        'message': 'Image URL test - Check if all URLs are accessible',
        'total_users': User.objects.count(),
        'sample_size': len(results),
        'results': results,
        'instructions': [
            'Copy any profile_picture_url and paste in browser',
            'Image should load if URL is correct',
            'If 404, check MEDIA_ROOT and media files',
        ]
    })
