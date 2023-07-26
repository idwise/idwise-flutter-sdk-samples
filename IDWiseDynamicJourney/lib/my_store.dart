import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyStore with ChangeNotifier {
  bool _isJourneyStarted = false;
  String _journeyId = '';

  bool get isJourneyStarted => _isJourneyStarted;

  String get journeyId => _journeyId;

  void setJourneyStatus(bool status) {
    _isJourneyStarted = status;
    notifyListeners(); // Notify listeners about the change
  }

  void setJourneyId(String journeyId) {
    _journeyId = journeyId;
    notifyListeners(); // Notify listeners about the change
  }
}
