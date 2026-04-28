// static/admin/js/auto_populate_course.js
(function($) {
    $(document).ready(function() {
        console.log('Course auto-populate script loaded');
        
        var rawCourseSelector = $('#id_raw_course');
        
        if (rawCourseSelector.length) {
            // Watch for raw_course selection change
            rawCourseSelector.change(function() {
                var rawCourseId = $(this).val();
                if (!rawCourseId) {
                    // Clear fields if no selection
                    clearFields();
                    return;
                }
                
                console.log('Raw course selected:', rawCourseId);
                
                // Show loading indicator
                showLoading(true);
                
                // Fetch course details via AJAX
                $.ajax({
                    url: '/admin/aicerts_courses/aicertscourse/' + rawCourseId + '/change/?format=json',
                    type: 'GET',
                    dataType: 'json',
                    success: function(data) {
                        console.log('Course data received:', data);
                        
                        // Auto-fill form fields
                        $('#id_title').val(data.fields.title || '');
                        $('#id_description').val(data.fields.description || '');
                        $('#id_categories').val(data.fields.category_name || '');
                        $('#id_certificate_badge_url').val(data.fields.certificate_badge_url || '');
                        $('#id_feature_image_url').val(data.fields.feature_image_url || '');
                        $('#id_course_id').val(data.fields.external_id || '');
                        $('#id_lms_id').val(data.fields.lms_course_id || '');
                        
                        // Set price if empty
                        var currentPrice = $('#id_our_price_usd').val();
                        if (!currentPrice && data.fields.price_individual) {
                            $('#id_our_price_usd').val(data.fields.price_individual);
                        }
                        
                        // Show success message
                        showMessage('success', '✓ Course details auto-populated from: ' + data.fields.title);
                        
                        // Hide loading
                        showLoading(false);
                    },
                    error: function(xhr, status, error) {
                        console.error('Error fetching course data:', error);
                        showMessage('error', '⚠ Could not fetch course details. Please fill manually.');
                        showLoading(false);
                    }
                });
            });
            
            // Trigger change on page load if already selected
            if (rawCourseSelector.val()) {
                rawCourseSelector.trigger('change');
            }
        }
        
        function clearFields() {
            $('#id_title').val('');
            $('#id_description').val('');
            $('#id_categories').val('');
            $('#id_certificate_badge_url').val('');
            $('#id_feature_image_url').val('');
            showMessage('info', 'No course selected. Fill details manually.');
        }
        
        function showLoading(show) {
            if (show) {
                $('<div class="loading-populate">Loading course details...</div>').insertAfter('#id_raw_course');
            } else {
                $('.loading-populate').remove();
            }
        }
        
        function showMessage(type, text) {
            // Remove existing messages
            $('.populate-message').remove();
            
            var color = type === 'success' ? '#28a745' : 
                       type === 'error' ? '#dc3545' : '#17a2b8';
            
            $('<div class="populate-message" style="background:' + color + ';color:white;padding:8px;margin:10px 0;border-radius:4px;">' + 
              text + '</div>').insertAfter('#id_raw_course');
            
            // Auto-remove after 5 seconds
            setTimeout(function() {
                $('.populate-message').fadeOut();
            }, 5000);
        }
    });
})(django.jQuery);