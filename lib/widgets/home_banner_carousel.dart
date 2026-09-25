import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll(int totalBanners) {
    _timer?.cancel();
    if (totalBanners <= 1) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % totalBanners;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _handleBannerClick(String targetUrl) async {
    if (targetUrl.trim().isEmpty) return;
    try {
      if (await canLaunchUrlString(targetUrl)) {
        await launchUrlString(targetUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Banner URL error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ಅಡ್ಮಿನ್ ಪ್ಯಾನೆಲ್‌ನ 'banners' ಕಲೆಕ್ಷನ್‌ಗೆ ನೇರ ರಿಯಲ್-ಟೈಮ್ ಕನೆಕ್ಷನ್
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('banners').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // isActive: false ಆಗಿದ್ದರೆ ಮಾತ್ರ ಹೈಡ್ ಮಾಡುವುದು, ಇಲ್ಲದಿದ್ದರೆ ಎಲ್ಲವನ್ನೂ ತೋರಿಸುವುದು
        final banners = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;
          return data['isActive'] != false;
        }).toList();

        banners.sort((a, b) {\n          final ad = a.data() as Map<String, dynamic>;\n          final bd = b.data() as Map<String, dynamic>;\n          return (ad['order'] as num? ?? 0).compareTo(bd['order'] as num? ?? 0);\n        });\n\n        if (banners.isEmpty) {
          return const SizedBox.shrink();
        }

        // Auto-scroll Timer ಆರಂಭ
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_timer == null || !_timer!.isActive) {
            _startAutoScroll(banners.length);
          }
        });

        return Column(
          children: [
            SizedBox(
              height: 155,
              child: PageView.builder(
                controller: _pageController,
                itemCount: banners.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final data = banners[index].data() as Map<String, dynamic>;
                  // image ಅಥವಾ imageUrl ಎರಡನ್ನೂ ಸಪೋರ್ಟ್ ಮಾಡುತ್ತದೆ
                  final imageUrl = (data['imageUrl'] ?? data['image'] ?? '').toString();
                  final targetUrl = (data['targetUrl'] ?? data['url'] ?? data['link'] ?? '').toString();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: GestureDetector(
                      onTap: () => _handleBannerClick(targetUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF111622),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: const Color(0xFF111622),
                                      child: const Center(
                                        child: Icon(Icons.broken_image, color: Colors.white30, size: 40),
                                      ),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Icon(Icons.image, color: Colors.white30, size: 40),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Carousel Dots Indicator
            if (banners.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(banners.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                    width: _currentPage == index ? 16 : 6,
                    height: 5,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? const Color(0xFF00FF87)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
          ],
        );
      },
    );
  }
}
