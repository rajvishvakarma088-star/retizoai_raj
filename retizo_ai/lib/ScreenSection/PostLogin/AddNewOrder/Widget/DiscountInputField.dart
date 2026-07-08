// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, deprecated_member_use, await_only_futures, unnecessary_null_comparison, unused_local_variable, strict_top_level_inference, avoid_web_libraries_in_flutter, unnecessary_import, curly_braces_in_flow_control_structures
import 'package:culai/HTTPRepository/Packages.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

//-✅---------------------------------------------------------------------✅-//
class DiscountInputField extends StatefulWidget {
  final String hintText;

  const DiscountInputField({super.key, this.hintText = "Discount"});

  @override
  State<DiscountInputField> createState() => _DiscountInputFieldState();
}

class _DiscountInputFieldState extends State<DiscountInputField> {
  // ✅ Once authorized for this order, allow free adjustment
  bool _discountAuthorized = false;

  //-✅--Manager Authorization Dialog-------------------------------------✅-//
  /// Shows a password dialog and verifies via the login endpoint.
  /// Returns true if authorized, false if cancelled or wrong password.
  Future<bool> _showAuthorizationDialog() async {
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    bool loading = false;
    String? errorMsg;

    final email =
        Provider.of<UserInfoProvider>(context, listen: false).email ?? '';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          backgroundColor: GlobalAppColor.WhiteColorCode,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.lock_outline,
                color: Color(0xFF5C5C8A),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Manager Authorization',
                  style: CommonWidget.CommonTitleTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD066)),
                  ),
                  child: Text(
                    'Applying a discount requires manager authorization. Enter your password to continue.',
                    style: CommonWidget.CommonTitleTextStyle(
                      color: const Color(0xFF7A5500),
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  'Password',
                  style: CommonWidget.CommonTitleTextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: passwordCtrl,
                  obscureText: obscure,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setDlg(() => obscure = !obscure),
                    ),
                    errorText: errorMsg,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onSubmitted: (_) {
                    // Allow submit on keyboard "done"
                    if (!loading)
                      _doVerify(
                        ctx,
                        setDlg,
                        passwordCtrl,
                        email,
                        getLoading: () => loading,
                        setLoading: (v) => loading = v,
                        setError: (e) => errorMsg = e,
                      );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C5C8A),
              ),
              onPressed: loading
                  ? null
                  : () => _doVerify(
                      ctx,
                      setDlg,
                      passwordCtrl,
                      email,
                      getLoading: () => loading,
                      setLoading: (v) => loading = v,
                      setError: (e) => errorMsg = e,
                    ),
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Authorize',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );

    return result == true;
  }

  //-✅--Do Password Verification-----------------------------------------✅-//
  void _doVerify(
    BuildContext ctx,
    StateSetter setDlg,
    TextEditingController passwordCtrl,
    String email, {
    required bool Function() getLoading,
    required void Function(bool) setLoading,
    required void Function(String?) setError,
  }) async {
    final pwd = passwordCtrl.text.trim();
    if (pwd.isEmpty) {
      setDlg(() => setError('Please enter password'));
      return;
    }
    setDlg(() {
      setLoading(true);
      setError(null);
    });
    try {
      final response = await http
          .post(
            Uri.parse(GlobalServiceURL.preLoginUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': pwd}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      if (response.statusCode == 200 &&
          (body?['success'] == true || body?['token'] != null)) {
        if (ctx.mounted) Navigator.of(ctx).pop(true);
      } else {
        setDlg(() {
          setLoading(false);
          String msg =
              body?['message']?.toString() ?? 'Incorrect password. Try again.';
          if (msg.toLowerCase().contains('email') ||
              msg.toLowerCase().contains('password')) {
            msg = 'Invalid manager password';
          }
          setError(msg);
        });
      }
    } catch (_) {
      setDlg(() {
        setLoading(false);
        setError('Verification failed. Check your connection.');
      });
    }
  }

  //-✅--Build------------------------------------------------------------✅-//
  @override
  Widget build(BuildContext context) {
    return Consumer2<NumberInputDiscountProvider, AddOrderProvider>(
      builder: (context, provider, AddOrderCtrl, child) {
        // Reset authorization once discount is cleared back to 0
        if (provider.value == 0 && _discountAuthorized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _discountAuthorized = false);
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: GlobalAppColor.WhiteColorCode,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: GlobalAppColor.DarkTextColorCode.withOpacity(.1),
              width: 2,
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: TextEditingController(
                    text: provider.formattedValue,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  textAlignVertical: TextAlignVertical.center,
                  cursorColor: GlobalAppColor.DarkTextColorCode,
                  style: CommonWidget.CommonTitleTextStyle(
                    color: GlobalAppColor.DarkTextColorCode,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: provider.value == 0 ? widget.hintText : '',
                    hintStyle: CommonWidget.CommonTitleTextStyle(
                      color: GlobalAppColor.DarkTextColorCode.withOpacity(.6),
                      fontSize: 13,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 4,
                    ),
                  ),
                  onChanged: AddOrderCtrl.isBookingLoader
                      ? null
                      : (value) async {
                          final newVal = int.tryParse(value) ?? 0;
                          if (newVal > 0 && !_discountAuthorized) {
                            // Require manager auth before applying discount
                            final authorized = await _showAuthorizationDialog();
                            if (authorized) {
                              if (mounted) {
                                setState(() => _discountAuthorized = true);
                              }
                              provider.manualInput(context, value);
                            } else {
                              // Revert to 0 — do not apply
                              provider.manualInput(context, '0');
                            }
                          } else {
                            provider.manualInput(context, value);
                          }
                        },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  InkWell(
                    onTap: AddOrderCtrl.isBookingLoader
                        ? null
                        : () async {
                            if (provider.value == 0 && !_discountAuthorized) {
                              // First increment from 0 requires auth
                              final authorized =
                                  await _showAuthorizationDialog();
                              if (authorized) {
                                if (mounted) {
                                  setState(() => _discountAuthorized = true);
                                }
                                provider.increment(context);
                              }
                            } else {
                              provider.increment(context);
                            }
                          },
                    child: const Icon(Icons.arrow_drop_up, size: 18),
                  ),
                  InkWell(
                    onTap: AddOrderCtrl.isBookingLoader
                        ? null
                        : () => provider.decrement(context),
                    child: const Icon(Icons.arrow_drop_down, size: 18),
                  ),
                ],
              ),
              // 🔹 % sign
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text('%', style: CommonWidget.CommonTitleTextStyle()),
              ),
            ],
          ),
        );
      },
    );
  }
}

//-✅---------------------------------------------------------------------✅-//
