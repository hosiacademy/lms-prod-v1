/**
 * Automatic Phase Date Calculator for Learnership Programmes
 * 
 * Functionality:
 * - Only Phase 1 start_date is manually editable
 * - Phase 1 end_date is auto-calculated from start_date + duration_weeks
 * - Phases 2-4 start_dates are auto-calculated (previous phase end_date + 1 day)
 * - Phases 2-4 end_dates are auto-calculated from start_date + duration_weeks
 * - All calculations trigger on any date/duration change
 */

(function ($) {
    'use strict';

    $(document).ready(function () {
        console.log('[Phase Auto Dates] Initializing...');

        // Wait for Django admin to fully load the inline formsets
        setTimeout(initializePhaseDateCalculator, 500);
    });

    function initializePhaseDateCalculator() {
        const formsetPrefix = 'phases';
        const phaseRows = $('.dynamic-' + formsetPrefix);

        if (phaseRows.length === 0) {
            console.log('[Phase Auto Dates] No phase rows found. Retrying...');
            setTimeout(initializePhaseDateCalculator, 1000);
            return;
        }

        console.log(`[Phase Auto Dates] Found ${phaseRows.length} phase rows`);

        // Attach event listeners
        attachEventListeners();

        // Initial calculation
        calculateAllPhaseDates();
    }

    function attachEventListeners() {
        // Listen to Phase 1 start_date changes
        $(document).on('change', '#id_phases-0-start_date', function () {
            console.log('[Phase Auto Dates] Phase 1 start_date changed');
            calculateAllPhaseDates();
        });

        // Listen to all duration_weeks changes
        $(document).on('change', '[id^="id_phases-"][id$="-duration_weeks"]', function () {
            const phaseIndex = extractPhaseIndex($(this).attr('id'));
            console.log(`[Phase Auto Dates] Phase ${phaseIndex + 1} duration changed`);
            calculateAllPhaseDates();
        });

        // Listen to manual start_date changes (for validation)
        $(document).on('change', '[id^="id_phases-"][id$="-start_date"]', function () {
            const phaseIndex = extractPhaseIndex($(this).attr('id'));
            if (phaseIndex > 0) {
                console.warn(`[Phase Auto Dates] Phase ${phaseIndex + 1} start_date should be auto-calculated`);
                // Recalculate to override manual changes
                calculateAllPhaseDates();
            }
        });
    }

    function calculateAllPhaseDates() {
        let previousEndDate = null;

        // Process each phase in order
        for (let i = 0; i < 10; i++) {  // Support up to 10 phases
            const phaseExists = $(`#id_phases-${i}-id`).length > 0 ||
                $(`#id_phases-${i}-start_date`).length > 0;

            if (!phaseExists) break;

            const startDateInput = $(`#id_phases-${i}-start_date`);
            const endDateInput = $(`#id_phases-${i}-end_date`);
            const durationInput = $(`#id_phases-${i}-duration_weeks`);

            if (i === 0) {
                // Phase 1: Calculate end_date from start_date + duration
                calculatePhase1EndDate(startDateInput, endDateInput, durationInput);
                previousEndDate = parseDateInput(endDateInput.val());
            } else {
                // Phases 2+: Auto-populate from previous phase
                if (previousEndDate) {
                    calculateSubsequentPhase(
                        i,
                        startDateInput,
                        endDateInput,
                        durationInput,
                        previousEndDate
                    );
                    previousEndDate = parseDateInput(endDateInput.val());
                }
            }
        }
    }

    function calculatePhase1EndDate(startDateInput, endDateInput, durationInput) {
        const startDateStr = startDateInput.val();
        const duration = parseInt(durationInput.val()) || 0;

        if (!startDateStr || duration === 0) {
            endDateInput.val('');
            return;
        }

        const startDate = parseDateInput(startDateStr);
        if (!startDate) {
            console.error('[Phase Auto Dates] Invalid Phase 1 start date');
            return;
        }

        // Calculate end date: start_date + (duration_weeks * 7 days) - 1 day
        const endDate = new Date(startDate);
        endDate.setDate(endDate.getDate() + (duration * 7) - 1);

        endDateInput.val(formatDate(endDate));
        endDateInput.prop('readonly', true);
        endDateInput.css('background-color', '#f0f0f0');

        console.log(`[Phase Auto Dates] Phase 1: ${formatDate(startDate)} to ${formatDate(endDate)} (${duration} weeks)`);
    }

    function calculateSubsequentPhase(phaseIndex, startDateInput, endDateInput, durationInput, previousEndDate) {
        const duration = parseInt(durationInput.val()) || 0;

        if (!previousEndDate || duration === 0) {
            startDateInput.val('');
            endDateInput.val('');
            return;
        }

        // Start date = previous end date + 1 day
        const startDate = new Date(previousEndDate);
        startDate.setDate(startDate.getDate() + 1);

        // End date = start date + (duration * 7 days) - 1 day
        const endDate = new Date(startDate);
        endDate.setDate(endDate.getDate() + (duration * 7) - 1);

        startDateInput.val(formatDate(startDate));
        startDateInput.prop('readonly', true);
        startDateInput.css('background-color', '#f0f0f0');

        endDateInput.val(formatDate(endDate));
        endDateInput.prop('readonly', true);
        endDateInput.css('background-color', '#f0f0f0');

        console.log(`[Phase Auto Dates] Phase ${phaseIndex + 1}: ${formatDate(startDate)} to ${formatDate(endDate)} (${duration} weeks)`);
    }

    function extractPhaseIndex(inputId) {
        // Extract index from id like "id_phases-2-start_date"
        const match = inputId.match(/id_phases-(\d+)-/);
        return match ? parseInt(match[1]) : 0;
    }

    function parseDateInput(dateStr) {
        if (!dateStr) return null;

        // Handle both YYYY-MM-DD and DD/MM/YYYY formats
        const parts = dateStr.includes('-') ? dateStr.split('-') : dateStr.split('/').reverse();

        if (parts.length !== 3) return null;

        const year = parseInt(parts[0]);
        const month = parseInt(parts[1]) - 1;  // JS months are 0-indexed
        const day = parseInt(parts[2]);

        const date = new Date(year, month, day);

        // Validate date
        if (isNaN(date.getTime())) return null;

        return date;
    }

    function formatDate(date) {
        if (!date || isNaN(date.getTime())) return '';

        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');

        return `${year}-${month}-${day}`;
    }

})(django.jQuery);
