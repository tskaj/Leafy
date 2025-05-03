from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.decorators import api_view, permission_classes
from django.views.decorators.csrf import csrf_exempt
from .model_manager import model_manager
from .models import LeafImageDetection
from .roboflow_validation import validate_leaf_image
from .roboflow_disease import classify_disease
import os
import tempfile
import mimetypes
from PIL import Image as PILImage
import io

class AvailableCropsView(APIView):
    permission_classes = [AllowAny]
    
    def get(self, request):
        available_crops = list(model_manager.models.keys())
        return Response({'crops': available_crops}, status=status.HTTP_200_OK)

class DiseaseDetectionView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        if 'image' not in request.FILES:
            return Response({'error': 'No image provided'}, status=status.HTTP_400_BAD_REQUEST)
        
        image = request.FILES['image']
        crop_type = request.data.get('crop_type', 'tomato')  # Default to tomato
        
        # Validate image type
        content_type = image.content_type
        if content_type not in ['image/jpeg', 'image/jpg', 'image/png']:
            return Response({'error': 'Only JPEG and PNG images are allowed'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate image size (max 10MB)
        if image.size > 10 * 1024 * 1024:  # 10MB in bytes
            return Response({'error': 'Image size should be less than 10MB'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Save the uploaded image to a temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as temp_file:
            for chunk in image.chunks():
                temp_file.write(chunk)
            temp_file_path = temp_file.name
        
        try:
            # Make prediction
            result = model_manager.predict(temp_file_path, crop_type)
            
            # Save detection to database
            detection = LeafImageDetection(
                user=request.user,
                image=image,
                crop_type=crop_type,
                prediction=result['prediction'],
                confidence=max(result['probabilities'].values())
            )
            detection.save()
            
            # Delete the temporary file
            os.unlink(temp_file_path)
            
            return Response(result, status=status.HTTP_200_OK)
        except Exception as e:
            # Delete the temporary file
            if os.path.exists(temp_file_path):
                os.unlink(temp_file_path)
            
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class AnonymousDiseaseDetectionView(APIView):
    permission_classes = [AllowAny]
    
    def post(self, request):
        if 'image' not in request.FILES:
            return Response({'error': 'No image provided'}, status=status.HTTP_400_BAD_REQUEST)
        
        image = request.FILES['image']
        crop_type = request.data.get('crop_type', 'tomato')  # Default to tomato
        
        # Validate image type
        content_type = image.content_type
        if content_type not in ['image/jpeg', 'image/jpg', 'image/png']:
            return Response({'error': 'Only JPEG and PNG images are allowed'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Validate image size (max 10MB)
        if image.size > 10 * 1024 * 1024:  # 10MB in bytes
            return Response({'error': 'Image size should be less than 10MB'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Save the uploaded image to a temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as temp_file:
            for chunk in image.chunks():
                temp_file.write(chunk)
            temp_file_path = temp_file.name
        
        try:
            # Make prediction
            result = model_manager.predict(temp_file_path, crop_type)
            
            # Save detection to database (anonymous user)
            detection = LeafImageDetection(
                user=None,  # Anonymous user
                image=image,
                crop_type=crop_type,
                prediction=result['prediction'],
                confidence=max(result['probabilities'].values())
            )
            detection.save()
            
            # Delete the temporary file
            os.unlink(temp_file_path)
            
            return Response(result, status=status.HTTP_200_OK)
        except Exception as e:
            # Delete the temporary file
            if os.path.exists(temp_file_path):
                os.unlink(temp_file_path)
            
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def validate_leaf(request):
    """
    Endpoint to validate if an uploaded image contains a leaf
    """
    if 'image' not in request.FILES:
        return Response({'error': 'No image provided'}, status=status.HTTP_400_BAD_REQUEST)
    
    image_file = request.FILES['image']
    
    # Reset file pointer to beginning
    image_file.seek(0)
    
    # Use the Roboflow validation function
    is_leaf, confidence, success, message = validate_leaf_image(image_file)
    
    return Response({
        'is_leaf': is_leaf,
        'confidence': confidence,
        'success': success,
        'message': message
    })

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def classify_plant_disease(request):
    """
    Endpoint to classify plant disease using the Pagdurusa model
    """
    if 'image' not in request.FILES:
        return Response({'error': 'No image provided'}, status=status.HTTP_400_BAD_REQUEST)
    
    image_file = request.FILES['image']
    
    # Validate image type
    content_type = image_file.content_type
    if content_type not in ['image/jpeg', 'image/jpg', 'image/png']:
        return Response({'error': 'Only JPEG and PNG images are allowed'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Validate image size (max 10MB)
    if image_file.size > 10 * 1024 * 1024:  # 10MB in bytes
        return Response({'error': 'Image size should be less than 10MB'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Reset file pointer to beginning
    image_file.seek(0)
    
    # Use the Roboflow disease classification function
    success, result_data, message = classify_disease(image_file)
    
    if success:
        return Response({
            'success': True,
            'data': result_data
        })
    else:
        return Response({
            'success': False,
            'message': message
        }, status=status.HTTP_400_BAD_REQUEST)