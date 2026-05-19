import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();

  String _sex = 'masculino';
  String _ocupacion = 'estudiante';
  double _freq = 3;
  bool _notifications = true;
  bool _acceptTos = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  Widget _buildSexOption(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: _sex,
          onChanged: (v) => setState(() => _sex = v!),
        ),
        Text(label),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: LoadingOverlay(
          isLoading: auth.isLoading,
          message: 'Creando cuenta...',
          child: ListView(
            padding: const EdgeInsets.all(AppDimens.lg),
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: AppDimens.sm),
              TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: AppDimens.sm),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: AppDimens.sm),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Contraseña'),
              ),
              const SizedBox(height: AppDimens.sm),
              TextField(
                controller: _passConfirmCtrl,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirmar contraseña'),
              ),
              const SizedBox(height: AppDimens.md),
              Text('Sexo', style: theme.textTheme.titleMedium),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildSexOption('masculino', 'Masculino'),
                  _buildSexOption('femenino', 'Femenino'),
                  _buildSexOption('prefiero_no', 'Prefiero no decir'),
                ],
              ),
              const SizedBox(height: AppDimens.md),
              DropdownButtonFormField<String>(
                value: _ocupacion,
                decoration: const InputDecoration(labelText: 'Ocupación'),
                items: const [
                  DropdownMenuItem(
                    value: 'estudiante',
                    child: Text('Estudiante'),
                  ),
                  DropdownMenuItem(
                    value: 'docente',
                    child: Text('Docente'),
                  ),
                  DropdownMenuItem(
                    value: 'profesional',
                    child: Text('Profesional'),
                  ),
                  DropdownMenuItem(
                    value: 'emprendedor',
                    child: Text('Emprendedor'),
                  ),
                  DropdownMenuItem(
                    value: 'otro',
                    child: Text('Otro'),
                  ),
                ],
                onChanged: (v) => setState(() => _ocupacion = v ?? _ocupacion),
              ),
              const SizedBox(height: AppDimens.md),
              Text(
                '¿Con qué frecuencia recicla actualmente?',
                style: theme.textTheme.bodyMedium,
              ),
              Slider(
                value: _freq,
                min: 0,
                max: 3,
                divisions: 3,
                label: () {
                  switch (_freq.round()) {
                    case 1:
                      return 'Raramente';
                    case 2:
                      return 'A veces';
                    case 3:
                      return 'Frecuentemente';
                    default:
                      return 'Nunca';
                  }
                }(),
                onChanged: (v) => setState(() => _freq = v),
              ),
              const SizedBox(height: AppDimens.md),
              SwitchListTile(
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
                title: const Text('Deseo recibir notificaciones'),
              ),
              CheckboxListTile(
                value: _acceptTos,
                onChanged: (v) => setState(() => _acceptTos = v ?? false),
                title: const Text('Acepto términos y condiciones'),
              ),
              const SizedBox(height: AppDimens.md),
              ElevatedButton(
                onPressed: _acceptTos && !auth.isLoading
                    ? () async {
                        if (_nameCtrl.text.trim().isEmpty ||
                            _usernameCtrl.text.trim().isEmpty ||
                            _emailCtrl.text.trim().isEmpty ||
                            _passCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Por favor complete los campos requeridos: Nombre, Username, Email y Contraseña.'),
                            ),
                          );
                          return;
                        }
                        if (_passCtrl.text != _passConfirmCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Las contraseñas no coinciden'),
                            ),
                          );
                          return;
                        }
                        final ok = await authNotifier.signup(
                          username: _usernameCtrl.text.trim(),
                          name: _nameCtrl.text.trim(),
                          email: _emailCtrl.text.trim(),
                          password: _passCtrl.text,
                        );
                        if (ok) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cuenta creada correctamente'),
                              ),
                            );
                            context.go(AppRoutes.login);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se pudo crear la cuenta'),
                            ),
                          );
                        }
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    auth.isLoading ? 'Creando cuenta...' : 'Crear cuenta',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
