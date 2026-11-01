class Facturas {
  const Facturas({
    required this.id,
    required this.facturaNumber,
    required this.valor,
    required this.creado,
    required this.tipo,
    required this.currency,
    this.primeros,
    this.ultimos,
    this.descripcion,
  });

  final int id;
  final String facturaNumber;
  final String valor;
  final String creado;

  final String tipo; // normal | blanco
  final String currency;

  // SOLO factura normal
  final String? primeros;
  final String? ultimos;

  // SOLO factura en blanco
  final String? descripcion;

  factory Facturas.fromJson(Map<String, dynamic> json) {
    return Facturas(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      facturaNumber: json['factura_id']?.toString() ?? '',
      valor: json['valor']?.toString() ?? '0',
      creado: json['created_at']?.toString() ?? '',

      tipo: json['tipo']?.toString() ?? 'normal',
      currency: json['currency']?.toString() ?? 'COP',

      primeros: json['wallet_inicio']?.toString(),
      ultimos: json['wallet_fin']?.toString(),

      descripcion: json['descripcion']?.toString(),
    );
  }
}
