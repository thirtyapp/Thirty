import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home's one-time invitations, in the parent V1 prompt-priority order:
/// reflection (not an invitation, always first), then the reminder
/// invitation, then the Premium invitation — never two in one session.
enum HomeInvitation { reminder, premium }

/// Which invitation owns Home's invitation slot for the current app
/// session, and whether its owner has been closed.
///
/// Invitation semantics (founder decision after B3):
/// - **eligible** — the invitation qualifies under its existing rules
///   (`reminder_invitation_provider.dart`, `premium_offer_provider.dart`).
/// - **presented this session** — the first eligible invitation that
///   renders claims the slot and keeps it for the rest of the session,
///   so an unrelated provider refresh can never remove it or hand its
///   place to the other invitation. Only a real terminating condition
///   ("Not now", a chosen reminder time, reminders enabled — which closes
///   the reminder invitation for the rest of the session — Premium
///   entitlement) hides it.
/// - **persisted shown** — the existing `*_shown_v1` flag is written only
///   once the card has been meaningfully visible (`ViewportVisibility`),
///   never merely because it rendered below the fold.
///
/// Session-scoped by construction: plain in-memory Riverpod state, reset
/// only when the app process (and its `ProviderContainer`) restarts.
typedef HomeInvitationSlot = ({HomeInvitation? owner, bool closed});

class HomeInvitationSlotNotifier extends Notifier<HomeInvitationSlot> {
  @override
  HomeInvitationSlot build() => (owner: null, closed: false);

  /// Claims the slot for [invitation] if nothing owns it yet; a no-op
  /// otherwise (idempotent for the current owner).
  void claim(HomeInvitation invitation) {
    if (state.owner != null) return;
    state = (owner: invitation, closed: false);
  }

  /// Reminders were enabled: the reminder invitation is over for the rest
  /// of this session, whether or not it had been presented yet. If it
  /// owns the slot it closes; if nothing owns the slot yet, the reminder
  /// takes it already closed, so neither a later "disable" nor Premium can
  /// reopen it this session. A Premium invitation that already owns the
  /// slot is left alone.
  void closeReminderForSession() {
    if (state.owner == HomeInvitation.premium) return;
    state = (owner: HomeInvitation.reminder, closed: true);
  }

  /// Closes [invitation] for the rest of the session if it owns the slot.
  /// The slot stays owned, so the other invitation cannot take its place
  /// in the same session.
  void close(HomeInvitation invitation) {
    if (state.owner != invitation || state.closed) return;
    state = (owner: invitation, closed: true);
  }
}

final homeInvitationSlotProvider =
    NotifierProvider<HomeInvitationSlotNotifier, HomeInvitationSlot>(
      HomeInvitationSlotNotifier.new,
    );
