from django.urls import path
from .views import RegisterView, LoginView, predict_image, DeleteUserView
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path("predict/", predict_image, name="predict_image"),
    path('delete-user/', DeleteUserView.as_view(), name='delete-user')
]
