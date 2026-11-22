(define (problem ronda-matutina)
  (:domain robot-hospital)

  (:objects
    robi - robot
    farmacia consultorio pasillo hab-101 hab-102 hab-103 central-limpieza - lugar
    caja-fria caja-normal - compartimento
    insulina antibiotico analgesico - medicamento
    ana beto carla - paciente
    b0 b1 b2 b3 b4 b5 b6 b7 b8 - nivel
  )

  (:init
    ;; Mapa 
    (conectado consultorio farmacia)      (conectado farmacia consultorio)
    (conectado consultorio pasillo)       (conectado pasillo consultorio)
    (conectado farmacia pasillo)          (conectado pasillo farmacia)
    (conectado hab-101 pasillo)           (conectado pasillo hab-101)
    (conectado hab-102 pasillo)           (conectado pasillo hab-102)
    (conectado hab-103 pasillo)           (conectado pasillo hab-103)
    (conectado central-limpieza pasillo)  (conectado pasillo central-limpieza)

    (es-farmacia farmacia)
    (es-cargador farmacia)
    (es-consultorio consultorio)
    (es-limpieza central-limpieza)

    ;; Robot y bateria
    (robot-en robi farmacia)
    (bateria robi b8)
    (nivel-maximo b8)
    (siguiente b0 b1) (siguiente b1 b2) (siguiente b2 b3) (siguiente b3 b4)
    (siguiente b4 b5) (siguiente b5 b6) (siguiente b6 b7) (siguiente b7 b8)

    ;; Compartimentos
    (compartimento-de caja-fria robi)
    (compartimento-de caja-normal robi)
    (libre caja-fria)
    (libre caja-normal)
    ;; cadena de frio: la insulina solo viaja refrigerada;
    ;; el antibiotico y el analgesico solo caben en la caja normal
    (apto insulina caja-fria)
    (apto antibiotico caja-normal)
    (apto analgesico caja-normal)

    ;; Medicamentos y recetas
    (en-farmacia insulina) (en-farmacia antibiotico) (en-farmacia analgesico)
    (receta-pendiente insulina)
    (receta-pendiente antibiotico)
    (receta-pendiente analgesico)
    (prescrito insulina ana)
    (prescrito antibiotico carla)
    (prescrito analgesico beto)

    ;; Pacientes
    (paciente-en ana hab-101)   (sin-aislamiento ana)
    (paciente-en beto hab-102)  (sin-aislamiento beto)
    (paciente-en carla hab-103) (en-aislamiento carla)
  )

  (:goal (and
    (administrado insulina ana)
    (administrado antibiotico carla)
    (administrado analgesico beto)
    ;; al terminar el turno: compartimentos limpios y robot de vuelta en su base
    (libre caja-fria)
    (libre caja-normal)
    (robot-en robi farmacia)
  ))
)
