import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  final String snapToken;

  const PaymentWebView({super.key, required this.snapToken});

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    final String paymentUrl =
        "https://app.sandbox.midtrans.com/snap/v2/vtweb/${widget.snapToken}";
    debugPrint("Snap Token: ${widget.snapToken}");
    debugPrint("Snap URL: $paymentUrl");

    final PlatformWebViewControllerCreationParams params =
        const PlatformWebViewControllerCreationParams();

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('Mulai muat halaman: $url');
          },
          onPageFinished: (url) {
            debugPrint('Selesai muat halaman: $url');
          },
          onWebResourceError: (error) {
            debugPrint('Terjadi error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pembayaran")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
