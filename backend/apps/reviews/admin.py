# apps/reviews/admin.py
from django.contrib import admin
from django.utils.html import format_html
from .models import Rating, Review, Favorite, ViewCount, PopularityMetric


@admin.register(Rating)
class RatingAdmin(admin.ModelAdmin):
    list_display = ['user', 'content_type', 'content_object_link', 'rating_stars', 'created_at']
    list_filter = ['rating', 'content_type', 'created_at']
    search_fields = ['user__username', 'user__email']
    date_hierarchy = 'created_at'
    readonly_fields = ['created_at', 'updated_at']

    def content_object_link(self, obj):
        return format_html('<strong>{}</strong>', str(obj.content_object))
    content_object_link.short_description = 'Content'

    def rating_stars(self, obj):
        stars = '⭐' * obj.rating
        return format_html('<span style="font-size: 16px;">{}</span>', stars)
    rating_stars.short_description = 'Rating'


@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = [
        'user', 'title', 'content_type', 'rating_display',
        'is_approved', 'is_featured', 'helpful_score', 'created_at'
    ]
    list_filter = ['is_approved', 'is_featured', 'content_type', 'created_at']
    search_fields = ['user__username', 'title', 'text']
    date_hierarchy = 'created_at'
    readonly_fields = ['created_at', 'updated_at', 'helpful_count', 'unhelpful_count']
    list_editable = ['is_approved', 'is_featured']

    fieldsets = (
        ('Review Information', {
            'fields': ('user', 'content_type', 'object_id', 'title', 'text', 'rating')
        }),
        ('Moderation', {
            'fields': ('is_approved', 'is_featured')
        }),
        ('Helpfulness', {
            'fields': ('helpful_count', 'unhelpful_count')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at')
        }),
    )

    def rating_display(self, obj):
        if obj.rating:
            stars = '⭐' * obj.rating
            return format_html('<span>{}</span>', stars)
        return '-'
    rating_display.short_description = 'Rating'

    def helpful_score(self, obj):
        score = obj.helpfulness_score
        color = 'green' if score >= 70 else 'orange' if score >= 40 else 'red'
        return format_html(
            '<span style="color: {};">{:.0f}%</span>',
            color, score
        )
    helpful_score.short_description = 'Helpfulness'


@admin.register(Favorite)
class FavoriteAdmin(admin.ModelAdmin):
    list_display = ['user', 'content_type', 'content_object_link', 'collection', 'created_at']
    list_filter = ['content_type', 'collection', 'created_at']
    search_fields = ['user__username', 'user__email']
    date_hierarchy = 'created_at'
    readonly_fields = ['created_at']

    def content_object_link(self, obj):
        return format_html('<strong>{}</strong>', str(obj.content_object))
    content_object_link.short_description = 'Content'


@admin.register(ViewCount)
class ViewCountAdmin(admin.ModelAdmin):
    list_display = ['content_type', 'content_object_link', 'user', 'ip_address', 'viewed_at']
    list_filter = ['content_type', 'viewed_at']
    search_fields = ['user__username', 'ip_address', 'session_key']
    date_hierarchy = 'viewed_at'
    readonly_fields = ['viewed_at']

    def content_object_link(self, obj):
        return format_html('<strong>{}</strong>', str(obj.content_object))
    content_object_link.short_description = 'Content'


@admin.register(PopularityMetric)
class PopularityMetricAdmin(admin.ModelAdmin):
    list_display = [
        'content_type', 'content_object_link', 'popularity_score',
        'rating_average', 'favorite_count', 'view_count_30d', 'last_updated'
    ]
    list_filter = ['content_type', 'last_updated']
    readonly_fields = [
        'view_count_total', 'view_count_30d', 'view_count_7d',
        'favorite_count', 'rating_average', 'rating_count',
        'review_count', 'popularity_score', 'last_updated'
    ]
    ordering = ['-popularity_score']

    actions = ['update_metrics']

    def content_object_link(self, obj):
        return format_html('<strong>{}</strong>', str(obj.content_object))
    content_object_link.short_description = 'Content'

    def update_metrics(self, request, queryset):
        """Admin action to update metrics"""
        for metric in queryset:
            metric.update_metrics()
        self.message_user(request, f'{queryset.count()} metrics updated successfully.')
    update_metrics.short_description = 'Update selected metrics'
