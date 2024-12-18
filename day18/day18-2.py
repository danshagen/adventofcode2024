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
obstacles = parse_input(input_file.readlines())
input_file.close()


def find_path(obstacle_num):
    width = 70 + 1
    height = 70 + 1
    start = (0, 0)
    end = (width - 1, height - 1)

    frontier = Queue()
    frontier.put(start)

    came_from = dict()
    came_from[start] = None

    steps = dict()
    steps[start] = 0

    while not frontier.empty():
        current = frontier.get()
        steps_so_far = steps[current]

        neighbours = []
        for direction in [(1, 0), (0, 1), (-1, 0), (0, -1)]:
            x = current[0] + direction[0]
            y = current[1] + direction[1]

            if x < 0 or y < 0 or x >= width or y >= height:
                continue

            if (x, y) in obstacles[:obstacle_num]:
                continue

            neighbours.append((x, y))

        for next in neighbours:
            if next not in came_from:
                frontier.put(next)
                came_from[next] = current
                steps[next] = steps_so_far + 1

    if end not in steps:
        return None
    else:
        return steps[end]


good = 1024
bad = len(obstacles)

while bad - good > 1:
    half = int((bad - good) / 2 + good)
    print(f"step: {half} ", end="")
    result = find_path(half)
    if result is None:
        print("bad")
        bad = half
    else:
        print(f"good ({result})")
        good = half

print(f"bad byte: {obstacles[good:bad]}")
