import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NeuBox extends StatelessWidget {
  final Widget child; // 子组件
  final double? height; // 可选的高度
  final double? width; // 可选的宽度
  final double bottomPadding; // 底部填充，用于增加下方空间

  const NeuBox({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.bottomPadding = 0, // 默认底部填充为 0
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height, // 如果设置了高度，则使用指定高度
      width: width, // 如果设置了宽度，则使用指定宽度
      padding: EdgeInsets.all(8), // 内边距
      child: Column( // 使用 Column 布局，以便在下方增加空间
        children: [
          Center(child: child), // 中心对齐的子组件
          SizedBox(height: bottomPadding), // 底部填充
        ],
      ),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade500,
            blurRadius: 15,
            offset: Offset(5, 5),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 15,
            offset: Offset(-5, -5),
          ),
        ],
      ),
    );
  }
}