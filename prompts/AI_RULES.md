# AI_RULES.md


## PRIORIDAD MÁXIMA

Estas reglas tienen prioridad sobre cualquier sugerencia de refactorización, optimización o rediseño arquitectónico.

## Misión

Evolucionar el sistema existente mediante cambios incrementales, seguros y compatibles.

La prioridad es preservar la estabilidad del proyecto.

---

## Principios

* Evolucionar, no reconstruir.
* Mantener compatibilidad total.
* Preservar funcionalidades existentes.
* Aplicar siempre la solución de menor impacto.
* Reutilizar primero el código existente.
* Mantener la arquitectura actual salvo que la tarea exija lo contrario.

---

## Restricciones

No:

* Cambiar APIs existentes.
* Cambiar contratos públicos.
* Cambiar endpoints.
* Cambiar estructuras JSON existentes.
* Cambiar estados conversacionales existentes.
* Cambiar comportamiento funcional ya validado.
* Renombrar archivos sin necesidad estricta.
* Renombrar clases sin necesidad estricta.
* Renombrar funciones sin necesidad estricta.
* Mover archivos innecesariamente.
* Crear nuevas capas arquitectónicas para resolver mejoras pequeñas.
* Refactorizar módulos completos para implementar una mejora puntual.

---

## Estrategia de Implementación

Antes de modificar código:

1. Identificar la funcionalidad solicitada.
2. Identificar archivos realmente afectados.
3. Evaluar riesgos de regresión.
4. Seleccionar la solución más simple posible.
5. Modificar únicamente los componentes necesarios.

Regla:

Si una mejora puede implementarse modificando 1 archivo, no modificar 2.

Si puede implementarse modificando 2 archivos, no modificar 3.

---

## Alcance de los Cambios

Modificar:

* La menor cantidad posible de archivos.
* La menor cantidad posible de líneas.
* El menor número posible de funciones.

No tocar archivos no relacionados.

No realizar mejoras no solicitadas.

No realizar optimizaciones no solicitadas.

No realizar refactors preventivos.

---

## Compatibilidad Obligatoria

Toda mejora debe preservar:

* Parser
* Flask
* Twilio
* Flow Engine
* Order Service
* Persistencia
* Estados conversacionales

---

## Si Existe Riesgo

Si una tarea implica riesgo significativo de romper compatibilidad:

* Detener implementación.
* Explicar el riesgo.
* Proponer alternativa segura.
* Solicitar confirmación antes de continuar.

---

## Formato de Respuesta

Siempre entregar:

### Análisis previo

### Cambios implementados

### Archivos modificados

### Riesgos mitigados

### Compatibilidad verificada

### Funcionalidades agregadas

### Funcionalidades preservadas


IMPORTANTE:
Si la mejora puede implementarse modificando 1 archivo, no modifiques 2.
Si puede implementarse modificando 2 archivos, no modifiques 3.

## Componentes Críticos

- app/core/parser.py
- app/services/order_service.py
- app/flow/*
- app/integrations/twilio/*
- app/integrations/google_sheets/*

Estos componentes deben modificarse únicamente cuando la mejora lo requiera explícitamente.