import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:pixel_ui/pixel_ui.dart';

import 'package:happy_cherry/app/app_theme.dart';
import 'package:happy_cherry/app/audio_manager.dart';
import 'package:happy_cherry/features/hatch/death.dart';
import 'package:happy_cherry/features/cherry_catch/game.dart';
import 'package:happy_cherry/features/hatch/hatch_screen.dart';
import 'package:happy_cherry/features/home/info_button.dart';
import 'package:happy_cherry/app/loading_screen.dart';
import 'package:happy_cherry/core/pet.dart';
import 'package:happy_cherry/widgets/pet_graphic.dart';
import 'package:happy_cherry/features/home/rename_button.dart';
import 'package:happy_cherry/features/shop/shop_page.dart';
import 'package:happy_cherry/features/home/user_input.dart';
import 'package:happy_cherry/features/wardrobe/wardrobe_page.dart';
import 'package:happy_cherry/features/shop/shop_purchase_result.dart';
import 'package:happy_cherry/features/home/home_controller.dart';
import 'package:happy_cherry/features/home/load_failure_screen.dart';
import 'package:happy_cherry/features/home/pet_hud.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final Future<void> Function() onLogout;

  const HomePage({super.key, required this.userId, required this.onLogout});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController(
      userId: widget.userId,
      onLogout: widget.onLogout,
    );
    unawaited(_controller.start());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openShop() async {
    if (!mounted) return;
    await AudioManager.instance.playButton();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShopPage(
          pet: _controller.pet,
          coins: _controller.coins,
          ownedAccessories: _controller.ownedAccessories,
          onPurchase: (ShopPurchaseResult result) {
            _controller.applyPurchase(
              newCoins: result.coins,
              owned: result.ownedAccessories,
            );
          },
        ),
      ),
    );
  }

  Future<void> _openWardrobe() async {
    if (!mounted) return;
    await AudioManager.instance.playButton();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WardrobePage(
          pet: _controller.pet,
          ownedAccessories: _controller.ownedAccessories,
          onAccessorySelected: _controller.setAccessory,
        ),
      ),
    );
  }

  Future<void> _onPlay() async {
    AudioManager.instance.playButton();
    final score = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => CherryCatchGame(userId: widget.userId),
      ),
    );
    if (!mounted) return;
    _controller.onPlayFinished(score);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final c = _controller;
        if (c.isLoading) {
          return const LoadingScreen();
        }
        if (c.loadFailed) {
          return LoadFailureScreen(
            errorMessage: c.loadErrorMessage,
            onRetry: () => unawaited(c.loadGame()),
            onBack: () => unawaited(c.backFromLoadFailure()),
          );
        }
        if (c.isHatching) {
          return HatchScreen(onComplete: c.onHatchComplete);
        }
        if (c.isDead) {
          return DeathScreen(onRestart: c.restartFromDeath);
        }

        final pet = c.pet;
        return Theme(
          data: AppTheme.forLightsOff(pet.lightsOff),
          child: Scaffold(
            appBar: AppBar(
              title: Text(pet.name, style: homePixelBodyText(pet, 20)),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(c.muted ? Icons.volume_off : Icons.volume_up),
                  tooltip: c.muted ? 'Unmute' : 'Mute',
                  onPressed: () => unawaited(c.toggleMute()),
                ),
                RenameButton(
                  pet: pet,
                  onRename: c.rename,
                ),
                InfoButton(
                  pet: pet,
                  coins: c.coins,
                  lightsOff: pet.lightsOff,
                  onAbandon: c.abandonPet,
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () => unawaited(c.logout()),
                ),
              ],
            ),
            backgroundColor:
                pet.lightsOff ? Colors.black : AppTheme.backgroundPink,
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: PetGraphic(
                        pet: pet,
                        height: 200,
                        showFood: c.showFood,
                        showStars: c.showStars,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      pet.feels,
                      textAlign: TextAlign.center,
                      style: homePixelBodyText(
                        pet,
                        22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    HeartMeter(label: 'Hunger', value: pet.hunger, pet: pet),
                    HeartMeter(
                      label: 'Happiness',
                      value: pet.happiness,
                      pet: pet,
                    ),
                    AttentionIndicator(pet: pet),
                    const SizedBox(height: 16),
                    LightsControl(
                      pet: pet,
                      onLightsChanged: (lightsOn) =>
                          c.toggleLights(lightsOn: lightsOn),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PixelButton(
                          logicalWidth: 28,
                          logicalHeight: 12,
                          width: 140,
                          pressChildOffset: const Offset(0, 1),
                          onPressed: _openShop,
                          semanticsLabel: 'Shop',
                          child: Text(
                            'Shop',
                            style: AppTheme.buttonLabel(AppTheme.textDark),
                          ),
                        ),
                        const SizedBox(width: 12),
                        PixelButton(
                          logicalWidth: 28,
                          logicalHeight: 12,
                          width: 140,
                          pressChildOffset: const Offset(0, 1),
                          onPressed: _openWardrobe,
                          semanticsLabel: 'Wardrobe',
                          child: Text(
                            'Wardrobe',
                            style: AppTheme.buttonLabel(AppTheme.textDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    UserActions(
                      isSleeping: pet.mood == PetMood.sleeping,
                      canHeal: pet.isSick,
                      onFeed: c.onFeed,
                      onPlay: _onPlay,
                      onClean: c.onClean,
                      onHeal: c.onHeal,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
