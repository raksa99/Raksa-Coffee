import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/local_database.dart';
import '../../../../core/network/supabase_service.dart';
import '../../data/datasources/local_menu_datasource.dart';
import '../../domain/models/modifier.dart';
import '../../domain/models/product.dart';
import '../bloc/menu_bloc.dart';
import '../bloc/menu_event.dart';

class AddProductDialog extends StatefulWidget {
  final List<String> existingCategories;

  const AddProductDialog({super.key, required this.existingCategories});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();

  String? _selectedCategory;
  bool _isCreatingNewCategory = false;

  // Picked image state variables
  XFile? _pickedImage;
  bool _isUploadingImage = false;

  // Selected modifier templates checklist
  final Map<String, bool> _modifierSelections = {
    'Size': false,
    'Milk Options': false,
    'Sweetness Level': false,
    'Coffee Add-ons': false,
    'Serving Temperature': false,
    'Extra Spreads': false,
  };

  @override
  void initState() {
    super.initState();
    // Pre-select first category that is not 'All'
    final filteredCats = widget.existingCategories.where((c) => c != 'All').toList();
    if (filteredCats.isNotEmpty) {
      _selectedCategory = filteredCats.first;
    } else {
      _isCreatingNewCategory = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final finalCategory = _isCreatingNewCategory 
        ? _newCategoryController.text.trim() 
        : _selectedCategory!;
        
    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    
    String? finalImageUrl;

    // 1. If a local file was picked, upload it to Supabase Storage
    if (_pickedImage != null) {
      if (!SupabaseService.isConfigured) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supabase is not configured. Local image upload requires Supabase credentials.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isUploadingImage = true;
      });

      try {
        finalImageUrl = await SupabaseService.uploadProductImage(_pickedImage!);
        if (finalImageUrl == null) {
          throw Exception('Image upload returned null. Check that your Supabase "product-images" storage bucket exists and is public.');
        }
      } catch (e) {
        setState(() {
          _isUploadingImage = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } else {
      final inputUrl = _imageUrlController.text.trim();
      finalImageUrl = inputUrl.isEmpty ? null : inputUrl;
    }

    // Assemble selected modifier groups based on checkboxes
    final List<ModifierGroup> selectedGroups = [];
    if (_modifierSelections['Size'] == true) selectedGroups.add(LocalMenuDatasource.sizeGroup);
    if (_modifierSelections['Milk Options'] == true) selectedGroups.add(LocalMenuDatasource.milkGroup);
    if (_modifierSelections['Sweetness Level'] == true) selectedGroups.add(LocalMenuDatasource.sweetnessGroup);
    if (_modifierSelections['Coffee Add-ons'] == true) selectedGroups.add(LocalMenuDatasource.coffeeAddonsGroup);
    if (_modifierSelections['Serving Temperature'] == true) selectedGroups.add(LocalMenuDatasource.heatingGroup);
    if (_modifierSelections['Extra Spreads'] == true) selectedGroups.add(LocalMenuDatasource.pastryAddonsGroup);

    final newProduct = Product(
      id: 'p_${const Uuid().v4().substring(0, 8)}',
      name: name,
      description: description,
      basePrice: price,
      category: finalCategory,
      imageUrl: finalImageUrl,
      isAvailable: true,
      modifierGroups: selectedGroups,
    );

    try {
      // Append to local database products cache list
      final currentProducts = LocalDatabase.getProducts();
      final updatedList = [...currentProducts, newProduct];
      await LocalDatabase.saveProducts(updatedList);

      // Upload to Supabase cloud table if configured
      if (SupabaseService.isConfigured) {
        await SupabaseService.pushProduct(newProduct);
      }

      // Trigger Bloc refresh
      if (mounted) {
        context.read<MenuBloc>().add(LoadMenu());
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product "$name" added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = widget.existingCategories.where((c) => c != 'All').toList();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add New Menu Item',
                      style: theme.textTheme.headlineMedium,
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Product Name *',
                            hintText: 'e.g. Iced Coconut Espresso',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a product name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Item description
                        TextFormField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'e.g. Silky double shot poured over cold fresh coconut juice',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // Base price & Category dropdown row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Base Price
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                decoration: const InputDecoration(
                                  labelText: 'Base Price (USD) *',
                                  hintText: 'e.g. 3.50',
                                  prefixText: '\$ ',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid price';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Category Selector
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _isCreatingNewCategory ? null : _selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category *',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  ...categories.map((cat) => DropdownMenuItem(
                                        value: cat,
                                        child: Text(cat),
                                      )),
                                  const DropdownMenuItem(
                                    value: '__new_category__',
                                    child: Row(
                                      children: [
                                        Icon(Icons.add, size: 16, color: Colors.amber),
                                        SizedBox(width: 4),
                                        Text('New Category', style: TextStyle(color: Colors.amber)),
                                      ],
                                    ),
                                  )
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    if (val == '__new_category__') {
                                      _isCreatingNewCategory = true;
                                    } else {
                                      _isCreatingNewCategory = false;
                                      _selectedCategory = val;
                                    }
                                  });
                                },
                                validator: (_) {
                                  if (!_isCreatingNewCategory && _selectedCategory == null) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        
                        // Inline text field for new category creation
                        if (_isCreatingNewCategory) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _newCategoryController,
                            decoration: const InputDecoration(
                              labelText: 'New Category Name *',
                              hintText: 'e.g. Coconut Drinks',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (_isCreatingNewCategory && (value == null || value.trim().isEmpty)) {
                                  return 'Please enter new category name';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Product Image Picker Selector
                        Text(
                          'Product Image',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1A18) : const Color(0xFFF3EFE9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_pickedImage == null) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _pickImage,
                                        icon: const Icon(Icons.image_outlined),
                                        label: const Text('Import Image from File'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Center(
                                  child: Text(
                                    'OR',
                                    style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _imageUrlController,
                                  decoration: const InputDecoration(
                                    labelText: 'Paste Image URL instead',
                                    hintText: 'https://images.unsplash.com/...',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _pickedImage!.path,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 50),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _pickedImage!.name,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const Text(
                                            'Selected from local files',
                                            style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _pickedImage = null;
                                        });
                                      },
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Modifier presets checklist
                        Text(
                          'Configure Modifier Options',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1A18) : const Color(0xFFF3EFE9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2D2927) : const Color(0xFFEADFD3),
                            ),
                          ),
                          child: Column(
                            children: _modifierSelections.keys.map((groupName) {
                              return CheckboxListTile(
                                title: Text(groupName, style: const TextStyle(fontSize: 14)),
                                value: _modifierSelections[groupName],
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                activeColor: theme.colorScheme.primary,
                                onChanged: (val) {
                                  setState(() {
                                    _modifierSelections[groupName] = val ?? false;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isUploadingImage ? null : _saveProduct,
                        child: _isUploadingImage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Add to Menu'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
