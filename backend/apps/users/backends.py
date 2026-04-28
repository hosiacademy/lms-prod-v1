from django.contrib.auth import get_user_model
from django.contrib.auth.backends import ModelBackend


class EmailOrUsernameBackend(ModelBackend):
    """
    Authenticate with either email or username.
    The frontend always sends the email address in the 'username' field,
    so this backend first tries a lookup by email, then falls back to username.
    """

    def authenticate(self, request, username=None, password=None, **kwargs):
        User = get_user_model()

        if username is None:
            return None

        # Try email lookup first
        try:
            user = User.objects.get(email__iexact=username)
        except User.DoesNotExist:
            # Fall back to username lookup
            try:
                user = User.objects.get(username__iexact=username)
            except User.DoesNotExist:
                return None

        if user.check_password(password) and self.user_can_authenticate(user):
            return user

        return None
