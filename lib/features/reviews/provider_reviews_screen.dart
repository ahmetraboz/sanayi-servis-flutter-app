import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import 'provider_reviews_notifier.dart';

class ProviderReviewsScreen extends ConsumerWidget {
  const ProviderReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(providerReviewsProvider);
    final notifier = ref.read(providerReviewsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Değerlendirmeler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray900)),
        actions: [
          if (!state.loading)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, color: AppColors.gray600),
              onPressed: notifier.fetchReviews,
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.blue600,
        onRefresh: notifier.fetchReviews,
        child: _buildBody(context, state, notifier),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProviderReviewsState state, ProviderReviewsNotifier notifier) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.blue600, strokeWidth: 2));
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: AppColors.gray500, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: notifier.fetchReviews,
              child: const Text('Tekrar Dene', style: TextStyle(color: AppColors.blue600)),
            ),
          ],
        ),
      );
    }

    if (state.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: AppColors.gray100, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.star_outline, size: 32, color: AppColors.gray300),
            ),
            const SizedBox(height: 16),
            const Text('Henüz değerlendirme yok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray700)),
            const SizedBox(height: 6),
            const Text('Tamamlanan işler sonrasında müşteri değerlendirmeleri burada görünecek', style: TextStyle(fontSize: 13, color: AppColors.gray400), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _RatingSummaryCard(state: state),
        const SizedBox(height: 20),
        ...state.reviews.map((r) => _ReviewCard(
              review: r,
              isReplying: state.replyingId == r.id,
              onReply: (reply) => notifier.submitReply(r.id, reply),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Rating Summary ───────────────────────────────────────────────────────────

class _RatingSummaryCard extends StatelessWidget {
  final ProviderReviewsState state;

  const _RatingSummaryCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final avg = state.averageRating;
    final total = state.totalReviews;
    final buckets = state.starBuckets;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                avg != null ? avg.toStringAsFixed(1) : '—',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.gray900, height: 1),
              ),
              const SizedBox(height: 4),
              _StarRow(rating: avg?.round() ?? 0),
              const SizedBox(height: 4),
              Text('$total değerlendirme', style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = buckets[star] ?? 0;
                final pct = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Text('$star', style: const TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, size: 12, color: AppColors.yellow400),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: AppColors.gray100,
                            color: AppColors.yellow400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 18,
                        child: Text('$count', style: const TextStyle(fontSize: 11, color: AppColors.gray400), textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;

  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_outline,
          size: 16,
          color: AppColors.yellow400,
        ),
      ),
    );
  }
}

// ─── Review Card ──────────────────────────────────────────────────────────────

class _ReviewCard extends StatefulWidget {
  final ReviewItem review;
  final bool isReplying;
  final Future<bool> Function(String) onReply;

  const _ReviewCard({required this.review, required this.isReplying, required this.onReply});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _showReplyForm = false;
  final _controller = TextEditingController();

  static const _kMonths = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day} ${_kMonths[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final ok = await widget.onReply(text);
    if (ok && mounted) {
      setState(() {
        _showReplyForm = false;
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    final hasReply = r.providerReply != null && r.providerReply!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: AppColors.blue600.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    r.customerName.isNotEmpty ? r.customerName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.blue600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.customerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray900)),
                    Text(r.requestTitle, style: const TextStyle(fontSize: 12, color: AppColors.gray400), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StarRow(rating: r.rating),
                  const SizedBox(height: 2),
                  Text(_fmtDate(r.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                ],
              ),
            ],
          ),
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(r.comment!, style: const TextStyle(fontSize: 13, color: AppColors.gray600, height: 1.5)),
          ],
          if (hasReply) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.blue600.withValues(alpha: 0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.reply_outlined, size: 14, color: AppColors.blue600),
                      SizedBox(width: 4),
                      Text('Yanıtınız', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(r.providerReply!, style: const TextStyle(fontSize: 13, color: AppColors.gray700, height: 1.4)),
                  if (r.repliedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(_fmtDate(r.repliedAt!), style: const TextStyle(fontSize: 11, color: AppColors.gray400)),
                  ],
                ],
              ),
            ),
          ] else if (!_showReplyForm) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() {
                _showReplyForm = true;
                _controller.clear();
              }),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.reply_outlined, size: 14, color: AppColors.blue600),
                  SizedBox(width: 4),
                  Text('Yanıtla', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue600)),
                ],
              ),
            ),
          ],
          if (_showReplyForm) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Yanıtınızı yazın...',
                hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 13),
                filled: true,
                fillColor: AppColors.gray50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.blue600)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _showReplyForm = false;
                    _controller.clear();
                  }),
                  child: const Text('İptal', style: TextStyle(color: AppColors.gray500)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: widget.isReplying ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: widget.isReplying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Gönder', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
