import collections


def simulate_wires(input: str) -> int:
	first_part, second_part = input.split("\n\n")

	# intial values are put into calculated
	calculated = dict()
	for line in first_part.split("\n"):
		if len(line) <= 1:
			continue
		name, value = line.split(": ")
		value = int(value)
		calculated[name] = value

	print("initial values:")
	for name in calculated:
		print(f"   {name}: {calculated[name]}")

	# calculations that are to be done are put into a queue
	calculations = collections.deque()
	for line in second_part.split("\n"):
		if len(line) <= 1:
			continue
		a, operation, b, _, result = line.split()
		calculations.append((a, operation, b, result))

	print("\ncalculations:")
	for a, operation, b, result in calculations:
		print(f"   calculate: {a} {operation} {b} -> {result}")
	print("")

	# calculate
	while len(calculations) > 0:
		a, operation, b, result = calculations.popleft()
		print(f"calculate: {a} {operation} {b} -> {result}... ", end="")

		# check if it is possible to calculate
		if a not in calculated or b not in calculated:
			# try again later
			print(f"cannot calculate yet, queue again.")
			calculations.append((a, operation, b, result))
			continue

		# do calculations
		if operation == "AND":
			calculated[result] = calculated[a] & calculated[b]
		elif operation == "XOR":
			calculated[result] = calculated[a] ^ calculated[b]
		elif operation == "OR":
			calculated[result] = calculated[a] | calculated[b]

		print(calculated[result])

	# find all results with z in their name
	print("\nCalculate result decimal...")
	result = 0
	for name in calculated:
		if name[0] == 'z':
			print(f"   {name}: {calculated[name]}")
			bit_pos = int(name[1:])
			result += calculated[name] << bit_pos

	print(f"\nresult: {result}")
	return result

with open("input.txt", "r") as file:
	text = file.read()
simulate_wires(text)
