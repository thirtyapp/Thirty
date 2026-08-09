/// The activity family a recommendation — and the World that accompanies
/// it — belongs to (WORLD_SYSTEM.md §3, "Category": "the recommendation
/// family, such as walking, meditation, reading or stretching").
///
/// This is the single source of truth for that classification. It is
/// shared by the Home feature's recommendation logic (which illustration
/// represents today's recommendation) and the World Engine (which [Place]s
/// are available for a [World]) — both are the same axis described by
/// WORLD_SYSTEM.md, not two separate concepts, so there is deliberately
/// only one type for it, living in `core/` rather than nested under a
/// single feature or under `core/worlds/`.
///
/// [walking] is the only category with an approved [Place] today.
/// WORLD_SYSTEM.md §16 names Meditation, Reading and Stretching only as
/// placeholders for future categories; each of those is added here only
/// once it has an approved Place, never speculatively ahead of one.
///
/// [generalWellness] is a deliberate, documented exception to that rule,
/// introduced by Recommendation MVP v0
/// (`docs/product/recommendation-mvp-v0.md`): a neutral category for
/// non-walking activities (e.g. quiet reading, writing something down) that
/// do not yet have an approved Place. It exists so those activities are
/// categorized honestly rather than mislabeled as [walking] — it is not
/// itself a World/Place identity, and `circle_hero.dart` renders it with
/// the same illustration as [walking] until a Place is designed for it.
enum ActivityCategory { walking, generalWellness }
