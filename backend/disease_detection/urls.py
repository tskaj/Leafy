from django.urls import path
from .views import DiseaseDetectionView, AnonymousDiseaseDetectionView, AvailableCropsView

urlpatterns = [
    path('detect/', DiseaseDetectionView.as_view(), name='disease_detection'),
    path('detect/anonymous/', AnonymousDiseaseDetectionView.as_view(), name='anonymous_disease_detection'),
    path('crops/', AvailableCropsView.as_view(), name='available_crops'),
]