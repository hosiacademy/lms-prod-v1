// static/admin/js/color-picker.js
document.addEventListener('DOMContentLoaded', function() {
    // Find all color input fields
    const colorFields = document.querySelectorAll('input[type="text"][id*="color"]');
    
    colorFields.forEach(function(field) {
        // Create color picker container
        const pickerContainer = document.createElement('div');
        pickerContainer.className = 'color-picker-container';
        pickerContainer.style.display = 'flex';
        pickerContainer.style.alignItems = 'center';
        pickerContainer.style.marginTop = '5px';
        
        // Create color preview
        const colorPreview = document.createElement('div');
        colorPreview.className = 'color-preview';
        colorPreview.style.width = '30px';
        colorPreview.style.height = '30px';
        colorPreview.style.borderRadius = '4px';
        colorPreview.style.border = '1px solid #ccc';
        colorPreview.style.marginRight = '10px';
        colorPreview.style.backgroundColor = field.value || '#ffffff';
        colorPreview.style.cursor = 'pointer';
        colorPreview.title = 'Click to pick color';
        
        // Create color picker input
        const colorPicker = document.createElement('input');
        colorPicker.type = 'color';
        colorPicker.value = field.value || '#1a1a1a';
        colorPicker.style.width = '50px';
        colorPicker.style.height = '30px';
        colorPicker.style.border = 'none';
        colorPicker.style.padding = '0';
        colorPicker.style.cursor = 'pointer';
        
        // Create hex value display
        const hexDisplay = document.createElement('span');
        hexDisplay.className = 'color-hex';
        hexDisplay.textContent = field.value || '#1a1a1a';
        hexDisplay.style.marginLeft = '10px';
        hexDisplay.style.fontFamily = 'monospace';
        hexDisplay.style.fontSize = '12px';
        hexDisplay.style.color = '#666';
        
        // Insert after the original field
        field.parentNode.appendChild(pickerContainer);
        pickerContainer.appendChild(colorPreview);
        pickerContainer.appendChild(colorPicker);
        pickerContainer.appendChild(hexDisplay);
        
        // Update functions
        function updateAll(newColor) {
            field.value = newColor;
            colorPreview.style.backgroundColor = newColor;
            colorPicker.value = newColor;
            hexDisplay.textContent = newColor;
        }
        
        // Event listeners
        colorPicker.addEventListener('input', function(e) {
            updateAll(e.target.value);
        });
        
        colorPreview.addEventListener('click', function() {
            colorPicker.click();
        });
        
        field.addEventListener('input', function(e) {
            // Validate hex color
            let value = e.target.value;
            if (!value.startsWith('#')) {
                value = '#' + value;
            }
            if (/^#[0-9A-F]{6}$/i.test(value)) {
                updateAll(value.toUpperCase());
            }
        });
        
        field.addEventListener('change', function(e) {
            // Validate hex color
            let value = e.target.value;
            if (!value.startsWith('#')) {
                value = '#' + value;
            }
            if (/^#[0-9A-F]{6}$/i.test(value)) {
                updateAll(value.toUpperCase());
            }
        });
        
        // Preset colors for quick selection
        const presetColors = [
            '#1A1A1A', '#333333', '#666666', '#999999', '#CCCCCC', '#FFFFFF',
            '#0066CC', '#0099FF', '#66CCFF', '#003366', '#336699',
            '#27AE60', '#2ECC71', '#1ABC9C', '#16A085', '#3498DB',
            '#9B59B6', '#8E44AD', '#E74C3C', '#C0392B', '#F39C12',
            '#D35400', '#7F8C8D', '#34495E', '#2C3E50'
        ];
        
        // Create preset color palette
        const presetContainer = document.createElement('div');
        presetContainer.className = 'color-presets';
        presetContainer.style.marginTop = '10px';
        presetContainer.style.display = 'flex';
        presetContainer.style.flexWrap = 'wrap';
        presetContainer.style.gap = '5px';
        presetContainer.style.maxWidth = '300px';
        
        const presetLabel = document.createElement('div');
        presetLabel.textContent = 'Quick picks:';
        presetLabel.style.fontSize = '11px';
        presetLabel.style.color = '#999';
        presetLabel.style.marginBottom = '5px';
        presetLabel.style.width = '100%';
        
        presetContainer.appendChild(presetLabel);
        
        presetColors.forEach(function(color) {
            const preset = document.createElement('div');
            preset.style.width = '20px';
            preset.style.height = '20px';
            preset.style.borderRadius = '3px';
            preset.style.backgroundColor = color;
            preset.style.border = color === '#FFFFFF' ? '1px solid #ddd' : 'none';
            preset.style.cursor = 'pointer';
            preset.title = color;
            
            preset.addEventListener('click', function() {
                updateAll(color);
            });
            
            presetContainer.appendChild(preset);
        });
        
        pickerContainer.appendChild(presetContainer);
    });
    
    // Add African-inspired color presets button
    const africanColors = [
        '#008000', // Green (Africa)
        '#FFD700', // Gold (Wealth)
        '#DC143C', // Crimson (Blood/Struggle)
        '#000000', // Black (People)
        '#FFFFFF', // White (Peace)
        '#0066CC', // Blue (Sky/Ocean)
        '#8B4513', // Brown (Earth)
        '#FF8C00', // Orange (Sunset)
        '#4B0082', // Indigo (Royalty)
        '#228B22'  // Forest Green (Nature)
    ];
    
    // Find the appearance form
    const form = document.querySelector('form#appappearance_form');
    if (form) {
        const africanBtn = document.createElement('button');
        africanBtn.type = 'button';
        africanBtn.textContent = '?? Afro Colors';
        africanBtn.style.margin = '15px 0';
        africanBtn.style.padding = '8px 15px';
        africanBtn.style.backgroundColor = '#27ae60';
        africanBtn.style.color = 'white';
        africanBtn.style.border = 'none';
        africanBtn.style.borderRadius = '4px';
        africanBtn.style.cursor = 'pointer';
        africanBtn.style.fontSize = '13px';
        
        africanBtn.addEventListener('click', function() {
            const colorFields = document.querySelectorAll('input[type="text"][id*="color"]');
            if (colorFields.length >= 3) {
                // Primary - African Green
                if (colorFields[0]) colorFields[0].value = '#008000';
                // Primary Variant - Dark Green
                if (colorFields[1]) colorFields[1].value = '#006400';
                // Secondary - African Gold
                if (colorFields[2]) colorFields[2].value = '#FFD700';
                
                // Trigger updates
                colorFields.forEach(field => {
                    field.dispatchEvent(new Event('input', { bubbles: true }));
                });
                
                alert('Applied African-inspired color palette!');
            }
        });
        
        form.querySelector('.submit-row').parentNode.insertBefore(africanBtn, form.querySelector('.submit-row'));
    }
});
