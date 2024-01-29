import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyStore with ChangeNotifier {
  bool _isJourneyStarted = false;
  bool _isJourneyCompleted = false;
  String _journeyId = '';

  bool get isJourneyStarted => _isJourneyStarted;
  bool get isJourneyCompleted => _isJourneyCompleted;

  String get journeyId => _journeyId;

  void setJourneyStatus(bool status) {
    _isJourneyStarted = status;
    notifyListeners(); // Notify listeners about the change
  }

  void setJourneyCompleted(bool status) {
    _isJourneyCompleted = status;
    notifyListeners(); // Notify listeners about the change
  }

  void setJourneyId(String journeyId) {
    _journeyId = journeyId;
    notifyListeners(); // Notify listeners about the change
  }
}
