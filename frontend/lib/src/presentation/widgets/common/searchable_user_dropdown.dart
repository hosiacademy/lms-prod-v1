// lib/src/presentation/widgets/common/searchable_user_dropdown.dart
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';

class SearchableUserDropdown extends StatefulWidget {
  final String label;
  final String? initialValue;
  final Function(Map<String, dynamic> user) onSelected;
  final bool isRequired;

  const SearchableUserDropdown({
    super.key,
    required this.label,
    required this.onSelected,
    this.initialValue,
    this.isRequired = false,
  });

  @override
  State<SearchableUserDropdown> createState() => _SearchableUserDropdownState();
}

class _SearchableUserDropdownState extends State<SearchableUserDropdown> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _searchUsers(String query) async {
    if (query.length < 2) return [];
    
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get(
        '/api/v1/payments/admin/bulk-sms/users/',
        queryParameters: {'search': query},
      );
      
      final List<dynamic> users = response.data['users'] ?? [];
      setState(() => _isLoading = false);
      return users.cast<Map<String, dynamic>>();
    } catch (e) {
      setState(() => _isLoading = false);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return RawAutocomplete<Map<String, dynamic>>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Map<String, dynamic>>.empty();
        }
        return _searchUsers(textEditingValue.text);
      },
      displayStringForOption: (Map<String, dynamic> option) => option['name'] ?? '',
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'Type to search students...',
            prefixIcon: const Icon(Icons.person_search_outlined),
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.arrow_drop_down),
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: colors.surfaceContainerLowest,
          ),
          validator: widget.isRequired
              ? (value) => value == null || value.isEmpty ? 'This field is required' : null
              : null,
          onFieldSubmitted: (value) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300, maxWidth: 440),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  final phone = option['phone'] ?? 'No phone';
                  final email = option['email'] ?? 'No email';
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colors.primaryContainer,
                      child: Text(
                        (option['name'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(color: colors.primary, fontSize: 12),
                      ),
                    ),
                    title: Text(option['name'] ?? 'Unknown User',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$email • $phone',
                        style: theme.textTheme.bodySmall),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: (Map<String, dynamic> selection) {
        widget.onSelected(selection);
      },
    );
  }
}
