// Archivo: lib/core/config/theme/app_icons.dart
// PROHIBIDO usar emojis o referenciar Icons.*/FontAwesomeIcons.* directamente
// en widgets de pantalla. Todo ícono pasa por AppIcons.
// AppIcons no maneja estado; los maneja el widget consumidor.
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppIcons {
  AppIcons._();

  // ─── DOMINIO / BOT ────────────────────────────────────────────────────────
  // robot es solid en la capa gratuita de FA6; botUnitSolid usa mismo glifo con color gold.
  static const IconData botUnit      = FontAwesomeIcons.robot;
  static const IconData botUnitSolid = FontAwesomeIcons.robot;
  static const IconData blueprint    = FontAwesomeIcons.fileCode;

  // ─── NAVEGACIÓN / SHELL ───────────────────────────────────────────────────
  static const IconData dashboard    = FontAwesomeIcons.gaugeHigh;
  static const IconData bots         = FontAwesomeIcons.robot;
  static const IconData store        = FontAwesomeIcons.store;
  static const IconData billing      = FontAwesomeIcons.creditCard;
  static const IconData settings     = FontAwesomeIcons.gear;
  static const IconData chat         = FontAwesomeIcons.commentDots;
  static const IconData library      = FontAwesomeIcons.bookOpen;

  // ─── ACCIONES ─────────────────────────────────────────────────────────────
  static const IconData add          = FontAwesomeIcons.plus;
  static const IconData edit         = FontAwesomeIcons.penToSquare;
  static const IconData delete       = FontAwesomeIcons.trash;
  static const IconData save         = FontAwesomeIcons.floppyDisk;
  static const IconData copy         = FontAwesomeIcons.copy;
  static const IconData refresh      = FontAwesomeIcons.arrowsRotate;
  static const IconData search       = FontAwesomeIcons.magnifyingGlass;
  static const IconData filter       = FontAwesomeIcons.filter;
  static const IconData close        = FontAwesomeIcons.xmark;
  static const IconData check        = FontAwesomeIcons.check;
  static const IconData send         = FontAwesomeIcons.paperPlane;
  static const IconData upload       = FontAwesomeIcons.upload;
  static const IconData download     = FontAwesomeIcons.download;
  static const IconData link         = FontAwesomeIcons.link;
  static const IconData externalLink = FontAwesomeIcons.arrowUpRightFromSquare;
  static const IconData back         = FontAwesomeIcons.arrowLeft;
  static const IconData forward      = FontAwesomeIcons.arrowRight;

  // ─── ESTADO / SEMÁNTICA ───────────────────────────────────────────────────
  static const IconData online       = FontAwesomeIcons.circleCheck;
  static const IconData offline      = FontAwesomeIcons.circleXmark;
  static const IconData warning      = FontAwesomeIcons.triangleExclamation;
  static const IconData info         = FontAwesomeIcons.circleInfo;
  static const IconData error        = FontAwesomeIcons.circleExclamation;
  static const IconData loading      = FontAwesomeIcons.spinner;
  static const IconData maintenance  = FontAwesomeIcons.wrench;
  static const IconData lock         = FontAwesomeIcons.lock;
  static const IconData unlock       = FontAwesomeIcons.lockOpen;
  static const IconData power        = FontAwesomeIcons.powerOff;
  static const IconData connected    = FontAwesomeIcons.wifi;
  static const IconData disconnected = FontAwesomeIcons.plugCircleXmark;

  // ─── USUARIO / CUENTA ─────────────────────────────────────────────────────
  static const IconData user         = FontAwesomeIcons.user;
  static const IconData logout       = FontAwesomeIcons.rightFromBracket;

  // ─── BILLING / FINANZAS ───────────────────────────────────────────────────
  static const IconData creditCard   = FontAwesomeIcons.creditCard;
  static const IconData money        = FontAwesomeIcons.dollarSign;
  static const IconData invoice      = FontAwesomeIcons.fileInvoiceDollar;
  static const IconData plan         = FontAwesomeIcons.layerGroup;
  static const IconData autopay      = FontAwesomeIcons.clockRotateLeft;
  static const IconData paywall      = FontAwesomeIcons.ban;

  // ─── BOT / UNIDAD (extras de configuración) ───────────────────────────────
  static const IconData bot          = FontAwesomeIcons.robot;
  static const IconData mood         = FontAwesomeIcons.faceSmile;
  static const IconData knowledge    = FontAwesomeIcons.brain;
  static const IconData embed        = FontAwesomeIcons.code;
  static const IconData config       = FontAwesomeIcons.sliders;
  static const IconData metrics      = FontAwesomeIcons.chartLine;

  // ─── DATOS / HUD ──────────────────────────────────────────────────────────
  static const IconData signal       = FontAwesomeIcons.signal;
  static const IconData server       = FontAwesomeIcons.server;
  static const IconData cpu          = FontAwesomeIcons.microchip;
  static const IconData database     = FontAwesomeIcons.database;
  static const IconData network      = FontAwesomeIcons.networkWired;
  static const IconData terminal     = FontAwesomeIcons.terminal;

  // ─── NAVEGACIÓN SHELL (Material — solo chevrons y controles de ventana) ───
  static const IconData chevronRight = Icons.chevron_right;
  static const IconData chevronLeft  = Icons.chevron_left;
  static const IconData chevronDown  = Icons.expand_more;
  static const IconData winMinimize  = Icons.remove;
  static const IconData winMaximize  = Icons.crop_square;
  static const IconData winClose     = Icons.close;

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  /// Renderiza el ícono correcto según su origen (FontAwesome o Material).
  /// [size] default = AppDimens.iconM (22). Pasar `null` para heredar del IconTheme.
  static Widget icon(
    IconData data, {
    double? size,
    Color? color,
  }) {
    final s = size ?? 22;
    if (data.fontPackage == 'font_awesome_flutter') {
      return FaIcon(data, size: s, color: color);
    }
    return Icon(data, size: s, color: color);
  }

  /// Botón solo-ícono con tooltip semántico obligatorio (accesibilidad §8).
  /// Área de hit: se garantiza desde el widget contenedor con padding space8.
  static Widget iconButton({
    required IconData data,
    required String tooltip,
    required VoidCallback? onPressed,
    double? size,
    Color? color,
  }) {
    final s = size ?? 22;
    final child = data.fontPackage == 'font_awesome_flutter'
        ? FaIcon(data, size: s, color: color)
        : Icon(data, size: s, color: color);
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: child,
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}
