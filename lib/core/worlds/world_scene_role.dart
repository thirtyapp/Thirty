/// The visual need an activity has (WORLD_SYSTEM.md §3, "Scene Role").
///
/// An activity names only its role — never a World. Worlds implement roles
/// through their Scenes, and a selection policy (`world_scene_policy.dart`)
/// picks the concrete Scene for a role, so a future World can serve an
/// existing role without any activity changing.
enum WorldSceneRole {
  walk,
  breathe,
  move,
  stretch,
  read,
  write,
  listen,
  tend,
  comfort,
}
