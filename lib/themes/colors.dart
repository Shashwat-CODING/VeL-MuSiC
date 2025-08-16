import 'package:flutter/material.dart';

// Spotify Colors
const Color spotifyGreen = Color(0xFF1DB954);
const Color spotifyDarkGreen = Color(0xFF1ed760);
const Color spotifyBlack = Color(0xFF191414);
const Color spotifyDarkGrey = Color(0xFF282828);
const Color spotifyMediumGrey = Color(0xFF535353);
const Color spotifyLightGrey = Color(0xFFB3B3B3);
const Color spotifyWhite = Color(0xFFFFFFFF);

Color greyColor = Colors.grey.withAlpha(100);
Color darkGreyColor = Colors.grey.withAlpha(70);

const MaterialColor primaryBlack = MaterialColor(
  0xFF000000,
  <int, Color>{
    50: Color.fromRGBO(0, 0, 0, .1),
    100: Color.fromRGBO(0, 0, 0, .2),
    200: Color.fromRGBO(0, 0, 0, .3),
    300: Color.fromRGBO(0, 0, 0, .4),
    400: Color.fromRGBO(0, 0, 0, .5),
    500: Color.fromRGBO(0, 0, 0, .6),
    600: Color.fromRGBO(0, 0, 0, .7),
    700: Color.fromRGBO(0, 0, 0, .8),
    800: Color.fromRGBO(0, 0, 0, .9),
    900: Color.fromRGBO(0, 0, 0, 1),
  },
);

const MaterialColor primaryWhite = MaterialColor(
  0xFFFFFFFF,
  <int, Color>{
    50: Color.fromRGBO(255, 255, 255, .1),
    100: Color.fromRGBO(255, 255, 255, .2),
    200: Color.fromRGBO(255, 255, 255, .3),
    300: Color.fromRGBO(255, 255, 255, .4),
    400: Color.fromRGBO(255, 255, 255, .5),
    500: Color.fromRGBO(255, 255, 255, .6),
    600: Color.fromRGBO(255, 255, 255, .7),
    700: Color.fromRGBO(255, 255, 255, .8),
    800: Color.fromRGBO(255, 255, 255, .9),
    900: Color.fromRGBO(255, 255, 255, 1),
  },
);

// Spotify Material Color
const MaterialColor spotifyGreenSwatch = MaterialColor(
  0xFF1DB954,
  <int, Color>{
    50: Color(0xFFE8F5E8),
    100: Color(0xFFC5E6C5),
    200: Color(0xFF9FD69F),
    300: Color(0xFF79C679),
    400: Color(0xFF5CBA5C),
    500: Color(0xFF1DB954), // Primary Spotify Green
    600: Color(0xFF1AA64A),
    700: Color(0xFF159240),
    800: Color(0xFF117E36),
    900: Color(0xFF0A5D28),
  },
);
