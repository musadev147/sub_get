import 'package:flutter/material.dart';
import 'package:sub_get/mock_database.dart';
import 'package:sub_get/theme.dart';
import 'package:sub_get/services/firestore_service.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  final _rewardController = TextEditingController(text: '100');
  final _workersController = TextEditingController(text: '50');
  final _stayController = TextEditingController(text: '20');
  final _instructionController = TextEditingController(
    text: '1. Click Start Task to open the link.\n2. Complete the required action.\n3. Stay at least 20 seconds.\n4. Return and claim coins.',
  );

  String? _selectedType;
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _firestoreService.seedCategoriesIfEmpty();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    _rewardController.dispose();
    _workersController.dispose();
    _stayController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a campaign type'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final db = MockDatabase();
      final title = _titleController.text.trim();
      final link = _linkController.text.trim();
      final reward = int.parse(_rewardController.text.trim());
      final workers = int.parse(_workersController.text.trim());
      final stay = int.parse(_stayController.text.trim());
      final instruction = _instructionController.text.trim();
      
      final cost = reward * workers;

      try {
        if (db.currentUser == null) throw Exception('Not logged in');
        
        // Deduct coins if not admin
        if (!db.isAdmin) {
          if (db.currentUser!.coin < cost) {
            throw Exception('Insufficient Coins! Required: $cost, Available: ${db.currentUser!.coin}');
          }
          // Note: Ideally, this user balance logic should also be moved to Firebase eventually.
          // For now, we update local mock database balance
          db.currentUser!.coin -= cost;
        }
        
        // Save to Firebase
        final campaign = Campaign(
          id: '', // Firestore will auto-generate
          title: title,
          link: link,
          type: _selectedType!,
          rewardCoin: reward,
          stayTime: stay,
          instruction: instruction,
          status: db.isAdmin ? 'active' : 'pending',
          createdBy: db.currentUser!.id,
          createdAt: DateTime.now(),
          totalWorkers: workers,
        );

        await _firestoreService.createCampaign(campaign);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Campaign submitted successfully!'),
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
        title: const Text('Create Campaign'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dynamic Campaign Type Dropdown from Firebase
              StreamBuilder<List<String>>(
                stream: _firestoreService.getCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primaryLight));
                  }
                  
                  final types = snapshot.data ?? [];
                  
                  // Make sure selectedType is valid
                  if (_selectedType != null && !types.contains(_selectedType)) {
                    _selectedType = null;
                  }
                  
                  // Auto-select first item if null and types exist
                  if (_selectedType == null && types.isNotEmpty) {
                    _selectedType = types.first;
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Campaign Type',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: types.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedType = val;
                        });
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Campaign Name
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Campaign Name',
                  hintText: 'e.g. Subscribe to my tech channel',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              // Target Link
              TextFormField(
                controller: _linkController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Campaign Target URL',
                  hintText: 'https://youtube.com/... or https://facebook.com/...',
                  prefixIcon: Icon(Icons.link_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter campaign URL';
                  if (!v.startsWith('http://') && !v.startsWith('https://')) {
                    return 'URL must start with http:// or https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Numerical config row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rewardController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Reward Coin',
                        hintText: 'e.g. 100',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final num = int.tryParse(v);
                        if (num == null || num <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _workersController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Workers Limit',
                        hintText: 'e.g. 50',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final num = int.tryParse(v);
                        if (num == null || num <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stay Duration
              TextFormField(
                controller: _stayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stay Time (Seconds)',
                  hintText: 'e.g. 20',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter stay duration';
                  final num = int.tryParse(v);
                  if (num == null || num < 10) return 'Duration must be at least 10s';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Instructions
              TextFormField(
                controller: _instructionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Worker Instructions',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.isEmpty ? 'Instructions are required' : null,
              ),
              const SizedBox(height: 24),
              // Budget preview card
              ListenableBuilder(
                listenable: MockDatabase(),
                builder: (context, _) {
                  final db = MockDatabase();
                  final reward = int.tryParse(_rewardController.text.trim()) ?? 0;
                  final workers = int.tryParse(_workersController.text.trim()) ?? 0;
                  final totalCost = reward * workers;
                  final balance = db.currentUser?.coin ?? 0;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Budget Cost:', style: TextStyle(color: AppTheme.textSecondary)),
                            Text('$totalCost Coins', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Available Balance:', style: TextStyle(color: AppTheme.textSecondary)),
                            Text('$balance Coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
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
                    : const Text('Submit Campaign'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
