const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = @embedFile("input.txt");

    std.debug.print("\nCalculating plots and fences...\n", .{});
    const map = try parseInput(allocator, input);
    defer allocator.free(map);
    const cost = try calculateFencePrize(allocator, map);
    std.debug.print("\n\nCost: {d}", .{cost});
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![][]const u8 {
    var map = std.ArrayList([]const u8).init(allocator);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try map.append(line);
    }

    return map.toOwnedSlice();
}

const Plot = struct {
    area: usize,
    corners: usize,
};

fn calculatePlot(map: [][]const u8, checked: [][]bool, x: usize, y: usize, crop: u8) Plot {
    std.debug.print("\ncheck {d},{d} ({c})", .{ x, y, crop });
    checked[y][x] = true;

    var plot = Plot{
        .area = 1,
        .corners = 0,
    };

    // keep track of which sides are a different crop
    var up: bool = true;
    var down: bool = true;
    var left: bool = true;
    var right: bool = true;
    // check all neighbours (not diagonal)
    // up
    if (y > 0) {
        // check if same crop or not
        if (map[y - 1][x] == crop) {
            up = false;
            // same crop
            if (!checked[y - 1][x]) {
                const neighbour_plot = calculatePlot(map, checked, x, y - 1, crop);
                plot.area += neighbour_plot.area;
                plot.corners += neighbour_plot.corners;
            }
        }
    }
    // down
    if (y + 1 < map.len) {
        // check if same crop or not
        if (map[y + 1][x] == crop) {
            // same crop
            down = false;
            if (!checked[y + 1][x]) {
                const neighbour_plot = calculatePlot(map, checked, x, y + 1, crop);
                plot.area += neighbour_plot.area;
                plot.corners += neighbour_plot.corners;
            }
        }
    }
    // left
    if (x > 0) {
        // check if same crop or not
        if (map[y][x - 1] == crop) {
            // same crop
            left = false;
            if (!checked[y][x - 1]) {
                const neighbour_plot = calculatePlot(map, checked, x - 1, y, crop);
                plot.area += neighbour_plot.area;
                plot.corners += neighbour_plot.corners;
            }
        }
    }
    // right
    if (x + 1 < map[0].len) {
        // check if same crop or not
        if (map[y][x + 1] == crop) {
            // same crop
            right = false;
            if (!checked[y][x + 1]) {
                const neighbour_plot = calculatePlot(map, checked, x + 1, y, crop);
                plot.area += neighbour_plot.area;
                plot.corners += neighbour_plot.corners;
            }
        }
    }

    // calculate number of corners from which neighbours are NOT there
    if (up and left)
        plot.corners += 1;
    if (up and right)
        plot.corners += 1;
    if (down and left)
        plot.corners += 1;
    if (down and right)
        plot.corners += 1;
    // special case: two neighbours are the same crop but diagonal is not
    // ↖
    if (!up and !left and map[y - 1][x - 1] != crop)
        plot.corners += 1;
    // ↗
    if (!up and !right and map[y - 1][x + 1] != crop)
        plot.corners += 1;
    // ↙
    if (!down and !left and map[y + 1][x - 1] != crop)
        plot.corners += 1;
    // ↘
    if (!down and !right and map[y + 1][x + 1] != crop)
        plot.corners += 1;
    std.debug.print("\n{d},{d}: u{any} l{any} d{any} r{any}, corners {d}", .{ x, y, up, left, down, right, plot.corners });

    return plot;
}

fn calculateFencePrize(allocator: std.mem.Allocator, map: [][]const u8) !usize {
    // keep a map of which plots are already part of a farm
    var checked: [][]bool = undefined;
    checked = try allocator.alloc([]bool, map.len);
    for (checked) |*row| {
        row.* = try allocator.alloc(bool, map[0].len);
        for (0..row.len) |i| {
            row.*[i] = false;
        }
    }

    var prize: usize = 0;
    for (0..map.len) |y| {
        for (0..map[0].len) |x| {
            if (!checked[y][x]) {
                std.debug.print("\n\nplot {d},{d}", .{ x, y });
                const plot = calculatePlot(map, checked, x, y, map[y][x]);
                prize += plot.area * plot.corners;
                std.debug.print("\nresult area {d}, corners {d}", .{ plot.area, plot.corners });
            }
        }
    }
    return prize;
}

test calculateFencePrize {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const example =
        \\USE EXAMPLE FROM TEXT
    ;

    const map = try parseInput(allocator, example);
    defer allocator.free(map);

    // USE EXAMPLE RESULT FROM TEXT
    try expectEqual(80, try calculateFencePrize(allocator, map));
}
