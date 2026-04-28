// templates/admin/js/course_locations.js
$(document).ready(function() {
    // Only run if country/city fields exist (AiCertsCourse form)
    if ($('#id_country').length && $('#id_city').length) {
        var countrySelect = $('#id_country');
        var citySelect = $('#id_city');

        // GeoNames free API username (register at https://www.geonames.org/login - free)
        var geoUsername = 'YOUR_GEONAMES_USERNAME_HERE';  // ← Replace this!

        // When country changes → fetch cities
        countrySelect.change(function() {
            var countryCode = $(this).val();
            if (!countryCode) {
                citySelect.empty().append('<option value="">Select country first</option>');
                return;
            }

            // Clear current cities
            citySelect.empty().append('<option value="">Loading cities...</option>');

            // GeoNames API call
            $.ajax({
                url: `http://api.geonames.org/searchJSON`,
                data: {
                    country: countryCode,
                    featureClass: 'P',  // P = populated places (cities/towns)
                    maxRows: 100,
                    username: geoUsername,
                    style: 'full'
                },
                dataType: 'json',
                success: function(data) {
                    citySelect.empty().append('<option value="">Select City/Town</option>');
                    if (data.geonames && data.geonames.length) {
                        data.geonames.forEach(function(place) {
                            var label = place.name;
                            if (place.adminName1) label += `, ${place.adminName1}`;
                            citySelect.append(`<option value="${place.name}">${label}</option>`);
                        });
                    } else {
                        citySelect.append('<option value="">No cities found</option>');
                    }
                },
                error: function(xhr, status, error) {
                    alert('Error loading cities. Check GeoNames username or internet.');
                    citySelect.empty().append('<option value="">Error loading cities</option>');
                }
            });
        });
    }
});