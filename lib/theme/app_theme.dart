import 'package:flutter/material.dart';

const Color kBumbleYellow = Color(0xFFFFD84D);

ButtonStyle bumbleButtonStyle() => FilledButton.styleFrom(
  backgroundColor: kBumbleYellow,
  foregroundColor: Colors.black,
  minimumSize: const Size.fromHeight(50),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
);
