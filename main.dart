import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const ValiControlApp());
}

class ValiControlApp extends StatelessWidget {
  const ValiControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1565C0);
    return MaterialApp(
      title: 'ValiControl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFE7EBF0)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const HomeShell(),
    );
  }
}

class Product {
  Product({
    required this.name,
    required this.brand,
    required this.quantity,
    required this.expiration,
  });

  final String name;
  final String brand;
  final int quantity;
  final DateTime expiration;

  Map<String, dynamic> toJson() => {
    'name': name, 'brand': brand, 'quantity': quantity, 'expiration': expiration.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    name: json['name'] as String,
    brand: (json['brand'] as String?) ?? 'Sem marca',
    quantity: (json['quantity'] as num).toInt(),
    expiration: DateTime.parse(json['expiration'] as String),
  );

  int get daysLeft {
    final today = DateTime.now();
    final startToday = DateTime(today.year, today.month, today.day);
    final expiryDay = DateTime(expiration.year, expiration.month, expiration.day);
    return expiryDay.difference(startToday).inDays;
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  bool _ready = false;
  final List<Product> _products = [
    Product(name: 'Leite integral', brand: 'Italac', quantity: 24,
        expiration: DateTime.now().add(const Duration(days: 12))),
    Product(name: 'Iogurte natural', brand: 'Nestlé', quantity: 10,
        expiration: DateTime.now().add(const Duration(days: 3))),
    Product(name: 'Biscoito cream cracker', brand: 'Marilan', quantity: 18,
        expiration: DateTime.now().subtract(const Duration(days: 2))),
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('valicontrol_products_v1');
    if (saved != null) {
      try {
        final decoded = jsonDecode(saved) as List<dynamic>;
        _products
          ..clear()
          ..addAll(decoded.map((item) => Product.fromJson(Map<String, dynamic>.from(item as Map))));
      } catch (_) {
        // Se os dados antigos estiverem inválidos, preserva a lista inicial de demonstração.
      }
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('valicontrol_products_v1', jsonEncode(_products.map((p) => p.toJson()).toList()));
  }

  void _addProduct(Product product) {
    setState(() {
      _products.add(product);
      _selectedIndex = 1;
    });
    _saveProducts();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(products: _products, onAdd: () => _openForm()),
      ProductsPage(products: _products, onAdd: _openForm),
      const SimplePage(icon: Icons.qr_code_scanner, title: 'ValiScan',
          subtitle: 'O leitor de código de barras será conectado nesta etapa.'),
      ProductsPage(products: _products, onAdd: _openForm, alertsOnly: true),
      const SimplePage(icon: Icons.person_outline, title: 'Meu perfil',
          subtitle: 'Configurações da conta serão adicionadas em uma próxima etapa.'),
    ];

    return Scaffold(
      body: SafeArea(child: _ready ? pages[_selectedIndex] : const Center(child: CircularProgressIndicator())),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Produtos'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alertas'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Future<void> _openForm() async {
    final product = await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (_) => const ProductFormPage()),
    );
    if (product != null) _addProduct(product);
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.products, required this.onAdd});
  final List<Product> products;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final expired = products.where((p) => p.daysLeft < 0).length;
    final attention = products.where((p) => p.daysLeft >= 0 && p.daysLeft <= 7).length;
    final okay = products.length - expired - attention;
    final money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: const Color(0xFFE3EEFF), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.shield_outlined, color: Color(0xFF1565C0), size: 29),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ValiControl', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text('Controle de validade e estoque', style: TextStyle(color: Colors.black54)),
          ])),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        ]),
        const SizedBox(height: 26),
        const Text('Olá! 👋', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Aqui está o resumo do seu estoque.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.55,
          children: [
            StatCard(title: 'Produtos', value: '${products.length}', icon: Icons.inventory_2_outlined, color: const Color(0xFF1565C0)),
            StatCard(title: 'Em dia', value: '$okay', icon: Icons.check_circle_outline, color: const Color(0xFF2E7D32)),
            StatCard(title: 'Atenção', value: '$attention', icon: Icons.warning_amber_rounded, color: const Color(0xFFEF8C00)),
            StatCard(title: 'Vencidos', value: '$expired', icon: Icons.error_outline, color: const Color(0xFFD32F2F)),
          ],
        ),
        const SizedBox(height: 16),
        Card(child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFFFF0D9), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.savings_outlined, color: Color(0xFFB96A00))),
            const SizedBox(width: 14),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Valor em risco', style: TextStyle(color: Colors.black54)),
              SizedBox(height: 4),
              Text('A calcular', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text('Adicionaremos custo e valor por produto.', style: TextStyle(fontSize: 12, color: Colors.black54)),
            ])),
          ]),
        )),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onAdd, icon: const Icon(Icons.add_box_outlined),
          label: const Text('Adicionar produto'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O scanner será implementado na próxima etapa.'))),
          icon: const Icon(Icons.qr_code_scanner), label: const Text('Escanear produto'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
        ),
        const SizedBox(height: 24),
        const Text('Produtos que precisam de atenção', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ...products.where((p) => p.daysLeft <= 7).take(3).map((p) => ProductTile(product: p)),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.title, required this.value, required this.icon, required this.color});
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(child: Padding(
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Icon(icon, color: color, size: 23),
      Text(value, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
      Text(title, style: const TextStyle(color: Colors.black54)),
    ]),
  ));
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, required this.products, required this.onAdd, this.alertsOnly = false});
  final List<Product> products;
  final VoidCallback onAdd;
  final bool alertsOnly;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) {
      final matches = '${p.name} ${p.brand}'.toLowerCase().contains(query.toLowerCase());
      return matches && (!widget.alertsOnly || p.daysLeft <= 7);
    }).toList()..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text(widget.alertsOnly ? 'Alertas' : 'Produtos', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
      const SizedBox(height: 5),
      Text(widget.alertsOnly ? 'Itens vencidos ou próximos do vencimento.' : 'Pesquise e acompanhe seus produtos.', style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 18),
      TextField(
        onChanged: (value) => setState(() => query = value),
        decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar por nome ou marca'),
      ),
      const SizedBox(height: 12),
      if (!widget.alertsOnly) Align(alignment: Alignment.centerRight, child: FilledButton.icon(onPressed: widget.onAdd, icon: const Icon(Icons.add), label: const Text('Novo produto'))),
      const SizedBox(height: 8),
      if (filtered.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Nenhum produto encontrado.')),
      ...filtered.map((p) => ProductTile(product: p)),
    ]);
  }
}

class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(product.expiration);
    final Color color = product.daysLeft < 0 ? const Color(0xFFD32F2F) : product.daysLeft <= 7 ? const Color(0xFFEF8C00) : const Color(0xFF2E7D32);
    final String status = product.daysLeft < 0 ? 'Vencido há ${product.daysLeft.abs()} dia(s)' : product.daysLeft == 0 ? 'Vence hoje' : 'Vence em ${product.daysLeft} dia(s)';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(Icons.inventory_2_outlined, color: color)),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${product.brand} • Qtd: ${product.quantity}\nValidade: $date'),
        isThreeLine: true,
        trailing: SizedBox(width: 92, child: Text(status, textAlign: TextAlign.end, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700))),
      ),
    );
  }
}

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  DateTime? _expiration;

  @override
  void dispose() {
    _name.dispose(); _brand.dispose(); _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Novo produto')),
    body: Form(
      key: _formKey,
      child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Informações do produto', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nome do produto'), validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome.' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _brand, decoration: const InputDecoration(labelText: 'Marca')),
        const SizedBox(height: 12),
        TextFormField(controller: _quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade'), validator: (v) => int.tryParse(v ?? '') == null || int.parse(v!) < 1 ? 'Informe uma quantidade válida.' : null),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final selected = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 30)), firstDate: DateTime(2020), lastDate: DateTime(2100), helpText: 'Selecione a validade');
            if (selected != null) setState(() => _expiration = selected);
          },
          icon: const Icon(Icons.calendar_month),
          label: Text(_expiration == null ? 'Selecionar validade' : DateFormat('dd/MM/yyyy').format(_expiration!)),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (_expiration == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione a data de validade.')));
              return;
            }
            Navigator.of(context).pop(Product(
              name: _name.text.trim(),
              brand: _brand.text.trim().isEmpty ? 'Sem marca' : _brand.text.trim(),
              quantity: int.parse(_quantity.text),
              expiration: _expiration!,
            ));
          },
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('Salvar produto'),
        ),
      ]),
    ),
  );
}

class SimplePage extends StatelessWidget {
  const SimplePage({super.key, required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
      ]),
    ),
  );
}
