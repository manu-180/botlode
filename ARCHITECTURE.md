# Arquitectura BotLode - Clean Architecture

## Principios Fundamentales

BotLode sigue **Clean Architecture** con una estructura por features, donde cada feature es independiente y sigue la separación de capas:

```
feature/
├── data/         # Capa de datos (implementaciones de repositorios, APIs, BD)
├── domain/       # Capa de dominio (modelos, repositorios abstractos, servicios)
└── presentation/ # Capa de presentación (UI, providers, widgets)
```

## Estructura General

```
lib/
├── core/                    # Funcionalidades compartidas y configuración
│   ├── config/             # Configuración global (tema, colores, app_config)
│   ├── providers/          # Providers de infraestructura (supabase, connectivity, rive)
│   ├── router/             # Routing con GoRouter
│   └── ui/
│       └── widgets/        # Widgets compartidos entre features
│
├── features/               # Features de la aplicación
│   ├── auth/              # Autenticación y autorización
│   ├── billing/           # Gestión de facturación y pagos
│   ├── bot_engine/        # Motor de chat y comunicación con bots
│   ├── bots_library/      # Catálogo de plantillas de bots
│   ├── dashboard/         # Dashboard principal y gestión de bots
│   └── settings/          # Configuración de usuario
│
└── main.dart              # Entry point de la aplicación
```

## Features Detallados

### 1. Auth (Autenticación)

**Responsabilidad**: Gestión de sesiones, login, registro y permisos.

**Estructura**:
- `domain/repositories/`: Contrato de AuthRepository
- `data/repositories/`: Implementación con Supabase
- `presentation/providers/`: 
  - `auth_repository_provider.dart`: Inyección del repositorio
  - `auth_state_provider.dart`: Estado de autenticación (sesión, loading, errores)
- `presentation/views/`: Vista de login

**Notas**:
- El archivo `core/providers/auth_provider.dart` actúa como alias de compatibilidad, pero el código real está en el feature auth.

### 2. Billing (Facturación)

**Responsabilidad**: Gestión de tarjetas, pagos, transacciones y límites de crédito.

**Estructura**:
- `domain/models/`: CardInfo, Transaction
- `domain/repositories/`: Contrato de BillingRepository
- `domain/services/`: Servicios de dominio
  - `card_validator_service.dart`: Validación de tarjetas (Luhn, BIN detection)
  - `payment_error_service.dart`: Mapeo de errores a mensajes amigables
- `data/repositories/`: Implementación con Supabase + Mercado Pago
- `presentation/`: Views, widgets y providers

**Decisiones de diseño**:
- Los servicios de dominio (`*_service.dart`) contienen lógica de negocio pura sin dependencias externas.
- La validación de tarjetas usa el algoritmo de Luhn estándar.

### 3. Bot Engine (Motor de Chat)

**Responsabilidad**: Comunicación con bots IA, gestión de conversaciones y animaciones.

**Estructura**:
- `domain/models/`: BotResponse
- `domain/repositories/`: ChatRepository
- `data/repositories/`: Implementación con API externa (OpenAI, Anthropic, etc.)
- `presentation/providers/`:
  - `chat_provider.dart`: Gestión del estado del chat
  - `bot_mood_provider.dart`: Estado del "mood" visual del bot (animaciones Rive)
- `presentation/widgets/`: Widgets de chat y visualización Rive

**Notas**:
- `bot_mood_provider.dart` se separó del widget para respetar la separación de capas.
- Los widgets de Rive manejan solo visualización, la lógica está en providers.

### 4. Bots Library (Biblioteca de Plantillas)

**Responsabilidad**: Catálogo de blueprints/plantillas predefinidas para crear bots.

**Estructura**:
- `domain/models/`: BotBlueprint (con prompts maestros predefinidos)
- `presentation/`: Views y widgets para mostrar el catálogo

**Notas**:
- No tiene capa `data` porque los blueprints están hardcodeados.
- Si en el futuro se necesita persistencia remota, agregar capa `data`.

### 5. Dashboard (Panel Principal)

**Responsabilidad**: Gestión de bots del usuario (CRUD), visualización de estado, orquestación general.

**Estructura**:
- `domain/models/`: Bot
- `domain/repositories/`: BotsRepository
- `data/repositories/`: Implementación con Supabase
- `presentation/providers/`:
  - `bots_provider.dart`: Gestión del ciclo de vida de bots, autopago, suspensiones
  - `dashboard_controller.dart`: Filtros y búsqueda de bots
- `presentation/views/`: Dashboard, bot detail, main layout
- `presentation/widgets/`: Cards, modals, toolbar

**Decisiones de diseño**:
- Dashboard actúa como **feature orquestador**, coordinando billing y bot_engine.
- El `bots_provider.dart` tiene lógica compleja de ciclo de vida que idealmente debería estar en use cases (mejora futura).

### 6. Settings (Configuración)

**Responsabilidad**: Configuración de usuario, cambio de contraseña.

**Estructura**:
- `presentation/`: Solo UI, sin lógica compleja

**Notas**:
- No requiere capas domain/data por simplicidad.
- Si crece en complejidad, refactorizar siguiendo la estructura estándar.

## Dependencias entre Features

### Dependencias Aceptables

Algunas dependencias entre features son esperadas y aceptables:

1. **Dashboard → Billing**: 
   - Dashboard necesita verificar límites de crédito y coordinar pagos.
   - Justificación: Dashboard es el orquestador principal.

2. **Dashboard → Bot Engine**:
   - Dashboard muestra detalles de bots que incluyen el chat.
   - Justificación: Composición de UI, no hay acoplamiento de lógica.

3. **Bots Library → Dashboard**:
   - Bots Library usa el modal de creación de dashboard.
   - Justificación: Bots Library es esencialmente un "alimentador" de dashboard.

### Reglas de Oro

- **Nunca**: Features no orquestadores dependen entre sí (ej: billing → bot_engine ❌).
- **Siempre**: Las dependencias van hacia el dominio, no hacia presentación de otros features (excepto widgets compartidos).
- **Ideal**: Widgets compartidos en `core/ui/widgets/`, lógica compartida en use cases.

## Tecnologías y Herramientas

- **Framework**: Flutter
- **State Management**: Riverpod (con code generation)
- **Backend**: Supabase (Auth, Database, Edge Functions)
- **Routing**: GoRouter con guards de autenticación
- **Animaciones**: Rive, Flutter Animate
- **Pagos**: Mercado Pago API

## Decisiones Arquitectónicas Importantes

### 1. Providers vs Use Cases

**Estado actual**: La lógica de negocio compleja está en Notifiers (presentation layer).

**Mejora futura**: Extraer lógica a use cases en `domain/use_cases/`.

**Ejemplo**:
- `bots_provider.dart` maneja ciclo de vida, autopago, suspensiones → debería ser `ManageBotsLifecycleUseCase`.

### 2. Modelos de Dominio vs DTOs

**Estado actual**: Modelos de dominio mapean directamente desde/hacia BD.

**Mejora futura**: Separar:
- `domain/models/`: Entidades de negocio puras
- `data/models/`: DTOs para mapeo de API/BD

### 3. Testing

**Estado actual**: Tests mínimos.

**Recomendación**:
- Tests unitarios para servicios de dominio
- Tests de integración para repositorios
- Tests de widget para UI crítica

## Refactorizaciones Recientes

### 2026-01-26: Limpieza Arquitectónica

1. **Eliminación de duplicados**:
   - Eliminado `dashboard/data/bots_repository_impl.dart` duplicado.

2. **Reorganización de Auth**:
   - Movido `AuthNotifier` de `core/` a `features/auth/presentation/`.
   - `core/providers/auth_provider.dart` ahora es un alias de compatibilidad.

3. **Servicios de Dominio en Billing**:
   - Renombrado `domain/logic/` → `domain/services/`
   - `card_validator_logic.dart` → `card_validator_service.dart`
   - `payment_error_handler.dart` → `payment_error_service.dart`

4. **Desacoplamiento de Bot Engine**:
   - Extraído `terminalBotMoodProvider` de widget a `bot_mood_provider.dart`
   - Mejor separación entre providers y widgets.

## Criterios de Éxito

Una arquitectura limpia cumple:

✅ Cada feature es independiente y testeable en aislamiento  
✅ Core contiene solo infraestructura compartida  
✅ La lógica de negocio está en domain o use cases  
✅ Cero duplicación de código  
✅ Imports claros y unidireccionales (presentation → domain → data)  

## Próximos Pasos Recomendados

1. Implementar use cases para lógica compleja (ej: ManageBotsLifecycleUseCase)
2. Agregar tests unitarios y de integración
3. Separar modelos de dominio vs DTOs si el mapeo se vuelve complejo
4. Considerar eventos/notificaciones para comunicación entre features si crece la complejidad
