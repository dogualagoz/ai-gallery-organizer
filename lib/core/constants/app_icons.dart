// Semantik ikon sözlüğü: SF Symbols karşılığı CupertinoIcons, tek kaynaktan.
import 'package:flutter/cupertino.dart';

/// Uygulama genelinde ikonlar anlamlarıyla adlandırılır; aynı eylem her
/// ekranda aynı glifle görünür (Familiarity). Material `Icons.*` yerine
/// yalnız bu sözlük kullanılır.
abstract final class AppIcons {
  // Sekmeler (dolgulu = seçili).
  static const IconData library = CupertinoIcons.photo_on_rectangle;
  static const IconData libraryFill =
      CupertinoIcons.photo_fill_on_rectangle_fill;
  static const IconData clean = CupertinoIcons.hand_draw;
  static const IconData cleanFill = CupertinoIcons.hand_draw_fill;
  static const IconData search = CupertinoIcons.search;
  static const IconData settings = CupertinoIcons.gear_alt;
  static const IconData settingsFill = CupertinoIcons.gear_alt_fill;

  // Eylemler.
  static const IconData analyze = CupertinoIcons.sparkles;
  static const IconData delete = CupertinoIcons.trash;
  static const IconData share = CupertinoIcons.square_arrow_up;
  static const IconData edit = CupertinoIcons.pencil;
  static const IconData more = CupertinoIcons.ellipsis_circle;
  static const IconData move = CupertinoIcons.folder;
  static const IconData addToBoard = CupertinoIcons.folder_badge_plus;
  static const IconData add = CupertinoIcons.plus;
  static const IconData close = CupertinoIcons.xmark;
  static const IconData undo = CupertinoIcons.arrow_uturn_left;
  static const IconData reanalyze = CupertinoIcons.arrow_clockwise;
  static const IconData restore = CupertinoIcons.arrow_counterclockwise;
  static const IconData sync = CupertinoIcons.arrow_2_circlepath;
  static const IconData skip = CupertinoIcons.arrow_up;
  static const IconData stop = CupertinoIcons.stop_circle;
  static const IconData pause = CupertinoIcons.pause_circle;
  static const IconData select = CupertinoIcons.checkmark_circle;
  static const IconData redeem = CupertinoIcons.gift;
  static const IconData copy = CupertinoIcons.doc_on_doc;

  // Durum ve gezinme.
  static const IconData back = CupertinoIcons.chevron_left;
  static const IconData chevronRight = CupertinoIcons.chevron_right;
  static const IconData chevronDown = CupertinoIcons.chevron_down;
  static const IconData check = CupertinoIcons.checkmark;
  static const IconData checkCircleFill = CupertinoIcons.checkmark_circle_fill;
  static const IconData circle = CupertinoIcons.circle;
  static const IconData info = CupertinoIcons.info_circle;
  static const IconData infoFill = CupertinoIcons.info_circle_fill;
  static const IconData error = CupertinoIcons.exclamationmark_circle;
  static const IconData warning = CupertinoIcons.exclamationmark_triangle;
  static const IconData lock = CupertinoIcons.lock_fill;
  static const IconData lockOpen = CupertinoIcons.lock_open;
  static const IconData pro = CupertinoIcons.rosette;
  static const IconData quota = CupertinoIcons.hourglass;
  static const IconData schedule = CupertinoIcons.clock;
  static const IconData unlimited = CupertinoIcons.infinite;
  static const IconData bolt = CupertinoIcons.bolt_fill;

  // İçerik ve ayarlar.
  static const IconData photo = CupertinoIcons.photo;
  static const IconData board = CupertinoIcons.rectangle_stack;
  static const IconData grid = CupertinoIcons.square_grid_2x2;
  static const IconData privacy = CupertinoIcons.hand_raised;
  static const IconData shield = CupertinoIcons.shield;
  static const IconData themeLight = CupertinoIcons.sun_max;
  static const IconData themeDark = CupertinoIcons.moon;
  static const IconData themeSystem = CupertinoIcons.circle_lefthalf_fill;
  static const IconData notifications = CupertinoIcons.bell;
  static const IconData rate = CupertinoIcons.star;
  static const IconData feedback = CupertinoIcons.envelope;
}
