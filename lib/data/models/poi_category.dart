import 'package:flutter/material.dart';

class PoiCategory {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final String queryFilter;

  const PoiCategory({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.queryFilter,
  });

  static const List<PoiCategory> categories = [
    PoiCategory(
      id: 'health',
      label: 'Y tế & Bệnh viện',
      description: 'Bệnh viện, Phòng khám, Nhà thuốc, Bác sĩ',
      icon: Icons.local_hospital,
      color: Colors.red,
      queryFilter:
          'nwr["amenity"~"hospital|pharmacy|clinic"](around:{radius},{lat},{lon});'
          'nwr["healthcare"~"hospital|clinic|doctor|pharmacy"](around:{radius},{lat},{lon});',
    ),
    PoiCategory(
      id: 'school',
      label: 'Giáo dục & Trường học',
      description: 'Trường học, Mầm non, Đại học, Trung tâm đào tạo',
      icon: Icons.school,
      color: Colors.orange,
      queryFilter:
          'nwr["amenity"="school"](around:{radius},{lat},{lon});',
    ),
    PoiCategory(
      id: 'food',
      label: 'Cafe & Ẩm thực',
      description: 'Nhà hàng, Quán cafe, Quán ăn nhanh, Trà sữa',
      icon: Icons.restaurant,
      color: Colors.brown,
      queryFilter:
          'nwr["amenity"~"cafe|restaurant|fast_food"](around:{radius},{lat},{lon});',
    ),
    PoiCategory(
      id: 'bank',
      label: 'Ngân hàng & ATM',
      description: 'Chi nhánh ngân hàng, Cây ATM tự động',
      icon: Icons.account_balance,
      color: Colors.green,
      queryFilter:
          'nwr["amenity"~"bank|atm"](around:{radius},{lat},{lon});',
    ),
    PoiCategory(
      id: 'shop',
      label: 'Chợ & Siêu thị',
      description: 'Siêu thị, Chợ truyền thống, Cửa hàng tiện lợi, TTM',
      icon: Icons.shopping_cart,
      color: Colors.purple,
      queryFilter:
          'nwr["amenity"="marketplace"](around:{radius},{lat},{lon});'
          'nwr["shop"~"supermarket|convenience|mall|bakery"](around:{radius},{lat},{lon});',
    ),
  ];

  static PoiCategory getCategoryById(String type) {
    switch (type) {
      case 'school':
        return categories[1];
      case 'hospital':
      case 'pharmacy':
      case 'clinic':
      case 'doctor':
      case 'health':
        return categories[0];
      case 'cafe':
      case 'restaurant':
      case 'fast_food':
      case 'food':
        return categories[2];
      case 'bank':
      case 'atm':
        return categories[3];
      case 'marketplace':
      case 'supermarket':
      case 'convenience':
      case 'mall':
      case 'shop':
        return categories[4];
      default:
        return const PoiCategory(
          id: 'other',
          label: 'Khác',
          description: 'Các tiện ích công cộng khác',
          icon: Icons.place,
          color: Colors.grey,
          queryFilter: '',
        );
    }
  }
}