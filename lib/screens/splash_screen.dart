import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/tab_selector.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  final Duration duration;
  final CalculatorMode initialMode;
  final ValueChanged<CalculatorMode>? onModeSelected;

  const SplashScreen({
    super.key,
    required this.onFinish,
    this.duration = const Duration(seconds: 5),
    this.initialMode = CalculatorMode.standard,
    this.onModeSelected,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Entrance animation controller (snappy 400ms entrance)
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  // Progress animation controller (runs for the full splash duration)
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  // Icon bounce & easter egg controllers
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;
  late final AnimationController _easterEggController;
  late final Animation<double> _easterEggOpacity;
  late final Animation<Offset> _easterEggSlide;

  // 3D tilt spring-back controller
  late final AnimationController _tiltResetController;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  double _tiltStartX = 0.0;
  double _tiltStartY = 0.0;

  // Touch burst particles controller
  late final AnimationController _burstController;

  Timer? _timer;
  bool _finished = false;

  // State
  late CalculatorMode _selectedMode;
  int _easterEggIndex = 0;
  bool _showEasterEgg = false;
  int _triviaIndex = 0;

  static const List<String> _easterEggs = [
    '= 42',
    'π ≈ 3.14159',
    'e ≈ 2.71828',
    'φ ≈ 1.618',
    'E = mc²',
    '√-1 = i',
    '∞',
    '+1',
    '1337',
    '∑ = ∫',
  ];

  static const List<String> _triviaFacts = [
    'Euler\'s identity: e^(iπ) + 1 = 0',
    '2520 is divisible by all numbers 1 through 10',
    'The "=" sign was invented in 1557 by Robert Recorde',
    'Zero as a numerical concept originated in India',
    'A googol is 10¹⁰⁰ (1 followed by 100 zeros)',
    'Golden Ratio φ ≈ 1.6180339887...',
    'Pizza volume: radius z, height a → π · z · z · a',
  ];

  // Ambient math glyphs drifting in background
  final List<_MathGlyph> _ambientGlyphs = [];
  final List<_BurstParticle> _burstParticles = [];
  final List<_TouchRipple> _ripples = [];

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;

    // 1. Entrance controller (snappy 400ms entrance)
    final entranceDuration = widget.duration < const Duration(milliseconds: 400)
        ? widget.duration
        : const Duration(milliseconds: 400);

    _controller = AnimationController(
      vsync: this,
      duration: entranceDuration,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    // Starting at 0.05 ensures RenderOpacity immediately allows hit tests from frame 0
    _fadeAnimation = Tween<double>(begin: 0.05, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    // 2. Progress controller (runs for widget.duration)
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration > Duration.zero
          ? widget.duration
          : const Duration(milliseconds: 1),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ),
    );

    // 3. Icon bounce animation
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.18).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.18, end: 0.94).chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.0).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 30,
      ),
    ]).animate(_bounceController);

    // 4. Easter egg reaction popup
    _easterEggController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _easterEggOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_easterEggController);
    _easterEggSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: const Offset(0.0, -0.65),
    ).animate(CurvedAnimation(parent: _easterEggController, curve: Curves.easeOutCubic));

    // 5. Tilt reset spring animation
    _tiltResetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tiltResetController.addListener(() {
      final t = CurvedAnimation(parent: _tiltResetController, curve: Curves.easeOutBack).value;
      setState(() {
        _tiltX = _tiltStartX * (1.0 - t);
        _tiltY = _tiltStartY * (1.0 - t);
      });
    });

    // 6. Burst particle controller
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _burstController.addListener(_updateBursts);

    // Initialize ambient math glyphs
    _initAmbientGlyphs();

    _controller.forward();
    _progressController.forward();

    _startOrResetDismissTimer();
  }

  void _startOrResetDismissTimer({Duration? extendDuration}) {
    if (_finished) return;
    _timer?.cancel();
    if (widget.duration == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _finish();
      });
      return;
    }

    final durationToUse = extendDuration ?? widget.duration;
    _timer = Timer(durationToUse, () {
      _finish();
    });

    if (extendDuration != null) {
      _progressController.duration = durationToUse;
      _progressController.forward(from: 0.0);
    }
  }

  void _onUserInteracted() {
    if (_finished) return;
    // When the user interacts (taps icon, mode, trivia, screen), extend the timer
    // so the splash screen doesn't vanish while they are actively engaging!
    if (widget.duration >= const Duration(milliseconds: 800)) {
      _startOrResetDismissTimer(extendDuration: const Duration(seconds: 5));
    }
  }

  void _initAmbientGlyphs() {
    const symbols = [
      '+', '−', '×', '÷', '%', 'π', '√', '∑',
      '∞', '=', '∫', 'x²', 'Δ', 'λ', 'φ', '≈',
      '≠', 'log', 'e', 'sin'
    ];
    for (int i = 0; i < symbols.length; i++) {
      _ambientGlyphs.add(_MathGlyph(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        vx: (_random.nextDouble() - 0.5) * 0.035,
        vy: -0.015 - _random.nextDouble() * 0.035,
        symbol: symbols[i],
        size: 13.0 + _random.nextDouble() * 11.0,
        baseOpacity: 0.08 + _random.nextDouble() * 0.14,
        rotation: (_random.nextDouble() - 0.5) * 0.6,
        rotSpeed: (_random.nextDouble() - 0.5) * 0.3,
      ));
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    _controller.stop();
    _progressController.stop();
    _bounceController.stop();
    _easterEggController.stop();
    _tiltResetController.stop();
    _burstController.stop();
    if (mounted) {
      widget.onFinish();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _progressController.dispose();
    _bounceController.dispose();
    _easterEggController.dispose();
    _tiltResetController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  void _handleScreenTap(Offset localPos) {
    _spawnBurst(localPos);
    _addRipple(localPos);
    HapticFeedback.lightImpact();
    _onUserInteracted();
  }

  void _handleScreenPan(Offset localPos) {
    if (_random.nextDouble() < 0.45) {
      _spawnBurst(localPos, count: 2);
    }
  }

  void _spawnBurst(Offset origin, {int count = 6}) {
    const burstSymbols = ['+', '−', '×', '÷', '%', 'π', '√', '=', '∞', '42', '1'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = AppColors.darkEqualsButton;

    for (int i = 0; i < count; i++) {
      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 1.8 + _random.nextDouble() * 4.5;
      final color = _random.nextBool()
          ? primary
          : (isDark ? const Color(0xFF64D2FF) : const Color(0xFF1D5A56));

      _burstParticles.add(_BurstParticle(
        x: origin.dx,
        y: origin.dy,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        symbol: burstSymbols[_random.nextInt(burstSymbols.length)],
        color: color,
        size: 12.0 + _random.nextDouble() * 10.0,
        life: 1.0,
        decay: 0.035 + _random.nextDouble() * 0.025,
        rotation: _random.nextDouble() * 2 * math.pi,
      ));
    }

    if (!_burstController.isAnimating && !_finished) {
      _burstController.forward(from: 0.0);
    }
  }

  void _addRipple(Offset origin) {
    final primary = AppColors.darkEqualsButton;
    _ripples.add(_TouchRipple(
      position: origin,
      maxRadius: 46.0 + _random.nextDouble() * 20.0,
      color: primary,
    ));
    if (!_burstController.isAnimating && !_finished) {
      _burstController.forward(from: 0.0);
    }
  }

  void _updateBursts() {
    if (_finished) return;
    setState(() {
      for (final p in _burstParticles) {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.08; // gentle gravity
        p.life -= p.decay;
        p.rotation += 0.04;
      }
      _burstParticles.removeWhere((p) => p.life <= 0.0);

      for (final r in _ripples) {
        r.radius += (r.maxRadius - r.radius) * 0.22;
        r.opacity *= 0.86;
      }
      _ripples.removeWhere((r) => r.opacity <= 0.03);
    });

    if (_burstParticles.isEmpty && _ripples.isEmpty && _burstController.isAnimating) {
      _burstController.stop();
    }
  }

  void _onIconTap() {
    _onUserInteracted();
    setState(() {
      _showEasterEgg = true;
      _bounceController.forward(from: 0.0);
      _easterEggIndex = (_easterEggIndex + 1) % _easterEggs.length;
      _easterEggController.forward(from: 0.0);
    });
    HapticFeedback.mediumImpact();

    // Spawn a burst from the icon
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final center = Offset(renderBox.size.width / 2, renderBox.size.height / 2 - 40);
      _spawnBurst(center, count: 8);
      _addRipple(center);
    }
  }

  void _selectMode(CalculatorMode mode) {
    _onUserInteracted();
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMode = mode;
    });
    widget.onModeSelected?.call(mode);
  }

  void _cycleTrivia() {
    _onUserInteracted();
    HapticFeedback.lightImpact();
    setState(() {
      _triviaIndex = (_triviaIndex + 1) % _triviaFacts.length;
    });
  }

  String _getModeDescription(CalculatorMode mode) {
    switch (mode) {
      case CalculatorMode.standard:
        return 'Clean arithmetic • Instant percentage';
      case CalculatorMode.scientific:
        return 'Trigonometry • Powers • Logarithms';
      case CalculatorMode.converter:
        return 'Length • Weight • Speed • Temperature';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.darkEqualsButton; // #347D78

    final bgGradientStart = isDark ? const Color(0xFF162232) : const Color(0xFFFFFFFF);
    final bgGradientEnd = isDark ? const Color(0xFF0F151F) : const Color(0xFFEDF2F7);
    final titleColor = isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final subtitleColor = isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final cardBorder = isDark ? const Color(0x33347D78) : const Color(0x22347D78);

    final screenHeight = MediaQuery.of(context).size.height;
    final isShort = screenHeight < 520;
    final iconSize = isShort ? 64.0 : 112.0;
    final iconRadius = isShort ? 16.0 : 26.0;
    final innerRadius = isShort ? 14.0 : 24.0;
    final titleSize = isShort ? 22.0 : 32.0;
    final gap1 = isShort ? 8.0 : 20.0;
    final gap2 = isShort ? 4.0 : 10.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgGradientStart, bgGradientEnd],
          ),
        ),
        child: Stack(
          children: [
            // 1. Interactive Ambient & Burst Math Particle Canvas with touch detector
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) => _handleScreenTap(details.localPosition),
                onPanUpdate: (details) => _handleScreenPan(details.localPosition),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_controller, _burstController]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _InteractiveParticlePainter(
                        progress: _controller.value,
                        ambientGlyphs: _ambientGlyphs,
                        burstParticles: _burstParticles,
                        ripples: _ripples,
                        isDark: isDark,
                        primaryColor: primaryColor,
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. Foreground Main UI
            SafeArea(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_controller, _progressAnimation]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Column(
                          children: [
                            // Top Bar with Skip button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _finish,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: (isDark ? AppColors.darkOperatorButton : AppColors.lightOperatorButton)
                                              .withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: primaryColor.withValues(alpha: 0.35),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Skip',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: subtitleColor,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 14,
                                              color: primaryColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(flex: 2),

                            // Interactive 3D Tilt & Elastic Bounce Icon
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // Floating Easter Egg reaction bubble
                                Positioned(
                                  top: -34,
                                  child: AnimatedBuilder(
                                    animation: _easterEggController,
                                    builder: (context, _) {
                                      if (!_showEasterEgg) {
                                        return const SizedBox.shrink();
                                      }
                                      return Opacity(
                                        opacity: _easterEggOpacity.value.clamp(0.0, 1.0),
                                        child: SlideTransition(
                                          position: _easterEggSlide,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: primaryColor,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: primaryColor.withValues(alpha: 0.4),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              _easterEggs[_easterEggIndex],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Interactive Icon with 3D tilt & spring bounce
                                Listener(
                                  onPointerMove: (event) {
                                    setState(() {
                                      _tiltX = (_tiltX + event.delta.dy * 0.015).clamp(-0.35, 0.35);
                                      _tiltY = (_tiltY - event.delta.dx * 0.015).clamp(-0.35, 0.35);
                                    });
                                  },
                                  onPointerUp: (_) {
                                    _tiltStartX = _tiltX;
                                    _tiltStartY = _tiltY;
                                    _tiltResetController.forward(from: 0.0);
                                  },
                                  child: GestureDetector(
                                    onTap: _onIconTap,
                                    child: AnimatedBuilder(
                                    animation: _bounceAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _bounceAnimation.value,
                                        child: Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()
                                            ..setEntry(3, 2, 0.0018)
                                            ..rotateX(_tiltX)
                                            ..rotateY(_tiltY),
                                          child: Container(
                                            width: iconSize,
                                            height: iconSize,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(iconRadius),
                                              border: Border.all(color: cardBorder, width: 1.5),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: primaryColor.withValues(alpha: isDark ? 0.38 : 0.22),
                                                  blurRadius: isShort ? 16 : 28,
                                                  spreadRadius: isShort ? 1 : 2,
                                                  offset: Offset(0, isShort ? 4 : 8),
                                                ),
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.1),
                                                  blurRadius: isShort ? 10 : 18,
                                                  offset: Offset(0, isShort ? 6 : 10),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(innerRadius),
                                              child: Image.asset(
                                                'assets/icon/app_icon.png',
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                            ),

                            SizedBox(height: gap1),

                            // App Title
                            Text(
                              'Calculator',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: titleSize,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: titleColor,
                              ),
                            ),

                            SizedBox(height: gap2),

                            // Interactive Mode Chips Row
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: (isDark ? AppColors.darkOperatorButton : AppColors.lightOperatorButton)
                                        .withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: primaryColor.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildModeChip(
                                        mode: CalculatorMode.standard,
                                        label: 'Standard',
                                        icon: Icons.calculate_rounded,
                                        isDark: isDark,
                                        primaryColor: primaryColor,
                                        subtitleColor: subtitleColor,
                                      ),
                                      _buildModeChip(
                                        mode: CalculatorMode.scientific,
                                        label: 'Scientific',
                                        icon: Icons.functions_rounded,
                                        isDark: isDark,
                                        primaryColor: primaryColor,
                                        subtitleColor: subtitleColor,
                                      ),
                                      _buildModeChip(
                                        mode: CalculatorMode.converter,
                                        label: 'Converter',
                                        icon: Icons.swap_horiz_rounded,
                                        isDark: isDark,
                                        primaryColor: primaryColor,
                                        subtitleColor: subtitleColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Dynamic Mode Tagline
                            const SizedBox(height: 6),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                _getModeDescription(_selectedMode),
                                key: ValueKey(_selectedMode),
                                style: TextStyle(
                                  fontSize: isShort ? 10.5 : 12,
                                  fontWeight: FontWeight.w500,
                                  color: primaryColor,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),

                            // Interactive Math Trivia Pill (shown on normal/large screens)
                            if (!isShort) ...[
                              const SizedBox(height: 14),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _cycleTrivia,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: (isDark ? const Color(0xFF1B2738) : const Color(0xFFE8EEF5))
                                            .withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: primaryColor.withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lightbulb_outline_rounded,
                                            size: 15,
                                            color: primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 220),
                                              child: Text(
                                                _triviaFacts[_triviaIndex],
                                                key: ValueKey(_triviaIndex),
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: subtitleColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.refresh_rounded,
                                            size: 13,
                                            color: primaryColor.withValues(alpha: 0.7),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const Spacer(flex: 3),

                            // Progress Indicator & Interactive Start Hint
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 64),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SizedBox(
                                  width: 130,
                                  height: 4,
                                  child: LinearProgressIndicator(
                                    value: _progressAnimation.value,
                                    backgroundColor: isDark
                                        ? const Color(0xFF233042)
                                        : const Color(0xFFD6DFEB),
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Tap to continue hint
                            GestureDetector(
                              onTap: _finish,
                              child: Text(
                                'Tap to start calculating',
                                style: TextStyle(
                                  fontSize: isShort ? 10 : 11,
                                  fontWeight: FontWeight.w500,
                                  color: subtitleColor.withValues(alpha: 0.65),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),

                            SizedBox(height: isShort ? 10 : 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildModeChip({
    required CalculatorMode mode,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
    required Color subtitleColor,
  }) {
    final isSelected = _selectedMode == mode;
    final activeBg = primaryColor.withValues(alpha: isDark ? 0.35 : 0.22);
    final activeBorder = primaryColor.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectMode(mode),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected ? activeBorder : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isSelected ? primaryColor : subtitleColor.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.darkEqualsButton)
                        : subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Particle model for ambient drifting math symbols
class _MathGlyph {
  double x;
  double y;
  double vx;
  double vy;
  final String symbol;
  final double size;
  final double baseOpacity;
  double rotation;
  final double rotSpeed;

  _MathGlyph({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.symbol,
    required this.size,
    required this.baseOpacity,
    required this.rotation,
    required this.rotSpeed,
  });
}

/// Dynamic particle spawned on tap/drag
class _BurstParticle {
  double x;
  double y;
  double vx;
  double vy;
  final String symbol;
  final Color color;
  final double size;
  double life;
  final double decay;
  double rotation;

  _BurstParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.symbol,
    required this.color,
    required this.size,
    required this.life,
    required this.decay,
    required this.rotation,
  });
}

/// Circular ripple expanding on touch
class _TouchRipple {
  final Offset position;
  double radius = 6.0;
  final double maxRadius;
  double opacity = 0.55;
  final Color color;

  _TouchRipple({
    required this.position,
    required this.maxRadius,
    required this.color,
  });
}

/// Canvas painter rendering ambient glyphs, touch bursts, and ripples
class _InteractiveParticlePainter extends CustomPainter {
  final double progress;
  final List<_MathGlyph> ambientGlyphs;
  final List<_BurstParticle> burstParticles;
  final List<_TouchRipple> ripples;
  final bool isDark;
  final Color primaryColor;

  _InteractiveParticlePainter({
    required this.progress,
    required this.ambientGlyphs,
    required this.burstParticles,
    required this.ripples,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Draw ripples
    final ripplePaint = Paint()..style = PaintingStyle.stroke;
    for (final r in ripples) {
      ripplePaint
        ..color = r.color.withValues(alpha: r.opacity.clamp(0.0, 1.0))
        ..strokeWidth = 2.0;
      canvas.drawCircle(r.position, r.radius, ripplePaint);
    }

    // 2. Draw ambient floating glyphs
    final glyphColor = isDark
        ? Colors.white
        : AppColors.darkEqualsButton;

    for (final g in ambientGlyphs) {
      // Drift calculation
      final curX = ((g.x + g.vx * progress * 4.0) % 1.0) * size.width;
      final curY = ((g.y + g.vy * progress * 4.0 + math.sin(progress * 2 * math.pi + g.x * 6) * 0.03) % 1.0) * size.height;
      final curRot = g.rotation + g.rotSpeed * progress * 2 * math.pi;

      final textSpan = TextSpan(
        text: g.symbol,
        style: TextStyle(
          fontSize: g.size,
          fontWeight: FontWeight.bold,
          color: glyphColor.withValues(alpha: g.baseOpacity),
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(curX, curY);
      canvas.rotate(curRot);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    // 3. Draw touch burst particles
    for (final p in burstParticles) {
      final currentOpacity = (p.life * 0.95).clamp(0.0, 1.0);
      final currentSize = p.size * (0.6 + 0.4 * p.life);

      final textSpan = TextSpan(
        text: p.symbol,
        style: TextStyle(
          fontSize: currentSize,
          fontWeight: FontWeight.w800,
          color: p.color.withValues(alpha: currentOpacity),
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotation);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveParticlePainter oldDelegate) {
    return true;
  }
}
