const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const input = @embedFile("input.txt");

    std.debug.print("\nPlaying the claw game...\n", .{});
    const games = try parseInput(allocator, input);
    defer allocator.free(games);
    var total_cost: usize = 0;
    for (games) |game| {
        if (playClawMachine(game)) |cost| {
            total_cost += cost;
        }
    }
    std.debug.print("\n\nCost: {d}", .{total_cost});
}

const Vector = struct {
    x: f128,
    y: f128,
};
const Configuration = struct {
    a: Vector,
    b: Vector,
    prize: Vector,
};

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]Configuration {
    var list = std.ArrayList(Configuration).init(allocator);

    var numbers = std.mem.tokenizeAny(u8, input, "ButtonABPrize:XY=, \n");
    while (numbers.next()) |first| {
        const a_x = try std.fmt.parseFloat(f128, first);
        const a_y = try std.fmt.parseFloat(f128, numbers.next().?);
        const b_x = try std.fmt.parseFloat(f128, numbers.next().?);
        const b_y = try std.fmt.parseFloat(f128, numbers.next().?);
        const prize_x = try std.fmt.parseFloat(f128, numbers.next().?) + 10000000000000;
        const prize_y = try std.fmt.parseFloat(f128, numbers.next().?) + 10000000000000;
        try list.append(Configuration{
            .a = .{ .x = a_x, .y = a_y },
            .b = .{ .x = b_x, .y = b_y },
            .prize = .{ .x = prize_x, .y = prize_y },
        });
    }

    // std.debug.print("\nparsed: {any}", .{list.items});
    return list.toOwnedSlice();
}

fn playClawMachine(config: Configuration) ?usize {
    std.debug.print("\nPrize {e},{e} a: {e},{e} b: {e},{e}", .{
        config.prize.x,
        config.prize.y,
        config.a.x,
        config.a.y,
        config.b.x,
        config.b.y,
    });
    // linear equations, solved on paper
    var a: f128 = (config.prize.x * config.b.y) - (config.b.x * config.prize.y);
    var b: f128 = (config.prize.y * config.a.x) - (config.a.y * config.prize.x);
    const det: f128 = (config.a.x * config.b.y) - (config.a.y * config.b.x);
    a = a / det;
    b = b / det;

    std.debug.print("\na: {e}, b: {e} ", .{ a, b });
    if (det != 0 and a >= 0 and @rem(a, 1) == 0 and b >= 0 and @rem(b, 1) == 0) {
        const cost: usize = @as(usize, @intFromFloat(a)) * 3 + @as(usize, @intFromFloat(b));
        std.debug.print("ok. (cost {d})", .{cost});
        return cost;
    }

    std.debug.print("fail! ", .{});
    return null;
}
