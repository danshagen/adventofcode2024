const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const input = @embedFile("input.txt");

    std.debug.print("\nCalculating all trails to peaks...", .{});
    const map = try parseInput(allocator, input);
    const peaks = try calcTrailheadScores(allocator, map);
    std.debug.print("\npeaks: {d}", .{peaks});
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![][]u8 {
    var map = std.ArrayList([]u8).init(allocator);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var row = std.ArrayList(u8).init(allocator);
        for (line) |ch| {
            const height: u8 = ch - '0';
            try row.append(height);
        }
        try map.append(try row.toOwnedSlice());
    }
    return try map.toOwnedSlice();
}

const Position = struct {
    x: i32,
    y: i32,
};

fn calcTrailheadScores(allocator: std.mem.Allocator, map: [][]u8) !usize {
    var score: usize = 0;
    // for all trailheads
    for (map, 0..) |row, y| {
        for (row, 0..) |height, x| {
            if (height == 0) {
                // trailhead
                var peaks = std.AutoHashMap(Position, void).init(allocator);
                try findTrails(&peaks, map, .{ .x = @intCast(x), .y = @intCast(y) });
                score += peaks.count();
            }
        }
    }
    return score;
}

test calcTrailheadScores {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const example =
        \\89010123
        \\78121874
        \\87430965
        \\96549874
        \\45678903
        \\32019012
        \\01329801
        \\10456732
    ;

    const map = try parseInput(allocator, example);
    try expectEqual(36, try calcTrailheadScores(allocator, map));
}

fn findTrails(peaks: *std.AutoHashMap(Position, void), map: [][]u8, start: Position) !void {
    const height = map[@intCast(start.y)][@intCast(start.x)];
    // std.debug.print("\n{d},{d}: {d}", .{ start.x, start.y, height });
    // check all directions
    const directions: [4]Position = .{ .{ .x = 0, .y = 1 }, .{ .x = 1, .y = 0 }, .{ .x = -1, .y = 0 }, .{ .x = 0, .y = -1 } };
    for (directions) |direction| {
        const new_position = .{
            .x = start.x + direction.x,
            .y = start.y + direction.y,
        };
        // continue with next position if not a valid position
        if (new_position.x < 0 or new_position.y < 0 or new_position.x >= map[0].len or new_position.y >= map.len)
            continue;

        const new_height = map[@intCast(new_position.y)][@intCast(new_position.x)];
        // if one higher, found a trail
        if (new_height > height and new_height - height == 1) {
            if (new_height == 9) {
                // found peak
                try peaks.*.put(new_position, {});
                // std.debug.print("\npeak: {d},{d}: {d}", .{ new_position.x, new_position.y, new_height });
            } else {
                // recurse
                try findTrails(peaks, map, new_position);
            }
        }
    }
}
