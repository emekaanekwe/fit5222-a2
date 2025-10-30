class Agents:
    def __init__(self):
        # Required: exactly 4 actions (no wait action)
        self.actions = [(-1, 0), (1, 0), (0, -1), (0, 1)]  # north, south, west, east
        
        # Agents setup
        self.num_agents = 2
        self.agent_positions = []
        self.goal_positions = []

class Config:
    """Sets the buget constraints of the training throughout
    """
    
    def __init__(self):
        self.MAX_STEPS = 1_500_000
        self.MAX_COLLISIONS = 4_000
        self.MAX_TIME_SECONDS = 600  # 10 minutes
        self.start_time = None
        
class Environment:
    """The envronment is designed for a 5x5 grid world
    """
    def __init__(self, grid_size):
        # Grid setup
        self.grid_size = grid_size
        self.grid_world = tuple((x, y) for x in range(grid_size) for y in range(grid_size))
        self.a = None  # Location A
        self.b = None  # Location B
        
class Episodes:
    def __init__(self):
        pass
    def setup_episode(self):
         # Random A and B locations where A != B
         coords = list(self.grid_world)
         self.a = RD.choice(coords)
         self.b = RD.choice(coords)
         while self.a == self.b:
             self.b = RD.choice(coords)
         
         # Agents start at A or B, with opposite as goal
         self.agent_positions = []
         self.goal_positions = []
         for _ in range(self.num_agents):
             start = RD.choice([self.a, self.b])
             goal = self.b if start == self.a else self.a
             self.agent_positions.append(start)
             self.goal_positions.append(goal)
             
import pytest as pyt

from src.agents import tabularq

def test_actions():
    pass

def test_grid():
    pass

def test_theory():
    pass