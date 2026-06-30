import 'package:flutter/material.dart';
import '../../domain/models/cart_item.dart';
import 'cart_item_tile.dart';

class AnimatedCartList extends StatefulWidget {
  final List<CartItem> items;
  final Function(CartItem, int) onQuantityChanged;
  final Function(CartItem) onRemove;

  const AnimatedCartList({
    super.key,
    required this.items,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  State<AnimatedCartList> createState() => _AnimatedCartListState();
}

class _AnimatedCartListState extends State<AnimatedCartList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<CartItem> _items = [];

  @override
  void initState() {
    super.initState();
    _items.addAll(widget.items);
  }

  @override
  void didUpdateWidget(covariant AnimatedCartList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncLists();
  }

  void _syncLists() {
    setState(() {
      final oldList = List<CartItem>.from(_items);
      final newList = widget.items;

      // Handle full clear
      if (newList.isEmpty && oldList.isNotEmpty) {
        for (int i = oldList.length - 1; i >= 0; i--) {
          final removedItem = oldList[i];
          _listKey.currentState?.removeItem(
            i,
            (context, animation) => _buildRemovedItem(removedItem, animation),
            duration: const Duration(milliseconds: 220),
          );
        }
        _items.clear();
        return;
      }

      // Alignment and diffing loop
      int oldIdx = 0;
      int newIdx = 0;

      while (newIdx < newList.length || oldIdx < oldList.length) {
        if (oldIdx >= oldList.length) {
          // Remaining are additions
          final item = newList[newIdx];
          _items.insert(newIdx, item);
          _listKey.currentState?.insertItem(newIdx, duration: const Duration(milliseconds: 220));
          newIdx++;
        } else if (newIdx >= newList.length) {
          // Remaining are removals
          final removedItem = oldList[oldIdx];
          _items.removeAt(newIdx); // removing from target index
          _listKey.currentState?.removeItem(
            newIdx,
            (context, animation) => _buildRemovedItem(removedItem, animation),
            duration: const Duration(milliseconds: 220),
          );
          oldIdx++;
        } else if (oldList[oldIdx].id == newList[newIdx].id) {
          // Same item: update internal reference in case quantity/modifiers changed
          _items[newIdx] = newList[newIdx];
          oldIdx++;
          newIdx++;
        } else {
          // Mismatch: see if oldList[oldIdx] exists later in newList (meaning newList inserted item)
          final existsLater = newList.skip(newIdx).any((item) => item.id == oldList[oldIdx].id);
          if (existsLater) {
            // Inserted at newIdx
            final item = newList[newIdx];
            _items.insert(newIdx, item);
            _listKey.currentState?.insertItem(newIdx, duration: const Duration(milliseconds: 220));
            newIdx++;
          } else {
            // Removed from oldIdx
            final removedItem = oldList[oldIdx];
            _items.removeAt(newIdx);
            _listKey.currentState?.removeItem(
              newIdx,
              (context, animation) => _buildRemovedItem(removedItem, animation),
              duration: const Duration(milliseconds: 220),
            );
            oldIdx++;
          }
        }
      }
    });
  }

  Widget _buildRemovedItem(CartItem item, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: CartItemTile(
          item: item,
          onQuantityChanged: (_) {},
          onRemove: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedList(
      key: _listKey,
      initialItemCount: _items.length,
      itemBuilder: (context, index, animation) {
        // Guard index in case list sync is in progress
        if (index >= _items.length) return const SizedBox.shrink();
        final item = _items[index];
        return SizeTransition(
          sizeFactor: animation,
          child: FadeTransition(
            opacity: animation,
            child: CartItemTile(
              item: item,
              onQuantityChanged: (q) => widget.onQuantityChanged(item, q),
              onRemove: () => widget.onRemove(item),
            ),
          ),
        );
      },
    );
  }
}
