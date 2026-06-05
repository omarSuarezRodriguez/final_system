# Paquetes — Bot de pedidos por WhatsApp

**Para restaurantes en Colombia** · Precios en COP · IVA no incluido (si aplica según tu régimen)

---

## Resumen rápido

| Paquete | Ideal para | Implementación (única vez) | Mensualidad |
|---------|------------|----------------------------|-------------|
| **Básico** | Cafetería, dark kitchen, local pequeño | **$3.500.000** | **$199.000/mes** |
| **Pro** | Restaurante con domicilios y reservas | **$6.500.000** | **$349.000/mes** |
| **Premium** | Cadena, alto volumen, soporte prioritario | **$12.000.000** | **$649.000/mes** |

*Pago anual de mensualidad: **2 meses gratis** (paga 10, usa 12).*

---

## Comparativa de paquetes

| Funcionalidad | Básico | Pro | Premium |
|---------------|:------:|:---:|:-------:|
| Menú por WhatsApp (`menu`) | ✅ | ✅ | ✅ |
| Pedidos en lenguaje natural (`pedido`) | ✅ | ✅ | ✅ |
| Confirmación con admin por WhatsApp | ✅ | ✅ | ✅ |
| Domicilio / recoger en tienda | ✅ | ✅ | ✅ |
| Google Sheets (menú, pedidos, clientes) | ✅ | ✅ | ✅ |
| Reservas de mesa (`reservar`) | — | ✅ | ✅ |
| Recordatorios al admin (pedidos pendientes) | — | ✅ | ✅ |
| Bloqueo de usuarios (`blockon` / `blockoff`) | — | ✅ | ✅ |
| Capacitación al equipo (2 h) | ✅ | ✅ | ✅ (4 h) |
| Ajustes de flujo / mensajes (por mes) | 1 h | 3 h | 8 h |
| Soporte respuesta | 48 h hábiles | 24 h hábiles | 8 h hábiles |
| Hosting y despliegue incluidos | ✅ | ✅ | ✅ |
| Onboarding y configuración inicial | ✅ | ✅ | ✅ |
| Segunda sede / segundo número | — | — | ✅ (1 incluida) |
| Reporte mensual de pedidos | — | — | ✅ |

---

## Detalle por paquete

### Básico — $3.500.000 + $199.000/mes

**Para:** negocio con un local, menú estable y pedidos por WhatsApp sin reservas.

**Incluye:**
- Bot en WhatsApp Business (vía Twilio; costos de Twilio/Meta aparte, ver notas).
- Menú digital sincronizado con Google Sheets.
- Toma de pedidos en texto libre (ej. *2 pizza hawaiana, 1 coca*).
- Flujo de confirmación, tipo de entrega y datos del cliente.
- Notificación al administrador y confirmación con `CONFIRMAR ORD-XXXX`.
- Despliegue en la nube (Render/Railway o equivalente).
- 1 h de ajustes post-lanzamiento el primer mes.

**No incluye:** reservas, bloqueo de clientes, integración de pagos, POS, dashboard web.

---

### Pro — $6.500.000 + $349.000/mes *(recomendado)*

**Para:** restaurante con domicilios, reservas y operación diaria con varios pedidos.

**Todo lo del Básico, más:**
- Reservas (`reservar`: personas, fecha, hora).
- Recordatorios automáticos al admin si hay pedidos sin confirmar.
- Gestión de usuarios bloqueados desde WhatsApp.
- Capacitación extendida (4 h total).
- Hasta 3 h/mes de cambios menores (textos, pasos del flujo, ítems del menú vía Sheets).
- Soporte en 24 h hábiles.

**No incluye:** pagos en línea, multi-sede adicional, integración Siigo/Rappi/etc.

---

### Premium — $12.000.000 + $649.000/mes

**Para:** cadena, franquicia o restaurante con alto volumen y necesidad de acompañamiento cercano.

**Todo lo del Pro, más:**
- Segunda sede o segundo número WhatsApp (1 incluido).
- Hasta 8 h/mes de evolución (flujos, mensajes, reglas del parser acordadas).
- Soporte prioritario (8 h hábiles).
- Reporte mensual: pedidos, tiempos de respuesta, incidencias.
- Revisión trimestral de rendimiento y menú/parser.

**Opcional bajo cotización:** tercera sede, pagos (Wompi/PayU), panel web, API a POS.

---

## Costos que paga el cliente aparte (transparencia)

| Concepto | Orden de magnitud (Colombia) |
|----------|------------------------------|
| **Twilio** (WhatsApp API) | ~$0,005–$0,08 USD por conversación; variable según volumen |
| **Hosting** (Render/Railway) | $0–$25 USD/mes según plan y tráfico |
| **Google Sheets** | Gratis en la mayoría de casos |
| **Dominio / SSL** | Incluido en hosting típico |

*En la mensualidad asumimos hosting en plan básico; si el tráfico crece mucho, se revisa el plan contigo.*

---

## Add-ons (precio aparte)

| Add-on | Precio desde |
|--------|--------------|
| Integración pagos (Wompi / PayU / Nequi) | $2.500.000 setup + $150.000/mes |
| Sede o número adicional | $2.000.000 setup + $199.000/mes c/u |
| Dashboard web (pedidos en tiempo real) | $5.000.000 setup + $299.000/mes |
| Integración POS / facturación | Cotización (desde $5.000.000) |
| Capacitación extra (por hora) | $120.000/h |
| Migración desde otro bot / ManyChat | $1.500.000 |

---

## Formas de pago sugeridas

| Modalidad | Detalle |
|-----------|---------|
| **Implementación** | 50% al firmar · 50% al go-live |
| **Mensualidad** | Mes calendario, anticipado |
| **Anual** | 10 meses por el precio de 12 |
| **Paquete lanzamiento** | Pro: **$8.900.000** (setup + 6 meses de servicio Pro) |

---

## Qué necesita el restaurante para empezar

1. Número WhatsApp Business (o línea a conectar vía Twilio).
2. Cuenta Google (para la hoja de menú y pedidos).
3. Lista de productos con precios y categorías.
4. Persona admin con WhatsApp para confirmar pedidos.
5. 1 reunión de 30–45 min para definir mensajes y flujo.

**Tiempo típico de implementación:** 5–10 días hábiles (Básico/Pro), 15–25 días (Premium con segunda sede).

---

## Garantía y alcance

- **Go-live:** bot operativo con menú cargado y prueba real de pedido + confirmación admin.
- **Soporte:** corrección de bugs del producto entregado; cambios de negocio nuevos se cotizan o consumen horas del plan.
- **Propiedad:** el cliente es dueño de sus datos (Sheets). El código y despliegue se licencian mientras exista la mensualidad; términos finales en contrato.

---

## Pitch para WhatsApp / correo (copiar y pegar)

> Hola, te comparto nuestros planes de **bot de pedidos por WhatsApp** para restaurantes:
>
> · **Básico** — $3,5M setup + $199k/mes — menú y pedidos con confirmación al admin  
> · **Pro** — $6,5M + $349k/mes — incluye reservas y soporte 24h *(el más elegido)*  
> · **Premium** — $12M + $649k/mes — segunda sede, reportes y soporte prioritario  
>
> El cliente escribe en natural (*2 pizzas y una coca*), el admin confirma desde su celular y todo queda en Google Sheets.  
> ¿Agendamos 20 min para ver si encaja con tu operación?

---

## Notas internas (no enviar al cliente)

- Ajusta precios ±15% según ciudad, tamaño del cliente y si tú provees la línea Twilio.
- Si el cliente ya tiene Twilio, resta complejidad y puedes subir margen en setup.
- El **Pro** debe ser el ancla visual en propuestas (efecto decoy).
- Revisa costos reales de Twilio cada trimestre; conviene tope de conversaciones en contrato.

---

*Documento generado para el producto chatbot-cursor · Actualizar precios cada 6 meses o si cambia el tipo de cambio / costos Twilio.*
