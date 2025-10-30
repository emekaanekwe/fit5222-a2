(define (problem myTeam)
	(:domain myTeam)
	(:objects
	arm - robot
	cupcake - cupcake
	table - location
	plate - location
	)

	(:init
		(on arm table)
		(on cupcake table)
		(arm-empty)
		(path table plate)
	)
	(:goal 
		(on cupcake plate)
	)
)