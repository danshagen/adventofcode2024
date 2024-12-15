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
        const new_row = try allocator.alloc(u8, row.len);
        @memcpy(new_row, row);
        try map.append(new_row);
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
fn move(map: [][]u8, x: usize, y: usize, direction: u8) bool {
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

    if (next == '#')
        return false;

    if (next == '.') {
        // move
        map[next_y][next_x] = block;
        map[y][x] = '.';
        return true;
    }

    if (next == 'O') {
        // try to move block
        if (move(map, next_x, next_y, direction)) {
            // move
            map[next_y][next_x] = block;
            map[y][x] = '.';
            return true;
        } else {
            return false;
        }
    }

    std.debug.assert(false);
    return false;
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
        if (move(map, x, y, direction)) {
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
            if (ch == 'O') {
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
    try expectEqual(0, calcBoxCoordinateTotal(parsed.map, parsed.movements));
}
