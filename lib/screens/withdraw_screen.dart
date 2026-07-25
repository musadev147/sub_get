import 'package:flutter/material.dart';
import 'package:sub_get/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sub_get/services/firestore_service.dart';
import 'package:sub_get/services/auth_service.dart';

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
  final List<String> _methods = ['bKash', 'Nagad', 'BTC', 'USDT'];

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

      final user = await AuthService().getUser();
      if (user == null) return;

      final amount = int.parse(_amountController.text.trim());

      try {
        await FirestoreService().requestWithdrawal(
          userId: user.id,
          userName: user.name,
          userEmail: user.email,
          amount: amount,
          method: _selectedMethod,
          accountDetails: _accountController.text.trim(),
        );

        // Deduct coins
        await FirebaseFirestore.instance.collection('users').doc(user.id).update({
          'coin': FieldValue.increment(-amount),
        });

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
        title: const Text('Withdraw BTC'),
      ),
      body: StreamBuilder<AppUser?>(
        stream: AuthService().getUserStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          if (user == null) return const SizedBox.shrink();

          final int minWithdraw = 1000; // Define your min withdraw logic here

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
                              '${user.coin} BTC',
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
                              'Minimum Withdraw: $minWithdraw BTC',
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
                      labelText: 'Amount of BTC',
                      hintText: 'e.g. 1000',
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Please enter BTC amount';
                      final num = int.tryParse(v);
                      if (num == null) return 'Enter a valid number';
                      if (num < minWithdraw) return 'Below minimum withdraw limit';
                      if (num > user.coin) return 'Insufficient BTC balance';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Account Details
                  TextFormField(
                    controller: _accountController,
                    decoration: InputDecoration(
                      labelText: _selectedMethod == 'BTC' || _selectedMethod == 'USDT' 
                          ? '$_selectedMethod Wallet Address' 
                          : 'Mobile Account Number',
                      hintText: _selectedMethod == 'BTC' || _selectedMethod == 'USDT'
                          ? 'Enter $_selectedMethod wallet address'
                          : '01XXXXXXXXX',
                      prefixIcon: Icon(_selectedMethod == 'BTC' || _selectedMethod == 'USDT'
                          ? Icons.qr_code_scanner
                          : Icons.phone_iphone_outlined),
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
