// static/admin/js/learnerships_admin.js
(function($) {
    $(document).ready(function() {
        // Chaining: Countries → Cities
        $('body').on('change', 'select[id$="-countries"]', function() {
            var countriesSelect = $(this);
            var citiesSelect = countriesSelect.closest('.form-row').find('select[id$="-cities"]');

            var selectedCountries = countriesSelect.val() || [];  // Array of country IDs

            citiesSelect.prop('disabled', true);

            if (selectedCountries.length > 0) {
                $.ajax({
                    url: '/admin/learnerships/city/autocomplete/',
                    data: { countries: selectedCountries.join(',') },
                    success: function(data) {
                        citiesSelect.html('<option value="">---------</option>');
                        $.each(data.results, function(index, item) {
                            citiesSelect.append($('<option>', {
                                value: item.id,
                                text: item.text  // Only city name
                            }));
                        });
                        citiesSelect.prop('disabled', false);
                        citiesSelect.trigger('change');
                    },
                    error: function() {
                        citiesSelect.html('<option value="">Error loading cities</option>');
                        citiesSelect.prop('disabled', false);
                    }
                });
            } else {
                citiesSelect.html('<option value="">---------</option>');
                citiesSelect.prop('disabled', false);
            }
        });
    });
})(django.jQuery);