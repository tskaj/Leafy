from django.urls import path
from .views import DiseaseDetectionView, AnonymousDiseaseDetectionView, AvailableCropsView, validate_leaf, classify_plant_disease

urlpatterns = [
    path('detect/', DiseaseDetectionView.as_view(), name='disease_detection'),
    path('detect/anonymous/', AnonymousDiseaseDetectionView.as_view(), name='anonymous_disease_detection'),
    path('crops/', AvailableCropsView.as_view(), name='available_crops'),
    path('validate-leaf/', validate_leaf, name='validate_leaf'),
    path('classify-disease/', classify_plant_disease, name='classify_plant_disease'),
]