// =========================================================
// MANDISYNC FLUTTER — HISTORY SCREEN
// =========================================================

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _api = ApiService();
  List<HistoryItemModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final list = await _api.getHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Activity & Audit History")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _history.length,
                itemBuilder: (context, i) {
                  final h = _history[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFF0F9FF),
                        child: Icon(Icons.history, color: Color(0xFF0284C7)),
                      ),
                      title: Text(h.eventType, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${h.details}\nModule: ${h.module}"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          h.status,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF075B38)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
