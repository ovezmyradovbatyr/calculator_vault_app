import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vault_content_page.dart';
import 'vault_pin_screen.dart';

// Entry point – checks for PIN and routes to PIN screen or vault content
class SecretVaultPage extends StatefulWidget {
  const SecretVaultPage({super.key});

  @override
  State<SecretVaultPage> createState() => _SecretVaultPageState();
}

class _SecretVaultPageState extends State<SecretVaultPage> {
  static const _pinKey = 'secret_vault_pin';
  bool _authenticated = false;
  bool _loaded = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_pinKey);
    setState(() {
      _hasPin = pin != null && pin.isNotEmpty;
      _loaded = true;
    });
  }

  void _onAuthenticated() => setState(() => _authenticated = true);

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9F0A)),
        ),
      );
    }
    if (!_authenticated) {
      return VaultPinScreen(
        mode: _hasPin ? VaultPinMode.enter : VaultPinMode.create,
        onSuccess: _onAuthenticated,
      );
    }
    return const VaultContentPage();
  }
}
