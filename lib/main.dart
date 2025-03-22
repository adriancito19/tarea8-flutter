// main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:multas_20230608/screens/infracciones_screen.dart';
import 'screens/agente_profile_screen.dart';
import 'dart:convert';
import 'InfraccionFormWidget.dart';

void main() {
  runApp(const MarbeteApp());
}

class MarbeteApp extends StatelessWidget {
  const MarbeteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consulta de Marbetes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFADD8E6), // Fondo azul claro
      ),
      home: const MarbeteScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MarbeteScreen extends StatefulWidget {
  const MarbeteScreen({super.key});

  @override
  State<MarbeteScreen> createState() => _MarbeteScreenState();
}

class _MarbeteScreenState extends State<MarbeteScreen> {
  final TextEditingController _marbeteController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _vehicleData;
  String? _errorMessage;

  // Método para navegar a la pantalla de infracciones
  void _navegarAInfracciones() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InfraccionesScreen(),
      ),
    );
  }
  
  // Método para navegar a la pantalla de perfil del agente
  void _navegarAPerfilAgente() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AgenteProfileScreen(),
      ),
    );
  }

  Future<void> _fetchVehicleData(String marbeteCode) async {
    if (marbeteCode.isEmpty) {
      setState(() {
        _errorMessage = 'Ingrese un código de marbete válido';
        _vehicleData = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.adamix.net/itla.php?m=$marbeteCode'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map<String, dynamic>) {
          if (data.containsKey('error') &&
              data['error'].toString().isNotEmpty) {
            setState(() {
              _errorMessage = data['error'] ?? 'Error desconocido';
              _vehicleData = null;
              _isLoading = false;
            });
          } else if (data.containsKey('ok') && data['ok'] == 1) {
            setState(() {
              _vehicleData = data;
              _isLoading = false;
            });
          } else {
            setState(() {
              _errorMessage = 'Formato de respuesta inesperado';
              _vehicleData = null;
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Formato de respuesta inválido';
            _vehicleData = null;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Error en la conexión: ${response.statusCode}';
          _vehicleData = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _vehicleData = null;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _marbeteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Consulta de Marbetes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor:
            const Color(0xFFADD8E6), // Azul claro para coincidir con la imagen
        elevation: 0,
        actions: [
          // Botón para ver infracciones
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Ver infracciones',
            onPressed: _navegarAInfracciones,
          ),
          // Botón para ver/editar perfil del agente
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Perfil del agente',
            onPressed: _navegarAPerfilAgente,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sección de búsqueda
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            color: const Color(0xFFADD8E6), // Azul claro para el fondo
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Código de Marbete',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _marbeteController,
                    decoration: InputDecoration(
                      hintText: 'Ingrese el código de marbete',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.qr_code),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () =>
                            _fetchVehicleData(_marbeteController.text.trim()),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) => _fetchVehicleData(value.trim()),
                  ),
                ),
              ],
            ),
          ),

          // Contenido principal
          Expanded(
            child: Container(
              color: Colors.white,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ErrorMessage(message: _errorMessage!),
                        )
                      : _vehicleData != null
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child:
                                  VehicleInfoCard(vehicleData: _vehicleData!),
                            )
                          : const Center(
                              child: Text(
                                'Ingrese un código de marbete para consultar',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class VehicleInfoCard extends StatelessWidget {
  final Map<String, dynamic> vehicleData;

  const VehicleInfoCard({super.key, required this.vehicleData});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información del Vehículo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        const SizedBox(height: 8),
        _buildInfoRow(
            icon: Icons.confirmation_number,
            color: Colors.blue,
            label: 'Código',
            value: vehicleData['codigo']?.toString() ?? 'No disponible'),
        _buildInfoRow(
            icon: Icons.credit_card,
            color: Colors.blue,
            label: 'Número de Marbete',
            value: vehicleData['marbete']?.toString() ?? 'No disponible'),
        _buildInfoRow(
            icon: Icons.directions_car,
            color: Colors.blue,
            label: 'Marca',
            value: vehicleData['marca']?.toString() ?? 'No disponible'),
        _buildInfoRow(
            icon: Icons.car_rental,
            color: Colors.blue,
            label: 'Modelo',
            value: vehicleData['modelo']?.toString() ?? 'No disponible'),
        _buildInfoRow(
            icon: Icons.color_lens,
            color: Colors.blue,
            label: 'Color',
            value: vehicleData['color']?.toString() ?? 'No disponible'),
        _buildInfoRow(
            icon: Icons.calendar_today,
            color: Colors.blue,
            label: 'Año',
            value: vehicleData['anio']?.toString() ?? 'No disponible'),
        _buildInfoRow(
            icon: Icons.pin,
            color: Colors.blue,
            label: 'Placa',
            value: vehicleData['placa']?.toString() ?? 'No disponible'),
        _buildInfoRow(
            icon: Icons.credit_card,
            color: Colors.blue,
            label: 'Chasis',
            value: vehicleData['chasis']?.toString() ?? 'No disponible'),
        const SizedBox(height: 24),

        // Botón para registrar infracción
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InfraccionFormWidget(
                    marbeteId: vehicleData['marbete']?.toString() ?? '',
                    placa: vehicleData['placa']?.toString() ?? '',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.report_problem),
            label: const Text('Registrar Infracción'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      {required IconData icon,
      required Color color,
      required String label,
      required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorMessage extends StatelessWidget {
  final String message;

  const ErrorMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}