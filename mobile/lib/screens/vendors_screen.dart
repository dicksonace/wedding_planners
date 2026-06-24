import 'package:flutter/material.dart';
import 'package:wedplan_ghana/services/wedding_service.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key, required this.weddingService, this.planId});

  final WeddingService weddingService;
  final int? planId;

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  List<dynamic> _vendors = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _vendors = await widget.weddingService.vendors(search: _search);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestVendor(Map<String, dynamic> vendor) async {
    if (widget.planId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a wedding plan first to request vendors.')),
      );
      return;
    }

    final messageController = TextEditingController(text: 'We would like to discuss your services for our wedding.');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request ${vendor['business_name']}'),
        content: TextField(
          controller: messageController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Message'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.weddingService.requestVendor(
        widget.planId!,
        vendor['id'] as int,
        messageController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vendor request sent')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search vendors...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
            ),
            onSubmitted: (value) {
              _search = value;
              _load();
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _vendors.length,
                  itemBuilder: (context, index) {
                    final vendor = _vendors[index] as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(vendor['business_name'].toString()),
                        subtitle: Text('${vendor['category']} • ${vendor['location'] ?? 'Ghana'}'),
                        trailing: ElevatedButton(
                          onPressed: () => _requestVendor(vendor),
                          child: const Text('Request'),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
