// Archivo: lib/features/dashboard/presentation/widgets/tabs/bot_mood_tab.dart
// Tab índice 3 del detalle de bot — selector de personalidad/mood.
// Grilla de 6 MoodCard (3 cols / 2 cols en breakpoint mínimo).
// Escribe terminalBotMoodProvider al seleccionar; el RiveBotDisplay reacciona en vivo.
import 'package:botslode/core/config/theme/app_colors.dart';
import 'package:botslode/core/config/theme/app_dimens.dart';
import 'package:botslode/core/config/theme/app_motion.dart';
import 'package:botslode/core/config/theme/app_text_styles.dart';
import 'package:botslode/core/ui/hud/hud_divider.dart';
import 'package:botslode/features/bot_engine/presentation/providers/bot_mood_provider.dart';
import 'package:botslode/features/dashboard/presentation/widgets/mood_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BotMoodTab extends ConsumerWidget {
  final bool disabled;

  const BotMoodTab({super.key, this.disabled = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMood = ref.watch(terminalBotMoodProvider);
    final reduced = AppMotion.reduced(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.space20,
        AppDimens.space20,
        AppDimens.space20,
        AppDimens.space32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HudDivider(label: 'PERSONALIDAD DE LA UNIDAD'),
          const SizedBox(height: AppDimens.space8),
          Text(
            'Elegí cómo se comporta y se expresa la unidad.'
            ' El avatar reflejará el cambio.',
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.space20),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 500 ? 3 : 2;
              const gap = AppDimens.space20;
              final cardWidth =
                  (constraints.maxWidth - gap * (cols - 1)) / cols;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: List.generate(6, (index) {
                  Widget card = SizedBox(
                    width: cardWidth,
                    child: MoodCard(
                      moodIndex: index,
                      isSelected: selectedMood == index,
                      disabled: disabled,
                      onTap: () {
                        ref.read(terminalBotMoodProvider.notifier).state =
                            index;
                      },
                    ),
                  );

                  if (!reduced) {
                    card = card
                        .animate(
                          delay: AppMotion.staggerDelay(index),
                        )
                        .fadeIn(
                          duration: AppMotion.durBase,
                          curve: AppMotion.easeEntrance,
                        )
                        .moveY(
                          begin: 12,
                          end: 0,
                          duration: AppMotion.durBase,
                          curve: AppMotion.easeEntrance,
                        );
                  } else {
                    card = card
                        .animate()
                        .fadeIn(duration: AppMotion.durCrossfadeReduced);
                  }

                  return card;
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
