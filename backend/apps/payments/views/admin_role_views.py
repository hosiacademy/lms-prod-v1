from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from django.contrib.auth import get_user_model
from ..models import AdminRoleRequest, AdminRole, AdminCountryAccess
from ..serializers import AdminRoleRequestSerializer

User = get_user_model()

class AdminRoleRequestViewSet(viewsets.ModelViewSet):
    """
    ViewSet for AdminRoleRequest.
    Allows staff to request admin roles and System Admins to approve them.
    """
    queryset = AdminRoleRequest.objects.all()
    serializer_class = AdminRoleRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser or AdminRole.is_system_admin(user):
            return AdminRoleRequest.objects.all()
        return AdminRoleRequest.objects.filter(requested_by=user)

    def perform_create(self, serializer):
        serializer.save(requested_by=self.request.user)

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def approve(self, request, pk=None):
        """
        Approve an admin role request and create the necessary records.
        """
        role_request = self.get_object()
        
        if role_request.status != 'pending':
            return Response(
                {'error': f'Request is already {role_request.status}'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # 1. Ensure User exists or create one
            user, created = User.objects.get_or_create(
                email=role_request.candidate_email,
                defaults={
                    'username': role_request.candidate_email,
                    'first_name': role_request.candidate_name.split(' ')[0],
                    'last_name': ' '.join(role_request.candidate_name.split(' ')[1:]),
                    'is_staff': True
                }
            )
            
            if created:
                user.set_password('HosiAdmin2026!')
                user.save()

            # 2. Create AdminRole
            admin_role, _ = AdminRole.objects.get_or_create(
                user=user,
                role_type=role_request.proposed_role,
                defaults={'is_active': True}
            )

            # 3. Assign Country Access if provided
            if role_request.target_country:
                AdminCountryAccess.objects.get_or_create(
                    admin_role=admin_role,
                    country=role_request.target_country,
                    defaults={'is_active': True}
                )

            # 4. Update Request Status
            role_request.status = 'approved'
            role_request.processed_by = request.user
            role_request.processed_at = timezone.now()
            role_request.save()

            return Response({
                'message': 'Admin role request approved and credentials created.',
                'email': user.email,
                'temporary_password': 'HosiAdmin2026!' if created else 'Existing Password'
            })

        except Exception as e:
            return Response(
                {'error': f'Approval failed: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'], permission_classes=[permissions.IsAdminUser])
    def reject(self, request, pk=None):
        """Reject an admin role request."""
        role_request = self.get_object()
        role_request.status = 'rejected'
        role_request.processed_by = request.user
        role_request.processed_at = timezone.now()
        role_request.save()
        return Response({'message': 'Request rejected.'})
