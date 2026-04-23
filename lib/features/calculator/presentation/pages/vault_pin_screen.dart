import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../l10n/app_localizations.dart';

enum VaultPinMode { enter, create, change }

class VaultPinScreen extends StatefulWidget {
  final VaultPinMode mode;
  final VoidCallback? onSuccess;

  const VaultPinScreen({super.key, required this.mode, this.onSuccess});

  @override
  State<VaultPinScreen> createState() => _VaultPinScreenState();
}

class _VaultPinScreenState extends State<VaultPinScreen> {
  static const _pinKey = 'secret_vault_pin';
  static const _attemptsKey = 'vault_pin_attempts';
  static const _lockedUntilKey = 'vault_pin_locked_until';
  static const _lockoutCountKey = 'vault_pin_lockout_count';
  static const _orange = Color(0xFFFF9F0A);

  String _input = '';
  String _firstPin = '';
  bool _confirming = false;
  bool _verifyingOld = false;
  String? _error;

  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  Timer? _countdownTimer;

  bool get _isLockedOut =>
      _lockedUntil != null && _lockedUntil!.isAfter(DateTime.now());

  @override
  void initState() {
    super.initState();
    _verifyingOld = widget.mode == VaultPinMode.change;
    _loadLockState();
  }

  Future<void> _loadLockState() async {
    final prefs = await SharedPreferences.getInstance();
    _failedAttempts = prefs.getInt(_attemptsKey) ?? 0;
    final ms = prefs.getInt(_lockedUntilKey);
    if (ms != null) {
      final locked = DateTime.fromMillisecondsSinceEpoch(ms);
      if (locked.isAfter(DateTime.now())) {
        _lockedUntil = locked;
        if (mounted) _startCountdown();
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateLockMessage();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _countdownTimer?.cancel();
        return;
      }
      final remaining = _lockedUntil?.difference(DateTime.now());
      if (remaining == null || remaining.isNegative) {
        _countdownTimer?.cancel();
        _failedAttempts = 0;
        SharedPreferences.getInstance().then((p) {
          p.remove(_lockedUntilKey);
          p.setInt(_attemptsKey, 0);
        });
        if (mounted)
          setState(() {
            _lockedUntil = null;
            _error = null;
          });
      } else {
        _updateLockMessage();
      }
    });
  }

  void _updateLockMessage() {
    if (!mounted || _lockedUntil == null) return;
    final remaining = _lockedUntil!.difference(DateTime.now());
    if (remaining.isNegative) return;
    final secs = remaining.inSeconds + 1;
    setState(() {
      _error = secs >= 60
          ? 'Подождите ${remaining.inMinutes} мин ${secs % 60} сек'
          : 'Подождите $secs сек';
    });
  }

  Future<void> _recordFail() async {
    _failedAttempts++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_attemptsKey, _failedAttempts);
    if (_failedAttempts >= 5) {
      final lockoutCount = prefs.getInt(_lockoutCountKey) ?? 0;
      await prefs.setInt(_lockoutCountKey, lockoutCount + 1);
      final dur = lockoutCount == 0
          ? const Duration(seconds: 30)
          : const Duration(minutes: 5);
      _lockedUntil = DateTime.now().add(dur);
      _failedAttempts = 0;
      await prefs.setInt(_attemptsKey, 0);
      await prefs.setInt(_lockedUntilKey, _lockedUntil!.millisecondsSinceEpoch);
      if (mounted) _startCountdown();
    }
  }

  String get _title {
    final l = AppLocalizations.instance;
    if (widget.mode == VaultPinMode.enter) return l.t('enterPin');
    if (_verifyingOld) return l.t('currentPin');
    if (_confirming) return l.t('confirmNewPin');
    return l.t('newPin');
  }

  void _onDigit(String d) {
    if (_isLockedOut) return;
    if (_input.length >= 4) return;
    setState(() {
      _input += d;
      if (!_isLockedOut) _error = null;
    });
    if (_input.length == 4) _submit();
  }

  void _onDelete() {
    if (_isLockedOut) return;
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  Future<void> _submit() async {
    final prefs = await SharedPreferences.getInstance();

    if (widget.mode == VaultPinMode.enter) {
      if (_isLockedOut) {
        setState(() => _input = '');
        return;
      }
      final saved = prefs.getString(_pinKey) ?? '';
      if (_input == saved) {
        await prefs.setInt(_attemptsKey, 0);
        await prefs.setInt(_lockoutCountKey, 0);
        await prefs.remove(_lockedUntilKey);
        widget.onSuccess?.call();
      } else {
        await _recordFail();
        if (mounted) {
          setState(() {
            if (!_isLockedOut) _error = AppLocalizations.instance.t('wrongPin');
            _input = '';
          });
        }
      }
      return;
    }

    // change: сначала проверяем старый PIN
    if (_verifyingOld) {
      if (_isLockedOut) {
        setState(() => _input = '');
        return;
      }
      final saved = prefs.getString(_pinKey) ?? '';
      if (_input == saved) {
        await prefs.setInt(_attemptsKey, 0);
        await prefs.setInt(_lockoutCountKey, 0);
        await prefs.remove(_lockedUntilKey);
        setState(() {
          _verifyingOld = false;
          _input = '';
          _error = null;
        });
      } else {
        await _recordFail();
        if (mounted) {
          setState(() {
            if (!_isLockedOut) _error = AppLocalizations.instance.t('wrongPin');
            _input = '';
          });
        }
      }
      return;
    }

    // create / change: вводим новый PIN
    if (!_confirming) {
      setState(() {
        _firstPin = _input;
        _input = '';
        _confirming = true;
      });
    } else {
      if (_input == _firstPin) {
        await prefs.setString(_pinKey, _input);
        if (widget.mode == VaultPinMode.change) {
          if (mounted) Navigator.pop(context, true);
        } else {
          widget.onSuccess?.call();
        }
      } else {
        setState(() {
          _error = AppLocalizations.instance.t('pinsDoNotMatch');
          _input = '';
          _firstPin = '';
          _confirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: widget.mode == VaultPinMode.change
          ? AppBar(
              backgroundColor: const Color(0xFF0A0A0A),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                AppLocalizations.instance.t('changePinTitle'),
                style: const TextStyle(color: Colors.white),
              ),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: _orange, size: 56),
            const SizedBox(height: 24),
            Text(
              _title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 28,
              child: _error != null
                  ? Text(
                      _error!,
                      style: TextStyle(
                        color: _isLockedOut ? _orange : Colors.redAccent,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _input.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? _orange : Colors.transparent,
                    border: Border.all(
                      color: filled ? _orange : Colors.white38,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 48),
            // Numpad
            for (final row in [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '<'],
            ])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((d) {
                  if (d.isEmpty) {
                    return const SizedBox(width: 80, height: 80);
                  }
                  return _PinKey(
                    label: d,
                    onTap: () => d == '<' ? _onDelete() : _onDigit(d),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _PinKey extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _PinKey({required this.label, required this.onTap});

  @override
  State<_PinKey> createState() => _PinKeyState();
}

class _PinKeyState extends State<_PinKey> {
  bool _pressed = false;

  void _handlePress() {
    setState(() => _pressed = true);
    // Auto-reset in case onTapUp/onTapCancel doesn't fire (e.g. rapid state changes)
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _pressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBack = widget.label == '<';
    return GestureDetector(
      onTapDown: (_) => _handlePress(),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 80,
        height: 80,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _pressed ? const Color(0xFF3A3A3C) : const Color(0xFF1C1C1E),
        ),
        child: Center(
          child: isBack
              ? Icon(
                  Icons.backspace_outlined,
                  color: _pressed ? Colors.white : Colors.white70,
                  size: 24,
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    color: _pressed ? Colors.white : Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                  ),
                ),
        ),
      ),
    );
  }
}
