import 'package:flutter/material.dart';

// **** To change color for themes, modify these variables ****
// LIGHT THEME COLORS
Color light_primaryDarkColor = Color(0xff1D3557); //Colors.green[600];
Color light_primaryMiddleColor = Color(0xff457B9D); //Colors.green[300];
Color light_primaryLightColor = Colors.grey[100];
Color light_accentColor = Color(0xffE63946); //Colors.green[800];
Color light_contrastColor = Colors.white;

final ThemeData lightTheme = ThemeData.light().copyWith(
  highlightColor: light_contrastColor,
  accentColor: light_accentColor,
  primaryColor: light_primaryDarkColor,
  primaryColorLight: light_primaryLightColor,
  errorColor: light_accentColor,
  cardColor: light_contrastColor,
  scaffoldBackgroundColor: light_primaryLightColor,
  appBarTheme: AppBarTheme(
    color: light_primaryDarkColor,
    iconTheme: IconThemeData(
      color: light_contrastColor,
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: light_primaryDarkColor,
    textTheme: ButtonTextTheme.primary,
    splashColor: light_primaryDarkColor,
    shape:
        RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: light_primaryMiddleColor,
    selectedItemColor: light_contrastColor,
  ),
  tabBarTheme: TabBarTheme(
    labelColor: light_primaryDarkColor,
    unselectedLabelColor: light_primaryMiddleColor,
  ),
  dividerTheme:
      DividerThemeData(thickness: 40.0, color: light_primaryDarkColor),
  toggleButtonsTheme: ToggleButtonsThemeData(
    fillColor: light_primaryMiddleColor,
    selectedColor: light_contrastColor,
  ),
  inputDecorationTheme:
      InputDecorationTheme(contentPadding: EdgeInsets.all(5.0)),
);
