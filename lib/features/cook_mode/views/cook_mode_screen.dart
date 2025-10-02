import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:suvai/data/models/recipe_model.dart';
import 'package:suvai/features/cook_mode/cubit/cook_mode_cubit.dart';
import 'package:suvai/features/cook_mode/cubit/cook_mode_state.dart';
import 'package:wakelock/wakelock.dart';

// Enum to manage the different states of the timer.
enum TimerStatus { initial, running, paused, finished }

class CookModeScreen extends StatefulWidget {
  final Recipe recipe;
  const CookModeScreen({super.key, required this.recipe});

  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> with TickerProviderStateMixin {
  // State variables
  late final CookModeCubit _cookModeCubit;
  Timer? _periodicTimer;
  AnimationController? _controller;
  int _totalDurationSeconds = 0;
  int _remainingSeconds = 0;
  TimerStatus _timerStatus = TimerStatus.initial;

  @override
  void initState() {
    super.initState();
    Wakelock.enable();

    // 1. Create the cubit here instead of in the provider.
    _cookModeCubit = CookModeCubit(widget.recipe);

    // 2. Perform the initial setup here, which is a safe place to call setState.
    final initialInstruction = _cookModeCubit.state.recipe.instructions[_cookModeCubit.state.currentStep];
    _setupStep(initialInstruction.durationInMinutes);
  }

  @override
  void dispose() {
    Wakelock.disable();
    _cleanupTimerAndController();
    _cookModeCubit.close(); // Dispose the cubit
    super.dispose();
  }

  // Centralized cleanup method
  void _cleanupTimerAndController() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _controller?.dispose();
    _controller = null;
  }

  // Sets up the timer for a new step without starting it.
  void _setupStep(int? durationInMinutes) {
    _cleanupTimerAndController();
    if (durationInMinutes != null && durationInMinutes > 0) {
      _totalDurationSeconds = durationInMinutes * 60;
      _remainingSeconds = _totalDurationSeconds;
      _controller = AnimationController(vsync: this, duration: Duration(seconds: _totalDurationSeconds));
      _timerStatus = TimerStatus.initial;
    } else {
      _timerStatus = TimerStatus.finished; // No timer needed for this step
    }
    // No need to call setState here as it will be called by the listener or initState
  }

  void _startTimer() {
    if (_timerStatus == TimerStatus.initial || _timerStatus == TimerStatus.paused) {
      _timerStatus = TimerStatus.running;
      // If resuming, the controller's value is already part-way.
      // If initial, it starts from 0.0.
      _controller?.forward(from: 1.0 - (_remainingSeconds / _totalDurationSeconds));

      _periodicTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _timerStatus = TimerStatus.finished;
        } else if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      });
      setState(() {});
    }
  }

  void _pauseTimer() {
    if (_timerStatus == TimerStatus.running) {
      _periodicTimer?.cancel();
      _controller?.stop();
      _timerStatus = TimerStatus.paused;
      setState(() {});
    }
  }

  void _cancelTimer() {
    _cleanupTimerAndController();
    _setupStep(_totalDurationSeconds ~/ 60);
    setState(() {}); // Update the UI to show the reset timer
  }

  @override
  Widget build(BuildContext context) {
    // 3. Use BlocProvider.value to provide the cubit created in initState.
    return BlocProvider.value(
      value: _cookModeCubit,
      child: BlocListener<CookModeCubit, CookModeState>(
        listener: (context, state) {
          final instruction = state.recipe.instructions[state.currentStep];
          setState(() {
            _setupStep(instruction.durationInMinutes);
          });
        },
        child: BlocBuilder<CookModeCubit, CookModeState>(
          builder: (context, state) {
            final instruction = state.recipe.instructions[state.currentStep];
            final isFirstStep = state.currentStep == 0;
            final isLastStep = state.currentStep == state.recipe.instructions.length - 1;

            return Scaffold(
              appBar: AppBar(
                title: Text('Step ${state.currentStep + 1} of ${state.recipe.instructions.length}'),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                elevation: 0,
              ),
              body: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Empty spacer to push content to the center
                    const SizedBox.shrink(),

                    // Main content area
                    Column(
                      children: [
                        if (_timerStatus != TimerStatus.finished) _buildTimerUI(),
                        const SizedBox(height: 48),
                        Text(
                          instruction.description,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(height: 1.5),
                        ),
                      ],
                    ),

                    // Bottom navigation buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Previous'),
                          onPressed: isFirstStep ? null : () => _cookModeCubit.previousStep(),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                          onPressed: isLastStep ? null : () => _cookModeCubit.nextStep(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimerUI() {
    return Column(
      children: [
        // The circular timer display
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: (_controller != null && _totalDurationSeconds > 0)
                    ? 1.0 - (_remainingSeconds / _totalDurationSeconds)
                    : 0.0,
                strokeWidth: 12,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
              ),
              Center(
                child: Text(
                  '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w300),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // The timer control buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_timerStatus == TimerStatus.running) ...[
              // Show Pause and Cancel buttons when running
              IconButton.filled(
                iconSize: 32,
                onPressed: _pauseTimer,
                icon: const Icon(Icons.pause),
              ),
              const SizedBox(width: 24),
              IconButton(
                iconSize: 32,
                onPressed: _cancelTimer,
                icon: const Icon(Icons.stop),
              ),
            ] else ...[
              // Show Start button when initial or paused
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    backgroundColor: Colors.green.shade700
                ),
                onPressed: _startTimer,
                icon: Icon(_timerStatus == TimerStatus.paused ? Icons.play_arrow : Icons.play_arrow_outlined, color: Colors.white),
                label: Text(_timerStatus == TimerStatus.paused ? 'Resume' : 'Start Timer', style: const TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}