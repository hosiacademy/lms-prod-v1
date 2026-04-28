// Add to your existing course_card.dart or create a payment-enabled version
import 'package:flutter/material.dart';
import '../../../core/constants/african_currencies.dart';
import '../../../core/services/currency_service.dart';

class PaymentEnabledCourseCard extends StatelessWidget {
  final String courseId;
  final String courseTitle;
  final String? instructor;
  final double price; // Price in USD (base currency)
  final String? imageUrl;
  final String? userCountry;

  const PaymentEnabledCourseCard({
    super.key,
    required this.courseId,
    required this.courseTitle,
    this.instructor,
    required this.price,
    this.imageUrl,
    this.userCountry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final country = userCountry ?? 'KE'; // Default to Kenya
    final currencyCode = AfricanCurrencies.getCurrencyCode(country);
    final currencySymbol = AfricanCurrencies.getCurrencySymbol(country);

    return Card(
      elevation: 3,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course image
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: colors.surfaceContainerHighest,
            ),
            child: imageUrl == null
                ? Center(
                    child: Icon(
                      Icons.school_rounded,
                      size: 60,
                      color: colors.onSurface.withValues(alpha: 0.3),
                    ),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (instructor != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      instructor!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FutureBuilder<double>(
                      future: CurrencyService.instance
                          .convertFromUSDAsync(price, currencyCode),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            width: 60,
                            height: 20,
                            child: LinearProgressIndicator(),
                          );
                        }

                        final localPrice = snapshot.data ?? price;
                        // If conversion failed (returns same price) but currency code is different,
                        // we might want to show USD or handle it.
                        // For now, we trust the service returns a value.

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CurrencyService.instance.formatPrice(localPrice, currencyCode: currencyCode),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.tertiary,
                              ),
                            ),
                            Text(
                              currencyCode,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: () => _enrollInCourse(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Enroll Now',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get price asynchronously for the bottom sheet
  Future<double> _getLocalPrice(String currencyCode) async {
    return await CurrencyService.instance
        .convertFromUSDAsync(price, currencyCode);
  }

  Future<void> _enrollInCourse(BuildContext context) async {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final country = userCountry ?? 'KE';
    final currencyCode = AfricanCurrencies.getCurrencyCode(country);
    final currencySymbol = AfricanCurrencies.getCurrencySymbol(country);

    // Show loading indicator briefly if needed, or just await
    final localPrice = await _getLocalPrice(currencyCode);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enroll in Course',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Course: $courseTitle',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Price: ${CurrencyService.instance.formatPrice(localPrice, currencyCode: currencyCode)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Proceeding to payment for $courseTitle'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Proceed to Payment',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
