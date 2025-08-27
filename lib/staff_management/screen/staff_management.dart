import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/staff_management/provider/provider.dart';
class AddStaffScreen extends StatelessWidget {
  const AddStaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StaffProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Staff"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Username",
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
                errorText:
                  provider.submitted &&  provider.username.isEmpty ? 'Username required' : null,
              ),
              onChanged: provider.setUsername,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "Email",
                prefixIcon: const Icon(Icons.email),
                border: const OutlineInputBorder(),
                errorText:provider.submitted && (provider.email.isEmpty || !provider.email.contains('@'))
                    ? 'Valid email required'
                    : null,
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: provider.setEmail,
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: provider.obscurePassword,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                errorText:provider.submitted && ( provider.password.isEmpty || provider.password.length < 6)
                    ? 'Min 6 characters'
                    : null,
                suffixIcon: IconButton(
                  icon: Icon(provider.obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: provider.togglePasswordVisibility,
                ),
              ),
              onChanged: provider.setPassword,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                ),
      onPressed: () async {
  provider.markSubmitted(); // set _submitted = true

  if (!provider.validateFields()) return;

  try {
    await provider.submitStaff();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Staff Added Successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
},

                child: const Text(
                  "Add Staff",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}