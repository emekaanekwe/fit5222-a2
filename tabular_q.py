import matplotlib.pyplot as plt
import random as RD
import time as time
import numpy as np


class Tabular_Q_Learning:
    
    def __init__(self, grid_size):
        # Grid setup
        self.grid_size = grid_size
        self.grid_world = tuple((x, y) for x in range(grid_size) for y in range(grid_size))
        
        # Required: exactly 4 actions (no wait action)
        self.actions = [(-1, 0), (1, 0), (0, -1), (0, 1)]  # north, south, west, east
        
        # Agents setup
        self.num_agents = 4
        self.agent_positions = []
        self.goal_positions = []
        
        # Tracking variables
        self.total_steps = 0
        self.collision_count = 0
        self.success_counts = [0] * self.num_agents
        self.a = None  # Location A
        self.b = None  # Location B
        self.reward_data = []
        
        # Q-tables: [agent_x, agent_y, goal_x, goal_y, action]
        self.q_tables = [np.zeros((grid_size, grid_size, grid_size, grid_size, 4)) 
                        for _ in range(self.num_agents)]
        
        # -conservative Q-learning parameters for collision reduction
        self.epsilon = 1.0
        self.epsilon_min = 0.01
        self.epsilon_decay = 0.9999  # Very conservative decay
        self.alpha = 0.08  # Slightly lower learning rate for stability
        self.gamma = 0.95
        self.epsilon_data = []
        
        # Budget constraints
        self.MAX_STEPS = 1_500_000
        self.MAX_COLLISIONS = 4_000
        self.MAX_TIME_SECONDS = 600  # 10 minutes
        self.start_time = None

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

    def get_action(self, agent_idx):
        """Basic epsilon-greedy action selection"""
        x, y = self.agent_positions[agent_idx]
        gx, gy = self.goal_positions[agent_idx]
        
        if RD.random() < self.epsilon:
            return RD.randint(0, 3)  # Random action
        else:
            return np.argmax(self.q_tables[agent_idx][x, y, gx, gy])

    def check_nearby_opposite_agents(self, agent_idx, test_pos):
        """Check for nearby opposite-direction agents (collision avoidance)"""
        my_goal = self.goal_positions[agent_idx]
        nearby_count = 0
        
        for other_idx, other_pos in enumerate(self.agent_positions):
            if (other_idx != agent_idx and 
                self.goal_positions[other_idx] != my_goal):  # Opposite direction
                dist = abs(other_pos[0] - test_pos[0]) + abs(other_pos[1] - test_pos[1])
                if dist == 0:  # Same position
                    nearby_count += 3  # Heavy penalty for same position
                elif dist == 1:  # Adjacent
                    nearby_count += 1  # Light penalty for adjacent
        
        return nearby_count

    def step(self, agent_idx, action):
        """Execute action with enhanced collision-avoidance rewards"""
        x, y = self.agent_positions[agent_idx]
        gx, gy = self.goal_positions[agent_idx]
        
        # Calculate new position
        dx, dy = self.actions[action]
        new_x, new_y = x + dx, y + dy
        
        # Check bounds
        if 0 <= new_x < self.grid_size and 0 <= new_y < self.grid_size:
            new_pos = (new_x, new_y)
            reward = 0
        else:
            new_pos = (x, y)  # Stay in place if out of bounds
            new_x, new_y = x, y
            reward = -2  # Higher wall penalty
            self.reward_data.append(reward)
        
        # Enhanced reward structure for collision avoidance
        if (new_x, new_y) == (gx, gy):
            reward += 20  # Very high goal reward
            self.reward_data.append(reward)
            # Efficiency bonus - reward faster completion
            dist_to_goal = abs(x - gx) + abs(y - gy)
            reward += max(0, 5 - dist_to_goal)  # Bonus for being close to goal
        # Strong proximity penalty for collision avoidance
        nearby_opposite = self.check_nearby_opposite_agents(agent_idx, new_pos)
        if nearby_opposite > 0:
            reward -= 1.0 * nearby_opposite  # Strong penalty for being near opposite agents
            self.reward_data.append(reward)
        # Q-learning update
        q_current = self.q_tables[agent_idx][x, y, gx, gy, action]
        q_next_max = np.max(self.q_tables[agent_idx][new_x, new_y, gx, gy])
        q_updated = q_current + self.alpha * (reward + self.gamma * q_next_max - q_current)
        self.q_tables[agent_idx][x, y, gx, gy, action] = q_updated
        
        return new_pos, (new_pos == (gx, gy))

    def head_on_collision(self, agent1_idx, agent2_idx, prev_pos1, new_pos1, prev_pos2, new_pos2):
        """Check for head-on collision (A→B vs B→A)"""
        goal1 = self.goal_positions[agent1_idx]
        goal2 = self.goal_positions[agent2_idx]
        
        # Must have opposite goals
        if goal1 == goal2:
            return False
        
        # Check A-B B-A colisions
        if ((prev_pos1 == self.a and new_pos1 == self.b and goal1 == self.b) and
            (prev_pos2 == self.b and new_pos2 == self.a and goal2 == self.a)):
            return True
        if ((prev_pos1 == self.b and new_pos1 == self.a and goal1 == self.a) and
            (prev_pos2 == self.a and new_pos2 == self.b and goal2 == self.b)):
            return True
        
        return False

    def detect_collisions(self, prev_positions, new_positions):
        """Detect head-on collisions"""
        collisions = []
        for i in range(self.num_agents):
            for j in range(i + 1, self.num_agents):
                if self.head_on_collision(i, j, prev_positions[i], new_positions[i],
                                           prev_positions[j], new_positions[j]):
                    collisions.append((i, j))
        return collisions

    def run_episode(self):
        """Run single episode with collision penalty"""
        self.setup_episode()
        goals_reached = [False] * self.num_agents
        steps = 0
        prev_positions = self.agent_positions.copy()
        
        while steps < 25 and not all(goals_reached):
            # Sequential execution in random order
            agent_order = list(range(self.num_agents))
            RD.shuffle(agent_order)
            
            for agent_idx in agent_order:
                if not goals_reached[agent_idx]:
                    action = self.get_action(agent_idx)
                    new_pos, reached = self.step(agent_idx, action)
                    self.agent_positions[agent_idx] = new_pos
                    
                    if reached:
                        goals_reached[agent_idx] = True
                        self.success_counts[agent_idx] += 1
            
            # Check for collisions and apply very strong penalty
            collisions = self.detect_collisions(prev_positions, self.agent_positions)
            if collisions:
                self.collision_count += len(collisions)
                
                # Very strong collision penalty to Q-tables
                for agent_i, agent_j in collisions:
                    # Heavily penalize the state-action that led to collision
                    x, y = prev_positions[agent_i]
                    gx, gy = self.goal_positions[agent_i]
                    # Apply strong penalty to all actions from collision-prone state
                    for a in range(4):
                        self.q_tables[agent_i][x, y, gx, gy, a] -= 1.0
                    
                    # Same for second agent
                    x, y = prev_positions[agent_j] 
                    gx, gy = self.goal_positions[agent_j]
                    for a in range(4):
                        self.q_tables[agent_j][x, y, gx, gy, a] -= 1.0
            
            prev_positions = self.agent_positions.copy()
            steps += 1
            self.total_steps += 1
        
        # Decay epsilon
        self.epsilon = max(self.epsilon * self.epsilon_decay, self.epsilon_min)
        
        # Import for graphing
        self.epsilon_data.append(self.epsilon)

    def display_agents(self,epsiode):
        """Makes a text-based diagram of agent positions"""
        grid = [[' ' for _ in range(self.grid_size)] for _ in range(self.grid_size)]
        # A, B locations
        ax, ay = self.a
        bx, by = self.b
        grid[ax][ay] = 'A'
        grid[bx][by] = 'B' if grid[bx][by] == ' ' else grid[bx][by] + '/B'
        # Agent locations
        for idx, (x,y) in enumerate(self.agent_positions):
            agent = str(idx+1)
            if grid[x][y] == ' ':
                grid[x][y] == agent
            else:
                grid[x][y] += '/' + agent
        print(f"\n" + ("-"*10) + "Agent's Positions at Episode {episode}" + ("-"*10))
        for row in grid:
            print(row)
        return grid
        
    def check_budgets(self, episode):
        """Check if any budget exceeded"""
        # Check time budget
        if time.time() - self.start_time > self.MAX_TIME_SECONDS:
            print(f"\nTime budget exceeded at episode {episode}")
            return True
        
        # Check step budget  
        if self.total_steps >= self.MAX_STEPS:
            print(f"\nStep budget exceeded at episode {episode}")
            return True
            
        # Check collision budget with early warning
        if self.collision_count >= (self.MAX_COLLISIONS - 100):  
            print(f"\nApproaching collision budget at episode {episode}")
            
            
        return False

    def stop_training(self, episode):
        """Stops the training early if achieving excellent performance with low collisions to avoid agents getting stuck"""
        if episode >= 20000:  
            success_rates = [count/episode for count in self.success_counts]
            avg_sr = sum(success_rates) / len(success_rates)
            
            
            if avg_sr >= 0.85 and self.collision_count <= 4000:
                print(f"\nstopping training")
                print(f"Success rate: {avg_sr:.3f},\n Collisions: {self.collision_count}")
                return True
        return False

    def train(self, max_episodes=50000):
        """Main training loop"""
        print("Starting Tabular Q-Learning Training...")
        print("-" * 70)
        
        self.start_time = time.time()
        
        for episode in range(max_episodes):
            self.run_episode()
            
            # Progress report
            if (episode + 1) % 3000 == 0:
                self.display_agents(episode)
                elapsed = time.time() - self.start_time
                success_rates = [count/(episode+1) for count in self.success_counts]
                avg_sr = sum(success_rates) / len(success_rates)
                print(f"Episode {episode+1}: SR={avg_sr:.3f}, Collisions={self.collision_count}, "
                      f"Steps={self.total_steps}, Time={elapsed:.1f}s, Eps={self.epsilon:.4f}")
            
            # Check for early stopping with good performance
            if self.stop_training(episode + 1):
                self.print_results(episode + 1)
                return
            
            # Check budget constraints
            if self.check_budgets(episode + 1):
                self.print_results(episode + 1)
                return
        
        self.print_results(max_episodes)

    def print_results(self, episodes):
        """Comprehensive results reporting"""
        print("\n" + "=" * 70)
        print("FINAL RESULTS")
        print("=" * 70)
        
        elapsed = time.time() - self.start_time
        success_rates = [count/episodes for count in self.success_counts]
        avg_success_rate = sum(success_rates) / len(success_rates)
        collision_margin = self.MAX_COLLISIONS - self.collision_count
        
        print(f"Episodes completed: {episodes}")
        print(f"Training time: {elapsed:.1f} seconds")
        print(f"Total steps: {self.total_steps}")
        print(f"Head-on collisions: {self.collision_count}")
        print(f"Collision budget remaining: {collision_margin}")
        print()
        
        for i, sr in enumerate(success_rates):
            print(f"Agent {i} success rate: {self.success_counts[i]}/{episodes} = {sr:.3f}")
        
        print(f"\nOverall success rate: {avg_success_rate:.3f}")
        print(f"Target success rate: 0.75")
        print(f"Success rate met: {'YES' if avg_success_rate >= 0.75 else 'NO'}")
        print(f"Collision budget met: {'YES' if self.collision_count < self.MAX_COLLISIONS else 'NO'}")
        print(f"Step budget met: {'YES' if self.total_steps <= self.MAX_STEPS else 'NO'}")
        print(f"Time budget met: {'YES' if elapsed <= self.MAX_TIME_SECONDS else 'NO'}")
        
        if (avg_success_rate >= 0.85 and self.collision_count < self.MAX_COLLISIONS and 
            self.total_steps <= self.MAX_STEPS and elapsed <= self.MAX_TIME_SECONDS):
            print("\n*** SUCCESS: All requirements and constraints satisfied! ***")
            if collision_margin >= 1000:
                print(f"*** EXCELLENT: {collision_margin} collisions under budget! ***")
            elif collision_margin >= 500:
                print(f"*** GOOD: {collision_margin} collisions under budget! ***")
        
        # Plot epsilon decay
        plt.figure(figsize=(10, 6))
        plt.plot(self.epsilon_data, label='Epsilon (Exploration Rate)')
        plt.xlabel('Episode')
        plt.ylabel('Log(Epsilon)')
        plt.title(f'Epsilon Decay Over {episodes} Episodes')
        plt.legend()
        plt.grid(True)
        plt.show()
        
        # Plot log epsilon decay
        plt.figure(figsize=(10, 6))
        plt.plot(np.log(self.epsilon_data), label='Epsilon (Exploration Rate)')
        plt.xlabel('Episode')
        plt.ylabel('Log(Epsilon)')
        plt.title(f'Log Epsilon Decay Over {episodes}  Episodes')
        plt.legend()
        plt.grid(True)
        plt.show()
        
        # Plot Agent's success counts individually
        plt.figure(figsize=(10, 6))
        agent_labels = [f"Agent {i}" for i in range(len(self.success_counts))]
        plt.bar(agent_labels, self.success_counts, color='skyblue')
        plt.title("Total Successes Per Agent")
        plt.xlabel("Agent")
        plt.ylabel("Total Successful Deliveries")
        plt.tight_layout()
        plt.grid(axis='y')
        plt.show()


        plt.plot(np.log(self.reward_data))
        # Add x and y axis labels
        plt.xlabel("#episodes")
        plt.ylabel("rewards")
        plt.title("Q table Agent")
        # Show the plot
        plt.show()
        
        return avg_success_rate
    
    
# Execute the final solution
if __name__ == "__main__":
    print("=" * 80)
    print("=" * 80)
    
    agents = Tabular_Q_Learning(grid_size=5)
    agents.train(max_episodes=1000000)
    
    
    print("\n" + "=" * 80)
    print("TRAINING COMPLETED")
    print("=" * 80)
       
    
        