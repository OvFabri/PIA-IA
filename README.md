# Robot hospitalario de entrega de medicamentos — PIA IA

Dominio y problema PDDL que modelan a un robot autónomo que hace la ronda de medicamentos en un piso de hospital: consigue la firma del médico para cada receta, recoge las dosis en farmacia respetando la cadena de frío, las administra al paciente correcto, desinfecta su compartimento si entró a una habitación de aislamiento y administra su batería.

| Archivo | Contenido |
|---|---|
| `domain.pddl` | Tipos, 22 predicados y 7 acciones |
| `problem.pddl` | Ronda matutina: 7 lugares, 3 pacientes, 3 medicamentos, 2 compartimentos, batería de 8 niveles |
| `plan.txt` | Plan óptimo encontrado (25 pasos) |
| `GUION_VIDEO.md` | Explicación paso a paso del plan para el video |

## Cómo ejecutarlo

**Opción A: editor.planning.domains**
1. Abrir https://editor.planning.domains, cargar `domain.pddl` y `problem.pddl`.
2. Clic en **Solve**, elegir dominio y problema, y ejecutar.

**Opción B: local con pyperplan**
```bash
pip install pyperplan
pyperplan -s astar -H lmcut domain.pddl problem.pddl   # plan óptimo -> problem.pddl.soln
```

El dominio usa solo `:strips` y `:typing`, así que funciona en prácticamente cualquier planificador.

---

## Proceso de diseño

### 1. Escenario elegido y por qué

Queríamos un problema real con restricciones que **no** fueran solo "mover cosas de A a B". En hospitales ya se usan robots de entrega (por ejemplo, TUG o Moxi), y su trabajo tiene reglas que encajan bien en PDDL:

- Farmacia no entrega un medicamento sin receta validada por un médico.
- Algunos medicamentos (insulina) requieren cadena de frío.
- Entrar a una habitación de aislamiento contamina lo que entra en ella.
- Un robot tiene batería limitada.

### 2. Predicados y para qué sirve cada uno

Los dividimos entre **estáticos** (describen el mundo y nunca cambian) y **dinámicos** (cambian con las acciones).

| Predicado | Tipo | Por qué lo necesitamos |
|---|---|---|
| `(conectado ?a ?b)` | estático | Grafo del piso. Lo hicimos dirigido para poder modelar pasillos de un solo sentido si hiciera falta; en el problema declaramos ambos sentidos. |
| `(es-farmacia ?l)`, `(es-consultorio ?l)`, `(es-cargador ?l)`, `(es-limpieza ?l)` | estáticos | Marcan qué lugar permite qué acción, en lugar de poner nombres de lugares fijos dentro del dominio. Así el dominio sirve para cualquier hospital. |
| `(robot-en ?r ?l)` | dinámico | Posición del robot. |
| `(bateria ?r ?n)` | dinámico | Nivel actual de batería. |
| `(siguiente ?menor ?mayor)` | estático | "Aritmética" de la batería sin `:numeric-fluents` (ver decisión 3.1). |
| `(nivel-maximo ?n)` | estático | A qué nivel deja la batería una recarga. |
| `(compartimento-de ?c ?r)` | estático | Qué compartimentos tiene el robot. |
| `(libre ?c)`, `(contaminado ?c)` | dinámicos | Estado de cada compartimento. Son estados distintos: un compartimento contaminado está vacío pero **no** se puede usar. |
| `(apto ?m ?c)` | estático | Cadena de frío: en qué compartimento puede viajar cada medicamento. |
| `(en-farmacia ?m)`, `(en-compartimento ?m ?c)` | dinámicos | Dónde está cada dosis. |
| `(receta-pendiente ?m)`, `(receta-firmada ?m)` | dinámicos | Estado de la receta. |
| `(prescrito ?m ?p)` | estático | Qué dosis corresponde a qué paciente; impide dar un medicamento al paciente equivocado. |
| `(paciente-en ?p ?l)` | estático | Habitación de cada paciente. |
| `(en-aislamiento ?p)`, `(sin-aislamiento ?p)` | estáticos | Distinguen los dos tipos de entrega (ver decisión 3.2). |
| `(administrado ?m ?p)` | dinámico | Lo que pide la meta. |

### 3. Acciones y cómo llegamos al esquema final

El dominio tiene **7 acciones**: `mover`, `recargar`, `obtener-firma`, `cargar`, `administrar`, `administrar-aislamiento` y `desinfectar`.

#### 3.1 `mover` y la batería
Primera versión: `mover` solo cambiaba `robot-en`. Al agregar batería, la opción natural era `:numeric-fluents` (`(decrease (bateria) 1)`), pero muchos planificadores clásicos (y varios de editor.planning.domains) no los soportan. Lo resolvimos con **niveles discretos como objetos** (`b0 … b8`) y el predicado estático `(siguiente ?menor ?mayor)`. `mover` exige `(bateria ?r ?bat)` y `(siguiente ?bat-menos ?bat)`, y cambia uno por otro. Como en `b0` no existe un nivel menor, el robot simplemente no puede moverse sin batería, sin necesidad de una precondición negativa.

#### 3.2 Dos acciones de entrega en lugar de una
Queríamos que entregar en aislamiento dejara el compartimento contaminado. Con una sola acción `administrar` necesitaríamos efectos condicionales (`:conditional-effects`, `when`), que no todos los planificadores aceptan. Preferimos **dividirla en dos acciones** con precondiciones complementarias (`sin-aislamiento` y `en-aislamiento`): la normal deja el compartimento `libre` y la de aislamiento lo deja `contaminado`. Por la misma razón usamos dos predicados positivos en vez de `(not (en-aislamiento ?p))`, y así evitamos `:negative-preconditions`.

#### 3.3 `cargar`: tres reglas en una precondición
La precondición de `cargar` junta tres reglas del hospital: la receta debe estar **firmada**, el compartimento debe estar **libre** (no basta con que esté vacío: si está contaminado no sirve) y debe ser **apto** para ese medicamento. Primero pensamos en dos acciones (`cargar-refrigerado` y `cargar-normal`), pero el predicado estático `apto` lo resuelve con una sola y permite reglas más finas por medicamento.

#### 3.4 `obtener-firma`
Es lo que obliga al robot a pasar por el consultorio antes que por farmacia, y crea una dependencia de orden que el planificador tiene que descubrir.

#### 3.5 `recargar` y `desinfectar`
Son acciones "de mantenimiento": no acercan directamente a la meta, pero sin ellas la meta es inalcanzable. Eso hace que el problema no sea trivial.

### 4. Ajustes al problema (iteraciones)

| Versión | Cambio | Resultado |
|---|---|---|
| v1 | Mapa con dos pasillos (norte/sur), estación de carga separada, batería de 4 niveles | **Sin solución**: ir y volver a una habitación ya costaba 6 movimientos. Aprendimos que el planificador también sirve para detectar modelos imposibles. |
| v2 | Batería de 6 niveles | Plan de **49 pasos** con 5 recargas: correcto pero repetitivo y difícil de explicar. |
| v3 | Probamos baterías de 7 a 10 niveles y variantes del mapa | Entre 35 y 49 pasos; seguía dominado por traslados. |
| **v4 (final)** | Pasillo central, puerta directa consultorio–farmacia, **base de carga dentro de la farmacia**, batería de 8 niveles | Plan óptimo de **25 pasos** con **1 recarga obligatoria** (sin límite de batería serían 24). |

### 5. El plan resultante y por qué es interesante

El planificador descubrió una estrategia que no programamos explícitamente: **deja al paciente en aislamiento para el final**. Si fuera primero a la hab-103, el compartimento normal quedaría contaminado y tendría que ir a desinfectarlo antes de llevar el analgésico. Al dejarlo al último, desinfecta una sola vez, de regreso a la base. También aprovecha la recarga en farmacia para cargar el antibiótico en la misma parada.

Ver `GUION_VIDEO.md` para la explicación paso a paso.

### 6. En qué se diferencia de los dominios de inspiración

Nos basamos en **Air Cargo** y **Logistics** (cargar, mover, descargar), pero:

| Aspecto | Air Cargo / Logistics | Nuestro dominio |
|---|---|---|
| Recurso consumible | No hay | Batería con niveles discretos y recarga |
| Permisos | Cualquier carga se puede subir | Se necesita receta **firmada** (acción previa en otro lugar) |
| Compatibilidad carga–vehículo | Cualquier carga en cualquier avión | Cadena de frío (`apto`) |
| Capacidad | Ilimitada | 2 compartimentos, y uno se puede **inhabilitar** |
| Estado del vehículo | No cambia | Compartimentos contaminados que requieren desinfección |
| Descarga | `unload` en un aeropuerto | Dos acciones según el tipo de paciente; la dosis debe ir al paciente **prescrito** |
| Meta | Carga en destino | Entregas + robot limpio y de vuelta en su base |
