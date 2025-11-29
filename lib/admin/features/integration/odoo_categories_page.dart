import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/odoo/odoo_state.dart';
import '../../../theme/brand_theme.dart';

class OdooCategoriesPage extends StatelessWidget {
  const OdooCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odoo Categories'),
        backgroundColor: BrandColors.jacaranda,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(child: _CategoryList()),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
                    onPressed: () => _showAddDialog(context),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    int? parentId;

    showDialog(
      context: context,
      builder: (ctx) {
        final odoo = context.read<OdooState>();
        return AlertDialog(
          title: const Text('Create Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: parentId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('No parent')),
                  ...odoo.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => parentId = v,
                decoration: const InputDecoration(labelText: 'Parent'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.of(ctx).pop();
                final odooState = context.read<OdooState>();
                await odooState.createCategory({
                  'name': name,
                  if (parentId != null) 'parent_id': parentId,
                });
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final odoo = context.watch<OdooState>();
    final categories = odoo.categories;

    if (!odoo.isAuthenticated) {
      return const Center(child: Text('Not connected to Odoo'));
    }

    if (odoo.isLoading && categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.separated(
      itemCount: categories.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final c = categories[i];
        return ListTile(
          title: Text(c.name),
          subtitle: Text(c.parentName ?? ''),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(context, c),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmDelete(context, c),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, dynamic category) {
    final nameCtrl = TextEditingController(text: category.name);
    int? parentId = category.parentId;

    showDialog(
      context: context,
      builder: (ctx) {
        final odoo = context.read<OdooState>();
        return AlertDialog(
          title: const Text('Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: parentId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('No parent')),
                  ...odoo.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                ],
                onChanged: (v) => parentId = v,
                decoration: const InputDecoration(labelText: 'Parent'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.of(ctx).pop();
                final odooState = context.read<OdooState>();
                await odooState.updateCategory(category.id, {
                  'name': name,
                  if (parentId != null) 'parent_id': parentId,
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, dynamic category) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Delete "${category.name}"? This will remove the category from Odoo.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final odooState = context.read<OdooState>();
                await odooState.deleteCategory(category.id);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
