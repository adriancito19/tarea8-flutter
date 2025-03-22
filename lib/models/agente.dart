// models/agente.dart
import 'dart:convert';

class Agente {
  final String nombre;
  final String apellido;
  final String matricula;
  final String frase;
  final String? fotoPath; // Ruta a la imagen guardada localmente

  Agente({
    required this.nombre,
    required this.apellido,
    required this.matricula,
    required this.frase,
    this.fotoPath,
  });

  // Convertir a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'matricula': matricula,
      'frase': frase,
      'fotoPath': fotoPath,
    };
  }

  // Crear desde Map (para recuperar del almacenamiento)
  factory Agente.fromMap(Map<String, dynamic> map) {
    return Agente(
      nombre: map['nombre'],
      apellido: map['apellido'],
      matricula: map['matricula'],
      frase: map['frase'],
      fotoPath: map['fotoPath'],
    );
  }

  // Serializar a JSON
  String toJson() => json.encode(toMap());

  // Deserializar desde JSON
  factory Agente.fromJson(String source) => Agente.fromMap(json.decode(source));
}