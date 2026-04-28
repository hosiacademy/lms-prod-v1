import 'package:flutter/material.dart';

class PaymentLogo {
  final String name;
  final IconData icon;
  final String? logoPath;

  const PaymentLogo({
    required this.name,
    required this.icon,
    this.logoPath,
  });
}

// Payment Logos Database
final List<PaymentLogo> paymentLogos = [
  PaymentLogo(
    name: 'Flutterwave',
    icon: Icons.payment,
    logoPath: 'assets/images/payments/flutterwave.png',
  ),
  PaymentLogo(
    name: 'Paystack',
    icon: Icons.payment,
    logoPath: 'assets/images/payments/paystack.png',
  ),
  PaymentLogo(
    name: 'M-Pesa',
    icon: Icons.phone_android,
    logoPath: 'assets/images/payments/mpesa.png',
  ),
  PaymentLogo(
    name: 'MTN MoMo',
    icon: Icons.phone_android,
    logoPath: 'assets/images/payments/mtn.png',
  ),
  PaymentLogo(
    name: 'Stripe',
    icon: Icons.credit_card,
    logoPath: 'assets/images/payments/stripe.png',
  ),
  PaymentLogo(
    name: 'PayPal',
    icon: Icons.payment,
    logoPath: 'assets/images/payments/paypal.png',
  ),
  PaymentLogo(
    name: 'Interswitch',
    icon: Icons.swap_horiz,
    logoPath: 'assets/images/payments/interswitch.png',
  ),
  PaymentLogo(
    name: 'Remita',
    icon: Icons.account_balance,
    logoPath: 'assets/images/payments/remita.png',
  ),
  PaymentLogo(
    name: 'Airtel Money',
    icon: Icons.phone_iphone,
    logoPath: 'assets/images/payments/airtel.png',
  ),
  PaymentLogo(
    name: 'Pesapal',
    icon: Icons.account_balance,
    logoPath: 'assets/images/payments/pesapal.png',
  ),
  PaymentLogo(
    name: 'PayFast',
    icon: Icons.speed,
    logoPath: 'assets/images/payments/payfast.png',
  ),
  PaymentLogo(
    name: 'SnapScan',
    icon: Icons.qr_code_scanner,
    logoPath: 'assets/images/payments/snapscan.png',
  ),
  PaymentLogo(
    name: 'Fawry',
    icon: Icons.store,
    logoPath: 'assets/images/payments/fawry.png',
  ),
  PaymentLogo(
    name: 'Paymob',
    icon: Icons.mobile_screen_share,
    logoPath: 'assets/images/payments/paymob.png',
  ),
  PaymentLogo(
    name: 'Vodacom',
    icon: Icons.phone_android,
    logoPath: 'assets/images/payments/vodacom.png',
  ),
  PaymentLogo(
    name: 'Bank Transfer',
    icon: Icons.account_balance,
    logoPath: null,
  ),
];

// ROUNDED EDGE CONTAINERS FOR LOGOS
class PaymentOptions extends StatelessWidget {
  final int crossAxisCount;
  final double containerSize;
  final double logoSize;
  final double spacing;
  final double borderRadius;

  const PaymentOptions({
    super.key,
    this.crossAxisCount = 4,
    this.containerSize = 70,
    this.logoSize = 40,
    this.spacing = 16,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: paymentLogos.length,
      itemBuilder: (context, index) {
        final logo = paymentLogos[index];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rounded container with logo
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  // This inner container ensures logo stays within bounds
                  constraints: BoxConstraints(
                    maxWidth: logoSize,
                    maxHeight: logoSize,
                  ),
                  child: logo.logoPath != null
                      ? Image.asset(
                          logo.logoPath!,
                          fit: BoxFit.contain, // This preserves aspect ratio
                          width: logoSize,
                          height: logoSize,
                        )
                      : Icon(
                          logo.icon,
                          size: logoSize * 0.7, // Slightly smaller icon
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                logo.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}

// HORIZONTAL SCROLL WITH ROUNDED CONTAINERS
class PaymentOptionsHorizontal extends StatelessWidget {
  final double containerSize;
  final double logoSize;
  final double borderRadius;

  const PaymentOptionsHorizontal({
    super.key,
    this.containerSize = 60,
    this.logoSize = 32,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: containerSize + 40, // Extra space for text
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: paymentLogos.length,
        itemBuilder: (context, index) {
          final logo = paymentLogos[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rounded container with logo
                Container(
                  width: containerSize,
                  height: containerSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .shadow
                            .withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: logoSize,
                        maxHeight: logoSize,
                      ),
                      child: logo.logoPath != null
                          ? Image.asset(
                              logo.logoPath!,
                              fit: BoxFit.contain,
                              width: logoSize,
                              height: logoSize,
                            )
                          : Icon(
                              logo.icon,
                              size: logoSize * 0.7,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface,
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Text
                Container(
                  constraints: BoxConstraints(maxWidth: containerSize),
                  child: Text(
                    logo.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ALTERNATIVE VERSION: WITH PADDING INSIDE CONTAINER
class PaymentOptionsWithPadding extends StatelessWidget {
  final int crossAxisCount;
  final double containerSize;
  final double logoSize;
  final double spacing;
  final double borderRadius;
  final Color backgroundColor;

  const PaymentOptionsWithPadding({
    super.key,
    this.crossAxisCount = 4,
    this.containerSize = 70,
    this.logoSize = 40,
    this.spacing = 16,
    this.borderRadius = 16,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: paymentLogos.length,
      itemBuilder: (context, index) {
        final logo = paymentLogos[index];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container with padding to ensure logo isn't cut
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: backgroundColor == Colors.transparent
                    ? colorScheme.surfaceContainerHighest
                    : backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              // Padding ensures logo stays away from edges
              padding: EdgeInsets.all(containerSize * 0.15),
              child: Center(
                child: logo.logoPath != null
                    ? Image.asset(
                        logo.logoPath!,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        logo.icon,
                        size: logoSize,
                        color: colorScheme.onSurface,
                      ),
              ),
            ),

            const SizedBox(height: 8),

            // Text
            Text(
              logo.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}
