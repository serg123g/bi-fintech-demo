# ADR-0003: Bloc para gestión de estado (vs Riverpod)

- **Estado:** Aceptado · **Fecha:** 2026-10-04

## Problema a resolver
Elegir un patrón de estado predecible, testeable y familiar para equipos grandes de banca.

## Alternativas evaluadas
| Alternativa | Pros | Contras |
|---|---|---|
| **flutter_bloc** (elegida) | Eventos/estados explícitos y auditables; `bloc_test`; muy extendido en banca | Más boilerplate |
| Riverpod | Menos código; DI integrada; composición reactiva | Dos mecanismos de DI con get_it; estilos muy variados entre equipos |
| Provider/ChangeNotifier | Simple | Escala mal; mutación implícita |

## Opción seleccionada
Bloc/Cubit + get_it. Se generalizó `SwrBloc<T>` para todas las lecturas cacheadas (home, cuentas, movimientos, detalle), lo que reduce el boilerplate.

## Trade-offs
Algo más de código por pantalla a cambio de transiciones de estado explícitas y tests de bloc expresivos.

## Impacto a largo plazo
Los estados (`ResourceState`) son homogéneos en toda la app: mismo comportamiento de carga, cache y error en cada dominio.
