# setup-admin.ps1
# Run this script from: C:\Users\HosiTech\lms-monorepo\backend\

Write-Host "Setting up Enhanced Django Admin Interface..." -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan

# Create necessary directories
$directories = @(
    "core\templatetags",
    "templates\admin"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        Write-Host "Created directory: $dir" -ForegroundColor Yellow
    } else {
        Write-Host "Directory exists: $dir" -ForegroundColor Gray
    }
}

# Create __init__.py files
$initFiles = @(
    "core\__init__.py",
    "core\templatetags\__init__.py"
)

foreach ($file in $initFiles) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file | Out-Null
        Write-Host "Created file: $file" -ForegroundColor Yellow
    }
}

# 1. Create core/admin.py with custom AdminSite
$adminPyContent = @"
from django.contrib import admin
from django.contrib.admin import AdminSite
from django.utils.translation import gettext_lazy as _

class HosiAdminSite(AdminSite):
    """Custom admin site for Hosi Technologies"""
    
    site_title = _("Admin Portal")
    site_header = _("Admin Portal")
    index_title = _("Dashboard")
    
    def each_context(self, request):
        context = super().each_context(request)
        # Add custom context variables
        context.update({
            'custom_admin': True,
            'version': '1.0.0',
        })
        return context

# Create singleton instance
hosi_admin_site = HosiAdminSite(name='hosi_admin')

# Register your models here (example)
# from django.contrib.auth.models import User, Group
# hosi_admin_site.register(User)
# hosi_admin_site.register(Group)
"@

Set-Content -Path "core\admin.py" -Value $adminPyContent
Write-Host "Created core/admin.py" -ForegroundColor Green

# 2. Create core/templatetags/admin_custom.py
$adminCustomContent = @"
# core/templatetags/admin_custom.py
from django import template
from django.contrib.admin import AdminSite
from django.apps import apps

register = template.Library()

@register.simple_tag(takes_context=True)
def get_app_list(context):
    """Custom app list for sidebar"""
    request = context.get('request')
    if not request:
        return []
    
    # Get available admin sites
    admin_sites = []
    try:
        # Try to get from context
        admin_site = context.get('admin_site') or admin.site
        app_list = admin_site.get_app_list(request)
        return app_list
    except:
        # Fallback: create simple app list
        app_dict = {}
        for model, model_admin in admin.site._registry.items():
            app_label = model._meta.app_label
            if app_label not in app_dict:
                try:
                    app_name = apps.get_app_config(app_label).verbose_name
                except:
                    app_name = app_label.replace('_', ' ').title()
                
                app_dict[app_label] = {
                    'name': app_name,
                    'app_label': app_label,
                    'app_url': f"/admin/{app_label}/",
                    'has_module_perms': True,
                    'models': []
                }
            
            model_dict = {
                'name': model._meta.verbose_name_plural,
                'object_name': model._meta.object_name,
                'admin_url': model_admin.get_changelist_url() or f"/admin/{app_label}/{model._meta.model_name}/",
                'add_url': model_admin.get_add_url() or f"/admin/{app_label}/{model._meta.model_name}/add/",
                'view_only': False,
            }
            app_dict[app_label]['models'].append(model_dict)
        
        # Convert to list and sort
        return sorted(app_dict.values(), key=lambda x: x['name'])
"@

Set-Content -Path "core\templatetags\admin_custom.py" -Value $adminCustomContent
Write-Host "Created core/templatetags/admin_custom.py" -ForegroundColor Green

# 3. Create templates/admin/app_list.html
$appListContent = @"
{% load admin_custom %}
{% load i18n %}

<div id="nav-sidebar" class="sidebar">
    <div class="sidebar-header">
        <h3>{% trans 'Applications' %}</h3>
    </div>
    
    <div class="sidebar-content">
        {% get_app_list as app_list %}
        {% for app in app_list %}
        <div class="app-section" data-app="{{ app.app_label }}">
            <div class="app-name" data-app="{{ app.app_label }}">
                <span class="app-icon">📁</span>
                <span class="app-title">{{ app.name }}</span>
                <span class="app-arrow">›</span>
            </div>
            <div class="app-model-list">
                {% for model in app.models %}
                <a href="{{ model.admin_url }}" class="app-model-item" data-model="{{ model.object_name|lower }}">
                    <span class="model-icon">📄</span>
                    <span class="model-name">{{ model.name }}</span>
                </a>
                {% endfor %}
            </div>
        </div>
        {% endfor %}
    </div>
</div>
"@

Set-Content -Path "templates\admin\app_list.html" -Value $appListContent
Write-Host "Created templates/admin/app_list.html" -ForegroundColor Green

# 4. Create enhanced base_site.html
$baseSiteContent = @"
{% extends "admin/base.html" %}
{% load static %}

{% block title %}{{ title }} | Admin Portal{% endblock %}

{% block extrahead %}
<script>
document.addEventListener('DOMContentLoaded', function() {
    // Initialize sidebar interactions
    function initSidebar() {
        const appSections = document.querySelectorAll('.app-section');
        
        appSections.forEach(app => {
            const modelList = app.querySelector('.app-model-list');
            if (modelList) {
                modelList.style.display = 'none';
            }
            
            let hoverTimer;
            const appName = app.querySelector('.app-name');
            
            appName.addEventListener('mouseenter', function() {
                clearTimeout(hoverTimer);
                
                // Close other app sections
                appSections.forEach(otherApp => {
                    if (otherApp !== app) {
                        const otherList = otherApp.querySelector('.app-model-list');
                        if (otherList) {
                            otherList.style.display = 'none';
                            otherApp.classList.remove('expanded');
                        }
                    }
                });
                
                hoverTimer = setTimeout(() => {
                    const modelList = app.querySelector('.app-model-list');
                    if (modelList) {
                        modelList.style.display = 'block';
                        app.classList.add('expanded');
                        
                        // Position the model list
                        const rect = appName.getBoundingClientRect();
                        const sidebar = document.getElementById('nav-sidebar');
                        if (sidebar) {
                            const sidebarRect = sidebar.getBoundingClientRect();
                            modelList.style.left = (sidebarRect.width) + 'px';
                            modelList.style.top = (rect.top - sidebarRect.top) + 'px';
                        }
                    }
                }, 150);
            });
            
            app.addEventListener('mouseleave', function(e) {
                clearTimeout(hoverTimer);
                const modelList = app.querySelector('.app-model-list');
                
                if (modelList && !modelList.matches(':hover') && !appName.matches(':hover')) {
                    hoverTimer = setTimeout(() => {
                        modelList.style.display = 'none';
                        app.classList.remove('expanded');
                    }, 300);
                }
            });
            
            // Keep model list open when hovering over it
            const modelList = app.querySelector('.app-model-list');
            if (modelList) {
                modelList.addEventListener('mouseenter', function() {
                    clearTimeout(hoverTimer);
                    app.classList.add('expanded');
                });
                
                modelList.addEventListener('mouseleave', function() {
                    hoverTimer = setTimeout(() => {
                        this.style.display = 'none';
                        app.classList.remove('expanded');
                    }, 300);
                });
            }
        });
    }
    
    // Transform selected app into header
    function transformSelectedApp() {
        const breadcrumbs = document.querySelector('.breadcrumbs');
        if (!breadcrumbs) return;
        
        const links = Array.from(breadcrumbs.querySelectorAll('a'));
        if (links.length >= 2) {
            const appLink = links[links.length - 2];
            const appName = appLink.textContent.trim();
            const appUrl = appLink.href;
            
            // Remove existing transformed header if any
            const existingHeader = document.querySelector('.transformed-app-header');
            if (existingHeader) {
                existingHeader.remove();
            }
            
            // Create new transformed header
            const appHeader = document.createElement('div');
            appHeader.className = 'transformed-app-header';
            appHeader.innerHTML = \`
                <div class="transformed-app-main">
                    <div class="transformed-app-icon">
                        <span class="icon">📁</span>
                    </div>
                    <div class="transformed-app-info">
                        <h2 class="transformed-app-title">\${appName}</h2>
                        <div class="transformed-app-models">
                            <!-- Models will be populated -->
                        </div>
                    </div>
                </div>
            \`;
            
            // Insert after header
            const header = document.getElementById('header');
            if (header && header.parentNode) {
                header.parentNode.insertBefore(appHeader, header.nextSibling);
            }
            
            // Populate models
            populateTransformedModels(appName, appHeader);
            
            // Hide breadcrumbs
            breadcrumbs.style.display = 'none';
            
            // Highlight sidebar app
            highlightSidebarApp(appName);
        }
    }
    
    function populateTransformedModels(appName, appHeader) {
        const modelsContainer = appHeader.querySelector('.transformed-app-models');
        if (!modelsContainer) return;
        
        // Find app in sidebar
        const appSections = document.querySelectorAll('.app-section');
        appSections.forEach(appSection => {
            const appTitle = appSection.querySelector('.app-title');
            if (appTitle && appTitle.textContent.trim() === appName) {
                const modelLinks = appSection.querySelectorAll('.app-model-item');
                modelLinks.forEach(link => {
                    const modelItem = document.createElement('a');
                    modelItem.href = link.href;
                    modelItem.className = 'transformed-model-item';
                    
                    // Check if this is the active model
                    const currentPath = window.location.pathname;
                    if (currentPath.includes(link.href.split('/admin/')[1] || '')) {
                        modelItem.classList.add('active');
                    }
                    
                    modelItem.innerHTML = \`
                        <span class="model-icon">📄</span>
                        <span class="model-title">\${link.querySelector('.model-name').textContent}</span>
                    \`;
                    
                    modelsContainer.appendChild(modelItem);
                });
            }
        });
    }
    
    function highlightSidebarApp(appName) {
        document.querySelectorAll('.app-section').forEach(section => {
            section.classList.remove('selected');
            const title = section.querySelector('.app-title');
            if (title && title.textContent.trim() === appName) {
                section.classList.add('selected');
            }
        });
    }
    
    // Initialize everything
    setTimeout(() => {
        initSidebar();
        transformSelectedApp();
    }, 100);
});
</script>
<style>
    /* ===== CUSTOM PROPERTIES ===== */
    :root {
        --wp-primary: #0693E3;
        --wp-background: #121212;
        --wp-surface: #1E1E1E;
        --wp-text-primary: #FFFFFF;
        --wp-text-secondary: #CCCCCC;
        --spacing-xs: 4px;
        --spacing-sm: 8px;
        --spacing-md: 16px;
        --spacing-lg: 24px;
        --spacing-xl: 32px;
        --header-height: 60px;
    }

    /* ===== BASE RESETS ===== */
    * {
        box-sizing: border-box;
        margin: 0;
        padding: 0;
    }

    body {
        background: var(--wp-background);
        color: var(--wp-text-primary);
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
        line-height: 1.5;
        min-height: 100vh;
    }

    /* ===== FIXED HEADER ===== */
    #header {
        background: var(--wp-surface) !important;
        border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        height: var(--header-height);
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        z-index: 1000;
        padding: 0 !important;
    }

    body {
        padding-top: var(--header-height) !important;
    }

    /* ===== COMPACT BRANDING ===== */
    #branding-container {
        display: flex;
        align-items: center;
        justify-content: space-between;
        height: 100%;
        padding: 0 var(--spacing-md);
        max-width: 100%;
        margin: 0 auto;
    }

    .branding-main {
        display: flex;
        align-items: center;
        gap: var(--spacing-md);
    }

    #site-name {
        margin: 0;
    }

    #site-name a {
        display: flex;
        align-items: center;
        gap: var(--spacing-sm);
        text-decoration: none;
        color: var(--wp-text-primary);
    }

    .logo-container {
        width: 32px;
        height: 32px;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .site-logo {
        max-width: 100%;
        max-height: 100%;
        object-fit: contain;
    }

    .logo-fallback {
        font-size: 24px;
        background: var(--wp-primary);
        padding: 4px;
        border-radius: 6px;
    }

    .logo-subtitle {
        font-size: 14px;
        font-weight: 500;
        color: var(--wp-text-secondary);
        letter-spacing: 0.5px;
    }

    /* ===== USER PROFILE ===== */
    .header-user {
        display: flex;
        align-items: center;
    }

    .user-profile-minimal {
        display: flex;
        align-items: center;
        gap: var(--spacing-sm);
    }

    .user-avatar-minimal {
        width: 32px;
        height: 32px;
        background: var(--wp-primary);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 14px;
        color: white;
    }

    .user-name {
        font-size: 14px;
        color: var(--wp-text-secondary);
    }

    /* ===== TRANSFORMED APP HEADER ===== */
    .transformed-app-header {
        background: rgba(30, 30, 30, 0.95);
        backdrop-filter: blur(10px);
        border-bottom: 1px solid rgba(6, 147, 227, 0.3);
        padding: var(--spacing-md) var(--spacing-xl);
        position: fixed;
        top: var(--header-height);
        left: 0;
        right: 0;
        z-index: 999;
        animation: slideDown 0.3s ease-out;
    }

    @keyframes slideDown {
        from {
            opacity: 0;
            transform: translateY(-20px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }

    .transformed-app-main {
        display: flex;
        align-items: center;
        gap: var(--spacing-lg);
        max-width: 1400px;
        margin: 0 auto;
    }

    .transformed-app-icon {
        width: 48px;
        height: 48px;
        background: linear-gradient(135deg, var(--wp-primary) 0%, #1a5f9e 100%);
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 24px;
    }

    .transformed-app-info {
        flex: 1;
    }

    .transformed-app-title {
        font-size: 20px;
        font-weight: 600;
        color: var(--wp-text-primary);
        margin: 0 0 var(--spacing-sm) 0;
    }

    .transformed-app-models {
        display: flex;
        gap: var(--spacing-sm);
        flex-wrap: wrap;
    }

    .transformed-model-item {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 8px 16px;
        background: rgba(255, 255, 255, 0.05);
        border: 1px solid rgba(255, 255, 255, 0.1);
        border-radius: 8px;
        color: var(--wp-text-secondary);
        text-decoration: none;
        font-size: 14px;
        font-weight: 500;
        transition: all 0.2s ease;
    }

    .transformed-model-item:hover {
        background: rgba(6, 147, 227, 0.1);
        border-color: var(--wp-primary);
        color: var(--wp-text-primary);
        transform: translateY(-1px);
    }

    .transformed-model-item.active {
        background: var(--wp-primary);
        color: white;
        border-color: var(--wp-primary);
    }

    /* ===== ENHANCED SIDEBAR ===== */
    #nav-sidebar {
        background: var(--wp-surface);
        border: none;
        border-right: 1px solid rgba(255, 255, 255, 0.1);
        margin-top: 0;
        padding: var(--spacing-lg) 0;
        position: fixed;
        left: 0;
        top: var(--header-height);
        bottom: 0;
        width: 250px;
        z-index: 998;
        overflow-y: auto;
    }

    .sidebar-header {
        padding: var(--spacing-md) var(--spacing-lg);
        border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        margin-bottom: var(--spacing-md);
    }

    .sidebar-header h3 {
        font-size: 14px;
        font-weight: 600;
        color: var(--wp-text-secondary);
        text-transform: uppercase;
        letter-spacing: 1px;
        margin: 0;
    }

    .app-section {
        position: relative;
        margin-bottom: var(--spacing-xs);
    }

    .app-name {
        display: flex;
        align-items: center;
        gap: var(--spacing-sm);
        padding: var(--spacing-sm) var(--spacing-lg);
        color: var(--wp-text-primary);
        cursor: pointer;
        transition: all 0.2s ease;
        border-radius: 6px;
        margin: 0 var(--spacing-md);
    }

    .app-name:hover {
        background: rgba(6, 147, 227, 0.1);
        color: var(--wp-primary);
    }

    .app-name.selected {
        background: var(--wp-primary);
        color: white;
    }

    .app-icon {
        font-size: 16px;
    }

    .app-title {
        flex: 1;
        font-weight: 600;
        font-size: 14px;
    }

    .app-arrow {
        font-size: 14px;
        transition: transform 0.2s ease;
    }

    .app-section.expanded .app-arrow {
        transform: rotate(90deg);
    }

    .app-model-list {
        display: none;
        position: absolute;
        left: 250px;
        top: 0;
        background: var(--wp-surface);
        border: 1px solid rgba(255, 255, 255, 0.1);
        border-radius: 8px;
        min-width: 200px;
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        z-index: 1000;
        animation: slideInLeft 0.2s ease-out;
        overflow: hidden;
    }

    @keyframes slideInLeft {
        from {
            opacity: 0;
            transform: translateX(-10px);
        }
        to {
            opacity: 1;
            transform: translateX(0);
        }
    }

    .app-model-item {
        display: flex;
        align-items: center;
        gap: var(--spacing-sm);
        padding: var(--spacing-sm) var(--spacing-lg);
        color: var(--wp-text-secondary);
        text-decoration: none;
        font-size: 13px;
        border-left: 3px solid transparent;
        transition: all 0.2s ease;
    }

    .app-model-item:hover {
        background: rgba(6, 147, 227, 0.1);
        color: var(--wp-text-primary);
        border-left-color: var(--wp-primary);
        padding-left: var(--spacing-xl);
    }

    .app-model-item.active {
        background: rgba(6, 147, 227, 0.15);
        color: var(--wp-primary);
        border-left-color: var(--wp-primary);
        font-weight: 500;
    }

    .model-icon {
        font-size: 12px;
    }

    /* ===== MAIN CONTENT ADJUSTMENT ===== */
    #content {
        margin: var(--spacing-lg);
        margin-left: 270px; /* Account for sidebar */
    }

    .breadcrumbs {
        display: none !important;
    }

    /* ===== ENHANCED COMPONENTS ===== */
    .dashboard .module,
    #changelist {
        background: var(--wp-surface);
        border: 1px solid rgba(255, 255, 255, 0.1);
        border-radius: 8px;
        overflow: hidden;
        margin-bottom: var(--spacing-lg);
    }

    .module h2, .module caption {
        background: rgba(6, 147, 227, 0.1) !important;
        color: var(--wp-primary) !important;
        border: none !important;
        font-weight: 600;
        padding: var(--spacing-md) var(--spacing-lg) !important;
        font-size: 14px;
    }

    .button, input[type=submit], input[type=button], .submit-row input, a.button {
        background: linear-gradient(135deg, var(--wp-primary) 0%, #1a5f9e 100%) !important;
        color: white !important;
        border: none !important;
        border-radius: 6px !important;
        padding: 10px 20px !important;
        font-weight: 500 !important;
        transition: all 0.2s ease !important;
    }

    .button:hover, input[type=submit]:hover {
        transform: translateY(-1px);
        box-shadow: 0 4px 12px rgba(6, 147, 227, 0.3);
    }

    /* ===== RESPONSIVE DESIGN ===== */
    @media (max-width: 768px) {
        #nav-sidebar {
            width: 200px;
        }
        
        #content {
            margin-left: 220px;
        }
        
        .app-model-list {
            left: 200px;
        }
        
        .transformed-app-models {
            overflow-x: auto;
            padding-bottom: var(--spacing-sm);
        }
        
        .transformed-model-item {
            white-space: nowrap;
        }
    }

    /* ===== SCROLLBAR STYLING ===== */
    ::-webkit-scrollbar {
        width: 8px;
        height: 8px;
    }

    ::-webkit-scrollbar-track {
        background: rgba(255, 255, 255, 0.05);
        border-radius: 4px;
    }

    ::-webkit-scrollbar-thumb {
        background: var(--wp-primary);
        border-radius: 4px;
    }

    ::-webkit-scrollbar-thumb:hover {
        background: #1a5f9e;
    }
</style>
{% endblock %}

{% block branding %}
<div id="branding-container">
    <div class="branding-main">
        <h1 id="site-name">
            <a href="{% url 'admin:index' %}">
                <div class="logo-container">
                    <img src="{% static 'logo.png' %}" alt="Logo" class="site-logo" 
                         onerror="this.style.display='none'; this.nextElementSibling.style.display='block';">
                    <span class="logo-fallback" style="display: none;">🏢</span>
                </div>
                <span class="logo-subtitle">Admin Portal</span>
            </a>
        </h1>
    </div>
    <div class="header-user">
        <div class="user-profile-minimal">
            <span class="user-avatar-minimal">👤</span>
            <span class="user-name">{{ user.username|default:"Admin" }}</span>
        </div>
    </div>
</div>
{% endblock %}

{% block userlinks %}
    {{ block.super }}
    <!-- Removed API Docs and other clutter -->
{% endblock %}

{% block nav-global %}
<!-- Include custom sidebar -->
{% include "admin/app_list.html" %}
{% endblock %}

{% block footer %}
<!-- Footer removed as requested -->
{% endblock %}
"@

# Check if base_site.html exists, if not create it
$baseSitePath = "templates\admin\base_site.html"
if (Test-Path $baseSitePath) {
    Write-Host "base_site.html already exists at: $baseSitePath" -ForegroundColor Yellow
    Write-Host "Backing up existing file..." -ForegroundColor Yellow
    Copy-Item $baseSitePath "$baseSitePath.backup" -Force
}

Set-Content -Path $baseSitePath -Value $baseSiteContent
Write-Host "Created/Updated templates/admin/base_site.html" -ForegroundColor Green

# 5. Create update_urls.py script
$updateUrlsContent = @"
# update_urls.py - Run this to update your project URLs
import os
import sys

# Add the backend directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Update your lms_project/urls.py
urls_content = '''
from django.contrib import admin
from django.urls import path, include
from core.admin import hosi_admin_site  # Import custom admin site

urlpatterns = [
    # Use custom admin site instead of default
    path('admin/', hosi_admin_site.urls),
    
    # Your other URLs...
]
'''

print("To use the custom admin site, update your lms_project/urls.py:")
print("==============================================================")
print(urls_content)
print("\nOr keep both:")
print("path('admin/', admin.site.urls),  # Default admin")
print("path('custom-admin/', hosi_admin_site.urls),  # Custom admin")
"@

Set-Content -Path "update_admin_urls.py" -Value $updateUrlsContent
Write-Host "Created update_admin_urls.py helper script" -ForegroundColor Green

# 6. Create requirements.txt for any additional packages (if needed)
$requirementsContent = @"
# For enhanced admin interface (if needed)
# django-admin-interface==3.2.0
# django-jet==1.0.8
"@

if (-not (Test-Path "requirements-admin.txt")) {
    Set-Content -Path "requirements-admin.txt" -Value $requirementsContent
    Write-Host "Created requirements-admin.txt (optional)" -ForegroundColor Gray
}

Write-Host "`nSetup Complete!" -ForegroundColor Green
Write-Host "===============" -ForegroundColor Cyan
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Make sure 'core' is in INSTALLED_APPS in settings.py" -ForegroundColor White
Write-Host "2. Restart your Django server" -ForegroundColor White
Write-Host "3. Update your logo.png in static/ directory" -ForegroundColor White
Write-Host "4. Check update_admin_urls.py for URL configuration" -ForegroundColor White
Write-Host "`nFiles created:" -ForegroundColor Cyan
Write-Host "- core/admin.py (Custom AdminSite)" -ForegroundColor White
Write-Host "- core/templatetags/admin_custom.py (Template tags)" -ForegroundColor White
Write-Host "- templates/admin/app_list.html (Enhanced sidebar)" -ForegroundColor White
Write-Host "- templates/admin/base_site.html (Main admin template)" -ForegroundColor White
Write-Host "- update_admin_urls.py (URL helper)" -ForegroundColor White