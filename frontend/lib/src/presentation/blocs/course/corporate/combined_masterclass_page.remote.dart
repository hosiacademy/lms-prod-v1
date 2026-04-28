// lib/src/presentation/blocs/course/corporate/combined_masterclass_page.dart
import 'package:flutter/material.dart';
import 'components/masterclass_calendar.dart';
import 'components/masterclass_filters.dart';
import 'components/masterclass_marquee.dart';
import 'providers/masterclass_data_provider.dart';
import 'providers/masterclass_enrollment.dart';
import 'package:frontend/src/data/models/masterclass.dart';
import '../../../widgets/headers/enrollment_page_header.dart';
import '../../../widgets/ai/native_ai_assistant.dart';
import '../../../pages/onboarding/widgets/modals/ai_masterclass_schedule_modal.dart';

class CombinedMasterclassPage extends StatefulWidget {
  final String? initialType;
  final bool embedMode;

  const CombinedMasterclassPage({
    super.key,
    this.initialType,
    this.embedMode = false,
  });

  @override
  State<CombinedMasterclassPage> createState() =>
      _CombinedMasterclassPageState();
}

class _CombinedMasterclassPageState extends State<CombinedMasterclassPage> {
  late final MasterclassDataProvider _dataProvider;
  final GlobalKey<MasterclassCalendarState> _calendarKey =
      GlobalKey<MasterclassCalendarState>();

  @override
  void initState() {
    super.initState();
    _dataProvider = MasterclassDataProvider(initialType: widget.initialType);
    _dataProvider.loadMasterclasses();
  }

  @override
  void dispose() {
    _dataProvider.dispose();
    super.dispose();
  }

  void _resetCalendarFilters() {
    _calendarKey.currentState?.resetQuarterAndMonthFilters();
  }

  void _handleMasterclassTap(Masterclass masterclass) {
    // Check if this is the AI+ Finance™ masterclass
    final isAiFinance = masterclass.title.toLowerCase().contains('ai+ finance') ||
        masterclass.title.toLowerCase().contains('ai finance');
    
    if (isAiFinance) {
      // Show the schedule & curriculum modal
      AiMasterclassScheduleModal.show(context);
    } else {
      // Set assistant prompt for other masterclasses
      NativeAIAssistant.setPrompt(
          context,
          "I am interested in the '${masterclass.title}' masterclass. "
          "Could you please provide detailed information about: "
          "\n1. The full curriculum and learning modules?"
          "\n2. What are the key benefits and career outcomes?"
          "\n3. Is there a certification upon completion, and who is the awarding body?"
          "\n4. What are the prerequisites for this masterclass?");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedMode) {
      return _buildMainContent(context);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _buildMainContent(context),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return ValueListenableBuilder<MasterclassState>(
      valueListenable: _dataProvider.stateNotifier,
      builder: (context, state, child) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null) {
          return Center(child: Text('Error: ${state.error}'));
        }

        return Column(
          children: [
            // Header
            if (!widget.embedMode)
              const EnrollmentPageHeader(
                title: 'Masterclasses',
                subtitle: 'Scale your expertise with AI-driven learning',
              ),

            // Marquee
            MasterclassMarquee(
              running: state.running,
              upcoming: state.upcoming,
              onMarqueeItemTap: _handleMasterclassTap,
            ),

            // Filters
            MasterclassFilters(
              selectedType: state.selectedType,
              selectedCountry: state.selectedCountry,
              selectedCity: state.selectedCity,
              selectedVenue: state.selectedVenue,
              countries: state.countries,
              cities: state.cities,
              venues: state.venues,
              onTypeChanged: _dataProvider.setType,
              onCountryChanged: _dataProvider.setCountry,
              onCityChanged: _dataProvider.setCity,
              onVenueChanged: _dataProvider.setVenue,
              onResetAllFilters: () {
                _dataProvider.resetFilters();
                _resetCalendarFilters();
              },
            ),

            // Calendar View
            Expanded(
              child: MasterclassCalendar(
                key: _calendarKey,
                events: state.events,
                dataProvider: _dataProvider,
                onMasterclassTap: _handleMasterclassTap,
                onEnrollTap: (masterclass) =>
                    MasterclassEnrollment.startEnrollment(
                  context: context,
                  masterclass: masterclass,
                  onPaymentComplete: () {
                    _dataProvider.loadMasterclasses();
                  },
                ),
                selectedType: state.selectedType,
              ),
            ),
          ],
        );
      },
    );
  }
}
