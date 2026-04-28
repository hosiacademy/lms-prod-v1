// lib/src/presentation/pages/instructor/start_session_page.dart
import 'package:flutter/material.dart';
import 'start_session_modal.dart';

/// Route wrapper that opens the StartSessionModal immediately.
/// Navigates back when the modal is dismissed.
class StartSessionPage extends StatefulWidget {
  const StartSessionPage({super.key});

  @override
  State<StartSessionPage> createState() => _StartSessionPageState();
}

class _StartSessionPageState extends State<StartSessionPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openModal());
  }

  Future<void> _openModal() async {
    if (!mounted) return;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const StartSessionModal(),
    );
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    // Transparent scaffold — modal appears on top immediately.
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: SizedBox.shrink(),
    );
  }
}
