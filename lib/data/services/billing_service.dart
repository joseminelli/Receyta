import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:receyta/core/result.dart';
import 'package:receyta/core/revenuecat_config.dart';

enum PlanPeriod { monthly, annual }

/// Um plano à venda, já com o preço formatado pela loja.
@immutable
class PlanOption {
  const PlanOption({
    required this.period,
    required this.priceText,
    required this.price,
    required this.handle,
    this.perMonthText,
  });

  final PlanPeriod period;
  final String priceText;

  /// Valor numérico, na moeda da loja (só serve pra comparar os planos).
  final double price;

  /// "R$ 7,50" já formatado pela loja: quanto o plano custa por mês.
  final String? perMonthText;

  /// O pacote do RevenueCat; só o [BillingService] que o criou sabe usá-lo.
  final Object handle;
}

/// Porta de entrada da cobrança. A interface (e os testes) falam com isto,
/// nunca com o RevenueCat direto. A cobrança só liga o acesso: quem decide o
/// que a pessoa pode usar é o servidor (ver `docs/supabase/subscription.sql`).
abstract class BillingService {
  /// A loja está configurada neste aparelho.
  bool get available;

  /// Liga a assinatura à conta do Supabase (o webhook usa este id).
  Future<void> logIn(String userId);

  Future<void> logOut();

  /// Os planos à venda. Vazio se a loja não respondeu.
  Future<List<PlanOption>> plans();

  /// `Ok(false)` = a pessoa fechou a tela da loja.
  Future<Result<bool>> purchase(PlanOption plan);

  /// Devolve a assinatura de uma compra feita antes (aparelho novo).
  Future<Result<bool>> restore();
}

class RevenueCatBillingService implements BillingService {
  bool _configured = false;
  String? _userId;
  Future<void> _ready = Future<void>.value();

  @override
  bool get available => kRevenueCatAndroidKey.isNotEmpty;

  Future<void> _ensureConfigured(String userId) async {
    if (_configured) return;
    await Purchases.configure(
      PurchasesConfiguration(kRevenueCatAndroidKey)..appUserID = userId,
    );
    _configured = true;
  }

  @override
  Future<void> logIn(String userId) => _ready = _logIn(userId);

  Future<void> _logIn(String userId) async {
    if (!available) return;
    try {
      if (!_configured) {
        await _ensureConfigured(userId);
      } else if (_userId != userId) {
        await Purchases.logIn(userId);
      }
      _userId = userId;
    } catch (e) {
      debugPrint('Billing.logIn: $e');
    }
  }

  @override
  Future<void> logOut() async {
    if (!available || !_configured || _userId == null) return;
    _userId = null;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('Billing.logOut: $e');
    }
  }

  @override
  Future<List<PlanOption>> plans() async {
    await _ready;
    if (!available || _userId == null) return const [];
    try {
      final offering = (await Purchases.getOfferings()).current;
      if (offering == null) return const [];
      return [
        if (offering.monthly != null)
          PlanOption(
            period: PlanPeriod.monthly,
            priceText: offering.monthly!.storeProduct.priceString,
            price: offering.monthly!.storeProduct.price,
            perMonthText: offering.monthly!.storeProduct.pricePerMonthString,
            handle: offering.monthly!,
          ),
        if (offering.annual != null)
          PlanOption(
            period: PlanPeriod.annual,
            priceText: offering.annual!.storeProduct.priceString,
            price: offering.annual!.storeProduct.price,
            perMonthText: offering.annual!.storeProduct.pricePerMonthString,
            handle: offering.annual!,
          ),
      ];
    } catch (e) {
      debugPrint('Billing.plans: $e');
      return const [];
    }
  }

  @override
  Future<Result<bool>> purchase(PlanOption plan) async {
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(plan.handle as Package),
      );
      return Ok(_isLive(result.customerInfo));
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const Ok(false);
      }
      debugPrint('Billing.purchase: $e');
      return Err(_failure(code));
    } catch (e) {
      debugPrint('Billing.purchase: $e');
      return const Err(
        ProcessingFailure('Não foi possível concluir a compra agora.'),
      );
    }
  }

  @override
  Future<Result<bool>> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      if (_isLive(info)) return const Ok(true);
      if (info.entitlements.all.containsKey(kCloudEntitlement)) {
        return const Err(
          ProcessingFailure(
            'Encontramos uma assinatura, mas ela não está ativa: venceu ou '
            'há um problema de pagamento. Resolva na Google Play ou assine '
            'de novo.',
          ),
        );
      }
      return const Ok(false);
    } on PlatformException catch (e) {
      debugPrint('Billing.restore: $e');
      return Err(_failure(PurchasesErrorHelper.getErrorCode(e)));
    } catch (e) {
      debugPrint('Billing.restore: $e');
      return const Err(
        ProcessingFailure('Não foi possível restaurar agora.'),
      );
    }
  }

  /// Assinatura que vale agora. O RevenueCat também chama de "ativa" a que já
  /// venceu mas está em carência de pagamento; o servidor não, então aqui só
  /// vale quem ainda está dentro do período.
  bool _isLive(CustomerInfo info) {
    final entitlement = info.entitlements.active[kCloudEntitlement];
    if (entitlement == null) return false;
    final end = DateTime.tryParse(entitlement.expirationDate ?? '');
    return end == null || end.isAfter(DateTime.now());
  }

  Failure _failure(PurchasesErrorCode code) => switch (code) {
        PurchasesErrorCode.networkError => const NetworkFailure(
            'Sem conexão. Tente de novo quando a internet voltar.',
          ),
        PurchasesErrorCode.productAlreadyPurchasedError =>
          const ProcessingFailure(
            'Você já tem essa assinatura. Toque em "Restaurar compra".',
          ),
        PurchasesErrorCode.purchaseNotAllowedError => const ProcessingFailure(
            'A Google Play não está disponível neste aparelho.',
          ),
        _ => const ProcessingFailure(
            'Não foi possível concluir a compra agora.',
          ),
      };
}

/// Usado quando a loja não está configurada (sem chave, testes).
class UnavailableBillingService implements BillingService {
  const UnavailableBillingService();

  @override
  bool get available => false;

  @override
  Future<void> logIn(String userId) async {}

  @override
  Future<void> logOut() async {}

  @override
  Future<List<PlanOption>> plans() async => const [];

  @override
  Future<Result<bool>> purchase(PlanOption plan) async => const Err(
        ProcessingFailure('A compra não está disponível agora.'),
      );

  @override
  Future<Result<bool>> restore() async => const Err(
        ProcessingFailure('A compra não está disponível agora.'),
      );
}

final billingServiceProvider = Provider<BillingService>((ref) {
  if (kRevenueCatAndroidKey.isEmpty ||
      defaultTargetPlatform != TargetPlatform.android) {
    return const UnavailableBillingService();
  }
  return RevenueCatBillingService();
});
