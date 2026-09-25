import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class CpaleadOffer {
  final String id, title, description, link, amount, currency, payoutType, device, category, imageUrl;
  final List<Map<String, dynamic>> events;
  const CpaleadOffer({required this.id, required this.title, required this.description, required this.link, required this.amount, required this.currency, required this.payoutType, required this.device, required this.category, required this.imageUrl, required this.events});

  factory CpaleadOffer.fromJson(Map<String, dynamic> json) {
    String image = '';
    final creatives = json['creatives'];
    if (creatives is List) {
      for (final item in creatives) {
        if (item is Map) {
          final candidate = (item['url'] ?? item['image'] ?? item['image_url'] ?? item['thumbnail'] ?? '').toString();
          if (candidate.startsWith('http')) { image = candidate; break; }
        }
      }
    } else if (creatives is Map) {
      image = (creatives['url'] ?? creatives['image'] ?? creatives['image_url'] ?? '').toString();
    }
    final events = <Map<String, dynamic>>[];
    if (json['events'] is List) {
      for (final e in json['events']) { if (e is Map) events.add(Map<String, dynamic>.from(e)); }
    }
    return CpaleadOffer(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Offer').toString(),
      description: (json['description'] ?? json['long_description'] ?? 'Complete the required steps to earn your reward.').toString(),
      link: (json['link'] ?? '').toString(),
      amount: (json['amount'] ?? 0).toString(),
      currency: (json['payout_currency'] ?? 'USD').toString(),
      payoutType: (json['payout_type'] ?? json['conversion'] ?? 'CPA').toString(),
      device: (json['device'] ?? 'Mobile').toString(),
      category: (json['category'] ?? json['type'] ?? 'Offers').toString(),
      imageUrl: image,
      events: events,
    );
  }

  int get estimatedCoins => ((double.tryParse(amount) ?? 0) * 100).round();
}

class CpaleadApiService {
  static Future<List<CpaleadOffer>> fetchOffers({required String publisherId, required String uid}) async {
    final query = {
      'id': publisherId,
      'country': 'user',
      'device': 'user',
      'limit': '50',
      'subid': uid,
      'fields': 'id,title,description,long_description,link,amount,payout_currency,payout_type,device,countries,creatives,events,offer_rank,conversion,conversion_mode',
    };
    final response = await http.get(Uri.https('www.cpalead.com', '/api/offers', query)).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw Exception('CPAlead API returned HTTP ${response.statusCode}.');
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) throw Exception('Invalid CPAlead API response.');
    final rawOffers = decoded['offers'];
    if (rawOffers is! List) return [];
    final offers = <CpaleadOffer>[];
    for (final item in rawOffers) {
      if (item is Map) {
        final offer = CpaleadOffer.fromJson(Map<String, dynamic>.from(item));
        if (offer.link.isNotEmpty) offers.add(offer);
      }
    }
    return offers;
  }
}

class CpaleadOfferwallPanel extends StatefulWidget {
  final double height;
  const CpaleadOfferwallPanel({super.key, this.height = 540});
  @override State<CpaleadOfferwallPanel> createState() => _CpaleadOfferwallPanelState();
}

class _CpaleadOfferwallPanelState extends State<CpaleadOfferwallPanel> {
  List<CpaleadOffer> _offers = [];
  bool _loading = true;
  String? _error;
  String _filter = 'All';

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Please sign in again.');
      final snap = await FirebaseFirestore.instance.collection('settings').doc('offerwalls').get();
      final data = snap.data() ?? <String, dynamic>{};
      if (data['cpaleadActive'] == false) throw Exception('CPAlead offers are temporarily unavailable.');
      final publisherId = (data['cpaleadPublisherId'] ?? '').toString().trim();
      if (publisherId.isEmpty) throw Exception('CPAlead Publisher ID is not configured in Admin Settings.');
      final offers = await CpaleadApiService.fetchOffers(publisherId: publisherId, uid: user.uid);
      if (mounted) setState(() { _offers = offers; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  List<CpaleadOffer> get _filtered {
    if (_filter == 'All') return _offers;
    return _offers.where((o) {
      final value = '\${o.category} \${o.payoutType} \${o.title} \${o.description}'.toLowerCase();
      if (_filter == 'Apps') return value.contains('app') || value.contains('install') || value.contains('cpi');
      if (_filter == 'Surveys') return value.contains('survey');
      return !value.contains('survey');
    }).toList();
  }

  Future<void> _openOffer(CpaleadOffer offer) async {
    final uri = Uri.tryParse(offer.link);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(color: const Color(0xFF0D111A), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFF00FF87).withOpacity(.16))),
      child: Column(children: [
        Row(children: [
          const Expanded(child: Text('Earn rewards by completing offers', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900))),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded, color: Colors.white70)),
        ]),
        SizedBox(height: 42, child: ListView(scrollDirection: Axis.horizontal, children: ['All','Apps','Surveys','Offers'].map((value) {
          final selected = _filter == value;
          return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
            label: Text(value), selected: selected, onSelected: (_) => setState(() => _filter = value),
            selectedColor: const Color(0xFF00FF87), backgroundColor: const Color(0xFF111622),
            labelStyle: TextStyle(color: selected ? Colors.black : Colors.white70, fontWeight: FontWeight.w800),
            side: const BorderSide(color: Color(0xFF283044)),
          ));
        }).toList())),
        const SizedBox(height: 8),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)))
          : _error != null ? _errorView()
          : _filtered.isEmpty ? _emptyView()
          : ListView.separated(itemCount: _filtered.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (_, i) => _offerCard(_filtered[i]))),
      ]),
    );
  }

  Widget _offerCard(CpaleadOffer offer) => InkWell(
    onTap: () => _showDetails(offer), borderRadius: BorderRadius.circular(16),
    child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF111622), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
      child: Row(children: [
        _offerImage(offer), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(offer.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(offer.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.25)),
          const SizedBox(height: 8),
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF00FF87).withOpacity(.12), borderRadius: BorderRadius.circular(8)),
              child: Text('+\${offer.estimatedCoins} Coins', style: const TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.w900))),
            const Spacer(), const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ]),
        ])),
      ]),
    ),
  );

  Widget _offerImage(CpaleadOffer offer) {
    if (offer.imageUrl.isEmpty) return Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFF080B10), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.local_offer_rounded, color: Color(0xFF00FF87), size: 28));
    return ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(offer.imageUrl, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 64, height: 64, color: const Color(0xFF080B10), child: const Icon(Icons.local_offer_rounded, color: Color(0xFF00FF87))));
  }

  Widget _errorView() => Center(child: Padding(padding: const EdgeInsets.all(18), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.cloud_off_rounded, color: Colors.white38, size: 40), const SizedBox(height: 8),
    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 12)),
    const SizedBox(height: 12), ElevatedButton(onPressed: _load, child: const Text('Retry')),
  ])));

  Widget _emptyView() => const Center(child: Text('No offers available right now. Please check again later.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)));

  void _showDetails(CpaleadOffer offer) {
    showModalBottomSheet(context: context, backgroundColor: const Color(0xFF0D111A), isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20,16,20,20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(5)))),
        const SizedBox(height: 18),
        Row(children: [_offerImage(offer), const SizedBox(width: 12), Expanded(child: Text(offer.title, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)))]),
        const SizedBox(height: 14),
        Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF00FF87).withOpacity(.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF00FF87).withOpacity(.16))), child: Text('+\${offer.estimatedCoins} Coins', style: const TextStyle(color: Color(0xFF00FF87), fontSize: 20, fontWeight: FontWeight.w900))),
        const SizedBox(height: 12), Text(offer.description, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
        if (offer.events.isNotEmpty) ...[
          const SizedBox(height: 14), const Text('How to earn', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)), const SizedBox(height: 8),
          ...offer.events.take(4).map((event) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF00FF87), size: 17), const SizedBox(width: 8),
            Expanded(child: Text('\${event['name'] ?? event['description'] ?? 'Complete this step'}  +\${event['amount'] ?? ''}', style: const TextStyle(color: Colors.white60, fontSize: 12))),
          ]))),
        ],
        const SizedBox(height: 18),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: () { Navigator.pop(context); _openOffer(offer); },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Text('START OFFER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)))),
      ])));
  }
}

class CpaleadOfferwallScreen extends StatelessWidget {
  const CpaleadOfferwallScreen({super.key});
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF080B10),
    appBar: AppBar(backgroundColor: const Color(0xFF0D111A), elevation: 0, title: const Text('Earn with Offers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)), iconTheme: const IconThemeData(color: Colors.white)),
    body: const CpaleadOfferwallPanel(height: double.infinity),
  );
}
