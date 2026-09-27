/// The internal World-compatibility family an activity belongs to
/// (WORLD_SYSTEM.md §3: Category is a compatibility axis, not a lookup).
///
/// A World declares which categories it serves
/// (`WorldDefinition.allowedCategories`); a category may be served by many
/// Worlds, and nothing resolves a category to exactly one Place. The
/// resolver uses it only to check that the Scene selected for an activity
/// belongs to a World allowed to show that activity.
///
/// These are internal classifications only — not the three user-facing
/// directions (`Intention`), not recommendation pools, and not a selection
/// signal (ADR-018).
enum ActivityCategory { walking, stillness, movement, quietFocus, homeCare }
