import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:staff_app/features/auth/presentation/providers/salesman_market_provider.dart';
import 'package:staff_app/features/products/domain/entities/product.dart';
import 'package:staff_app/features/products/presentation/providers/product_list_provider.dart';
import 'package:staff_app/shared/widgets/price_mode_banner.dart';

final NumberFormat _qarMoney = NumberFormat.currency(
  name: 'QAR',
  symbol: 'QAR ',
  decimalDigits: 2,
);

class ProductsListPage extends ConsumerStatefulWidget {
  const ProductsListPage({super.key});

  @override
  ConsumerState<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends ConsumerState<ProductsListPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final priceModeLabel =
        ref.watch(salesmanMarketContextProvider).valueOrNull?.priceModeLabel ??
        'Local Market';

    return Scaffold(
      appBar: AppBar(title: const Text('Products Catalog')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: PriceModeBanner(label: priceModeLabel),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: TextField(
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: const InputDecoration(
                hintText: 'Search by name or code',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                final filtered = _filterProducts(products, _query);
                if (filtered.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  child: _ProductsTable(products: filtered),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Could not load products.\n$error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Product> _filterProducts(List<Product> products, String query) {
    if (query.isEmpty) return products;
    final q = query.toLowerCase();
    return products.where((product) {
      return product.name.toLowerCase().contains(q) ||
          product.code.toLowerCase().contains(q);
    }).toList();
  }
}

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 900,
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: const Row(
                    children: [
                      _Cell(text: 'Image', width: 110, bold: true),
                      _Cell(text: 'Code', width: 130, bold: true),
                      _Cell(text: 'Product Name', width: 230, bold: true),
                      _Cell(text: 'Price', width: 120, bold: true),
                      _Cell(text: 'Offer Price', width: 130, bold: true),
                      _Cell(text: 'Stock', width: 140, bold: true),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: products.length,
                    cacheExtent: 720,
                    addAutomaticKeepAlives: false,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 1),
                    itemBuilder: (context, index) =>
                        _ProductRow(product: products[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imageUrls = product.imageUrls.isEmpty
        ? (product.imageUrl.isNotEmpty ? [product.imageUrl] : <String>[])
        : product.imageUrls;
    final offer = product.offerPriceQar;
    final showOffer = offer > 0 && offer < product.priceQar;
    final openViewer = imageUrls.isEmpty
        ? null
        : () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductImageViewerPage(
                  productName: product.name,
                  imageUrls: imageUrls,
                ),
              ),
            );
          };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: openViewer,
                borderRadius: BorderRadius.circular(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _ProductThumb(
                    url: imageUrls.isEmpty ? '' : imageUrls.first,
                    size: 56,
                  ),
                ),
              ),
            ),
          ),
          _Cell(text: product.code, width: 130),
          _Cell(text: product.name, width: 230),
          _Cell(text: _qarMoney.format(product.priceQar), width: 120),
          _Cell(
            text: showOffer ? _qarMoney.format(offer) : '-',
            width: 130,
            color: showOffer ? const Color(0xFFB91C1C) : null,
            bold: showOffer,
          ),
          _Cell(
            text:
                '${product.availableStock.toStringAsFixed(2)} ${product.baseUnit}',
            width: 140,
            color: const Color(0xFF0F766E),
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.text,
    required this.width,
    this.bold = false,
    this.color,
  });

  final String text;
  final double width;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? const Color(0xFF111827),
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.url, this.size = 92});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final targetPixels = (size * pixelRatio).round().clamp(1, 1024);

    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: const Color(0xFFF3F4F6),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined),
      );
    }

    return Image.network(
      url,
      width: size,
      height: size,
      cacheWidth: targetPixels,
      cacheHeight: targetPixels,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      errorBuilder: (_, __, ___) {
        return Container(
          width: size,
          height: size,
          color: const Color(0xFFF3F4F6),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        );
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: size,
          height: size,
          color: const Color(0xFFF9FAFB),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}

class ProductImageViewerPage extends StatefulWidget {
  const ProductImageViewerPage({
    super.key,
    required this.productName,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  final String productName;
  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<ProductImageViewerPage> createState() => _ProductImageViewerPageState();
}

class _ProductImageViewerPageState extends State<ProductImageViewerPage> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    if (widget.imageUrls.isEmpty) {
      _index = 0;
    } else {
      _index = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    }
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.productName),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final mediaSize = MediaQuery.sizeOf(context);
                final pixelRatio = MediaQuery.of(context).devicePixelRatio;
                final cacheWidth = (mediaSize.width * pixelRatio * 2)
                    .round()
                    .clamp(1, 2500);

                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      cacheWidth: cacheWidth,
                      filterQuality: FilterQuality.low,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 42,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.imageUrls.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Text(
                '${_index + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}
