// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_calls, deprecated_member_use, unused_local_variable

//-✅---------------------------------------------------------------------✅-//
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

class CommonShimmer {
  //-✅-----------OrderListShimmer----------------------------------------✅-//
  static Widget OrderListShimmer(BuildContext context, int value) {
    const double itemSize = 50.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;

        // 🔹 Responsive layout rules
        int itemsPerRow;
        if (screenWidth < 600) {
          itemsPerRow = 1; // mobile
        } else if (screenWidth < 1000) {
          itemsPerRow = 2; // tablet
        } else {
          itemsPerRow = 3; // desktop / web
        }

        final rowCount = (value / itemsPerRow).ceil();

        return ListView.separated(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 15, left: 8, right: 8),
          itemCount: rowCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, rowIndex) {
            List<Widget> rowItems = [];

            for (int i = 0; i < itemsPerRow; i++) {
              final itemIndex = rowIndex * itemsPerRow + i;
              if (itemIndex < value) {
                rowItems.add(
                  Expanded(
                    child: CommonWidget().buildStaggeredAnimation(
                      index: rowIndex,
                      child: Shimmer.fromColors(
                        baseColor: const Color(0xFFE0E0E0),
                        highlightColor: const Color(0xFFF5F5F5),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: GlobalAppColor.DarkTextColorCode,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // 🔹 Top Row (Order ID + Status)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CommonWidget().shimmerLine(
                                    width: 120,
                                    height: 16,
                                  ),
                                  Container(
                                    height: 16,
                                    width: 60,
                                    color: Colors.grey.shade300,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // 🔹 2 text lines
                              Container(
                                height: 14,
                                width: screenWidth * 0.5,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CommonWidget().shimmerLine(
                                    width: 120,
                                    height: 16,
                                  ),
                                  Container(
                                    height: 16,
                                    width: 60,
                                    color: Colors.grey.shade300,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 5),
                              Divider(
                                color: Colors.grey.shade300,
                                thickness: 0.3,
                              ),

                              // 🔹 order items
                              const SizedBox(height: 5),
                              Container(
                                height: 14,
                                width: screenWidth * 0.5,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 5),
                              Container(
                                height: 14,
                                width: screenWidth * 0.5,
                                color: Colors.grey.shade300,
                              ),

                              const SizedBox(height: 5),
                              Divider(
                                color: Colors.grey.shade300,
                                thickness: 0.3,
                              ),

                              // 🔹 subtotal
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    height: 14,
                                    width: 60,
                                    color: Colors.grey.shade300,
                                  ),
                                  Container(
                                    height: 14,
                                    width: 50,
                                    color: Colors.grey.shade300,
                                  ),
                                ],
                              ),

                              Divider(
                                color: Colors.grey.shade300,
                                thickness: 0.3,
                              ),

                              // 🔹 bottom buttons row (✅ Fixed Overflow)
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Button 1
                                  Expanded(
                                    child: Container(
                                      height: 35,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  // Button 2
                                  Expanded(
                                    child: Container(
                                      height: 35,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  // Icon Button (fixed width)
                                  Container(
                                    height: 35,
                                    width: 35,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  // Button 3
                                  Expanded(
                                    child: Container(
                                      height: 35,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                rowItems.add(const Expanded(child: SizedBox()));
              }
              if (i < itemsPerRow - 1) {
                rowItems.add(const SizedBox(width: 6));
              }
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rowItems,
            );
          },
        );
      },
    );
  }

  //-✅-----------CategoryListShimmer-------------------------------------✅-//
  static Widget CategoryListShimmer(BuildContext context, int value) {
    const double itemSize = 50.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // 🔹 Responsive items per row
        int itemsPerRow;
        if (screenWidth < 600) {
          itemsPerRow = 3;
        } else if (screenWidth < 1000) {
          itemsPerRow = 5;
        } else {
          itemsPerRow = 8;
        }

        final rowCount = (value / itemsPerRow).ceil(); // use `value` only

        return ListView.separated(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 15, left: 0, right: 0),
          itemCount: rowCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, rowIndex) {
            List<Widget> rowItems = [];

            for (int i = 0; i < itemsPerRow; i++) {
              final itemIndex = rowIndex * itemsPerRow + i;

              if (itemIndex < value) {
                rowItems.add(
                  Expanded(
                    child: CommonWidget().buildStaggeredAnimation(
                      index: rowIndex,
                      child: Shimmer.fromColors(
                        baseColor: const Color(0xFFE0E0E0),
                        highlightColor: const Color(0xFFF5F5F5),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: GlobalAppColor.DarkTextColorCode,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                height: itemSize,
                                width: itemSize,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(
                                    itemSize * 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              CommonWidget().shimmerLine(
                                width: 120,
                                height: 10,
                              ),
                              const SizedBox(height: 8),
                              CommonWidget().shimmerLine(
                                width: 120,
                                height: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                rowItems.add(const Expanded(child: SizedBox()));
              }

              if (i < itemsPerRow - 1) {
                rowItems.add(const SizedBox(width: 6));
              }
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rowItems,
            );
          },
        );
      },
    );
  }

  //-✅-----------MenuListShimmer-----------------------------------------✅-//
  static Widget MenuListShimmer(BuildContext context, int value) {
    const double itemSize = 50.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // 🔹 Responsive items per row
        int itemsPerRow;
        if (screenWidth < 600) {
          itemsPerRow = 2;
        } else if (screenWidth < 1000) {
          itemsPerRow = 4;
        } else {
          itemsPerRow = 8;
        }

        final rowCount = (value / itemsPerRow).ceil(); // use `value` only

        return ListView.separated(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 15, left: 0, right: 0),
          itemCount: rowCount,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, rowIndex) {
            List<Widget> rowItems = [];

            for (int i = 0; i < itemsPerRow; i++) {
              final itemIndex = rowIndex * itemsPerRow + i;

              if (itemIndex < value) {
                rowItems.add(
                  Expanded(
                    child: CommonWidget().buildStaggeredAnimation(
                      index: rowIndex,
                      child: Shimmer.fromColors(
                        baseColor: const Color(0xFFE0E0E0),
                        highlightColor: const Color(0xFFF5F5F5),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: GlobalAppColor.DarkTextColorCode,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              CommonWidget().shimmerLine(width: 80, height: 10),
                              const SizedBox(height: 8),
                              CommonWidget().shimmerLine(width: 50, height: 10),
                              const SizedBox(height: 8),
                              CommonWidget().shimmerLine(
                                width: 100,
                                height: 10,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  // Minus Button Circle
                                  Container(
                                    height: 25,
                                    width: 25,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(
                                        itemSize * 0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),

                                  // Current Value
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    child: CommonWidget().shimmerLine(
                                      width: 20,
                                      height: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 4),

                                  // Plus Button Circle
                                  Container(
                                    height: 25,
                                    width: 25,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(
                                        itemSize * 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                rowItems.add(const Expanded(child: SizedBox()));
              }

              if (i < itemsPerRow - 1) {
                rowItems.add(const SizedBox(width: 6));
              }
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rowItems,
            );
          },
        );
      },
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
