from django.urls import path
from .views import industry_course_list, active_courses, list_industries, list_roles, course_list

urlpatterns = [
    path('industry/<int:industry_id>/', industry_course_list, name='industry_course_list'),
    path('active-courses/', active_courses, name='active_courses'),
    path('courses/', course_list, name='course_list'),
    path('industries/', list_industries, name='list_industries'),
    path('roles/', list_roles, name='list_roles'),
]
