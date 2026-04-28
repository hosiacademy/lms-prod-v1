def get_training_start_date(enrollment):
    from apps.masterclasses.models import Masterclass
    from apps.learnerships.models import LearnershipProgramme
    from apps.industry_based_training.models import IndustryBasedTraining

    if enrollment.enrollment_type == 'learnership' and enrollment.programme:
        return enrollment.programme.start_date
    elif enrollment.enrollment_type == 'masterclass':
        masterclass_id = enrollment.metadata.get('masterclass_id') or enrollment.programme_id
        if masterclass_id:
            try:
                return Masterclass.objects.get(id=masterclass_id).start_date
            except Masterclass.DoesNotExist:
                pass
    elif enrollment.enrollment_type == 'industry':
        industry_id = enrollment.metadata.get('industry_id') or enrollment.programme_id
        if industry_id:
            try:
                return IndustryBasedTraining.objects.get(id=industry_id).start_date
            except IndustryBasedTraining.DoesNotExist:
                pass
    
    return None
