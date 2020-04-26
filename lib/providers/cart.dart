import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CartItem {
  final String id;
  final String title;
  final int quantity;
  final double price;
  final String imageUrl;

  CartItem({
    @required this.id,
    @required this.title,
    @required this.quantity,
    @required this.price,
    @required this.imageUrl,
  });
}

class Cart with ChangeNotifier {
  final String token;
  final String userId;
  Cart(this.token, this._items, this.userId);
  Map<String, CartItem> _items = {};
  Map<String, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.length;
  }

  double get totalAmount {
    var total = 0.00;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  Future<void> fetchAndSetCart() async {
    final url = 'https://shop-aca25.firebaseio.com/cart/$userId.json?auth=$token';
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      CartItem newProduct;
      if (extractedData != null) {
        extractedData.forEach((prodId, prodData) {
          newProduct = CartItem(
            id: prodData['id'],
            title: prodData['title'],
            price: prodData['price'],
            quantity: prodData['quantity'],
            imageUrl: prodData['imageUrl'],
          );
          _items.putIfAbsent(
            prodId,
            () => newProduct,
          );
        });
        notifyListeners();
      }
    } catch (error) {
      throw (error);
    }
  }

  Future<void> addItem(
    String productId,
    double price,
    String title,
    String imageUrl,
  ) async {
    String key;
    int value;
    _items.forEach((id, val) {
      if (val.id == productId) {
        key = id;
        value = val.quantity + 1;
        return;
      }
    });
    if (_items.containsKey(key)) {
      var url = 'https://shop-aca25.firebaseio.com/cart/$userId/$key.json?auth=$token';
      try {
        await http.patch(
          url,
          body: json.encode({
            'quantity': value,
          }),
        );
        _items.update(
          key,
          (existingCartItem) => CartItem(
            id: existingCartItem.id,
            title: existingCartItem.title,
            price: existingCartItem.price,
            imageUrl: existingCartItem.imageUrl,
            quantity: existingCartItem.quantity + 1,
          ),
        );
      } catch (error) {
        throw error;
      }
    } else {
      final url = 'https://shop-aca25.firebaseio.com/cart/$userId.json?auth=$token';
      try {
        final res = await http.post(
          url,
          body: json.encode({
            'id': productId,
            'title': title,
            'price': price,
            'quantity': 1,
            'imageUrl': imageUrl,
          }),
        );
        final newProduct = CartItem(
          id: productId,
          title: title,
          price: price,
          quantity: 1,
          imageUrl: imageUrl,
        );
        _items.putIfAbsent(
          json.decode(res.body)['name'],
          () => newProduct,
        );
      } catch (error) {
        throw error;
      }
    }
    notifyListeners();
  }

  Future<void> removeItem(String cId) async {
    final url = 'https://shop-aca25.firebaseio.com/cart/$userId/$cId.json';
    var existingProduct;
    _items.forEach((id, val) {
      if (id == cId) existingProduct = val;
    });
    _items.remove(cId);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      final newProduct = CartItem(
        id: existingProduct.id,
        title: existingProduct.title,
        price: existingProduct.price,
        quantity: existingProduct.quantity,
        imageUrl: existingProduct.imageUrl,
      );
      _items.putIfAbsent(
        cId,
        () => newProduct,
      );
      notifyListeners();
      throw Exception("Could not Delete Products");
    }
    existingProduct = null;
  }

  void removeSingleItem(String pId) async {
    var cId;
    _items.forEach((id, val) {
      if (val.id == pId) cId = id;
    });
    final url = 'https://shop-aca25.firebaseio.com/cart/$userId/$cId.json';
    if (_items[cId].quantity > 1) {
      await http.patch(
        url,
        body: json.encode({
          'quantity': _items[cId].quantity - 1,
        }),
      );
      _items.update(
          cId,
          (existingItem) => CartItem(
                id: existingItem.id,
                imageUrl: existingItem.imageUrl,
                price: existingItem.price,
                quantity: existingItem.quantity - 1,
                title: existingItem.title,
              ));
    } else {
      final existingProduct = _items[cId];
      _items.remove(cId);
      final response = await http.delete(url);
      if (response.statusCode >= 400) {
        final newProduct = CartItem(
          id: existingProduct.id,
          title: existingProduct.title,
          price: existingProduct.price,
          quantity: existingProduct.quantity,
          imageUrl: existingProduct.imageUrl,
        );
        _items.putIfAbsent(
          cId,
          () => newProduct,
        );
      }
    }
    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }
}
