def calc(goal, a):
    found = []
    for B in range(7):
        A = a
        A = (A * 8) + B
        B = B ^ 5
        C = int(A / (2**B))
        B = B ^ 6
        B = B ^ C
        out = B % 8
        if out == goal:
            print(f"found A: {A} B: {B} C: {C} out: {out}")
            found.append(A)
    return found

def find_A(list, A=0):
    if len(list) == 1:
        return calc(list[0], A)[0]
    else:
        possible = calc(list[0], A)
        for a in possible:
            res = find_A(list[1:], a)
            if res is not None:
                return res
        return None

program = [n for n in reversed([2,4,1,5,7,5,1,6,4,1,5,5,0,3,3,0])]
A = find_A(program)
print(f"Register A value: {A}")