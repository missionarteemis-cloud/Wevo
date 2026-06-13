import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

class DevAccessScreen extends StatefulWidget {
  const DevAccessScreen({super.key});

  @override
  State<DevAccessScreen> createState() => _DevAccessScreenState();
}

class _DevAccessScreenState extends State<DevAccessScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _enter() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await AuthService.ensureDevAccount();
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _error = error.message;
        _loading = false;
      });
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WevoColors.dark,
      appBar: AppBar(title: const Text('Accesso rapido dev')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entra subito con un account demo persistente.',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Utente demo: wevo_demo\nEmail: demo@wevo.app\nPassword: wevo1234',
              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _enter,
                style: ElevatedButton.styleFrom(backgroundColor: WevoColors.pink),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Entra con account demo', style: TextStyle(color: Colors.white)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: WevoColors.coral)),
            ],
          ],
        ),
      ),
    );
  }
}
