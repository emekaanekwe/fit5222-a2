;; Improved Pacman Capture the Flag Domain
;; This domain extends the baseline with more sophisticated actions and predicates
;; for better strategic decision-making in the Pacman CTF game

(define (domain pacman_ctf_advanced)

    (:requirements :strips :typing :negative-preconditions)

    ;; Type hierarchy for game objects
    (:types
        enemy team - object          ; Top-level categorization
        enemy1 enemy2 - enemy        ; Two enemy agents
        ally current_agent - team    ; Teammate and self
    )

    ;; Predicates define all possible states in the game
    (:predicates
        ;; ============================================
        ;; BASIC STATE PREDICATES
        ;; ============================================
        (is_pacman ?x)                    
        (food_available)                      
        (food_in_backpack ?a - team)          
        (capsule_available)                   

        ;; ============================================
        ;; DISTANCE PREDICATES (Enemy tracking)
        ;; ============================================
        ;; These use noisy distance readings to categorize enemy positions
        (enemy_around ?e - enemy ?a - team)           ; Enemy within 4 squares
        (enemy_short_distance ?e - enemy ?a - current_agent)   ; Distance < 15
        (enemy_medium_distance ?e - enemy ?a - current_agent)  ; 15 ≤ Distance < 25
        (enemy_long_distance ?e - enemy ?a - current_agent)    ; Distance ≥ 25

        ;; ============================================
        ;; FOOD QUANTITY PREDICATES
        ;; ============================================
        ;; Track how much food agent is carrying for risk assessment
        (food_3_in_backpack ?a - team)        ; Carrying 3+ food
        (food_5_in_backpack ?a - team)        ; Carrying 5+ food
        (food_10_in_backpack ?a - team)       ; Carrying 10+ food
        (food_20_in_backpack ?a - team)       ; Carrying 20+ food

        ;; ============================================
        ;; PROXIMITY PREDICATES
        ;; ============================================
        (near_food ?a - current_agent)        ; Food within 4 squares
        (near_capsule ?a - current_agent)     ; Capsule within 4 squares
        (near_ally ?a - current_agent)        ; Teammate within 4 squares

        ;; ============================================
        ;; SCORE AND WIN STATE PREDICATES
        ;; ============================================
        (winning)                             ; Team score > enemy score
        (winning_gt3)                         ; Leading by 3+ points
        (winning_gt5)                         ; Leading by 5+ points
        (winning_gt10)                        ; Leading by 10+ points
        (winning_gt20)                        ; Leading by 20+ points

        ;; ============================================
        ;; POWER-UP STATE PREDICATES
        ;; ============================================
        (is_scared ?x)                        ; Agent is in scared state (from capsule)

        ;; ============================================
        ;; COOPERATIVE/COORDINATION PREDICATES
        ;; ============================================
        ;; These track what teammate is doing for coordination
        (eat_enemy ?a - ally)                 ; Ally is hunting enemy
        (go_home ?a - ally)                   ; Ally is returning to base
        (go_enemy_land ?a - ally)             ; Ally is invading enemy territory
        (eat_capsule ?a - ally)               ; Ally is going for capsule
        (eat_food ?a - ally)                  ; Ally is collecting food

        ;; ============================================
        ;; VIRTUAL GOAL PREDICATES
        ;; ============================================
        ;; These are used as goal states only, not tracked by environment
        (defend_foods)                        ; Goal: Patrol and defend
        (foods_secured)                       ; Goal: Successfully deposited food
        (capsule_obtained)                    ; Goal: Got power capsule
        (enemy_neutralized ?e - enemy)        ; Goal: Caught enemy pacman
    )

    ;; ============================================
    ;; OFFENSIVE ACTIONS
    ;; ============================================

    ;; Basic attack action - go to enemy territory and collect food
    (:action attack
        :parameters (?a - current_agent ?e1 - enemy1 ?e2 - enemy2)
        :precondition (and
            (not (is_pacman ?e1))             ; Enemy 1 is ghost (defending)
            (not (is_pacman ?e2))             ; Enemy 2 is ghost (defending)
            (food_available)                  ; There is food to collect
            (not (is_pacman ?a))              ; We are currently ghost (safe at home)
        )
        :effect (and
            (is_pacman ?a)                    ; We become pacman (enter enemy territory)
        )
    )

    ;; Aggressive attack when enemies are scared (after eating capsule)
    (:action attack_aggressive
        :parameters (?a - current_agent ?e1 - enemy1 ?e2 - enemy2)
        :precondition (and
            (food_available)                  ; Food still available
            (or
                (is_scared ?e1)               ; Enemy 1 is scared, OR
                (is_scared ?e2)               ; Enemy 2 is scared
            )
            (not (is_scared ?a))              ; We are not scared
        )
        :effect (and
            (is_pacman ?a)                    ; Enter enemy territory
        )
    )

    ;; Coordinated attack - both agents attack together
    (:action coordinated_attack
        :parameters (?a - current_agent ?ally - ally ?e1 - enemy1 ?e2 - enemy2)
        :precondition (and
            (food_available)
            (not (is_pacman ?a))
            (not (is_pacman ?e1))
            (not (is_pacman ?e2))
            (near_ally ?a)                    ; Teammate is nearby
            (go_enemy_land ?ally)             ; Teammate is also attacking
        )
        :effect (and
            (is_pacman ?a)
        )
    )

    ;; ============================================
    ;; DEFENSIVE ACTIONS
    ;; ============================================

    ;; Basic defense - chase enemy pacman
    (:action defence
        :parameters (?a - current_agent ?e - enemy)
        :precondition (and
            (is_pacman ?e)                    ; Enemy is invading (is pacman)
            (not (is_pacman ?a))              ; We are ghost (can catch them)
            (not (is_scared ?a))              ; We are not scared
        )
        :effect (and
            (enemy_neutralized ?e)            ; Goal: neutralize the invader
        )
    )

    ;; Patrol when winning - defend territory without chasing
    (:action patrol
        :parameters (?a - current_agent ?e1 - enemy1 ?e2 - enemy2)
        :precondition (and
            (not (is_pacman ?a))              ; We are on home territory
            (not (is_pacman ?e1))             ; Enemies not currently invading
            (not (is_pacman ?e2))
            (winning_gt10)                    ; We have comfortable lead
        )
        :effect (and
            (defend_foods)                    ; Virtual goal state
        )
    )

    ;; ============================================
    ;; ESCAPE/RETURN ACTIONS
    ;; ============================================

    ;; Basic return home action
    (:action go_home
        :parameters (?a - current_agent)
        :precondition (and
            (is_pacman ?a)                    ; We are in enemy territory
            (food_in_backpack ?a)             ; We have food to deposit
        )
        :effect (and
            (not (is_pacman ?a))              ; Return home (become ghost)
            (foods_secured)                   ; Virtual goal: food secured
        )
    )

    ;; Emergency retreat when carrying significant food
    (:action retreat_heavy
        :parameters (?a - current_agent ?e - enemy)
        :precondition (and
            (is_pacman ?a)                    ; In enemy territory
            (food_5_in_backpack ?a)           ; Carrying 5+ food
            (enemy_around ?e ?a)              ; Enemy nearby (danger!)
            (not (is_scared ?e))              ; Enemy is not scared
        )
        :effect (and
            (not (is_pacman ?a))              ; Get home ASAP
            (foods_secured)
        )
    )

    ;; Strategic retreat with light load when enemy close
    (:action retreat_light
        :parameters (?a - current_agent ?e - enemy)
        :precondition (and
            (is_pacman ?a)
            (food_in_backpack ?a)             ; Have some food
            (not (food_5_in_backpack ?a))     ; But less than 5
            (enemy_around ?e ?a)              ; Enemy very close
            (not (is_scared ?e))
        )
        :effect (and
            (not (is_pacman ?a))
            (foods_secured)
        )
    )

    ;; ============================================
    ;; POWER CAPSULE ACTIONS
    ;; ============================================

    ;; Pursue power capsule strategically
    (:action get_capsule
        :parameters (?a - current_agent)
        :precondition (and
            (capsule_available)               ; Capsule exists
            (near_capsule ?a)                 ; We are near it
            (or
                (is_pacman ?a)                ; Already in enemy territory, OR
                (not (food_in_backpack ?a))   ; Not carrying food (safe to go)
            )
        )
        :effect (and
            (is_pacman ?a)                    ; Enter/stay in enemy territory
            (capsule_obtained)                ; Virtual goal: got capsule
        )
    )

    ;; Emergency capsule grab when being chased
    (:action emergency_capsule
        :parameters (?a - current_agent ?e - enemy)
        :precondition (and
            (is_pacman ?a)                    ; In enemy territory
            (capsule_available)               ; Capsule available
            (near_capsule ?a)                 ; Near capsule
            (enemy_around ?e ?a)              ; Enemy hunting us
            (not (is_scared ?e))              ; Enemy is dangerous
        )
        :effect (and
            (capsule_obtained)                ; Grab it for safety!
        )
    )

    ;; ============================================
    ;; SPECIALIZED STRATEGIC ACTIONS
    ;; ============================================

    ;; Deposit and return - deposit food, then go back for more
    (:action deposit_and_return
        :parameters (?a - current_agent ?e1 - enemy1 ?e2 - enemy2)
        :precondition (and
            (is_pacman ?a)                    ; Currently in enemy territory
            (food_3_in_backpack ?a)           ; Carrying moderate amount
            (food_available)                  ; More food available
            (not (enemy_around ?e1 ?a))       ; Enemies not nearby
            (not (enemy_around ?e2 ?a))
            (not (winning_gt10))              ; Not yet winning big
        )
        :effect (and
            (not (is_pacman ?a))              ; Go home to deposit
            (foods_secured)
        )
    )

    ;; Greedy collect - keep collecting when safe
    (:action greedy_collect
        :parameters (?a - current_agent ?e1 - enemy1 ?e2 - enemy2)
        :precondition (and
            (is_pacman ?a)                    ; In enemy territory
            (food_available)                  ; Food available
            (near_food ?a)                    ; Food nearby
            (not (food_10_in_backpack ?a))    ; Not carrying too much
            (or
                (enemy_long_distance ?e1 ?a)  ; Enemies far away
                (enemy_long_distance ?e2 ?a)
            )
        )
        :effect (and
            ; Stay in enemy territory collecting
        )
    )

    ;; Hunt enemy pacman when they're invading
    (:action hunt_invader
        :parameters (?a - current_agent ?e - enemy)
        :precondition (and
            (not (is_pacman ?a))              ; We are ghost
            (is_pacman ?e)                    ; Enemy is pacman (invading)
            (enemy_around ?e ?a)              ; Enemy is in range
            (not (is_scared ?a))              ; We can catch them
        )
        :effect (and
            (enemy_neutralized ?e)            ; Catch the invader!
        )
    )

    ;; Defensive positioning when teammate is attacking
    (:action defensive_position
        :parameters (?a - current_agent ?ally - ally ?e1 - enemy1 ?e2 - enemy2)
        :precondition (and
            (not (is_pacman ?a))              ; We stay home
            (go_enemy_land ?ally)             ; Teammate is attacking
            (not (is_pacman ?e1))
            (not (is_pacman ?e2))
        )
        :effect (and
            (defend_foods)                    ; We defend while ally attacks
        )
    )

    ;; Support ally - go help teammate if they're in trouble
    (:action support_ally
        :parameters (?a - current_agent ?ally - ally ?e - enemy)
        :precondition (and
            (go_enemy_land ?ally)             ; Ally in enemy territory
            (near_ally ?a)                    ; We are near ally
            (is_pacman ?e)                    ; Enemy is invading
            (not (is_pacman ?a))              ; We can help defend
        )
        :effect (and
            (enemy_neutralized ?e)            ; Help protect our territory
        )
    )
)
