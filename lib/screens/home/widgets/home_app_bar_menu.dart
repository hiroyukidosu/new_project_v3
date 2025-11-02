// lib/screens/home/widgets/home_app_bar_menu.dart
// AppBarのメニューボタンを分離

import 'package:flutter/material.dart';

/// AppBarのメニューボタンウィジェット
class HomeAppBarMenu extends StatelessWidget {
  final VoidCallback onPurchaseStatus;
  final VoidCallback onPurchaseLink;
  final VoidCallback onBackup;

  const HomeAppBarMenu({
    super.key,
    required this.onPurchaseStatus,
    required this.onPurchaseLink,
    required this.onBackup,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'purchase_status':
            onPurchaseStatus();
            break;
          case 'set_purchase_link':
            onPurchaseLink();
            break;
          case 'backup':
            onBackup();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'purchase_status',
          child: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 8),
              Text('購入状態'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'set_purchase_link',
          child: const Row(
            children: [
              Icon(Icons.payment, color: Colors.green),
              SizedBox(width: 8),
              Text('課金情報'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'backup',
          child: const Row(
            children: [
              Icon(Icons.backup, color: Colors.orange),
              SizedBox(width: 8),
              Text('バックアップ'),
            ],
          ),
        ),
      ],
    );
  }
}

