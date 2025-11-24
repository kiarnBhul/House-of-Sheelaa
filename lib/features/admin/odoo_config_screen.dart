import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:house_of_sheelaa/theme/brand_theme.dart';
import '../../core/odoo/odoo_config.dart';
import '../../core/odoo/odoo_state.dart';

class OdooConfigScreen extends StatefulWidget {
  static const String route = '/odoo-config';
  const OdooConfigScreen({super.key});

  @override
  State<OdooConfigScreen> createState() => _OdooConfigScreenState();
}

class _OdooConfigScreenState extends State<OdooConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _databaseController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureApiKey = true;
  bool _isConnecting = false;
  bool _useApiKey = true; // Default to API key authentication

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    await OdooConfig.loadConfig();
    setState(() {
      _baseUrlController.text = OdooConfig.baseUrl;
      _databaseController.text = OdooConfig.database;
      _apiKeyController.text = OdooConfig.apiKey;
      _usernameController.text = OdooConfig.username;
      _passwordController.text = OdooConfig.password;
      _useApiKey = OdooConfig.apiKey.isNotEmpty;
    });
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _databaseController.dispose();
    _apiKeyController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isConnecting = true);

    final odooState = context.read<OdooState>();
    final success = await odooState.configure(
      baseUrl: _baseUrlController.text.trim(),
      database: _databaseController.text.trim(),
      apiKey: _useApiKey ? _apiKeyController.text.trim() : '',
      username: _useApiKey ? '' : _usernameController.text.trim(),
      password: _useApiKey ? '' : _passwordController.text.trim(),
    );

    setState(() => _isConnecting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Successfully connected to Odoo!'),
            backgroundColor: BrandColors.ecstasy,
          ),
        );
        // Refresh data after successful connection
        await odooState.refreshAll();
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: ${odooState.error ?? "Unknown error"}'),
            backgroundColor: BrandColors.persianRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final odooState = context.watch<OdooState>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BrandColors.jacaranda,
                    BrandColors.cardinalPink,
                    BrandColors.persianRed,
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  leading: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          BrandColors.alabaster.withValues(alpha: 0.25),
                          BrandColors.alabaster.withValues(alpha: 0.15),
                        ],
                      ),
                      border: Border.all(
                        color: BrandColors.alabaster.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: BrandColors.alabaster,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    'Odoo Configuration',
                    style: tt.titleLarge?.copyWith(
                      color: BrandColors.alabaster,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: false,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            BrandColors.alabaster.withValues(alpha: 0.15),
                            BrandColors.alabaster.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: BrandColors.alabaster.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: BrandColors.codGrey.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            BrandColors.ecstasy.withValues(alpha: 0.8),
                                            BrandColors.persianRed.withValues(alpha: 0.8),
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.settings_rounded,
                                        color: BrandColors.alabaster,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Connect to Odoo',
                                            style: tt.headlineSmall?.copyWith(
                                              color: BrandColors.alabaster,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Configure your Odoo instance to manage products, services, and events',
                                            style: tt.bodyMedium?.copyWith(
                                              color: BrandColors.alabaster.withValues(alpha: 0.8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // CORS Warning for Web Builds
                                if (kIsWeb)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: BrandColors.ecstasy.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: BrandColors.ecstasy.withValues(alpha: 0.5),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: BrandColors.ecstasy,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Web Build CORS Limitation',
                                                style: tt.titleSmall?.copyWith(
                                                  color: BrandColors.ecstasy,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Flutter web apps may encounter CORS errors when connecting to Odoo. If you see "Failed to fetch" errors, try:\n'
                                                '• Testing on mobile/desktop builds\n'
                                                '• Configuring Odoo server CORS settings\n'
                                                '• Using a backend proxy server',
                                                style: tt.bodySmall?.copyWith(
                                                  color: BrandColors.alabaster.withValues(alpha: 0.9),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                _buildTextField(
                                  controller: _baseUrlController,
                                  label: 'Odoo Base URL',
                                  hint: 'https://your-odoo-instance.com (without /odoo)',
                                  icon: Icons.link_rounded,
                                  keyboardType: TextInputType.url,
                                  required: true,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 4),
                                  child: Text(
                                    'For Odoo.com: Use https://your-instance.odoo.com (remove /odoo if present)',
                                    style: tt.bodySmall?.copyWith(
                                      color: BrandColors.alabaster.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _databaseController,
                                  label: 'Database Name',
                                  hint: 'your_database_name',
                                  icon: Icons.storage_rounded,
                                  required: true,
                                ),
                                const SizedBox(height: 16),
                                // Authentication Method Toggle
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: BrandColors.alabaster.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: BrandColors.alabaster.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.vpn_key_rounded,
                                        color: BrandColors.ecstasy,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Use API Key Authentication',
                                          style: tt.bodyMedium?.copyWith(
                                            color: BrandColors.alabaster,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Switch(
                                        value: _useApiKey,
                                        onChanged: (value) {
                                          setState(() => _useApiKey = value);
                                        },
                                        activeColor: BrandColors.ecstasy,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_useApiKey)
                                  _buildTextField(
                                    controller: _apiKeyController,
                                    label: 'API Key',
                                    hint: 'Enter your Odoo API key',
                                    icon: Icons.vpn_key_rounded,
                                    obscureText: _obscureApiKey,
                                    required: true,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureApiKey
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      color: BrandColors.alabaster.withValues(alpha: 0.7),
                                      onPressed: () {
                                        setState(() => _obscureApiKey = !_obscureApiKey);
                                      },
                                    ),
                                  )
                                else ...[
                                  _buildTextField(
                                    controller: _usernameController,
                                    label: 'Username',
                                    hint: 'your_username',
                                    icon: Icons.person_outline_rounded,
                                    required: true,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hint: 'your_password',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscurePassword,
                                    required: true,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      color: BrandColors.alabaster.withValues(alpha: 0.7),
                                      onPressed: () {
                                        setState(() => _obscurePassword = !_obscurePassword);
                                      },
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                if (odooState.isAuthenticated)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          BrandColors.ecstasy.withValues(alpha: 0.3),
                                          BrandColors.persianRed.withValues(alpha: 0.3),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: BrandColors.ecstasy.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: BrandColors.ecstasy,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Connected to Odoo',
                                            style: tt.bodyLarge?.copyWith(
                                              color: BrandColors.alabaster,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (odooState.error != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: BrandColors.persianRed.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: BrandColors.persianRed.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: BrandColors.persianRed,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            odooState.error!,
                                            style: tt.bodyMedium?.copyWith(
                                              color: BrandColors.alabaster,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [BrandColors.ecstasy, BrandColors.persianRed],
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: BrandColors.ecstasy.withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isConnecting || odooState.isLoading
                                        ? null
                                        : _testConnection,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: BrandColors.alabaster,
                                      minimumSize: const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                    ),
                                    child: _isConnecting || odooState.isLoading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(BrandColors.alabaster),
                                            ),
                                          )
                                        : const Text(
                                            'Test & Connect',
                                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                          ),
                                  ),
                                ),
                                if (odooState.isAuthenticated) ...[
                                  const SizedBox(height: 16),
                                  TextButton(
                                    onPressed: () async {
                                      await odooState.logout();
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Disconnected from Odoo'),
                                            backgroundColor: BrandColors.ecstasy,
                                          ),
                                        );
                                      }
                                    },
                                    child: Text(
                                      'Disconnect',
                                      style: tt.labelLarge?.copyWith(
                                        color: BrandColors.persianRed,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    bool required = false,
  }) {
    final tt = Theme.of(context).textTheme;
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: tt.bodyLarge?.copyWith(color: BrandColors.alabaster),
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        hintText: hint,
        prefixIcon: Icon(icon, color: BrandColors.ecstasy),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: BrandColors.codGrey.withValues(alpha: 0.25),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: BrandColors.alabaster.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: BrandColors.ecstasy,
            width: 2,
          ),
        ),
        labelStyle: tt.bodyMedium?.copyWith(
          color: BrandColors.alabaster.withValues(alpha: 0.7),
        ),
        hintStyle: tt.bodyMedium?.copyWith(
          color: BrandColors.alabaster.withValues(alpha: 0.5),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              if (keyboardType == TextInputType.url) {
                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                  return 'Please enter a valid URL';
                }
              }
              return null;
            }
          : null,
    );
  }
}

