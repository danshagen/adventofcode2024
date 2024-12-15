const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nCalculating sum of GPS coordinates...\n", .{});
    const input = @embedFile("input.txt");
    const parsed = try parseInput(allocator, input);
    const gps_total = calcBoxCoordinateTotal(parsed.map, parsed.movements);
    std.debug.print("\n\nGPS total: {d}", .{gps_total});
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !struct { map: [][]u8, movements: []u8 } {
    // split into map and movements pars
    var parts = std.mem.tokenizeSequence(u8, input, "\n\n");
    const first_part = parts.next().?;
    const second_part = parts.next().?;

    // parse map
    var map = std.ArrayList([]u8).init(allocator);
    var rows = std.mem.tokenizeScalar(u8, first_part, '\n');
    while (rows.next()) |row| {
        var list = std.ArrayList(u8).init(allocator);
        for (row) |ch| {
            if (ch == '#') {
                try list.append('#');
                try list.append('#');
            }
            if (ch == 'O') {
                try list.append('[');
                try list.append(']');
            }
            if (ch == '.') {
                try list.append('.');
                try list.append('.');
            }
            if (ch == '@') {
                try list.append('@');
                try list.append('.');
            }
        }
        try map.append(try list.toOwnedSlice());
    }

    // parse movements
    var movements = std.ArrayList(u8).init(allocator);
    for (second_part) |ch| {
        if (ch != '\n')
            try movements.append(ch);
    }

    return .{ .map = try map.toOwnedSlice(), .movements = try movements.toOwnedSlice() };
}

// move a block: if possible move and return true, else return false
fn move(map: [][]u8, x: usize, y: usize, direction: u8, peek: bool) bool {
    const block = map[y][x];
    const next_x = switch (direction) {
        '^' => x,
        'v' => x,
        '<' => x - 1,
        '>' => x + 1,
        else => el: {
            std.debug.assert(false);
            break :el 0;
        },
    };
    const next_y = switch (direction) {
        '^' => y - 1,
        'v' => y + 1,
        '<' => y,
        '>' => y,
        else => el: {
            std.debug.assert(false);
            break :el 0;
        },
    };

    const next = map[next_y][next_x];
    var neighbour: ?u8 = null;
    var neighbour_next: u8 = '.'; // neighbour_next is the next if we also check the second part of a block
    var neighbour_x: usize = 0;
    if (direction == '^' or direction == 'v') {
        if (block == '[') {
            neighbour = ']';
            neighbour_x = next_x + 1;
            neighbour_next = map[next_y][neighbour_x];
        } else if (block == ']') {
            neighbour = '[';
            neighbour_x = next_x - 1;
            neighbour_next = map[next_y][neighbour_x];
        }
    }

    // if the next (or the block neighbour next, if there) is a wall, cannot move
    if (next == '#' or neighbour_next == '#')
        return false;

    // if the next (or the block neighbour next, if there) is a block, try to move
    if (next == '[' or next == ']') {
        // try to move block
        if (!move(map, next_x, next_y, direction, true)) {
            // could not move next (peeking)
            return false;
        }
        // actually do the move of next
        if (!peek and next != block)
            _ = move(map, next_x, next_y, direction, false);
    }

    if (neighbour_next == '[' or neighbour_next == ']') {
        // check if block neighbour next can also be moved
        if (!move(map, neighbour_x, next_y, direction, true)) {
            // could not move next of block neighbour (peeking)
            return false;
        }
        // actually do the move of neighbour_next
        if (!peek) {
            _ = move(map, neighbour_x, next_y, direction, false);
        }
    }

    if (!peek) {
        // move
        map[next_y][next_x] = block;
        map[y][x] = '.';
        if (neighbour != null) {
            // move the neighbour block
            map[next_y][neighbour_x] = map[y][neighbour_x];
            map[y][neighbour_x] = '.';
        }
    }
    return true;
}

fn calcBoxCoordinateTotal(map: [][]u8, movements: []u8) usize {
    var x: usize = undefined;
    var y: usize = undefined;
    // find robot
    find_robot: for (map, 0..) |rows, _y| {
        for (rows, 0..) |ch, _x| {
            if (ch == '@') {
                x = _x;
                y = _y;
                break :find_robot;
            }
        }
    }

    std.debug.print("\n\ninitials state\n", .{});
    for (map) |row| {
        std.debug.print("{s}\n", .{row});
    }

    for (movements, 1..) |direction, n| {
        if (move(map, x, y, direction, false)) {
            // new positions
            switch (direction) {
                '^' => {
                    y -= 1;
                },
                'v' => {
                    y += 1;
                },
                '<' => {
                    x -= 1;
                },
                '>' => {
                    x += 1;
                },
                else => {
                    std.debug.assert(false);
                },
            }
        }

        // print map
        _ = n;
        // std.debug.print("\n\nstep {d} {c}\n", .{ n, direction });
        // for (map) |row| {
        //     std.debug.print("{s}\n", .{row});
        // }
    }

    // calculate GPS total
    var total: usize = 0;
    for (map, 0..) |row, _y| {
        for (row, 0..) |ch, _x| {
            if (ch == '[') {
                total += 100 * _y + _x;
            }
        }
    }
    return total;
}

test parseInput {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const example =
        \\USE EXAMPLE FROM TEXT
    ;

    const parsed = try parseInput(allocator, example);

    // ADD RESULT FROM EXAMPLE
    try expectEqual(”, calcBoxCoordinateTotal(parsed.map, parsed.movements));
}
