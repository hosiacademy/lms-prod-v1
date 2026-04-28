from django.urls import path
from ..views.quotation_views import (
    GetTrainingTypesView,
    GetTrainingStreamsView,
    GetCoursesListView,
    GetMasterclassesListView,
    GetLearnershipsListView,
    CreateQuotationView,
    ListQuotationsView,
    QuotationDetailView,
    UpdateQuotationView,
    DeleteQuotationView,
    SendQuotationEmailView,
    SendQuotationSMSView,
    PublicQuotationView,
)

urlpatterns = [
    path('', ListQuotationsView.as_view(), name='quotation-list'),
    path('training-types/', GetTrainingTypesView.as_view(), name='training-types'),
    path('streams/', GetTrainingStreamsView.as_view(), name='training-streams'),
    path('courses/', GetCoursesListView.as_view(), name='quotation-courses'),
    path('masterclasses/', GetMasterclassesListView.as_view(), name='quotation-masterclasses'),
    path('learnerships/', GetLearnershipsListView.as_view(), name='quotation-learnerships'),
    path('create/', CreateQuotationView.as_view(), name='quotation-create'),
    path('public/<str:quotation_number>/', PublicQuotationView.as_view(), name='quotation-public-detail'),
    path('<int:quotation_id>/send-email/', SendQuotationEmailView.as_view(), name='quotation-send-email'),
    path('<int:quotation_id>/send-sms/', SendQuotationSMSView.as_view(), name='quotation-send-sms'),
    path('<str:quotation_number>/', QuotationDetailView.as_view(), name='quotation-detail'),
    path('<int:pk>/update/', UpdateQuotationView.as_view(), name='quotation-update'),
    path('<int:pk>/delete/', DeleteQuotationView.as_view(), name='quotation-delete'),
]
