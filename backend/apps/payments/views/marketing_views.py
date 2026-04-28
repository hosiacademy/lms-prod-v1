from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db.models import Count
from ..models_marketing import MailingList, MailingListContact, MarketingCampaign
from ..models import CouponCode, CouponPathway, CouponPromotionType, CouponDiscountType
from .bulk_sms_views import _is_admin

class MailingListView(APIView):
    # ... (keeping existing implementation)
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        lists = MailingList.objects.filter(owner=request.user).annotate(
            contact_count=Count('contacts')
        )
        
        return Response({
            'mailing_lists': [
                {
                    'id': l.id,
                    'name': l.name,
                    'description': l.description,
                    'theme': l.theme,
                    'country': l.country,
                    'is_universal': l.is_universal,
                    'contact_count': l.contact_count,
                    'created_at': l.created_at.isoformat(),
                } for l in lists
            ]
        })

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        name = request.data.get('name')
        description = request.data.get('description', '')
        theme = request.data.get('theme')
        country = request.data.get('country')
        is_universal = request.data.get('is_universal', False)
        
        if not name:
            return Response({'error': 'Name is required'}, status=400)
            
        mailing_list = MailingList.objects.create(
            name=name,
            description=description,
            theme=theme,
            country=country,
            is_universal=is_universal,
            owner=request.user
        )
        
        return Response({
            'id': mailing_list.id,
            'name': mailing_list.name,
            'theme': mailing_list.theme,
            'success': True
        })

class MailingListContactView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, list_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
            
        try:
            mailing_list = MailingList.objects.get(id=list_id, owner=request.user)
        except MailingList.DoesNotExist:
            return Response({'error': 'Mailing list not found'}, status=404)
            
        contacts = mailing_list.contacts.all()
        return Response({
            'contacts': [
                {
                    'id': c.id,
                    'name': c.name,
                    'email': c.email,
                    'phone': c.phone,
                    'country_code': c.country_code,
                } for c in contacts
            ]
        })

    def post(self, request, list_id):
        if not _is_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
            
        try:
            mailing_list = MailingList.objects.get(id=list_id, owner=request.user)
        except MailingList.DoesNotExist:
            return Response({'error': 'Mailing list not found'}, status=404)
            
        contacts_data = request.data.get('contacts', [])
        if not isinstance(contacts_data, list):
            contacts_data = [contacts_data]
            
        created_count = 0
        for c in contacts_data:
            MailingListContact.objects.create(
                mailing_list=mailing_list,
                name=c.get('name', 'Unknown'),
                email=c.get('email'),
                phone=c.get('phone'),
                country_code=c.get('country_code', '+27')
            )
            created_count += 1
            
        return Response({'success': True, 'count': created_count})

class MarketingCampaignView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        campaigns = MarketingCampaign.objects.filter(created_by=request.user)
        return Response({
            'campaigns': [
                {
                    'id': c.id,
                    'name': c.name,
                    'theme': c.theme,
                    'message': c.message,
                    'method': c.method,
                    'media_url': c.media_url,
                    'created_at': c.created_at.isoformat(),
                } for c in campaigns
            ]
        })

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
            
        name = request.data.get('name')
        if not name:
            return Response({'error': 'Campaign name is required'}, status=400)
            
        campaign = MarketingCampaign.objects.create(
            name=name,
            theme=request.data.get('theme'),
            message=request.data.get('message'),
            method=request.data.get('method', 'email'),
            media_url=request.data.get('media_url'),
            created_by=request.user
        )
        return Response({'id': campaign.id, 'success': True})

class CouponManagementView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
            
        coupons = CouponCode.objects.all()
        return Response({
            'coupons': [
                {
                    'id': c.id,
                    'code': c.code,
                    'name': c.name,
                    'discount_value': str(c.discount_value),
                    'discount_type': c.discount_type,
                    'product_pathway': c.product_pathway,
                    'is_active': c.is_active,
                    'valid_until': c.valid_until.isoformat() if c.valid_until else None,
                } for c in coupons
            ],
            'pathways': CouponPathway.choices,
            'promo_types': CouponPromotionType.choices,
            'discount_types': CouponDiscountType.choices,
        })

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
            
        data = request.data
        coupon = CouponCode.objects.create(
            code=data.get('code'),
            name=data.get('name'),
            discount_type=data.get('discount_type', 'percentage'),
            discount_value=data.get('discount_value', 0),
            product_pathway=data.get('product_pathway', 'all'),
            valid_from=data.get('valid_from', '2026-01-01T00:00:00Z'),
            valid_until=data.get('valid_until', '2027-01-01T00:00:00Z'),
            is_active=True,
            created_by=request.user
        )
        return Response({'id': coupon.id, 'success': True})
