import 'package:flutter/material.dart';
import 'package:testproject/screens/home.dart';
import 'package:testproject/screens/login.dart';
import 'package:testproject/services/auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _loading = false;
  String? _error;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  String? _getPasswordError(String password) {
    if (password.length < 6) {
      return "Password must be at least 6 characters";
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Password must contain at least 1 uppercase letter";
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Password must contain at least 1 lowercase letter";
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Password must contain at least 1 number";
    }
    if (!RegExp(r'[!@#\$&*~]').hasMatch(password)) {
      return "Password must contain at least 1 special character (!@#\$&*~)";
    }
    return null;
  }

  bool _validateInputs() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
    });

    bool isValid = true;

    if (_emailController.text.trim().isEmpty) {
      setState(() => _emailError = "Please enter email");
      isValid = false;
    } else if (!_isValidEmail(_emailController.text.trim())) {
      setState(() => _emailError = "Invalid email format");
      isValid = false;
    }

    if (_passwordController.text.trim().isEmpty) {
      setState(() => _passwordError = "Please enter password");
      isValid = false;
    } else {
      String? passwordValidationError = _getPasswordError(_passwordController.text.trim());
      if (passwordValidationError != null) {
        setState(() => _passwordError = passwordValidationError);
        isValid = false;
      }
    }

    if (_confirmController.text.trim().isEmpty) {
      setState(() => _confirmError = "Please confirm password");
      isValid = false;
    } else if (_passwordController.text != _confirmController.text) {
      setState(() => _confirmError = "Password confirmation does not match");
      isValid = false;
    }

    return isValid;
  }

  void _signUp() async {
    if (!_validateInputs()) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: const OutlineInputBorder(),
                errorText: _emailError,
                errorBorder: _emailError != null 
                    ? const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      )
                    : null,
                focusedErrorBorder: _emailError != null
                    ? const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      )
                    : null,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                errorText: _passwordError,
                errorBorder: _passwordError != null 
                    ? const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      )
                    : null,
                focusedErrorBorder: _passwordError != null
                    ? const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      )
                    : null,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                border: const OutlineInputBorder(),
                errorText: _confirmError,
                errorBorder: _confirmError != null 
                    ? const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      )
                    : null,
                focusedErrorBorder: _confirmError != null
                    ? const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      )
                    : null,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _loading ? null : _signUp,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Sign Up"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text("Already have an account? Login"),
            )
          ],
        ),
      ),
    );
  }
}
