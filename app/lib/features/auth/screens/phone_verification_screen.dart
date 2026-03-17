import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../onboarding/data/onboarding_data.dart';
import '../../onboarding/data/onboarding_session.dart';
import '../data/repositories/auth_repository.dart';
import '../../../shared/widgets/app_button.dart';

/// Firebase phone number verification after Create Account form.
/// Matches Figma OTP design: 6 digit boxes, timer pill, resend link.
class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({
    super.key,
    required this.phone,
    required this.name,
    required this.email,
    this.profilePictureUrl,
    this.isLoginMode = false,
  });

  final String phone;
  final String name;
  final String email;
  final String? profilePictureUrl;
  final bool isLoginMode;

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String? _verificationId;
  bool _loading = false;
  bool _sending = false;
  bool _resending = false;
  String? _error;
  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _sendCode();
    ApiClient().getJson('/ping').then((_) => _log('BACKEND PING', 'OK')).catchError((e) => _log('BACKEND PING', 'FAILED: $e'));
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _log(String msg, [String? extra]) {
    debugPrint('📱 AUTH OTP: $msg${extra != null ? ' | $extra' : ''}');
  }

  Future<void> _sendCode() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
      _resendSeconds = 60;
    });
    _resendTimer?.cancel();
    _startResendTimer();

    _log('REQUEST SMS', 'phone=${widget.phone}');
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _log('CALLBACK verificationCompleted', 'auto-retrieved');
          if (!mounted) return;
          setState(() => _loading = true);
          await _verifyWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _log('CALLBACK verificationFailed', 'code=${e.code} | ${e.message}');
          if (!mounted) return;
          setState(() {
            _sending = false;
            _error = e.message ?? 'Verification failed. Please try again.';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          _log('CALLBACK codeSent', 'verificationId=${verificationId.substring(0, 20)}...');
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _sending = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _log('CALLBACK codeAutoRetrievalTimeout');
          _verificationId ??= verificationId;
        },
      );
    } catch (e) {
      _log('EXCEPTION _sendCode', e.toString());
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Could not send verification code. Please try again.';
      });
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) t.cancel();
      });
    });
  }

  Future<void> _verifyWithCredential(PhoneAuthCredential credential) async {
    _log('VERIFY credential', 'calling signInWithCredential');
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      _log('VERIFY SUCCESS', 'Firebase verified phone');
      if (!mounted) return;
      if (widget.isLoginMode) {
        await _loginWithPhone();
      } else {
        await FirebaseAuth.instance.signOut();
        _navigateToOnboarding();
      }
    } catch (e) {
      _log('VERIFY FAILED', e.toString());
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Invalid code. Please try again.';
      });
    }
  }

  Future<void> _loginWithPhone() async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken(true);
      await FirebaseAuth.instance.signOut();
      if (idToken == null || idToken.isEmpty || !mounted) {
        setState(() => _loading = false);
        setState(() => _error = 'Could not sign in. Please try again.');
        return;
      }
      final result = await AuthRepository().loginWithPhone(idToken);
      if (!mounted) return;
      setState(() => _loading = false);
      if (result.ok) {
        context.go(AppRoutes.home);
      } else {
        setState(() => _error =
            result.errorMessage ?? 'No account found. Please register first.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      setState(() => _error = 'Could not sign in. Please try again.');
    }
  }

  void _navigateToOnboarding() {
    if (!mounted) return;
    setState(() => _loading = false);
    OnboardingSession.set(OnboardingData(
      name: widget.name,
      email: widget.email,
      phone: widget.phone,
      profilePictureUrl: widget.profilePictureUrl,
    ));
    context.push('${AppRoutes.choice}?fromOtp=1');
  }

  String get _enteredCode => _controllers.map((c) => c.text).join();

  Future<void> _verifyCode() async {
    final code = _enteredCode;
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    if (_verificationId == null) {
      setState(() => _error = 'Still sending code. Please wait.');
      return;
    }

    _log('USER SUBMIT CODE', 'code=$code');
    setState(() {
      _loading = true;
      _error = null;
    });

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: code,
    );
    await _verifyWithCredential(credential);
  }


  Future<void> _resendCode() async {
    if (_resending || _resendSeconds > 0) return;
    setState(() => _resending = true);
    await _sendCode();
    if (mounted) setState(() => _resending = false);
  }

  void _onOtpChanged(int index, String value) {
    setState(() => _error = null);
    if (value.length != 1) return;
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      FocusScope.of(context).unfocus();
      _verifyCode();
    }
  }

  void _goBack() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildBackButton(context),
                          const SizedBox(height: 56),
                          _buildTitle(),
                          const SizedBox(height: 20),
                          _buildSubtitle(),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade400, fontSize: 14),
                            ),
                          ],
                          const SizedBox(height: 30),
                          _buildOtpBoxes(),
                          const SizedBox(height: 50),
                          Center(
                            child: AppButton(
                              label: _loading ? 'Verifying...' : 'Verify',
                              isLoading: _loading,
                              onPressed: (_loading || _sending) ? null : _verifyCode,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(child: _buildTimerPill()),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 32),
                        child: Center(child: _buildResendText()),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _goBack,
        borderRadius: BorderRadius.circular(25),
        child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.greySoft1,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: AppColors.textPrimary,
        ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.lato(
          fontSize: 25,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.75,
          height: 1.6,
        ),
        children: [
          const TextSpan(text: 'Enter the '),
          TextSpan(
            text: 'code',
            style: GoogleFonts.lato(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.greyMedium,
          height: 1.25,
        ),
        children: [
          const TextSpan(text: 'Enter the 6 digit code that we just sent to\n'),
          TextSpan(
            text: widget.phone,
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBoxes() {
    const gap = 10.0;
    const totalGaps = 5 * gap;
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = (constraints.maxWidth - totalGaps) / 6;
        return AutofillGroup(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              for (var i = 0; i < 6; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                _buildOtpBox(i, boxWidth),
              ],
            ],
          ),
        );
      },
    );
  }

  void _onOtpBoxChanged(int index, String value) {
    if (value.length == 6) {
      // Autofill pasted full code (iOS / Android 11+)
      for (var i = 0; i < 6; i++) {
        _controllers[i].text = value[i];
      }
      FocusScope.of(context).unfocus();
      _verifyCode();
      return;
    }
    _onOtpChanged(index, value);
  }

  Widget _buildOtpBox(int index, double width) {
    final hasValue = _controllers[index].text.isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;
    final showBorder = hasValue || isFocused;
    final isFirst = index == 0;

    return SizedBox(
      width: width,
      height: 70,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _controllers[index].text.isEmpty &&
              index > 0) {
            _controllers[index - 1].clear();
            _focusNodes[index - 1].requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        autofillHints: isFirst ? const [AutofillHints.oneTimeCode] : null,
        keyboardType: TextInputType.number,
        maxLength: isFirst ? 6 : 1,
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 0.6,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.greySoft1,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: showBorder ? AppColors.inputBorderActive : Colors.transparent,
              width: 1.6,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.inputBorderActive,
              width: 1.6,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) => _onOtpBoxChanged(index, v),
        onFieldSubmitted: (_) {
          if (index == 5 && _enteredCode.length == 6) _verifyCode();
        },
      ),
      ),
    );
  }

  Widget _buildTimerPill() {
    final minutes = _resendSeconds ~/ 60;
    final seconds = _resendSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}.${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.greySoft1,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(
            timeStr,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              letterSpacing: 0.36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendText() {
    return GestureDetector(
      onTap: _resendSeconds > 0 || _resending ? null : _resendCode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.raleway(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.greyMedium,
              letterSpacing: 0.36,
              height: 1.67,
            ),
            children: [
              TextSpan(
                text: _resendSeconds > 0
                    ? 'Resend OTP in ${_resendSeconds}s'
                    : _resending
                        ? 'Sending...'
                        : "Didn't receive the OTP? ",
              ),
              if (_resendSeconds <= 0 && !_resending)
                TextSpan(
                  text: 'Resend OTP',
                  style: GoogleFonts.raleway(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
