const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const input = @embedFile("input.txt");

    std.debug.print("\nBlinking and counting stones...\n", .{});
    const total = try blink(allocator, input, 75);
    std.debug.print("\n\nNumber of stones: {d}", .{total});
}

fn parseInput(map: *std.AutoHashMap(usize, usize), input: []const u8) !void {
    // std.debug.print("\ninput: {s}\n", .{input});

    var numbers = std.mem.tokenizeAny(u8, input, " \n");
    while (numbers.next()) |number_str| {
        const number = try std.fmt.parseInt(usize, number_str, 10);
        try map.*.put(number, 1);
        // std.debug.print("{d} ", .{number});
    }
}

fn blink(allocator: std.mem.Allocator, input: []const u8, times: usize) !usize {
    var map = std.AutoHashMap(usize, usize).init(allocator);
    defer map.deinit();
    try parseInput(&map, input);

    for (0..times) |i| {
        std.debug.print("\nblink {d}...", .{i + 1});
        var next_map = std.AutoHashMap(usize, usize).init(allocator);

        var entries = map.iterator();
        while (entries.next()) |entry| {
            const stone = entry.key_ptr.*;
            const stone_num = entry.value_ptr.*;

            if (stone == 0) {
                if (next_map.get(1)) |value| {
                    try next_map.put(1, value + stone_num);
                } else {
                    try next_map.putNoClobber(1, stone_num);
                }
            } else {
                const num_digits = std.math.log10_int(stone) + 1;
                if (num_digits % 2 == 0) {
                    // even number of digits: split number
                    const n = std.math.pow(u64, 10, num_digits / 2);
                    // split into two numbers
                    const first = stone / n;
                    const second = stone - (first * n);
                    // save into array
                    if (next_map.get(first)) |value| {
                        try next_map.put(first, value + stone_num);
                    } else {
                        try next_map.putNoClobber(first, stone_num);
                    }
                    if (next_map.get(second)) |value| {
                        try next_map.put(second, value + stone_num);
                    } else {
                        try next_map.putNoClobber(second, stone_num);
                    }
                } else {
                    // no other rules: multiply by 2024
                    const m = stone * 2024;
                    if (next_map.get(m)) |value| {
                        try next_map.put(m, value + stone_num);
                    } else {
                        try next_map.putNoClobber(m, stone_num);
                    }
                }
            }
        }

        // switch map to next_map
        map.deinit();
        map = next_map;
    }

    var total_stones: usize = 0;
    var stone_nums = map.valueIterator();
    while (stone_nums.next()) |stone_num| {
        total_stones += stone_num.*;
    }
    return total_stones;
}

test blink {
    const allocator = std.testing.allocator;

    try expectEqual(22, try blink(allocator, "125 17", 6));
    try expectEqual(55312, try blink(allocator, "125 17", 25));
}
