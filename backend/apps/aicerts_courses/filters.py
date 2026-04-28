# apps/aicerts_courses/filters.py
import django_filters
from django.db.models import Q
from .models import AiCertsCourse


class AiCertsCourseFilter(django_filters.FilterSet):
    """
    Enhanced filters for AICerts courses with price range and popularity filtering.
    """

    # Text search (already exists but keeping for completeness)
    search = django_filters.CharFilter(method='filter_search', label='Search')

    # Basic filters
    provider = django_filters.CharFilter(lookup_expr='iexact')
    is_offered = django_filters.BooleanFilter()
    on_offer = django_filters.BooleanFilter(field_name='is_offered')
    featured = django_filters.BooleanFilter(method='filter_popular')
    is_self_paced = django_filters.BooleanFilter()
    is_in_package = django_filters.BooleanFilter()

    # Category filters
    category = django_filters.CharFilter(
        field_name='category_name',
        lookup_expr='icontains',
        label='Category'
    )
    category_exact = django_filters.CharFilter(
        field_name='category_name',
        lookup_expr='iexact',
        label='Category (Exact)'
    )

    # Price filters - Individual pricing
    price_min = django_filters.NumberFilter(
        field_name='price_individual',
        lookup_expr='gte',
        label='Minimum Price (Individual)'
    )
    price_max = django_filters.NumberFilter(
        field_name='price_individual',
        lookup_expr='lte',
        label='Maximum Price (Individual)'
    )
    price_range = django_filters.RangeFilter(
        field_name='price_individual',
        label='Price Range (Individual)'
    )

    # Price filters - Package pricing
    package_price_min = django_filters.NumberFilter(
        field_name='price_package',
        lookup_expr='gte',
        label='Minimum Price (Package)'
    )
    package_price_max = django_filters.NumberFilter(
        field_name='price_package',
        lookup_expr='lte',
        label='Maximum Price (Package)'
    )
    package_price_range = django_filters.RangeFilter(
        field_name='price_package',
        label='Price Range (Package)'
    )

    # Free courses
    is_free = django_filters.BooleanFilter(method='filter_free', label='Free Courses')

    # Package filtering
    package = django_filters.CharFilter(
        field_name='package_name',
        lookup_expr='icontains',
        label='Package Name'
    )
    has_package = django_filters.BooleanFilter(
        field_name='is_in_package',
        label='Has Package Option'
    )

    # Popularity filters
    min_rating = django_filters.NumberFilter(method='filter_min_rating', label='Minimum Rating')
    min_favorites = django_filters.NumberFilter(method='filter_min_favorites', label='Minimum Favorites')
    min_views = django_filters.NumberFilter(method='filter_min_views', label='Minimum Views (30 days)')
    popular = django_filters.BooleanFilter(method='filter_popular', label='Popular Only')

    # Date filters
    synced_after = django_filters.DateTimeFilter(
        field_name='last_synced',
        lookup_expr='gte',
        label='Synced After'
    )
    synced_before = django_filters.DateTimeFilter(
        field_name='last_synced',
        lookup_expr='lte',
        label='Synced Before'
    )

    # Ordering
    ordering = django_filters.OrderingFilter(
        fields=(
            ('title', 'name'),
            ('price_individual', 'price'),
            ('price_package', 'package_price'),
            ('last_synced', 'last_synced'),
            ('category_name', 'category'),
        ),
        field_labels={
            'title': 'Course Name',
            'price_individual': 'Individual Price',
            'price_package': 'Package Price',
            'last_synced': 'Last Synced',
            'category_name': 'Category',
        }
    )

    class Meta:
        model = AiCertsCourse
        fields = ['provider', 'is_offered', 'is_self_paced', 'is_in_package']

    def filter_search(self, queryset, name, value):
        """Full-text search across multiple fields"""
        return queryset.filter(
            Q(title__icontains=value) |
            Q(shortname__icontains=value) |
            Q(summary__icontains=value) |
            Q(category_name__icontains=value) |
            Q(package_name__icontains=value)
        )

    def filter_free(self, queryset, name, value):
        """Filter free courses (price = 0 or null)"""
        if value:
            return queryset.filter(
                Q(price_individual=0) | Q(price_individual__isnull=True)
            )
        return queryset.exclude(
            Q(price_individual=0) | Q(price_individual__isnull=True)
        )

    def filter_min_rating(self, queryset, name, value):
        """Filter by minimum average rating"""
        try:
            from apps.reviews.models import PopularityMetric
            from django.contrib.contenttypes.models import ContentType

            ct = ContentType.objects.get_for_model(AiCertsCourse)
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

            ct = ContentType.objects.get_for_model(AiCertsCourse)
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

            ct = ContentType.objects.get_for_model(AiCertsCourse)
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

            ct = ContentType.objects.get_for_model(AiCertsCourse)

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
