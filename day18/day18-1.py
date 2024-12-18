from queue import Queue


def parse_input(lines):
    fallen = []
    for line in lines:
        if len(line) > 1:
            x, y = line.split(",")
            pos = (int(x), int(y))
            fallen.append(pos)
    return fallen


input_file = open("input.txt", "r")
obstacles = parse_input(input_file.readlines())[:1024]
input_file.close()
print(f"{obstacles=}")

width = 70 + 1
height = 70 + 1
frontier = Queue()
start = (0, 0)
end = (width - 1, height - 1)
frontier.put(start)
came_from = dict()
came_from[start] = None
steps = dict()
steps[start] = 0


print("")
for y in range(height):
    print("")
    for x in range(width):
        if (x, y) in obstacles:
            print("#", end="")
        else:
            print(".", end="")

while not frontier.empty():
    current = frontier.get()
    print(f"\ncurrent: {current} ", end="")
    steps_so_far = steps[current]

    neighbours = []
    for direction in [(1, 0), (0, 1), (-1, 0), (0, -1)]:
        x = current[0] + direction[0]
        y = current[1] + direction[1]

        if x < 0 or y < 0 or x >= width or y >= height:
            continue

        if (x, y) in obstacles:
            continue

        neighbours.append((x, y))

    print(f"neighbours: {neighbours} ", end="")

    for next in neighbours:
        if next not in came_from:
            frontier.put(next)
            came_from[next] = current
            steps[next] = steps_so_far + 1


path = [end]
node = end
while node != start:
    print(node)
    node = came_from[node]
    path.append(node)


print("")
for y in range(height):
    print("")
    for x in range(width):
        if (x, y) in obstacles:
            print("#", end="")
        elif (x, y) in path:
            print("O", end="")
        else:
            print(".", end="")

print(f"\nsteps: {steps[end]}")
