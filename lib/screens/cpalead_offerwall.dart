bool _isAllowedOfferwallHost(String host) {
  return host == 'cpalead.com' ||
      host.endsWith('.cpalead.com') ||
      host == 'cdnflair.com' ||
      host.endsWith('.cdnflair.com');
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CpaleadOfferwallScreen extends StatefulWidget {
  const CpaleadOfferwallScreen({super.key});
  @override
  State<CpaleadOfferwallScreen> createState() => _CpaleadOfferwallScreenState();
}

class _CpaleadOfferwallScreenState extends State<CpaleadOfferwallScreen> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Please sign in again.');
      final snap = await FirebaseFirestore.instance.collection('settings').doc('offerwalls').get();
      final data = snap.data() ?? <String, dynamic>{};
      if (data['cpaleadActive'] == false) throw Exception('Offerwall is temporarily unavailable.');
      final template = (data['cpaleadUrlTemplate'] ?? data['cpaleadUrl'] ?? '').toString().trim();
      if (template.isEmpty) throw Exception('CPAlead Offerwall is not configured yet.');
      if (!template.startsWith('https://')) throw Exception('Offerwall URL must use HTTPS.');

      final host = Uri.tryParse(template)?.host.toLowerCase() ?? '';
      if (!_isAllowedOfferwallHost(host)) {
        throw Exception('CPAlead Offerwall URL is not allowed. Use the Direct Link from CPAlead Get Code.');
      }

      var url = template.replaceAll('{uid}', Uri.encodeComponent(user.uid));
      if (!template.contains('{uid}')) {
        final separator = url.contains('?') ? '&' : '?';
        url = url + separator + 'subid=' + Uri.encodeComponent(user.uid);
      }

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF080B10))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) { if (mounted) setState(() => _loading = true); },
            onPageFinished: (_) { if (mounted) setState(() => _loading = false); },
            onWebResourceError: (error) {
              if (mounted) setState(() { _loading = false; _error = error.description; });
            },
          ),
        )
        ..loadRequest(Uri.parse(url));

      if (mounted) setState(() { _controller = controller; _loading = true; });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080B10),
        elevation: 0,
        title: const Text('Earn with Offers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: () => _controller?.reload(), icon: const Icon(Icons.refresh_rounded, color: Colors.white70)),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF111622), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_offer_outlined, color: Color(0xFF00FF87), size: 48),
                      const SizedBox(height: 12),
                      const Text('CPAlead Offers', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadConfig, child: const Text('Try Again')),
                    ],
                  ),
                ),
              ),
            ),
          if (_loading && _error == null) const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87))),
        ],
      ),
    );
  }
}


class CpaleadOfferwallPanel extends StatefulWidget {
  final double height;
  const CpaleadOfferwallPanel({super.key, this.height = 620});

  @override
  State<CpaleadOfferwallPanel> createState() => _CpaleadOfferwallPanelState();
}

class _CpaleadOfferwallPanelState extends State<CpaleadOfferwallPanel> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Please sign in again.');
      final snap = await FirebaseFirestore.instance.collection('settings').doc('offerwalls').get();
      final data = snap.data() ?? <String, dynamic>{};
      if (data['cpaleadActive'] == false) throw Exception('CPAlead Offerwall is disabled.');
      final template = (data['cpaleadUrlTemplate'] ?? data['cpaleadUrl'] ?? '').toString().trim();
      if (template.isEmpty) throw Exception('CPAlead Offerwall is not configured in Admin Settings.');
      if (!template.startsWith('https://')) throw Exception('Offerwall URL must use HTTPS.');

      final host = Uri.tryParse(template)?.host.toLowerCase() ?? '';
      if (!_isAllowedOfferwallHost(host)) {
        throw Exception('CPAlead Offerwall URL is not allowed. Use the Direct Link from CPAlead Get Code.');
      }

      var url = template.replaceAll('{uid}', Uri.encodeComponent(user.uid));
      if (!template.contains('{uid}')) {
        url = url + (url.contains('?') ? '&' : '?') + 'subid=' + Uri.encodeComponent(user.uid);
      }

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF080B10))
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (_) { if (mounted) setState(() => _loading = true); },
          onPageFinished: (_) { if (mounted) setState(() => _loading = false); },
          onWebResourceError: (e) { if (mounted) setState(() { _loading = false; _error = e.description; }); },
        ))
        ..loadRequest(Uri.parse(url));

      if (mounted) setState(() { _controller = controller; _loading = true; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: const Color(0xFF111622), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.22))),
      child: Stack(children: [
        if (_controller != null) WebViewWidget(controller: _controller!),
        if (_error != null) Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.local_offer_outlined, color: Color(0xFF00FF87), size: 38),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ]))),
        if (_loading && _error == null) const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87))),
      ]),
    );
  }
}
