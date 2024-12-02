const std = @import("std");
const expectEqual = std.testing.expectEqual;
const input = @embedFile("input.txt");

pub fn main() !void {
    std.debug.print("Calculating reactor safety...\n", .{});
    const safety: u32 = try calcReactorSafety(input);
    std.debug.print("reactor safety: {d}\n", .{safety});
}

fn calcReactorSafety(reports: []const u8) !u32 {
    var safety: u32 = 0;

    var lines = std.mem.tokenizeScalar(u8, reports, '\n');
    lineLoop: while (lines.next()) |line| {
        std.debug.print("\nsafety {d} for {any} ", .{ safety, line });
        var increasing: ?bool = null;

        var tokens = std.mem.tokenizeScalar(u8, line, ' ');

        var last: u32 = try std.fmt.parseInt(u32, tokens.next().?, 10);
        while (tokens.next()) |token| {
            const value = try std.fmt.parseInt(u32, token, 10);
            const diff: i64 = @as(i64, value) - @as(i64, last);
            std.debug.print("{d} ", .{diff});
            if (diff > 0) {
                // increasing
                if (increasing == null)
                    increasing = true;

                if (increasing.? and diff <= 3) {
                    // good!
                } else {
                    // not increasing or increasing too much
                    continue :lineLoop;
                }
            } else if (diff < 0) {
                // decreasing
                if (increasing == null)
                    increasing = false;

                if (!increasing.? and diff >= -3) {
                    // good!
                } else {
                    // not increasing or increasing too much
                    continue :lineLoop;
                }
            } else {
                // diff is 0
                continue :lineLoop;
            }

            last = value;
        }
        std.debug.print("++ ", .{});
        safety += 1;
    }
    return safety;
}

test calcReactorSafety {
    const example =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;

    try expectEqual(2, calcReactorSafety(example));

    try expectEqual(0, calcReactorSafety("1 6 7 8"));
}
