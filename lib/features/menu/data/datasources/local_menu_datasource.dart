import '../../../../core/network/local_database.dart';
import '../../domain/models/modifier.dart';
import '../../domain/models/product.dart';

class LocalMenuDatasource {
  // Common modifier groups
  static const ModifierGroup sizeGroup = ModifierGroup(
    id: 'size',
    name: 'Size',
    isRequired: true,
    allowMultiple: false,
    options: [
      ModifierOption(id: 's_small', name: 'Small', price: 0.0),
      ModifierOption(id: 's_medium', name: 'Medium', price: 0.50),
      ModifierOption(id: 's_large', name: 'Large', price: 1.00),
    ],
  );

  static const ModifierGroup milkGroup = ModifierGroup(
    id: 'milk',
    name: 'Milk Options',
    isRequired: true,
    allowMultiple: false,
    options: [
      ModifierOption(id: 'm_whole', name: 'Whole Milk', price: 0.0),
      ModifierOption(id: 'm_oat', name: 'Oat Milk', price: 0.80),
      ModifierOption(id: 'm_almond', name: 'Almond Milk', price: 0.80),
      ModifierOption(id: 'm_coconut', name: 'Coconut Milk', price: 0.80),
    ],
  );

  static const ModifierGroup sweetnessGroup = ModifierGroup(
    id: 'sweetness',
    name: 'Sweetness Level',
    isRequired: true,
    allowMultiple: false,
    options: [
      ModifierOption(id: 'sw_100', name: '100% (Standard)', price: 0.0),
      ModifierOption(id: 'sw_50', name: '50% (Less Sweet)', price: 0.0),
      ModifierOption(id: 'sw_0', name: '0% (Sugar-Free)', price: 0.0),
    ],
  );

  static const ModifierGroup coffeeAddonsGroup = ModifierGroup(
    id: 'coffee_addons',
    name: 'Coffee Add-ons',
    isRequired: false,
    allowMultiple: true,
    options: [
      ModifierOption(id: 'ad_shot', name: 'Extra Espresso Shot', price: 1.20),
      ModifierOption(id: 'ad_whipped', name: 'Whipped Cream', price: 0.50),
      ModifierOption(id: 'ad_caramel', name: 'Caramel Drizzle', price: 0.60),
      ModifierOption(id: 'ad_vanilla', name: 'Vanilla Syrup', price: 0.60),
    ],
  );

  static const ModifierGroup heatingGroup = ModifierGroup(
    id: 'heating',
    name: 'Serving Temperature',
    isRequired: true,
    allowMultiple: false,
    options: [
      ModifierOption(id: 'h_warm', name: 'Warm Up', price: 0.0),
      ModifierOption(id: 'h_asis', name: 'Serve As Is', price: 0.0),
    ],
  );

  static const ModifierGroup pastryAddonsGroup = ModifierGroup(
    id: 'pastry_addons',
    name: 'Extra Spreads',
    isRequired: false,
    allowMultiple: true,
    options: [
      ModifierOption(id: 'pa_butter', name: 'Butter Portion', price: 0.40),
      ModifierOption(id: 'pa_jam', name: 'Strawberry Jam', price: 0.50),
      ModifierOption(id: 'pa_cream', name: 'Cream Cheese', price: 0.80),
    ],
  );

  // Initial mockup products with real Unsplash images
  static final List<Product> _defaultProducts = [
    // ESPRESSO CATEGORY
    const Product(
      id: 'p_espresso',
      name: 'Espresso',
      description: 'Rich, concentrated shot of our signature house espresso blend.',
      basePrice: 2.80,
      category: 'Espresso',
      imageUrl: 'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=400&q=80',
      isAvailable: true,
      modifierGroups: [
        ModifierGroup(
          id: 'size_espresso',
          name: 'Shots',
          isRequired: true,
          options: [
            ModifierOption(id: 'es_single', name: 'Single Shot', price: 0.0),
            ModifierOption(id: 'es_double', name: 'Double Shot', price: 1.00),
          ],
        )
      ],
    ),
    const Product(
      id: 'p_caffe_latte',
      name: 'Caffè Latte',
      description: 'Double espresso balanced with silky steamed milk and thin foam.',
      basePrice: 4.20,
      category: 'Espresso',
      imageUrl: 'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=400&q=80',
      isAvailable: true,
      modifierGroups: [sizeGroup, milkGroup, sweetnessGroup, coffeeAddonsGroup],
    ),
    const Product(
      id: 'p_cappuccino',
      name: 'Cappuccino',
      description: 'Classic double espresso topped with equal parts steamed milk and airy foam.',
      basePrice: 4.20,
      category: 'Espresso',
      imageUrl: 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400&q=80',
      isAvailable: true,
      modifierGroups: [sizeGroup, milkGroup, sweetnessGroup, coffeeAddonsGroup],
    ),
    const Product(
      id: 'p_cortado',
      name: 'Cortado',
      description: 'Equal parts double espresso and warm steamed milk.',
      basePrice: 3.80,
      category: 'Espresso',
      imageUrl: 'https://images.unsplash.com/photo-1534778101976-62847782c213?w=400&q=80',
      isAvailable: true,
      modifierGroups: [milkGroup, sweetnessGroup],
    ),
    const Product(
      id: 'p_americano',
      name: 'Caffè Americano',
      description: 'Double espresso diluted with hot water for a smooth, bold brew.',
      basePrice: 3.50,
      category: 'Espresso',
      imageUrl: 'https://images.unsplash.com/photo-1551046713-247c676906b5?w=400&q=80',
      isAvailable: true,
      modifierGroups: [sizeGroup, sweetnessGroup, coffeeAddonsGroup],
    ),

    // BREW CATEGORY
    const Product(
      id: 'p_v60',
      name: 'V60 Pour Over',
      description: 'Hand-brewed filter coffee showcasing single-origin bean flavor profiles.',
      basePrice: 4.80,
      category: 'Brew',
      imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400&q=80',
      isAvailable: true,
      modifierGroups: [
        ModifierGroup(
          id: 'origin_v60',
          name: 'Bean Origin',
          isRequired: true,
          options: [
            ModifierOption(id: 'bo_ethiopia', name: 'Ethiopia Yirgacheffe (Floral)', price: 0.0),
            ModifierOption(id: 'bo_colombia', name: 'Colombia Geisha (Fruity)', price: 1.50),
            ModifierOption(id: 'bo_sumatra', name: 'Sumatra Mandheling (Earthy)', price: 0.0),
          ],
        )
      ],
    ),
    const Product(
      id: 'p_cold_brew',
      name: 'Signature Cold Brew',
      description: 'Steeped for 18 hours in cold water. Smooth, sweet, and low in acidity.',
      basePrice: 4.50,
      category: 'Brew',
      imageUrl: 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=400&q=80',
      isAvailable: true,
      modifierGroups: [sizeGroup, sweetnessGroup, coffeeAddonsGroup],
    ),
    const Product(
      id: 'p_nitro_brew',
      name: 'Nitro Cold Brew',
      description: 'Our signature cold brew infused with nitrogen for a rich, creamy head.',
      basePrice: 5.00,
      category: 'Brew',
      imageUrl: 'https://images.unsplash.com/photo-1595981267035-7b04ca84a82d?w=400&q=80',
      isAvailable: true,
      modifierGroups: [sweetnessGroup],
    ),

    // NON-COFFEE CATEGORY
    const Product(
      id: 'p_matcha_latte',
      name: 'Ceremonial Matcha Latte',
      description: 'Whisked organic Japanese ceremonial matcha paired with creamy milk.',
      basePrice: 4.80,
      category: 'Non-Coffee',
      imageUrl: 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=400&q=80',
      isAvailable: true,
      modifierGroups: [sizeGroup, milkGroup, sweetnessGroup],
    ),
    const Product(
      id: 'p_chai_latte',
      name: 'Masala Chai Latte',
      description: 'Spiced black tea concentrate steamed with milk and dusted with cinnamon.',
      basePrice: 4.60,
      category: 'Non-Coffee',
      imageUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=400&q=80',
      isAvailable: true,
      modifierGroups: [sizeGroup, milkGroup, sweetnessGroup],
    ),
    const Product(
      id: 'p_hot_chocolate',
      name: 'Valrhona Chocolate',
      description: 'Rich, melted Valrhona dark chocolate steamed with velvety milk.',
      basePrice: 4.50,
      category: 'Non-Coffee',
      imageUrl: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=400&q=80',
      isAvailable: true,
      modifierGroups: [sizeGroup, milkGroup, coffeeAddonsGroup],
    ),
    const Product(
      id: 'p_water',
      name: 'Water',
      description: 'Refreshing pure mineral bottled water.',
      basePrice: 0.10,
      category: 'Non-Coffee',
      imageUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=400&q=80',
      isAvailable: true,
      modifierGroups: [],
    ),

    // PASTRIES CATEGORY
    const Product(
      id: 'p_croissant_almond',
      name: 'Butter Almond Croissant',
      description: 'Flaky pastry filled with rich almond cream and topped with sliced almonds.',
      basePrice: 3.90,
      category: 'Pastries',
      imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400&q=80',
      isAvailable: true,
      modifierGroups: [heatingGroup, pastryAddonsGroup],
    ),
    const Product(
      id: 'p_muffin_blueberry',
      name: 'Blueberry Streusel Muffin',
      description: 'Moist muffin packed with wild blueberries, finished with brown sugar streusel.',
      basePrice: 3.50,
      category: 'Pastries',
      imageUrl: 'https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=400&q=80',
      isAvailable: true,
      modifierGroups: [heatingGroup, pastryAddonsGroup],
    ),
    const Product(
      id: 'p_avocado_toast',
      name: 'Avocado Sourdough Toast',
      description: 'Fresh smashed avocado on rustic sourdough toast, seasoned with sea salt.',
      basePrice: 6.50,
      category: 'Pastries',
      imageUrl: 'https://images.unsplash.com/photo-1541532713592-79a0317b6b77?w=400&q=80',
      isAvailable: true,
      modifierGroups: [
        ModifierGroup(
          id: 'toast_addons',
          name: 'Toast Toppings',
          isRequired: false,
          allowMultiple: true,
          options: [
            ModifierOption(id: 'tt_egg', name: 'Poached Egg', price: 1.50),
            ModifierOption(id: 'tt_salmon', name: 'Smoked Salmon', price: 3.00),
            ModifierOption(id: 'tt_feta', name: 'Feta Cheese crumble', price: 1.00),
          ],
        )
      ],
    ),
  ];

  Future<List<Product>> getProducts() async {
    final cached = LocalDatabase.getProducts();
    // Upgrade cache automatically if it holds the older format or lacks new seed items
    if (cached.isEmpty || cached.any((p) => p.imageUrl == null) || !cached.any((p) => p.id == 'p_water')) {
      await LocalDatabase.saveProducts(_defaultProducts);
      return _defaultProducts;
    }
    return cached;
  }

  Future<List<String>> getCategories() async {
    final products = await getProducts();
    final categories = products.map((e) => e.category).toSet().toList();
    return categories;
  }
}
