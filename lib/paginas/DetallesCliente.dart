import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/model/Facturas.dart';
import 'package:xeler_impresora/paginas/CrearFactura.dart';
import 'package:xeler_impresora/paginas/CrearFacturaBlanco.dart';
import 'package:xeler_impresora/paginas/testprint.dart';

class DetallesCliente extends StatefulWidget {
  const DetallesCliente({super.key, required this.id, required this.name});

  final int id;
  final String name;

  @override
  State<DetallesCliente> createState() => _DetallesClienteState();
}

class _DetallesClienteState extends State<DetallesCliente> {
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  final TestPrint testPrint = TestPrint();
  final NumberFormat formato = NumberFormat('#,###');

  final List<Facturas> _ultimos = [];
  String? pathImage;
  String pathImage2 = '';
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    initSavetoPath();
    initSavetoPath2();
    initPlatformState();
    _getUserInfo();
    _loadFacturas();
  }

  Future<void> _loadFacturas() async {
    try {
      final response = await CallApi().getData('obtenerFacturasCliente2/${widget.id}');
      if (response.statusCode == 200) {
        final List<dynamic> notesJson = jsonDecode(response.body) as List<dynamic>;
        final facturas = notesJson
            .map((noteJson) => Facturas.fromJson(noteJson as Map<String, dynamic>))
            .toList();
        if (!mounted) return;
        setState(() {
          _ultimos
            ..clear()
            ..addAll(facturas);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ultimos.clear();
      });
    }
  }

  Future<void> _getUserInfo() async {
    final localStorage = await SharedPreferences.getInstance();
    final userJson = localStorage.getString('user');
    if (!mounted) return;
    setState(() {
      userData = userJson != null
          ? jsonDecode(userJson) as Map<String, dynamic>
          : null;
    });
  }

  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return File(path).writeAsBytes(
      buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  Future<void> initPlatformState() async {
    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
        case BlueThermalPrinter.DISCONNECTED:
        default:
          break;
      }
    });

    if (!mounted) return;
  }

  Future<void> initSavetoPath() async {
    const filename = '192xeler.png';
    final bytes = await rootBundle.load('assets/images/192xeler.png');
    final dir = (await getApplicationDocumentsDirectory()).path;
    final fullPath = '$dir/$filename';
    await writeToFile(bytes, fullPath);
    if (mounted) {
      setState(() {
        pathImage = fullPath;
      });
    }
  }

  Future<void> initSavetoPath2() async {
    const filename = '192blanco.png';
    final bytes = await rootBundle.load('assets/images/192blanco.png');
    final dir = (await getApplicationDocumentsDirectory()).path;
    final fullPath = '$dir/$filename';
    await writeToFile(bytes, fullPath);
    if (mounted) {
      setState(() {
        pathImage2 = fullPath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/512xeler.png',
              fit: BoxFit.contain,
              height: 32,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 0.0, left: 0.0, right: 0.0),
          child: Column(
            children: <Widget>[
              ProfileHeader(
                title: widget.name,
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.print, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CrearFacturaBlancoPage(
                            id: widget.id,
                            name: widget.name,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      await _loadFacturas();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.print, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                    ),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CrearFacturaPage(
                            id: widget.id,
                            name: widget.name,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      await _loadFacturas();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              Container(
                width: double.infinity,
                height: 690,
                margin: const EdgeInsets.only(top: 15),
                child: Column(
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(top: 0.0, left: 20),
                          child: Text(
                            'Últimas 5 Facturas',
                            style: TextStyle(fontSize: 18.0),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: _ultimos.isNotEmpty
                          ? ListView.builder(
                              itemBuilder: (context, index) {
                                final factura = _ultimos[index];
                                final bool esBlanco = factura.tipo == 'blanco';

                                return Card(
                                  elevation: 8.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: esBlanco
                                          ? Colors.green // FACTURA EN BLANCO
                                          : const Color.fromARGB(255, 36, 38, 80),
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20.0,
                                        vertical: 10.0,
                                      ),
                                      title: Text(
                                        'Valor: ${factura.currency} ${formato.format(int.parse(factura.valor))}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Row(
                                        children: <Widget>[
                                          Expanded(
                                            flex: 4,
                                            child: Padding(
                                              padding: const EdgeInsets.only(left: 4.0),
                                              child: Text(
                                                esBlanco
                                                    ? 'Descripción: ${factura.descripcion ?? ''}'
                                                    : 'Wallet destino: ${factura.primeros} / ${factura.ultimos}',
                                                style: const TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      onTap: () async {
                                        final direccion =
                                            userData?['direccion']?.toString() ??
                                                userData?['address']?.toString();
                                        final imagePath = pathImage;
                                        final imagePath2 = pathImage2;

                                        if (direccion == null || imagePath == null) return;

                                        if (factura.tipo == 'blanco') {
                                          // FACTURA EN BLANCO → sample3
                                          await testPrint.sample3(
                                            imagePath2,
                                            direccion,
                                            factura.id.toString(),
                                          );
                                        } else {
                                          // FACTURA NORMAL → sample2
                                          await testPrint.sample2(
                                            imagePath,
                                            direccion,
                                            factura.id.toString(),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                              itemCount: _ultimos.length,
                            )
                          : Center(
                              child: Text(
                                'El cliente ${widget.name} no tiene facturas',
                                style: const TextStyle(fontSize: 18.0),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, required this.title, this.subtitle, this.actions});

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Ink(
          height: 80,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 36, 38, 80),
          ),
        ),
        Container(
          width: double.infinity,
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              if (actions != null && actions!.isNotEmpty)
                actions![0]
              else
                const SizedBox(width: 48),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ),
              if (actions != null && actions!.length > 1)
                actions![1]
              else
                const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }
}
