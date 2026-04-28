# apps/content/serializers.py
"""
Serializers for static and dynamic content pages.

These expose About Us, Privacy Policy, Testimonials, Sponsors,
custom Pages, and Front Pages to the Flutter frontend.

All content is database-driven, allowing instant updates
to reflect African stories, voices, and partnerships.
"""

from rest_framework import serializers

from .models import (
    Page, AboutPage, PrivacyPolicy,
    Testimonial, Sponsor, FrontPage
)


class PageSerializer(serializers.ModelSerializer):
    """
    Generic static pages (Terms, FAQ, Contact, etc.).
    """
    class Meta:
        model = Page
        fields = (
            'id', 'title', 'slug', 'heading',
            'description', 'breadcumb_image', 'status'
        )


class AboutPageSerializer(serializers.ModelSerializer):
    """
    Singleton About Us page – tells your powerful African story.
    """
    images = serializers.SerializerMethodField()

    class Meta:
        model = AboutPage
        fields = (
            'who_we_are', 'banner_title',
            'story_title', 'story_description',
            'teacher_title', 'teacher_details',
            'course_title', 'course_details',
            'student_title', 'student_details',
            'images'
        )

    def get_images(self, obj):
        return {
            "hero1": obj.image1,
            "hero2": obj.image2,
            "hero3": obj.image3,
            "counter_bg": obj.image4,
        }


class PrivacyPolicySerializer(serializers.ModelSerializer):
    """
    Privacy Policy – builds trust with African users.
    """
    class Meta:
        model = PrivacyPolicy
        fields = (
            'description', 'general', 'personal_data',
            'voluntary_disclosure', 'children_privacy',
            'information_about_cookies', 'thirt_party_adv',
            'other_sites', 'teacher', 'student',
            'business_transfer', 'status'
        )


class TestimonialSerializer(serializers.ModelSerializer):
    """
    Success stories from African students and instructors.
    Social proof with authentic voices.
    """
    class Meta:
        model = Testimonial
        fields = (
            'id', 'body', 'author', 'profession',
            'image', 'star', 'status'
        )


class SponsorSerializer(serializers.ModelSerializer):
    """
    Partners and sponsors – proudly showcase African organizations.
    """
    class Meta:
        model = Sponsor
        fields = ('id', 'title', 'image', 'status')


class FrontPageSerializer(serializers.ModelSerializer):
    """
    Additional front-facing static pages (beyond homepage).
    """
    class Meta:
        model = FrontPage
        fields = (
            'id', 'name', 'title', 'sub_title',
            'details', 'slug', 'banner', 'status', 'is_static'
        )


# Composite serializer for complete content bundle
class ContentConfigSerializer(serializers.Serializer):
    """
    Master endpoint response – all static content in one efficient call.
    Ideal for app startup or cache refresh.
    """
    about = AboutPageSerializer(read_only=True)
    privacy_policy = PrivacyPolicySerializer(read_only=True)
    testimonials = TestimonialSerializer(many=True, read_only=True)
    sponsors = SponsorSerializer(many=True, read_only=True)
    pages = PageSerializer(many=True, read_only=True)
    front_pages = FrontPageSerializer(many=True, read_only=True)

    def to_representation(self, instance):
        return {
            'about': AboutPage.objects.first(),
            'privacy_policy': PrivacyPolicy.objects.first(),
            'testimonials': Testimonial.objects.filter(status=1).order_by('-id'),
            'sponsors': Sponsor.objects.filter(status=True),
            'pages': Page.objects.filter(status=1),
            'front_pages': FrontPage.objects.filter(status=1, is_static=1),
        }