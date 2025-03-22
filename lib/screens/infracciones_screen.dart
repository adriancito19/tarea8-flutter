import 'dart:io';
import 'package:flutter/material.dart';
import '../models/infraccion.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';

class InfraccionesScreen extends StatefulWidget {
  const InfraccionesScreen({super.key});

  @override
  State<InfraccionesScreen> createState() => _InfraccionesScreenState();
}

class _InfraccionesScreenState extends State<InfraccionesScreen> {
  final StorageService _storageService = StorageService();
  List<Infraccion> _infracciones = [];
  bool _isLoading = true;
  String _searchQuery = '';
  List<Infraccion> _filteredInfracciones = [];

  @override
  void initState() {
    super.initState();
    _loadInfracciones();
  }

  Future<void> _loadInfracciones() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final infracciones = await _storageService.getInfracciones();
      setState(() {
        _infracciones = infracciones;
        _filteredInfracciones = infracciones;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al cargar infracciones: $e');
    }
  }

  void _filterInfracciones(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredInfracciones = _infracciones;
      } else {
        _filteredInfracciones = _infracciones.where((infraccion) {
          return infraccion.tipoInfraccion
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              infraccion.placa.toLowerCase().contains(query.toLowerCase()) ||
              infraccion.marbeteId
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              infraccion.descripcion
                  .toLowerCase()
                  .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _deleteInfraccion(String id) async {
    final bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text(
                '¿Estás seguro de que deseas eliminar esta infracción?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmDelete) return;

    try {
      await _storageService.deleteInfraccion(id);
      await _loadInfracciones();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Infracción eliminada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error al eliminar infracción: $e');
    }
  }

  Future<void> _deleteAllInfracciones() async {
    final bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar eliminación masiva'),
            content: const Text(
                '¿Estás seguro de que deseas eliminar TODAS las infracciones? Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                child: const Text('ELIMINAR TODO'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmDelete) return;

    try {
      setState(() {
        _isLoading = true;
      });

      await _storageService.deleteAllInfracciones();

      setState(() {
        _infracciones = [];
        _filteredInfracciones = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas las infracciones han sido eliminadas'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al eliminar infracciones: $e');
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }

  // Método para ver imágenes en tamaño grande
  void _viewImages(List<String> imagePaths) {
    if (imagePaths.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Galería de imágenes'),
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
          ),
          body: PageView.builder(
            itemCount: imagePaths.length,
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.file(
                    File(imagePaths[index]),
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _viewInfraccionDetails(Infraccion infraccion) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 60,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.only(bottom: 20),
                      ),
                    ),
                    Text(
                      infraccion.tipoInfraccion,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailCard(
                      title: 'Información del Vehículo',
                      content: [
                        _buildDetailRow(Icons.confirmation_number, 'Marbete',
                            infraccion.marbeteId),
                        _buildDetailRow(Icons.pin, 'Placa', infraccion.placa),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailCard(
                      title: 'Detalles de la Infracción',
                      content: [
                        _buildDetailRow(Icons.calendar_today, 'Fecha y hora',
                            _formatDateTime(infraccion.fechaHora)),
                        const SizedBox(height: 12),
                        const Text(
                          'Descripción:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          infraccion.descripcion,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    // Sección de imágenes
                    if (infraccion.imagePaths.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        title: 'Evidencia Fotográfica',
                        content: [
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: infraccion.imagePaths.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () =>
                                      _viewImages(infraccion.imagePaths),
                                  child: Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(
                                            File(infraccion.imagePaths[index])),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton.icon(
                              onPressed: () =>
                                  _viewImages(infraccion.imagePaths),
                              icon: const Icon(Icons.zoom_in),
                              label: Text(
                                  'Ver ${infraccion.imagePaths.length} ${infraccion.imagePaths.length == 1 ? 'imagen' : 'imágenes'}'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Volver'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteInfraccion(infraccion.id);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Eliminar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ));
        },
      ),
    );
  }

  Widget _buildDetailCard(
      {required String title, required List<Widget> content}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(height: 24),
            ...content,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Infracciones'),
        backgroundColor: const Color(0xFFADD8E6),
        actions: [
          if (_infracciones.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Eliminar todas las infracciones',
              onPressed: _deleteAllInfracciones,
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por tipo, placa o marbete...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _filterInfracciones,
            ),
          ),

          // Lista de infracciones
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInfracciones.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isEmpty
                                  ? Icons.check_circle_outline
                                  : Icons.search_off,
                              size: 80,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No hay infracciones registradas'
                                  : 'No se encontraron resultados para "$_searchQuery"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _filteredInfracciones.length,
                        itemBuilder: (context, index) {
                          final infraccion = _filteredInfracciones[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: InkWell(
                              onTap: () => _viewInfraccionDetails(infraccion),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            infraccion.tipoInfraccion,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () =>
                                              _deleteInfraccion(infraccion.id),
                                          tooltip: 'Eliminar infracción',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 16, color: Colors.blue),
                                        const SizedBox(width: 6),
                                        Text(_formatDateTime(
                                            infraccion.fechaHora)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(
                                                  Icons.confirmation_number,
                                                  size: 16,
                                                  color: Colors.blue),
                                              const SizedBox(width: 6),
                                              Text(
                                                  'Marbete: ${infraccion.marbeteId}'),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Row(
                                            children: [
                                              const Icon(Icons.pin,
                                                  size: 16, color: Colors.blue),
                                              const SizedBox(width: 6),
                                              Text(
                                                  'Placa: ${infraccion.placa}'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      infraccion.descripcion.length > 100
                                          ? '${infraccion.descripcion.substring(0, 100)}...'
                                          : infraccion.descripcion,
                                      style: TextStyle(
                                          color: Colors.grey.shade700),
                                    ),

                                    // Miniaturas de imágenes si existen
                                    if (infraccion.imagePaths.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.photo_library,
                                              size: 16, color: Colors.blue),
                                          const SizedBox(width: 6),
                                          Text(
                                              '${infraccion.imagePaths.length} ${infraccion.imagePaths.length == 1 ? 'imagen' : 'imágenes'}'),
                                          const Spacer(),
                                          TextButton(
                                            onPressed: () => _viewImages(
                                                infraccion.imagePaths),
                                            child: const Text('Ver'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
