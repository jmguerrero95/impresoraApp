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

class CrearFacturaBlancoPage extends StatefulWidget {
  const CrearFacturaBlancoPage({super.key, required this.id, required this.name});

  final int id;
  final String name;

  @override
  State<CrearFacturaBlancoPage> createState() => _CrearFacturaState();
}

class _CrearFacturaState extends State<CrearFacturaBlancoPage> {
  final MoneyMaskedTextController controller = MoneyMaskedTextController(
    precision: 0,
    decimalSeparator: '',
    thousandSeparator: '.',
  );
  final TextEditingController descripcionController = TextEditingController();
  final TestPrint testPrint = TestPrint();

  bool _isLoading = false;
  Map<String, dynamic>? userData;
  String? pathImage;
  String _mySelection = 'COP';

  @override
  void initState() {
    super.initState();
    _getUserInfo();
    initSavetoPath();
  }

  @override
  void dispose() {
    controller.dispose();
    descripcionController.dispose();
    super.dispose();
  }

  Future<void> initSavetoPath() async {
    const filename = '192blanco.png';
    final bytes = await rootBundle.load('assets/images/192blanco.png');
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
                            bottom: BorderSide(color: Colors.transparent, width: 1.0),
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
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextField(
                  controller: descripcionController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Descripción',
                    hintText: 'Escribe una descripción',
                    icon: Icon(Icons.description),
                  ),
                ),
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
    setState(() {
      _isLoading = true;
    });

    final data = {
      'valor': controller.numberValue.toInt().toString(),
      'descripcion': descripcionController.text,
      'cliente_id': widget.id,
      'currency': _mySelection,
    };


    try {
      final res = await CallApi().postData(data, 'crearFacturaBlanco');
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final facturaId = body['factura_id']?.toString();
        final direccion = userData?['direccion']?.toString() ??
            userData?['address']?.toString();
        final imagePath = pathImage;
        if (facturaId != null && direccion != null && imagePath != null) {
          await testPrint.sample3(imagePath, direccion, facturaId);
        }
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      } else {
        await _showDialog(body['mensaje']?.toString() ?? 'Error al crear la factura');
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
