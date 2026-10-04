import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pakeaja/core/constants/app_constants.dart';
import 'package:pakeaja/core/providers/service_providers.dart';
import 'package:pakeaja/core/theme/app_theme.dart';
import 'package:pakeaja/core/widgets/custom_button.dart';
import 'package:pakeaja/core/widgets/state_widgets.dart';
import 'package:pakeaja/data/models/cloth_model.dart';
import 'package:pakeaja/features/auth/providers/auth_provider.dart' show authStateProvider;
import 'package:pakeaja/features/wardrobe/providers/wardrobe_provider.dart';

class EditClothScreen extends ConsumerStatefulWidget {
  final String clothId;

  const EditClothScreen({super.key, required this.clothId});

  @override
  ConsumerState<EditClothScreen> createState() => _EditClothScreenState();
}

class _EditClothScreenState extends ConsumerState<EditClothScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  ClothCategory _category = ClothCategory.top;
  String _color = 'black';
  ClothStyle _style = ClothStyle.casual;
  ClothWeather _weather = ClothWeather.cool;

  ClothModel? _cloth;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCloth();
  }

  Future<void> _loadCloth() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final cloth = await ref
        .read(clothRepositoryProvider)
        .watchCloth(user.uid, widget.clothId)
        .first;

    if (cloth != null && mounted) {
      setState(() {
        _cloth = cloth;
        _nameController.text = cloth.name;
        _category = cloth.category;
        _color = cloth.color;
        _style = cloth.styles.first;
        _weather = cloth.weather;
        _loading = false;
      });
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final data = {
      'name': _nameController.text.trim(),
      'category': _category.value,
      'color': _color,
      'styles': [_style.value],
      'weather': _weather.value,
    };

    final success = await ref.read(updateClothProvider.notifier).updateCloth(
          uid: user.uid,
          clothId: widget.clothId,
          data: data,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pakaian berhasil diperbarui.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingWidget());
    }

    if (_cloth == null) {
      return const Scaffold(
        body: ErrorWidgetPage(message: 'Pakaian tidak ditemukan.'),
      );
    }

    final updateState = ref.watch(updateClothProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Pakaian')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preview foto lama
                if (_cloth!.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _cloth!.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 16),

                // Nama
                TextFormField(
                  controller: _nameController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama pakaian wajib diisi';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Nama Pakaian',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Kategori
                const Text('Kategori',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ClothCategory.values.map((cat) {
                    return ChoiceChip(
                      label: Text(cat.label),
                      selected: _category == cat,
                      onSelected: (_) => setState(() => _category = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Warna
                const Text('Warna',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in AppConstants.clothColors.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _color == entry.key,
                        onSelected: (_) => setState(() => _color = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Gaya
                const Text('Gaya',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ClothStyle.values.map((s) {
                    return ChoiceChip(
                      label: Text(s.label),
                      selected: _style == s,
                      onSelected: (_) => setState(() => _style = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Cuaca
                const Text('Cuaca',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ClothWeather.values.map((w) {
                    return ChoiceChip(
                      label: Text(w.label),
                      selected: _weather == w,
                      onSelected: (_) => setState(() => _weather = w),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: 'Simpan Perubahan',
                  onPressed: updateState.isLoading ? null : _save,
                  isLoading: updateState.isLoading,
                  icon: Icons.check,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
