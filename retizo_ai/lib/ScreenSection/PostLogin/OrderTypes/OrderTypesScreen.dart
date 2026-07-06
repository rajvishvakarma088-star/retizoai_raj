// ignore_for_file: file_names, use_build_context_synchronously
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';

//-✅-------Order Types Management Screen (Full CRUD)--------------------✅-//
class OrderTypesScreen extends StatefulWidget {
  const OrderTypesScreen({super.key});

  @override
  State<OrderTypesScreen> createState() => _OrderTypesScreenState();
}

class _OrderTypesScreenState extends State<OrderTypesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderTypes();
    });
  }

  Future<void> _loadOrderTypes() async {
    if (!mounted) return;
    final addOrderCtrl = context.read<AddOrderProvider>();
    await addOrderCtrl.getOrderTypeListService(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddOrderProvider>(
      builder: (context, addOrderCtrl, child) {
        return Scaffold(
          backgroundColor: GlobalAppColor.HomeBgColorCode,
          appBar: AppBar(
            title: Text(
              "Manage Order Types",
              style: CommonWidget.CommonTitleTextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: GlobalAppColor.DarkBlueColor,
            elevation: 0,
            actions: [
              // Add New Order Type Button
              IconButton(
                icon: Icon(Symbols.add_circle, color: Colors.white),
                onPressed: () => _showCreateDialog(context, addOrderCtrl),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadOrderTypes,
            child: addOrderCtrl.TableTypeListing.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Symbols.restaurant_menu,
                          size: 80,
                          color: GlobalAppColor.DarkTextColorCode.withValues(
                            alpha: .3,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No Order Types Found",
                          style: CommonWidget.CommonTitleTextStyle(
                            fontSize: 18,
                            color: GlobalAppColor.HomeLightTextColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () =>
                              _showCreateDialog(context, addOrderCtrl),
                          icon: Icon(Symbols.add),
                          label: Text("Create First Order Type"),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(AppDimensions.lg),
                    itemCount: addOrderCtrl.TableTypeListing.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: AppDimensions.md),
                    itemBuilder: (context, index) {
                      final orderType = addOrderCtrl.TableTypeListing[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppBorderRadius.sm,
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: GlobalAppColor
                                .DarkBlueColor.withValues(alpha: .1),
                            child: Icon(
                              Symbols.restaurant,
                              color: GlobalAppColor.DarkBlueColor,
                            ),
                          ),
                          title: Text(
                            orderType.orderTypeName,
                            style: CommonWidget.CommonTitleTextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            "ID: ${orderType.orderTypeId}",
                            style: CommonWidget.CommonTitleTextStyle(
                              fontSize: 13,
                              color: GlobalAppColor.HomeLightTextColor,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Edit Button - PUT /order-types/{id}
                              IconButton(
                                icon: Icon(
                                  Symbols.edit,
                                  color: GlobalAppColor.DarkBlueColor,
                                ),
                                onPressed: () => _showEditDialog(
                                  context,
                                  addOrderCtrl,
                                  orderType,
                                ),
                              ),
                              // Delete Button - DELETE /order-types/{id}
                              IconButton(
                                icon: Icon(
                                  Symbols.delete,
                                  color: GlobalAppColor.RedCode,
                                ),
                                onPressed: () => _confirmDelete(
                                  context,
                                  addOrderCtrl,
                                  orderType,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  //-✅---Create Order Type Dialog - POST /order-types/-------------------✅-//
  Future<void> _showCreateDialog(
    BuildContext context,
    AddOrderProvider addOrderCtrl,
  ) async {
    final nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Create Order Type"),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: "Order Type Name",
            hintText: "e.g. Drive Thru, Pick Up",
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                showCustomToast(
                  context: context,
                  message: "⚠️ Please enter order type name",
                );
                return;
              }

              Navigator.pop(ctx);

              // ✅ Call POST /order-types/
              await addOrderCtrl.createOrderTypeService(context, name);
            },
            child: Text("Create"),
          ),
        ],
      ),
    );
  }

  //-✅---Edit Order Type Dialog - PUT /order-types/{id}------------------✅-//
  Future<void> _showEditDialog(
    BuildContext context,
    AddOrderProvider addOrderCtrl,
    OrderSummaryTableTypeList orderType,
  ) async {
    final nameController = TextEditingController(text: orderType.orderTypeName);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Edit Order Type"),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: "Order Type Name",
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty) {
                showCustomToast(
                  context: context,
                  message: "⚠️ Please enter order type name",
                );
                return;
              }

              Navigator.pop(ctx);

              // ✅ Call PUT /order-types/{id}
              await addOrderCtrl.updateOrderTypeService(
                context,
                orderType.orderTypeId,
                newName,
              );
            },
            child: Text("Update"),
          ),
        ],
      ),
    );
  }

  //-✅---Delete Confirmation - DELETE /order-types/{id}------------------✅-//
  Future<void> _confirmDelete(
    BuildContext context,
    AddOrderProvider addOrderCtrl,
    OrderSummaryTableTypeList orderType,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete Order Type"),
        content: Text(
          "Are you sure you want to delete '${orderType.orderTypeName}'?\n\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GlobalAppColor.RedCode,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // ✅ Call DELETE /order-types/{id}
      await addOrderCtrl.deleteOrderTypeService(context, orderType.orderTypeId);
    }
  }
}
