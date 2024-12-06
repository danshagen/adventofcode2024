const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = @embedFile("input.txt");
    const area = try makeArrayFromInput(allocator, input);
    const steps = try predictRoutePositions(allocator, area);
    std.debug.print("\n\nPositions stood on by guard: {d}", .{steps});
}

fn makeArrayFromInput(allocator: std.mem.Allocator, input: []const u8) ![]const []const u8 {
    var list = std.ArrayList([]const u8).init(allocator);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try list.append(line);
    }
    return try list.toOwnedSlice();
}

fn predictRoutePositions(allocator: std.mem.Allocator, area: []const []const u8) !usize {
    var guard: Guard = undefined;
    var steps = std.AutoHashMap(Position, void).init(allocator);
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
    try steps.put(guard.position, {});
    std.debug.print("\nguard: {any}", .{guard});

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
            std.debug.print("\noutside area! ({any})", .{next});
            break;
        }

        // check for obstacle
        if (area[next.y][next.x] == '#') {
            std.debug.print("\n# obstacle!", .{});
            guard.direction = @enumFromInt(@addWithOverflow(@intFromEnum(guard.direction), 1)[0]);
            continue;
        }

        // move position
        std.debug.print("\nstep {any} ({d},{d})", .{ guard.direction, next.x, next.y });
        guard.position = next;

        // update steps
        if (!steps.contains(next)) {
            try steps.put(next, {});
        }
    }

    // print area like in example
    std.debug.print("\nresult:", .{});
    for (area, 0..) |row, y| {
        std.debug.print("\n|", .{});
        for (row, 0..) |ch, x| {
            const char = if (steps.contains(.{ .x = x, .y = y })) 'X' else ch;
            std.debug.print("{c}", .{char});
        }
        std.debug.print("|", .{});
    }

    return steps.count();
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

    try expectEqual(41, try predictRoutePositions(allocator, example_area));
}

const Position = struct {
    x: usize,
    y: usize,
};

const Direction = enum(u2) { up, right, down, left };

const Guard = struct { position: Position, direction: Direction };
