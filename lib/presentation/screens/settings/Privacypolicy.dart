import 'package:aqi_app/constants/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CommanWebViewWidget extends StatefulWidget {
  final String url;
  final String title;

  const CommanWebViewWidget({Key? key, required this.url, required this.title})
    : super(key: key);

  @override
  _CommanWebViewWidgetState createState() => _CommanWebViewWidgetState();
}

class _CommanWebViewWidgetState extends State<CommanWebViewWidget> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (int progress) {
                // You can add a progress indicator here
                debugPrint('WebView is loading (progress : $progress%)');
              },
              onPageStarted: (String url) {
                debugPrint('Page started loading: $url');
              },
              onPageFinished: (String url) {
                debugPrint('Page finished loading: $url');
              },
              onWebResourceError: (WebResourceError error) {
                debugPrint('''
              Page resource error:
              code: ${error.errorCode}
              description: ${error.description}
              errorType: ${error.errorType}
              isForMainFrame: ${error.isForMainFrame}
            ''');
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: COLOR_CONST.backgroundColor ,
        title: Text(widget.title),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}
