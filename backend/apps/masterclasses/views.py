from django.shortcuts import render, get_object_or_404
from django.http import JsonResponse, HttpResponse
import re
import requests
from django.db.models import Q
from .models import Masterclass


def _inline_svg_css(svg_bytes):
    """
    Convert CSS class selectors in SVG <style> blocks to inline style attributes.
    flutter_svg does not support CSS class-based styling, so we must inline them
    before serving. Example: <rect class="cls-1"> with .cls-1{fill:#fff} becomes
    <rect style="fill:#fff">.
    """
    try:
        svg_text = svg_bytes.decode('utf-8', errors='replace')

        # Extract all class→style mappings from <style> blocks
        class_styles = {}
        for style_block in re.findall(r'<style[^>]*>(.*?)</style>', svg_text, re.DOTALL | re.IGNORECASE):
            for cls, props in re.findall(r'\.([\w-]+)\s*\{([^}]+)\}', style_block):
                class_styles[cls.strip()] = props.strip()

        if not class_styles:
            return svg_bytes

        def replace_class_attr(m):
            classes = m.group(1).split()
            styles = [class_styles[c] for c in classes if c in class_styles]
            if not styles:
                return m.group(0)
            return f'style="{"; ".join(styles)}"'

        result = re.sub(r'class="([^"]+)"', replace_class_attr, svg_text)
        return result.encode('utf-8')
    except Exception:
        return svg_bytes

def masterclass_list(request):
    """List all masterclasses with filtering - return JSON for API"""
    # Get query parameters
    stream_type = request.GET.get('stream_type')
    tier = request.GET.get('tier')
    focus_area = request.GET.get('focus_area')
    min_price = request.GET.get('min_price')
    max_price = request.GET.get('max_price')
    page = int(request.GET.get('page', 1))
    page_size = int(request.GET.get('page_size', 20))  # Allow frontend to control page size
    
    # Start with all masterclasses
    masterclasses = Masterclass.objects.all().order_by('start_date')

    # Apply filters if provided
    if stream_type:
        masterclasses = masterclasses.filter(stream_type=stream_type)

    if tier:
        masterclasses = masterclasses.filter(tier=tier)

    if focus_area:
        masterclasses = masterclasses.filter(focus_area__icontains=focus_area)

    if min_price:
        try:
            # Filter by price_online (main price field)
            masterclasses = masterclasses.filter(price_online__gte=float(min_price))
        except ValueError:
            pass

    if max_price:
        try:
            # Filter by price_online (main price field)
            masterclasses = masterclasses.filter(price_online__lte=float(max_price))
        except ValueError:
            pass

    # Pagination with configurable page size (max 500 to prevent abuse)
    per_page = min(page_size, 500)
    start_idx = (page - 1) * per_page
    end_idx = start_idx + per_page
    paginated_masterclasses = masterclasses[start_idx:end_idx]
    
    # Return JSON response for API
    results = []
    for mc in paginated_masterclasses:
        # Get feature image from linked AICERTS courses
        feature_image_url = None
        first_course = mc.provider_courses.first()
        if first_course:
            feature_image_url = first_course.feature_image_url

        results.append({
            'id': mc.id,
            'title': mc.title,
            'slug': mc.slug,
            'description': mc.description,
            'status': mc.status,
            'stream_type': mc.stream_type,
            'tier': mc.tier,
            'focus_area': mc.focus_area,
            'start_date': mc.start_date.isoformat() if mc.start_date else None,
            'end_date': mc.end_date.isoformat() if mc.end_date else None,
            'city': mc.city,
            'country': mc.country_name,
            'country_name': mc.country_name,
            'venue': mc.venue,
            'price': float(mc.price_online) if mc.price_online else None,
            'price_usd': float(mc.price_online) if mc.price_online else None,
            'price_physical': float(mc.price_physical) if mc.price_physical else None,
            'currency': mc.currency,
            'is_featured': mc.is_featured,
            'seats_remaining': mc.seats_remaining if hasattr(mc, 'seats_remaining') else None,
            'is_full': mc.is_full if hasattr(mc, 'is_full') else None,
            'feature_image_url': feature_image_url,  # Added: Image from linked AICERTS course
        })

    data = {
        'count': masterclasses.count(),
        'page': page,
        'per_page': per_page,
        'results': results
    }
    return JsonResponse(data)

def masterclass_detail(request, slug):
    """Masterclass detail view"""
    masterclass = get_object_or_404(Masterclass, slug=slug)
    
    data = {
        'id': masterclass.id,
        'title': masterclass.title,
        'slug': masterclass.slug,
        'description': masterclass.description,
        'status': masterclass.status,
        'stream_type': masterclass.stream_type,  # Added this field
        'tier': masterclass.tier,  # Added this field
        'focus_area': masterclass.focus_area,  # Added this field
        'start_date': masterclass.start_date.isoformat() if masterclass.start_date else None,
        'end_date': masterclass.end_date.isoformat() if masterclass.end_date else None,
        'city': masterclass.city,
        'country': masterclass.country_name,  # Added 'country' alias
        'country_name': masterclass.country_name,
        'country_code': masterclass.country_code,
        'venue': masterclass.venue,
        'price': float(masterclass.price) if masterclass.price else None,  # Convert to float
        'price_usd': float(masterclass.price) if masterclass.price else None,  # Added price_usd alias
        'currency': masterclass.currency,
        'is_featured': masterclass.is_featured,
        'max_participants': masterclass.max_participants,
        'current_participants': masterclass.current_participants,
        'seats_remaining': masterclass.seats_remaining,
        'is_full': masterclass.is_full,
        'duration_days': masterclass.duration_days,
        'location_display': masterclass.location_display,
        'formatted_price': masterclass.formatted_price,
        'notes': masterclass.notes,
        'created_at': masterclass.created_at.isoformat() if masterclass.created_at else None,
        'updated_at': masterclass.updated_at.isoformat() if masterclass.updated_at else None,
    }
    return JsonResponse(data)

def proxy_aicerts_image(request):
    """
    Proxy image requests to bypass CORS for aicerts.ai.
    Adds necessary CORS headers for Flutter Web.
    """
    url = request.GET.get('url')
    if not url:
        return HttpResponse("Missing URL", status=400)
    
    # Security check: only allow aicerts.ai
    allowed_domains = ["www.aicerts.ai", "cdn.aicerts.ai", "aicerts.ai"]
    parsed_url = re.match(r'https?://([^/]+)/', url)
    if not parsed_url or parsed_url.group(1) not in allowed_domains:
        return HttpResponse("Invalid domain", status=403)
        
    try:
        fetch_headers = {'User-Agent': 'Mozilla/5.0'}
        resp = requests.get(url, stream=True, headers=fetch_headers, timeout=10)
        resp.raise_for_status()
        
        # Determine content type: prefer SVG for .svg URLs or explicit format=svg
        content_type = resp.headers.get('Content-Type', 'application/octet-stream')
        if url.lower().endswith('.svg') or request.GET.get('format') == 'svg':
            content_type = 'image/svg+xml'
            
        content = resp.content
        # Inline CSS class styles so flutter_svg can render them
        if content_type == 'image/svg+xml':
            content = _inline_svg_css(content)

        response = HttpResponse(content, content_type=content_type)

        # Essential for Flutter Web
        response['Access-Control-Allow-Origin'] = '*'
        response['Access-Control-Allow-Methods'] = 'GET, OPTIONS'

        # Cache for performance
        response['Cache-Control'] = 'public, max-age=86400'

        return response
    except Exception as e:
        return HttpResponse(f"Error fetching image: {str(e)}", status=500)