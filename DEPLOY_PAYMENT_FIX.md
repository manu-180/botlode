# Desplegar Fix de Moneda

## Comando para redesplegar:

```powershell
cd c:\MisProyectos\BotLode_Suite\botslode
supabase functions deploy process-payment --no-verify-jwt
```

## Verificar Credenciales de Mercado Pago

### En el Dashboard de Supabase:

1. Ve a **Project Settings** → **Edge Functions** → **Secrets**
2. Verifica estas variables:

- `MP_ACCESS_TOKEN`: Debe empezar con `APP_USR-` (producción) o `TEST-` (prueba)
- `MP_PUBLIC_KEY`: Debe empezar con `APP_USR-` (producción) o `TEST-` (prueba)

### ⚠️ IMPORTANTE: Modo de Prueba vs Producción

**Modo de Prueba (TEST):**
- Credenciales empiezan con `TEST-`
- Tarjetas de prueba de Mercado Pago
- NO se cobra dinero real
- Los emails dicen "Modo de prueba"

**Modo de Producción (APP_USR):**
- Credenciales empiezan con `APP_USR-`
- Tarjetas reales
- Se cobra dinero real
- Los emails NO dicen "Modo de prueba"

### Si quieres usar Producción:

1. Obtén tus credenciales de producción desde: https://www.mercadopago.com.ar/developers/panel/app
2. En Supabase, actualiza:
   - `MP_ACCESS_TOKEN` → Tu Access Token de producción
   - `MP_PUBLIC_KEY` → Tu Public Key de producción
3. Redesplega: `supabase functions deploy process-payment --no-verify-jwt`

### Si quieres seguir en Prueba:

Mantén las credenciales TEST y usa tarjetas de prueba:
- **Visa aprobada**: `4509 9535 6623 3704`
- **Mastercard aprobada**: `5031 7557 3453 0604`
- **CVV**: cualquier 3 dígitos
- **Fecha**: cualquier fecha futura

## Cambio Aplicado:

Se agregó `currency_id: "ARS"` al payload del pago para que Mercado Pago cobre en pesos, no en dólares.
