const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const input = @embedFile("input.txt");

    std.debug.print("\nBlinking and counting stones...\n", .{});
    var list = try parseInput(allocator, input);
    defer list.deinit();

    for (1..25 + 1) |i| {
        try blink(&list);
        std.debug.print("\nblinked {d} times...", .{i});
    }
    std.debug.print("\n\nNumber of stones: {d}", .{list.items.len});
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !std.ArrayList(u64) {
    std.debug.print("\ninput: {s}", .{input});
    var list = std.ArrayList(u64).init(allocator);

    var numbers = std.mem.tokenizeAny(u8, input, " \n");
    while (numbers.next()) |number| {
        try list.append(try std.fmt.parseInt(u64, number, 10));
    }

    std.debug.print("\nparsed: {any}", .{list.items});
    return list;
}

fn blink(list_ptr: *std.ArrayList(u64)) !void {
    // go through list from the back
    var i: usize = list_ptr.*.items.len;
    while (i > 0) {
        i -= 1;
        const stone = list_ptr.*.items[i];

        if (stone == 0) {
            list_ptr.*.items[i] = 1;
        } else {
            const num_digits = std.math.log10_int(stone) + 1;
            if (num_digits % 2 == 0) {
                // even number of digits: split number
                const n = std.math.pow(u64, 10, num_digits / 2);
                // split into two numbers
                const first = stone / n;
                const second = stone - (first * n);
                // save into array
                list_ptr.*.items[i] = first;
                try list_ptr.*.insert(i + 1, second);
            } else {
                // no other rules: multiply by 2024
                list_ptr.*.items[i] = stone * 2024;
            }
        }
    }
}

test blink {
    const allocator = std.testing.allocator;
    var list = try parseInput(allocator, "125 17");
    defer list.deinit();

    for (1..6 + 1) |i| {
        try blink(&list);
        std.debug.print("\n{d}: {any}", .{ i, list.items });
    }
    try expectEqual(22, list.items.len);

    for (1..25 - 6 + 1) |_| {
        try blink(&list);
        // std.debug.print("\n{d}: {any}", .{ i, list.items });
    }
    try expectEqual(55312, list.items.len);
}
