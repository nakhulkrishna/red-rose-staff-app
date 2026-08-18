import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:staff_app/shared/providers/whatsapp_order_number_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen confirmation shown after an order is saved.
/// Sends the bill to the dashboard-configured WhatsApp number on open,
/// and lets the salesman resend it if WhatsApp did not launch.
class OrderSuccessPage extends ConsumerStatefulWidget {
  const OrderSuccessPage({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.itemCount,
    required this.totalQar,
    required this.message,
  });

  final String orderId;
  final String customerName;
  final int itemCount;
  final double totalQar;
  final String message;

  @override
  ConsumerState<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends ConsumerState<OrderSuccessPage> {
  bool _sending = false;
  String? _status;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendWhatsApp());
  }

  Future<void> _sendWhatsApp() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _status = null;
    });

    try {
      // Refetch so a number changed in the dashboard applies immediately,
      // without needing an app restart.
      ref.invalidate(whatsappOrderNumberProvider);
      final phone = await ref.read(whatsappOrderNumberProvider.future);
      if (!mounted) return;
      if (phone == null || phone.isEmpty) {
        setState(() {
          _sending = false;
          _status =
              'WhatsApp order number is not configured in the dashboard.';
        });
        return;
      }

      final uri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(widget.message)}',
      );
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = opened;
        _status = opened ? null : 'Could not open WhatsApp. Try again.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _status = 'Could not open WhatsApp: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  height: 104,
                  width: 104,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 62,
                    color: Color(0xFF047857),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Order Placed',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _sent
                      ? 'Bill sent on WhatsApp.'
                      : 'Your order has been saved.',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      _Row(label: 'Order ID', value: widget.orderId),
                      const Divider(height: 20),
                      _Row(label: 'Customer', value: widget.customerName),
                      const Divider(height: 20),
                      _Row(
                        label: 'Items',
                        value: '${widget.itemCount}',
                      ),
                      const Divider(height: 20),
                      _Row(
                        label: 'Total',
                        value: 'QAR ${widget.totalQar.toStringAsFixed(2)}',
                        emphasize: true,
                      ),
                    ],
                  ),
                ),
                if (_status != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      _status!,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _sendWhatsApp,
                    icon: _sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.chat_bubble_outline),
                    label: Text(
                      _sending
                          ? 'Opening WhatsApp...'
                          : _sent
                          ? 'Send Again on WhatsApp'
                          : 'Send Bill on WhatsApp',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Back to Products'),
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

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: emphasize ? 18 : 14,
              color: emphasize
                  ? const Color(0xFF047857)
                  : const Color(0xFF111827),
            ),
          ),
        ),
      ],
    );
  }
}
