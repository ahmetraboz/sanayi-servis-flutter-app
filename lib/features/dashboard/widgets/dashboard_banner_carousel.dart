import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class DashboardBannerCarousel extends StatefulWidget {
  const DashboardBannerCarousel({super.key});

  @override
  State<DashboardBannerCarousel> createState() => _DashboardBannerCarouselState();
}

class _DashboardBannerCarouselState extends State<DashboardBannerCarousel> {
  final _controller = PageController();
  int _current = 0;
  Timer? _timer;

  static const _banners = [
    _BannerData(
      title: 'Hızlı Teklif Ver, Öne Çık',
      subtitle: 'İlk teklif veren servisler %40 daha fazla iş alıyor.',
      icon: Icons.bolt_outlined,
      gradientColors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
      accentColor: Color(0xFF93C5FD),
    ),
    _BannerData(
      title: 'Profilini Güçlendir',
      subtitle: 'Fotoğraf ve belge ekleyen servisler müşteri güvenini 3x artırıyor.',
      icon: Icons.workspace_premium_outlined,
      gradientColors: [Color(0xFF0D9488), Color(0xFF0F766E)],
      accentColor: Color(0xFF99F6E4),
    ),
    _BannerData(
      title: '5 Yıldız, Daha Fazla İş',
      subtitle: 'Her işi zamanında bitir, puanını yükselt, sıralamanı artır.',
      icon: Icons.star_outline_rounded,
      gradientColors: [Color(0xFFD97706), Color(0xFFB45309)],
      accentColor: Color(0xFFFDE68A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 110,
          child: PageView.builder(
            controller: _controller,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _BannerCard(data: _banners[i]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.blue600 : AppColors.gray300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final _BannerData data;

  const _BannerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: data.gradientColors.first.withValues(alpha: 0.30),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(data.icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.subtitle,
                      style: TextStyle(
                        color: data.accentColor,
                        fontSize: 12,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final Color accentColor;

  const _BannerData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.accentColor,
  });
}
