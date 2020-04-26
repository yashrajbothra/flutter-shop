import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/cart.dart';
import 'package:shop/providers/products.dart';

class CartItem extends StatelessWidget {
  final String id;
  final String pId;
  final String imageUrl;
  final double price;
  final int quantity;
  final String title;

  CartItem(
    this.id,
    this.pId,
    this.price,
    this.quantity,
    this.title,
    this.imageUrl,
  );
  @override
  Widget build(BuildContext context) {
    final product = Provider.of<Products>(context, listen: false);
    return Dismissible(
      key: ValueKey(id),
      background: Container(
        color: Theme.of(context).accentColor,
        child: Icon(
          Icons.favorite,
          color: Colors.white,
          size: 40,
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20),
      ),
      secondaryBackground: Container(
        color: Theme.of(context).errorColor,
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: 40,
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart)
          Provider.of<Cart>(context, listen: false).removeItem(id);
        else {
          product.findById(pId).isFavorite = true;
          Provider.of<Cart>(context, listen: false).removeItem(id);
        }
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final bool res = await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                    title: Text('Are you Sure?'),
                    content: Text(
                      'Do you want to remove the item from cart?',
                    ),
                    actions: <Widget>[
                      FlatButton(
                        child: Text("No"),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      FlatButton(
                        child: Text("Yes"),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  ));
          return res;
        } else {
          return true;
        }
      },
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 4,
        ),
        child: ListTile(
          leading: Image.network(
            imageUrl,
            width: 100,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          title: Text(title),
          subtitle: Text('Total : \$${price * quantity}'),
          trailing: Text('$quantity x'),
        ),
      ),
    );
  }
}
