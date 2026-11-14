import 'package:flutter/material.dart';

class PriceText extends StatelessWidget {
  final double regularPrice;
  final double finalPrice;
  final String currency;
  final double discountPercent;
  final bool showBadge;
  final TextStyle? priceStyle;
  final TextStyle? regularPriceStyle;

  const PriceText({
    super.key,
    required this.regularPrice,
    required this.finalPrice,
    required this.currency,
    this.discountPercent = 0.0,
    this.showBadge = false,
    this.priceStyle,
    this.regularPriceStyle,
  });

  String _formatCurrency(double amount) {
    final symbol = currency == 'USD' ? '\$' : '$currency ';
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = discountPercent > 0 && regularPrice > finalPrice;

    final defaultPriceStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: Theme.of(context).colorScheme.primary,
    );

    final defaultRegularStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Colors.grey.shade500,
      decoration: TextDecoration.lineThrough,
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        Text(
          _formatCurrency(finalPrice),
          style: priceStyle ?? defaultPriceStyle,
        ),
        if (hasDiscount) ...[
          Text(
            _formatCurrency(regularPrice),
            style: regularPriceStyle ?? defaultRegularStyle,
          ),
          if (showBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${discountPercent.toStringAsFixed(0)}% OFF',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
