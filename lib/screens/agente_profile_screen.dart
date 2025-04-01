// screens/agente_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../models/agente.dart';
import '../services/storage_service.dart';
import 'agente_form_screen.dart';

class AgenteProfileScreen extends StatefulWidget {
  const AgenteProfileScreen({super.key});

  @override
  State<AgenteProfileScreen> createState() => _AgenteProfileScreenState();
}

class _AgenteProfileScreenState extends State<AgenteProfileScreen> {
  final StorageService _storageService = StorageService();
  Agente? _agente;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgente();
  }

  Future<void> _loadAgente() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final agente = await _storageService.getAgente();
      setState(() {
        _agente = agente;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error al cargar perfil: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _navigateToForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgenteFormScreen(agente: _agente),
      ),
    );

    if (result == true) {
      _loadAgente();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Agente'),
        backgroundColor: const Color(0xFFADD8E6),
        actions: [
          if (_agente != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToForm,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _agente == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_off,
                        size: 70,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay información de agente',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _navigateToForm,
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Perfil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Información del agente en un Card elegante
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                // Imagen del agente
                                Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blue,
                                      width: 3,
                                    ),
                                    image: _agente!.fotoPath != null
                                        ? DecorationImage(
                                            image: FileImage(File(_agente!.fotoPath!)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: _agente!.fotoPath == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 80,
                                          color: Colors.blue,
                                        )
                                      : null,
                                ),
                                
                                const SizedBox(height: 20),
                                
                                // Nombre y apellido
                                Text(
                                  '${_agente!.nombre} ${_agente!.apellido}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                
                                const SizedBox(height: 8),
                                
                                // Matrícula
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Matrícula: ${_agente!.matricula}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(height: 24),
                                
                                // Frase motivadora
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.format_quote,
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _agente!.frase,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black87,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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