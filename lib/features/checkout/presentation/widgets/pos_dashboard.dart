import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/network/local_database.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../cart/presentation/widgets/cart_sidebar.dart';
import '../../../menu/presentation/bloc/menu_bloc.dart';
import '../../../menu/presentation/bloc/menu_state.dart';
import '../../../menu/presentation/bloc/menu_event.dart';
import '../../../menu/presentation/widgets/add_product_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../menu/presentation/widgets/product_grid.dart';
import 'daily_dashboard.dart';
import '../../../../core/utils/animations.dart';

class PosDashboard extends StatefulWidget {
  final VoidCallback onThemeToggled;
  final bool isDarkMode;
  final VoidCallback onLocaleToggled;
  final Locale activeLocale;

  const PosDashboard({
    super.key,
    required this.onThemeToggled,
    required this.isDarkMode,
    required this.onLocaleToggled,
    required this.activeLocale,
  });

  @override
  State<PosDashboard> createState() => _PosDashboardState();
}

class _PosDashboardState extends State<PosDashboard> {
  int _activeNavIndex = 0; // 0 = POS Counter, 1 = Sales Report

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 750;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: (isDark ? const Color(0xFF0B0909) : const Color(0xFFFAF8F5)).withAlpha(210),
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.local_cafe_rounded, color: theme.colorScheme.primary, size: 24);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'appTitle'.tr(context),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                fontFamily: 'Outfit',
                fontSize: 18,
                color: isDark ? const Color(0xFFF5F0EC) : const Color(0xFF1F1511),
              ),
            ),
          ],
        ),
        bottom: isMobile
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: isDark ? const Color(0xFF2A2321) : const Color(0xFFE8DFD5),
                ),
              ),
        actions: [
          // Nav bar items (Counter vs Dashboard) - only show on desktop/tablet
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151211) : const Color(0xFFF4EFEA),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2321) : const Color(0xFFE8DFD5),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  _buildNavTab(
                    index: 0,
                    icon: Icons.point_of_sale_rounded,
                    label: 'counter'.tr(context),
                    theme: theme,
                  ),
                  const SizedBox(width: 4),
                  _buildNavTab(
                    index: 1,
                    icon: Icons.insights_rounded,
                    label: 'salesReport'.tr(context),
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          // Add product button
          IconButton(
            onPressed: () {
              final menuState = context.read<MenuBloc>().state;
              if (menuState is MenuLoaded) {
                showDialog(
                  context: context,
                  builder: (_) {
                    return BlocProvider.value(
                      value: context.read<MenuBloc>(),
                      child: AddProductDialog(
                        existingCategories: menuState.categories,
                      ),
                    );
                  },
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please wait for the menu to load.')),
                );
              }
            },
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'addMenuItem'.tr(context),
          ),
          const SizedBox(width: 8),

          // Language switcher
          ScaleBouncePressReaction(
            child: TextButton(
              onPressed: widget.onLocaleToggled,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.primary.withAlpha(100)),
                ),
                child: Text(
                  widget.activeLocale.languageCode.toUpperCase() == 'EN' ? 'KM' : 'EN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontFamily: 'Outfit',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Theme toggler
          ScaleBouncePressReaction(
            child: IconButton(
              onPressed: widget.onThemeToggled,
              icon: Icon(widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              tooltip: 'Toggle Theme Mode',
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<String>('${isMobile ? "m" : "d"}_$_activeNavIndex'),
            child: isMobile
                ? _buildMobileBody(context, theme, isDark)
                : (_activeNavIndex == 1 ? const DailyDashboard() : _buildTabletLayout(context, theme, isDark)),
          ),
        ),
      ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _activeNavIndex > 3 ? 0 : _activeNavIndex,
              onTap: (index) {
                setState(() {
                  _activeNavIndex = index;
                });
              },
              backgroundColor: isDark ? const Color(0xFF1C1816) : Colors.white,
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: theme.colorScheme.secondary,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.point_of_sale_outlined),
                  activeIcon: const Icon(Icons.point_of_sale),
                  label: 'counter'.tr(context),
                ),
                BottomNavigationBarItem(
                  icon: BlocBuilder<CartBloc, CartState>(
                    builder: (context, state) {
                      final count = state.items.fold(0, (sum, i) => sum + i.quantity);
                      if (count == 0) {
                        return const Icon(Icons.shopping_bag_outlined);
                      }
                      return Badge(
                        label: Text('$count'),
                        child: const Icon(Icons.shopping_bag),
                      );
                    },
                  ),
                  label: 'currentOrder'.tr(context),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.analytics_outlined),
                  activeIcon: const Icon(Icons.analytics),
                  label: 'salesReport'.tr(context),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.menu_outlined),
                  activeIcon: const Icon(Icons.menu),
                  label: 'more'.tr(context),
                ),
              ],
            )
          : null,
    );
  }

  // Tablet split screen layout (Landscape / Wide screen)
  Widget _buildTabletLayout(BuildContext context, ThemeData theme, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left product area
        const Expanded(
          flex: 5,
          child: ProductGrid(),
        ),
        
        // Right cart summary
        const Expanded(
          flex: 3,
          child: CartSidebar(),
        ),
      ],
    );
  }

  // Mobile layout body switching
  Widget _buildMobileBody(BuildContext context, ThemeData theme, bool isDark) {
    switch (_activeNavIndex) {
      case 1:
        return const CartSidebar();
      case 2:
        return const DailyDashboard();
      case 3:
        return _buildMobileMenuPanel(context, theme, isDark);
      case 0:
      default:
        return _buildMobileLayout(context, theme, isDark);
    }
  }

  // Mobile layout with a bottom cart sliding sheet drawer toggle
  Widget _buildMobileLayout(BuildContext context, ThemeData theme, bool isDark) {
    return Stack(
      children: [
        // Grid fills screen
        const Padding(
          padding: EdgeInsets.only(bottom: 72), // leave room for bottom action bar
          child: ProductGrid(),
        ),

        // Bottom drawer toggle bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state.items.isEmpty) return const SizedBox.shrink();
              final quantityCount = state.items.fold(0, (sum, i) => sum + i.quantity);

              return Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1A18) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Switch to Cart Tab directly
                    setState(() {
                      _activeNavIndex = 1;
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                            ),
                            child: Text(
                              '$quantityCount items',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'View Active Order',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        CurrencyFormatter.format(state.total),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Mobile More Settings & Functions Panel Layout
  Widget _buildMobileMenuPanel(BuildContext context, ThemeData theme, bool isDark) {
    final menuState = context.read<MenuBloc>().state;
    final isKhmer = widget.activeLocale.languageCode.toLowerCase() == 'km';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Shop Profile Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF38231A), const Color(0xFF261610)]
                    : [const Color(0xFFF7ECE1), const Color(0xFFEADFD3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? const Color(0xFF4A3326) : const Color(0xFFD6C5B3),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.local_cafe, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Raksa Coffee',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            SupabaseService.isConfigured ? 'Supabase Connected' : 'Local Sandbox Mode',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFA5968E) : const Color(0xFF705D53),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section Title
          Text(
            isKhmer ? 'មុខងារគ្រប់គ្រង' : 'Management & Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Menu Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.15,
            children: [
              // 1. Add product card
              _buildMenuCard(
                context,
                icon: Icons.add_circle_outline_rounded,
                iconColor: Colors.amber,
                title: 'addMenuItem'.tr(context),
                subtitle: isKhmer ? 'បន្ថែមមុខទំនិញថ្មី' : 'Insert new product',
                onTap: () {
                  if (menuState is MenuLoaded) {
                    showDialog(
                      context: context,
                      builder: (_) {
                        return BlocProvider.value(
                          value: context.read<MenuBloc>(),
                          child: AddProductDialog(
                            existingCategories: menuState.categories,
                          ),
                        );
                      },
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please wait for the menu to load.')),
                    );
                  }
                },
              ),

              // 2. Language switcher
              _buildMenuCard(
                context,
                icon: Icons.translate_rounded,
                iconColor: Colors.blueAccent,
                title: isKhmer ? 'English' : 'ភាសាខ្មែរ',
                subtitle: isKhmer ? 'Switch to English' : 'ប្តូរទៅភាសាខ្មែរ',
                onTap: widget.onLocaleToggled,
              ),

              // 3. Dark mode toggler
              _buildMenuCard(
                context,
                icon: widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                iconColor: Colors.purpleAccent,
                title: widget.isDarkMode 
                    ? (isKhmer ? 'របៀបពន្លឺ' : 'Light Mode')
                    : (isKhmer ? 'របៀបងងឹត' : 'Dark Mode'),
                subtitle: isKhmer ? 'ផ្លាស់ប្តូររូបរាង' : 'Toggle application theme',
                onTap: widget.onThemeToggled,
              ),

              // 4. ResetPOS/Clear box
              _buildMenuCard(
                context,
                icon: Icons.phonelink_erase_rounded,
                iconColor: Colors.redAccent,
                title: isKhmer ? 'សម្អាតប្រវត្តិ' : 'Reset POS History',
                subtitle: isKhmer ? 'លុបទិន្នន័យទាំងអស់' : 'Clear local transactions',
                onTap: () {
                  _showResetConfirmation(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E1A18) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? const Color(0xFFA5968E) : const Color(0xFF705D53),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    final isKhmer = widget.activeLocale.languageCode.toLowerCase() == 'km';
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isKhmer ? 'សម្អាតទិន្នន័យ POS' : 'Reset POS History'),
          content: Text(isKhmer 
              ? 'តើអ្នកប្រាកដជាចង់លុបទិន្នន័យការលក់ ផលិតផល និងការកំណត់ទាំងអស់មែនទេ? សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។'
              : 'Are you sure you want to clear all sales, products and setting history? This action is irreversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isKhmer ? 'បោះបង់' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await LocalDatabase.clearAllData();
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!context.mounted) return;
                context.read<MenuBloc>().add(LoadMenu());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isKhmer ? 'បានសម្អាតរួចរាល់' : 'POS Reset Successful'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(isKhmer ? 'យល់ព្រម' : 'Reset'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavTab({
    required int index,
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    final isSelected = _activeNavIndex == index;
    
    return InkWell(
      onTap: () => setState(() => _activeNavIndex = index),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
