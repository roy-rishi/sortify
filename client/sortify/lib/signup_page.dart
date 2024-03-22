import 'package:flutter/material.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.primary,
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text("Sign Up", style: titleStyle),
            ),
            Text(
                "To verify your email, you will receive an email at the provided address"),
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 24),
              child: SizedBox(
                width: 320,
                height: 48,
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Email",
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 42,
              child: OutlinedButton(
                onPressed: () => {
                  print("Registration requested"),
                },
                child: Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
