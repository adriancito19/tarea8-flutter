import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/infraccion.dart';
import '../models/agente.dart';

class StorageService {
  static const String _infraccionesKey = 'infracciones';
  static const String _agenteKey = 'agente';

  // Obtener todas las infracciones
  Future<List<Infraccion>> getInfracciones() async {
    final prefs = await SharedPreferences.getInstance();
    final infraccionesJson = prefs.getStringList(_infraccionesKey) ?? [];
    
    return infraccionesJson
        .map((json) => Infraccion.fromMap(
            Map<String, dynamic>.from(jsonDecode(json))))
        .toList();
  }

  // Guardar una infracción
  Future<void> saveInfraccion(Infraccion infraccion) async {
    final prefs = await SharedPreferences.getInstance();
    final infracciones = await getInfracciones();
    
    infracciones.add(infraccion);
    
    await prefs.setStringList(
      _infraccionesKey,
      infracciones.map((i) => jsonEncode(i.toMap())).toList(),
    );
  }

  // Eliminar una infracción
  Future<void> deleteInfraccion(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final infracciones = await getInfracciones();
    
    infracciones.removeWhere((i) => i.id == id);
    
    await prefs.setStringList(
      _infraccionesKey,
      infracciones.map((i) => jsonEncode(i.toMap())).toList(),
    );
  }
  // Eliminar todas las infracciones
Future<void> deleteAllInfracciones() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_infraccionesKey, []);
}

  // Guardar imagen del agente
  Future<String> saveAgenteImage(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'agente_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await imageFile.copy('${directory.path}/$fileName');
    return savedImage.path;
  }

  // Guardar datos del agente
  Future<void> saveAgente(Agente agente) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_agenteKey, agente.toJson());
  }

  // Obtener datos del agente
  Future<Agente?> getAgente() async {
    final prefs = await SharedPreferences.getInstance();
    final agenteJson = prefs.getString(_agenteKey);
    
    if (agenteJson == null) {
      return null;
    }
    
    return Agente.fromJson(agenteJson);
  }
}