# 🚀 Setup de Base de Datos Offline - ByteFit

Este documento explica cómo configurar la base de datos offline con **todos los ejercicios pre-traducidos y GIFs incluidos**.

---

## 📋 ¿Qué hace esto?

1. ✅ Descarga **todos los ejercicios** de ExerciseDB (~1500 ejercicios)
2. ✅ **Traduce TODO al español** usando Gemini (nombres, músculos, instrucciones, etc.)
3. ✅ Descarga **todos los GIFs** (~1500 archivos)
4. ✅ Guarda todo en `assets/` para incluir en la app
5. ✅ La app funciona **100% offline** después del setup

---

## ⚡ Pasos para Ejecutar (Solo UNA VEZ)

### **Paso 1: Instalar Dependencias**

```bash
flutter pub get
```

### **Paso 2: Ejecutar el Script de Setup**

```bash
dart run scripts/setup_offline_database.dart
```

**Esto va a:**
- Crear carpetas `assets/data/` y `assets/gifs/`
- Descargar ~1500 ejercicios de ExerciseDB
- Traducir todo al español con Gemini
- Descargar ~1500 GIFs
- Guardar todo localmente

**⏱️ Tiempo estimado:** 30-60 minutos (dependiendo de tu conexión)

### **Paso 3: Verificar los Archivos Generados**

Después de ejecutar el script, deberías tener:

```
ByteFit/
├── assets/
│   ├── data/
│   │   └── exercises_es.json (~1-2 MB)
│   └── gifs/
│       ├── ex001.gif
│       ├── ex002.gif
│       └── ... (~1500 archivos, ~150-200 MB total)
```

### **Paso 4: Compilar la App**

```bash
flutter run
```

O compilar APK:

```bash
flutter build apk --release
```

---

## 🎯 Ventajas de Este Sistema

✅ **100% Offline** - Todo está incluido en la app
✅ **Instantáneo** - No descarga nada al iniciar
✅ **Sin APIs** - No depende de servicios externos
✅ **Sin errores** - Todo pre-verificado y traducido
✅ **Rápido** - Carga en 1-2 segundos

---

## 📦 Tamaño de la App

- **APK sin GIFs:** ~50 MB
- **APK con GIFs:** ~200-250 MB

---

## 🔧 Si Algo Falla

### **Error: No se puede conectar a ExerciseDB**
- Verifica tu conexión a internet
- La API podría estar temporalmente caída
- Espera unos minutos y vuelve a intentar

### **Error: API Key de Gemini inválida**
- Verifica que tu API key esté correcta en `scripts/setup_offline_database.dart`
- Línea 8: `static const String geminiApiKey = 'TU_API_KEY';`

### **Error: Timeout en traducción**
- Es normal si Gemini está lento
- El script reintenta automáticamente
- Algunos ejercicios quedarán en inglés si fallan todas las traducciones

### **Carpeta assets/ no existe**
- El script la crea automáticamente
- Si ya existe, la usa

---

## 🔄 Actualizar la Base de Datos

Si ExerciseDB agrega nuevos ejercicios:

1. Borra las carpetas `assets/data/` y `assets/gifs/`
2. Ejecuta de nuevo: `dart run scripts/setup_offline_database.dart`
3. Recompila la app

---

## 💡 Notas Importantes

- **Solo ejecuta el script UNA VEZ** antes de distribuir la app
- Los GIFs se incluyen en el APK, por eso es más pesado
- La primera carga de la app toma 2-3 segundos (carga los ejercicios al Hive)
- Después de la primera carga, todo es instantáneo

---

## ❓ Preguntas Frecuentes

### **¿Puedo distribuir la app con estos archivos?**
Sí, los ejercicios de ExerciseDB y los GIFs son de uso público.

### **¿Necesito internet después del setup?**
No, la app funciona 100% offline después de compilar.

### **¿Puedo editar las traducciones?**
Sí, edita `assets/data/exercises_es.json` manualmente.

### **¿Qué pasa si ExerciseDB cambia su API?**
El JSON local sigue funcionando. Solo necesitas re-ejecutar el script si quieres nuevos ejercicios.

---

## 🎉 ¡Listo!

Después de ejecutar el script y compilar, tu app:
- ✅ Funciona 100% offline
- ✅ Tiene todos los ejercicios en español
- ✅ Incluye todos los GIFs
- ✅ No necesita descargar nada
- ✅ No depende de APIs externas

**¡Disfruta tu app ByteFit completamente offline!** 🚀
