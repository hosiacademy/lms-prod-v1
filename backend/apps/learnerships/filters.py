# apps/learnerships/filters.py
import django_filters
from django.db.models import Q, Avg, Count
from .models import LearnershipProgramme


class LearnershipProgrammeFilter(django_filters.FilterSet):
    """
    Comprehensive filters for learnership programmes with geo-spatial and popularity filtering.
    """

    # Text search
    search = django_filters.CharFilter(method='filter_search', label='Search')

    # Basic filters
    # role = django_filters.ChoiceFilter(choices=LearnershipProgramme.ROLE_CHOICES)
    active = django_filters.BooleanFilter()
    # intake_frequency = django_filters.CharFilter(lookup_expr='icontains')

    # Duration filters
    duration_min_weeks = django_filters.NumberFilter(
        field_name='duration_weeks',
        lookup_expr='gte',
        label='Minimum Duration (weeks)'
    )
    duration_max_weeks = django_filters.NumberFilter(
        field_name='duration_weeks',
        lookup_expr='lte',
        label='Maximum Duration (weeks)'
    )
    # duration_min_months = django_filters.NumberFilter(
    #     field_name='duration_months',
    #     lookup_expr='gte',
    #     label='Minimum Duration (months)'
    # )
    # duration_max_months = django_filters.NumberFilter(
    #     field_name='duration_months',
    #     lookup_expr='lte',
    #     label='Maximum Duration (months)'
    # )

    # Cost filters (USD)
    # cost_min = django_filters.NumberFilter(
    #     field_name='cost_usd',
    #     lookup_expr='gte',
    #     label='Minimum Cost (USD)'
    # )
    # cost_max = django_filters.NumberFilter(
    #     field_name='cost_usd',
    #     lookup_expr='lte',
    #     label='Maximum Cost (USD)'
    # )
    # cost_range = django_filters.RangeFilter(field_name='cost_usd', label='Cost Range (USD)')

    # Geographic filters
    # country = django_filters.CharFilter(
    #     field_name='eligible_countries__name',
    #     lookup_expr='icontains',
    #     label='Country'
    # )
    # country_code = django_filters.CharFilter(
    #     field_name='eligible_countries__code',
    #     lookup_expr='iexact',
    #     label='Country Code'
    # )
    # city = django_filters.CharFilter(
    #     field_name='eligible_cities__name',
    #     lookup_expr='icontains',
    #     label='City'
    # )

    # Multiple countries (comma-separated codes)
    # countries = django_filters.CharFilter(method='filter_countries', label='Countries (comma-separated codes)')

    # Popularity filters (requires PopularityMetric from reviews app)
    min_rating = django_filters.NumberFilter(method='filter_min_rating', label='Minimum Rating')
    min_favorites = django_filters.NumberFilter(method='filter_min_favorites', label='Minimum Favorites')
    popular = django_filters.BooleanFilter(method='filter_popular', label='Popular Only')

    # Ordering
    ordering = django_filters.OrderingFilter(
        fields=(
            ('title', 'title'),
            ('duration_weeks', 'duration_weeks'),
            ('created_at', 'created'),
            ('updated_at', 'updated'),
        ),
        field_labels={
            'title': 'Title',
            'duration_weeks': 'Duration (Weeks)',
            'created_at': 'Created Date',
            'updated_at': 'Updated Date',
        }
    )

    class Meta:
        model = LearnershipProgramme
        fields = ['active']

    def filter_search(self, queryset, name, value):
        """Full-text search across multiple fields"""
        return queryset.filter(
            Q(title__icontains=value) |
            Q(focus__icontains=value)
            # Q(description__icontains=value) |
            # Q(overview__icontains=value)
        )

    def filter_countries(self, queryset, name, value):
        """Filter by multiple country codes (comma-separated)"""
        # if not value:
        #     return queryset
        # codes = [code.strip().upper() for code in value.split(',')]
        # return queryset.filter(eligible_countries__code__in=codes).distinct()
        return queryset

    def filter_min_rating(self, queryset, name, value):
        """Filter by minimum average rating"""
        try:
            from apps.reviews.models import PopularityMetric
            from django.contrib.contenttypes.models import ContentType

            ct = ContentType.objects.get_for_model(LearnershipProgramme)
            popular_ids = PopularityMetric.objects.filter(
                content_type=ct,
                rating_average__gte=value
            ).values_list('object_id', flat=True)

            return queryset.filter(id__in=popular_ids)
        except Exception:
            return queryset

    def filter_min_favorites(self, queryset, name, value):
        """Filter by minimum favorite count"""
        try:
            from apps.reviews.models import PopularityMetric
            from django.contrib.contenttypes.models import ContentType

            ct = ContentType.objects.get_for_model(LearnershipProgramme)
            popular_ids = PopularityMetric.objects.filter(
                content_type=ct,
                favorite_count__gte=value
            ).values_list('object_id', flat=True)

            return queryset.filter(id__in=popular_ids)
        except Exception:
            return queryset

    def filter_popular(self, queryset, name, value):
        """Filter only popular items (top 25% by popularity score)"""
        if not value:
            return queryset

        try:
            from apps.reviews.models import PopularityMetric
            from django.contrib.contenttypes.models import ContentType

            ct = ContentType.objects.get_for_model(LearnershipProgramme)

            # Get popularity metrics ordered by score
            metrics = PopularityMetric.objects.filter(
                content_type=ct
            ).order_by('-popularity_score')

            # Get top 25%
            count = metrics.count()
            top_count = max(1, count // 4)
            popular_ids = list(metrics[:top_count].values_list('object_id', flat=True))

            return queryset.filter(id__in=popular_ids)
        except Exception:
            return queryset


    # class Meta:
    #     model = AfricanCity
    #     fields = ['country']
