"""
Custom storage backends for Django.
Provides S3 storage for media files in production.
"""
from django.conf import settings
from django.core.files.storage import FileSystemStorage
from storages.backends.s3boto3 import S3Boto3Storage


class MediaStorage(S3Boto3Storage):
    """
    S3 storage for media files (user uploads, course images, etc.)
    """
    location = 'media'
    file_overwrite = False
    default_acl = 'public-read'


class StaticStorage(S3Boto3Storage):
    """
    S3 storage for static files (CSS, JS, images)
    """
    location = 'static'
    default_acl = 'public-read'


class PrivateMediaStorage(S3Boto3Storage):
    """
    S3 storage for private media files (user documents, certificates)
    """
    location = 'private'
    default_acl = 'private'
    file_overwrite = False
    custom_domain = False
    querystring_auth = True
    querystring_expire = 3600  # 1 hour


# Local storage fallback for development
class LocalMediaStorage(FileSystemStorage):
    """
    Local filesystem storage for development.
    """
    pass
