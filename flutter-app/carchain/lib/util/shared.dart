import 'package:flutter/material.dart';

// **** To change color for themes, modify these variables ****
// LIGHT THEME COLORS
const Color light_primaryDarkColor = Color(0xff1C5253); //Colors.green[600];
const Color light_primaryMiddleColor = Color(0xff00AD9F); //Colors.green[300];
const Color light_primaryLightColor = Color(0xfff5f5f5);
const Color light_accentColor = Color(0xffFF5A5F); //Colors.green[800];
const Color light_contrastColor = Colors.white;

final ThemeData lightTheme = ThemeData.light().copyWith(
  highlightColor: light_contrastColor,
  accentColor: light_accentColor,
  primaryColor: light_primaryLightColor,
  primaryColorLight: light_primaryMiddleColor,
  primaryColorDark: light_primaryDarkColor,
  backgroundColor: light_primaryLightColor,
  errorColor: light_accentColor,
  cardColor: light_contrastColor,
  buttonColor: light_primaryMiddleColor,
  scaffoldBackgroundColor: light_primaryLightColor,
  appBarTheme: AppBarTheme(
    color: light_primaryDarkColor,
    iconTheme: IconThemeData(
      color: light_contrastColor,
    ),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: light_primaryMiddleColor,
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
