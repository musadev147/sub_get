import 'package:flutter/material.dart';
import 'package:sub_get/mock_database.dart';
import 'package:sub_get/theme.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();
  
  String _selectedMethod = 'bKash';
  bool _isLoading = false;

  final List<String> _methods = ['bKash', 'Nagad', 'Rocket', 'Bank'];

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final db = MockDatabase();
      final amount = int.parse(_amountController.text.trim());
      final account = _accountController.text.trim();

      try {
        await db.requestWithdraw(
          coinAmount: amount,
          method: _selectedMethod,
          accountDetails: account,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Withdrawal request submitted successfully!'),
              backgroundColor: AppTheme.secondary,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw Coins'),
      ),
      body: ListenableBuilder(
        listenable: MockDatabase(),
        builder: (context, _) {
          final db = MockDatabase();
          final user = db.currentUser;
          if (user == null) return const SizedBox.shrink();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Balance Card Summary
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        const Text('Available Balance', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.monetization_on, color: AppTheme.accent, size: 26),
                            const SizedBox(width: 6),
                            Text(
                              '${user.coin} Coins',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.accent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Minimum Withdraw: ${db.minWithdrawCoins} Coins',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Dropdown Method Selection
                  DropdownButtonFormField<String>(
                    value: _selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Select Payment Method',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                    items: _methods.map((method) {
                      return DropdownMenuItem<String>(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedMethod = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount of Coins',
                      hintText: 'e.g. 1000',
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please enter coins amount';
                      final num = int.tryParse(v);
                      if (num == null) return 'Enter a valid number';
                      if (num < db.minWithdrawCoins) return 'Below minimum withdraw limit';
                      if (num > user.coin) return 'Insufficient coins balance';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Account Details
                  TextFormField(
                    controller: _accountController,
                    decoration: InputDecoration(
                      labelText: _selectedMethod == 'Bank' ? 'Bank Account Details' : 'Mobile Account Number',
                      hintText: _selectedMethod == 'Bank'
                          ? 'Bank Name, Branch, A/C: 123-456...'
                          : '01XXXXXXXXX',
                      prefixIcon: const Icon(Icons.phone_iphone_outlined),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Account details are required' : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Request Payout'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
