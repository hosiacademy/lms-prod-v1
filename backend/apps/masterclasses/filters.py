# apps/masterclasses/filters.py
import django_filters
from django.db.models import Q
from django.utils import timezone
from .models import Masterclass


class MasterclassFilter(django_filters.FilterSet):
    """
    Comprehensive filters for masterclasses with geo-spatial, date, and popularity filtering.
    """

    # Text search
    search = django_filters.CharFilter(method='filter_search', label='Search')

    # Basic filters
    stream_type = django_filters.ChoiceFilter(choices=Masterclass.STREAM_TYPE_CHOICES)
    tier = django_filters.ChoiceFilter(choices=Masterclass.TIER_CHOICES)
    status = django_filters.ChoiceFilter(choices=Masterclass.STATUS_CHOICES)
    is_featured = django_filters.BooleanFilter()
    is_full = django_filters.BooleanFilter()

    # Focus area filters
    focus_area = django_filters.CharFilter(lookup_expr='icontains', label='Focus Area')
    focus_area_exact = django_filters.CharFilter(
        field_name='focus_area',
        lookup_expr='iexact',
        label='Focus Area (Exact)'
    )

    # Geographic filters
    country = django_filters.CharFilter(
        field_name='country_name',
        lookup_expr='icontains',
        label='Country'
    )
    country_code = django_filters.CharFilter(
        field_name='country_code',
        lookup_expr='iexact',
        label='Country Code'
    )
    city = django_filters.CharFilter(
        field_name='city',
        lookup_expr='icontains',
        label='City'
    )

    # Multiple countries (comma-separated codes)
    countries = django_filters.CharFilter(method='filter_countries', label='Countries (comma-separated codes)')

    # Venue filters
    venue = django_filters.CharFilter(
        field_name='venue',
        lookup_expr='icontains',
        label='Venue'
    )
    has_venue = django_filters.BooleanFilter(method='filter_has_venue', label='Has Venue')

    # Date filters
    start_date_after = django_filters.DateFilter(
        field_name='start_date',
        lookup_expr='gte',
        label='Starts After'
    )
    start_date_before = django_filters.DateFilter(
        field_name='start_date',
        lookup_expr='lte',
        label='Starts Before'
    )
    end_date_after = django_filters.DateFilter(
        field_name='end_date',
        lookup_expr='gte',
        label='Ends After'
    )
    end_date_before = django_filters.DateFilter(
        field_name='end_date',
        lookup_expr='lte',
        label='Ends Before'
    )

    # Date range filters
    start_date_range = django_filters.DateFromToRangeFilter(
        field_name='start_date',
        label='Start Date Range'
    )
    end_date_range = django_filters.DateFromToRangeFilter(
        field_name='end_date',
        label='End Date Range'
    )

    # Convenience date filters
    upcoming = django_filters.BooleanFilter(method='filter_upcoming', label='Upcoming')
    ongoing = django_filters.BooleanFilter(method='filter_ongoing', label='Ongoing')
    past = django_filters.BooleanFilter(method='filter_past', label='Past')

    # Price filters
    price_min = django_filters.NumberFilter(
        field_name='price',
        lookup_expr='gte',
        label='Minimum Price'
    )
    price_max = django_filters.NumberFilter(
        field_name='price',
        lookup_expr='lte',
        label='Maximum Price'
    )
    price_range = django_filters.RangeFilter(
        field_name='price',
        label='Price Range'
    )
    is_free = django_filters.BooleanFilter(method='filter_free', label='Free Only')

    # Capacity filters
    has_seats = django_filters.BooleanFilter(method='filter_has_seats', label='Has Available Seats')
    seats_min = django_filters.NumberFilter(
        field_name='seats_remaining',
        lookup_expr='gte',
        label='Minimum Seats Available'
    )

    # Popularity filters
    min_rating = django_filters.NumberFilter(method='filter_min_rating', label='Minimum Rating')
    min_favorites = django_filters.NumberFilter(method='filter_min_favorites', label='Minimum Favorites')
    min_views = django_filters.NumberFilter(method='filter_min_views', label='Minimum Views (30 days)')
    popular = django_filters.BooleanFilter(method='filter_popular', label='Popular Only')

    # Provider course filters
    has_provider_courses = django_filters.BooleanFilter(
        method='filter_has_provider_courses',
        label='Has Provider Courses'
    )

    # Ordering
    ordering = django_filters.OrderingFilter(
        fields=(
            ('title', 'title'),
            ('start_date', 'start_date'),
            ('end_date', 'end_date'),
            ('price', 'price'),
            ('seats_remaining', 'seats'),
            ('created_at', 'created'),
        ),
        field_labels={
            'title': 'Title',
            'start_date': 'Start Date',
            'end_date': 'End Date',
            'price': 'Price',
            'seats_remaining': 'Available Seats',
            'created_at': 'Created Date',
        }
    )

    class Meta:
        model = Masterclass
        fields = ['stream_type', 'tier', 'status', 'is_featured', 'is_full']

    def filter_search(self, queryset, name, value):
        """Full-text search across multiple fields"""
        return queryset.filter(
            Q(title__icontains=value) |
            Q(description__icontains=value) |
            Q(focus_area__icontains=value) |
            Q(venue__icontains=value) |
            Q(city__icontains=value) |
            Q(country_name__icontains=value)
        )

    def filter_countries(self, queryset, name, value):
        """Filter by multiple country codes (comma-separated)"""
        if not value:
            return queryset
        codes = [code.strip().upper() for code in value.split(',')]
        return queryset.filter(country_code__in=codes)

    def filter_has_venue(self, queryset, name, value):
        """Filter masterclasses with/without venue"""
        if value:
            return queryset.exclude(Q(venue__isnull=True) | Q(venue=''))
        return queryset.filter(Q(venue__isnull=True) | Q(venue=''))

    def filter_upcoming(self, queryset, name, value):
        """Filter upcoming masterclasses (start date in future)"""
        if value:
            return queryset.filter(start_date__gt=timezone.now())
        return queryset

    def filter_ongoing(self, queryset, name, value):
        """Filter currently ongoing masterclasses"""
        if value:
            now = timezone.now()
            return queryset.filter(start_date__lte=now, end_date__gte=now)
        return queryset

    def filter_past(self, queryset, name, value):
        """Filter past masterclasses (end date in past)"""
        if value:
            return queryset.filter(end_date__lt=timezone.now())
        return queryset

    def filter_free(self, queryset, name, value):
        """Filter free masterclasses"""
        if value:
            return queryset.filter(Q(price=0) | Q(price__isnull=True))
        return queryset.exclude(Q(price=0) | Q(price__isnull=True))

    def filter_has_seats(self, queryset, name, value):
        """Filter masterclasses with available seats"""
        if value:
            return queryset.filter(is_full=False, seats_remaining__gt=0)
        return queryset

    def filter_has_provider_courses(self, queryset, name, value):
        """Filter masterclasses with linked provider courses"""
        if value:
            return queryset.exclude(provider_courses__isnull=True)
        return queryset.filter(provider_courses__isnull=True)

    def filter_min_rating(self, queryset, name, value):
        """Filter by minimum average rating"""
        try:
            from apps.reviews.models import PopularityMetric
            from django.contrib.contenttypes.models import ContentType

            ct = ContentType.objects.get_for_model(Masterclass)
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

            ct = ContentType.objects.get_for_model(Masterclass)
            popular_ids = PopularityMetric.objects.filter(
                content_type=ct,
                favorite_count__gte=value
            ).values_list('object_id', flat=True)

            return queryset.filter(id__in=popular_ids)
        except Exception:
            return queryset

    def filter_min_views(self, queryset, name, value):
        """Filter by minimum view count (30 days)"""
        try:
            from apps.reviews.models import PopularityMetric
            from django.contrib.contenttypes.models import ContentType

            ct = ContentType.objects.get_for_model(Masterclass)
            popular_ids = PopularityMetric.objects.filter(
                content_type=ct,
                view_count_30d__gte=value
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

            ct = ContentType.objects.get_for_model(Masterclass)

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
