$(document).ready(function() {
    // Add button to add new country + cities
    $('<button type="button" class="add-location btn btn-sm btn-primary">Add Country & Cities</button>')
        .insertAfter('#id_locations');

    $('.add-location').click(function() {
        var row = $('<div class="location-row mt-3 border p-3 rounded"></div>');

        // Country dropdown (African only)
        var countrySelect = $('<select class="form-control country-select mb-2"><option value="">Select African Country</option></select>');
        $.each([
            ['DZ', 'Algeria'], ['AO', 'Angola'], ['BJ', 'Benin'], ['BW', 'Botswana'], ['BF', 'Burkina Faso'],
            ['BI', 'Burundi'], ['CV', 'Cape Verde'], ['CM', 'Cameroon'], ['CF', 'Central African Republic'],
            ['TD', 'Chad'], ['KM', 'Comoros'], ['CG', 'Congo'], ['CD', 'DR Congo'], ['CI', "Côte d'Ivoire"],
            ['DJ', 'Djibouti'], ['EG', 'Egypt'], ['GQ', 'Equatorial Guinea'], ['ER', 'Eritrea'], ['SZ', 'Eswatini'],
            ['ET', 'Ethiopia'], ['GA', 'Gabon'], ['GM', 'Gambia'], ['GH', 'Ghana'], ['GN', 'Guinea'],
            ['GW', 'Guinea-Bissau'], ['KE', 'Kenya'], ['LS', 'Lesotho'], ['LR', 'Liberia'], ['LY', 'Libya'],
            ['MG', 'Madagascar'], ['MW', 'Malawi'], ['ML', 'Mali'], ['MR', 'Mauritania'], ['MU', 'Mauritius'],
            ['MA', 'Morocco'], ['MZ', 'Mozambique'], ['NA', 'Namibia'], ['NE', 'Niger'], ['NG', 'Nigeria'],
            ['RW', 'Rwanda'], ['ST', 'São Tomé and Príncipe'], ['SN', 'Senegal'], ['SC', 'Seychelles'],
            ['SL', 'Sierra Leone'], ['SO', 'Somalia'], ['ZA', 'South Africa'], ['SS', 'South Sudan'],
            ['SD', 'Sudan'], ['TZ', 'Tanzania'], ['TG', 'Togo'], ['TN', 'Tunisia'], ['UG', 'Uganda'],
            ['ZM', 'Zambia'], ['ZW', 'Zimbabwe']
        ], function(index, item) {
            countrySelect.append($('<option></option>').val(item[0]).text(item[1]));
        });

        var citiesSelect = $('<select multiple class="form-control city-select mb-2" size="5"><option disabled>Select cities after country</option></select>');

        // Fetch cities when country changes
        countrySelect.change(function() {
            var countryName = $(this).find('option:selected').text();
            if (!countryName) return;

            $.ajax({
                url: 'https://countriesnow.space/api/v0.1/countries/cities',
                type: 'POST',
                contentType: 'application/json',
                data: JSON.stringify({ country: countryName }),
                success: function(response) {
                    citiesSelect.empty();
                    if (response.data && response.data.length) {
                        response.data.forEach(function(city) {
                            citiesSelect.append($('<option></option>').val(city).text(city));
                        });
                    } else {
                        citiesSelect.append('<option disabled>No cities found</option>');
                    }
                },
                error: function() {
                    alert('Error fetching cities. Try again.');
                }
            });
        });

        // Save button
        var saveBtn = $('<button type="button" class="btn btn-sm btn-success save-location">Save Location</button>');
        saveBtn.click(function() {
            var countryCode = countrySelect.val();
            var countryName = countrySelect.find('option:selected').text();
            var cities = citiesSelect.val() || [];
            if (countryCode && cities.length) {
                var current = JSON.parse($('#id_locations').val() || '[]');
                current.push({ country: countryCode, country_name: countryName, cities: cities });
                $('#id_locations').val(JSON.stringify(current));
                row.remove(); // remove row after save
            } else {
                alert('Select country and at least one city.');
            }
        });

        row.append(countrySelect).append(citiesSelect).append(saveBtn);
        $('#id_locations').after(row);
    });
});
