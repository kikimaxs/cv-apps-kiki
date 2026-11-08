import 'webview_setup_stub.dart'
    if (dart.library.js_interop) 'webview_setup_web.dart'
    as impl;

/// Registers the web WebView implementation on web only, so the Android and
/// iOS builds never compile `webview_flutter_web`.
void setupWebView() => impl.setupWebView();
