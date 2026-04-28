// static/admin/js/learnerships_cost_conversion.js
document.addEventListener('DOMContentLoaded', function () {
    const costInput = document.querySelector('#id_cost_usd');
    const durationInput = document.querySelector('#id_duration_weeks');
    const countriesSelect = document.querySelector('#id_countries');

    if (!costInput || !durationInput || !countriesSelect) return;

    // Create display elements if not present
    let convertedSpan = document.querySelector('#converted-price');
    if (!convertedSpan) {
        convertedSpan = document.createElement('span');
        convertedSpan.id = 'converted-price';
        convertedSpan.style.marginLeft = '15px';
        convertedSpan.style.color = '#555';
        const costLabel = document.querySelector('label[for="id_cost_usd"]');
        if (costLabel) costLabel.appendChild(convertedSpan);
    }

    let instalmentSpan = document.querySelector('#monthly-instalment');
    if (!instalmentSpan) {
        instalmentSpan = document.createElement('span');
        instalmentSpan.id = 'monthly-instalment';
        instalmentSpan.style.marginLeft = '15px';
        instalmentSpan.style.color = '#555';
        const durationLabel = document.querySelector('label[for="id_duration_weeks"]');
        if (durationLabel) durationLabel.appendChild(instalmentSpan);
    }

    // Fetch exchange rates (hourly updated)
    fetch('https://api.exchangerate-api.com/v4/latest/USD?apiKey=YOUR_FREE_API_KEY_HERE')
        .then(response => response.json())
        .then(data => {
            const rates = data.rates;

            function update() {
                const usd = parseFloat(costInput.value) || 0;
                const weeks = parseInt(durationInput.value) || 0;
                const months = weeks > 0 ? Math.round(weeks / 4.33) : 0;

                // Monthly instalment
                instalmentSpan.textContent = months > 0 ? `Monthly: $${(usd / months).toFixed(2)}` : '(set duration)';

                // Local currency (first selected country)
                const selected = Array.from(countriesSelect.selectedOptions).map(opt => opt.value);
                if (selected.length === 0) {
                    convertedSpan.textContent = '(select country)';
                } else if (selected.length === 1) {
                    const code = selected[0];
                    const currency = COUNTRY_TO_CURRENCY[code];
                    if (currency && rates[currency]) {
                        const local = (usd * rates[currency]).toFixed(2);
                        const symbol = CURRENCY_SYMBOLS[currency] || currency;
                        convertedSpan.textContent = `≈ ${symbol}${local}`;
                    } else {
                        convertedSpan.textContent = '(currency not found)';
                    }
                } else {
                    convertedSpan.textContent = '(multiple countries — base USD)';
                }
            }

            costInput.addEventListener('input', update);
            durationInput.addEventListener('input', update);
            countriesSelect.addEventListener('change', update);
            update(); // Initial
        })
        .catch(err => {
            convertedSpan.textContent = ' (conversion failed)';
            instalmentSpan.textContent = ' (instalment failed)';
        });
});