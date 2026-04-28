# apps/reviews/models.py
from django.db import models
from django.contrib.auth import get_user_model
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from django.db.models import Avg, Count

User = get_user_model()


class Rating(models.Model):
    """
    Generic rating system for any content (courses, learnerships, masterclasses).
    Uses Django's ContentType framework for flexibility.
    """
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='ratings',
        verbose_name=_("User")
    )

    # Generic relation to any model
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey('content_type', 'object_id')

    # Rating value (1-5 stars)
    rating = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        verbose_name=_("Rating"),
        help_text=_("Rating from 1 to 5 stars")
    )

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))
    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    class Meta:
        db_table = 'reviews_rating'
        verbose_name = _("Rating")
        verbose_name_plural = _("Ratings")
        unique_together = ['user', 'content_type', 'object_id']
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['content_type', 'object_id']),
            models.Index(fields=['user', 'content_type']),
            models.Index(fields=['rating']),
            models.Index(fields=['-created_at']),
        ]

    def __str__(self):
        return f"{self.user.username} - {self.rating}★ on {self.content_object}"

    @classmethod
    def get_average_rating(cls, content_type, object_id):
        """Get average rating for an object"""
        result = cls.objects.filter(
            content_type=content_type,
            object_id=object_id
        ).aggregate(
            avg_rating=Avg('rating'),
            count=Count('id')
        )
        return {
            'average': round(result['avg_rating'], 2) if result['avg_rating'] else 0,
            'count': result['count']
        }


class Review(models.Model):
    """
    Text reviews with optional rating for any content.
    """
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='reviews',
        verbose_name=_("User")
    )

    # Generic relation
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey('content_type', 'object_id')

    # Review content
    title = models.CharField(
        max_length=200,
        verbose_name=_("Title"),
        help_text=_("Review title/summary")
    )
    text = models.TextField(verbose_name=_("Review Text"))

    # Optional rating (if user wants both rating and review)
    rating = models.IntegerField(
        null=True,
        blank=True,
        validators=[MinValueValidator(1), MaxValueValidator(5)],
        verbose_name=_("Rating")
    )

    # Moderation
    is_approved = models.BooleanField(default=True, verbose_name=_("Approved"))
    is_featured = models.BooleanField(default=False, verbose_name=_("Featured"))

    # Helpfulness tracking
    helpful_count = models.IntegerField(default=0, verbose_name=_("Helpful Count"))
    unhelpful_count = models.IntegerField(default=0, verbose_name=_("Unhelpful Count"))

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))
    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    class Meta:
        db_table = 'reviews_review'
        verbose_name = _("Review")
        verbose_name_plural = _("Reviews")
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['content_type', 'object_id']),
            models.Index(fields=['user']),
            models.Index(fields=['is_approved']),
            models.Index(fields=['is_featured']),
            models.Index(fields=['-created_at']),
            models.Index(fields=['-helpful_count']),
        ]

    def __str__(self):
        return f"{self.user.username} - {self.title}"

    @property
    def helpfulness_score(self):
        """Calculate helpfulness score"""
        total = self.helpful_count + self.unhelpful_count
        if total == 0:
            return 0
        return (self.helpful_count / total) * 100


class Favorite(models.Model):
    """
    User favorites/likes for any content.
    Used for "like" functionality and popularity tracking.
    """
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='favorites',
        verbose_name=_("User")
    )

    # Generic relation
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey('content_type', 'object_id')

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))

    # Optional categorization
    collection = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("Collection"),
        help_text=_("Optional collection name (e.g., 'wishlist', 'completed')")
    )

    class Meta:
        db_table = 'reviews_favorite'
        verbose_name = _("Favorite")
        verbose_name_plural = _("Favorites")
        unique_together = ['user', 'content_type', 'object_id', 'collection']
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['content_type', 'object_id']),
            models.Index(fields=['user', 'content_type']),
            models.Index(fields=['-created_at']),
            models.Index(fields=['collection']),
        ]

    def __str__(self):
        return f"{self.user.username} ❤️ {self.content_object}"

    @classmethod
    def get_favorite_count(cls, content_type, object_id):
        """Get total favorites for an object"""
        return cls.objects.filter(
            content_type=content_type,
            object_id=object_id
        ).count()

    @classmethod
    def is_favorited_by_user(cls, user, content_type, object_id):
        """Check if user has favorited an object"""
        return cls.objects.filter(
            user=user,
            content_type=content_type,
            object_id=object_id
        ).exists()


class ViewCount(models.Model):
    """
    Track views/impressions for popularity metrics.
    """
    # Generic relation
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey('content_type', 'object_id')

    user = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='views',
        verbose_name=_("User")
    )

    # Session tracking for anonymous users
    session_key = models.CharField(
        max_length=40,
        blank=True,
        null=True,
        verbose_name=_("Session Key")
    )

    ip_address = models.GenericIPAddressField(
        blank=True,
        null=True,
        verbose_name=_("IP Address")
    )

    viewed_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Viewed At"))

    class Meta:
        db_table = 'reviews_viewcount'
        verbose_name = _("View Count")
        verbose_name_plural = _("View Counts")
        ordering = ['-viewed_at']
        indexes = [
            models.Index(fields=['content_type', 'object_id']),
            models.Index(fields=['user']),
            models.Index(fields=['session_key']),
            models.Index(fields=['-viewed_at']),
        ]

    def __str__(self):
        return f"View of {self.content_object} at {self.viewed_at}"

    @classmethod
    def get_view_count(cls, content_type, object_id, days=None):
        """Get view count for an object, optionally filtered by days"""
        queryset = cls.objects.filter(
            content_type=content_type,
            object_id=object_id
        )

        if days:
            from datetime import timedelta
            since = timezone.now() - timedelta(days=days)
            queryset = queryset.filter(viewed_at__gte=since)

        return queryset.count()

    @classmethod
    def record_view(cls, content_type, object_id, user=None, session_key=None, ip_address=None):
        """Record a view"""
        return cls.objects.create(
            content_type=content_type,
            object_id=object_id,
            user=user,
            session_key=session_key,
            ip_address=ip_address
        )


class PopularityMetric(models.Model):
    """
    Aggregated popularity metrics for efficient filtering.
    Updated periodically via Celery task.
    """
    # Generic relation
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE)
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey('content_type', 'object_id')

    # Metrics
    view_count_total = models.IntegerField(default=0, verbose_name=_("Total Views"))
    view_count_30d = models.IntegerField(default=0, verbose_name=_("Views (30 days)"))
    view_count_7d = models.IntegerField(default=0, verbose_name=_("Views (7 days)"))

    favorite_count = models.IntegerField(default=0, verbose_name=_("Favorites"))

    rating_average = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=0.00,
        verbose_name=_("Average Rating")
    )
    rating_count = models.IntegerField(default=0, verbose_name=_("Rating Count"))

    review_count = models.IntegerField(default=0, verbose_name=_("Review Count"))

    # Popularity score (calculated)
    popularity_score = models.FloatField(
        default=0.0,
        verbose_name=_("Popularity Score"),
        help_text=_("Calculated score based on all metrics")
    )

    last_updated = models.DateTimeField(auto_now=True, verbose_name=_("Last Updated"))

    class Meta:
        db_table = 'reviews_popularitymetric'
        verbose_name = _("Popularity Metric")
        verbose_name_plural = _("Popularity Metrics")
        unique_together = ['content_type', 'object_id']
        ordering = ['-popularity_score']
        indexes = [
            models.Index(fields=['content_type', 'object_id']),
            models.Index(fields=['-popularity_score']),
            models.Index(fields=['-rating_average']),
            models.Index(fields=['-favorite_count']),
            models.Index(fields=['-view_count_30d']),
        ]

    def __str__(self):
        return f"Popularity: {self.content_object} (Score: {self.popularity_score})"

    def calculate_popularity_score(self):
        """
        Calculate popularity score based on multiple factors.
        Weights can be adjusted based on business requirements.
        """
        score = (
            (self.view_count_30d * 0.3) +
            (self.favorite_count * 5) +
            (self.rating_average * 10) +
            (self.review_count * 3)
        )
        return round(score, 2)

    def update_metrics(self):
        """Update all metrics for this object"""
        ct = self.content_type
        obj_id = self.object_id

        # Update view counts
        self.view_count_total = ViewCount.get_view_count(ct, obj_id)
        self.view_count_30d = ViewCount.get_view_count(ct, obj_id, days=30)
        self.view_count_7d = ViewCount.get_view_count(ct, obj_id, days=7)

        # Update favorite count
        self.favorite_count = Favorite.get_favorite_count(ct, obj_id)

        # Update rating metrics
        rating_data = Rating.get_average_rating(ct, obj_id)
        self.rating_average = rating_data['average']
        self.rating_count = rating_data['count']

        # Update review count
        self.review_count = Review.objects.filter(
            content_type=ct,
            object_id=obj_id,
            is_approved=True
        ).count()

        # Calculate popularity score
        self.popularity_score = self.calculate_popularity_score()

        self.save()

    @classmethod
    def get_or_create_for_object(cls, obj):
        """Get or create popularity metric for an object"""
        content_type = ContentType.objects.get_for_model(obj)
        metric, created = cls.objects.get_or_create(
            content_type=content_type,
            object_id=obj.id
        )
        if created:
            metric.update_metrics()
        return metric
