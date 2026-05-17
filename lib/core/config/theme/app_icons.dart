// lib/core/config/theme/app_icons.dart
// Set unificado de iconos «Hangar OS».
// Base: FontAwesome (font_awesome_flutter) para coherencia de trazo.
// Regla: NO usar emojis como iconos. Grosor de trazo coherente en toda la app.
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppIcons {
  // ─── TAMAÑOS ──────────────────────────────────────────────────────────────
  static const double sizeXS = 12;
  static const double sizeS  = 16;
  static const double sizeM  = 20;  // tamaño estándar de UI
  static const double sizeL  = 24;
  static const double sizeXL = 32;

  // ─── NAVEGACIÓN / SHELL ───────────────────────────────────────────────────
  static const IconData dashboard   = FontAwesomeIcons.tableCellsLarge;
  static const IconData bots        = FontAwesomeIcons.robot;
  static const IconData store       = FontAwesomeIcons.store;
  static const IconData billing     = FontAwesomeIcons.creditCard;
  static const IconData settings    = FontAwesomeIcons.gear;
  static const IconData chat        = FontAwesomeIcons.commentDots;
  static const IconData library     = FontAwesomeIcons.bookOpen;

  // ─── ACCIONES ─────────────────────────────────────────────────────────────
  static const IconData add         = FontAwesomeIcons.plus;
  static const IconData edit        = FontAwesomeIcons.pen;
  static const IconData delete      = FontAwesomeIcons.trash;
  static const IconData save        = FontAwesomeIcons.floppyDisk;
  static const IconData copy        = FontAwesomeIcons.copy;
  static const IconData refresh     = FontAwesomeIcons.arrowsRotate;
  static const IconData search      = FontAwesomeIcons.magnifyingGlass;
  static const IconData filter      = FontAwesomeIcons.filter;
  static const IconData close       = FontAwesomeIcons.xmark;
  static const IconData back        = FontAwesomeIcons.arrowLeft;
  static const IconData forward     = FontAwesomeIcons.arrowRight;
  static const IconData send        = FontAwesomeIcons.paperPlane;
  static const IconData upload      = FontAwesomeIcons.upload;
  static const IconData download    = FontAwesomeIcons.download;
  static const IconData link        = FontAwesomeIcons.link;
  static const IconData externalLink= FontAwesomeIcons.arrowUpRightFromSquare;

  // ─── ESTADO ───────────────────────────────────────────────────────────────
  static const IconData online      = FontAwesomeIcons.circleCheck;
  static const IconData offline     = FontAwesomeIcons.circleXmark;
  static const IconData warning     = FontAwesomeIcons.triangleExclamation;
  static const IconData info        = FontAwesomeIcons.circleInfo;
  static const IconData error       = FontAwesomeIcons.circleExclamation;
  static const IconData loading     = FontAwesomeIcons.spinner;
  static const IconData maintenance = FontAwesomeIcons.wrench;
  static const IconData lock        = FontAwesomeIcons.lock;
  static const IconData unlock      = FontAwesomeIcons.lockOpen;

  // ─── BILLING / FINANZAS ───────────────────────────────────────────────────
  static const IconData creditCard  = FontAwesomeIcons.creditCard;
  static const IconData money       = FontAwesomeIcons.dollarSign;
  static const IconData invoice     = FontAwesomeIcons.fileInvoiceDollar;
  static const IconData plan        = FontAwesomeIcons.layerGroup;
  static const IconData autopay     = FontAwesomeIcons.clockRotateLeft;
  static const IconData paywall     = FontAwesomeIcons.ban;

  // ─── BOT / UNIDAD ─────────────────────────────────────────────────────────
  static const IconData bot         = FontAwesomeIcons.robot;
  static const IconData mood        = FontAwesomeIcons.faceSmile;
  static const IconData knowledge   = FontAwesomeIcons.brain;
  static const IconData embed       = FontAwesomeIcons.code;
  static const IconData config      = FontAwesomeIcons.sliders;
  static const IconData metrics     = FontAwesomeIcons.chartLine;

  // ─── DATOS / HUD ──────────────────────────────────────────────────────────
  static const IconData signal      = FontAwesomeIcons.signal;
  static const IconData server      = FontAwesomeIcons.server;
  static const IconData cpu         = FontAwesomeIcons.microchip;
  static const IconData database    = FontAwesomeIcons.database;
  static const IconData network     = FontAwesomeIcons.networkWired;
  static const IconData terminal    = FontAwesomeIcons.terminal;

  // ─── HELPER: widget de icono con tamaño y color estándar ──────────────────
  static Widget icon(
    IconData data, {
    double size = sizeM,
    Color? color,
  }) =>
      FaIcon(data, size: size, color: color);

  /// Icono con tooltip semántico (obligatorio en botones solo-ícono).
  static Widget iconButton({
    required IconData data,
    required String tooltip,
    required VoidCallback? onPressed,
    double size = sizeM,
    Color? color,
  }) =>
      Tooltip(
        message: tooltip,
        child: IconButton(
          icon: FaIcon(data, size: size, color: color),
          onPressed: onPressed,
          tooltip: tooltip,
        ),
      );
}
