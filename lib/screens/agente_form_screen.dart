// screens/agente_form_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/agente.dart';
import '../services/storage_service.dart';

class AgenteFormScreen extends StatefulWidget {
  final Agente? agente;

  const AgenteFormScreen({Key? key, this.agente}) : super(key: key);

  @override
  State<AgenteFormScreen> createState() => _AgenteFormScreenState();
}

class _AgenteFormScreenState extends State<AgenteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storageService = StorageService();
  
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _matriculaController = TextEditingController();
  final TextEditingController _fraseController = TextEditingController();
  
  File? _profileImage;
  String? _currentPhotoPath;
  bool _isSaving = false;
  
  @override
  void initState() {
    super.initState();
    
    // Si estamos editando, cargamos los datos del agente
    if (widget.agente != null) {
      _nombreController.text = widget.agente!.nombre;
      _apellidoController.text = widget.agente!.apellido;
      _matriculaController.text = widget.agente!.matricula;
      _fraseController.text = widget.agente!.frase;
      _currentPhotoPath = widget.agente!.fotoPath;
    }
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _saveAgente() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      
      try {
        String? photoPath = _currentPhotoPath;
        
        // Si hay una nueva imagen, la guardamos
        if (_profileImage != null) {
          photoPath = await _storageService.saveAgenteImage(_profileImage!);
        }
        
        // Crear objeto Agente
        final agente = Agente(
          nombre: _nombreController.text,
          apellido: _apellidoController.text,
          matricula: _matriculaController.text,
          frase: _fraseController.text,
          fotoPath: photoPath,
        );
        
        // Guardar en almacenamiento local
        await _storageService.saveAgente(agente);
        
        // Mostrar confirmación
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil de agente guardado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Cerrar el formulario
        // ignore: use_build_context_synchronously
        Navigator.pop(context, true);
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
    _nombreController.dispose();
    _apellidoController.dispose();
    _matriculaController.dispose();
    _fraseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.agente == null ? 'Crear Perfil de Agente' : 'Editar Perfil de Agente'),
        backgroundColor: const Color(0xFFADD8E6),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Foto de perfil
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.photo_camera),
                            title: const Text('Tomar foto'),
                            onTap: () {
                              Navigator.pop(context);
                              _takePicture();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Elegir de la galería'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                    image: _profileImage != null
                        ? DecorationImage(
                            image: FileImage(_profileImage!),
                            fit: BoxFit.cover,
                          )
                        : _currentPhotoPath != null
                            ? DecorationImage(
                                image: FileImage(File(_currentPhotoPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: (_profileImage == null && _currentPhotoPath == null)
                      ? const Icon(
                          Icons.person_add,
                          size: 40,
                          color: Colors.grey,
                        )
                      : null,
                ),
              ),
              
              const SizedBox(height: 8),
              const Text(
                'Toca para añadir foto',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su nombre';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Apellido
              TextFormField(
                controller: _apellidoController,
                decoration: InputDecoration(
                  labelText: 'Apellido',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su apellido';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Matrícula
              TextFormField(
                controller: _matriculaController,
                decoration: InputDecoration(
                  labelText: 'Matrícula',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su matrícula';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Frase motivadora
              TextFormField(
                controller: _fraseController,
                decoration: InputDecoration(
                  labelText: 'Frase motivadora sobre seguridad vial',
                  prefixIcon: const Icon(Icons.format_quote),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una frase motivadora';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAgente,
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
                    : Text(
                        widget.agente == null ? 'CREAR PERFIL' : 'GUARDAR CAMBIOS',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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