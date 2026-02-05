// Archivo: lib/features/store/presentation/views/store_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/ui/widgets/page_title.dart';
import 'package:botslode/features/store/domain/models/store_product.dart';
import 'package:botslode/features/store/presentation/widgets/product_card.dart';

class StoreView extends ConsumerWidget {
  static const String routeName = 'store';

  const StoreView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = StoreProduct.catalog;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Grid de productos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categorías
                  _buildCategories(),
                  const SizedBox(height: 24),
                  
                  // Grid de productos
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return ProductCard(product: products[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Título con icono
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.store,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TIENDA',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Oxanium',
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'Potencia tus bots con addons premium',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 12,
                      fontFamily: 'Oxanium',
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const Spacer(),
          
          // Buscador (placeholder)
          Container(
            width: 250,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderGlass),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(
                  Icons.search,
                  color: AppColors.textSecondary.withOpacity(0.4),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Oxanium',
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.4),
                        fontFamily: 'Oxanium',
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Row(
      children: [
        _categoryChip('TODOS', true),
        const SizedBox(width: 12),
        ...ProductCategory.values.map((cat) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _categoryChip(cat.displayName, false, cat.color),
        )),
      ],
    );
  }

  Widget _categoryChip(String label, bool isActive, [Color? color]) {
    final chipColor = color ?? AppColors.textSecondary;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? chipColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? chipColor.withOpacity(0.4) : AppColors.borderGlass,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? chipColor : AppColors.textSecondary.withOpacity(0.6),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          fontFamily: 'Oxanium',
        ),
      ),
    );
  }
}
