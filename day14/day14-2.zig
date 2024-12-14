const std = @import("std");
const expectEqual = std.testing.expectEqual;

// prints maps of the robots every time the safety is lower than ever before
// -> just a guess, but it show the tree :)
// I assumed puzzle 1 is somehow related to puzzle 2

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const input = @embedFile("input.txt");

    std.debug.print("\nChecking when robots show christmas tree...\n", .{});
    const robots = try parseInput(allocator, input);
    defer allocator.free(robots);
    const safety = try calcRobotsShowChristmasTree(robots, 101, 103);
    std.debug.print("\n\nSeconds until robots show christmas tree: {d}", .{safety});
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

fn calcRobotsShowChristmasTree(robots: []Robot, width: usize, height: usize) !usize {
    std.debug.assert(width % 2 == 1 and height % 2 == 1);

    const max: usize = 1E6;
    var min_safety: usize = 1E10; // very high value

    for (1..max) |s| {
        // move all robots one second
        for (robots) |*robot| {
            robot.x += robot.vx;
            robot.y += robot.vy;
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

        const safety = q1 * q2 * q3 * q4;

        if (safety < min_safety) {
            min_safety = safety;
            std.debug.print("\n\n{d} seconds\n", .{s});
            for (0..height) |y| {
                for (0..width) |x| {
                    var count: usize = 0;
                    for (robots) |robot| {
                        if (robot.x == x and robot.y == y)
                            count += 1;
                    }

                    if (count > 0) {
                        std.debug.print("{d}", .{count});
                    } else {
                        std.debug.print(".", .{});
                    }
                }
                std.debug.print("\n", .{});
            }
        }
    }
    return 0;
}
