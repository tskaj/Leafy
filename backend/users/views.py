from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .serializers import RegisterSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializers import CustomTokenObtainPairSerializer

from rest_framework.parsers import MultiPartParser
from rest_framework.decorators import api_view
from tensorflow.keras.preprocessing.image import load_img, img_to_array
from tensorflow.keras.models import load_model
import numpy as np
from django.http import JsonResponse
import os
from io import BytesIO
from PIL import Image


class RegisterView(APIView):
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "User registered successfully"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer




# Load the trained model
MODEL_PATH = os.path.join("models", "My_Efficient-B1_acc98.3.h5")  # Adjust path if necessary
model = load_model(MODEL_PATH)

# Define class labels (update this list to match your model's output)
CLASS_LABELS = ["Healthy", "Diseased"]  # Replace with your actual labels

@api_view(["POST"])
def predict_image(request):
    # Ensure that MultiPartParser is being used
    parser_classes = [MultiPartParser]
    
    # Check if the request contains an image
    if "image" not in request.data:
        return JsonResponse({"error": "No image provided"}, status=400)

    # Get the uploaded image file
    image = request.data["image"]
    
    try:
        # Convert the InMemoryUploadedFile to a file-like object
        img_file = Image.open(BytesIO(image.read()))
        img = img_file.resize((224, 224))  # Resize to the required input size
        img_array = img_to_array(img) / 255.0  # Normalize pixel values
        img_array = np.expand_dims(img_array, axis=0)

        # Make prediction
        predictions = model.predict(img_array)
        predicted_class_index = np.argmax(predictions, axis=1)[0]
        predicted_class = CLASS_LABELS[predicted_class_index]

        # Return the prediction result
        return JsonResponse({"prediction": predicted_class})

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)