import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'menu_vm.dart'; // 确保导入 MenuViewModel

class FavoriteButton extends StatelessWidget {
  final String filePath;

  const FavoriteButton({
    Key? key,
    required this.filePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MenuViewModel>(context);

    return IconButton(
      icon: Icon(
        viewModel.getIsFavorited(filePath) ? Icons.favorite : Icons.favorite_border,
        color: viewModel.getIsFavorited(filePath) ? Colors.red : null,
      ),
      onPressed: () {
        viewModel.toggleFavorite(filePath);
      },
    );
  }
}