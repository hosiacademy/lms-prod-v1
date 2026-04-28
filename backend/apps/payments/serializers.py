# apps/payments/serializers.py
from rest_framework import serializers
from .models import Order, Cart, PaymentTransaction, PaymentRefund, DepositRecord, PaymentProviderModel, ProviderPaymentMethod, CountryPaymentLandscape


class PaymentProviderSerializer(serializers.ModelSerializer):
    """Serializer for payment providers"""
    class Meta:
        model = PaymentProviderModel
        fields = '__all__'


class ProviderPaymentMethodSerializer(serializers.ModelSerializer):
    """Serializer for provider payment methods"""
    class Meta:
        model = ProviderPaymentMethod
        fields = '__all__'


class CountryPaymentLandscapeSerializer(serializers.ModelSerializer):
    """Serializer for country payment landscapes"""
    class Meta:
        model = CountryPaymentLandscape
        fields = '__all__'


class OrderCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating orders"""
    class Meta:
        model = Order
        fields = (
            'user', 'total_amount', 'currency', 'payment_method',
            'billing_address', 'shipping_address', 'notes', 'metadata'
        )
        read_only_fields = ('order_number', 'created_at', 'updated_at')


class OrderSerializer(serializers.ModelSerializer):
    """Serializer for viewing orders"""
    class Meta:
        model = Order
        fields = '__all__'
        read_only_fields = (
            'order_number', 'created_at', 'updated_at', 'payment_status',
            'transaction_id', 'completed_at'
        )


class CartSerializer(serializers.ModelSerializer):
    """Serializer for shopping cart"""
    item_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Cart
        fields = (
            'id', 'user', 'items', 'total_amount', 'currency',
            'created_at', 'updated_at', 'item_count'
        )
        read_only_fields = ('created_at', 'updated_at', 'item_count')
    
    def get_item_count(self, obj):
        return obj.items.count() if hasattr(obj, 'items') else 0


class CartItemSerializer(serializers.ModelSerializer):
    """Serializer for cart items (if you have a CartItem model)"""
    # If you have a CartItem model, define it here
    # Otherwise, remove this serializer
    pass


class PaymentTransactionSerializer(serializers.ModelSerializer):
    """Serializer for payment transactions"""
    class Meta:
        model = PaymentTransaction
        fields = '__all__'
        read_only_fields = (
            'transaction_id', 'created_at', 'updated_at', 'status',
            'provider_reference', 'webhook_received', 'webhook_processed_at'
        )


class PaymentRefundSerializer(serializers.ModelSerializer):
    """Serializer for refunds"""
    class Meta:
        model = PaymentRefund
        fields = '__all__'
        read_only_fields = (
            'refund_id', 'created_at', 'updated_at', 'status',
            'provider_refund_id', 'completed_at'
        )


class DepositRecordSerializer(serializers.ModelSerializer):
    """Serializer for deposit records"""
    class Meta:
        model = DepositRecord
        fields = '__all__'
        read_only_fields = (
            'deposit_id', 'created_at', 'updated_at', 'status'
        )


# If you need to keep the old Checkout serializer names for compatibility,
# you can create aliases or adapters:

class CheckoutCreateSerializer(serializers.Serializer):
    """
    Adapter serializer for compatibility with old checkout API.
    Maps to OrderCreateSerializer functionality.
    """
    user = serializers.PrimaryKeyRelatedField(read_only=True)
    billing_detail = serializers.JSONField(required=False)
    package = serializers.CharField(required=False)
    coupon = serializers.CharField(required=False, allow_blank=True)
    purchase_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    price = serializers.DecimalField(max_digits=10, decimal_places=2)
    payment_method = serializers.CharField(max_length=50)
    currency = serializers.CharField(max_length=3, default='USD')
    
    def validate_billing_detail(self, value):
        """Harden phone and email validation for African contexts"""
        if not value:
            raise serializers.ValidationError("Billing details are required.")
            
        email = value.get('email')
        phone = value.get('phone')
        country = value.get('country_code', 'ZA')
        
        if not email or '@' not in email:
            raise serializers.ValidationError("A valid work email is required.")
            
        if not phone:
            raise serializers.ValidationError("Phone number is required for payment verification.")
            
        # African Phone Validation Logic
        prefixes = {'ZA': '+27', 'KE': '+254', 'NG': '+234', 'GH': '+233'}
        prefix = prefixes.get(country, '+27')
        
        if not phone.startswith(prefix) and not phone.startswith('0'):
            raise serializers.ValidationError(f"Phone number must start with {prefix} or 0 for {country}.")
            
        return value

    def create(self, validated_data):
        # Convert checkout data to order data
        from .models import Order
        
        # Extract user from context
        user = self.context['request'].user
        
        # Create order from checkout data
        order = Order.objects.create(
            user=user,
            total_amount=validated_data.get('purchase_price', 0),
            currency=validated_data.get('currency', 'USD'),
            payment_method=validated_data.get('payment_method', 'card'),
            metadata={
                'billing_detail': validated_data.get('billing_detail'),
                'package': validated_data.get('package'),
                'coupon': validated_data.get('coupon'),
                'original_price': validated_data.get('price', 0),
            }
        )
        
        return order


class CheckoutSerializer(serializers.ModelSerializer):
    """
    Adapter serializer for compatibility with old checkout API.
    Maps to OrderSerializer for viewing.
    """
    # Map old checkout fields to order fields
    tracking = serializers.CharField(source='order_number')
    status = serializers.BooleanField(source='payment_status_bool')  # Need to add this property
    response = serializers.JSONField(source='metadata')
    
    class Meta:
        model = Order
        fields = (
            'tracking', 'user', 'billing_address', 'items', 'total_amount',
            'currency', 'payment_method', 'payment_status', 'metadata',
            'created_at'
        )
        read_only_fields = fields