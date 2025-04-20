from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated, AllowAny
from .model_manager import model_manager
import os
import tempfile

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
        
        # Save the uploaded image to a temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as temp_file:
            for chunk in image.chunks():
                temp_file.write(chunk)
            temp_file_path = temp_file.name
        
        try:
            # Make prediction
            result = model_manager.predict(temp_file_path, crop_type)
            
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
        
        # Save the uploaded image to a temporary file
        with tempfile.NamedTemporaryFile(delete=False, suffix='.jpg') as temp_file:
            for chunk in image.chunks():
                temp_file.write(chunk)
            temp_file_path = temp_file.name
        
        try:
            # Make prediction
            result = model_manager.predict(temp_file_path, crop_type)
            
            # Delete the temporary file
            os.unlink(temp_file_path)
            
            return Response(result, status=status.HTTP_200_OK)
        except Exception as e:
            # Delete the temporary file
            if os.path.exists(temp_file_path):
                os.unlink(temp_file_path)
            
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)