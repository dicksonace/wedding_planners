import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../store/app_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

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
    await store.fetchVendorCategories();
    await store.searchVendors();
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _runSearch() async {
    await context.read<AppStore>().searchVendors(
          search: _search.text,
          category: _category,
          location: _location.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return Scaffold(
      appBar: AppBar(title: const Text('Find Vendors')),
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
                        value: _category,
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppCard(
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
