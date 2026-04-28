# apps/enrollments/urls.py
from django.urls import path
from . import views

# app_name = 'enrollments'

urlpatterns = [
    path('provisional/', views.create_provisional_enrollment, name='create_provisional'),
    path('provisional/list/', views.get_provisional_enrollments, name='list_provisional'),
]
