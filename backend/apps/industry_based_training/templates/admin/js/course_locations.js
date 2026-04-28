// static/admin/js/simple_locations.js
(function($) {
    $(document).ready(function() {
        var countrySelect = $('#id_country');
        var citySelect = $('#id_city');
        
        // Predefined cities for common countries
        var citiesByCountry = {
            'ZA': ['Johannesburg', 'Cape Town', 'Durban', 'Pretoria', 'Port Elizabeth', 'Bloemfontein', 'Online'],
            'US': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia', 'Online'],
            'GB': ['London', 'Manchester', 'Birmingham', 'Liverpool', 'Glasgow', 'Edinburgh', 'Online'],
            'CA': ['Toronto', 'Vancouver', 'Montreal', 'Calgary', 'Ottawa', 'Edmonton', 'Online'],
            'AU': ['Sydney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaide', 'Canberra', 'Online'],
            'KE': ['Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret', 'Online'],
            'NG': ['Lagos', 'Abuja', 'Port Harcourt', 'Kano', 'Ibadan', 'Online'],
        };
        
        if (countrySelect.length && citySelect.length) {
            // Initialize
            citySelect.empty().append('<option value="">Select country first</option>');
            
            // Country change handler
            countrySelect.change(function() {
                var countryCode = $(this).val();
                citySelect.empty().append('<option value="">Select City</option>');
                
                if (countryCode && citiesByCountry[countryCode]) {
                    citiesByCountry[countryCode].forEach(function(city) {
                        citySelect.append('<option value="' + city + '">' + city + '</option>');
                    });
                }
            });
            
            // Trigger change if country already selected
            if (countrySelect.val()) {
                countrySelect.trigger('change');
            }
        }
    });
})(django.jQuery);