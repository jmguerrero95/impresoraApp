import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xeler_impresora/api/api.dart';
import 'package:xeler_impresora/paginas/testprint.dart';

class CrearFacturaPage extends StatefulWidget {
  const CrearFacturaPage({super.key, required this.id, required this.name});

  final int id;
  final String name;

  @override
  State<CrearFacturaPage> createState() => _CrearFacturaState();
}

class _CrearFacturaState extends State<CrearFacturaPage> {
  static final RegExp _walletPattern = RegExp(r'^[a-zA-Z0-9]+$');

  final MoneyMaskedTextController controller = MoneyMaskedTextController(
    precision: 0,
    decimalSeparator: '',
    thousandSeparator: '.',
  );
  final TextEditingController primerosController = TextEditingController();
  final TextEditingController ultimosController = TextEditingController();
  final TestPrint testPrint = TestPrint();

  bool _isLoading = false;
  bool _showWalletErrors = false;
  Map<String, dynamic>? userData;
  String? pathImage;
  String _mySelection = 'COP';

  String? _walletError(String value, String fieldName) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return 'Ingresa $fieldName del wallet';
    }
    if (value != trimmedValue || !_walletPattern.hasMatch(trimmedValue)) {
      return 'Usa solo letras y numeros';
    }
    return null;
  }

  void _showSoftMessage(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          backgroundColor: const Color.fromARGB(255, 45, 57, 78),
        ),
      );
  }

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    initSavetoPath();
  }

  @override
  void dispose() {
    controller.dispose();
    primerosController.dispose();
    ultimosController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Material(
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppBar(
                centerTitle: true,
                title: const Text('Crear Factura'),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    DropdownButton<String>(
                      value: _mySelection,
                      underline: Container(
                        height: 1.0,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Colors.transparent, width: 1.0),
                          ),
                        ),
                      ),
                      items: const ['COP', 'USD', 'EUR']
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: SizedBox(
                                width: 70.0,
                                child: Text(value, textAlign: TextAlign.center),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (newVal) {
                        if (newVal != null) {
                          setState(() {
                            _mySelection = newVal;
                          });
                        }
                      },
                    ),
                    Flexible(
                      child: TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Valor',
                          hintText: 'Ingresa el valor',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: TextField(
                        controller: primerosController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Inicio wallet',
                          hintText: 'Escribe el inicio del wallet',
                          icon: Icon(Icons.monetization_on),
                          isDense: true,
                          contentPadding: EdgeInsets.all(10),
                        ).copyWith(
                          errorText: _showWalletErrors
                              ? _walletError(
                                  primerosController.text, 'el inicio')
                              : null,
                        ),
                        keyboardType: TextInputType.visiblePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization: TextCapitalization.none,
                        onChanged: (_) {
                          if (_showWalletErrors) {
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: TextField(
                        controller: ultimosController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Fin wallet',
                          hintText: 'Escribe el fin del wallet',
                          icon: Icon(Icons.monetization_on),
                          isDense: true,
                          contentPadding: EdgeInsets.all(10),
                        ).copyWith(
                          errorText: _showWalletErrors
                              ? _walletError(ultimosController.text, 'el fin')
                              : null,
                        ),
                        keyboardType: TextInputType.visiblePassword,
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization: TextCapitalization.none,
                        onChanged: (_) {
                          if (_showWalletErrors) {
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: double.infinity),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 118, 104, 254),
                      padding: const EdgeInsets.all(22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _isLoading ? null : _crearFactura,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : const Text(
                            'Crear',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDialog(String msg) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(msg),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _crearFactura() async {
    final walletInicioRaw = primerosController.text;
    final walletFinRaw = ultimosController.text;
    final walletInicio = walletInicioRaw.trim();
    final walletFin = walletFinRaw.trim();
    final walletInicioError = _walletError(walletInicioRaw, 'el inicio');
    final walletFinError = _walletError(walletFinRaw, 'el fin');

    if (walletInicioError != null || walletFinError != null) {
      setState(() {
        _showWalletErrors = true;
      });
      _showSoftMessage(
        walletInicio.isEmpty || walletFin.isEmpty
            ? 'Ingresa inicio y fin del wallet para continuar.'
            : 'El wallet solo puede contener letras y numeros.',
      );
      return;
    }

    if (_showWalletErrors) {
      setState(() {
        _showWalletErrors = false;
      });
    }

    setState(() {
      _isLoading = true;
    });

    final data = {
      'valor': controller.numberValue.toInt().toString(),
      'wallet_inicio': walletInicio,
      'wallet_fin': walletFin,
      'cliente_id': widget.id,
      'currency': _mySelection,
    };

    try {
      final res = await CallApi().postData(data, 'crearFactura');
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final facturaId = body['factura_id']?.toString();
        final direccion = userData?['direccion']?.toString() ??
            userData?['address']?.toString();
        final imagePath = pathImage;
        if (facturaId != null && direccion != null && imagePath != null) {
          await testPrint.sample2(imagePath, direccion, facturaId);
        }
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      } else {
        await _showDialog(
            body['mensaje']?.toString() ?? 'Error al crear la factura');
      }
    } catch (error) {
      await _showDialog('No se pudo crear la factura: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return File(path).writeAsBytes(
      buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }
}
