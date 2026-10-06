import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/credit_score_service.dart';

class CreditScoreScreen extends StatefulWidget {
  const CreditScoreScreen({super.key});

  @override
  State<CreditScoreScreen> createState() => _CreditScoreScreenState();
}

class _CreditScoreScreenState extends State<CreditScoreScreen> {
  final CreditScoreService _creditService = CreditScoreService();
  late Future<List<CreditHistoryItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _creditService.getCreditHistory();
  }

  Color _getScoreColor(double score) {
    if (score >= 150) return Colors.green;
    if (score >= 100) return Colors.blue;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(double score) {
    if (score >= 150) return 'Excellent';
    if (score >= 100) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Needs Improvement';
  }

  List<String> _getPerks(double score) {
    final perks = <String>[];
    if (score >= 50) perks.add('Basic rental access');
    if (score >= 100) perks.add('Standard vehicles available');
    if (score >= 150) perks.add('5% discount on bookings');
    if (score >= 180) perks.add('Premium vehicles unlocked');
    return perks;
  }

  double _calculateMonthlyChange(List<CreditHistoryItem> history) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    double change = 0;
    for (var item in history) {
      final date = DateTime.parse(item.date);
      if (date.isAfter(firstDayOfMonth) || date.isAtSameMomentAs(firstDayOfMonth)) {
        change += item.change;
      }
    }
    return change;
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final creditScore = user?.creditScore ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Credit Score'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<CreditHistoryItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          final history = snapshot.data ?? [];
          final monthlyChange = _calculateMonthlyChange(history);

          return SingleChildScrollView(
            child: Column(
              children: [

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue[700]!, Colors.blue[900]!],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your Trust Score',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: (creditScore / 200).clamp(0.0, 1.0),
                              strokeWidth: 12,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation(_getScoreColor(creditScore)),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                creditScore.toStringAsFixed(0),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _getScoreLabel(creditScore),
                                style: TextStyle(
                                  color: _getScoreColor(creditScore),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              monthlyChange >= 0 ? Icons.trending_up : Icons.trending_down,
                              color: monthlyChange >= 0 ? Colors.greenAccent : Colors.redAccent,
                              size: 18
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${monthlyChange >= 0 ? "+" : ""}${monthlyChange.toStringAsFixed(0)} points this month',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Benefits',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: _getPerks(creditScore).map((perk) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                                  const SizedBox(width: 12),
                                  Text(perk),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Score History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (history.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No history yet'),
                          ),
                        )
                      else
                        ...history.map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: item.change >= 0
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              child: Icon(
                                item.change >= 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: item.change >= 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            title: Text(item.reason),
                            subtitle: Text(item.date),
                            trailing: Text(
                              '${item.change >= 0 ? "+" : ""}${item.change.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: item.change >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
          },
        ),
      );
    }
}
