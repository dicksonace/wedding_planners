import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'create_plan_screen.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  final _search = TextEditingController();
  final _location = TextEditingController();
  String? _category;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final store = context.read<AppStore>();
    await store.refreshDashboard();
    await store.fetchVendorCategories();
    await store.searchVendors();
    if (store.hasPlan) await store.fetchVendorRequests();
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _runSearch() async {
    await context.read<AppStore>().searchVendors(
          search: _search.text,
          category: _category,
          location: _location.text,
        );
  }

  Future<void> _openVendor(Map<String, dynamic> vendor) async {
    final store = context.read<AppStore>();
    Map<String, dynamic> detail = vendor;
    try {
      detail = await store.fetchVendor(vendor['id'] as int);
    } catch (_) {}

    if (!mounted) return;

    final request = _requestForVendor(store, vendor['id'] as int);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _VendorDetailSheet(
        vendor: detail,
        hasPlan: store.hasPlan,
        request: request,
        onRequest: () => _requestVendor(detail),
        onCancel: request == null
            ? null
            : () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Cancel request?'),
                    content: const Text('This will withdraw your quote request before the vendor responds.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Keep')),
                      TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Cancel request')),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await store.cancelVendorRequest(request['id'] as int);
                  if (mounted) {
                    Navigator.pop(context);
                    await _load();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request cancelled')),
                    );
                  }
                }
              },
      ),
    );
    if (mounted) await _load();
  }

  Map<String, dynamic>? _requestForVendor(AppStore store, int vendorId) {
    for (final r in store.vendorRequests) {
      if (r['vendor_id'] == vendorId && r['status'] != 'cancelled') return r;
    }
    return null;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.deepGreen;
      case 'declined':
        return AppColors.richRed;
      case 'cancelled':
        return AppColors.textMuted;
      default:
        return AppColors.goldDark;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted · in Budget';
      case 'declined':
        return 'Declined';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  Future<void> _requestVendor(Map<String, dynamic> vendor) async {
    final store = context.read<AppStore>();
    if (!store.hasPlan) {
      final created = await openCreatePlanScreen(context);
      if (created != true || !mounted) return;
      await _load();
      if (!mounted) return;
    }

    final message = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request quote'),
        content: TextField(
          controller: message,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Message to ${vendor['business_name'] ?? 'vendor'} (optional)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );

    if (sent != true || !mounted) {
      message.dispose();
      return;
    }

    try {
      await store.sendVendorRequest(vendorId: vendor['id'] as int, message: message.text);
      message.dispose();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor request sent successfully.')),
        );
      }
    } on ApiException catch (e) {
      message.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.richRed),
        );
      }
    }
  }

  Future<void> _onAddFab() async {
    final store = context.read<AppStore>();
    if (!store.hasPlan) {
      final created = await openCreatePlanScreen(context);
      if (created == true && mounted) await _load();
      return;
    }
    await _showCategoryPicker();
  }

  Future<void> _showCategoryPicker() async {
    final store = context.read<AppStore>();
    await showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: AppDecor.radiusLg),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Browse by category', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: store.vendorCategories.map((c) {
                return ActionChip(
                  label: Text(c),
                  onPressed: () {
                    setState(() => _category = c);
                    Navigator.pop(ctx);
                    _runSearch();
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final activeRequests = store.vendorRequests.where((r) => r['status'] != 'cancelled').toList();

    return Scaffold(
      appBar: const CoupleAppBar(title: 'Find Vendors'),
      floatingActionButton: AppAddFab(
        tooltip: store.hasPlan ? 'Browse vendors' : 'Create plan',
        onPressed: _onAddFab,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search name, category, location...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        _runSearch();
                      },
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _runSearch(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        initialValue: _category,
                        decoration: const InputDecoration(labelText: 'Category', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All categories')),
                          ...store.vendorCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                        ],
                        onChanged: (v) {
                          setState(() => _category = v);
                          _runSearch();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _location,
                        decoration: const InputDecoration(labelText: 'Location'),
                        onSubmitted: (_) => _runSearch(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                PrimaryButton(label: 'Search', icon: Icons.search, onPressed: _runSearch),
              ],
            ),
          ),
          if (store.hasPlan && activeRequests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('My requests', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...activeRequests.map((req) {
                    final vendor = req['vendor'] as Map<String, dynamic>?;
                    final status = req['status'] as String? ?? 'pending';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.all(14),
                        onTap: vendor != null ? () => _openVendor(vendor) : null,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(vendor?['business_name'] as String? ?? 'Vendor', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      _statusLabel(status),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status)),
                                    ),
                                  ),
                                  if (status == 'accepted' && req['quoted_amount'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Added to budget · GHS ${req['quoted_amount']}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.deepGreen, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (status == 'pending')
                              TextButton(
                                onPressed: () async {
                                  await store.cancelVendorRequest(req['id'] as int);
                                  if (mounted) await _load();
                                },
                                child: const Text('Cancel', style: TextStyle(color: AppColors.richRed)),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          Expanded(
            child: !_loaded || store.vendorsLoading
                ? const Center(child: CircularProgressIndicator())
                : store.vendors.isEmpty
                    ? const EmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'No vendors found',
                        subtitle: 'Try a different search term or category.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: store.vendors.length,
                        itemBuilder: (context, i) {
                          final v = store.vendors[i];
                          final request = _requestForVendor(store, v['id'] as int);
                          final status = request?['status'] as String?;
                          final canRequest = request == null || status == 'declined' || status == 'cancelled';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
                              onTap: () => _openVendor(v),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.softGreen,
                                        child: Text(
                                          (v['business_name'] as String? ?? 'V')[0].toUpperCase(),
                                          style: const TextStyle(color: AppColors.deepGreen, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(v['business_name'] as String? ?? 'Vendor', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                            Text(v['category'] as String? ?? '', style: const TextStyle(color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ),
                                      if (request != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _statusColor(status!).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            _statusLabel(status),
                                            style: TextStyle(fontSize: 10, color: _statusColor(status), fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (v['location'] != null) ...[
                                    const SizedBox(height: 8),
                                    Row(children: [const Icon(Icons.place, size: 16, color: AppColors.textMuted), const SizedBox(width: 4), Text(v['location'] as String)]),
                                  ],
                                  if (v['description'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(v['description'] as String, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted)),
                                  ],
                                  const SizedBox(height: 12),
                                  if (canRequest)
                                    PrimaryButton(label: 'Request Quote', icon: Icons.send, onPressed: () => _openVendor(v))
                                  else if (status == 'pending')
                                    OutlinedButton.icon(
                                      onPressed: () => _openVendor(v),
                                      icon: const Icon(Icons.hourglass_top_rounded),
                                      label: const Text('Pending — tap to cancel'),
                                    )
                                  else
                                    PrimaryButton(label: 'View Details', icon: Icons.visibility, onPressed: () => _openVendor(v)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _VendorDetailSheet extends StatelessWidget {
  const _VendorDetailSheet({
    required this.vendor,
    required this.hasPlan,
    required this.onRequest,
    this.request,
    this.onCancel,
  });

  final Map<String, dynamic> vendor;
  final bool hasPlan;
  final VoidCallback onRequest;
  final Map<String, dynamic>? request;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final services = (vendor['services'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final status = request?['status'] as String?;
    final isPending = status == 'pending';
    final isAccepted = status == 'accepted';
    final canRequest = request == null || status == 'declined';

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(vendor['business_name'] as String? ?? 'Vendor', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('${vendor['category'] ?? ''} · ${vendor['location'] ?? ''}', style: const TextStyle(color: AppColors.textMuted)),
          if (request != null) ...[
            const SizedBox(height: 10),
            _StatusBanner(status: status ?? 'pending', quotedAmount: request!['quoted_amount']),
          ],
          if (vendor['phone'] != null) ...[
            const SizedBox(height: 8),
            Text('Phone: ${vendor['phone']}', style: const TextStyle(color: AppColors.textMuted)),
          ],
          if (vendor['description'] != null) ...[
            const SizedBox(height: 12),
            Text(vendor['description'] as String),
          ],
          if (services.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Services', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...services.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['title'] as String? ?? 'Service', style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (s['description'] != null)
                          Text(s['description'] as String, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        if (s['price_from'] != null)
                          Text(
                            'From GHS ${s['price_from']}',
                            style: const TextStyle(color: AppColors.deepGreen, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                )),
          ],
          const SizedBox(height: 16),
          if (isAccepted)
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: const [
                  Icon(Icons.check_circle_rounded, color: AppColors.deepGreen),
                  SizedBox(width: 10),
                  Expanded(child: Text('This vendor is booked and added to your Budget expenses.', style: TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
            )
          else if (isPending && onCancel != null)
            OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined, color: AppColors.richRed),
              label: const Text('Cancel Request', style: TextStyle(color: AppColors.richRed)),
            )
          else if (canRequest)
            PrimaryButton(
              label: hasPlan ? 'Request Quote' : 'Create Plan to Request',
              icon: Icons.send,
              onPressed: onRequest,
            ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, this.quotedAmount});

  final String status;
  final dynamic quotedAmount;

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.goldDark;
    String label = 'Waiting for vendor response';
    if (status == 'accepted') {
      color = AppColors.deepGreen;
      label = 'Accepted — added to your budget';
    } else if (status == 'declined') {
      color = AppColors.richRed;
      label = 'Vendor declined your request';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppDecor.radiusMd,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          if (status == 'accepted' && quotedAmount != null)
            Text('Estimated: GHS $quotedAmount', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
