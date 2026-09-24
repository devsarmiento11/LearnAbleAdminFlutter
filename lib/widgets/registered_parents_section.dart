import 'package:flutter/material.dart';
import '../models/parent_model.dart';
import '../services/account_service.dart';

const _brown = Color(0xFF4D2F18);
const _accent = Color(0xFF8C5A2D);
const _muted = Color(0xFF918274);
const _border = Color(0xFFE8E1D8);

class RegisteredParentsSection extends StatefulWidget {
  final AccountService accountService;
  const RegisteredParentsSection({super.key, required this.accountService});
  @override
  State<RegisteredParentsSection> createState() =>
      _RegisteredParentsSectionState();
}

class _RegisteredParentsSectionState extends State<RegisteredParentsSection> {
  List<ParentModel> parents = [];
  bool loading = true;
  bool failed = false;
  String query = '';
  int page = 0;
  final Set<String> deleting = {};
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final result = await widget.accountService.getParents();
      if (!mounted) return;
      setState(() {
        parents = result;
        loading = false;
        page = 0;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          failed = true;
        });
      }
    }
  }

  Widget _icon() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F1E9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Image.asset(
      'assets/images/parents_icon.png',
      width: 22,
      height: 22,
      color: _accent,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final filtered = parents
        .where(
          (p) => '${p.fullName} ${p.id} ${p.email} ${p.childrenId}'
              .toLowerCase()
              .contains(query),
        )
        .toList();
    final pages = (filtered.length / 5).ceil().clamp(1, 1000000);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _icon(),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parent Account',
                      style: TextStyle(
                        color: _brown,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'List of all registered parent accounts.',
                      style: TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh parents',
                onPressed: loading ? null : _load,
                icon: const Icon(Icons.refresh, color: _accent),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() {
              query = value.trim().toLowerCase();
              page = 0;
            }),
            decoration: InputDecoration(
              hintText: 'Search parent accounts...',
              hintStyle: const TextStyle(color: _muted, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: _accent),
              filled: true,
              fillColor: const Color(0xFFFCFAF7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (loading)
            const Center(child: CircularProgressIndicator(color: _accent))
          else if (failed)
            Center(
              child: Column(
                children: [
                  const Text(
                    'Unable to load parent accounts. Please try again.',
                  ),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          else if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                query.isEmpty
                    ? 'No parent accounts yet. Create a Parent Account to see it here.'
                    : 'No parent accounts found. Try a different search.',
                style: const TextStyle(color: _muted),
              ),
            )
          else
            ...filtered
                .skip(page * 5)
                .take(5)
                .map(
                  (parent) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCFAF7),
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _icon(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    parent.fullName,
                                    style: const TextStyle(
                                      color: _brown,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    parent.id,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: parent.status == 'Active'
                                    ? const Color(0xFFE0F3E6)
                                    : const Color(0xFFF7F1E9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                parent.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: parent.status == 'Active'
                                      ? const Color(0xFF28733F)
                                      : _muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        IconButton(
                          tooltip: 'Delete parent account',
                          onPressed: deleting.contains(parent.id)
                              ? null
                              : () => _delete(parent),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          'Children ID: ${parent.childrenId}',
                          style: const TextStyle(color: _brown, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accent,
                            ),
                            onPressed: () => _view(parent),
                            child: const Text('View'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          if (!loading && !failed)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${filtered.length} parent accounts',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ),
                IconButton(
                  tooltip: 'Previous page',
                  onPressed: page > 0 ? () => setState(() => page--) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  '${page + 1} / $pages',
                  style: const TextStyle(color: _brown),
                ),
                IconButton(
                  tooltip: 'Next page',
                  onPressed: page + 1 < pages
                      ? () => setState(() => page++)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _delete(ParentModel parent) async {
    if (deleting.contains(parent.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Parent Account?'),
        content: Text(
          'Delete ' +
              parent.fullName +
              ' (' +
              parent.id +
              ') and their login? The linked child account will remain. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || deleting.contains(parent.id)) return;
    setState(() => deleting.add(parent.id));
    try {
      await widget.accountService.deleteParent(parent.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Parent account deleted.')));
      await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete parent account. Please retry.'),
          ),
        );
    } finally {
      if (mounted) setState(() => deleting.remove(parent.id));
    }
  }

  void _view(ParentModel parent) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            _icon(),
            const SizedBox(width: 12),
            const Expanded(child: Text('Parent Account')),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final field in <String, String>{
                  'Parents ID': parent.id,
                  'First Name': parent.firstName,
                  'Middle Name': parent.middleName,
                  'Last Name': parent.lastName,
                  'Email': parent.email,
                  'Gender': parent.gender,
                  'Children ID': parent.childrenId,
                  'Status': parent.status,
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.key,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                        SelectableText(
                          field.value.isEmpty ? 'Not provided' : field.value,
                          style: const TextStyle(color: _brown),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
