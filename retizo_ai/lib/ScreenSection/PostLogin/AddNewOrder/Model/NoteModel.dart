// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable

//-✅---------------------------------------------------------------------✅-//
class NoteModel {
  int mProdIng;
  int mProdId;
  int invProductID;
  int qty;
  String creationDatetime;
  String createdBy;
  String modificationDatetime;
  String modifiedBy;
  Product product;
  InventoryProduct inventoryProduct;

  NoteModel({
    required this.mProdIng,
    required this.mProdId,
    required this.invProductID,
    required this.qty,
    required this.creationDatetime,
    required this.createdBy,
    required this.modificationDatetime,
    required this.modifiedBy,
    required this.product,
    required this.inventoryProduct,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return NoteModel(
      mProdIng: parseInt(json['m_prod_ing']),
      mProdId: parseInt(json['m_prod_id']),
      invProductID: parseInt(json['inv_product_ID']),
      qty: parseInt(json['qty']),
      creationDatetime: json['creation_datetime'] ?? "",
      createdBy: json['created_by'] ?? "",
      modificationDatetime: json['modification_datetime'] ?? "",
      modifiedBy: json['modified_by'] ?? "",
      product: Product.fromJson(json['Product'] ?? {}),
      inventoryProduct: InventoryProduct.fromJson(
        json['InventoryProduct'] ?? {},
      ),
    );
  }
}

class Product {
  int mProdId;
  String mPName;
  String mPArbName;
  String price;
  String status;

  Product({
    required this.mProdId,
    required this.mPName,
    required this.mPArbName,
    required this.price,
    required this.status,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Product(
      mProdId: parseInt(json['m_prod_id']),
      mPName: json['m_p_name'] ?? "",
      mPArbName: json['m_p_arb_name'] ?? "",
      price: json['price'] ?? "0",
      status: json['status'] ?? "",
    );
  }
}

class InventoryProduct {
  int invProductID;
  String pName;

  InventoryProduct({required this.invProductID, required this.pName});

  factory InventoryProduct.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return InventoryProduct(
      invProductID: parseInt(json['inv_product_ID']),
      pName: json['p_name'] ?? "",
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
