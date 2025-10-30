;; Improved Pacman Capture the Flag Domain
;; This domain extends the baseline with more sophisticated actions and predicates
;; for better strategic decision-making in the Pacman CTF game

(define (domain a2-domain2)

    (:requirements :strips :typing :negative-preconditions )

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
        (enemy_medium_distance ?e - enemy ?a - current_agent)  ; 15 <= Distance < 25
        (enemy_long_distance ?e - enemy ?a - current_agent)    ; Distance >= 25

        ;; ============================================
        ;; FOOD QUANTITY PREDICATES
        ;; ============================================
        ;; Track how much food agent is carrying for risk assessment
        (food_in_backpack_1 ?a - team)        ; Carrying 3+ food

        ;; ============================================
        ;; PROXIMITY PREDICATES
        ;; ============================================
        (near_food ?a - current_agent)        ; Food within 4 squares
        (near_capsule ?a - current_agent)     ; Capsule within 4 squares
        (near_ally ?a - current_agent)        ; Teammate within 4 squares

        ;; ============================================
        ;; SCORE AND WIN STATE PREDICATES
        ;; ============================================
        (winning_gt1)                             ; Team score > enemy score

        ;; ============================================
        ;; POWER-UP STATE PREDICATES
        ;; ============================================
        (is_scared ?x)                        ; Agent is in scared state (from capsule)

        ;; ============================================
        ;; COOPERATIVE/COORDINATION PREDICATES
        ;; ============================================
        ;; These track what teammate is doing for coordination
        (eat_enemy ?a - ally)                 
        (go_home ?a - ally)                   
        (go_enemy_land ?a - ally)          
        (eat_capsule ?a - ally)            
        (eat_food ?a - ally)               

        ;; ============================================
        ;; VIRTUAL GOAL PREDICATES
        ;; ============================================
        ;; These are used as goal states only, not tracked by environment
        (defend_foods)                      
        (foods_secured)                     
        (capsule_obtained)                  
        (enemy_neutralized ?e - enemy)      
    )

    ;; ============================================
    ;; OFFENSIVE ACTIONS
    ;; ============================================

    ;; Basic attack action - go to enemy territory and collect food
    (:action attack
        :parameters (?a - current_agent ?e1 - enemy1 ?e2 - enemy2)
        :precondition (and
            (not (is_pacman ?e1))             
            (not (is_pacman ?e2))             
            (food_available)                  
            (not (is_pacman ?a))              
        )
        :effect (and
            (is_pacman ?a)                    
        )
    )

    ;; Aggressive attack when enemies are scared (after eating capsule)
    (:action attack_aggressive
        :parameters (?a - current_agent ?e1 - enemy1 ?e2 - enemy2)
        :precondition (and
            (food_available)                  
            (not (is_scared ?a))              
        )
        :effect (and
            (is_pacman ?a)                    
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
            (near_ally ?a)                   
            (go_enemy_land ?ally)            
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
            (winning_gt1)                    ; We have comfortable lead
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
            (is_pacman ?a)                    
            (food_in_backpack ?a)             
        )
        :effect (and
            (not (is_pacman ?a))             
            (foods_secured)                  
        )
    )

    ;; Strategic retreat with light load when enemy close
    (:action retreat_light
        :parameters (?a - current_agent ?e - enemy)
        :precondition (and
            (is_pacman ?a)
            (food_in_backpack ?a)           
            (not (food_in_backpack ?a))     
            (enemy_around ?e ?a)            
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
    ;;??? (To be implemented based on further strategic needs)
)
