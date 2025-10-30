(define (problem a2-problem2)

    ;; Reference the domain file
    (:domain a2-domain2)

    ;; ============================================
    ;; OBJECTS - Specific agents in this game
    ;; ============================================
    (:objects
        a1 - current_agent    ; This is the agent making decisions (self)
        ally1 - ally          ; Our teammate
        e1 - enemy1           ; First enemy agent
        e2 - enemy2           ; Second enemy agent
    )

    ;; ============================================
    ;; INITIAL STATE - What is true right now
    ;; ============================================
    (:init
        ;; Current agent state
        (is_pacman a1)                    ; We are currently in enemy territory

        (food_in_backpack)           ; Specifically, we have 3+ food

        ;; Food and capsule availability
        (food_available)                  ; There is still food to collect
        (near_food a1)                    ; Food is nearby (within 4 squares)
        (capsule_available)               ; Power capsules exist on the map

        ;; Enemy positions and states
        (not (is_pacman e1))              ; Enemy 1 is a ghost (defending)
        (not (is_pacman e2))              ; Enemy 2 is a ghost (defending)
        (enemy_around e1 a1)              ; Enemy 1 is close to us (danger!)
        (not (is_scared e1))              ; Enemy 1 is not scared
        (enemy_long_distance e2 a1)       ; Enemy 2 is far away

        ;; Teammate state
        (not (is_pacman ally1))           ; Ally is currently a ghost (at home)
        (not (near_ally a1))              ; Ally is not near us

        ;; Score state
        (winning_gt1)                         ; We are currently winning
        (not (winning_gt1))              ; But not by a large margin

        ;; Capsule information
        (not (near_capsule a1))           ; No capsule nearby
    )

    ;; ============================================
    ;; GOAL - What we want to achieve
    ;; ============================================
    ;;
    ;; The goal represents the high-level objective.
    ;; Different goals will be selected based on the situation:
    ;;
    ;; SCENARIO: We have food and enemy nearby -> GOAL: Get home safely!
    ;;
    (:goal (and
        (not (is_pacman a1))              ; Return to home territory
        (foods_secured)                   ; Deposit the food we're carrying
    ))
)