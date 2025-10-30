class Config:
    """Sets the buget constraints of the training throughout
    """
    
    def __init__(self):
        self.MAX_STEPS = 1_500_000
        self.MAX_COLLISIONS = 4_000
        self.MAX_TIME_SECONDS = 600  # 10 minutes
        self.start_time = None