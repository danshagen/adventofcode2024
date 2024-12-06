const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    // const input = @embedFile("input.txt");
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
    _ = allocator;
    _ = area;
    return 2;
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
        \\.#......v.
        \\........#.
        \\#.........
        \\......#...
    ;
    const example_area = try makeArrayFromInput(allocator, example);
    try expectEqual(41, try predictRoutePositions(allocator, example_area));
}
