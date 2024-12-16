const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();
    // const allocator = arena.allocator();

    // std.debug.print("\nCalculating sum of GPS coordinates...\n", .{});
    // const input = @embedFile("input.txt");
    // const parsed = try parseInput(allocator, input);
    // const gps_total = calcBoxCoordinateTotal(parsed.map, parsed.movements);
    // std.debug.print("\n\nGPS total: {d}", .{gps_total});
}

const Position = @Vector(2, i16);

const Map = struct { map: [][]const u8, start: Position, end: Position };

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !Map {
    var start: Position = undefined;
    var end: Position = undefined;
    var map = std.ArrayList([]const u8).init(allocator);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var y: i16 = 0;
    while (lines.next()) |line| {
        for (line, 0..) |ch, x| {
            if (ch == 'S')
                start = .{ @intCast(x), y };
            if (ch == 'E')
                end = .{ @intCast(x), y };
        }
        try map.append(line);
        y += 1;
    }

    return .{ .map = try map.toOwnedSlice(), .start = start, .end = end };
}

fn findBestPath(allocator: std.mem.Allocator, map: [][]const u8, start: Position, end: Position) !usize {
    _ = allocator;
    _ = map;
    _ = start;
    _ = end;
    return 0;
}

test parseInput {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const example =
        \\###############
        \\#.......#....E#
        \\#.#.###.#.###.#
        \\#.....#.#...#.#
        \\#.###.#####.#.#
        \\#.#.#.......#.#
        \\#.#.#####.###.#
        \\#...........#.#
        \\###.#.#####.#.#
        \\#...#.....#.#.#
        \\#.#.#.###.#.#.#
        \\#.....#...#.#.#
        \\#.###.#.#.#.#.#
        \\#S..#.....#...#
        \\###############
    ;

    const parsed = try parseInput(allocator, example);

    try expectEqual(11048, try findBestPath(allocator, parsed.map, parsed.start, parsed.end));
}
