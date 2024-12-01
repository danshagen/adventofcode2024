const std = @import("std");
const expectEqual = std.testing.expectEqual;
const input = @embedFile("input.txt");

pub fn main() !void {
    var first: [1000]u32 = undefined;
    var second: [1000]u32 = undefined;

    std.debug.print("extracting lists...\n", .{});
    try extractLists(input, &first, &second);

    std.debug.print("calculating similarity score...\n", .{});
    const result = similarityScore(&first, &second);
    std.debug.print("similarity score: {d}\n", .{result});
}

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

test extractLists {
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
}

fn similarityScore(first: []u32, second: []u32) u32 {
    var score: u32 = 0;
    for (first) |i| {
        var matches: u32 = 0;
        for (second) |j| {
            if (i == j) {
                matches += 1;
            }
        }
        score += i * matches;
    }
    return score;
}

test similarityScore {
    var first: [6]u32 = [_]u32{ 3, 4, 2, 1, 3, 3 };
    var second: [6]u32 = [_]u32{ 4, 3, 5, 3, 9, 3 };

    try expectEqual(31, similarityScore(&first, &second));
}
