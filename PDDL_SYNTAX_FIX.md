# PDDL Syntax Fix Summary

## Problem
The original domain file had **syntax errors** because PDDL predicate names **cannot start with a number**.

## Error Message
```
domain: syntax error in line 39, '3':
domain definition expected
```

## Root Cause
In PDDL, identifiers (predicate names, action names, etc.) must follow these rules:
- Must start with a **letter** (a-z, A-Z)
- Can contain letters, numbers, hyphens, and underscores
- **Cannot start with a digit**

## Changes Made

### ❌ Invalid Syntax (Original)
```lisp
(3_food_in_backpack ?a - team)
(5_food_in_backpack ?a - team)
(10_food_in_backpack ?a - team)
(20_food_in_backpack ?a - team)
```

### ✅ Valid Syntax (Fixed)
```lisp
(food_3_in_backpack ?a - team)
(food_5_in_backpack ?a - team)
(food_10_in_backpack ?a - team)
(food_20_in_backpack ?a - team)
```

## Updated Locations

### 1. Predicate Definitions (Lines 39-42)
Changed all food quantity predicates to start with "food_"

### 2. Action: `retreat_heavy` (Line 188)
```lisp
; Before: (5_food_in_backpack ?a)
; After:  (food_5_in_backpack ?a)
```

### 3. Action: `retreat_light` (Line 204)
```lisp
; Before: (not (5_food_in_backpack ?a))
; After:  (not (food_5_in_backpack ?a))
```

### 4. Action: `deposit_and_return` (Line 259)
```lisp
; Before: (3_food_in_backpack ?a)
; After:  (food_3_in_backpack ?a)
```

### 5. Action: `greedy_collect` (Line 278)
```lisp
; Before: (not (10_food_in_backpack ?a))
; After:  (not (food_10_in_backpack ?a))
```

### 6. Example Problem File
Updated `a2-problem.pddl` to use correct predicate names:
```lisp
; Before: (3_food_in_backpack a1)
; After:  (food_3_in_backpack a1)
```

## Python Code Updates Needed

When you implement the `get_pddl_state()` function in `myTeam.py`, use these corrected predicate names:

```python
def get_pddl_state(self, gameState):
    objects = []
    initState = []

    # ... object creation ...

    # Food quantity tracking
    foodCarrying = gameState.getAgentState(self.index).numCarrying

    if foodCarrying > 0:
        initState.append(("food_in_backpack", "a1"))

    if foodCarrying >= 3:
        initState.append(("food_3_in_backpack", "a1"))  # ✅ Correct

    if foodCarrying >= 5:
        initState.append(("food_5_in_backpack", "a1"))  # ✅ Correct

    if foodCarrying >= 10:
        initState.append(("food_10_in_backpack", "a1")) # ✅ Correct

    if foodCarrying >= 20:
        initState.append(("food_20_in_backpack", "a1")) # ✅ Correct

    return objects, initState
```

## Alternative Naming Conventions

If you prefer different naming, here are some valid alternatives:

### Option 1: Spelled Out (Most Readable)
```lisp
(three_food_in_backpack ?a - team)
(five_food_in_backpack ?a - team)
(ten_food_in_backpack ?a - team)
(twenty_food_in_backpack ?a - team)
```

### Option 2: Food First (What We Used)
```lisp
(food_3_in_backpack ?a - team)
(food_5_in_backpack ?a - team)
(food_10_in_backpack ?a - team)
(food_20_in_backpack ?a - team)
```

### Option 3: Descriptive
```lisp
(carrying_few_food ?a - team)      ; 3+
(carrying_some_food ?a - team)     ; 5+
(carrying_much_food ?a - team)     ; 10+
(carrying_lots_food ?a - team)     ; 20+
```

## PDDL Naming Rules Reference

### Valid Identifiers ✅
- `my_predicate`
- `action_1`
- `food_3_in_backpack`
- `winning_gt10`
- `enemy-position`
- `AT_HOME`

### Invalid Identifiers ❌
- `3_food` (starts with number)
- `10_items` (starts with number)
- `2nd_place` (starts with number)
- `my predicate` (contains space)
- `action@home` (contains @)

## Testing the Fixed Domain

To verify the domain file is syntactically correct:

### Option 1: Using Python PDDL Parser
```python
from lib_piglet.utils.pddl_solver import pddl_solver

solver = pddl_solver('/path/to/a2-domain.pddl')
print("Domain loaded successfully!")
```

### Option 2: Using Online Validators
- Visit: http://editor.planning.domains/
- Paste your domain file
- Check for syntax errors

### Option 3: Using Piglet in Your Code
```python
# In myTeam.py
def registerInitialState(self, gameState):
    try:
        self.pddl_solver = pddl_solver(BASE_FOLDER+'/a2-domain.pddl')
        print("✅ Domain loaded successfully!")
    except Exception as e:
        print(f"❌ Domain loading failed: {e}")
```

## Summary

✅ **All syntax errors fixed**
✅ **Domain file now PDDL compliant**
✅ **Problem file updated to match**
✅ **Ready to use with Piglet solver**

The domain should now load without errors. You can proceed with implementing the Python side of your agent!
