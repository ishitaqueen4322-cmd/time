import 'dart:async';
import 'dart:math';

import 'package:clock_app/common/widgets/card_container.dart';
import 'package:clock_app/settings/types/setting_group.dart';
import 'package:flutter/material.dart';

class SquatTask extends StatefulWidget {
  const SquatTask({
    super.key,
    required this.onSolve,
    required this.settings,
  });

  final VoidCallback onSolve;
  final SettingGroup settings;

  @override
  State<SquatTask> createState() => _SquatTaskState();
}

class _SquatTaskState extends State<SquatTask> with TickerProviderStateMixin {
  late final int numberOfSquats =
      widget.settings.getSetting("numberOfSquats").value.toInt();

  late List<CardModel> _cards;
  CardModel? _firstCard;
  bool _isWaiting = false;

  @override
  void initState() {
    super.initState();
    _initializeCards();
  }


  void _onCardTap(CardModel card) {
    if (_isWaiting || card.isFlipped) return;

    setState(() {
      card.isFlipped = true;
    });

    if (_firstCard == null) {
      _firstCard = card;
    } else {
      if (_firstCard!.value == card.value) {
        // Match found
        _firstCard!.isCompleted = true;
        card.isCompleted = true;
        _firstCard = null;

        if (_cards.every((card) => card.isFlipped)) {
          // All cards are flipped
          Future.delayed(const Duration(seconds: 1), () {
            widget.onSolve();
          });
        }
      } else {
        // No match, flip back after delay
        _isWaiting = true;
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            card.isFlipped = false;
            _firstCard!.isFlipped = false;
            _firstCard = null;
            _isWaiting = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;
    TextTheme textTheme = theme.textTheme;
    int gridSize = (sqrt(_cards.length)).floor();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            "Match card pairs",
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            width: double.infinity,
            // height: 512,
            child: GridView.builder(
              itemCount: _cards.length,
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
              ),
              itemBuilder: (context, index) {
                CardModel card = _cards[index];
                return GestureDetector(
                  key: ValueKey(card),
                  onTap: () => _onCardTap(card),
                  child: FlipCard(
                    isFlipped: card.isFlipped,
                    front: CardContainer(
                      margin: const EdgeInsets.all(4.0),
                      color: colorScheme.primary,
                      child: Center(
                        child: Text(
                          '?',
                          style: textTheme.displayMedium?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                    back: CardContainer(
                      margin: const EdgeInsets.all(4.0),
                      color: card.isCompleted ? Colors.green : Colors.orangeAccent,
                      child: Center(
                        child: Text(
                          '${card.value}',
                          style: textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                                                      
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}