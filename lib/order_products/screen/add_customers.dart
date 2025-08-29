import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/order_products/provider/customer.dart';

class AddCustomers extends StatelessWidget {
  AddCustomers({super.key});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customerProvider = Provider.of<Costomer>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Add Customers")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// Name Field
            TextField(
              controller: nameController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Name",
                hintText: "Enter Customer Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => customerProvider.setUsername(value),
            ),
            const SizedBox(height: 20),

            /// Qatar Phone Number Field
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8), // Qatar has 8 digits
              ],
              decoration: InputDecoration(
                labelText: "Contact Number",
                hintText: "Enter 8-digit Qatar Number",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => customerProvider.setEmail(value),
            ),

            const Spacer(),

            /// Add Customer Button
            GestureDetector(
              onTap: () async {
                try {
                  await customerProvider.submitStaff();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Customer Added Successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );

                  nameController.clear();
                  phoneController.clear();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("❌ Invalid Qatar Phone Number"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.primaryColor,
                ),
                child: const Center(
                  child: Text(
                    "Add Customer",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
