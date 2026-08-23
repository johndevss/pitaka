import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitaka/features/account/controllers/account_providers.dart';
import 'package:pitaka/core/utils/currency_formatter.dart';
import 'package:pitaka/features/account/models/account.dart';
import 'package:pitaka/features/account/presentation/edit_account_screen.dart';
import 'package:pitaka/core/utils/page_transitions.dart';

class AccountCard extends ConsumerStatefulWidget {
  final Account account;
  final String heroTagPrefix;

  const AccountCard({
    super.key,
    required this.account,
    this.heroTagPrefix = 'card',
  });

  @override
  ConsumerState<AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends ConsumerState<AccountCard> {
  bool _isPressed = false;

  void _handleTapDown(_) {
    setState(() => _isPressed = true);
  }

  void _handleTapUp(_) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    final heroTag = '${widget.heroTagPrefix}_card_${widget.account.id}';
    Navigator.of(context).push(
      SmoothSlideRoute(
        page: AccountDetailsScreen(account: widget.account, heroTag: heroTag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final balanceAsync = ref.watch(accountBalanceProvider(account.id!));
    final cardColor = colorForAccount(account);
    final heroTag = '${widget.heroTagPrefix}_card_${account.id}';

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Hero(
          tag: heroTag,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cardColor.withValues(alpha: _isPressed ? 0.2 : 0.35),
                    blurRadius: _isPressed ? 6 : 12,
                    offset: Offset(0, _isPressed ? 2 : 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon + Provider Name + More Button
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: account.iconKey != null
                            ? Image.asset(
                                'assets/icons/institutions/${account.iconKey}.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                      iconForType(account.type),
                                      size: 18,
                                      color: Colors.white,
                                    ),
                              )
                            : Icon(
                                iconForType(account.type),
                                size: 18,
                                color: Colors.white,
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayNameForProvider(account.providerName),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.more_horiz,
                        size: 18,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // ACCOUNT NAME: Custom nickname chosen by the user
                  if (account.name != null && account.name!.isNotEmpty) ...[
                    Text(
                      account.name!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],

                  // SUBTITLE: Account type (e.g., Debit · PHP)
                  Text(
                    subtitleForAccount(account),
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),

                  const Spacer(),

                  const Text(
                    'BALANCE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  balanceAsync.when(
                    data: (balance) => Text(
                      formatMoney(balance, account.currency),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    error: (err, stack) => const Text(
                      '—',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Looks up the specific brand identity color using the iconKey database value
Color colorForAccount(Account account) {
  switch (account.iconKey) {
    // Wallets
    case 'gcash':
      return const Color(0xFF005CE6); // GCash Blue
    case 'maya':
      return const Color(0xFF00DF89); // Maya Vibrant Green
    case 'grabpay':
      return const Color(0xFF00B14F); // Grab Green
    case 'shopeepay':
      return const Color(0xFFEE4D2D); // Shopee Orange
    case 'maribank':
      return const Color(0xFFF58220); // Maribank Orange
    case 'gotyme':
      return const Color(0xFF00D2FF); // GoTyme Electric Cyan/Blue
    case 'bpi-banko':
      return const Color(0xFF951415); // BanKo Crimson Red
    case 'rcbc-diskartech':
      return const Color(0xFF00A8B5); // DiskarTech Vibrant Teal

    // Banks
    case 'bpi':
      return const Color(0xFF8A1538); // BPI Maroon/Red
    case 'bdo':
      return const Color(0xFF002C6C); // BDO Deep Blue
    case 'metrobank':
      return const Color(0xFF00529B); // Metrobank Blue
    case 'unionbank':
      return const Color(0xFFFF671F); // UnionBank Vibrant Orange
    case 'landbank':
      return const Color(0xFF006A4E); // Landbank Forest Green
    case 'rcbc':
      return const Color(0xFF003DA5); // RCBC Corporate Blue

    case 'cash':
      return const Color(0xFF2E7D32); // Cash/Money Green

    default:
      return _colorForType(account.type); // Safe fallback if no match found
  }
}

Color _colorForType(String type) {
  switch (type) {
    case 'bank':
      return const Color(0xffd64545);
    case 'e-wallet':
      return const Color(0xff1f8a5b);
    case 'credit':
      return const Color(0xff3aa76d);
    case 'cash':
      return const Color(0xffd9a441);
    default:
      return const Color(0xff666666);
  }
}

IconData iconForType(String type) {
  switch (type) {
    case 'bank':
      return Icons.account_balance_rounded;
    case 'e-wallet':
      return Icons.phone_iphone_rounded;
    case 'credit':
      return Icons.credit_card_rounded;
    case 'cash':
      return Icons.payments_rounded;
    default:
      return Icons.account_balance_wallet_rounded;
  }
}

String subtitleForAccount(Account account) {
  final typeLabel = account.type == 'e-wallet'
      ? 'Debit'
      : account.type == 'credit'
      ? 'Credit'
      : account.type[0].toUpperCase() + account.type.substring(1);
  return '$typeLabel · ${account.currency}';
}

String displayNameForProvider(String provider) {
  switch (provider) {
    case 'gcash':
      return 'GCash';
    case 'maya':
      return 'Maya';
    case 'grabpay':
      return 'GrabPay';
    case 'shopeepay':
      return 'ShopeePay';
    case 'maribank':
      return 'MariBank';
    case 'bpi':
      return 'BPI';
    case 'bdo':
      return 'BDO';
    case 'metrobank':
      return 'Metrobank';
    case 'unionbank':
      return 'UnionBank';
    case 'landbank':
      return 'Landbank';
    case 'rcbc':
      return 'RCBC';
    default:
      if (provider.isEmpty) return 'Custom';
      return provider[0].toUpperCase() + provider.substring(1);
  }
}
