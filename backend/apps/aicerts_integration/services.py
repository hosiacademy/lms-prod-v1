"""
AICERTs Partnership Integration Services
Handles all API interactions with AICERTs LMS for:
- Course data synchronization
- User creation and management
- Course enrollment
- SSO authentication
- Instructor validation
"""

import hmac
import hashlib
import time
import requests
import logging
from typing import Dict, List, Optional, Tuple
from django.conf import settings
from django.core.cache import cache
from django.db import transaction

logger = logging.getLogger(__name__)


class AICERTsAPIError(Exception):
    """Custom exception for AICERTs API errors"""
    pass


class AICERTsAuthenticationError(AICERTsAPIError):
    """Authentication failed with AICERTs"""
    pass


class AICERTsEnrollmentError(AICERTsAPIError):
    """Enrollment operation failed"""
    pass


class HMACSignatureService:
    """
    Handles HMAC signature generation for AICERTs SSO API.

    Signature format: HMAC-SHA256(data, secret_key)
    Data format: "email:timestamp" or "userid:timestamp"
    """

    @staticmethod
    def generate_signature(data: str, secret_key: str = None) -> str:
        """
        Generate HMAC SHA256 signature.

        Args:
            data: String to sign (e.g., "user@example.com:1234567890")
            secret_key: HMAC secret key (defaults to settings)

        Returns:
            Hex-encoded HMAC signature
        """
        if secret_key is None:
            secret_key = settings.AICERTS_SECRET_KEY

        return hmac.new(
            secret_key.encode('utf-8'),
            data.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()

    @staticmethod
    def generate_timestamp_signature(identifier: str, timestamp: int = None) -> Tuple[int, str]:
        """
        Generate timestamp and signature for API call.

        Args:
            identifier: Email or user ID
            timestamp: Optional timestamp (generates current if None)

        Returns:
            Tuple of (timestamp, signature)
        """
        if timestamp is None:
            timestamp = int(time.time())

        data = f"{identifier}:{timestamp}"
        signature = HMACSignatureService.generate_signature(data)

        return timestamp, signature


class CourseDataService:
    """
    Service for interacting with AICERTs Course Data API (v1.1).
    Base URL: https://www.aicerts.ai/wp-json/aicerts-api/v1

    Endpoints:
    - GET /courses - List all courses (paginated)
    - GET /course/{id} - Get course details
    """

    BASE_URL = settings.AICERTS_COURSE_API_BASE_URL
    CACHE_TTL = 3600  # Cache course data for 1 hour

    @classmethod
    def get_courses(cls, page: int = 1, per_page: int = 100, search: str = None) -> Dict:
        """
        Fetch paginated list of courses from AICERTs.

        Args:
            page: Page number
            per_page: Items per page (max 100)
            search: Optional search keyword

        Returns:
            Dict with 'success', 'data', 'total', 'total_pages'

        Raises:
            AICERTsAPIError: On API failure
        """
        params = {
            'page': page,
            'per_page': min(per_page, 100)
        }

        if search:
            params['search'] = search

        try:
            response = requests.get(
                f"{cls.BASE_URL}/courses",
                params=params,
                timeout=settings.AICERTS_REQUEST_TIMEOUT
            )
            response.raise_for_status()

            data = response.json()
            if not data.get('success'):
                raise AICERTsAPIError(f"Course list API returned success=false")

            logger.info(f"Fetched {len(data.get('data', []))} courses from AICERTs (page {page})")
            return data

        except requests.RequestException as e:
            logger.error(f"Failed to fetch courses from AICERTs: {e}")
            raise AICERTsAPIError(f"Course list API failed: {e}")

    @classmethod
    def get_course_detail(cls, course_id: int, use_cache: bool = True) -> Dict:
        """
        Fetch detailed information for a specific course.

        Args:
            course_id: AICERTs course ID
            use_cache: Whether to use cached data

        Returns:
            Course detail dict

        Raises:
            AICERTsAPIError: On API failure or course not found
        """
        cache_key = f"aicerts_course_{course_id}"

        if use_cache:
            cached_data = cache.get(cache_key)
            if cached_data:
                logger.debug(f"Returning cached data for course {course_id}")
                return cached_data

        try:
            response = requests.get(
                f"{cls.BASE_URL}/course/{course_id}",
                timeout=settings.AICERTS_REQUEST_TIMEOUT
            )
            response.raise_for_status()

            data = response.json()
            if not data.get('success'):
                raise AICERTsAPIError(f"Course detail API returned success=false for ID {course_id}")

            course_data = data.get('data')
            if not course_data:
                raise AICERTsAPIError(f"Course {course_id} not found")

            # Cache the result
            cache.set(cache_key, course_data, cls.CACHE_TTL)

            logger.info(f"Fetched details for course {course_id}: {course_data.get('title')}")
            return course_data

        except requests.HTTPError as e:
            if e.response.status_code == 404:
                raise AICERTsAPIError(f"Course {course_id} not found")
            logger.error(f"HTTP error fetching course {course_id}: {e}")
            raise AICERTsAPIError(f"Course detail API failed: {e}")
        except requests.RequestException as e:
            logger.error(f"Failed to fetch course {course_id} from AICERTs: {e}")
            raise AICERTsAPIError(f"Course detail API failed: {e}")

    @classmethod
    def sync_all_courses(cls, callback=None) -> Tuple[int, int, List[str]]:
        """
        Sync all courses from AICERTs Course Data API.

        Args:
            callback: Optional function called for each course: callback(course_data)

        Returns:
            Tuple of (total_courses, new_courses, errors)
        """
        total_courses = 0
        new_courses = 0
        errors = []
        page = 1

        logger.info("Starting full course sync from AICERTs...")

        while True:
            try:
                result = cls.get_courses(page=page, per_page=100)
                courses = result.get('data', [])

                if not courses:
                    break

                for course in courses:
                    try:
                        # Fetch full details
                        course_id = course.get('id')
                        if not course_id:
                            continue

                        detail = cls.get_course_detail(course_id, use_cache=False)

                        # Call callback if provided
                        if callback:
                            is_new = callback(detail)
                            if is_new:
                                new_courses += 1

                        total_courses += 1

                    except Exception as e:
                        error_msg = f"Error syncing course {course.get('id')}: {e}"
                        logger.error(error_msg)
                        errors.append(error_msg)

                # Check if there are more pages
                if page >= result.get('total_pages', 1):
                    break

                page += 1

            except AICERTsAPIError as e:
                error_msg = f"Error fetching page {page}: {e}"
                logger.error(error_msg)
                errors.append(error_msg)
                break

        logger.info(f"Course sync complete: {total_courses} total, {new_courses} new, {len(errors)} errors")
        return total_courses, new_courses, errors


class SSOService:
    """
    Service for AICERTs SSO API interactions.
    Base URL: https://learn.aicerts.io/webservice/rest/server.php

    Handles:
    - User creation
    - Course enrollment
    - Authentication/auto-login
    """

    BASE_URL = settings.AICERTS_SSO_BASE_URL
    WSTOKEN = settings.AICERTS_WSTOKEN
    PARTNER_ID = settings.AICERTS_PARTNER_ID
    REST_FORMAT = settings.AICERTS_REST_FORMAT

    @classmethod
    def _build_base_params(cls, wsfunction: str) -> Dict:
        """Build base parameters for all SSO API calls"""
        return {
            'wstoken': cls.WSTOKEN,
            'wsfunction': wsfunction,
            'moodlewsrestformat': cls.REST_FORMAT
        }

    @classmethod
    def create_user(cls, email: str, first_name: str, last_name: str, username: str = None) -> Dict:
        """
        Create a new user in AICERTs LMS.

        Args:
            email: User email
            first_name: User's first name
            last_name: User's last name
            username: Username (defaults to email)

        Returns:
            Dict with 'status', 'message', 'id', 'username'

        Raises:
            AICERTsAuthenticationError: On authentication failure
            AICERTsAPIError: On other API errors
        """
        if username is None:
            username = email

        # Generate timestamp and signature
        timestamp, signature = HMACSignatureService.generate_timestamp_signature(email)

        params = cls._build_base_params('core_user_create_users')
        params.update({
            'users[0][firstname]': first_name,
            'users[0][lastname]': last_name,
            'users[0][email]': email,
            'users[0][username]': username,
            'users[0][partner_id]': cls.PARTNER_ID,
            'users[0][source]': 'sso',
            'timestamp': timestamp,
            'signature': signature
        })

        try:
            response = requests.post(
                cls.BASE_URL,
                params=params,
                timeout=settings.AICERTS_REQUEST_TIMEOUT
            )
            response.raise_for_status()

            result = response.json()

            # Response is a list with one item
            if isinstance(result, list) and len(result) > 0:
                user_data = result[0]

                if user_data.get('status') == 'success':
                    logger.info(f"Created AICERTs user: {email} (ID: {user_data.get('id')})")
                    return user_data
                else:
                    error_msg = user_data.get('message', 'Unknown error')
                    logger.error(f"Failed to create AICERTs user {email}: {error_msg}")

                    if 'authentication' in error_msg.lower():
                        raise AICERTsAuthenticationError(error_msg)
                    raise AICERTsAPIError(error_msg)

            raise AICERTsAPIError(f"Unexpected response format: {result}")

        except requests.RequestException as e:
            logger.error(f"HTTP error creating AICERTs user {email}: {e}")
            raise AICERTsAPIError(f"User creation API failed: {e}")

    @classmethod
    def enroll_user(cls, aicerts_user_id: int, course_id: int, role_id: int = None, email: str = None) -> Dict:
        """
        Enroll a user in an AICERTs course.

        Args:
            aicerts_user_id: AICERTs user ID (from create_user response)
            course_id: AICERTs course ID
            role_id: Role ID (defaults to student role)
            email: User email (for signature generation)

        Returns:
            Dict with 'status', 'message', 'isUserAlreadyEnrolled'

        Raises:
            AICERTsEnrollmentError: On enrollment failure
        """
        if role_id is None:
            role_id = settings.AICERTS_STUDENT_ROLE_ID

        # Generate timestamp and signature (use email or user_id)
        identifier = email if email else str(aicerts_user_id)
        timestamp, signature = HMACSignatureService.generate_timestamp_signature(identifier)

        params = cls._build_base_params('enrol_manual_enrol_users')
        params.update({
            'enrolments[0][roleid]': role_id,
            'enrolments[0][userid]': aicerts_user_id,
            'enrolments[0][courseid]': course_id,
            'enrolments[0][enrollmentsourcefrom]': 'hosi-academy',
            'enrolments[0][partner_id]': cls.PARTNER_ID,
            'timestamp': timestamp,
            'signature': signature
        })

        try:
            response = requests.post(
                cls.BASE_URL,
                params=params,
                timeout=settings.AICERTS_REQUEST_TIMEOUT
            )
            response.raise_for_status()

            result = response.json()

            if result.get('status') == 'success':
                already_enrolled = result.get('isUserAlreadyEnrolled') == '1'
                logger.info(f"Enrolled user {aicerts_user_id} in course {course_id} "
                           f"(already enrolled: {already_enrolled})")
                return result
            else:
                error_msg = result.get('message', 'Enrollment failed')
                logger.error(f"Failed to enroll user {aicerts_user_id} in course {course_id}: {error_msg}")
                raise AICERTsEnrollmentError(error_msg)

        except requests.RequestException as e:
            logger.error(f"HTTP error enrolling user {aicerts_user_id} in course {course_id}: {e}")
            raise AICERTsEnrollmentError(f"Enrollment API failed: {e}")

    @classmethod
    def generate_sso_url(cls, email: str, course_id: int = None) -> str:
        """
        Generate SSO URL for auto-login to AICERTs LMS.

        Args:
            email: User email
            course_id: Optional course ID to redirect to after login

        Returns:
            Full SSO URL for redirect
        """
        timestamp, signature = HMACSignatureService.generate_timestamp_signature(email)

        params = cls._build_base_params('local_myauthplugin_authenticate_user')
        params.update({
            'username': email,
            'partner_id': cls.PARTNER_ID,
            'timestamp': timestamp,
            'signature': signature
        })

        if course_id:
            params['courseid'] = course_id

        # Build URL with query parameters
        param_string = '&'.join(f"{k}={v}" for k, v in params.items())
        sso_url = f"{cls.BASE_URL}?{param_string}"

        logger.info(f"Generated SSO URL for {email} (course: {course_id})")
        return sso_url


class InstructorValidationService:
    """
    Service for validating AICERTs instructor designations.
    Ensures only registered AICERTs instructors can teach their designated courses.
    """

    @staticmethod
    def is_aicerts_instructor(user) -> bool:
        """
        Check if user is a registered AICERTs instructor.

        Args:
            user: User instance

        Returns:
            True if user is AICERTs instructor
        """
        return getattr(user, 'is_aicerts_instructor', False)

    @staticmethod
    def can_instruct_course(user, course) -> bool:
        """
        Check if user can instruct a specific AICERTs course.

        Args:
            user: User instance
            course: AICertsCourse instance

        Returns:
            True if user is authorized to instruct this course
        """
        if not InstructorValidationService.is_aicerts_instructor(user):
            return False

        # Check if user is designated for this course
        if hasattr(user, 'aicerts_instructor_courses'):
            return user.aicerts_instructor_courses.filter(id=course.id).exists()

        return False

    @staticmethod
    def get_instructor_courses(user):
        """
        Get all AICERTs courses the user can instruct.

        Args:
            user: User instance

        Returns:
            QuerySet of AICertsCourse instances
        """
        if not InstructorValidationService.is_aicerts_instructor(user):
            from apps.aicerts_courses.models import AiCertsCourse
            return AiCertsCourse.objects.none()

        if hasattr(user, 'aicerts_instructor_courses'):
            return user.aicerts_instructor_courses.all()

        from apps.aicerts_courses.models import AiCertsCourse
        return AiCertsCourse.objects.none()


class EnrollmentSyncService:
    """
    Service for synchronizing enrollments between Hosi Academy and AICERTs.
    Handles dual enrollment with transaction management.
    """

    @staticmethod
    @transaction.atomic
    def enroll_user_in_course(user, course, create_aicerts_user: bool = True):
        """
        Enroll user in both Hosi Academy and AICERTs course.

        Args:
            user: User instance
            course: AICertsCourse instance
            create_aicerts_user: Whether to create user on AICERTs if not exists

        Returns:
            Tuple of (local_enrollment, aicerts_result)

        Raises:
            AICERTsEnrollmentError: On enrollment failure
        """
        from apps.aicerts_integration.models import AICertsEnrollment

        # Check if user has AICERTs ID
        aicerts_user_id = getattr(user, 'aicerts_user_id', None)

        if not aicerts_user_id and create_aicerts_user:
            # Create user on AICERTs
            try:
                result = SSOService.create_user(
                    email=user.email,
                    first_name=user.first_name,
                    last_name=user.last_name
                )
                aicerts_user_id = result.get('id')

                # Update local user record
                user.aicerts_user_id = aicerts_user_id
                user.aicerts_synced_at = time.time()
                user.save(update_fields=['aicerts_user_id', 'aicerts_synced_at'])

            except AICERTsAPIError as e:
                logger.error(f"Failed to create AICERTs user for {user.email}: {e}")
                raise AICERTsEnrollmentError(f"Could not create AICERTs account: {e}")

        if not aicerts_user_id:
            raise AICERTsEnrollmentError("User does not have AICERTs account")

        # Enroll on AICERTs
        try:
            aicerts_result = SSOService.enroll_user(
                aicerts_user_id=aicerts_user_id,
                course_id=course.lms_course_id,  # Use lms_course_id (Moodle ID), not external_id (WordPress product ID)
                email=user.email
            )
        except AICERTsEnrollmentError as e:
            logger.error(f"Failed to enroll {user.email} in course {course.id} on AICERTs: {e}")
            raise

        # Create local enrollment record
        enrollment, created = AICertsEnrollment.objects.get_or_create(
            user=user,
            course=course,
            defaults={
                'aicerts_enrollment_status': 'enrolled',
                'aicerts_already_enrolled': aicerts_result.get('isUserAlreadyEnrolled') == '1'
            }
        )

        if not created:
            enrollment.aicerts_enrollment_status = 'enrolled'
            enrollment.aicerts_already_enrolled = aicerts_result.get('isUserAlreadyEnrolled') == '1'
            enrollment.save()

        logger.info(f"Successfully enrolled {user.email} in {course.title}")
        return enrollment, aicerts_result
