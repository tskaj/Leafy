from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Post, Like, Comment, Reaction
from .serializers import PostSerializer, CommentSerializer, ReactionSerializer
from django.shortcuts import get_object_or_404
from rest_framework.parsers import MultiPartParser, FormParser

class PostViewSet(viewsets.ModelViewSet):
    queryset = Post.objects.all().order_by('-created_at')
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def get_serializer_context(self):
        context = super().get_serializer_context()
        context.update({"request": self.request})
        return context
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
    
    def list(self, request):
        # Override the list method to ensure we're returning all posts
        posts = Post.objects.all().order_by('-created_at')
        serializer = self.get_serializer(posts, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def like(self, request, pk=None):
        post = self.get_object()
        user = request.user
        
        like, created = Like.objects.get_or_create(user=user, post=post)
        
        if not created:
            # User already liked the post, so unlike it
            like.delete()
            return Response({"liked": False, "like_count": post.like_count})
        
        return Response({"liked": True, "like_count": post.like_count})
    
    @action(detail=True, methods=['post'])
    def react(self, request, pk=None):
        post = self.get_object()
        user = request.user
        reaction_type = request.data.get('reaction_type')
        
        if not reaction_type:
            return Response({'error': 'Reaction type is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if user already reacted with this type
        existing_reaction = Reaction.objects.filter(
            user=user, post=post, reaction_type=reaction_type
        ).first()
        
        if existing_reaction:
            # Remove the reaction if it already exists
            existing_reaction.delete()
            return Response({'status': 'reaction removed'})
        else:
            # Create new reaction
            reaction = Reaction.objects.create(
                user=user, post=post, reaction_type=reaction_type
            )
            return Response(ReactionSerializer(reaction).data)
    
    @action(detail=True, methods=['post'])
    def comment(self, request, pk=None):
        post = self.get_object()
        content = request.data.get('content')
        parent_id = request.data.get('parent_id')
        
        if not content:
            return Response({'error': 'Comment content is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if this is a reply to another comment
        parent = None
        if parent_id:
            parent = get_object_or_404(Comment, id=parent_id)
        
        comment = Comment.objects.create(
            user=request.user,
            post=post,
            parent=parent,
            content=content
        )
        
        return Response(CommentSerializer(comment).data)

class CommentViewSet(viewsets.ModelViewSet):
    queryset = Comment.objects.all()
    serializer_class = CommentSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    @action(detail=True, methods=['post'])
    def reply(self, request, pk=None):
        parent_comment = self.get_object()
        content = request.data.get('content')
        
        if not content:
            return Response({'error': 'Reply content is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        reply = Comment.objects.create(
            user=request.user,
            post=parent_comment.post,
            parent=parent_comment,
            content=content
        )
        
        return Response(CommentSerializer(reply).data)