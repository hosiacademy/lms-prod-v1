# apps/users/serializers.py

from rest_framework import serializers
from .models import User, UserThemePreference  # ← Only import the existing User model


class UserSerializer(serializers.ModelSerializer):
    """
    Serializer for reading/displaying existing User instances from the Infix LMS database.
    Uses the real fields from the 'users' table.
    """
    full_name = serializers.CharField(source='name', read_only=True)
    profile_picture = serializers.CharField(source='image', read_only=True)  # most commonly used in frontend

    class Meta:
        model = User
        fields = [
            'id', 'username', 'email', 'full_name', 'name', 'role_id',
            'photo', 'image', 'avatar', 'profile_picture',
            'headline', 'phone', 'address', 'city', 'country', 'zip', 'dob',
            'about', 'short_details',
            'facebook', 'twitter', 'linkedin', 'instagram', 'youtube',
            'balance', 'currency_id', 'special_commission',
            'payout', 'payout_icon', 'payout_email',
            'bank_name', 'branch_name', 'bank_account_number', 'account_holder_name', 'bank_type',
            'zoom_api_key_of_user', 'zoom_api_serect_of_user',
            'is_active', 'is_staff', 'is_superuser',
            'date_joined', 'last_login'
        ]
        read_only_fields = [
            'id', 'balance', 'date_joined', 'last_login',
            'is_staff', 'is_superuser'
        ]

    def to_representation(self, instance):
        """
        Add human-readable role name.
        For role_id=1 (Admin), checks AdminRole entries to return the specific
        admin sub-role (executive_admin, hr_admin, payment_admin) or 'admin' for superusers.
        """
        ret = super().to_representation(instance)
        if instance.role_id == 1 or instance.is_superuser:
            try:
                from apps.payments.models import AdminRole
                if AdminRole.is_executive_admin(instance):
                    ret['role_name'] = 'executive_admin'
                elif AdminRole.is_hr_admin(instance):
                    ret['role_name'] = 'hr_admin'
                elif AdminRole.is_payment_admin(instance):
                    ret['role_name'] = 'payment_admin'
                else:
                    ret['role_name'] = 'admin'
            except Exception:
                ret['role_name'] = 'admin'
        elif instance.role_id == 2:
            ret['role_name'] = 'instructor'
        elif instance.role_id == 3:
            ret['role_name'] = 'learner'
        else:
            ret['role_name'] = 'unknown'
        return ret


class UserThemePreferenceSerializer(serializers.ModelSerializer):
    """
    Serializer for user theme preferences.
    """
    class Meta:
        model = UserThemePreference
        fields = ['id', 'theme_mode', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class UserCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating new users (local registration or future sync).
    Handles password securely.
    """
    password = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'},
        help_text="Leave empty if syncing from external source"
    )

    class Meta:
        model = User
        fields = [
            'username', 'email', 'password', 'name', 'phone',
            'role_id', 'headline', 'about', 'payout_email'
        ]
        extra_kwargs = {
            'password': {'write_only': True},
            'email': {'required': True},
            'name': {'required': True}
        }

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User(**validated_data)
        user.set_password(password)
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop('password', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance


class UserUpdateSerializer(serializers.ModelSerializer):
    """
    For partial updates (profile editing by user or admin)
    """
    class Meta:
        model = User
        fields = [
            'name', 'headline', 'phone', 'address', 'city', 'country', 'zip',
            'about', 'short_details', 'facebook', 'twitter', 'linkedin',
            'instagram', 'youtube', 'payout_email', 'bank_name',
            'branch_name', 'bank_account_number', 'account_holder_name'
        ]