import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleForm() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _controller.forward(from: 0.0); // Replay animation on form switch
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
              Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400), // Limit width
              child: Card(
                elevation: 8.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: FadeTransition( // Animation for the whole form
                    opacity: _animation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isLogin ? 'ログイン' : '新規登録',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isLogin
                              ? LoginForm(key: const ValueKey('loginForm'), onSwitch: _toggleForm)
                              : RegisterForm(key: const ValueKey('registerForm'), onSwitch: _toggleForm),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  final VoidCallback onSwitch;
  const LoginForm({super.key, required this.onSwitch});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインに失敗しました。ユーザー名またはパスワードを確認してください。')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'ユーザー名',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) => value!.isEmpty ? '入力してください' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'パスワード',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              prefixIcon: const Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) => value!.isEmpty ? '入力してください' : null,
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50), // Make button full width
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              child: const Text('登録', style: TextStyle(fontSize: 18)),
            ),
          TextButton(
            onPressed: widget.onSwitch,
            child: const Text('既にアカウントをお持ちですか？ ログイン'),
          ),
        ],
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  final VoidCallback onSwitch;
  const RegisterForm({super.key, required this.onSwitch});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.register(
      _usernameController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登録が完了しました。ログインしてください。')),
        );
        widget.onSwitch(); // Switch to login form
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登録に失敗しました。このユーザー名は既に使用されている可能性があります。')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'ユーザー名',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              prefixIcon: const Icon(Icons.person),
            ),
            validator: (value) => value!.isEmpty ? '入力してください' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'パスワード',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              prefixIcon: const Icon(Icons.lock),
            ),
            obscureText: true,
            validator: (value) => value!.isEmpty ? '入力してください' : null,
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50), // Make button full width
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              child: const Text('登録', style: TextStyle(fontSize: 18)),
            ),
          TextButton(
            onPressed: widget.onSwitch,
            child: const Text('既にアカウントをお持ちですか？ ログイン'),
          ),
        ],
      ),
    );
  }
}

