import 'package:flutter/material.dart';

class ExpenseCategory {
  const ExpenseCategory(this.name, this.icon);

  final String name;
  final IconData icon;
}

const expenseCategories = [
  ExpenseCategory('Transporte', Icons.directions_car_outlined),
  ExpenseCategory('Alimentación', Icons.restaurant_outlined),
  ExpenseCategory('Hospedaje', Icons.hotel_outlined),
  ExpenseCategory('Tiquetes', Icons.flight_outlined),
  ExpenseCategory('Papelería', Icons.description_outlined),
  ExpenseCategory('Otros', Icons.receipt_long_outlined),
];

IconData iconForCategory(String category) {
  final match = expenseCategories.where(
    (c) => c.name.toLowerCase() == category.trim().toLowerCase(),
  );
  return match.isEmpty ? Icons.receipt_long_outlined : match.first.icon;
}
