class ThemeModel {
  String primaryColor;
  String accentColor;
  String fontFamily;
  bool darkMode;

  ThemeModel({
    this.primaryColor = '#2196F3',
    this.accentColor = '#FF5722',
    this.fontFamily = 'Roboto',
    this.darkMode = false,
  });

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      primaryColor: json['primaryColor'] ?? '#2196F3',
      accentColor: json['accentColor'] ?? '#FF5722',
      fontFamily: json['fontFamily'] ?? 'Roboto',
      darkMode: json['darkMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor,
      'accentColor': accentColor,
      'fontFamily': fontFamily,
      'darkMode': darkMode,
    };
  }
}