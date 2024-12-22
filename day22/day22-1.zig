const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const input = @embedFile("input.txt");

    std.debug.print("\nCalculating secret and sum of secrets...\n", .{});
    const parsed = try parseInput(allocator, input);
    defer allocator.free(parsed);
    const sum = sumOfSecrets(parsed, 2000);
    std.debug.print("\n\nSecret sum: {d}", .{sum});
}

const Secret = u24;

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]Secret {
    var list = std.ArrayList(Secret).init(allocator);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const number = try std.fmt.parseInt(Secret, line, 10);
        try list.append(number);
    }
    return list.toOwnedSlice();
}

fn sumOfSecrets(initial: []Secret, num: usize) usize {
    var sum: usize = 0;
    for (initial) |initial_secret| {
        var secret: Secret = initial_secret;
        std.debug.print("\ninitial {d}... ", .{initial_secret});
        for (0..num) |_| {
            secret = (secret << 6) ^ secret;
            secret = (secret >> 5) ^ secret;
            secret = (secret << 11) ^ secret;
        }
        std.debug.print("{d}th: {d}", .{ num, secret });
        sum += @intCast(secret);
    }
    return sum;
}
