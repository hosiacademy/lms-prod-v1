# apps/content/views.py
from rest_framework import viewsets, permissions
from rest_framework.views import APIView
from rest_framework.response import Response

from .models import Page, Testimonial, Sponsor, FrontPage
from .serializers import (
    PageSerializer, TestimonialSerializer,
    SponsorSerializer, FrontPageSerializer,
    ContentConfigSerializer
)


class PageViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Page.objects.filter(status=1)
    serializer_class = PageSerializer
    permission_classes = [permissions.AllowAny]
    lookup_field = 'slug'


class TestimonialViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Testimonial.objects.filter(status=1).order_by('-id')
    serializer_class = TestimonialSerializer
    permission_classes = [permissions.AllowAny]


class SponsorViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Sponsor.objects.filter(status=True)
    serializer_class = SponsorSerializer
    permission_classes = [permissions.AllowAny]


class FrontPageViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = FrontPage.objects.filter(status=1)
    serializer_class = FrontPageSerializer
    permission_classes = [permissions.AllowAny]
    lookup_field = 'slug'


class ContentConfigView(APIView):
    """
    GET /api/v1/content/config/
    Returns all static content in one call – perfect for app load.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        serializer = ContentConfigSerializer(instance=None)
        return Response(serializer.data)