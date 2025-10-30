class Agents:
    def __init__(self):
        # Required: exactly 4 actions (no wait action)
        self.actions = [(-1, 0), (1, 0), (0, -1), (0, 1)]  # north, south, west, east
        
        # Agents setup
        self.num_agents = 4
        self.agent_positions = []
        self.goal_positions = []