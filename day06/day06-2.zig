const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = @embedFile("input.txt");
    const area = try makeArrayFromInput(allocator, input);
    const obstructions = try howManyGuardObstructions(allocator, area);
    std.debug.print("\n\nPossible obstructions: {d}", .{obstructions});
}

fn makeArrayFromInput(allocator: std.mem.Allocator, input: []const u8) ![]const []const u8 {
    var list = std.ArrayList([]const u8).init(allocator);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try list.append(line);
    }
    return try list.toOwnedSlice();
}

// use ArrayHashMap so that order is kept (important so that the start position is at index 0)
const Positions = std.AutoArrayHashMap(Position, void);
/// Returns the number of positions of the guard when patrolling until off the area.
/// If the guard gets stuck, returns null.
fn predictRoutePositions(allocator: std.mem.Allocator, area: []const []const u8) !?Positions {
    var guard: Guard = undefined;
    var positions = Positions.init(allocator);
    var steps = std.ArrayList(Guard).init(allocator);
    defer steps.deinit();

    // find initial guard position and direction
    for (area, 0..) |row, y| {
        if (std.mem.indexOfScalar(u8, row, '^')) |x| {
            guard = .{ .position = .{ .x = x, .y = y }, .direction = Direction.up };
            break;
        }
        if (std.mem.indexOfScalar(u8, row, '<')) |x| {
            guard = .{ .position = .{ .x = x, .y = y }, .direction = Direction.left };
            break;
        }
        if (std.mem.indexOfScalar(u8, row, '>')) |x| {
            guard = .{ .position = .{ .x = x, .y = y }, .direction = Direction.right };
            break;
        }
        if (std.mem.indexOfScalar(u8, row, 'v')) |x| {
            guard = .{ .position = .{ .x = x, .y = y }, .direction = Direction.down };
            break;
        }
    }
    try positions.put(guard.position, {});
    try steps.append(guard);
    // std.debug.print("\nguard: {any}", .{guard});

    // while the guard has position in the area, move the guard one step
    while (true) {
        const next: Position = switch (guard.direction) {
            Direction.up => Position{ .x = guard.position.x, .y = @subWithOverflow(guard.position.y, 1)[0] },
            Direction.right => Position{ .x = guard.position.x + 1, .y = guard.position.y },
            Direction.down => Position{ .x = guard.position.x, .y = guard.position.y + 1 },
            Direction.left => Position{ .x = @subWithOverflow(guard.position.x, 1)[0], .y = guard.position.y },
        };

        // check if next position is outside of area
        if (next.x >= area.len or next.y >= area[0].len) {
            // std.debug.print("\noutside area! ({any})", .{next});
            break;
        }

        // check for obstacle
        if (area[next.y][next.x] == '#') {
            // std.debug.print("\n# obstacle!", .{});
            guard.direction = @enumFromInt(@addWithOverflow(@intFromEnum(guard.direction), 1)[0]);
            continue;
        }

        // move position
        // std.debug.print("\nstep {any} ({d},{d})", .{ guard.direction, next.x, next.y });
        guard.position = next;

        // update steps and positions
        if (!positions.contains(next)) {
            try positions.put(next, {});
        } else {
            // check if caught in a loop
            for (steps.items) |step| {
                // if position and direction are the same, the guard is caught in a loop
                if (std.meta.eql(step, guard)) {
                    // std.debug.print("\n### caught in a loop!", .{});
                    positions.deinit();
                    return null;
                }
            }
        }
        try steps.append(guard);
    }

    // print area like in example
    // std.debug.print("\nresult:", .{});
    // for (area, 0..) |row, y| {
    //     std.debug.print("\n|", .{});
    //     for (row, 0..) |ch, x| {
    //         const char = if (positions.contains(.{ .x = x, .y = y })) 'X' else ch;
    //         std.debug.print("{c}", .{char});
    //     }
    //     std.debug.print("|", .{});
    // }

    return positions;
}

test predictRoutePositions {
    const allocator = std.testing.allocator;

    const example =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;
    const example_area = try makeArrayFromInput(allocator, example);
    defer allocator.free(example_area);

    var positions = try predictRoutePositions(allocator, example_area);
    defer positions.?.deinit();
    try expectEqual(41, positions.?.count());

    const example_loop =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#.#^.....
        \\........#.
        \\#.........
        \\......#...
    ;
    const example_loop_area = try makeArrayFromInput(allocator, example_loop);
    defer allocator.free(example_loop_area);

    try expectEqual(null, try predictRoutePositions(allocator, example_loop_area));
}

const Position = struct {
    x: usize,
    y: usize,
};

const Direction = enum(u2) { up, right, down, left };

const Guard = struct { position: Position, direction: Direction };

fn howManyGuardObstructions(allocator: std.mem.Allocator, area: []const []const u8) !usize {
    var count: usize = 0;

    // place an obstruction at every point of the guard positions (except the start)
    var positions = try predictRoutePositions(allocator, area);
    defer positions.?.deinit();
    for (positions.?.keys()[1..]) |position| {
        var area_list = std.ArrayList([]u8).init(allocator);
        defer area_list.deinit();
        for (area) |row| {
            const new_row: []u8 = try allocator.alloc(u8, row.len);
            @memcpy(new_row, row);
            try area_list.append(new_row);
        }
        defer {
            for (area_list.items) |array|
                allocator.free(array);
        }

        const new_area = area_list.items;
        new_area[position.y][position.x] = '#';
        var new_positions = try predictRoutePositions(allocator, new_area);
        if (new_positions == null) {
            // got guard to enter loop!
            count += 1;
        } else {
            new_positions.?.deinit();
        }
    }

    return count;
}

test howManyGuardObstructions {
    const allocator = std.testing.allocator;

    const example =
        \\....#.....
        \\.........#
        \\..........
        \\..#.......
        \\.......#..
        \\..........
        \\.#..^.....
        \\........#.
        \\#.........
        \\......#...
    ;
    const example_area = try makeArrayFromInput(allocator, example);
    defer allocator.free(example_area);

    try expectEqual(6, try howManyGuardObstructions(allocator, example_area));
}
