from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),  # Keep this as is
    path('', include('users.urls')),  # Add this line to support direct URLs
    
    # Update these paths to use the new app names
    path('predict/', include('leafy_disease.urls')),
    path('predict-anonymous/', include('leafy_disease.urls')),
    
    path('community/', include('leafy_community.urls')),
]

# Add this for serving media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
