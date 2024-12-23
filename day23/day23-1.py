
def parse_input(input: str) -> dict:
	connections = dict()
	print("Parsing input...")
	for line in input.split("\n"):
		# ignore empty lines
		if len(line) < 5:
			continue

		a, b = line.split("-")
		for x, y in [(a, b), (b, a)]:
			if x in connections:
				connections[x].append(y)
			else:
				connections[x] = [y]
	return connections

def find_three_connected(input: dict) -> int:
	found = set()
	# only check for connections with computers that start with t
	print("Checking for connections...")
	candidates = [computer for computer in input if computer[0] == 't']
	for first in candidates:
		print(f"checking '{first}'")
		for second in input[first]:
			for third in input[second]:
				if first in input[third]:
					# found
					found.add(frozenset((first, second, third)))
	return len(found)

with open("input.txt", "r") as file:
	text = file.read()

parsed = parse_input(text)
print(find_three_connected(parsed))
