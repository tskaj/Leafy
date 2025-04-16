from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .serializers import RegisterSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from .serializers import CustomTokenObtainPairSerializer

from rest_framework.parsers import MultiPartParser
from rest_framework.decorators import api_view, permission_classes
from tensorflow.keras.preprocessing.image import load_img, img_to_array
from tensorflow.keras.models import load_model
import numpy as np
from django.http import JsonResponse
import os
from io import BytesIO
from PIL import Image
from .models import DiseaseInfo  # Make sure this model exists in your models.py
from django.utils import timezone


class RegisterView(APIView):
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "User registered successfully"}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

class DeleteUserView(APIView):
    permission_classes = [IsAuthenticated]

    def delete(self, request):
        try:
            # Get the logged-in user
            user = request.user
            user.delete()
            return Response({"message": "User deleted successfully"}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Load the trained model
MODEL_PATH = os.path.join("models", "My_Efficient-B1_acc98.3.h5")  # Model Path
model = load_model(MODEL_PATH)

# Define class labels (update this list to match your model's output)
CLASS_LABELS = ["Healthy", "Diseased"]  # Replace with your actual labels

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def predict_image(request):
    # Ensure that MultiPartParser is being used
    parser_classes = [MultiPartParser]
    
    # Define class labels (update this list with your actual labels)
    CLASS_LABELS = [
        "Tomato___Bacterial_spot", "Tomato___Early_blight", "Tomato___Late_blight", "Tomato___Leaf_Mold", "Tomato___Septoria_leaf_spot",
        "Tomato___Spider_mites Two-spotted_spider_mite", "Tomato___Target_Spot", "Tomato___Tomato_Yellow_Leaf_Curl_Virus", "Tomato___Tomato_mosaic_virus", "Healthy"
    ]  # Replace with your actual labels
    
    # Check if the request contains an image
    if "image" not in request.data:
        return JsonResponse({"error": "No image provided"}, status=400)

    # Get the uploaded image file
    image = request.data["image"]
    
    try:
        # Convert the InMemoryUploadedFile to a file-like object
        img_file = Image.open(BytesIO(image.read()))
        
        # Ensure the image has 3 channels (RGB)
        if img_file.mode != "RGB":
            img_file = img_file.convert("RGB")
        
        # Resize the image to the required input size
        img = img_file.resize((224, 224))
        
        # Normalize pixel values and convert to NumPy array
        img_array = img_to_array(img) / 255.0
        img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension

        # Make prediction
        predictions = model.predict(img_array)
        
        # Get the index of the highest predicted class
        predicted_class_index = np.argmax(predictions, axis=1)[0]
        
        # Map index to class label
        predicted_class = CLASS_LABELS[predicted_class_index]
        
        # Include probabilities for each class in the response
        probabilities = {CLASS_LABELS[i]: float(predictions[0][i]) for i in range(len(CLASS_LABELS))}

        # Return the prediction result
        return JsonResponse({
            "prediction": predicted_class,
            "probabilities": probabilities
        })

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


# Add this new view for anonymous prediction
@api_view(["POST"])
def predict_image_anonymous(request):
    # Ensure that MultiPartParser is being used
    parser_classes = [MultiPartParser]
    
    # Define class labels (update this list with your actual labels)
    CLASS_LABELS = [
        "Tomato___Bacterial_spot", "Tomato___Early_blight", "Tomato___Late_blight", "Tomato___Leaf_Mold", "Tomato___Septoria_leaf_spot",
        "Tomato___Spider_mites Two-spotted_spider_mite", "Tomato___Target_Spot", "Tomato___Tomato_Yellow_Leaf_Curl_Virus", "Tomato___Tomato_mosaic_virus", "Healthy"
    ]
    
    # Check if the request contains an image
    if "image" not in request.data:
        return JsonResponse({"error": "No image provided"}, status=400)

    # Get the uploaded image file
    image = request.data["image"]
    
    try:
        # Convert the InMemoryUploadedFile to a file-like object
        img_file = Image.open(BytesIO(image.read()))
        
        # Ensure the image has 3 channels (RGB)
        if img_file.mode != "RGB":
            img_file = img_file.convert("RGB")
        
        # Resize the image to the required input size
        img = img_file.resize((224, 224))
        
        # Normalize pixel values and convert to NumPy array
        img_array = img_to_array(img) / 255.0
        img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension

        # Make prediction
        predictions = model.predict(img_array)
        
        # Get the index of the highest predicted class
        predicted_class_index = np.argmax(predictions, axis=1)[0]
        
        # Map index to class label
        predicted_class = CLASS_LABELS[predicted_class_index]
        
        # Include probabilities for each class in the response
        probabilities = {CLASS_LABELS[i]: float(predictions[0][i]) for i in range(len(CLASS_LABELS))}

        # Return the prediction result
        return JsonResponse({
            "prediction": predicted_class,
            "probabilities": probabilities
        })

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

# Add this new view
class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        serializer = UserProfileSerializer(user)
        return Response(serializer.data)
    
    def put(self, request):
        user = request.user
        serializer = UserProfileSerializer(user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)


@api_view(["GET"])
def get_disease_info(request, disease_name):
    try:
        disease_info = DiseaseInfo.objects.get(disease_name=disease_name)
        return JsonResponse({
            "disease_name": disease_info.disease_name,
            "description": disease_info.description,
            "treatment": disease_info.treatment,
            "prevention": disease_info.prevention
        })
    except DiseaseInfo.DoesNotExist:
        return JsonResponse({"error": "Disease information not found"}, status=404)


# Add these views to your existing views.py file

class CommunityPostListCreateView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [MultiPartParser]
    
    def get(self, request):
        # Return dummy data instead of trying to access a non-existent model
        dummy_posts = [
            {
                'id': 1,
                'user': request.user.username,
                'caption': 'My beautiful plant collection',
                'image': '/media/posts/plant1.jpg',
                'created_at': timezone.now().isoformat(),
                'like_count': 12,
                'is_liked': True,
                'comments': [
                    {
                        'id': 1,
                        'user': 'plant_lover',
                        'text': 'Amazing collection!',
                        'created_at': timezone.now().isoformat()
                    }
                ]
            },
            {
                'id': 2,
                'user': 'garden_enthusiast',
                'caption': 'Spring flowers in my garden',
                'image': '/media/posts/garden.jpg',
                'created_at': timezone.now().isoformat(),
                'like_count': 8,
                'is_liked': False,
                'comments': []
            }
        ]
        return Response({'success': True, 'data': dummy_posts})
    
    def post(self, request):
        # For now, just return a success response with dummy data
        return Response({
            'success': True,
            'data': {
                'id': 3,
                'user': request.user.username,
                'caption': request.data.get('caption', ''),
                'image': '/media/posts/new_placeholder.jpg',
                'created_at': timezone.now().isoformat(),
                'like_count': 0,
                'is_liked': False,
                'comments': []
            }
        }, status=status.HTTP_201_CREATED)
        serializer = CommunityPostSerializer(posts, many=True, context={'request': request})
        return Response(serializer.data)
    
    def post(self, request):
        serializer = CommunityPostSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save(user=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class CommunityPostDetailView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get_object(self, pk):
        try:
            return CommunityPost.objects.get(pk=pk)
        except CommunityPost.DoesNotExist:
            raise Http404
    
    def get(self, request, pk):
        post = self.get_object(pk)
        serializer = CommunityPostSerializer(post, context={'request': request})
        return Response(serializer.data)
    
    def delete(self, request, pk):
        post = self.get_object(pk)
        if post.user != request.user:
            return Response({"error": "You don't have permission to delete this post"}, status=status.HTTP_403_FORBIDDEN)
        post.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

class PostLikeView(APIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, pk):
        try:
            post = CommunityPost.objects.get(pk=pk)
            if post.likes.filter(id=request.user.id).exists():
                post.likes.remove(request.user)
                return Response({"liked": False, "like_count": post.like_count})
            else:
                post.likes.add(request.user)
                return Response({"liked": True, "like_count": post.like_count})
        except CommunityPost.DoesNotExist:
            return Response({"error": "Post not found"}, status=status.HTTP_404_NOT_FOUND)

class CommentListCreateView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request, post_id):
        comments = Comment.objects.filter(post_id=post_id)
        serializer = CommentSerializer(comments, many=True)
        return Response(serializer.data)
    
    def post(self, request, post_id):
        try:
            post = CommunityPost.objects.get(pk=post_id)
            serializer = CommentSerializer(data=request.data)
            if serializer.is_valid():
                serializer.save(user=request.user, post=post)
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        except CommunityPost.DoesNotExist:
            return Response({"error": "Post not found"}, status=status.HTTP_404_NOT_FOUND)
