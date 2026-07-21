import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:dali_cash/features/home/home_page.dart';
import 'package:dali_cash/features/mine/mine_page.dart';
import 'package:dali_cash/features/progress/progress_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'main_controller.dart';

class MainShellPage extends GetView<MainController> {
  const MainShellPage({super.key});
  static const _pages = <Widget>[HomePage(), ProgressPage(), MinePage()];

  static const _items = <_TabItemData>[
    _TabItemData(
      id: 'home',
      label: 'Home',
      selectedAsset: AppAssets.tabHomeSelected,
      unselectedAsset: AppAssets.tabHomeUnselected,
      iconSize: Size(24, 24),
    ),
    _TabItemData(
      id: 'progress',
      label: 'progress',
      selectedAsset: AppAssets.tabProgressSelected,
      unselectedAsset: AppAssets.tabProgressUnselected,
      iconSize: Size(24, 24),
    ),
    _TabItemData(
      id: 'mine',
      label: 'Mine',
      selectedAsset: AppAssets.tabMineSelected,
      unselectedAsset: AppAssets.tabMineUnselected,
      iconSize: Size(24, 24),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: _pages,
        ),
        bottomNavigationBar: _DaliTabBar(
          items: _items,
          selectedIndex: controller.selectedIndex.value,
          onSelected: controller.selectTab,
        ),
      ),
    );
  }
}

class _DaliTabBar extends StatelessWidget {
  const _DaliTabBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_TabItemData> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.divider,
            width: ScreenAdapter.height(1),
          ),
        ),
      ),
      child: SizedBox(
        height: ScreenAdapter.height(49) + bottomInset,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == selectedIndex;

              return Expanded(
                child: InkWell(
                  key: Key('tab-${item.id}'),
                  onTap: () => onSelected(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        isSelected ? item.selectedAsset : item.unselectedAsset,
                        key: isSelected ? Key('tab-${item.id}-selected') : null,
                        width: ScreenAdapter.width(item.iconSize.width),
                        height: ScreenAdapter.height(item.iconSize.height),
                      ),
                      SizedBox(height: ScreenAdapter.height(2)),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.tabUnselected,
                          fontSize: ScreenAdapter.font(12),
                          fontWeight: FontWeight.w400,
                          height: 17 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabItemData {
  const _TabItemData({
    required this.id,
    required this.label,
    required this.selectedAsset,
    required this.unselectedAsset,
    required this.iconSize,
  });

  final String id;
  final String label;
  final String selectedAsset;
  final String unselectedAsset;
  final Size iconSize;
}
