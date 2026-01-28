# 🧪 MODO PRUEBAS - Configuración Activada

## Cambios Aplicados para Testing

Se ha configurado el sistema en **MODO PRUEBAS** para facilitar testing con transacciones pequeñas:

### 1. ✅ Precio de Ciclo de Bots: $0.10 USD

**Archivo**: `lib/features/dashboard/presentation/providers/bots_provider.dart`

```dart
static const double CYCLE_PRICE = 0.10; // Era $20.00
```

- Los bots ahora cobran **$0.10 por ciclo** en lugar de $20
- Permite ver el flujo de carga rápidamente
- Ideal para testing de suspensiones por crédito

### 2. ✅ Slider de Autopago: Mínimo $1 USD

**Archivo**: `lib/features/billing/presentation/widgets/auto_pay_settings_card.dart`

```dart
const double minLimit = 1.0; // Era 20.0
```

- El slider de autopago ahora permite configurar desde **$1 USD**
- Valor inicial del slider: $1 (antes era $20)
- Facilita probar el sistema de autopago con montos pequeños

### 3. ✅ Sin Conversión USD → ARS

**Archivos modificados**:
- `supabase/functions/process-payment/index.ts`
- `lib/features/billing/presentation/widgets/payment_checkout_modal.dart`

**Cambios**:
- **NO se consulta la API de dólar blue**
- **NO se multiplica por el tipo de cambio**
- `$1 USD = $1 ARS` (directo, sin conversión)
- Mínimo de Mercado Pago: $1 peso (antes era $100)

**Ejemplo**:
- Deuda de $2.50 USD → Se cobran **$2.50 ARS** en la tarjeta
- Sin conversión, sin complicaciones

---

## 🚀 Pasos para Activar el Modo Pruebas

### Paso 1: Deploy del Edge Function Actualizado

El Edge Function `process-payment` debe ser redesplegado con los cambios:

```bash
cd c:\MisProyectos\BotLode_Suite\botslode
supabase functions deploy process-payment
```

O si usas PowerShell y tienes un script de deploy:

```powershell
.\verceldeploy.ps1
```

### Paso 2: Verificar en la App

1. **Ejecuta la app**:
   ```bash
   flutter run -d windows
   ```

2. **Crea un bot** o espera que uno existente complete su ciclo

3. **Verifica el cobro**: Deberías ver cargos de **$0.10** en lugar de $20

4. **Configura autopago**: El slider ahora empieza en $1

5. **Realiza un pago**: Verifica que se cobren los montos en USD directo sin conversión

---

## 🔄 Restaurar Configuración de Producción

Cuando termines las pruebas, debes revertir estos cambios:

### 1. Restaurar precio de ciclo a $20

```dart
// bots_provider.dart
static const double CYCLE_PRICE = 20.00;
```

### 2. Restaurar slider de autopago a $20

```dart
// auto_pay_settings_card.dart
const double minLimit = 20.0;
_tempLimit = dbVal > 0 ? dbVal : 20.0;
```

### 3. Restaurar conversión USD → ARS

Descomentar el código original en `process-payment/index.ts`:

```typescript
// Descomentar este bloque:
let dollarRate = 1200;
try {
    const rateResponse = await fetch('https://dolarapi.com/v1/dolares/blue');
    if (rateResponse.ok) {
        const rateData = await rateResponse.json();
        dollarRate = rateData.venta;
        console.log(`[COTIZACION] Dolar Blue: $${dollarRate}`);
    }
} catch (e) {
    console.error("[COTIZACION] Excepción:", e);
}
const amount_ars = amount_usd * dollarRate;
const finalAmountARS = Math.max(amount_ars, 100);
```

Y comentar/eliminar:

```typescript
// Comentar este bloque de pruebas:
const dollarRate = 1;
const amount_ars = amount_usd;
const finalAmountARS = Math.max(amount_ars, 1);
```

### 4. Restaurar link de pago manual

```dart
// payment_checkout_modal.dart
void _openPaymentLink() {
  final amountInArs = widget.amount * widget.exchangeRate;
  ref.read(billingProvider.notifier).openManualPaymentLink(amountInArs);
  Navigator.of(context).pop(); 
}
```

### 5. Redesplegar Edge Function

```bash
supabase functions deploy process-payment
```

---

## 📊 Escenarios de Testing Recomendados

### Test 1: Carga Normal de Bot
1. Crear un bot nuevo
2. Esperar que cargue (30 segundos en modo turbo)
3. Verificar que se agregue $0.10 a la deuda

### Test 2: Suspensión por Crédito
1. Configurar límite de crédito bajo (ej: $1)
2. Crear varios bots hasta superar el límite
3. Verificar que se suspendan automáticamente

### Test 3: Autopago
1. Configurar autopago en $1
2. Dejar que la deuda llegue a $1
3. Verificar que se ejecute el pago automático

### Test 4: Pago Manual
1. Acumular deuda (ej: $2.50)
2. Hacer pago manual
3. Verificar que se cobre exactamente $2.50 en la tarjeta

### Test 5: Error de Pago
1. Usar una tarjeta de prueba de Mercado Pago que falle
2. Verificar mensajes de error apropiados
3. Verificar que la deuda NO se reduzca

---

## ⚠️ IMPORTANTE

- **NO SUBIR A PRODUCCIÓN** con estos valores
- Estos cambios son **SOLO PARA TESTING**
- Recordar restaurar valores originales antes de deploy final
- Verificar el Edge Function esté redesplegado con cambios de producción

---

## 🔍 Logs a Revisar

Cuando hagas pruebas, revisa estos logs:

### En Flutter (console)
```
🤖 AUTOPAGO INICIADO: Deuda ($X) >= Límite ($Y)
✅ AUTOPAGO ENVIADO
```

### En Supabase Edge Functions
```
[MODO PRUEBAS] Cobrando $X ARS (sin conversión)
```

### En Base de Datos (transactions table)
- Verificar que `amount` refleje los valores en USD
- Verificar que `type` sea 'liquidation' para pagos
- Verificar que `status` sea 'COMPLETED'

---

**Fecha de configuración**: 26 de enero de 2026  
**Configurado para**: Testing de flujo de pagos con transacciones pequeñas
