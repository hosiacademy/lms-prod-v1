# apps/localization/admin.py

from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe
from django.utils.translation import gettext_lazy as _

from .models import Language, Translation, Country, CountryOverride, LocalizedPromotion
from apps.frontend_manage.models import AppAppearance  # For theme override preview


@admin.register(Language)
class LanguageAdmin(admin.ModelAdmin):
    """
    Truly Afrocentric Language Admin — Country-Level Accuracy.
    Reflects the reality: African languages are spoken across multiple nations.
    Prioritizes official, national, and widely used languages in education and AI training.
    """
    list_display = (
        'name', 'native', 'code',
        'official_countries',
        'speakers_millions',
        'status_display', 'json_exist_display'
    )
    list_filter = ('status', 'rtl', 'json_exist')
    search_fields = ('name', 'native', 'code')
    ordering = ('name',)
    readonly_fields = ('countries_preview',)

    fieldsets = (
        ("Language Identity", {
            'fields': ('name', 'native', 'code'),
        }),
        ("African Context (Country-Level)", {
            'fields': ('countries_preview',),
            'description': mark_safe(
                "<strong>Pan-African Reality:</strong> One language → Many countries. "
                "Swahili is official in Tanzania, Kenya, Uganda, DRC, and lingua franca across East Africa. "
                "Hausa spans Nigeria, Niger, Ghana. Arabic across North Africa. "
                "This LMS celebrates cross-border African knowledge and unity. 🌍"
            )
        }),
        ("Technical", {
            'fields': ('rtl', 'status', 'json_exist')
        }),
        ("Timestamps", {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    def official_countries(self, obj):
        """
        Returns full names of African countries where this language has official or national status.
        No vague fallbacks — only real countries.
        """
        official_map = {
            'sw': 'Tanzania, Kenya, Uganda, Democratic Republic of the Congo, Rwanda',
            'ha': 'Niger, Nigeria',
            'yo': 'Benin, Nigeria',
            'ig': 'Nigeria',
            'am': 'Ethiopia',
            'om': 'Ethiopia',
            'ti': 'Eritrea, Ethiopia',
            'zu': 'South Africa',
            'xh': 'South Africa',
            'af': 'South Africa, Namibia',
            'ar': 'Algeria, Egypt, Libya, Mauritania, Morocco, Sudan, Tunisia',
            'fr': 'Benin, Burkina Faso, Cameroon, Central African Republic, Chad, Comoros, Democratic Republic of the Congo, Republic of the Congo, Cote d\'Ivoire, Djibouti, Gabon, Guinea, Madagascar, Mali, Mauritania, Niger, Senegal, Togo',
            'pt': 'Angola, Cape Verde, Guinea-Bissau, Mozambique, Sao Tome and Principe',
            'rw': 'Rwanda',
            'ln': 'Democratic Republic of the Congo, Republic of the Congo',
            'ak': 'Ghana',
            'sn': 'Zimbabwe',
            'so': 'Somalia, Djibouti',
            'en': 'Botswana, Gambia, Ghana, Kenya, Lesotho, Liberia, Malawi, Mauritius, Namibia, Nigeria, Rwanda, Seychelles, Sierra Leone, South Africa, South Sudan, Eswatini, Tanzania, Uganda, Zambia, Zimbabwe',
        }
        countries = official_map.get(obj.code.lower()[:2], None)
        return countries if countries else "No official status listed in African countries"
    official_countries.short_description = "Official In"

    def speakers_millions(self, obj):
        speakers_map = {
            'sw': '150–200M (L1+L2)', 'ha': '80–100M', 'yo': '45–50M',
            'ig': '30–40M', 'am': '35M+', 'om': '35M+', 'ar': '300M+ (Africa: 200M+)',
            'fr': '140M+ in Africa', 'en': '400M+ in Africa (L2)', 'pt': '40M+ in Africa',
            'ln': '70M+ (L2)', 'zu': '12M', 'rw': '12M',
            'sn': '15M+', 'so': '20M+', 'ak': '11M+', 'mg': '25M+',
            'ny': '8M+', 'bm': '14M+', 'ff': '40M+', 'wo': '12M+',
            'kr': '1M+', 'men': '2M+', 'din': '3M+', 'nus': '1M+',
            'kmb': '3M+', 'umb': '4M+', 'fon': '2M+', 'sg': '2M+',
            'tn': '6M+', 'ss': '1M+', 'st': '5M+', 've': '1M+',
            'ts': '2M+', 'nr': '1M+', 'af': '7M+',
            'ti': '7M+',
        }
        return speakers_map.get(obj.code.lower()[:2], "—")
    speakers_millions.short_description = "Speakers (Africa)"

    def countries_preview(self, obj):
        countries = self.official_countries(obj)
        speakers = self.speakers_millions(obj)

        return mark_safe(f"""
            <div style="background: #f8f9fa; padding: 15px; border-radius: 8px; border-left: 5px solid #27ae60;">
                <p><strong>Official African Countries:</strong> {countries}</p>
                <p><strong>Speakers in Africa:</strong> {speakers}</p>
            </div>
        """)
    countries_preview.short_description = "African Presence"

    def status_display(self, obj):
        color = "#27ae60" if obj.status else "#95a5a6"
        status = "Active" if obj.status else "Disabled"
        return format_html('<strong style="color: {};">{}</strong>', color, status)
    status_display.short_description = "Status"

    def json_exist_display(self, obj):
        color = "#27ae60" if obj.json_exist else "#e67e22"
        text = "Complete" if obj.json_exist else "Missing"
        return format_html('<strong style="color: {};">{}</strong>', color, text)
    json_exist_display.short_description = "Translations"

    class Media:
        css = {
            'all': ('admin/css/afrocentric_localization.css',)
        }


@admin.register(Translation)
class TranslationAdmin(admin.ModelAdmin):
    list_display = ('key', 'language', 'value_preview', 'description_short')
    list_filter = ('language',)
    search_fields = ('key', 'value', 'description')

    fieldsets = (
        ("Translation Details", {
            'fields': ('key', 'language', 'value', 'description'),
        }),
    )

    def value_preview(self, obj):
        return obj.value[:80] + ('...' if len(obj.value) > 80 else "")
    value_preview.short_description = "Value"

    def description_short(self, obj):
        return obj.description[:80] + ('...' if len(obj.description) > 80 else "") if obj.description else "—"
    description_short.short_description = "Description"


@admin.register(Country)
class CountryAdmin(admin.ModelAdmin):
    list_display = ('code', 'name', 'is_active')
    search_fields = ('code', 'name')
    list_filter = ('is_active',)


@admin.register(CountryOverride)
class CountryOverrideAdmin(admin.ModelAdmin):
    """
    Manage country-specific customizations for a truly "country sensitive" LMS.
    Examples: ZA → Sawubona! greeting, Youth Day banner (June 16), green/gold/red theme tweak.
    """
    list_display = (
        'country', 'is_default_display', 'greeting_preview',
        'holiday_date', 'default_language', 'theme_preview', 'updated_at'
    )
    list_filter = ('is_default', 'country')
    search_fields = ('country__name', 'greeting_message', 'cultural_note')
    readonly_fields = ('created_at', 'updated_at', 'full_preview')

    fieldsets = (
        ("Country Scope", {
            'fields': ('country', 'is_default', 'default_language'),
            'description': mark_safe(
                "<strong>Tip:</strong> Set one country as default for fallback when no user country is detected."
            )
        }),
        ("Cultural & Greeting Elements", {
            'fields': ('greeting_message', 'cultural_note'),
        }),
        ("Holidays & Visuals", {
            'fields': ('holiday_date', 'holiday_banner_url'),
        }),
        ("Theme Override (Colors & Mode)", {
            'fields': ('appearance',),
            'classes': ('collapse',),
        }),
        ("Preview", {
            'fields': ('full_preview',),
            'classes': ('collapse',),
        }),
        ("Timestamps", {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    def is_default_display(self, obj):
        return obj.is_default

    is_default_display.boolean = True
    is_default_display.short_description = "Default"

    def greeting_preview(self, obj):
        return obj.greeting_message[:60] + ('...' if len(obj.greeting_message) > 60 else "") if obj.greeting_message else "—"
    greeting_preview.short_description = "Greeting"

    def theme_preview(self, obj):
        if not obj.appearance:
            return "—"
        return format_html(
            '<div style="display: inline-block; vertical-align: middle;">'
            '<div style="width: 24px; height: 24px; background-color: {}; border: 1px solid #ccc; border-radius: 4px;"></div> '
            '<div style="width: 24px; height: 24px; background-color: {}; border: 1px solid #ccc; border-radius: 4px;"></div> '
            '<div style="width: 24px; height: 24px; background-color: {}; border: 1px solid #ccc; border-radius: 4px;"></div>'
            '</div>',
            obj.appearance.primary_color or '#000',
            obj.appearance.secondary_color or '#000',
            obj.appearance.background_color or '#fff'
        )
    theme_preview.short_description = "Theme"

    def full_preview(self, obj):
        html = '<div style="background: #f8f9fa; padding: 20px; border-radius: 8px; border-left: 5px solid #27ae60;">'
        
        if obj.greeting_message:
            html += f'<p><strong>Greeting:</strong> {obj.greeting_message}</p>'
        
        if obj.cultural_note:
            html += f'<p><strong>Cultural Note:</strong> {obj.cultural_note}</p>'
        
        if obj.holiday_date and obj.holiday_banner_url:
            html += f'<p><strong>Holiday:</strong> {obj.holiday_date} — <a href="{obj.holiday_banner_url}" target="_blank">Banner</a></p>'
        
        if obj.appearance:
            html += f'<p><strong>Theme Override:</strong> Primary {obj.appearance.primary_color}</p>'
        
        html += '</div>'
        return mark_safe(html)
    full_preview.short_description = "Full Country Preview"

    actions = ['make_default_override']

    def make_default_override(self, request, queryset):
        count = queryset.update(is_default=True)
        CountryOverride.objects.filter(is_default=True).exclude(id__in=queryset.values_list('id')).update(is_default=False)
        self.message_user(request, f'{count} country override(s) set as default.')
    make_default_override.short_description = "Set selected as default override"


@admin.register(LocalizedPromotion)
class LocalizedPromotionAdmin(admin.ModelAdmin):
    """
    DEPRECATED — Use Payments › Coupon Codes instead.

    Promotions and coupons are now unified. Every promotion is a CouponCode with
    display fields (background_color, icon, cta_text, countries M2M, etc.).
    The /api/v1/localization/promotions/ endpoint now proxies to CouponCode.

    This model and admin are retained for historical records only.
    New promotions should be created via Payments › Coupon Codes.
    """
    list_display = (
        'title', 'promotion_type', 'discount_badge', 'countries_list',
        'date_range', 'priority', 'is_active', 'is_live_now',
    )
    list_filter = ('is_active', 'promotion_type', 'show_on_onboarding', 'show_on_home')
    search_fields = ('title', 'description')
    filter_horizontal = ('countries',)
    readonly_fields = ('created_at', 'updated_at', 'preview_card')

    fieldsets = (
        ("Promotion Content", {
            'fields': ('title', 'native_title', 'description', 'native_description',
                       'promotion_type', 'icon'),
        }),
        ("Discount", {
            'fields': ('discount_percentage',),
            'description': mark_safe(
                "<strong>Tip:</strong> Set a discount percentage to enable promo pricing in the enrollment modal. "
                "Leave blank for non-discount promotions (free course, bundle, etc.)."
            ),
        }),
        ("Visuals", {
            'fields': ('image', 'image_url', 'background_color', 'text_color'),
        }),
        ("Call to Action", {
            'fields': ('cta_text', 'cta_url'),
        }),
        ("Schedule & Targeting", {
            'fields': ('start_date', 'end_date', 'priority', 'countries'),
        }),
        ("Placement Flags", {
            'fields': ('show_on_splash', 'show_on_home', 'show_on_onboarding', 'is_active'),
        }),
        ("Preview", {
            'fields': ('preview_card',),
            'classes': ('collapse',),
        }),
        ("Metadata", {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    def discount_badge(self, obj):
        if obj.discount_percentage:
            return format_html(
                '<span style="background:#FF5722;color:#fff;padding:2px 8px;border-radius:12px;font-weight:bold;">'
                '{}% OFF</span>', int(obj.discount_percentage)
            )
        return "—"
    discount_badge.short_description = "Discount"

    def countries_list(self, obj):
        codes = list(obj.countries.values_list('code', flat=True)[:5])
        if not codes:
            return "All countries"
        return ", ".join(codes)
    countries_list.short_description = "Countries"

    def date_range(self, obj):
        return f"{obj.start_date} → {obj.end_date}"
    date_range.short_description = "Active Period"

    def is_live_now(self, obj):
        return obj.is_currently_active
    is_live_now.boolean = True
    is_live_now.short_description = "Live Now"

    def preview_card(self, obj):
        bg = obj.background_color or '#FF5722'
        fg = obj.text_color or '#FFFFFF'
        icon = obj.icon or '🎉'
        discount = f"{int(obj.discount_percentage)}% OFF — " if obj.discount_percentage else ""
        return mark_safe(f"""
            <div style="background:{bg};color:{fg};padding:20px;border-radius:16px;max-width:360px;font-family:sans-serif;">
                <div style="font-size:32px;text-align:center;">{icon}</div>
                <h3 style="margin:8px 0;text-align:center;">{discount}{obj.title}</h3>
                <p style="font-size:14px;text-align:center;opacity:0.9;">{obj.description[:100]}...</p>
                <div style="text-align:center;margin-top:16px;">
                    <span style="background:rgba(255,255,255,0.25);padding:8px 20px;border-radius:20px;font-weight:bold;">
                        {obj.cta_text}
                    </span>
                </div>
            </div>
        """)
    preview_card.short_description = "Promo Card Preview"

    def save_model(self, request, obj, form, change):
        if not obj.pk:
            obj.created_by = request.user
        super().save_model(request, obj, form, change)