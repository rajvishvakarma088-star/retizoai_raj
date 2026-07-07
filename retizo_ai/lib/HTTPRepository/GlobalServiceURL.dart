// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, unnecessary_null_comparison, avoid_function_literals_in_foreach_calls, constant_identifier_names
//-✅---------------------------------------------------------------------✅-//
class GlobalServiceURL {
  static String noProfileImage =
      "https://st3.depositphotos.com/3431221/13621/v/450/depositphotos_136216036-stock-illustration-man-avatar-icon-hipster-character.jpg";
  static String noImage =
      "https://upload.wikimedia.org/wikipedia/commons/1/14/No_Image_Available.jpg";

  //-- Base API URL
  //static const String baseUrl = "https://culai.atlasits.cloud:5500/api";
  //static const String ImageBaseUrl = "https://culai.atlasits.cloud:5500";
  ////Production
  static const String baseUrl = "https://retizoai.ezyprojects.com:5600/api";
  static const String ImageBaseUrl = "https://retizoai.ezyprojects.com:5600";

  //-- Pre-login APIs
  static String preLoginUrl = "$baseUrl/auth/org-login";
  static String AuthMeUrl = "$baseUrl/auth/me";
  static String UpdateProfileUrl = "$baseUrl/auth/update-profile";
  static String ChangePasswordUrl = "$baseUrl/auth/change-password";

  //-- Post-login Order List APIs
  static String OrderListUrl = "$baseUrl/order-master/";

  //-- Post-login Category List APIs
  static String CategoryListUrl = "$baseUrl/menu/category";

  //-- Post-login Menu List APIs
  static String MenuListUrl = "$baseUrl/menu/product?orderMode=true";

  //-- Post-login Table List APIs
  static String OrderTableListUrl = "$baseUrl/table-master";
  static String TableWithStatusUrl = "$baseUrl/table-master/tableWithStatus";

  //-- Post-login Tax List APIs
  static String OrderTaxListUrl = "$baseUrl/tax";

  //-- Post-login Charges List APIs
  static String OrderChargesListUrl = "$baseUrl/charges";

  //-- Post-login PaymentMethods List APIs
  static String OrderPaymentMethodsListUrl = "$baseUrl/payment-methods";

  //-- Post-login Booking Order APIs
  static String BookingOrderUrl = "$baseUrl/order-master";

  //-- Post-login Update Existing Order API (PUT /order-master/{orderId})
  /// Append orderId: "${UpdateExistingOrderUrl}{orderId}"
  static String UpdateExistingOrderUrl = "$baseUrl/order-master/";

  //-- Post-login SearchMobile APIs
  static String SearchMobileUrl = "$baseUrl/customers/search/mobile/";

  //-- Post-login AddCustomer APIs
  static String AddCustomerUrl = "$baseUrl/customers/";

  //-- Post-login OrderNow APIs
  static String OrderNowUrl = "$baseUrl/order-details/";
  static String OrderTypeUrl = "$baseUrl/order-types";

  //-- Post-login Order Types by Branch API (NEW - Production)
  static String OrderTypesByBranchUrl = "$baseUrl/order-types/branch/";

  //-- Post-login Order Details by Order ID API (NEW - Production)
  static String OrderDetailsByOrderUrl = "$baseUrl/order-details/order/";

  //-- Post-login Order Master Description API (NEW - Production)
  static String OrderDescriptionUrl = "$baseUrl/order-master/descrip/";

  //-- Post-login Order Type by ID API (NEW - Production)
  static String OrderTypeByIdUrl = "$baseUrl/order-types/";

  //-- Post-login Order Detail by ID API (NEW - Production)
  static String OrderDetailByIdUrl = "$baseUrl/order-details/";

  //-- order item note patch
  static String OrderDetailNoteUrl = "$baseUrl/order-details/notes";

  //-- Post-login Order Details by Branch API (NEW - Production)
  static String OrderDetailsByBranchUrl = "$baseUrl/order-details/branch/";

  //-- Post-login brands APIs
  static String BrandsUrl = "$baseUrl/brands";

  //-- Post-login Note APIs
  static String NoteListUrl = "$baseUrl/menu/product-ingredients?";

  //-- Post-login Station APIs
  static String StationListUrl = "$baseUrl/stations?branch_id=";

  //-- Post-login OrderAll APIs
  static String FilterOrderListUrl = "$baseUrl/order-master/kitchen/";

  //-- Post-login HomeCountsUrl APIs
  static String HomeCountsUrl =
      "$baseUrl/order-master/counts/preparing-prepared?";

  //-- Post-login HomeCountsUrl APIs
  static String HomeNotificationsListUrl =
      "$baseUrl/order-master/notifications/prepared?";

  static String PayBillPaymentListUrl = "$baseUrl/payment-methods";
  static String ProcessPayBillPaymentUrl =
      "$baseUrl/order-master/process-payment";

  //-- Post-login Cash Drawer APIs (VERIFIED with Postman - March 10, 2026)
  static String CashDrawerUrl = "$baseUrl/cash-drawer/";
  static String CashDrawerSaveOnlyUrl = "$baseUrl/cash-drawer/save-only";
  static String CashDrawerReopenUrl = "$baseUrl/cash-drawer/re-open";

  //-- Post-login Product Stock APIs
  static String ProductsStockUrl = "$baseUrl/order-master/products-stock";
  static String CheckStockUrl = "$baseUrl/order-master/check-stock";
  static String ProductsInfoUrl = "$baseUrl/order-master/products-info";
  //-- Post-login Refund Order API
  static String RefundOrderUrl = "$baseUrl/order-master/orders/refund";

  //-- Post-login Group Orders API
  static String GroupOrdersUrl = "$baseUrl/order-master/group-orders";

  //-- Post-login Adjust Order API
  static String AdjustOrderUrl = "$baseUrl/order-master/adjust";

  //-- Post-login Order Payment Status API (GET /:orderId)
  static String OrderPaymentStatusUrl = "$baseUrl/order-master/payment-status/";

  //-- Post-login Modifier Mapping API (GET /product/:productId)
  /// Append productId: "$ModifierMappingUrl{productId}"
  static String ModifierMappingUrl = "$baseUrl/menu/modifier-mapping/product/";

  //-- Post-login Partial Payment APIs
  /// POST body: {"order_id": int, "amount": double, "pay_method_id": int, "remark": string (optional), "ref_no": string (optional)}
  static String PartialPaymentCreateUrl = "$baseUrl/order-master/partial-pay";

  /// GET: append orderId → "$PartialPaymentGetUrl{orderId}/partial-payments"
  static String PartialPaymentGetUrl = "$baseUrl/order-master/";

  //-- Printing Devices API
  /// GET /printingDevice — returns array of [{device_id, device_name, type, ip_address, port_number, ...}]
  /// type: "kds" | "cashier"  — differentiate by type field
  static String PrintingDeviceUrl = "$baseUrl/printingDevice";
}

//-✅---------------------------------------------------------------------✅-//
