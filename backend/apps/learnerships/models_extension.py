from django.db import models
from apps.courses.models import Course
from .models import LearnershipPhase

class LearnershipPhaseCourse(models.Model):
    phase = models.ForeignKey(
        LearnershipPhase,
        on_delete=models.CASCADE,
        related_name='phase_courses'
    )
    course = models.ForeignKey(
        Course,
        on_delete=models.PROTECT,
        related_name='learnership_phases'
    )
    order = models.PositiveIntegerField(default=1)

    class Meta:
        ordering = ('order',)
        unique_together = ('phase', 'course')

    def __str__(self):
        return f"{self.phase.name} ? {self.course.title}"
