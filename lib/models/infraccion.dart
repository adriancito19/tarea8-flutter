import 'package:uuid/uuid.dart';

class Infraccion {
  final String id;
  final String marbeteId;
  final String placa;
  final String tipoInfraccion;
  final DateTime fechaHora;
  final String descripcion;
  final List<String> imagePaths; // Nueva propiedad para almacenar rutas de imágenes
  
  Infraccion({
    String? id,
    required this.marbeteId,
    required this.placa,
    required this.tipoInfraccion,
    required this.fechaHora,
    required this.descripcion,
    this.imagePaths = const [], // Valor predeterminado: lista vacía
  }) : id = id ?? const Uuid().v4();

  // Convertir a Map para almacenamiento
  Map toMap() {
    return {
      'id': id,
      'marbeteId': marbeteId,
      'placa': placa,
      'tipoInfraccion': tipoInfraccion,
      'fechaHora': fechaHora.toIso8601String(),
      'descripcion': descripcion,
      'imagePaths': imagePaths, // Guardar las rutas de las imágenes
    };
  }

  // Crear desde Map (para recuperar del almacenamiento)
  factory Infraccion.fromMap(Map map) {
    return Infraccion(
      id: map['id'],
      marbeteId: map['marbeteId'],
      placa: map['placa'],
      tipoInfraccion: map['tipoInfraccion'],
      fechaHora: DateTime.parse(map['fechaHora']),
      descripcion: map['descripcion'],
      imagePaths: map['imagePaths'] != null 
        ? List<String>.from(map['imagePaths']) 
        : [], // Convertir a List<String>
    );
  }
}