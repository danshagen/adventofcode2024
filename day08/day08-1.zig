const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const input = @embedFile("input.txt");

    var antinodes = std.AutoHashMap(Position, void).init(allocator);

    std.debug.print("Calculating all antinodes...", .{});
    const antennas = try parseInput(allocator, input);
    var antenna_types = antennas.keyIterator();
    while (antenna_types.next()) |antenna_type| {
        std.debug.print("\n{c}: {any}", .{ antenna_type.*, antennas.get(antenna_type.*) });
        try getAllAntinodes(
            antennas.get(antenna_type.*).?,
            &antinodes,
            50,
            50,
        );
    }
    std.debug.print("\n\nNumber of antinodes: {d}", .{antinodes.count()});
}

const Antennas = std.AutoHashMap(u8, []Position);

const Position = struct {
    x: isize,
    y: isize,
};

fn calculateAntinodes(antenna1: Position, antenna2: Position) [2]Position {
    var antinodes: [2]Position = undefined;
    // distance: vector of direction from antenna1 to antenna2
    const distance: Position = .{ .x = antenna2.x - antenna1.x, .y = antenna2.y - antenna1.y };
    // first antinode: behind antenna1
    antinodes[0].x = antenna1.x - distance.x;
    antinodes[0].y = antenna1.y - distance.y;
    // second antinode: behind antenna2
    antinodes[1].x = antenna2.x + distance.x;
    antinodes[1].y = antenna2.y + distance.y;
    return antinodes;
}

test calculateAntinodes {
    // from example
    // ..........
    // ...#......
    // ..........
    // ....a.....
    // ..........
    // .....a....
    // ..........
    // ......#...
    // ..........
    // ..........
    try expectEqual([2]Position{ .{ .x = 3, .y = 1 }, .{ .x = 6, .y = 7 } }, calculateAntinodes(.{ .x = 4, .y = 3 }, .{ .x = 5, .y = 5 }));
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !Antennas {
    var map = std.AutoHashMap(u8, *std.ArrayList(Position)).init(allocator);
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
    }

    var final_map = Antennas.init(allocator);

    // make into map of slices
    var antenna_types = map.keyIterator();
    while (antenna_types.next()) |antenna_type| {
        const list_ptr = map.get(antenna_type.*).?;
        try final_map.put(antenna_type.*, try list_ptr.*.toOwnedSlice());
    }

    return final_map;
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

    const antennas = try parseInput(allocator, example);
    var antenna_types = antennas.keyIterator();
    while (antenna_types.next()) |antenna_type| {
        std.debug.print("\n{c}: {any}", .{ antenna_type.*, antennas.get(antenna_type.*) });
    }
}

fn getAllAntinodes(antennas: []Position, antinodes: *std.AutoHashMap(Position, void), width: usize, height: usize) !void {
    std.debug.print("\ngetAllAntinodes for ", .{});
    for (antennas) |pos|
        std.debug.print("({d},{d}) ", .{ pos.x, pos.y });
    for (antennas, 1..) |first, i| {
        for (antennas[i..]) |second| {
            std.debug.print("\n({d},{d}) - ({d},{d})", .{ first.x, first.y, second.x, second.y });
            const new_antinodes = calculateAntinodes(first, second);
            for (new_antinodes) |new| {
                // check if antinodes is valid
                if (new.x < 0 or new.y < 0 or new.x >= width or new.y >= height)
                    continue;
                try antinodes.*.put(new, {});
            }
        }
    }
    std.debug.print("\n", .{});
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
    const antennas = try parseInput(allocator, example);
    var antenna_types = antennas.keyIterator();
    while (antenna_types.next()) |antenna_type| {
        std.debug.print("\n{c}: {any}", .{ antenna_type.*, antennas.get(antenna_type.*) });
        try getAllAntinodes(antennas.get(antenna_type.*).?, &antinodes, 12, 12);
    }
    std.debug.print("\n\nNumber of antinodes: {d}", .{antinodes.count()});
    try expectEqual(14, antinodes.count());
}
