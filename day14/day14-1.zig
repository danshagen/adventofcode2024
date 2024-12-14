const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const input = @embedFile("input.txt");

    std.debug.print("\nCalculating robot safety...\n", .{});
    const robots = try parseInput(allocator, input);
    defer allocator.free(robots);
    const safety = calcRobotSafety(robots, 101, 103, 100);
    std.debug.print("\n\nSafety: {d}", .{safety});
}

const Robot = struct {
    x: i32,
    y: i32,
    vx: i32,
    vy: i32,
};

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]Robot {
    var list = std.ArrayList(Robot).init(allocator);

    var numbers = std.mem.tokenizeAny(u8, input, "p=,v \n");
    while (numbers.next()) |first| {
        const x = try std.fmt.parseInt(i32, first, 10);
        const y = try std.fmt.parseInt(i32, numbers.next().?, 10);
        const vx = try std.fmt.parseInt(i32, numbers.next().?, 10);
        const vy = try std.fmt.parseInt(i32, numbers.next().?, 10);
        try list.append(Robot{
            .x = x,
            .y = y,
            .vx = vx,
            .vy = vy,
        });
    }

    return list.toOwnedSlice();
}

fn calcRobotSafety(robots: []Robot, width: usize, height: usize, seconds: usize) usize {
    std.debug.assert(width % 2 == 1 and height % 2 == 1);
    try expectEqual([]Robot, @TypeOf(robots));
    // move all robots individually for the seconds
    for (robots) |*robot| {
        // they move linearly
        robot.x += robot.vx * @as(i32, @intCast(seconds));
        robot.y += robot.vy * @as(i32, @intCast(seconds));
        // wrap around the edges
        robot.x = @mod(robot.x, @as(i32, @intCast(width)));
        robot.y = @mod(robot.y, @as(i32, @intCast(height)));
    }

    // count robots per quadrant
    var q1: usize = 0;
    var q2: usize = 0;
    var q3: usize = 0;
    var q4: usize = 0;

    // q2 | q1
    // ---+---
    // q3 | q4
    for (robots) |robot| {
        if (robot.x < width / 2) {
            if (robot.y < height / 2)
                q2 += 1;
            if (robot.y > height / 2)
                q3 += 1;
        }
        if (robot.x > width / 2) {
            if (robot.y < height / 2)
                q1 += 1;
            if (robot.y > height / 2)
                q4 += 1;
        }
    }

    return q1 * q2 * q3 * q4;
}

test calcRobotSafety {
    const allocator = std.testing.allocator;
    const example =
        \\p=0,4 v=3,-3
        \\p=6,3 v=-1,-3
        \\p=10,3 v=-1,2
        \\p=2,0 v=2,-1
        \\p=0,0 v=1,3
        \\p=3,0 v=-2,-2
        \\p=7,6 v=-1,-3
        \\p=3,0 v=-1,-2
        \\p=9,3 v=2,3
        \\p=7,3 v=-1,2
        \\p=2,4 v=2,-3
        \\p=9,5 v=-3,-3
    ;

    const robots = try parseInput(allocator, example);
    defer allocator.free(robots);

    for (robots) |robot| {
        std.debug.print("\nrobot {d},{d} with v {d},{d}", .{ robot.x, robot.y, robot.vx, robot.vy });
    }

    try expectEqual(12, calcRobotSafety(robots, 11, 7, 100));
}
