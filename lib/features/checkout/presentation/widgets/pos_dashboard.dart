import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../../cart/presentation/widgets/cart_sidebar.dart';
import '../../../menu/presentation/bloc/menu_bloc.dart';
import '../../../menu/presentation/bloc/menu_state.dart';
import '../../../menu/presentation/widgets/add_product_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../menu/presentation/widgets/product_grid.dart';
import '../../../../core/network/local_database.dart';
import 'daily_dashboard.dart';

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

  void _showSettingsDialog() {
    final bakongIdController = TextEditingController(
      text: LocalDatabase.getSetting('bakong_account_id', 'raksa_coffee@usd'),
    );
    final merchantNameController = TextEditingController(
      text: LocalDatabase.getSetting('bakong_merchant_name', 'Raksa Coffee'),
    );
    final merchantCityController = TextEditingController(
      text: LocalDatabase.getSetting('bakong_merchant_city', 'Phnom Penh'),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bakong QR Settings'),
              IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Configure the account information used to compile the dynamic Bakong KHQR code on checkout.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bakongIdController,
                  decoration: const InputDecoration(
                    labelText: 'Bakong Account ID (or Mobile Number)',
                    helperText: 'e.g. raksa_coffee@usd or 012345678@usd',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: merchantNameController,
                  decoration: const InputDecoration(
                    labelText: 'Merchant Name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: merchantCityController,
                  decoration: const InputDecoration(
                    labelText: 'Merchant City',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                final messenger = ScaffoldMessenger.of(context);

                await LocalDatabase.saveSetting('bakong_account_id', bakongIdController.text.trim());
                await LocalDatabase.saveSetting('bakong_merchant_name', merchantNameController.text.trim());
                await LocalDatabase.saveSetting('bakong_merchant_city', merchantCityController.text.trim());
                
                // Automatically switch dynamic QR provider to Bakong since user is saving Bakong settings
                await LocalDatabase.saveSetting('qr_provider', 'bakong');

                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Bakong KHQR credentials saved successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save Settings'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 750;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.local_cafe, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'appTitle'.tr(context),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(width: 12),
            // Offline indicators
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi, size: 12, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'offlineCache'.tr(context),
                    style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: isMobile
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(
                  color: isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3),
                  height: 1,
                ),
              ),
        actions: [
          // Nav bar items (Counter vs Dashboard)
          TextButton.icon(
            onPressed: () => setState(() => _activeNavIndex = 0),
            icon: Icon(
              Icons.point_of_sale,
              color: _activeNavIndex == 0 ? theme.colorScheme.primary : theme.colorScheme.secondary,
            ),
            label: Text(
              'counter'.tr(context),
              style: TextStyle(
                color: _activeNavIndex == 0 ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                fontWeight: _activeNavIndex == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => setState(() => _activeNavIndex = 1),
            icon: Icon(
              Icons.analytics_outlined,
              color: _activeNavIndex == 1 ? theme.colorScheme.primary : theme.colorScheme.secondary,
            ),
            label: Text(
              'salesReport'.tr(context),
              style: TextStyle(
                color: _activeNavIndex == 1 ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
                fontWeight: _activeNavIndex == 1 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          
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

          // Settings button
          IconButton(
            onPressed: () => _showSettingsDialog(),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),

          // Language switcher
          TextButton(
            onPressed: widget.onLocaleToggled,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: theme.colorScheme.primary),
              ),
              child: Text(
                widget.activeLocale.languageCode.toUpperCase() == 'EN' ? 'KM' : 'EN',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Theme toggler
          IconButton(
            onPressed: widget.onThemeToggled,
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme Mode',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _activeNavIndex == 1
          ? const DailyDashboard()
          : (isMobile 
              ? _buildMobileLayout(context, theme, isDark) 
              : _buildTabletLayout(context, theme, isDark)),
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
                    // Open cart sidebar inside mobile bottom sheet
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) {
                        return DraggableScrollableSheet(
                          initialChildSize: 0.9,
                          minChildSize: 0.5,
                          maxChildSize: 1.0,
                          expand: false,
                          builder: (context, scrollController) {
                            return BlocProvider.value(
                              value: context.read<CartBloc>(),
                              child: const CartSidebar(),
                            );
                          },
                        );
                      },
                    );
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
}
