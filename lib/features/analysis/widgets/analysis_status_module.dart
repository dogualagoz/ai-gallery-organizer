// Kütüphane'nin tek analiz durum modülü: bekleyen varsa kota bilgili "Analiz
// et" kartı, analiz sürerken kompakt ilerleme, bitince kısa özet, hak ya da
// tur sorunlarında tek satır; yapılacak bir şey yoksa gizlenir. Tamamlanan
// öğeleri AnalysisFlightScope'a uçuş olarak besler; özet durumu widget
// ömründen bağımsız olarak analysisSummaryProvider'da tutulur.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/l10n/l10n_extension.dart';
import '../../../core/models/screenshot_entry.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/entitlement_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/review_service.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../gallery/data/screenshot_repository.dart';
import '../providers/analysis_queue_provider.dart';
import '../providers/analysis_summary_provider.dart';
import 'analysis_flights.dart';
import 'analysis_status_views.dart';

class AnalysisStatusModule extends ConsumerStatefulWidget {
  const AnalysisStatusModule({super.key, required this.entries});

  /// Galerideki kayıtlar (bekleyen sayısı ve kaynak küçük resim için).
  final List<ScreenshotEntry> entries;

  @override
  ConsumerState<AnalysisStatusModule> createState() =>
      _AnalysisStatusModuleState();
}

class _AnalysisStatusModuleState extends ConsumerState<AnalysisStatusModule> {
  /// Uçuşa gönderilmiş son `done` değeri; yeni tamamlananlar bunun üstüdür.
  int _lastSeenDone = 0;

  /// Bu özet için başarı haptiği verildi mi (özet kapanınca sıfırlanır).
  bool _celebrated = false;

  AnalysisFlights? _flights;

  @override
  void initState() {
    super.initState();
    _lastSeenDone = ref.read(analysisQueueProvider).done;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AnalysisFlights? flights = AnalysisFlightScope.of(context);
    if (identical(flights, _flights)) return;
    _flights?.busy.removeListener(_onFlightsChanged);
    _flights = flights?..busy.addListener(_onFlightsChanged);
  }

  @override
  void dispose() {
    _flights?.busy.removeListener(_onFlightsChanged);
    super.dispose();
  }

  bool get _flying => _flights?.busy.value ?? false;

  int get _pending => widget.entries.where((entry) => entry.isPending).length;

  /// Özet, tur bitmiş ve son kart inmişken görünür.
  bool get _summaryVisible => ref.read(analysisSummaryProvider) && !_flying;

  void _onFlightsChanged() {
    if (!mounted) return;
    _maybeCelebrate();
    setState(() {});
  }

  /// Yeni tamamlananları uçuşa verir.
  void _onQueueChanged(AnalysisQueueState? previous, AnalysisQueueState next) {
    if (next.done < _lastSeenDone) _lastSeenDone = next.done; // yeni tur
    final int fresh = next.done - _lastSeenDone;
    if (fresh <= 0) return;
    _lastSeenDone = next.done;
    final ScreenshotRepository repo = ref.read(screenshotRepositoryProvider);
    final int take = math.min(fresh, next.recent.length);
    _flights?.enqueue([
      for (final AnalyzedItem item in next.recent.skip(
        next.recent.length - take,
      ))
        (asset: repo.assetFor(item.assetId), category: item.category),
    ]);
  }

  /// Özet göründüğü karede (son kart inince) başarı haptiği; yalnız tur
  /// sorunsuz tamamlandıysa.
  void _maybeCelebrate() {
    if (!ref.read(analysisSummaryProvider)) {
      _celebrated = false;
      return;
    }
    if (_celebrated || _flying) return;
    _celebrated = true;
    if (ref.read(analysisQueueProvider).status ==
        AnalysisQueueStatus.completed) {
      Haptics.success();
    }
  }

  void _start() {
    Haptics.analysisStart();
    _flights?.clear();
    ref.read(analysisQueueProvider.notifier).start();
  }

  /// Özet kapanır; haftalık hak bu turda bittiyse milestone açılır, başarılı
  /// turda değerlendirme istenir (cooldown'lı).
  void _onDone() {
    final AnalysisQueueState queue = ref.read(analysisQueueProvider);
    final bool milestone =
        queue.status == AnalysisQueueStatus.limitReached &&
        queue.freeQuotaExhausted;
    final bool success = queue.status == AnalysisQueueStatus.completed;
    ref.read(analysisSummaryProvider.notifier).dismiss();
    ref.read(analysisQueueProvider.notifier).dismiss();
    if (milestone) {
      context.push(AppRoutes.analysisMilestone);
    } else if (success) {
      ref.read(reviewServiceProvider).requestIfAppropriate();
    }
  }

  /// Duraklat: aktif istek biter, yenisi başlamaz; analiz edilenler kayıtlı
  /// kalır ve kalanlar daha sonra "Analiz et" ile sürer. Hiç analiz yoksa
  /// özet yerine doğrudan boşta duruma dönülür.
  Future<void> _confirmPause() async {
    Haptics.tap();
    final l10n = context.l10n;
    final bool pause = await showConfirmAlert(
      context,
      title: l10n.analysisPauseTitle,
      message: l10n.analysisPauseBody,
      confirmLabel: l10n.analysisPauseAction,
      cancelLabel: l10n.analysisContinueAction,
    );
    if (!pause || !mounted) return;
    final AnalysisQueueNotifier notifier = ref.read(
      analysisQueueProvider.notifier,
    );
    notifier.cancel();
    if (ref.read(analysisQueueProvider).done == 0) notifier.reset();
    _flights?.clear();
  }

  void _openPacks() => context.push(AppRoutes.paywallPacks);

  void _dismissResult() => ref.read(analysisQueueProvider.notifier).dismiss();

  /// Kalan hak metni. Sıra önemli: deneme penceresi (Pro sayılsa da sınırlı)
  /// önce, sonra sınırsız Pro, aksi halde haftalık ücretsiz (+ kredi).
  String _quotaHint(EntitlementState e) {
    final l10n = context.l10n;
    if (e.isInTrialWindow) {
      return l10n.analyzeHeroTrialHint(
        e.remainingTrialAnalysis + e.analysisCredits,
      );
    }
    if (e.isPro) return l10n.analyzeHeroUnlimited;
    if (e.analysisCredits > 0) {
      return l10n.analyzeHeroQuotaWithCredits(
        e.remainingFreeAnalysis,
        FreeLimits.aiAnalysis,
        e.analysisCredits,
      );
    }
    return l10n.analyzeHeroQuotaHint(
      e.remainingFreeAnalysis,
      FreeLimits.aiAnalysis,
    );
  }

  /// Hak bittiğinde: denemede neden bittiği, ücretsizde ne zaman yenileneceği.
  String _quotaExhaustedDetail(EntitlementState e) {
    final l10n = context.l10n;
    if (e.isInTrialWindow) return l10n.analysisTrialQuotaUsed;
    // Kalan gün yukarı yuvarlanır: pencere içinde en az 1 gösterilir.
    final int days =
        (e.nextWeeklyReset.difference(DateTime.now()).inHours /
                Duration.hoursPerDay)
            .ceil()
            .clamp(1, FreeLimits.aiAnalysisWindow.inDays);
    return l10n.homeWeeklyLimitResetIn(days);
  }

  AssetEntity? _nextSource() {
    for (final ScreenshotEntry entry in widget.entries) {
      if (entry.isPending) {
        return ref.read(screenshotRepositoryProvider).assetFor(entry.assetId);
      }
    }
    return null;
  }

  /// (anahtar, görünüm) — görünüm null ise modül gizlenir.
  (String, Widget?) _view(AnalysisQueueState queue, EntitlementState e) {
    if (_summaryVisible) {
      return (
        'summary',
        AnalysisSummaryRow(
          done: queue.done,
          categories: queue.categoryCounts.length,
          onDone: _onDone,
        ),
      );
    }
    if (queue.isRunning || _flying) {
      return (
        'progress',
        AnalysisProgressCard(
          processed: queue.done + queue.failed,
          total: queue.total,
          source: _nextSource(),
          onPause: _confirmPause,
        ),
      );
    }
    return switch (queue.status) {
      AnalysisQueueStatus.limitReached ||
      AnalysisQueueStatus.failed ||
      AnalysisQueueStatus.dailyCapReached => _resultView(queue.status, e),
      AnalysisQueueStatus.idle ||
      AnalysisQueueStatus.running ||
      AnalysisQueueStatus.completed => _pendingView(e),
    };
  }

  /// Tur sorunla bittiğinde: limit, hata ya da günlük tavan satırı.
  (String, Widget) _resultView(AnalysisQueueStatus status, EntitlementState e) {
    final l10n = context.l10n;
    return switch (status) {
      AnalysisQueueStatus.limitReached => (
        'limit',
        AnalysisMessageRow(
          icon: AppIcons.quota,
          text: e.isInTrialWindow
              ? l10n.analysisTrialLimitBanner
              : l10n.analysisLimitBanner,
          actionLabel: l10n.analysisGetMoreAction,
          onAction: _openPacks,
          onDismiss: _dismissResult,
        ),
      ),
      AnalysisQueueStatus.failed => (
        'failed',
        AnalysisMessageRow(
          icon: AppIcons.error,
          text: l10n.analysisFailedBanner,
          actionLabel: l10n.analysisRetryAction,
          onAction: _start,
          onDismiss: _dismissResult,
        ),
      ),
      _ => (
        'dailyCap',
        AnalysisMessageRow(
          icon: AppIcons.schedule,
          text: l10n.analysisDailyCapBanner,
          onDismiss: _dismissResult,
        ),
      ),
    };
  }

  /// Boşta: bekleyen varsa hak durumuna göre kart ya da kota satırı.
  (String, Widget?) _pendingView(EntitlementState e) {
    final int pending = _pending;
    if (pending == 0) return ('hidden', null);
    if (!e.canAnalyze) {
      return (
        'quota',
        AnalysisQuotaRow(
          pending: pending,
          detail: _quotaExhaustedDetail(e),
          onGetMore: _openPacks,
        ),
      );
    }
    return (
      'pending',
      AnalysisPendingCard(
        pending: pending,
        quotaHint: _quotaHint(e),
        onAnalyze: _start,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(analysisQueueProvider, _onQueueChanged);
    ref.listen(analysisSummaryProvider, (_, _) => _maybeCelebrate());
    ref.watch(analysisSummaryProvider);
    final AnalysisQueueState queue = ref.watch(analysisQueueProvider);
    final EntitlementState entitlement = ref.watch(entitlementProvider);
    final (String phase, Widget? view) = _view(queue, entitlement);

    // Kaynak anahtarı geçişin dışında: çıkan ve giren görünüm aynı anda
    // ağaçta dururken GlobalKey çakışmaz; uçuşlar kutunun sol-ortasından
    // (ilerleme kartındaki küçük resim) kalkar.
    return AnimatedSize(
      key: _flights?.sourceKey,
      duration: AppDurations.medium,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppDurations.medium,
        child: view == null
            ? const SizedBox(
                key: ValueKey<String>('hidden'),
                width: double.infinity,
              )
            : Padding(
                key: ValueKey<String>(phase),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: view,
              ),
      ),
    );
  }
}
