from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.generics import ListAPIView
from django.shortcuts import get_object_or_404
from django.db import transaction
from .models import LearnershipProgramme, LearnershipEnrollment, PrerequisiteEvidence
from .serializers import (
    LearnershipProgrammeSerializer,
    LearnershipEnrollmentSerializer,
    LearnershipEnrollmentCreateSerializer,
    LearnershipEnrollmentDetailSerializer,
    PrerequisiteEvidenceSerializer,
)


# -----------------------------
# Learnership Programme API
# -----------------------------
class LearnershipProgrammeViewSet(viewsets.ModelViewSet):
    queryset = LearnershipProgramme.objects.all()
    serializer_class = LearnershipProgrammeSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        queryset = LearnershipProgramme.objects.filter(active=True, is_offered=True)

        specialization = self.request.query_params.get('specialization')
        category = self.request.query_params.get('category')
        country = self.request.query_params.get('country')
        status = self.request.query_params.get('status')
        nqf_level = self.request.query_params.get('nqf_level')
        delivery_mode = self.request.query_params.get('delivery_mode')

        if self.request.user.is_authenticated and self.request.user.role_id == 2:
            instructor_param = self.request.query_params.get('instructor', None)
            if instructor_param == 'me':
                queryset = queryset.filter(instructor=self.request.user)

        if category:
            queryset = queryset.filter(category=category)
        if specialization:
            queryset = queryset.filter(specialization=specialization)
        if country:
            queryset = queryset.filter(country=country)
        if status:
            queryset = queryset.filter(status=status)
        if nqf_level:
            queryset = queryset.filter(nqf_level=nqf_level)
        if delivery_mode:
            queryset = queryset.filter(delivery_mode=delivery_mode)

        return queryset

    @action(detail=False, methods=['get'])
    def my_learnerships(self, request):
        """Get learnerships assigned to the current instructor"""
        if not request.user.is_authenticated or request.user.role_id != 2:
            return Response(
                {'error': 'Only instructors can access this endpoint'},
                status=403
            )

        learnerships = LearnershipProgramme.objects.filter(
            instructor=request.user,
            active=True
        )
        serializer = self.get_serializer(learnerships, many=True)
        return Response(serializer.data)


# -----------------------------------------------
# Dedicated Category Views (separate API endpoints)
# -----------------------------------------------

class CybersecurityLearnershipListView(ListAPIView):
    """
    GET /api/v1/learnerships/programmes/cybersecurity/
    Returns only active, offered learnerships in the 'Cybersecurity' category.
    """
    serializer_class = LearnershipProgrammeSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        return LearnershipProgramme.objects.filter(
            active=True,
            is_offered=True,
            category='Cybersecurity',
        ).order_by('title')


class AIBlockchainLearnershipListView(ListAPIView):
    """
    GET /api/v1/learnerships/programmes/ai-blockchain/
    Returns only active, offered learnerships in the 'AI & Blockchain' category.
    """
    serializer_class = LearnershipProgrammeSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def get_queryset(self):
        return LearnershipProgramme.objects.filter(
            active=True,
            is_offered=True,
            category='AI & Blockchain',
        ).order_by('title')


# -----------------------------
# Learnership Enrollment API
# -----------------------------
class LearnershipEnrollmentViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing learnership enrollments.
    
    Endpoints:
    - POST /api/v1/learnerships/enrollments/ - Create enrollment (individual or corporate)
    - GET /api/v1/learnerships/enrollments/ - List enrollments
    - GET /api/v1/learnerships/enrollments/{id}/ - Get enrollment details
    - POST /api/v1/learnerships/enrollments/{id}/upload_evidence/ - Upload prerequisite evidence
    - POST /api/v1/learnerships/enrollments/{id}/confirm/ - Confirm enrollment (admin)
    - POST /api/v1/learnerships/enrollments/{id}/reject/ - Reject enrollment (admin)
    """
    queryset = LearnershipEnrollment.objects.all()
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        if self.action == 'create':
            return LearnershipEnrollmentCreateSerializer
        elif self.action in ['retrieve', 'list']:
            return LearnershipEnrollmentDetailSerializer
        return LearnershipEnrollmentSerializer

    def get_queryset(self):
        user = self.request.user
        
        # Admins can see all enrollments
        if user.is_admin:
            return self.queryset
        
        # Students see only their own enrollments
        if user.role_id == 3:  # Student/Learner
            return self.queryset.filter(user=user)
        
        # Instructors can see enrollments for their assigned programmes
        if user.role_id == 2:  # Instructor
            programme_ids = LearnershipProgramme.objects.filter(
                instructor=user
            ).values_list('id', flat=True)
            return self.queryset.filter(programme_id__in=programme_ids)
        
        return self.queryset.none()

    @transaction.atomic
    def create(self, request, *args, **kwargs):
        """
        Create a new learnership enrollment.
        Supports both individual and corporate enrollments.
        """
        serializer = self.get_serializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        enrollment = serializer.save()

        # Return enrollment details
        return Response(
            LearnershipEnrollmentDetailSerializer(enrollment).data,
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['post'], url_path='upload_evidence')
    def upload_evidence(self, request, pk=None):
        """
        Upload prerequisite evidence for an enrollment.
        """
        enrollment = self.get_object()
        
        # Check if user can upload evidence for this enrollment
        if enrollment.user != request.user and not request.user.is_admin:
            return Response(
                {'error': 'You do not have permission to upload evidence for this enrollment'},
                status=status.HTTP_403_FORBIDDEN
            )

        serializer = PrerequisiteEvidenceSerializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        
        # Set enrollment and save
        evidence = serializer.save(enrollment=enrollment)
        
        # Update enrollment status
        enrollment.auto_update_status()
        
        return Response(
            PrerequisiteEvidenceSerializer(evidence).data,
            status=status.HTTP_201_CREATED
        )

    @action(detail=True, methods=['post'], url_path='confirm')
    def confirm_enrollment(self, request, pk=None):
        """
        Confirm enrollment after prerequisite verification (Admin only).
        """
        if not request.user.is_admin:
            return Response(
                {'error': 'Only administrators can confirm enrollments'},
                status=status.HTTP_403_FORBIDDEN
            )

        enrollment = self.get_object()
        reason = request.data.get('reason', 'Prerequisites verified and approved')
        
        enrollment.confirm_enrollment(verified_by=request.user, reason=reason)
        
        return Response({
            'message': 'Enrollment confirmed successfully',
            'status': enrollment.status,
        })

    @action(detail=True, methods=['post'], url_path='reject')
    def reject_enrollment(self, request, pk=None):
        """
        Reject enrollment due to prerequisites not being met (Admin only).
        """
        if not request.user.is_admin:
            return Response(
                {'error': 'Only administrators can reject enrollments'},
                status=status.HTTP_403_FORBIDDEN
            )

        enrollment = self.get_object()
        reason = request.data.get('reason', 'Prerequisites not met')
        
        enrollment.reject_enrollment(verified_by=request.user, reason=reason)
        
        return Response({
            'message': 'Enrollment rejected',
            'status': enrollment.status,
        })

    @action(detail=False, methods=['get'], url_path='my-enrollments')
    def my_enrollments(self, request):
        """Get current user's learnership enrollments"""
        enrollments = self.get_queryset()
        serializer = self.get_serializer(enrollments, many=True)
        return Response(serializer.data)


# -----------------------------
# Corporate Enrollment Endpoint
# -----------------------------
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def create_corporate_enrollment(request):
    """
    Create a corporate learnership enrollment.
    
    Body:
    {
        "programme_id": 1,
        "company": {
            "name": "...",
            "registration_number": "...",
            "tax_number": "...",
            "contact_person": "...",
            "email": "...",
            "phone": "...",
            "address": "..."
        },
        "learners": [
            {"full_name": "...", "email": "..."},
            ...
        ],
        "payment_option": "installments"
    }
    """
    from .serializers import LearnershipEnrollmentCreateSerializer
    
    data = request.data.copy()
    data['company'] = data.get('company', {})
    data['corporate_learners'] = data.get('learners', [])
    data['programme'] = data.pop('programme_id', None)
    
    serializer = LearnershipEnrollmentCreateSerializer(
        data=data,
        context={'request': request}
    )
    serializer.is_valid(raise_exception=True)
    enrollment = serializer.save()
    
    return Response(
        LearnershipEnrollmentDetailSerializer(enrollment).data,
        status=status.HTTP_201_CREATED
    )
