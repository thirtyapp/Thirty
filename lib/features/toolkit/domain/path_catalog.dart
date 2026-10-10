/// The launch Path templates (V2 Phase D, ADR-022): two per need, each
/// with one distinct job — the routine it builds.
///
/// A Path is not a course, a challenge or a schedule. It is a bounded run
/// of Circles that tries a few pieces, short then full, then joined, and
/// ends with a routine the user keeps. Its pieces are three modules
/// ([pool]); the user's own evidence decides their order when there is
/// any.
library;

import '../../home/application/activity_catalog.dart';
import 'module_library.dart';

/// A Path template's stable identity — stored in Path runs, routines and
/// journal entries; never removed or renamed.
enum PathTemplateId {
  wakeUpIndoors,
  outTheDoor,
  clearTheDecks,
  awayFromTheScreen,
  softLanding,
  slowTimeOutside,
}

class PathTemplate {
  const PathTemplate({
    required this.id,
    required this.need,
    required this.name,
    required this.building,
    required this.routineName,
    required this.pool,
  });

  final PathTemplateId id;
  final Intention need;

  /// What the user sees: "A lift at home".
  final String name;

  /// "What am I building?" — answered before the Path starts.
  final String building;

  /// The name the routine it builds starts with. The user can rename it.
  final String routineName;

  /// The three pieces this Path works with, in its default order: the
  /// first two are tried first; the third is the alternative.
  final List<ModuleId> pool;
}

const List<PathTemplate> pathCatalog = [
  PathTemplate(
    id: PathTemplateId.wakeUpIndoors,
    need: Intention.moreEnergy,
    name: 'A lift at home',
    building:
        'A short movement routine for when you want a little more energy '
        '— all at home, about 15 to 25 minutes.',
    routineName: 'My pick-me-up',
    pool: [ModuleId.standingStretch, ModuleId.musicMove, ModuleId.activeTask],
  ),
  PathTemplate(
    id: PathTemplateId.outTheDoor,
    need: Intention.moreEnergy,
    name: 'Out the door',
    building:
        'A routine built around a brisk walk for when you want a little '
        'more energy — about 25 to 30 minutes.',
    routineName: 'My brisk walk',
    pool: [
      ModuleId.briskWalk,
      ModuleId.standingStretch,
      ModuleId.phoneFreeWalk,
    ],
  ),
  PathTemplate(
    id: PathTemplateId.clearTheDecks,
    need: Intention.clearerHead,
    name: 'Clear the decks',
    building:
        'What’s in your head onto paper, and one space cleared, so the next '
        'thing has room — about 20 to 30 minutes.',
    routineName: 'My reset',
    pool: [ModuleId.writeDown, ModuleId.clearSurface, ModuleId.standingStretch],
  ),
  PathTemplate(
    id: PathTemplateId.awayFromTheScreen,
    need: Intention.clearerHead,
    name: 'Away from the screen',
    building:
        'Less coming in for a while, for when your head is full — about 30 '
        'minutes.',
    routineName: 'My screen break',
    pool: [ModuleId.phoneFreeWalk, ModuleId.listenOne, ModuleId.writeDown],
  ),
  PathTemplate(
    id: PathTemplateId.softLanding,
    need: Intention.gentlerPace,
    name: 'A soft landing',
    building:
        'An unhurried routine at home, for slowing right down — about 20 to '
        '25 minutes.',
    routineName: 'My quiet pause',
    pool: [ModuleId.warmDrink, ModuleId.gentleStretch, ModuleId.quietMusic],
  ),
  PathTemplate(
    id: PathTemplateId.slowTimeOutside,
    need: Intention.gentlerPace,
    name: 'Easy time outdoors',
    building:
        'Unhurried time outside, walking and sitting at your own pace — '
        'about 25 to 30 minutes.',
    routineName: 'My time outdoors',
    pool: [ModuleId.easyWalk, ModuleId.sitOutside, ModuleId.gentleStretch],
  ),
];

PathTemplate pathTemplate(PathTemplateId id) =>
    pathCatalog.firstWhere((template) => template.id == id);

List<PathTemplate> pathsFor(Intention need) => [
  for (final template in pathCatalog)
    if (template.need == need) template,
];
