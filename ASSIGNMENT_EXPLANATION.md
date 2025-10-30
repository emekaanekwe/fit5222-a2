# FIT5222 Assignment 2: Pacman Capture the Flag - Complete Guide

## Table of Contents
1. [Overview](#overview)
2. [Environment Setup](#environment-setup)
3. [Game Rules and Mechanics](#game-rules-and-mechanics)
4. [Assignment Architecture](#assignment-architecture)
5. [Step-by-Step Implementation Guide](#step-by-step-implementation-guide)
6. [PDDL Planning Explained](#pddl-planning-explained)
7. [Q-Learning and Low-Level Planning](#q-learning-and-low-level-planning)
8. [Submission Requirements](#submission-requirements)
9. [Marking Rubric Breakdown](#marking-rubric-breakdown)

---

## Overview

### What is This Assignment About?

You are building an **AI controller** for a multiplayer Pacman game where:
- Two teams (Red and Blue) compete against each other
- Each team has **2 agents** that must cooperate
- Goal: Eat food from the opponent's side and bring it back home
- You must defend your own food while attacking

### Key Innovation: Hierarchical Planning

This assignment uses a **two-level planning approach**:

1. **High-Level Planning (PDDL)**: Decides *what* to do (attack, defend, escape, patrol)
2. **Low-Level Planning (Q-Learning/Heuristic Search)**: Decides *how* to do it (which direction to move)

**Analogy**: Think of it like a military general (high-level) deciding "we should attack the enemy base" and the squad leader (low-level) figuring out "we'll go north, then east, avoiding the mines."

---

## Environment Setup

### Step 1: Install Piglet PDDL Solver

```bash
cd piglet-public
# Activate your virtual environment if you use one
git fetch
git checkout pddl_solver
python setup.py install
```

**Why?** The Piglet library provides the PDDL solver that will compute high-level plans for your agents.

### Step 2: Update Pacman Code

```bash
cd pacman-public
git fetch
git reset --hard  # Warning: This removes local changes
git pull
```

**Check**: You should see `staffTeam.py` and `berkeleyTeam.py` in the repository.

### Step 3: Test the Baseline

```bash
python capture.py -r staffTeam.py -b berkeleyTeam.py
```

This runs a game between the staff baseline and Berkeley's implementation. Watch how agents behave!

---

## Game Rules and Mechanics

### Game Environment Characteristics

| Property | Description |
|----------|-------------|
| **Multi-agent** | 2 agents per team must cooperate |
| **Discrete** | Grid-based map, turn-based timesteps |
| **Dynamic** | Environment changes as food is eaten |
| **Partially Observable** | Limited sensing range (5 squares Manhattan distance) |
| **Sequential** | Past actions affect future states |
| **Deterministic** | No randomness in outcomes |
| **Offline** | World pauses while agent thinks |
| **Known** | All rules available in advance |

### Map Layout

```
[RED TERRITORY]  |  [BLUE TERRITORY]
    (Home)       |      (Enemy)
```

- **Ghost Mode**: When agent is on their own side
- **Pacman Mode**: When agent crosses to enemy territory
- Agents spawn as ghosts at their starting positions

### Scoring System

1. **Eat food** on enemy side → food goes to "backpack"
2. **Return home** → deposit food, earn points (1 point per dot)
3. **Get caught** by enemy ghost → lose all food in backpack (no points)
4. **Win condition**: Return all but 2 of opponent's food, OR have most food after 1800 total moves

### Power Capsules

- Eating a capsule makes enemy ghosts **scared** for 40 timesteps
- Scared ghosts can be eaten by Pacman (sends them back to start)
- Strategic advantage for offensive plays

### Observations

- **Full knowledge**: Your own position and teammate position
- **Limited vision**: Enemy positions only if within 5 squares
- **Noisy distance**: Always get distance reading to all agents (±6 error)

---

## Assignment Architecture

### File Structure

```
pacman-public/
├── capture.py           # Simulator entry point
├── myTeam.py           # YOUR IMPLEMENTATION (modify this)
├── myTeam.pddl         # YOUR PDDL DOMAIN (modify this)
├── staffTeam.py        # Baseline to beat
├── berkeleyTeam.py     # UC Berkeley baseline
├── captureAgents.py    # Base agent class
├── game.py             # Game state definitions
└── layouts/            # Map files
```

### Main Classes and Functions

#### In `myTeam.py`:

**Key Functions You'll Work With:**

1. **`createTeam()`**
   - Creates two agents for your team
   - Default: Both agents use `MixedAgent` class
   - You can customize to use different agent types

2. **`chooseAction(gameState)`** ⭐ MOST IMPORTANT
   - Called every timestep for each agent
   - Returns: "North", "South", "East", "West", or "Stop"
   - Implements the planning workflow

3. **`get_pddl_state(gameState)`**
   - Converts game state to PDDL predicates
   - Returns: (objects, init_states)
   - Modify to track additional game information

4. **`getGoals(objects, initState)`**
   - Selects which high-level goal to pursue
   - Returns: (positive_goals, negative_goals)
   - Implement priority logic here

5. **`getHighLevelPlan()`**
   - Solves PDDL problem
   - Returns: List of high-level actions
   - Usually don't modify this

6. **`getLowLevelPlanQL(gameState, highLevelAction)`**
   - Q-learning based low-level planning
   - Returns: List of move directions
   - Implement feature extraction and rewards

7. **`getLowLevelPlanHS(gameState, highLevelAction)`**
   - Heuristic search based low-level planning
   - Currently unimplemented (you can implement it)
   - Returns: List of move directions

---

## Step-by-Step Implementation Guide

### Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Game Timestep Loop                      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
          ┌──────────────────────────────────────┐
          │  1. CHOOSE HIGH-LEVEL GOAL           │
          │  - Check game state                  │
          │  - Evaluate priorities               │
          │  - Select goal (attack/defend/etc)   │
          └──────────────────────────────────────┘
                            │
                            ▼
          ┌──────────────────────────────────────┐
          │  2. GENERATE/REUSE HIGH-LEVEL PLAN   │
          │  - Convert state to PDDL             │
          │  - Solve PDDL problem                │
          │  - Get sequence of actions           │
          └──────────────────────────────────────┘
                            │
                            ▼
          ┌──────────────────────────────────────┐
          │  3. GENERATE/REUSE LOW-LEVEL PLAN    │
          │  - Given high-level action           │
          │  - Compute concrete moves            │
          │  - Use Q-learning or A* search       │
          └──────────────────────────────────────┘
                            │
                            ▼
          ┌──────────────────────────────────────┐
          │  4. EXECUTE NEXT MOVE                │
          │  - Return "North"/"South"/etc        │
          │  - Advance game state                │
          └──────────────────────────────────────┘
                            │
                            ▼
                     [Next Timestep]
```

### Phase 1: Understanding the Baseline (Week 1-2)

**What to do:**
1. Run the baseline implementation and observe behavior
2. Read through `chooseAction()` line by line
3. Understand the PDDL model in `myTeam.pddl`
4. Observe what predicates are being used

**Key Questions to Answer:**
- What high-level actions exist? (attack, defence, go_home, patrol)
- What triggers replanning?
- What features does Q-learning use?
- What are the weaknesses? (Hint: Run games and watch failures)

### Phase 2: Improve PDDL High-Level Planning (Week 3-4)

#### Strategy 1: Add New Predicates

**Current "Basic" Predicates:**
```lisp
(enemy_around ?e - enemy ?a - team)
(is_pacman ?x)
(food_in_backpack ?a - team)
(food_available)
```

**Add "Advanced" Predicates (already listed but not used):**
```lisp
(food_3_in_backpack ?a - team)
(near_food ?a - current_agent)
(near_capsule ?a - current_agent)
(winning)
(is_scared ?x)
```

**How to use them:**
1. In `get_pddl_state()`, add logic to collect these states from `gameState`
2. Use them in action preconditions and effects

**Example**: Add a new action that only activates when carrying 3+ food:

```lisp
(:action retreat_with_food
    :parameters (?a - current_agent)
    :precondition (and
        (is_pacman ?a)
        (food_3_in_backpack ?a)
    )
    :effect (and
        (not (is_pacman ?a))
    )
)
```

#### Strategy 2: Create New High-Level Actions

**Ideas:**
- `pursue_capsule`: Go after power capsules strategically
- `aggressive_attack`: Attack while enemy ghost is scared
- `coordinated_attack`: Both agents attack together
- `strategic_defend`: Defend specific areas based on enemy behavior

**Template:**
```lisp
(:action your_action_name
    :parameters (?a - current_agent ?e - enemy)
    :precondition (and
        ; What must be true to use this action?
    )
    :effect (and
        ; What changes after this action?
    )
)
```

#### Strategy 3: Improve Goal Selection

**Current baseline**: Simple priority-based selection

**Improvements:**
- Consider game time remaining
- Consider score differential
- Consider teammate's current action
- Adapt strategy dynamically

**In `getGoals()`:**
```python
def getGoals(self, objects, initState):
    # Check if winning by large margin
    if ("winning_gt10",) in initState:
        return self.goalPatrol(objects, initState)

    # Check if teammate is attacking
    if teammate_is_attacking:
        return self.goalDefend(objects, initState)

    # Default to balanced strategy
    return self.goalScoring(objects, initState)
```

### Phase 3: Improve Low-Level Planning (Week 5-6)

#### Option A: Enhance Q-Learning

**Current Features (Offensive):**
```python
'closest-food': -1           # Distance to nearest food
'bias': 1                     # Constant bias
'#-of-ghosts-1-step-away': -100
'successorScore': 100
'chance-return-food': 10
```

**Better Features to Add:**
1. **Distance to home** (when carrying food)
2. **Distance to nearest capsule**
3. **Number of scared ghosts nearby**
4. **Food density in area** (more food = better target)
5. **Teammate distance** (avoid clustering)
6. **Dead-end danger** (avoid getting trapped)

**Template for new feature:**
```python
def getOffensiveFeatures(self, gameState, action):
    features = {}
    successor = self.getSuccessor(gameState, action)

    # Example: Distance to home
    myPos = successor.getAgentState(self.index).getPosition()
    homeDistance = self.getMazeDistance(myPos, self.startPosition)
    features['distance-to-home'] = homeDistance

    return features
```

**Improve Reward Function:**
```python
def getOffensiveReward(self, gameState, nextGameState):
    reward = 0

    # Positive: Successfully deposited food
    if food_deposited:
        reward += 100

    # Negative: Got caught by ghost
    if got_caught:
        reward -= 50

    # Small negative: Each timestep (encourages efficiency)
    reward -= 1

    return reward
```

**Training Process:**
1. Set `self.training = True`
2. Run many games: `python capture.py -r myTeam.py -b staffTeam.py -n 100 -Q`
3. Watch weights converge
4. Set `self.training = False` before submission

#### Option B: Implement Heuristic Search

**Advantages:**
- No training required
- Guarantees optimal path (if using A*)
- Easier to debug

**Implementation in `getLowLevelPlanHS()`:**

```python
def getLowLevelPlanHS(self, gameState, highLevelAction):
    # 1. Determine target based on high-level action
    if highLevelAction == "attack":
        target = self.getNearestFood(gameState)
    elif highLevelAction == "defence":
        target = self.getNearestInvader(gameState)
    elif highLevelAction == "go_home":
        target = self.getHomePosition()

    # 2. Run A* search to target
    path = self.aStarSearch(gameState, target)

    # 3. Convert path to action list
    return self.pathToActions(path)
```

**A* Search Template:**
```python
def aStarSearch(self, gameState, goal):
    from util import PriorityQueue

    frontier = PriorityQueue()
    start = gameState.getAgentPosition(self.index)
    frontier.push((start, []), 0)
    explored = set()

    while not frontier.isEmpty():
        position, path = frontier.pop()

        if position == goal:
            return path

        if position in explored:
            continue
        explored.add(position)

        for action in self.getLegalActions(gameState):
            successor = self.getSuccessor(gameState, action)
            newPos = successor.getAgentPosition(self.index)
            newPath = path + [action]

            g_cost = len(newPath)
            h_cost = self.getMazeDistance(newPos, goal)
            f_cost = g_cost + h_cost

            frontier.push((newPos, newPath), f_cost)

    return []  # No path found
```

### Phase 4: Agent Coordination (Week 7-8)

**Challenge**: Make your two agents work together, not independently

**Coordination Strategies:**

1. **Role Assignment**
   - Agent 0: Always offensive
   - Agent 1: Always defensive
   - OR: Dynamic role switching

2. **Shared Information**
   ```python
   # Use class variables to share between agents
   MixedAgent.CURRENT_ACTION[self.index] = "attacking"
   teammate_action = MixedAgent.CURRENT_ACTION[teammate_index]
   ```

3. **Cooperative Predicates** (in PDDL)
   ```lisp
   (eat_food ?a - ally)
   (go_home ?a - ally)
   ```

4. **Coordinated Attacks**
   - Both agents attack when enemy is defending with only 1 ghost
   - One agent draws ghost away while other scores

### Phase 5: Testing and Refinement (Week 9-10)

**Test Against:**
1. `staffTeam.py` - Must beat convincingly (28/49 games)
2. `berkeleyTeam.py` - Good benchmark
3. Different map layouts (use `-l` flag)
4. Random maps (`-l RANDOM`)

**Debugging Tips:**
1. Use print statements to trace decisions
2. Watch replays to see what went wrong
3. Test individual components separately
4. Use `-q` flag for fast testing without graphics

---

## PDDL Planning Explained

### What is PDDL?

**PDDL** = Planning Domain Definition Language

**Purpose**: Describe planning problems in a standardized way so automated planners can solve them.

### PDDL Structure

#### Domain File (`myTeam.pddl`)

Defines the "rules of the world":
- What types of objects exist?
- What properties can be true/false?
- What actions are possible?
- What are the preconditions and effects of actions?

#### Problem File (Generated Programmatically)

Defines a specific scenario:
- What objects exist right now?
- What is true in the current state?
- What do we want to achieve?

### PDDL Components Explained

#### 1. Requirements

```lisp
(:requirements :strips :typing :negative-preconditions)
```

- `:strips` - Basic actions with preconditions and effects
- `:typing` - Objects have types (enemy, team, etc.)
- `:negative-preconditions` - Can use (not ...) in preconditions

#### 2. Types

```lisp
(:types
    enemy team - object
    enemy1 enemy2 - enemy
    ally current_agent - team
)
```

**Hierarchy:**
```
object
├── enemy
│   ├── enemy1
│   └── enemy2
└── team
    ├── ally
    └── current_agent
```

**Why?** Allows actions to work on categories of objects.

#### 3. Predicates

```lisp
(:predicates
    (is_pacman ?x)                      ; Boolean property
    (food_in_backpack ?a - team)        ; Property of team agent
    (enemy_around ?e - enemy ?a - team) ; Relationship between two objects
)
```

**Closed World Assumption**: If not stated to be true, it's false.

#### 4. Actions

```lisp
(:action attack
    :parameters (?a - current_agent ?e1 - enemy1 ?e2 - enemy2)
    :precondition (and
        (not (is_pacman ?e1))    ; Enemy 1 is ghost
        (not (is_pacman ?e2))    ; Enemy 2 is ghost
        (food_available)         ; There's food to get
    )
    :effect (and
        (not (food_available))   ; Food gets taken
    )
)
```

**How it works:**
1. **Parameters**: Variables that will be bound to actual objects
2. **Precondition**: Must be satisfied for action to be applicable
3. **Effect**: What changes after action executes

### Example: Adding a New Action

**Scenario**: Create action to eat a power capsule

```lisp
(:action eat_capsule
    :parameters (?a - current_agent)
    :precondition (and
        (is_pacman ?a)           ; Must be in enemy territory
        (near_capsule ?a)        ; Capsule is nearby
        (capsule_available)      ; Capsule exists
    )
    :effect (and
        (not (capsule_available)) ; Capsule consumed
        ; Note: Being scared is handled by environment
    )
)
```

**Then in Python** (`get_pddl_state()`):

```python
# Check if capsule is nearby
capsules = self.getCapsules(gameState)
myPos = gameState.getAgentPosition(self.index)
for capsule in capsules:
    if self.getMazeDistance(myPos, capsule) <= CLOSE_DISTANCE:
        initState.append(("near_capsule", "a1"))
        break

if len(capsules) > 0:
    initState.append(("capsule_available",))
```

---

## Q-Learning and Low-Level Planning

### Q-Learning Basics

**Goal**: Learn Q(s, a) = expected future reward from taking action 'a' in state 's'

**Update Rule:**
```
Q(s,a) ← Q(s,a) + α[R(s,a,s') + γ·max Q(s',a') - Q(s,a)]
                     └─────────┘   └────────────┘
                       reward     future value
```

**Approximate Q-Learning:**
```
Q(s,a) = w₁·f₁(s,a) + w₂·f₂(s,a) + ... + wₙ·fₙ(s,a)
```

Where:
- **w**: Weights (learned)
- **f**: Features (designed by you)

### Feature Design Principles

**Good Features:**
1. **Normalized** - Values in similar ranges
2. **Smooth** - Small state changes = small feature changes
3. **Informative** - Correlate with reward
4. **Independent** - Not redundant

**Bad Features:**
- Binary cliff features (sudden jumps)
- Unnormalized distances on varying map sizes
- Duplicate information

### Example Feature Function

```python
def getOffensiveFeatures(self, gameState, action):
    features = {}
    successor = self.getSuccessor(gameState, action)
    myState = successor.getAgentState(self.index)
    myPos = myState.getPosition()

    # Feature 1: Distance to nearest food (normalized)
    foodList = self.getFood(successor).asList()
    if len(foodList) > 0:
        minDistance = min([self.getMazeDistance(myPos, food)
                          for food in foodList])
        features['closest-food'] = minDistance / (walls.width * walls.height)

    # Feature 2: Number of nearby ghosts
    enemies = [successor.getAgentState(i) for i in self.getOpponents(successor)]
    ghosts = [a for a in enemies if not a.isPacman and a.getPosition()]
    features['#-of-ghosts-1-step-away'] = sum([
        1 for g in ghosts if self.getMazeDistance(myPos, g.getPosition()) == 1
    ])

    # Feature 3: Food carrying risk
    foodCarrying = myState.numCarrying
    distHome = self.getMazeDistance(myPos, self.startPosition)
    features['carrying-risk'] = foodCarrying * distHome / 100.0

    return features
```

### Reward Design Principles

**Guidelines:**
1. **Dense rewards** better than sparse
2. **Consistent** with long-term goal
3. **Avoid contradictions**

**Example: Offensive Rewards**

```python
def getOffensiveReward(self, gameState, nextState):
    reward = -1  # Base cost for each step (encourages efficiency)

    # Food collected
    prevFood = self.getFood(gameState).asList()
    currFood = self.getFood(nextState).asList()
    if len(currFood) < len(prevFood):
        reward += 10  # Got food!

    # Food deposited (returned home)
    prevScore = self.getScore(gameState)
    currScore = self.getScore(nextState)
    if currScore > prevScore:
        reward += 50 * (currScore - prevScore)  # Major reward!

    # Got caught
    prevPos = gameState.getAgentPosition(self.index)
    currPos = nextState.getAgentPosition(self.index)
    if currPos == self.startPosition and prevPos != self.startPosition:
        reward -= 30  # Penalty for getting caught

    return reward
```

### Training Your Agent

```bash
# Training mode: Many fast games
python capture.py -r myTeam.py -b staffTeam.py -n 100 -Q -l layouts/RANDOM

# Monitor: Watch weights change
# Weights should converge (stop changing much)

# Test mode: Visual games
python capture.py -r myTeam.py -b staffTeam.py
```

**Important**: Set `self.training = False` before submitting!

---

## Submission Requirements

### What to Submit

#### 1. Code Submission (to Moodle)

**File**: `lastname_studentid_pacman.zip`

**Contents**: Copy entire `pacman` folder to a folder named `src`, then zip it.

```bash
cp -r pacman src
zip -r Chen_123456_pacman.zip src/
```

#### 2. Report (to Moodle)

**File**: `lastname_studentid_report_pacman.pdf`

**Required Sections:**

1. **Introduction** (1 page)
   - Overview of approach
   - Key innovations

2. **High-Level Planning** (2-3 pages)
   - PDDL model description
   - Predicates used
   - Actions designed
   - Goal selection strategy
   - Pseudo-code

3. **Low-Level Planning** (2-3 pages)
   - Approach chosen (Q-learning or heuristic search)
   - If Q-learning: Features, rewards, training process
   - If heuristic search: Search algorithm, heuristic function
   - Pseudo-code

4. **Coordination Strategy** (1-2 pages)
   - How agents communicate
   - Role assignment
   - Examples of coordination

5. **Analysis** (2-3 pages)
   - Strengths and weaknesses
   - Complexity analysis
   - Comparison of different strategies you tried

6. **Experiments** (2-3 pages)
   - Win rates against baselines
   - Performance on different maps
   - Training curves (if using Q-learning)
   - Statistical analysis

7. **Reflection** (1 page)
   - What worked well
   - What didn't work
   - Future improvements

8. **References**
   - Cite PDDL planning papers
   - Cite Q-learning/reinforcement learning papers
   - Cite any other sources

**Total**: ~10-15 pages

#### 3. Contest Server Submission

**Must submit to leaderboard for marks!**

Follow instructions in "Assignment 2 Contest Submission Instruction.pdf"

**Deadline**: 11:55 PM Friday, October 31, 2025 (Week 13)

---

## Marking Rubric Breakdown

### Criterion 1: Competition (33.3%)

| Grade | Requirement |
|-------|-------------|
| N (0%) | Lose to `staffTeam.py` |
| P (50-59%) | Beat staff team, get 25-49% of victory points |
| C (60-69%) | Beat staff team, get 50-74% of victory points |
| D (70-79%) | Beat staff team, get 75-100% of victory points |
| HD (80-100%) | Top tier on leaderboard |

**Victory Points**:
- Win 28+ out of 49 games against opponent: 3 points
- Tie (win <28, lose <28): 0.5 points
- Lose 28+ games: 0 points

**Strategy**: Submit early and often! Test against many opponents.

### Criterion 2: Implementation (33.3%)

| Grade | Requirements |
|-------|-------------|
| **N** | Only changed parameter values |
| **P** | Fixed some bugs in baseline |
| **C** | - New PDDL actions using more predicates<br>- OR: New goal functions |
| **D** | - Above PLUS:<br>- Alternative goal prioritization<br>- Improved low-level planner (features/rewards/heuristics) |
| **HD** | - Above PLUS:<br>- Custom low-level strategies for each high-level action<br>- Agent coordination<br>- OR: Completely new approach |

**Key**: Show progression of complexity!

### Criterion 3: Report Description (23.3%)

| Grade | Requirements |
|-------|-------------|
| **N** | Incomplete, missing justification |
| **P** | Basic description with pseudo-code |
| **C** | - Above PLUS:<br>- Algorithmic analysis<br>- Motivation for choices<br>- Links to course material |
| **D** | - Above PLUS:<br>- Reflection comparing 2-3 strategies<br>- Discussion of advantages/disadvantages |
| **HD** | - Above PLUS:<br>- Detailed experiments with statistics<br>- Win rate analysis<br>- Runtime analysis |

**Key**: Justify every decision with theory and experiments!

### Criterion 4: Communication (10%)

| Grade | Quality |
|-------|---------|
| **N** | Hard to follow, inaccurate |
| **P** | Logical narrative, some structure |
| **C** | Clear narrative, well-structured, some supporting materials |
| **D** | Very clear, well-structured, good supporting materials |
| **HD** | Expertly written, scientific report style, excellent diagrams |

**Key**: Write like a research paper!

---

## Tips for Success

### Time Management

**Week 1-2**: Understand baseline, read documentation
**Week 3-4**: Improve PDDL model
**Week 5-6**: Improve low-level planning
**Week 7-8**: Add coordination
**Week 9-10**: Test, refine, write report
**Week 11-12**: Final testing, report polish
**Week 13**: Submit!

### Common Pitfalls

1. **Leaving everything to last minute** - Competition server may be slow/down
2. **Not testing on different maps** - Your agent may overfit to one map
3. **Forgetting to set `training = False`** - Random actions in competition!
4. **Not documenting experiments** - Can't write report without data
5. **Overly complex first attempt** - Start simple, iterate!

### Success Strategies

1. **Submit early to leaderboard** - See where you stand
2. **Watch replays** - Learn from failures
3. **Keep a log** - Document what you try and results
4. **Test incrementally** - Don't change everything at once
5. **Use version control** - Git is your friend
6. **Ask on Ed** - Discuss strategies (not code!)

---

## Resources

### Official Resources
- Planning.wiki: https://planning.wiki/
- PDDL Guide: https://planning.wiki/guide/whatis/pddl
- Assignment PDFs in Moodle

### Recommended Reading
- Russell & Norvig, "Artificial Intelligence: A Modern Approach" (Ch 10: Classical Planning, Ch 21: Reinforcement Learning)
- Sutton & Barto, "Reinforcement Learning: An Introduction"

### Tools
- Visual Studio Code with PDDL extension
- Python debugger (pdb)
- Matplotlib for plotting training curves

---

## Summary Checklist

Before submission, ensure:

- [ ] Beat `staffTeam.py` convincingly (28/49 games)
- [ ] Tested on multiple map layouts
- [ ] `training = False` in submitted code
- [ ] PDDL model has meaningful improvements
- [ ] Low-level planning works reliably
- [ ] Agents coordinate in some way
- [ ] Report has all required sections
- [ ] Report includes experiments with data
- [ ] Report includes proper references
- [ ] Code is clean and commented
- [ ] Submitted to Moodle: code.zip and report.pdf
- [ ] Submitted to contest server
- [ ] Submitted before deadline!

---

## Good Luck!

This assignment is challenging but rewarding. You're building a real AI system that combines classical planning (PDDL) with modern learning (Q-learning). Take it step by step, test frequently, and don't hesitate to ask for help.

**Remember**: The goal is not just to win, but to understand the AI techniques deeply and demonstrate that understanding in your report.

**Key Insight**: High-level planning (PDDL) handles strategic decisions in a principled, interpretable way. Low-level planning (Q-learning/search) handles the complexity of execution in a detailed, reactive way. Together, they create a powerful hierarchical AI system!
