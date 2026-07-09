import 'package:flutter/material.dart';

import '../services/billing_service.dart';
import '../services/premium_service.dart';

const _bg = Color(0xFF070A12);
const _panel = Color(0xFF101827);
const _cyan = Color(0xFF00E5FF);
const _pink = Color(0xFFFF2D92);
const _violet = Color(0xFF7C4DFF);

const _gradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_cyan, _violet, _pink],
);

/// Premium Lifetime purchase screen.
///
/// Uses Google Play Billing through BillingService and does not directly write
/// premium entitlement. Unlocking happens only after purchase/restore events.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final premium = PremiumService.instance;
  final billing = BillingService.instance;

  @override
  void initState() {
    super.initState();
    premium.addListener(_onStateChanged);
    billing.addListener(_onStateChanged);
    PremiumService.instance.initialize();
  }

  @override
  void dispose() {
    premium.removeListener(_onStateChanged);
    billing.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _buy() async {
    await premium.buyPremium();
    _showBillingMessage();
  }

  Future<void> _restore() async {
    await premium.restorePurchases();
    _showBillingMessage();
  }

  void _showBillingMessage() {
    final message = billing.errorMessage;
    if (!mounted || message == null || message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = billing.premiumProduct;
    final price = product?.price ?? 'Lifetime';
    final isBusy = premium.isLoading || billing.purchasePending;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Premium'),
        backgroundColor: _bg,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: _gradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _cyan.withValues(alpha: 0.24),
                      blurRadius: 32,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 52),
                    SizedBox(height: 16),
                    Text(
                      'Premium Lifetime',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Unlock everything forever with one purchase.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _PriceCard(price: price),
              const SizedBox(height: 20),
              _FeatureTile(
                icon: Icons.block_rounded,
                title: 'No Ads',
                subtitle: 'AdMob banners and interstitials disabled.',
              ),
              _FeatureTile(
                icon: Icons.image_rounded,
                title: 'Premium Wallpapers',
                subtitle: 'Premium wallpapers unlocked forever.',
              ),
              _FeatureTile(
                icon: Icons.high_quality_rounded,
                title: '4K Access',
                subtitle: '4K wallpapers and future restrictions unlocked.',
              ),
              const SizedBox(height: 22),
              if (premium.isPremium)
                _StatusBox(
                  icon: Icons.verified_rounded,
                  text: 'Premium active on this device.',
                )
              else
                FilledButton.icon(
                  onPressed: isBusy ? null : _buy,
                  icon: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.workspace_premium_rounded),
                  label: Text(isBusy ? 'Please wait...' : 'Buy Premium'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: _cyan,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isBusy ? null : _restore,
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Restore Purchases'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                ),
              ),
              if (billing.errorMessage != null) ...[
                const SizedBox(height: 14),
                Text(
                  billing.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String price;

  const _PriceCard({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cyan.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.all_inclusive_rounded, color: _cyan, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lifetime access',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'One-time purchase',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.58)),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _cyan),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StatusBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
