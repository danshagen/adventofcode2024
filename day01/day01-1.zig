const std = @import("std");
const expectEqual = std.testing.expectEqual;
const input = @embedFile("input.txt");

pub fn main() !void {}

fn extractLists(string: []const u8, first: []u32, second: []u32) !void {
    // split on space and newline
    var it = std.mem.tokenizeAny(u8, string, " \n");
    var idx: u32 = 0;
    while (it.peek() != null) {
        var token = it.next().?;
        first[idx] = try std.fmt.parseInt(u32, token, 10);

        token = it.next().?;
        second[idx] = try std.fmt.parseInt(u32, token, 10);
        idx += 1;
    }
}

fn totalDistance(first: []u32, second: []u32) u32 {
    // sort arrays into ascending
    std.mem.sort(@TypeOf(first[0]), first, {}, comptime std.sort.asc(@TypeOf(first[0])));
    std.mem.sort(@TypeOf(second[0]), second, {}, comptime std.sort.asc(@TypeOf(second[0])));
    std.debug.print("\nfirst: {any}\nsecond: {any}\n", .{ first, second });
    // sum distances
    var sum: u32 = 0;
    for (first, second) |i, j| {
        const distance: u32 = if (i > j) i - j else j - i;
        std.debug.print("distance between {d} and {d}: {d}\n", .{ i, j, distance });
        sum += distance;
    }
    return sum;
}

test totalDistance {
    const example =
        \\ 3   4
        \\ 4   3
        \\ 2   5
        \\ 1   3
        \\ 3   9
        \\ 3   3
    ;

    var first: [6]u32 = undefined;
    var second: [6]u32 = undefined;

    try extractLists(example, &first, &second);
    try expectEqual([_]u32{ 3, 4, 2, 1, 3, 3 }, first);
    try expectEqual([_]u32{ 4, 3, 5, 3, 9, 3 }, second);

    try expectEqual(11, totalDistance(&first, &second));
}
