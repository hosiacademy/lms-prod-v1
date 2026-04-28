import 'dart:async';
import 'package:flutter/material.dart';

class PaymentLogo {
  final String name;
  final IconData icon;
  final String? logoPath;
  final String url;

  const PaymentLogo({
    required this.name,
    required this.icon,
    this.logoPath,
    required this.url,
  });
}

// Payment Logos Database
final List<PaymentLogo> paymentLogos = [
  PaymentLogo(
    name: 'Flutterwave',
    icon: Icons.payment,
    logoPath: 'assets/images/payments/flutterwave.png',
    url: 'https://flutterwave.com',
  ),
  PaymentLogo(
    name: 'Paystack',
    icon: Icons.payment,
    logoPath: 'assets/images/payments/paystack.png',
    url: 'https://paystack.com',
  ),
  PaymentLogo(
    name: 'M-Pesa',
    icon: Icons.phone_android,
    logoPath: 'assets/images/payments/mpesa.png',
    url: 'https://www.safaricom.co.ke/personal/m-pesa',
  ),
  PaymentLogo(
    name: 'MTN MoMo',
    icon: Icons.phone_android,
    logoPath: 'assets/images/payments/mtn.png',
    url: 'https://www.mtn.com/fintech/',
  ),
  PaymentLogo(
    name: 'Stripe',
    icon: Icons.credit_card,
    logoPath: 'assets/images/payments/stripe.png',
    url: 'https://stripe.com',
  ),
  PaymentLogo(
    name: 'PayPal',
    icon: Icons.payment,
    logoPath: 'assets/images/payments/paypal.png',
    url: 'https://www.paypal.com',
  ),
  PaymentLogo(
    name: 'Interswitch',
    icon: Icons.swap_horiz,
    logoPath: 'assets/images/payments/interswitch.png',
    url: 'https://www.interswitchgroup.com',
  ),
  PaymentLogo(
    name: 'Remita',
    icon: Icons.account_balance,
    logoPath: 'assets/images/payments/remita.png',
    url: 'https://www.remita.net',
  ),
  PaymentLogo(
    name: 'Airtel Money',
    icon: Icons.phone_iphone,
    logoPath: 'assets/images/payments/airtel.png',
    url: 'https://www.airtel.africa/personal/money',
  ),
  PaymentLogo(
    name: 'Pesapal',
    icon: Icons.account_balance,
    logoPath: 'assets/images/payments/pesapal.png',
    url: 'https://www.pesapal.com',
  ),
  PaymentLogo(
    name: 'PayFast',
    icon: Icons.speed,
    logoPath: 'assets/images/payments/payfast.png',
    url: 'https://payfast.io',
  ),
  PaymentLogo(
    name: 'SnapScan',
    icon: Icons.qr_code_scanner,
    logoPath: 'assets/images/payments/snapscan.png',
    url: 'https://www.snapscan.co.za',
  ),
  PaymentLogo(
    name: 'Fawry',
    icon: Icons.store,
    logoPath: 'assets/images/payments/fawry.png',
    url: 'https://fawry.com',
  ),
  PaymentLogo(
    name: 'Paymob',
    icon: Icons.mobile_screen_share,
    logoPath: 'assets/images/payments/paymob.png',
    url: 'https://paymob.com',
  ),
  PaymentLogo(
    name: 'Vodacom',
    icon: Icons.phone_android,
    logoPath: 'assets/images/payments/vodacom.png',
    url: 'https://www.vodacom.co.za/vodacom/services/voda-pay',
  ),
  PaymentLogo(
    name: 'Bank Transfer',
    icon: Icons.account_balance,
    logoPath: null,
    url: 'https://hosi.academy/bank-details', // Placeholder
  ),
];

/// Rightward flowing marquee for payment logos
/// Height automatically adjusts to tallest logo
class PaymentLogoMarquee extends StatefulWidget {
  final double logoHeight;
  final double spacing;
  final double scrollSpeed;

  const PaymentLogoMarquee({
    super.key,
    this.logoHeight = 60.0,
    this.spacing = 32.0,
    this.scrollSpeed = 1.5,
  });

  @override
  State<PaymentLogoMarquee> createState() => _PaymentLogoMarqueeState();
}

class _PaymentLogoMarqueeState extends State<PaymentLogoMarquee> {
  late ScrollController _scrollController;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMarquee());
  }

  void _startMarquee() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      // Reset to start when reaching halfway point for seamless loop
      // We duplicate logos, so reset at 50% to create infinite effect
      if (currentScroll >= maxScroll * 0.5) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.animateTo(
          currentScroll + widget.scrollSpeed,
          duration: const Duration(milliseconds: 30),
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Duplicate logos for seamless infinite scroll
    final duplicatedLogos = [...paymentLogos, ...paymentLogos];

    // Vertical padding matches logo height for balanced spacing
    final verticalPadding = widget.logoHeight * 0.3;

    return Container(
      height: widget.logoHeight + (verticalPadding * 2),
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: duplicatedLogos.length,
        itemBuilder: (context, index) {
          final logo = duplicatedLogos[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
            child: _buildLogoWidget(logo),
          );
        },
      ),
    );
  }

  Widget _buildLogoWidget(PaymentLogo logo) {
    if (logo.logoPath != null) {
      return Image.asset(
        logo.logoPath!,
        height: widget.logoHeight,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return Icon(
            logo.icon,
            size: widget.logoHeight,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          );
        },
      );
    } else {
      return Icon(
        logo.icon,
        size: widget.logoHeight,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      );
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}

// SIMPLE, CLEAN DISPLAY WITHOUT STUPID CONTAINERS
class PaymentOptions extends StatelessWidget {
  final int crossAxisCount;
  final double logoSize;
  final double spacing;

  const PaymentOptions({
    super.key,
    this.crossAxisCount = 4,
    this.logoSize = 40,
    this.spacing = 16,
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

        // NO CONTAINER, JUST SIMPLE COLUMN
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo - no container, just the image/icon
            logo.logoPath != null
                ? Image.asset(
                    logo.logoPath!,
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  )
                : Icon(
                    logo.icon,
                    size: logoSize,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),

            const SizedBox(height: 8),

            // Text - no wrapping container, no background
            Text(
              logo.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        );
      },
    );
  }
}

// EVEN SIMPLER - HORIZONTAL SCROLL
class PaymentOptionsHorizontal extends StatelessWidget {
  final double logoSize;

  const PaymentOptionsHorizontal({
    super.key,
    this.logoSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: logoSize + 40,
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
                logo.logoPath != null
                    ? Image.asset(
                        logo.logoPath!,
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                      )
                    : Icon(
                        logo.icon,
                        size: logoSize,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                const SizedBox(height: 6),
                Text(
                  logo.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
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

/// Auto-scrolling carousel with 5px rounded containers and 2cm vertical padding
class PaymentLogoCarousel extends StatefulWidget {
  final double logoHeight;
  final double spacing;
  final double scrollSpeed;
  final double borderRadius;
  final double verticalPaddingCm;

  const PaymentLogoCarousel({
    super.key,
    this.logoHeight = 50.0,
    this.spacing = 16.0,
    this.scrollSpeed = 1.0,
    this.borderRadius = 5.0,
    this.verticalPaddingCm = 2.0, // 2cm vertical padding
  });

  @override
  State<PaymentLogoCarousel> createState() => _PaymentLogoCarouselState();
}

class _PaymentLogoCarouselState extends State<PaymentLogoCarousel> {
  late ScrollController _scrollController;
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCarousel());
  }

  void _startCarousel() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_scrollController.hasClients) return;

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      // Reset to start when reaching halfway point for seamless loop
      // We duplicate logos, so reset at 50% to create infinite effect
      if (currentScroll >= maxScroll * 0.5) {
        _scrollController.jumpTo(0);
      } else {
        _scrollController.animateTo(
          currentScroll + widget.scrollSpeed,
          duration: const Duration(milliseconds: 30),
          curve: Curves.linear,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Duplicate logos for seamless infinite scroll
    final duplicatedLogos = [...paymentLogos, ...paymentLogos];

    // Convert 2cm to pixels (1cm ˜ 37.795 pixels)
    final verticalPaddingPx = widget.verticalPaddingCm * 37.795;

    return Container(
      padding: EdgeInsets.symmetric(vertical: verticalPaddingPx),
      child: SizedBox(
        height: widget.logoHeight + 20, // Extra space for container padding
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: duplicatedLogos.length,
          itemBuilder: (context, index) {
            final logo = duplicatedLogos[index];
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              child: _buildLogoContainer(logo, context),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoContainer(PaymentLogo logo, BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: widget.logoHeight + 30,
      height: widget.logoHeight + 20,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: isDark
              ? colors.outline.withValues(alpha: 0.2)
              : colors.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: _buildLogoWidget(logo, context),
      ),
    );
  }

  Widget _buildLogoWidget(PaymentLogo logo, BuildContext context) {
    if (logo.logoPath != null) {
      return Image.asset(
        logo.logoPath!,
        height: widget.logoHeight * 0.7,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails to load
          return Icon(
            logo.icon,
            size: widget.logoHeight * 0.6,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          );
        },
      );
    } else {
      return Icon(
        logo.icon,
        size: widget.logoHeight * 0.6,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      );
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }
}
