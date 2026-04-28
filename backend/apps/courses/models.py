from django.db import models

class CourseProvider(models.Model):
    code = models.CharField(max_length=50, unique=True)
    name = models.CharField(max_length=255)
    active = models.BooleanField(default=True)

    class Meta:
        ordering = ("name",)

    def __str__(self):
        return self.name


class Course(models.Model):
    provider = models.ForeignKey(
        CourseProvider,
        on_delete=models.CASCADE,
        related_name="courses"
    )
    external_id = models.CharField(
        max_length=255,
        blank=True,
        null=True
    )
    title = models.CharField(max_length=255)
    summary = models.TextField(blank=True)
    active = models.BooleanField(default=True)

    class Meta:
        unique_together = ("provider", "external_id")
        ordering = ("title",)

    def __str__(self):
        return f"{self.title} ({self.provider.code})"
