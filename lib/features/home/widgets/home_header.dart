import 'package:dali_cash/app/layout/screen_adapter.dart';
import 'package:dali_cash/app/navigation/navigation_helper.dart';
import 'package:dali_cash/app/resources/app_assets.dart';
import 'package:dali_cash/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, this.onCustomerServiceTap});

  final VoidCallback? onCustomerServiceTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ScreenAdapter.width(343),
      height: ScreenAdapter.height(40),
      child: Row(
        children: [
          SizedBox(width: ScreenAdapter.width(40)),
          Expanded(
            child: Center(
              child: Text(
                'Dali Cash',
                style: TextStyle(
                  color: AppColors.surface,
                  fontSize: ScreenAdapter.font(17),
                  fontWeight: FontWeight.w600,
                  height: 24 / 17,
                ),
              ),
            ),
          ),
          SizedBox(
            width: ScreenAdapter.width(40),
            height: ScreenAdapter.height(40),
            child: InkResponse(
              key: const Key('home-customer-service'),
              onTap: onCustomerServiceTap ?? _openCustomerService,
              radius: ScreenAdapter.width(24),
              child: Center(
                child: Image.asset(
                  AppAssets.homeCustomerService,
                  width: ScreenAdapter.width(24),
                  height: ScreenAdapter.height(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _openCustomerService() {
  NavigationHelper.toWebPath<void>(path: NavigationHelper.customerServicePath);
}
