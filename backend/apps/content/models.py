from django.db import models


class Page(models.Model):
    title = models.CharField(max_length=191)
    slug = models.CharField(max_length=191)
    description = models.TextField(blank=True, null=True)
    heading = models.TextField(blank=True, null=True)
    breadcumb_image = models.CharField(max_length=191, blank=True, null=True)
    status = models.IntegerField(default=1)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'pages'


class AboutPage(models.Model):
    who_we_are = models.CharField(max_length=191, blank=True, null=True)
    banner_title = models.CharField(max_length=191, blank=True, null=True)
    story_title = models.CharField(max_length=191, blank=True, null=True)
    story_description = models.TextField(blank=True, null=True)
    teacher_title = models.CharField(max_length=191, blank=True, null=True)
    teacher_details = models.TextField(blank=True, null=True)
    course_title = models.CharField(max_length=191, blank=True, null=True)
    course_details = models.TextField(blank=True, null=True)
    student_title = models.CharField(max_length=191, blank=True, null=True)
    student_details = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    image1 = models.CharField(max_length=191, default='public/frontend/infixlmstheme/img/about/1.jpg')
    image2 = models.CharField(max_length=191, default='public/frontend/infixlmstheme/img/about/2.jpg')
    image3 = models.CharField(max_length=191, default='public/frontend/infixlmstheme/img/about/3.jpg')
    image4 = models.CharField(max_length=191, default='public/frontend/infixlmstheme/img/about/counter_bg.png')

    class Meta:
        db_table = 'about_pages'


class PrivacyPolicy(models.Model):
    description = models.TextField(blank=True, null=True)
    general = models.TextField(blank=True, null=True)
    personal_data = models.TextField(blank=True, null=True)
    voluntary_disclosure = models.TextField(blank=True, null=True)
    children_privacy = models.TextField(blank=True, null=True)
    information_about_cookies = models.TextField(blank=True, null=True)
    thirt_party_adv = models.TextField(blank=True, null=True)
    other_sites = models.TextField(blank=True, null=True)
    teacher = models.TextField(blank=True, null=True)
    student = models.TextField(blank=True, null=True)
    business_transfer = models.TextField(blank=True, null=True)
    status = models.SmallIntegerField(default=1)
    created_by = models.IntegerField(blank=True, null=True)
    updated_by = models.IntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'privacy_policies'


class Testimonial(models.Model):
    body = models.TextField(blank=True, null=True)
    author = models.CharField(max_length=191, blank=True, null=True)
    profession = models.CharField(max_length=191, blank=True, null=True)
    image = models.CharField(max_length=191, blank=True, null=True)
    star = models.IntegerField(default=5)
    status = models.IntegerField(default=1)
    created_by = models.IntegerField(blank=True, null=True)
    updated_by = models.IntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'testimonials'


class Sponsor(models.Model):
    title = models.CharField(max_length=191)
    image = models.CharField(max_length=191)
    status = models.BooleanField(default=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'sponsors'


class FrontPage(models.Model):
    name = models.TextField(blank=True, null=True)
    title = models.TextField(blank=True, null=True)
    sub_title = models.TextField(blank=True, null=True)
    details = models.TextField(blank=True, null=True)
    slug = models.CharField(max_length=191)
    status = models.SmallIntegerField(default=1)
    is_static = models.SmallIntegerField(default=1)
    banner = models.CharField(max_length=191, blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'front_pages'