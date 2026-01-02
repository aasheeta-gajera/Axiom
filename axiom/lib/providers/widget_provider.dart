import 'package:flutter/material.dart';
import '../models/widget_model.dart';
import 'package:uuid/uuid.dart';

class WidgetProvider extends ChangeNotifier {
  List<WidgetModel> _widgets = [];
  WidgetModel? _selectedWidget;
  String? _currentScreenId = 'screen_1';

  List<WidgetModel> get widgets => _widgets;
  WidgetModel? get selectedWidget => _selectedWidget;
  String? get currentScreenId => _currentScreenId;

  void setWidgets(List<WidgetModel> widgets) {
    _widgets = widgets;
    notifyListeners();
  }

  void addWidget(WidgetModel widget) {
    _widgets.add(widget);
    notifyListeners();
  }

  void updateWidget(WidgetModel updatedWidget) {
    final index = _widgets.indexWhere((w) => w.id == updatedWidget.id);
    if (index != -1) {
      _widgets[index] = updatedWidget;
      if (_selectedWidget?.id == updatedWidget.id) {
        _selectedWidget = updatedWidget;
      }
      notifyListeners();
    }
  }

  void deleteWidget(String widgetId) {
    _widgets.removeWhere((w) => w.id == widgetId);
    if (_selectedWidget?.id == widgetId) {
      _selectedWidget = null;
    }
    notifyListeners();
  }

  void selectWidget(WidgetModel? widget) {
    _selectedWidget = widget;
    print('🔍 Selected widget: ${widget?.id} - Type: ${widget?.type}');
    notifyListeners();
  }

  void updateWidgetPosition(String widgetId, Offset position) {
    final index = _widgets.indexWhere((w) => w.id == widgetId);
    if (index != -1) {
      _widgets[index] = _widgets[index].copyWith(position: position);
      notifyListeners();
    }
  }

  void updateWidgetProperty(String widgetId, String key, dynamic value) {
    final index = _widgets.indexWhere((w) => w.id == widgetId);
    if (index != -1) {
      final widget = _widgets[index];
      final newProperties = Map<String, dynamic>.from(widget.properties);
      newProperties[key] = value;
      _widgets[index] = widget.copyWith(properties: newProperties);

      if (_selectedWidget?.id == widgetId) {
        _selectedWidget = _widgets[index];
      }
      notifyListeners();
    }
  }

  void clearWidgets() {
    _widgets.clear();
    _selectedWidget = null;
    notifyListeners();
  }

  void setCurrentScreen(String screenId) {
    _currentScreenId = screenId;
    notifyListeners();
  }

  // Helper method to create registration screen for testing
  void createRegistrationScreen() {
    clearWidgets();
    
    // Title widget
    addWidget(WidgetModel(
      id: const Uuid().v4(),
      type: 'Text',
      position: const Offset(150, 50),
      properties: {
        'text': 'User Registration',
        'fontSize': 24.0,
        'fontWeight': 'bold',
        'color': '#000000',
      },
    ));

    // Full Name TextField
    addWidget(WidgetModel(
      id: const Uuid().v4(),
      type: 'TextField',
      position: const Offset(150, 120),
      properties: {
        'label': 'Full Name',
        'fieldKey': 'name',
        'hint': 'Enter your full name',
        'width': 300.0,
      },
    ));

    // Email TextField
    addWidget(WidgetModel(
      id: const Uuid().v4(),
      type: 'TextField',
      position: const Offset(150, 180),
      properties: {
        'label': 'Email',
        'fieldKey': 'email',
        'hint': 'Enter your email',
        'width': 300.0,
      },
    ));

    // Password TextField
    addWidget(WidgetModel(
      id: const Uuid().v4(),
      type: 'TextField',
      position: const Offset(150, 240),
      properties: {
        'label': 'Password',
        'fieldKey': 'password',
        'hint': 'Enter your password',
        'obscureText': true,
        'width': 300.0,
      },
    ));

    // Register Button
    addWidget(WidgetModel(
      id: const Uuid().v4(),
      type: 'Button',
      position: const Offset(150, 300),
      properties: {
        'text': 'Register',
        'backgroundColor': '#2196F3',
        'color': '#FFFFFF',
        'fontSize': 16.0,
      },
    ));
  }
}