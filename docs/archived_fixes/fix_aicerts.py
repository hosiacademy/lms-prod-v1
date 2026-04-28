import re
import os

def process_aicerts_form_data():
    path = 'frontend/lib/src/presentation/widgets/modals/aicerts/shared/aicerts_form_data.dart'
    if not os.path.exists(path): return
    with open(path, 'r') as f:
        content = f.read()

    # AICertsLearnerFormData
    content = content.replace(
        "final fullNameController = TextEditingController();",
        "final firstNameController = TextEditingController();\n  final lastNameController = TextEditingController();"
    )
    content = content.replace(
        "fullNameController.dispose();",
        "firstNameController.dispose();\n    lastNameController.dispose();"
    )
    content = content.replace(
        "fullNameController.text.trim().isEmpty",
        "firstNameController.text.trim().isEmpty || lastNameController.text.trim().isEmpty"
    )
    content = content.replace(
        "'full_name': fullNameController.text.trim(),",
        "'first_name': firstNameController.text.trim(),\n      'last_name': lastNameController.text.trim(),\n      'full_name': '${firstNameController.text.trim()} ${lastNameController.text.trim()}',"
    )
    # CorporateLearnerData
    content = content.replace(
        "fullNameController.text.trim().isNotEmpty &&",
        "firstNameController.text.trim().isNotEmpty && lastNameController.text.trim().isNotEmpty &&"
    )

    with open(path, 'w') as f:
        f.write(content)
    print("Updated aicerts_form_data.dart")

def process_custom_selection_modal():
    path = 'frontend/lib/src/presentation/widgets/modals/aicerts/multi_step_aicerts_custom_selection_modal.dart'
    if not os.path.exists(path): return
    with open(path, 'r') as f:
        content = f.read()

    content = content.replace(
        "if (learner.fullNameController.text.trim().isEmpty) {",
        "if (learner.firstNameController.text.trim().isEmpty || learner.lastNameController.text.trim().isEmpty) {"
    )
    content = content.replace(
        "_showError('Full Name is required');",
        "_showError('First and Last Name are required');"
    )
    
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
    print("Updated multi_step_aicerts_custom_selection_modal.dart")

def process_industry_training_modal():
    path = 'frontend/lib/src/presentation/widgets/modals/aicerts/multi_step_aicerts_industry_training_modal.dart'
    if not os.path.exists(path): return
    with open(path, 'r') as f:
        content = f.read()

    content = content.replace(
        "if (learner.fullNameController.text.trim().isEmpty) {",
        "if (learner.firstNameController.text.trim().isEmpty || learner.lastNameController.text.trim().isEmpty) {"
    )
    content = content.replace(
        "_showError('Full Name is required');",
        "_showError('First and Last Name are required');"
    )
    
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
    print("Updated multi_step_aicerts_industry_training_modal.dart")

process_aicerts_form_data()
process_custom_selection_modal()
process_industry_training_modal()
