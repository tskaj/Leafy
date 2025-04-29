from rest_framework import serializers
from .models import Post, Comment, Like, Reaction
from django.contrib.auth import get_user_model

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    profile_image = serializers.ImageField(read_only=True)
    
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'profile_image']

class CommentSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = Comment
        fields = ['id', 'user', 'content', 'created_at', 'parent']

class PostSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    comments = CommentSerializer(many=True, read_only=True)
    is_liked = serializers.SerializerMethodField()
    like_count = serializers.SerializerMethodField()
    reactions = serializers.SerializerMethodField()
    
    class Meta:
        model = Post
        fields = ['id', 'user', 'caption', 'image', 'created_at', 'comments', 'is_liked', 'like_count', 'reactions']
    
    def get_is_liked(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return Like.objects.filter(post=obj, user=request.user).exists()
        return False
    
    def get_like_count(self, obj):
        return obj.likes.count()
    
    def get_reactions(self, obj):
        return ReactionSerializer(obj.reactions.all(), many=True).data


class ReactionSerializer(serializers.ModelSerializer):
    user = serializers.ReadOnlyField(source='user.username')
    
    class Meta:
        model = Reaction
        fields = ['id', 'user', 'post', 'reaction_type', 'created_at']