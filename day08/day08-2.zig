const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const input = @embedFile("input.txt");

    var antinodes = std.AutoHashMap(Position, void).init(allocator);

    std.debug.print("Calculating all antinodes...", .{});
    const map = try parseInput(allocator, input);
    try getAllAntinodes(allocator, map, &antinodes);
    std.debug.print("\n\nNumber of antinodes: {d}", .{antinodes.count()});
}

const Antennas = std.AutoHashMap(u8, []Position);
const Map = struct { antennas: Antennas, width: usize, height: usize };

const Position = struct {
    x: isize,
    y: isize,
};

fn calculateAntinodes(allocator: std.mem.Allocator, antenna1: Position, antenna2: Position, width: usize, height: usize) ![]Position {
    var antinodes = std.ArrayList(Position).init(allocator);
    var antinode: Position = undefined;
    // distance: vector of direction from antenna1 to antenna2
    const distance: Position = .{ .x = antenna2.x - antenna1.x, .y = antenna2.y - antenna1.y };
    // add all antinodes until edge of map is hit in all directions
    antinode = antenna1;
    while (antinode.x >= 0 and antinode.x < width and antinode.y >= 0 and antinode.y < height) {
        try antinodes.append(antinode);
        antinode.x -= distance.x;
        antinode.y -= distance.y;
    }
    antinode = antenna2;
    while (antinode.x >= 0 and antinode.x < width and antinode.y >= 0 and antinode.y < height) {
        try antinodes.append(antinode);
        antinode.x += distance.x;
        antinode.y += distance.y;
    }

    return try antinodes.toOwnedSlice();
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !Map {
    var map = std.AutoHashMap(u8, *std.ArrayList(Position)).init(allocator);
    var width: usize = undefined;
    var height: usize = undefined;
    defer map.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var y: isize = 0;
    while (lines.next()) |line| : (y += 1) {
        var x: isize = 0;
        for (line) |ch| {
            // everything is an antenna except '.'
            if (ch != '.') {
                // check if already in map
                if (map.contains(ch)) {
                    const list_ptr = map.get(ch).?;
                    try list_ptr.*.append(.{ .x = x, .y = y });
                } else {
                    // create new list and put into map
                    const list_ptr = try allocator.create(std.ArrayList(Position));
                    list_ptr.* = std.ArrayList(Position).init(allocator);
                    try list_ptr.*.append(.{ .x = x, .y = y });
                    try map.put(ch, list_ptr);
                }
            }
            x += 1;
        }
        width = @intCast(x);
    }
    height = @intCast(y);

    var final_map = Antennas.init(allocator);

    // make into map of slices
    var antenna_types = map.keyIterator();
    while (antenna_types.next()) |antenna_type| {
        const list_ptr = map.get(antenna_type.*).?;
        try final_map.put(antenna_type.*, try list_ptr.*.toOwnedSlice());
    }

    return Map{
        .antennas = final_map,
        .width = width,
        .height = height,
    };
}

test parseInput {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const example =
        \\..........
        \\...#......
        \\..........
        \\....a.....
        \\..........
        \\.....a....
        \\..........
        \\......#...
        \\..........
        \\..........
    ;

    const map = try parseInput(allocator, example);
    var antenna_types = map.antennas.keyIterator();
    while (antenna_types.next()) |antenna_type| {
        std.debug.print("\n{c}: {any}", .{ antenna_type.*, map.antennas.get(antenna_type.*) });
    }
}

fn getAllAntinodes(allocator: std.mem.Allocator, map: Map, antinodes: *std.AutoHashMap(Position, void)) !void {
    var antenna_types = map.antennas.keyIterator();
    while (antenna_types.next()) |antenna_type| {
        const antennas = map.antennas.get(antenna_type.*).?;
        for (antennas, 1..) |first, i| {
            for (antennas[i..]) |second| {
                const new_antinodes = try calculateAntinodes(allocator, first, second, map.width, map.height);
                for (new_antinodes) |new| {
                    // check if antinodes is valid
                    if (new.x < 0 or new.y < 0 or new.x >= map.width or new.y >= map.height)
                        continue;
                    try antinodes.*.put(new, {});
                }
            }
        }
    }
}

test getAllAntinodes {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const example =
        \\............
        \\........0...
        \\.....0......
        \\.......0....
        \\....0.......
        \\......A.....
        \\............
        \\............
        \\........A...
        \\.........A..
        \\............
        \\............
    ;

    var antinodes = std.AutoHashMap(Position, void).init(allocator);

    std.debug.print("Calculating all antinodes...", .{});
    const map = try parseInput(allocator, example);
    try getAllAntinodes(allocator, map, &antinodes);
    std.debug.print("\n\nNumber of antinodes: {d}", .{antinodes.count()});
    try expectEqual(34, antinodes.count());
}
