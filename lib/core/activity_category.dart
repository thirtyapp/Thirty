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
/// Only [walking] is a shipped value today. WORLD_SYSTEM.md §16 names
/// Meditation, Reading and Stretching only as placeholders for future
/// categories; each is added here only once it has an approved [Place],
/// never speculatively ahead of one.
enum ActivityCategory { walking }
