import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/brand.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/screen_header.dart';
import '../providers/auth_provider.dart';
import '../widgets/staff_card.dart';
import 'device_enrollment_screen.dart';

/// "Build your staff card" — step 1 of sign-up (design direction C).
///
/// The card at the top fills in as the employee types. Submitting creates the
/// Firebase Auth user and the `pending` employee profile in one go (see
/// `AuthRepository.signUp`, which rolls the auth user back if the profile
/// call fails), then moves on to sealing the card to this phone.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _employeeId = TextEditingController();
  final TextEditingController _department = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    authProvider.clearError();
    // The card mirrors these three as they are typed.
    for (final TextEditingController c in [_name, _employeeId, _department]) {
      c.addListener(_onCardFieldChanged);
    }
  }

  void _onCardFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final TextEditingController c in [
      _name,
      _email,
      _phone,
      _employeeId,
      _department,
      _password,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await authProvider.signUp(
      email: _email.text,
      password: _password.text,
      fullName: _name.text,
      phone: _phone.text,
      employeeId: _employeeId.text,
      department: _department.text,
    );
    if (!mounted || !authProvider.isSignedIn) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const DeviceEnrollmentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final BrandPalette p = BrandPalette.forBrightness(brightness);

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: authProvider,
          builder: (context, _) {
            final bool busy = authProvider.isSigningIn;
            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // On a first launch this is the app's entry screen and
                      // there is nothing to go back to: registering is
                      // required. From the sign-in screen's "Create an
                      // account" link, back returns there.
                      if (Navigator.of(context).canPop())
                        IconButton(
                          tooltip: 'Back to sign in',
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          onPressed: busy
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          icon: Icon(CupertinoIcons.back, color: p.ink),
                        )
                      else
                        const SizedBox(height: 48),
                      const SectionEyebrow('1 / 2'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StaffCard(
                    name: _name.text,
                    employeeId: _employeeId.text.trim().toUpperCase(),
                    department: _department.text.trim(),
                  ),
                  const SizedBox(height: 22),
                  const ScreenTitle('Build your staff card'),
                  const SizedBox(height: 6),
                  Text(
                    'Your supervisor approves new accounts before you can clock in.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: p.muted,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Field(
                    label: 'Full name',
                    controller: _name,
                    enabled: !busy,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    validator: Validators.fullName,
                  ),
                  _Field(
                    label: 'Work email',
                    controller: _email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: Validators.email,
                  ),
                  _Field(
                    label: 'Phone number',
                    hint: 'e.g. 082 555 1234',
                    controller: _phone,
                    enabled: !busy,
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: Validators.phone,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _Field(
                          label: 'Employee ID',
                          hint: 'Optional',
                          controller: _employeeId,
                          enabled: !busy,
                          textCapitalization: TextCapitalization.characters,
                          validator: Validators.optionalEmployeeId,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Field(
                          label: 'Department',
                          hint: 'Optional',
                          controller: _department,
                          enabled: !busy,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),
                  _Field(
                    label: 'Password',
                    hint: 'At least 8 characters',
                    controller: _password,
                    enabled: !busy,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: Validators.newPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    suffix: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                        size: 20,
                      ),
                    ),
                  ),
                  if (authProvider.errorMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      authProvider.errorMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.danger(brightness),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  LoadingButton(
                    label: 'Next: seal your card',
                    loading: busy,
                    onPressed: _submit,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Label-above text field, per the design's form rows.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.hint,
    this.enabled = true,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.autofillHints,
    this.suffix,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final Widget? suffix;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final BrandPalette p = BrandPalette.forBrightness(
      Theme.of(context).brightness,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: p.ink,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            enabled: enabled,
            validator: validator,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            obscureText: obscureText,
            autocorrect: false,
            autofillHints: autofillHints,
            textInputAction: textInputAction,
            onFieldSubmitted: onSubmitted,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffix,
              fillColor: p.field,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
