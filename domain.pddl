(define (domain robot-hospital)
  (:requirements :strips :typing)

  (:types
    robot lugar compartimento medicamento paciente nivel - object
  )

  (:predicates
    (conectado ?a - lugar ?b - lugar)        
    (es-farmacia ?l - lugar)
    (es-consultorio ?l - lugar)
    (es-cargador ?l - lugar)
    (es-limpieza ?l - lugar)

    ;; Robot
    (robot-en ?r - robot ?l - lugar)
    (bateria ?r - robot ?n - nivel)            
    (siguiente ?menor - nivel ?mayor - nivel) 
    (nivel-maximo ?n - nivel)                  

    ;; Compartimentos del robot
    (compartimento-de ?c - compartimento ?r - robot)  
    (libre ?c - compartimento)
    (contaminado ?c - compartimento)
    (apto ?m - medicamento ?c - compartimento)        

    ;; Medicamentos y recetas
    (en-farmacia ?m - medicamento)
    (prescrito ?m - medicamento ?p - paciente)       
    (receta-pendiente ?m - medicamento)
    (receta-firmada ?m - medicamento)
    (en-compartimento ?m - medicamento ?c - compartimento)

    ;; Pacientes
    (paciente-en ?p - paciente ?l - lugar)
    (en-aislamiento ?p - paciente)
    (sin-aislamiento ?p - paciente)
    (administrado ?m - medicamento ?p - paciente)
  )

  ;; 1. MOVER: avanza a un lugar conectado y gasta un nivel de bateria.
  (:action mover
    :parameters (?r - robot ?desde - lugar ?hacia - lugar
                 ?bat - nivel ?bat-menos - nivel)
    :precondition (and (robot-en ?r ?desde)
                       (conectado ?desde ?hacia)
                       (bateria ?r ?bat)
                       (siguiente ?bat-menos ?bat))
    :effect (and (not (robot-en ?r ?desde))
                 (robot-en ?r ?hacia)
                 (not (bateria ?r ?bat))
                 (bateria ?r ?bat-menos)))

  ;; 2. RECARGAR: en la estacion de carga la bateria vuelve al maximo.
  (:action recargar
    :parameters (?r - robot ?l - lugar ?bat - nivel ?max - nivel)
    :precondition (and (robot-en ?r ?l)
                       (es-cargador ?l)
                       (bateria ?r ?bat)
                       (nivel-maximo ?max))
    :effect (and (not (bateria ?r ?bat))
                 (bateria ?r ?max)))

  ;; 3. OBTENER-FIRMA: en el consultorio el medico valida una receta.
  (:action obtener-firma
    :parameters (?r - robot ?m - medicamento ?l - lugar)
    :precondition (and (robot-en ?r ?l)
                       (es-consultorio ?l)
                       (receta-pendiente ?m))
    :effect (and (not (receta-pendiente ?m))
                 (receta-firmada ?m)))

  ;; 4. CARGAR: la farmacia solo entrega dosis con receta firmada, y solo
  (:action cargar
    :parameters (?r - robot ?m - medicamento ?c - compartimento ?l - lugar)
    :precondition (and (robot-en ?r ?l)
                       (es-farmacia ?l)
                       (en-farmacia ?m)
                       (receta-firmada ?m)
                       (compartimento-de ?c ?r)
                       (libre ?c)
                       (apto ?m ?c))
    :effect (and (not (en-farmacia ?m))
                 (not (libre ?c))
                 (en-compartimento ?m ?c)))

  ;; 5. ADMINISTRAR: entrega la dosis a un paciente sin aislamiento.
  (:action administrar
    :parameters (?r - robot ?m - medicamento ?c - compartimento
                 ?p - paciente ?l - lugar)
    :precondition (and (robot-en ?r ?l)
                       (paciente-en ?p ?l)
                       (sin-aislamiento ?p)
                       (compartimento-de ?c ?r)
                       (en-compartimento ?m ?c)
                       (prescrito ?m ?p))
    :effect (and (not (en-compartimento ?m ?c))
                 (libre ?c)
                 (administrado ?m ?p)))

  ;; 6. ADMINISTRAR-AISLAMIENTO: igual que la anterior, pero el paciente
  (:action administrar-aislamiento
    :parameters (?r - robot ?m - medicamento ?c - compartimento
                 ?p - paciente ?l - lugar)
    :precondition (and (robot-en ?r ?l)
                       (paciente-en ?p ?l)
                       (en-aislamiento ?p)
                       (compartimento-de ?c ?r)
                       (en-compartimento ?m ?c)
                       (prescrito ?m ?p))
    :effect (and (not (en-compartimento ?m ?c))
                 (contaminado ?c)
                 (administrado ?m ?p)))

  ;; 7. DESINFECTAR: en la central de limpieza un compartimento
  (:action desinfectar
    :parameters (?r - robot ?c - compartimento ?l - lugar)
    :precondition (and (robot-en ?r ?l)
                       (es-limpieza ?l)
                       (compartimento-de ?c ?r)
                       (contaminado ?c))
    :effect (and (not (contaminado ?c))
                 (libre ?c)))
)
