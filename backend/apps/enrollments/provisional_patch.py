import re

with open("backend/apps/enrollments/models.py", "r") as f:
    content = f.read()

patch = """
    def get_enrolled_item(self):
        \"\"\"Mock get_enrolled_item for ChatEnforcerService compat\"\"\"
        if self.enrollment_type == 'learnership':
            return self.programme
        elif self.enrollment_type == 'masterclass':
            m_id = self.metadata.get('training_id') or self.programme_id
            if m_id:
                from apps.masterclasses.models import Masterclass
                try:
                    return Masterclass.objects.get(id=m_id)
                except Exception:
                    pass
        elif self.enrollment_type == 'industry':
            i_id = self.metadata.get('training_id') or self.programme_id
            if i_id:
                from apps.industry_based_training.models import IndustryBasedTraining
                try:
                    return IndustryBasedTraining.objects.get(id=i_id)
                except Exception:
                    pass
        return None
"""

if "def get_enrolled_item" not in content:
    idx = content.find("    def save(self, *args, **kwargs):")
    if idx != -1:
        new_content = content[:idx] + patch + "\n" + content[idx:]
        with open("backend/apps/enrollments/models.py", "w") as f:
            f.write(new_content)
        print("Patched ProvisionalEnrollment")

