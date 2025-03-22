import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;
import '../models/infraccion.dart';
import '../services/storage_service.dart';

class InfraccionFormWidget extends StatefulWidget {
  final String marbeteId;
  final String placa;
  
  const InfraccionFormWidget({
    super.key, 
    required this.marbeteId,
    required this.placa,
  });

  @override
  State<InfraccionFormWidget> createState() => _InfraccionFormWidgetState();
}

class _InfraccionFormWidgetState extends State<InfraccionFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Lista de tipos de infracciones disponibles
  final List<String> _tiposInfraccion = [
    'Exceso de velocidad',
    'Estacionamiento prohibido',
    'Luz roja',
    'No usar cinturón de seguridad',
    'Uso de teléfono al conducir',
    'Conducir bajo influencia de alcohol',
    'Documentos vencidos',
    'Otro',
  ];
  
  // Variables para almacenar los datos del formulario
  String _tipoInfraccionSeleccionado = 'Exceso de velocidad';
  DateTime _fechaHora = DateTime.now();
  final TextEditingController _descripcionController = TextEditingController();
  bool _isSaving = false;
  List<File> _selectedImages = []; // Lista para almacenar las imágenes seleccionadas
  
  // Para seleccionar fecha y hora
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _fechaHora,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    
    if (pickedDate != null) {
      // ignore: use_build_context_synchronously
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_fechaHora),
      );
      
      if (pickedTime != null) {
        setState(() {
          _fechaHora = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  // Formatear fecha y hora para mostrar
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  // Método para tomar una foto con la cámara
  Future<void> _takePicture() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, // Reducir calidad para optimizar almacenamiento
    );
    
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }
  
  // Método para seleccionar imágenes de la galería
  Future<void> _pickImages() async {
    final List<XFile> images = await _imagePicker.pickMultiImage(
      imageQuality: 80,
    );
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)).toList());
      });
    }
  }
  
  // Método para eliminar una imagen seleccionada
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
  
  // Método para guardar las imágenes en el almacenamiento local
  Future<List<String>> _saveImages() async {
    final List<String> savedPaths = [];
    
    if (_selectedImages.isEmpty) {
      return savedPaths;
    }
    
    
    final appDir = await path_provider.getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/infraccion_images');
    
    // Crear directorio si no existe
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    // Guardar cada imagen con un nombre único
    for (var image in _selectedImages) {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      final savedImage = await image.copy('${imagesDir.path}/$fileName');
      savedPaths.add(savedImage.path);
    }
    
    return savedPaths;
  }
  
  // Guardar la infracción
  Future<void> _guardarInfraccion() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      
      try {
        // Guardar imágenes primero
        final List<String> imagePaths = await _saveImages();
        
        // Crear objeto Infraccion
        final infraccion = Infraccion(
          marbeteId: widget.marbeteId,
          placa: widget.placa,
          tipoInfraccion: _tipoInfraccionSeleccionado,
          fechaHora: _fechaHora,
          descripcion: _descripcionController.text,
          imagePaths: imagePaths, // Añadir rutas de imágenes
        );
        
        // Guardar en almacenamiento local
        await _storageService.saveInfraccion(infraccion);
        
        // Mostrar confirmación
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Infracción registrada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Cerrar el formulario
        // ignore: use_build_context_synchronously
        Navigator.pop(context, true); // Retornar true para indicar que se guardó
      } catch (e) {
        // Mostrar error
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Infracción'),
        backgroundColor: const Color(0xFFADD8E6),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información del vehículo
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Marbete: ${widget.marbeteId}'),
                          Text('Placa: ${widget.placa}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Tipo de infracción
              const Text(
                '📜 Tipo de infracción',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _tipoInfraccionSeleccionado,
                    items: _tiposInfraccion.map((String tipo) {
                      return DropdownMenuItem<String>(
                        value: tipo,
                        child: Text(tipo),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _tipoInfraccionSeleccionado = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Fecha y hora
              const Text(
                '🕒 Fecha y hora',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDateTime(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDateTime(_fechaHora)),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Descripción de la multa
              const Text(
                '🖊️ Descripción de la multa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  hintText: 'Ingrese detalles de la infracción',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Sección de imágenes
              const Text(
                '📷 Fotos del vehículo o infracción',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              // Mostrar imágenes seleccionadas
              if (_selectedImages.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Imágenes seleccionadas:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(_selectedImages[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  top: 0,
                                  child: InkWell(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Botones para capturar o seleccionar imágenes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePicture,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Tomar foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galería'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _guardarInfraccion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving 
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.0,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('GUARDANDO...', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    : const Text(
                        'GUARDAR INFRACCIÓN',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}