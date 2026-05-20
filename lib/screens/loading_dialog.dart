import 'package:flutter/material.dart';

class LoadingDialog{
  static Future<void> show(
    BuildContext context, {
      String? message,
      bool dismissible = false,
    }) {
      return showDialog( 
        context: context,
        barrierDismissible: dismissible,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  message ?? "Please wait...",
                  style: const TextStyle(fontSize: 16),
                ),
                ),
            ],
          ),
        ),
      );
    }
    static void hide(BuildContext context) {
      Navigator.of(context).pop();
    }
}