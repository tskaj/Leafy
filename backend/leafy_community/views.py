from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def post_list_create(request):
    if request.method == 'GET':
        # Placeholder for getting all posts
        return JsonResponse([
            {
                'id': 1,
                'user': 'testuser',
                'caption': 'My first plant post',
                'image': '/media/posts/placeholder.jpg',
                'created_at': '2023-06-01T12:00:00Z',
                'like_count': 5,
                'is_liked': False,
                'comments': []
            }
        ], safe=False)
    elif request.method == 'POST':
        # Placeholder for creating a post
        return JsonResponse({
            'id': 2,
            'user': request.user.username,
            'caption': request.data.get('caption', ''),
            'image': '/media/posts/new_placeholder.jpg',
            'created_at': '2023-06-02T12:00:00Z',
            'like_count': 0,
            'is_liked': False,
            'comments': []
        }, status=201)

@api_view(['GET', 'PUT', 'DELETE'])
@permission_classes([IsAuthenticated])
def post_detail(request, pk):
    # Placeholder for post detail
    return JsonResponse({
        'id': pk,
        'user': 'testuser',
        'caption': 'Post detail',
        'image': '/media/posts/placeholder.jpg',
        'created_at': '2023-06-01T12:00:00Z',
        'like_count': 5,
        'is_liked': False,
        'comments': []
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def like_post(request, pk):
    # Placeholder for liking a post
    return JsonResponse({
        'liked': True,
        'like_count': 6
    })

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_comment(request, pk):
    # Placeholder for adding a comment
    return JsonResponse({
        'id': 1,
        'post': pk,
        'user': request.user.username,
        'text': request.data.get('content', ''),
        'created_at': '2023-06-03T12:00:00Z'
    }, status=201)