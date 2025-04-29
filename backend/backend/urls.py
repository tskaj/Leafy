from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, include
from users.views import (
    RegisterView, 
    LoginView, 
    DeleteUserView, 
    predict_image, 
    predict_image_anonymous,
    get_disease_info,
    UserProfileView,
    CommunityPostListCreateView,
    CommunityPostDetailView,
    PostLikeView,
    CommentListCreateView
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/community/', include('community.urls')),
    
    # Authentication endpoints
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('delete-account/', DeleteUserView.as_view(), name='delete-account'),
    
    # Prediction endpoints
    path('predict/', predict_image, name='predict'),
    path('predict-anonymous/', predict_image_anonymous, name='predict-anonymous'),
    
    # Disease info endpoint
    path('disease-info/<str:disease_name>/', get_disease_info, name='disease-info'),
    
    # User profile endpoint
    path('profile/', UserProfileView.as_view(), name='user-profile'),
    
    # Community endpoints
    path('community/posts/', CommunityPostListCreateView.as_view(), name='community-posts'),
    path('community/posts/<int:pk>/', CommunityPostDetailView.as_view(), name='community-post-detail'),
    path('community/posts/<int:pk>/like/', PostLikeView.as_view(), name='post-like'),
    path('community/posts/<int:post_id>/comments/', CommentListCreateView.as_view(), name='post-comments'),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
