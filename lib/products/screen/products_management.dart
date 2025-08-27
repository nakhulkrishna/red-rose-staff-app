import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:staff_app/products/provider/products_management.dart';

// class ProductsScreen extends StatelessWidget {
//   const ProductsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final productProvider = Provider.of<ProductProvider>(context);

//     // 🔎 Apply search + filter
//     final products = productProvider.filteredProducts;

//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: const Text(
//           "Products",
//           style: TextStyle(
//             fontSize: 22,
//             fontWeight: FontWeight.bold,
//             color: Colors.black,
//           ),
//         ),
//         centerTitle: false,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             // 🔹 Search Bar
//             Container(
//               height: 50,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black12,
//                     blurRadius: 6,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   const Icon(
//                     Iconsax.search_normal,
//                     size: 22,
//                     color: Colors.grey,
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: TextField(
//                       decoration: const InputDecoration(
//                         hintText: "Search products...",
//                         border: InputBorder.none,
//                       ),
//                       onChanged: (value) {
//                         productProvider.setSearchQuery(value);
//                       },
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(
//                       Iconsax.setting_4,
//                       size: 22,
//                       color: Colors.black87,
//                     ),
//                     onPressed: () {
//                       showModalBottomSheet(
//                         context: context,
//                         backgroundColor: Colors.white,
//                         shape: const RoundedRectangleBorder(
//                           borderRadius: BorderRadius.vertical(
//                             top: Radius.circular(20),
//                           ),
//                         ),
//                         builder: (_) {
//                           return Consumer<ProductProvider>(
//                             builder: (context, provider, child) {
//                               return Padding(
//                                 padding: const EdgeInsets.all(20),
//                                 child: Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     const Text(
//                                       "Filter by Category",
//                                       style: TextStyle(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 16),

//                                     // "All" option
//                                     ListTile(
//                                       leading: Icon(
//                                         provider.selectedCategory == null
//                                             ? Icons.radio_button_checked
//                                             : Icons.radio_button_off,
//                                         color: Colors.blueAccent,
//                                       ),
//                                       title: const Text("All"),
//                                       onTap: () {
//                                         provider.setCategory(null);
//                                         Navigator.pop(context);
//                                       },
//                                     ),

//                                     // Category List
//                                     ...provider.categories.map((c) {
//                                       return ListTile(
//                                         leading: Icon(
//                                           provider.selectedCategory == c.name
//                                               ? Icons.radio_button_checked
//                                               : Icons.radio_button_off,
//                                           color: Colors.blueAccent,
//                                         ),
//                                         title: Text(c.name),
//                                         onTap: () {
//                                           provider.setCategory(c.name);
//                                           Navigator.pop(context);
//                                         },
//                                       );
//                                     }).toList(),
//                                   ],
//                                 ),
//                               );
//                             },
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // 🔹 Table Header
//             Container(
//               height: 45,
//               padding: const EdgeInsets.symmetric(horizontal: 12),
//               decoration: BoxDecoration(
//                 color: Colors.blueGrey.shade700,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 children: const [
//                   SizedBox(width: 40),
//                   Expanded(
//                     flex: 3,
//                     child: Text(
//                       'Products',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   SizedBox(
//                     width: 80,
//                     child: Text(
//                       'Actions',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 12),

//             // 🔹 Product List
//             Expanded(
//               child: products.isEmpty
//                   ? const Center(child: Text("No products found"))
//                   : ListView.builder(
//                       itemCount: products.length,
//                       itemBuilder: (context, index) {
//                         final product = products[index];
//                         final isExpanded =
//                             productProvider.expandedProductId == product.id;

//                         return GestureDetector(
//                           onTap: () =>
//                               productProvider.toggleExpanded(product.id),
//                           child: AnimatedContainer(
//                             duration: const Duration(milliseconds: 300),
//                             curve: Curves.easeInOut,
//                             margin: const EdgeInsets.only(bottom: 12),
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(15),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black12,
//                                   blurRadius: 6,
//                                   offset: const Offset(0, 3),
//                                 ),
//                               ],
//                             ),
//                             child: Column(
//                               children: [
//                                 Row(
//                                   children: [
//                                     // Product Image
//                                     // Product Image (show first image or fallback)
//                                     ClipRRect(
//                                       borderRadius: BorderRadius.circular(12),
//                                       child: buildProductImage(
//                                         product.images.isNotEmpty
//                                             ? product.images.first
//                                             : "",
//                                       ),
//                                     ),

//                                     const SizedBox(width: 12),

//                                     // Product Info
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             product.name,
//                                             style: const TextStyle(
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                           const SizedBox(height: 4),
//                                           Row(
//                                             children: [
//                                               Text(
//                                                 "₹ ${product.price}  ",
//                                                 style: TextStyle(
//                                                   fontSize: 14,
//                                                   fontWeight: FontWeight.w600,
//                                                   color: Colors.red,
//                                                 ),
//                                               ),
//                                               Text(
//                                               "/  ${product.unit}",
//                                                 style: TextStyle(
//                                                   fontSize: 14,
//                                                   color: Colors.red.shade300,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                     ),

//                                     // Actions
//                                     IconButton(
//                                       onPressed: () {
//                                         showOrderBottomSheet(
//                                           context,
//                                           product,
//                                           productProvider,
//                                         );
//                                       },
//                                       icon: const Icon(
//                                         Iconsax.send_2,
//                                         color: Colors.green,
//                                         size: 26,
//                                       ),
//                                     ),
//                                   ],
//                                 ),

//                                 // Expanded Section
//                                 if (isExpanded) ...[
//                                   const SizedBox(height: 12),
//                                   Container(
//                                     width: double.infinity,
//                                     padding: const EdgeInsets.all(12),
//                                     decoration: BoxDecoration(
//                                       color: Colors.grey.shade50,
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         // 🔹 Multiple Images Carousel
//                                         if (product.images.isNotEmpty)
//                                           SizedBox(
//                                             height: 120,
//                                             child: ListView.separated(
//                                               scrollDirection: Axis.horizontal,
//                                               itemCount: product.images.length,
//                                               separatorBuilder: (_, __) =>
//                                                   const SizedBox(width: 10),
//                                               itemBuilder: (context, i) {
//                                                 return ClipRRect(
//                                                   borderRadius:
//                                                       BorderRadius.circular(10),
//                                                   child: buildProductImage(
//                                                     product.images[i],
//                                                     size: 120,
//                                                   ),
//                                                 );
//                                               },
//                                             ),
//                                           ),

//                                         const SizedBox(height: 12),

//                                         // Product details
//                                         Text(
//                                           "📦 Product details:\n- Stock: ${product.stock} pcs\n- Category: ${product.categoryId}\n- Description: ${product.description}",
//                                           style: const TextStyle(
//                                             fontSize: 14,
//                                             color: Colors.black87,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// 🖼️ Product image helper
//   Widget buildProductImage(String base64Image, {double size = 40}) {
//     try {
//       if (base64Image.isEmpty) {
//         return Icon(Iconsax.camera, size: size, color: Colors.grey);
//       }
//       return Image.memory(
//         base64Decode(base64Image),
//         width: size,
//         height: size,
//         fit: BoxFit.cover,
//       );
//     } catch (e) {
//       return Icon(Icons.broken_image, size: size, color: Colors.red);
//     }
//   }

//   void showOrderBottomSheet(
//     BuildContext context,
//     Product product,
//     ProductProvider provider,
//   ) {
//     int quantity = 1;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//       ),
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             return Padding(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // 🔹 Drag Handle
//                   Center(
//                     child: Container(
//                       width: 40,
//                       height: 5,
//                       margin: const EdgeInsets.only(bottom: 20),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade300,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),

//                   // 🔹 Product Card
//                   Row(
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: buildProductImage(
//                           product.images.isNotEmpty ? product.images.first : "",
//                           size: 50,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               product.name,
//                               style: const TextStyle(
//                                 fontSize: 20,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             const SizedBox(height: 5),
//                             Text(
//                               "₹ ${product.price} / ${product.unit}",
//                               style: TextStyle(
//                                 fontSize: 15,
//                                 color: Colors.grey.shade600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 25),

//                   // 🔹 Quantity Selector
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "Quantity (${product.unit})",
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),

//                       // +/- Counter
//                       Row(
//                         children: [
//                           IconButton(
//                             onPressed: () {
//                               if (quantity > 1) {
//                                 setModalState(() => quantity--);
//                               }
//                             },
//                             icon: const Icon(
//                               Icons.remove_circle,
//                               color: Colors.redAccent,
//                               size: 28,
//                             ),
//                           ),
//                           Text(
//                             "$quantity",
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           IconButton(
//                             onPressed: () {
//                               if (quantity < product.stock) {
//                                 // ✅ restrict to stock
//                                 setModalState(() => quantity++);
//                               } else {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text(
//                                       "⚠️ Not enough stock available",
//                                     ),
//                                   ),
//                                 );
//                               }
//                             },
//                             icon: const Icon(
//                               Icons.add_circle,
//                               color: Colors.green,
//                               size: 28,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),

//                   const SizedBox(height: 20),

//                   // 🔹 Total Price
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 14,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.blueGrey.shade50,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           "Total",
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         Text(
//                           "₹ ${(product.price * quantity).toStringAsFixed(2)}",
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blueAccent,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 25),

//                   // 🔹 Place Order Button
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton.icon(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                       ),
//                       onPressed: () {
//                         Navigator.pop(context);
//                         provider.sendOrderWhatsApp(product, quantity, context);
//                       },
//                       icon: const Icon(Iconsax.send_2, color: Colors.white),
//                       label: const Text(
//                         "Place Order",
//                         style: TextStyle(fontSize: 16, color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }


