import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/thirty_confirm_dialog.dart';
import '../application/circle_plans_provider.dart';
import '../domain/circle_plan.dart';
import '../domain/plan_copy.dart';
import 'plan_view.dart';

/// Where a Plan's detail page lives.
String planLocation(String planId) => '/plans/$planId';

/// Runs [primary] for [plan]: Premium's own offer for Free, otherwise the
/// Plan notifier's action — never a change made here. Starting or carrying
/// on one Plan while another is active says first that the other pauses at
/// its place (the notifier pauses it).
Future<void> runPlanPrimary(
  BuildContext context,
  WidgetRef ref,
  CirclePlanDefinition plan,
  PlanPrimary primary,
) async {
  final plans = ref.read(circlePlansProvider.notifier);
  switch (primary) {
    case PlanPrimary.startWithPremium:
    case PlanPrimary.continueWithPremium:
      await context.push('/premium');
    case PlanPrimary.goToToday:
    case PlanPrimary.openToday:
      context.go('/');
    case PlanPrimary.seeReview:
      context.go(planLocation(plan.id));
    case PlanPrimary.start:
    case PlanPrimary.carryOn:
      if (!await _confirmSwitch(context, ref, plan, primary)) return;
      final result = primary == PlanPrimary.start
          ? plans.start(plan.id)
          : plans.resume(plan.id);
      if (result == PlanActionResult.needsPremium && context.mounted) {
        await context.push('/premium');
      }
  }
}

Future<bool> _confirmSwitch(
  BuildContext context,
  WidgetRef ref,
  CirclePlanDefinition plan,
  PlanPrimary primary,
) async {
  final active = ref.read(circlePlansProvider).active;
  if (active == null || active.planId == plan.id) return true;
  final confirmed = await showDialog<bool>(
    context: context,
    barrierLabel: PlanCopy.switchCancel,
    builder: (_) => ThirtyConfirmDialog(
      title: PlanCopy.switchTitle,
      body: PlanCopy.switchBody(
        plan.name,
        active.definition.name,
        active.current.cursor,
      ),
      cancelLabel: PlanCopy.switchCancel,
      confirmLabel: primary == PlanPrimary.start
          ? PlanCopy.start
          : PlanCopy.carryOn,
    ),
  );
  return confirmed == true;
}

/// "Leave this Plan?" — its Circles stay in History; starting again begins
/// at stage 1.
Future<void> confirmLeave(
  BuildContext context,
  WidgetRef ref,
  CirclePlanDefinition plan,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierLabel: PlanCopy.leaveCancel,
    builder: (_) => const ThirtyConfirmDialog(
      title: PlanCopy.leaveTitle,
      body: PlanCopy.leaveBody,
      cancelLabel: PlanCopy.leaveCancel,
      confirmLabel: 'Leave',
    ),
  );
  if (confirmed == true) ref.read(circlePlansProvider.notifier).leave(plan.id);
}

/// The label of [primary].
String planPrimaryLabel(PlanPrimary primary) => switch (primary) {
  PlanPrimary.startWithPremium => PlanCopy.startWithPremium,
  PlanPrimary.start => PlanCopy.start,
  PlanPrimary.carryOn => PlanCopy.carryOn,
  PlanPrimary.continueWithPremium => PlanCopy.continueWithPremium,
  PlanPrimary.goToToday => PlanCopy.goToToday,
  PlanPrimary.openToday => PlanCopy.openToday,
  PlanPrimary.seeReview => PlanCopy.seeReview,
};
