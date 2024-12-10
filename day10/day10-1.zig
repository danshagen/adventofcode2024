const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    // var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    // defer arena.deinit();
    // const allocator = arena.allocator();
    // const input = @embedFile("input.txt");

    // var antinodes = std.AutoHashMap(Position, void).init(allocator);

    // std.debug.print("Calculating all antinodes...", .{});
    // const map = try parseInput(allocator, input);
    // try getAllAntinodes(allocator, map, &antinodes);
    // std.debug.print("\n\nNumber of antinodes: {d}", .{antinodes.count()});
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

test parseInput {
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
    const map = parseInput(allocator, example);
    std.debug.print("{any}", .{map});
}
