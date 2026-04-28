import re
import os

def process_regular_modal():
    path = 'frontend/lib/src/presentation/widgets/modals/multi_step_enrollment_modal.dart'
    if not os.path.exists(path): return
    with open(path, 'r') as f:
        content = f.read()

    # 1. LearnerFormData declaration
    content = content.replace(
        "final fullNameController = TextEditingController();",
        "final firstNameController = TextEditingController();\n  final lastNameController = TextEditingController();"
    )

    # 2. dispose
    content = content.replace(
        "fullNameController.dispose();",
        "firstNameController.dispose();\n    lastNameController.dispose();"
    )

    # 3. validate
    content = content.replace(
        "if (fullNameController.text.trim().isEmpty) return false;",
        "if (firstNameController.text.trim().isEmpty || lastNameController.text.trim().isEmpty) return false;"
    )

    # 4. _collectAllFormData
    content = content.replace(
        "'full_name': learner.fullNameController.text.trim(),",
        "'first_name': learner.firstNameController.text.trim(),\n        'last_name': learner.lastNameController.text.trim(),\n        'full_name': '${learner.firstNameController.text.trim()} ${learner.lastNameController.text.trim()}',"
    )

    # 5. _preparePaymentPayload individual_details
    content = content.replace(
        "'full_name': firstLearner.fullNameController.text.trim(),",
        "'first_name': firstLearner.firstNameController.text.trim(),\n            'last_name': firstLearner.lastNameController.text.trim(),\n            'full_name': '${firstLearner.firstNameController.text.trim()} ${firstLearner.lastNameController.text.trim()}',"
    )

    # 6. switch case 2 (validation)
    content = content.replace(
        "if (learner.fullNameController.text.trim().isEmpty) {",
        "if (learner.firstNameController.text.trim().isEmpty || learner.lastNameController.text.trim().isEmpty) {"
    )
    content = content.replace(
        "_showError('Full Name is required');",
        "_showError('First and Last Name are required');"
    )

    # 7. Summary text
    content = content.replace(
        "${learner.fullNameController.text}",
        "${learner.firstNameController.text} ${learner.lastNameController.text}"
    )

    # 8. UI field replacement
    old_ui = """                TextFormField(
                  controller: learner.fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    border: OutlineInputBorder(),
                    hintText: 'Enter your full name',
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Required';
                    return null;
                  },
                ),"""
    new_ui = """                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: learner.firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name *',
                          border: OutlineInputBorder(),
                          hintText: 'First name',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: learner.lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name *',
                          border: OutlineInputBorder(),
                          hintText: 'Last name',
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),"""
    content = content.replace(old_ui, new_ui)

    with open(path, 'w') as f:
        f.write(content)
    print("Updated regular enrollment modal.")

def process_learnership_modal():
    path = 'frontend/lib/src/presentation/widgets/modals/multi_step_learnership_enrollment_modal.dart'
    if not os.path.exists(path): return
    with open(path, 'r') as f:
        content = f.read()

    # CorporateLearnerData needs firstName and lastName
    content = content.replace(
        "class CorporateLearnerData {\n  final fullNameController = TextEditingController();",
        "class CorporateLearnerData {\n  final firstNameController = TextEditingController();\n  final lastNameController = TextEditingController();"
    )
    content = content.replace(
        "fullNameController.dispose();\n    emailController.dispose();",
        "firstNameController.dispose();\n    lastNameController.dispose();\n    emailController.dispose();"
    )

    # Remove fullNameController from LearnerFormData (it already has firstNameController and lastNameController)
    content = re.sub(r'final fullNameController = TextEditingController\(\);\n\s*', '', content)
    # Wait, the replace for CorporateLearnerData removed its fullNameController. The remaining one is in LearnerFormData, which we want to remove.
    # But let's be safe. LearnerFormData dispose has fullNameController.dispose()
    content = re.sub(r'fullNameController\.dispose\(\);\n\s*', '', content)

    # validate
    content = content.replace(
        "if (fullNameController.text.isEmpty ||",
        "if (firstNameController.text.isEmpty || lastNameController.text.isEmpty ||"
    )

    # validate corporate
    content = content.replace(
        "if (learner.fullNameController.text.trim().isEmpty ||",
        "if (learner.firstNameController.text.trim().isEmpty || learner.lastNameController.text.trim().isEmpty ||"
    )

    # learnersData mapping corporate
    content = content.replace(
        "'full_name': learner.fullNameController.text.trim(),",
        "'first_name': learner.firstNameController.text.trim(),\n          'last_name': learner.lastNameController.text.trim(),\n          'full_name': '${learner.firstNameController.text.trim()} ${learner.lastNameController.text.trim()}',"
    )

    # _individualLearnerData mapping
    content = content.replace(
        "'learner_full_name': _individualLearnerData.fullNameController.text.trim(),",
        "'learner_first_name': _individualLearnerData.firstNameController.text.trim(),\n        'learner_last_name': _individualLearnerData.lastNameController.text.trim(),\n        'learner_full_name': '${_individualLearnerData.firstNameController.text.trim()} ${_individualLearnerData.lastNameController.text.trim()}',"
    )

    # Summary texts
    content = content.replace(
        "_individualLearnerData.fullNameController.text",
        "'${_individualLearnerData.firstNameController.text} ${_individualLearnerData.lastNameController.text}'"
    )

    content = content.replace(
        "learner.fullNameController.text",
        "'${learner.firstNameController.text} ${learner.lastNameController.text}'"
    )

    # Replace UI for Corporate learner
    old_corp_ui = """        _buildTextField(
          controller: learnerData.fullNameController,
          label: 'Full Name *',
          icon: Icons.person_outline,
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        ),"""
    new_corp_ui = """        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: learnerData.firstNameController,
                label: 'First Name *',
                icon: Icons.person_outline,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                controller: learnerData.lastNameController,
                label: 'Last Name *',
                icon: null,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
            ),
          ],
        ),"""
    content = content.replace(old_corp_ui, new_corp_ui)

    # Replace UI for Individual learner
    old_ind_ui = """            TextField(
              controller: learner.fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),"""
    new_ind_ui = """            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: learner.firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: learner.lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),"""
    content = content.replace(old_ind_ui, new_ind_ui)

    with open(path, 'w') as f:
        f.write(content)
    print("Updated learnership enrollment modal.")

process_regular_modal()
process_learnership_modal()
