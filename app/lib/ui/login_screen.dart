import 'package:flutter/material.dart';

import '../cloud/roborock_cloud.dart';
import '../l10n/describe.dart';
import '../l10n/strings.dart';
import '../session_store.dart';
import 'design/kit.dart';

/// Login to the Roborock account with a code sent by email (also works for accounts created with Google).
class LoginScreen extends StatefulWidget {
  final SessionStore store;
  final void Function(CloudSession, CloudDevice) onLoggedIn;

  const LoginScreen({super.key, required this.store, required this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  RoborockCloud? _cloud;
  bool _busy = false;
  Object? _error;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on Exception catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _sendCode() => _run(() async {
    final cloud = RoborockCloud(email: _email.text.trim(), deviceId: widget.store.deviceId);
    await cloud.requestCode();
    _cloud = cloud;
  });

  Future<void> _login() => _run(() async {
    final session = await _cloud!.login(_code.text.trim());
    final home = await RoborockCloud.home(session);
    if (home.devices.isEmpty) throw const CloudException(CloudErrorKind.noRobots, 'Account has no robots');
    await widget.store.save(session, home.devices.first);
    widget.onLoggedIn(session, home.devices.first);
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final codeSent = _cloud != null;
    return Scaffold(
      body: PageBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                children: [
                  Text('Roborock++', style: t.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(context.l.loginPitch, style: t.bodyLarge),
                  const SizedBox(height: 28),
                  Field(
                    controller: _email,
                    hint: context.l.emailHint,
                    icon: Icons.alternate_email_rounded,
                    enabled: !codeSent && !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    onSubmitted: (_) => _sendCode(),
                  ),
                  if (codeSent) ...[
                    const SizedBox(height: 14),
                    Field(
                      controller: _code,
                      hint: context.l.codeHint,
                      icon: Icons.pin_rounded,
                      enabled: !_busy,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      onSubmitted: (_) => _login(),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(errorText(context.l, _error!), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 22),
                  _busy
                      ? const SizedBox(height: 54, child: Center(child: Dots()))
                      : BigButton(
                          label: codeSent ? context.l.signIn : context.l.sendCode,
                          onTap: codeSent ? _login : _sendCode,
                        ),
                  if (codeSent)
                    Pressable(
                      onTap: _busy ? null : () => setState(() => _cloud = null),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Center(
                          child: Text(
                            context.l.changeEmail,
                            style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
