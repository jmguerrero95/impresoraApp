# Xeler Impresora

Aplicación móvil Flutter para consultar y crear clientes, registrar comprobantes asociados a un cliente e imprimirlos en una impresora térmica Bluetooth mediante comandos ESC/POS.

La interfaz está en español. La aplicación consume una API HTTP externa; este repositorio contiene el cliente móvil y su adaptador local de impresión, pero **no incluye el backend, la base de datos ni un servicio para crear usuarios**.

## Funcionalidades

- Inicio de sesión con usuario y contraseña y recuperación de sesión local.
- Pantalla de inicio con clientes recientes, presentada como «Últimos 5 Clientes».
- Listado de clientes y búsqueda local por nombre.
- Creación de clientes por nombre.
- Consulta de comprobantes de un cliente y reimpresión al tocar un registro.
- Creación de comprobantes normales: valor, moneda e inicio/fin de wallet.
- Creación de comprobantes «en blanco»: valor, moneda y descripción libre.
- Selección de COP, USD o EUR; los formularios actuales capturan valores enteros, sin centavos.
- Resumen tabular de cliente, valor y fecha.
- Selección, conexión, desconexión y prueba de impresora Bluetooth.
- Guardado de la impresora seleccionada mediante API y actualización del usuario local.
- Cambio de contraseña desde Configuración.

«Factura» es el nombre utilizado por el código y los endpoints. La presencia de esta funcionalidad no acredita integración con facturación electrónica ni cumplimiento fiscal. El comprobante normal incorpora una declaración sobre una transacción en criptomonedas; la aplicación revisada no ejecuta transferencias de criptomonedas.

## Plataformas y alcance

| Plataforma | Estado del código incluido |
| --- | --- |
| Android | Contiene proyecto nativo, permisos Bluetooth y canal Kotlin personalizado. Es la plataforma principal de esta implementación; la impresión requiere validación en equipo físico. |
| iOS | Contiene proyecto Xcode, Podfile y textos de permiso Bluetooth. La configuración requiere revisión antes de considerarla operativa. |
| Web y escritorio | No se incluyen proyectos de estas plataformas. El código utiliza `dart:io` y dependencias nativas. |

## Tecnologías y dependencias

| Componente | Uso |
| --- | --- |
| Flutter / Dart | Interfaz, navegación y lógica del cliente móvil. |
| `http` | Comunicación JSON con la API. |
| `shared_preferences` | Persistencia local de las claves `token` y `user`. |
| `flutter_localizations` / `intl` | Interfaz en español y formatos numéricos/fechas. |
| `flutter_masked_text2` | Captura de importes con separador de miles. |
| `path_provider` | Directorio local donde se copian los logotipos para imprimir. |
| `blue_thermal_printer` local | Capa de compatibilidad de impresión personalizada. |
| `print_bluetooth_thermal` | Transporte Bluetooth usado por el adaptador. |
| `esc_pos_utils_plus` | Generación de comandos ESC/POS. |
| `permission_handler` | Gestión de permisos y apertura de ajustes. |
| `image` / `charset_converter` | Procesamiento de logotipos y codificación de texto. |
| `flutter_launcher_icons` | Generación del icono Android. |

Las restricciones de dependencias están en los dos archivos `pubspec.yaml`; las resoluciones concretas están en sus `pubspec.lock`.

**Es obligatorio conservar `packages/blue_thermal_printer/`.** No es una caché ni una descarga sustituible por el paquete homónimo de pub.dev: contiene código propio y la aplicación lo referencia mediante una dependencia `path`.

## Requisitos de desarrollo

Los valores siguientes se obtienen de la configuración incluida, no de una compilación verificada:

| Herramienta | Configuración observada |
| --- | --- |
| Dart declarado | `>=3.4.0 <4.0.0` en el proyecto principal. |
| Flutter declarado | `>=3.22.0`. |
| Dart del lockfile principal | `>=3.9.0-0 <4.0.0`. Usar un Flutter que incluya Dart estable 3.9 o compatible superior dentro de Dart 3. |
| Flutter del lockfile principal | `>=3.24.0`; por sí solo este mínimo no garantiza satisfacer el requisito de Dart del mismo archivo. |
| Java | JDK 17; Java y Kotlin compilan con destino 17. |
| Gradle Wrapper | 8.8. |
| Android Gradle Plugin | 8.6.1. |
| Kotlin | 2.1.0 en `settings.gradle` y en la dependencia de la app; también hay una declaración 2.0.21 en el `buildscript` raíz. |
| Android SDK | `compileSdk` es el mayor entre el valor de Flutter y 35. Build Tools fijado a 35.0.0. |
| Android NDK | La lógica intenta usar el NDK de Flutter con un mínimo de 26.1.10909125. |
| Android mínimo/objetivo | Se toman de `flutter.minSdkVersion` y `flutter.targetSdkVersion`; no hay números fijos en la app. |

No se incluye `.fvmrc` ni otra fijación exacta del SDK de Flutter. Conserva el lockfile y registra la versión de Flutter usada al validar una compilación. No uses `flutter pub upgrade` como primer paso de instalación.

Para Android se necesita el SDK con sus licencias aceptadas y un teléfono con depuración USB para comprobar Bluetooth. Para trabajar en iOS se necesita un equipo macOS con Xcode y CocoaPods, además de resolver los pendientes descritos más abajo.

## Instalación y ejecución en Android

### 1. Obtener el proyecto

Clona tu repositorio y abre la carpeta que contiene `pubspec.yaml`. Si partes de un ZIP, extrae su contenido conservando la estructura completa.

### 2. Comprobar el entorno

```bash
flutter --version
dart --version
java -version
flutter doctor -v
flutter doctor --android-licenses
```

Corrige los problemas Android indicados por `flutter doctor`. Instala Android SDK Platform 35 y Build Tools 35.0.0; si tu SDK de Flutter exige una plataforma de compilación superior, instálala también. Instala el NDK que resuelva la configuración Gradle cuando sea necesario.

### 3. Resolver dependencias

Desde la raíz:

```bash
flutter pub get
```

Este paso resuelve también `packages/blue_thermal_printer` y genera metadatos locales. No copies `android/local.properties` de otro equipo: contiene rutas particulares del SDK. Flutter puede generarlo al preparar/ejecutar Android; si Gradle no encuentra Flutter, verifica `flutter.sdk` en ese archivo o la variable `FLUTTER_SDK`, que también consulta `android/settings.gradle`.

### 4. Configurar la API

La URL está escrita directamente en tres lugares:

| Archivo | Configuración |
| --- | --- |
| `lib/api/api.dart` | `_baseUrl = 'https://impresora.xeler.io/api/'`. Mantener `/` al final. |
| `lib/paginas/testprint.dart` | URL directa de `obtenerFactura/{id}` en `sample2()`. |
| `lib/paginas/testprint.dart` | URL directa de `obtenerFacturaBlanco/{id}` en `sample3()`. |

Para usar otro backend, cambia los tres destinos. Cambiar únicamente `_baseUrl` deja las consultas de impresión apuntando al servidor anterior.

Actualmente no se lee `.env` ni se usa `--dart-define` para configurar estas URLs. Crear un archivo `.env` no cambia el comportamiento. Utiliza un backend de pruebas y credenciales suministradas por su administrador para validar creación de registros.

### 5. Ejecutar

```bash
flutter devices
flutter run -d <ID_DEL_DISPOSITIVO>
```

Sustituye `<ID_DEL_DISPOSITIVO>` por un identificador real. Un emulador puede servir para revisar interfaz, pero no sustituye una prueba con impresora física.

## Uso de la impresora

1. Enciende la impresora y emparéjala desde los ajustes Bluetooth del teléfono.
2. Inicia sesión en la aplicación.
3. Abre **Configuración → Impresora Seleccionada**.
4. Concede los permisos solicitados. En Android anteriores a 12 el canal nativo exige ubicación precisa; en Android 12 o superior exige permisos de escaneo y conexión Bluetooth.
5. Activa Bluetooth, pulsa **Actualizar**, selecciona la impresora y pulsa **Conectar**.
6. Ejecuta **Imprimir Prueba** antes de crear comprobantes.
7. Abre un cliente para crear un comprobante o toca uno de sus registros existentes para reimprimirlo.

La lista se obtiene de dispositivos emparejados; no hay una pantalla que complete el emparejamiento inicial. La conexión usa la dirección del dispositivo y necesita un modelo compatible con el transporte del plugin y con ESC/POS.

El adaptador configura papel de **80 mm** mediante `PaperSize.mm80`. No existe un selector de ancho en la interfaz. Para adaptar una impresora de 58 mm hay que ajustar ese valor y verificar anchos de imagen, texto y saltos con una impresión física.

Los logotipos se copian de assets al directorio de documentos de la app. `sample2()` utiliza `192xeler.png`; `sample3()` utiliza `192blanco.png`. El adaptador convierte imágenes a escala de grises y blanco/negro. La codificación habitual es CP1252; varias llamadas de comprobantes solicitan `iso-8859-1`. Si una impresora muestra caracteres incorrectos, revisa su tabla de caracteres y el contenido enviado.

**Crear y imprimir son operaciones distintas:** primero se registra el comprobante en el servidor y después se intenta imprimir. Una ausencia de papel, desconexión o error de impresión no revierte el registro creado. Consulta el historial y reimprime antes de volver a crear el mismo comprobante.

## Estructura y responsabilidades

| Ruta | Responsabilidad |
| --- | --- |
| `lib/main.dart` | Inicialización, localización, tema, recuperación de sesión e intento de reconexión si el usuario guardado tiene datos de impresora completos. |
| `lib/api/api.dart` | Cliente común GET/POST JSON y anexado del token a la URL. |
| `lib/model/` | Modelos `Clientes`, `Facturas`, `Resumen` y `UltimosClientes`. |
| `lib/paginas/Inicio.dart` | Navegación inferior: Inicio, Clientes, Resumen y Configuración. |
| `lib/paginas/Home.dart` | Clientes recientes. |
| `lib/paginas/Clientes.dart` / `CrearCliente.dart` | Listado, filtro local y creación de clientes. |
| `lib/paginas/DetallesCliente.dart` | Historial del cliente, acceso a creación y reimpresión. |
| `lib/paginas/CrearFactura.dart` | Registro de valor/moneda e inicio/fin de wallet alfanuméricos y no vacíos. |
| `lib/paginas/CrearFacturaBlanco.dart` | Registro de valor/moneda y descripción libre. |
| `lib/paginas/testprint.dart` | Servicio `TestPrint`: formatos de comprobantes y ticket de prueba. Pese al nombre, es código de ejecución de la app. |
| `lib/paginas/Seleccion2.dart` | Permisos, dispositivos emparejados, conexión y guardado de impresora. |
| `lib/paginas/Login.dart` / `Cambiar.dart` | Inicio de sesión y cambio de contraseña. |
| `lib/impresora/convert_to_letters.dart` | Utilidad de conversión numérica en inglés/farsi; no se encontró importación en el flujo actual. El ticket usa `valor_letras` del backend. |
| `lib/paginas/Password.dart` | Archivo vacío en esta versión; no implementa recuperación de contraseña. |
| `packages/blue_thermal_printer/` | Adaptador Dart local, permisos, conexión, imágenes, texto y comandos ESC/POS. |
| `android/app/src/main/kotlin/com/example/xeler_impresora/MainActivity.kt` | Canal nativo `com.example.xeler_impresora/bluetooth`: permisos, estado, activación y dispositivos emparejados. |
| `assets/images/` / `fonts/` | Imágenes de interfaz/impresión y tipografía Raleway. |
| `android/` / `ios/` | Configuraciones y proyectos nativos. |
| `test/widget_test.dart` | Prueba de presentación del login sin sesión. |

La app usa `StatefulWidget`, `setState` y navegación con `MaterialPageRoute`. Las pantallas llaman al cliente API y convierten JSON a modelos; no hay una capa adicional de repositorios ni una base de datos local de clientes/comprobantes.

## API que espera el cliente

Este es el contrato **observado en las llamadas Dart**. No sustituye la documentación del servidor ni confirma sus controles de acceso, validaciones o disponibilidad.

Las llamadas de `CallApi` envían `Accept: application/json` y `Content-Type: application/json`. Los POST llevan JSON. Si existe un token local, se añade a la query como `?token=...` o `&token=...`, incluso al login si hubiera un token anterior. No se usa un header Bearer.

| Método | Ruta relativa a `/api/` | Datos enviados / respuesta utilizada |
| --- | --- | --- |
| POST | `login` | Envía `username`, `password`. Espera `success`, `token`, `user`; usa `message` para el error. |
| GET | `obtenerUltimos` | Espera objeto con `clientes`, una lista de `id` y `name`. |
| GET | `obtenerMisClientes` | Espera lista de objetos con `id` y `name`. |
| POST | `crearCliente` | Envía `name`. Con HTTP 200 utiliza `id` y `name`; para errores utiliza `mensaje`. |
| GET | `obtenerFacturasCliente2/{clienteId}` | Espera lista de comprobantes. |
| POST | `crearFactura` | Envía `valor` como texto entero, `wallet_inicio`, `wallet_fin`, `cliente_id`, `currency`. Con HTTP 200 usa `factura_id`. |
| POST | `crearFacturaBlanco` | Envía `valor` como texto entero, `descripcion`, `cliente_id`, `currency`. Con HTTP 200 usa `factura_id`. |
| GET | `obtenerResumen` | Espera lista con `id`, `valor`, `cliente`, `wallet_inicio`, `wallet_fin`, `created_at`. |
| POST | `guardarImpresora` | Envía `dispositivo`, `tipo`, `address`, `direccion`. Si `success` es verdadero, reemplaza `user` local con el `user` recibido. |
| POST | `configuracion2` | Envía `old_password`, `password`, `nueva` (confirmación). Utiliza `success`, `mensaje`, `titulo`. |
| GET | `logout` | Los métodos de logout esperan `success`; al ser verdadero eliminan `token` y `user`. No se encontró botón que los invoque en la interfaz incluida. |
| GET directo | `obtenerFactura/{id}` | `sample2()` consulta con `http.get`, sin pasar por `CallApi` y sin añadir token. |
| GET directo | `obtenerFacturaBlanco/{id}` | `sample3()` consulta con `http.get`, sin pasar por `CallApi` y sin añadir token. |

Los comprobantes del historial usan `id`, `factura_id`, `valor`, `created_at`, `tipo` (`normal` o `blanco`), `currency`, `wallet_inicio`, `wallet_fin` y `descripcion`. Los detalles para imprimir utilizan `created_at`, `name`, `valor`, `valor_letras`, `currency` y los campos del tipo de comprobante.

La creación pasa el `factura_id` devuelto al servicio de impresión; la reimpresión pasa el `id` del modelo. El backend debe admitir esta correspondencia o se debe ajustar el cliente. No asumir que esos identificadores son equivalentes sin verificarlo.

El usuario persistido se consulta para `dispositivo`, `tipo` y `address`/`direccion`. Hoy `address` y `direccion` se utilizan como alternativas para la dirección del dispositivo; ese mismo valor se imprime bajo la etiqueta «Punto».

## Sesión y consideraciones de integración

- `token` se guarda como texto y `user` como JSON en `SharedPreferences`; no hay almacenamiento seguro dedicado en el código revisado.
- El arranque considera que hay sesión si existen ambas claves. No hace una validación remota previa del token.
- La app requiere conexión con la API para consultar clientes, registrar comprobantes y obtener los datos de reimpresión. No hay cola de sincronización offline.
- El cliente común no configura timeout explícito ni tratamiento central de HTTP 401/403.
- Los tokens en query pueden quedar en registros de infraestructura. Para migrar a headers de autorización hay que coordinar el cambio con el backend.
- Los dos endpoints de detalle para impresión se consultan sin token desde este cliente. Hay que revisar en el servidor la autorización y el acceso a datos por identificador; el ZIP móvil no permite determinar qué protege esas rutas.

## Comandos de desarrollo y compilación

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release
flutter build appbundle --release
```

Los comandos son instrucciones para el desarrollador. No se ejecutaron en la revisión del ZIP porque el entorno de revisión no tenía Flutter/Dart instalados.

Salidas habituales según el comando:

- APK debug: `build/app/outputs/flutter-apk/app-debug.apk`.
- APK release: `build/app/outputs/flutter-apk/app-release.apk`.
- Android App Bundle: `build/app/outputs/bundle/release/app-release.aab`.

**Firma:** `android/app/build.gradle` asigna `signingConfigs.debug` también a `release`. Antes de distribuir una versión, configura una clave y firma de lanzamiento propias. Ignorar `key.properties` o los keystores no configura automáticamente la firma.

El identificador Android actual es `com.example.xeler_impresora`. Si se cambia para distribución, actualiza coherentemente namespace, applicationId, paquete/ruta Kotlin y manifest. Si también se cambia el nombre del canal Bluetooth, modifica tanto Kotlin como el adaptador Dart para que coincidan.

Para regenerar el icono Android, si se modifica su imagen de origen:

```bash
dart run flutter_launcher_icons
```

La configuración del icono está en `pubspec.yaml` y usa `assets/images/impresoralogo.png`.

### Pruebas incluidas

Hay una prueba de widget que comprueba que `MyApp` muestra `LogIn` cuando `SharedPreferences` está vacío y desactiva temporalmente el monitoreo del adaptador. No cubre autenticación real, contratos de API, creación, impresión, permisos ni reconexión.

Una comprobación manual mínima debe incluir login con cuenta de pruebas, listado/creación de cliente, conexión y ticket de prueba, creación y reimpresión de ambos tipos de comprobante y cambio de contraseña. Confirma la respuesta del servidor antes de repetir una creación tras un error de impresión.

## Estado de iOS

No asumir soporte iOS completo a partir de la presencia de la carpeta:

- El Podfile declara iOS 12.0, pero el proyecto Xcode contiene valores `IPHONEOS_DEPLOYMENT_TARGET = 8.0`.
- El Podfile incluido no contiene un bloque `target 'Runner'` ni una llamada a `flutter_install_all_ios_pods`. Hay que revisar la integración de plugins antes de esperar una compilación funcional.
- Existen textos de permiso Bluetooth en `Info.plist` y registro de plugins en `AppDelegate.swift`, pero eso no valida la compatibilidad de la impresora/transporte en iOS.
- El canal nativo personalizado solo tiene implementación Kotlin en este repositorio.
- Deben comprobarse compatibilidad de plugins, permisos, destino mínimo, firma y pruebas físicas con el modelo concreto de impresora.

No se modifican estos archivos como parte de la documentación.

## Problemas frecuentes

| Síntoma | Qué revisar |
| --- | --- |
| `pub get` informa de SDK incompatible | Compara el Dart de `flutter --version` con el requisito del lockfile, no solo con el mínimo de `pubspec.yaml`. |
| No se encuentra `blue_thermal_printer` local | Verifica que exista `packages/blue_thermal_printer/pubspec.yaml` y que no se haya excluido `packages/` de Git. |
| Gradle no encuentra Flutter/Android SDK | Ejecuta `flutter doctor -v` y revisa las rutas locales de `android/local.properties`. |
| Falla por Java o SDK | Comprueba JDK 17, SDK/Build Tools y la versión de NDK solicitada por Gradle. |
| No aparecen impresoras | Empareja primero desde Android, activa Bluetooth, concede permisos y pulsa Actualizar. |
| La impresora conecta pero no queda guardada | `_guardarImpresora()` exige nombre, dirección y `tipo` no nulos. Algunas rutas de detección pueden devolver `tipo` nulo; revisa los datos recibidos antes de atribuir el fallo a la API. |
| No imprime al crear | Comprueba conexión, datos de impresora en `user`, disponibilidad del logo y respuesta del endpoint de detalle. El registro puede haberse creado aunque no se imprima. |
| Al cambiar de servidor sigue consultando el anterior | Cambia también las dos URLs directas de `testprint.dart`. |
| Acentos o símbolos incorrectos | Verifica tabla CP1252/codificación, fuentes admitidas por la impresora y contenido del ticket. |
| Ticket cortado o mal alineado | El ancho está fijado a 80 mm; adapta `_paperSize` y el formato al hardware. |
| Un corte de conexión no se refleja automáticamente | El inicio del monitor está comentado en el constructor del adaptador; no asumir sondeo periódico activo en producción. Actualizar/reconectar y revisar el estado real. |
| Listado vacío o error JSON | Revisa conectividad, HTTP, vigencia de sesión y estructura real del JSON. Algunas pantallas convierten errores en listas vacías. |

## Archivos que se deben versionar

Conserva `lib/`, `packages/blue_thermal_printer/`, `assets/`, `fonts/`, `test/`, proyectos nativos, manifests, configuración Gradle/Xcode, `pubspec.yaml`, **`pubspec.lock`**, `analysis_options.yaml` y documentación.

También conserva `android/gradlew`, `android/gradlew.bat`, `android/gradle/wrapper/gradle-wrapper.jar` y `android/gradle/wrapper/gradle-wrapper.properties`. El wrapper permite mantener la versión de Gradle del proyecto. En este repositorio hay reglas en `android/.gitignore`; usa la versión corregida incluida junto a este README para que esos archivos no queden ocultos.

Las imágenes de la raíz se conservan: no se excluyen por una regla genérica aunque algunas no estén declaradas como assets. La revisión de archivos sin uso debe ser una decisión separada.

El `.gitignore` excluye cachés, salidas de compilación, metadatos regenerables, preferencias locales de IDE y configuración local de SDK/firma. No excluye código Dart, fuentes, recursos, lockfiles ni archivos de configuración necesarios del proyecto.

### Aplicar esta documentación antes del primer commit

Coloca estos archivos en sus rutas exactas:

- `README.md` en la raíz, reemplazando el README inicial de Flutter.
- `.gitignore` en la raíz.
- `android/.gitignore` dentro de Android, reemplazando las reglas que ignoraban el wrapper.

Si todavía no existe un repositorio Git, ejecuta `git init`. Después, revisa:

```bash
git status --short --ignored
git add .
git diff --cached --stat
git diff --cached --name-only
```

Confirma que aparezcan el paquete local, los assets y los archivos del wrapper, y que no se añadan `android/local.properties`, `android/.gradle/`, `build/` ni secretos de firma. Estos comandos preparan y permiten inspeccionar los archivos; no crean un commit ni publican nada.

Si un archivo generado ya estaba versionado, `.gitignore` no lo elimina del índice. Retíralo de seguimiento de forma específica, conservando el archivo local, por ejemplo:

```bash
git rm --cached --ignore-unmatch android/local.properties .flutter-plugins-dependencies
git rm -r --cached --ignore-unmatch android/.gradle
```

Evita borrar carpetas completas de código o regenerar los proyectos nativos para solucionar reglas de Git.

## Versión y licencia

`pubspec.yaml` declara `1.0.0+1`; la pantalla Configuración muestra `V2.0` como texto fijo. Unifica ambos valores cuando prepares una nueva versión.

No se incluyó un archivo `LICENSE` en el material revisado. No se presume una licencia de código abierto; define las condiciones de uso y los derechos sobre el código, marcas, imágenes y tipografías antes de una publicación pública.
