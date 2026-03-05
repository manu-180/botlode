import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/features/wpp_inbox/domain/models/wpp_conversation.dart';
import 'package:botslode/features/wpp_inbox/domain/models/wpp_message.dart';
import 'package:botslode/features/wpp_inbox/presentation/providers/wpp_inbox_provider.dart';

Widget _bullet(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: TextStyle(color: AppColors.primary, fontSize: 11)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontFamily: 'Oxanium',
            ),
          ),
        ),
      ],
    ),
  );
}

class WppInboxView extends ConsumerWidget {
  static const String routeName = 'inbox';

  const WppInboxView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeConversationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Panel izquierdo: lista de conversaciones
          const SizedBox(
            width: 320,
            child: _ConversationList(),
          ),
          // Divisor
          VerticalDivider(
            width: 1,
            color: AppColors.borderGlass,
          ),
          // Panel derecho: chat o placeholder
          Expanded(
            child: active != null
                ? _ChatPanel(conversation: active)
                : const _EmptyState(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lista de conversaciones
// ---------------------------------------------------------------------------

class _ConversationList extends ConsumerWidget {
  const _ConversationList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(wppConversationsProvider);
    final active = ref.watch(activeConversationProvider);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              bottom: BorderSide(color: AppColors.borderGlass),
              right:  BorderSide(color: AppColors.borderGlass),
            ),
          ),
          child: Row(
            children: [
              FaIcon(FontAwesomeIcons.whatsapp, color: AppColors.success, size: 18),
              const SizedBox(width: 10),
              Text(
                'INBOX',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oxanium',
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),

        // Lista
        Expanded(
          child: convsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e',
                  style: TextStyle(color: AppColors.error, fontSize: 12)),
            ),
            data: (convs) {
              if (convs.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(FontAwesomeIcons.commentSlash,
                            color: AppColors.textSecondary.withValues(alpha: 0.3),
                            size: 40),
                        const SizedBox(height: 16),
                        Text(
                          'Sin mensajes aún',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontFamily: 'Oxanium',
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Las respuestas al número Assistify (+5491125303794)\naparecerán acá cuando lleguen.',
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.6),
                            fontFamily: 'Oxanium',
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderGlass),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Si enviaste un mensaje y no aparece, revisá:',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontFamily: 'Oxanium',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _bullet('Ejecutaste la migración SQL en Supabase (tablas wpp_conversations y wpp_messages).'),
                              _bullet('En Twilio Console → WhatsApp Senders → tu número → "A message comes in" está la URL de la Edge Function.'),
                              _bullet('La Edge Function "twilio-webhook" está desplegada y en Logs ves "[twilio-webhook] REQUEST RECIBIDO" al enviar un mensaje.'),
                              _bullet('Si configuraste TWILIO_ACCOUNT_SID en Supabase Secrets, que coincida con el Account SID de Twilio.'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                itemCount: convs.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: AppColors.borderGlass),
                itemBuilder: (context, i) {
                  final conv = convs[i];
                  final isActive = active?.id == conv.id;
                  return _ConversationTile(
                    conversation: conv,
                    isActive: isActive,
                    onTap: () {
                      ref.read(activeConversationProvider.notifier).state = conv;
                      ref.read(wppConversationsProvider.notifier).markAsRead(conv.id);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
  });

  final WppConversation conversation;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;
    final timeLabel = conversation.lastMessageAt != null
        ? _formatTime(conversation.lastMessageAt!)
        : '';

    return Material(
      color: isActive
          ? AppColors.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: isActive
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 3),
                  ),
                )
              : null,
          child: Row(
            children: [
              // Avatar con inicial
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    _initial(conversation.title),
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Oxanium',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nombre + último mensaje
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.title,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontFamily: 'Oxanium',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeLabel,
                          style: TextStyle(
                            color: hasUnread
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontSize: 10,
                            fontFamily: 'Oxanium',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessageBody ?? '—',
                            style: TextStyle(
                              color: hasUnread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontFamily: 'Oxanium',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initial(String title) {
    if (title.isEmpty) return '?';
    // Si el título es un número, mostrar el ícono de teléfono como texto
    if (title.startsWith('+')) return '#';
    return title[0].toUpperCase();
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    if (local.day == now.day && local.month == now.month && local.year == now.year) {
      return DateFormat('HH:mm').format(local);
    }
    return DateFormat('dd/MM').format(local);
  }
}

// ---------------------------------------------------------------------------
// Panel de chat
// ---------------------------------------------------------------------------

class _ChatPanel extends ConsumerStatefulWidget {
  const _ChatPanel({required this.conversation});
  final WppConversation conversation;

  @override
  ConsumerState<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<_ChatPanel> {
  final _scrollCtrl   = ScrollController();
  final _textCtrl     = TextEditingController();
  final _focusNode    = FocusNode();
  bool _sending       = false;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendReply() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _textCtrl.clear();

    final ok = await ref.read(wppReplyServiceProvider).sendReply(
      conversationId: widget.conversation.id,
      toPhoneNumber:  widget.conversation.phoneNumber,
      body:           text,
    );

    if (mounted) {
      setState(() => _sending = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo enviar el mensaje'),
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(wppMessagesProvider(widget.conversation.id));

    // Auto-scroll cuando llegan mensajes nuevos
    messagesAsync.whenData((_) => _scrollToBottom());

    return Column(
      children: [
        // Header del chat
        _buildHeader(),
        const Divider(height: 1),

        // Mensajes
        Expanded(
          child: messagesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(
              child: Text('Error cargando mensajes: $e',
                  style: TextStyle(color: AppColors.error)),
            ),
            data: (messages) {
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'Sin mensajes en esta conversación',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Oxanium',
                      fontSize: 12,
                    ),
                  ),
                );
              }
              return ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final msg = messages[i];
                  final showDate = i == 0 ||
                      !_sameDay(messages[i - 1].createdAt, msg.createdAt);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showDate) _DateDivider(date: msg.createdAt),
                      _MessageBubble(
                        message:  msg,
                        showName: widget.conversation.title,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),

        // Input de respuesta
        _buildInputBar(),
      ],
    );
  }

  Widget _buildHeader() {
    final conv = widget.conversation;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: AppColors.surface,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                conv.title.isEmpty ? '?' : conv.title[0].toUpperCase(),
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oxanium',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conv.title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Oxanium',
                ),
              ),
              Text(
                conv.phoneNumber.replaceFirst('whatsapp:', ''),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontFamily: 'Oxanium',
                ),
              ),
            ],
          ),
          const Spacer(),
          Tooltip(
            message: 'Respuesta libre disponible durante 24h desde el último mensaje del contacto.',
            child: Icon(Icons.info_outline,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderGlass)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderGlass),
              ),
              child: TextField(
                controller: _textCtrl,
                focusNode: _focusNode,
                maxLines: null,
                minLines: 1,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontFamily: 'Oxanium',
                ),
                decoration: InputDecoration(
                  hintText: 'Escribí tu respuesta…',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontFamily: 'Oxanium',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendReply(),
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _sending
              ? SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.success,
                  ),
                )
              : Material(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: _sendReply,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }
}

// ---------------------------------------------------------------------------
// Burbuja de mensaje
// ---------------------------------------------------------------------------

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.showName});
  final WppMessage message;
  final String showName;

  @override
  Widget build(BuildContext context) {
    final isOut = message.isOutbound;

    return Align(
      alignment: isOut ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4, bottom: 4,
          left:  isOut ? 64 : 0,
          right: isOut ? 0  : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOut
              ? AppColors.primary.withValues(alpha: 0.85)
              : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  isOut ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isOut ? const Radius.circular(4)  : const Radius.circular(18),
          ),
          border: isOut
              ? null
              : Border.all(color: AppColors.borderGlass),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isOut)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  showName,
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Oxanium',
                  ),
                ),
              ),
            if (message.body != null && message.body!.isNotEmpty)
              SelectableText(
                message.body!,
                style: TextStyle(
                  color: isOut ? Colors.black : AppColors.textPrimary,
                  fontSize: 13,
                  fontFamily: 'Oxanium',
                  height: 1.4,
                ),
              ),
            if (message.hasMedia)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attach_file,
                        size: 14,
                        color: isOut ? Colors.black54 : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      message.mediaType ?? 'Adjunto',
                      style: TextStyle(
                        color: isOut ? Colors.black54 : AppColors.textSecondary,
                        fontSize: 11,
                        fontFamily: 'Oxanium',
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.createdAt.toLocal()),
                  style: TextStyle(
                    color: isOut
                        ? Colors.black.withValues(alpha: 0.5)
                        : AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontFamily: 'Oxanium',
                  ),
                ),
                if (isOut) ...[
                  const SizedBox(width: 4),
                  _StatusIcon(status: message.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final WppStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case WppStatus.sent:
        return Icon(Icons.check, size: 12, color: Colors.black.withValues(alpha: 0.5));
      case WppStatus.delivered:
        return Icon(Icons.done_all, size: 12, color: Colors.black.withValues(alpha: 0.5));
      case WppStatus.read:
        return const Icon(Icons.done_all, size: 12, color: Color(0xFF34B7F1));
      case WppStatus.failed:
        return const Icon(Icons.error_outline, size: 12, color: Colors.red);
      default:
        return Icon(Icons.schedule, size: 12, color: Colors.black.withValues(alpha: 0.4));
    }
  }
}

// ---------------------------------------------------------------------------
// Divisor de fecha
// ---------------------------------------------------------------------------

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now   = DateTime.now();
    final local = date.toLocal();
    String label;
    if (local.day == now.day && local.month == now.month && local.year == now.year) {
      label = 'Hoy';
    } else if (local.day == now.day - 1 &&
               local.month == now.month &&
               local.year == now.year) {
      label = 'Ayer';
    } else {
      label = DateFormat('dd/MM/yyyy').format(local);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.borderGlass)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontFamily: 'Oxanium',
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.borderGlass)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado vacío (ninguna conversación seleccionada)
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.whatsapp,
            size: 64,
            color: AppColors.success.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          Text(
            'Seleccioná una conversación',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontFamily: 'Oxanium',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los mensajes de tus contactos\naparecen en el panel izquierdo.',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 12,
              fontFamily: 'Oxanium',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
