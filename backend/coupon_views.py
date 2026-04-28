from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

class PublicCouponsView(APIView):
    def get(self, request):
        return Response([], status=200)

class ListCouponsView(APIView):
    def get(self, request):
        return Response([], status=200)

class ValidateCouponView(APIView):
    def post(self, request):
        return Response({'valid': False, 'message': 'Invalid coupon'}, status=200)

class RedeemCouponView(APIView):
    def post(self, request):
        return Response({'success': False, 'message': 'Redeem disabled'}, status=200)
