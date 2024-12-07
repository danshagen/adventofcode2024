const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const input = @embedFile("input.txt");

    std.debug.print("Trying all possible operations for calibrations...", .{});
    const calibrations = try parseInput(allocator, input);
    var sum: usize = 0;
    for (calibrations) |calibration| {
        if (try checkCalibration(allocator, calibration)) |value|
            sum += value;
    }
    std.debug.print("\n\nTotal calibration result: {d}", .{sum});
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]Calibration {
    var list = std.ArrayList(Calibration).init(allocator);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var calibration: Calibration = undefined;
        var value_list = std.ArrayList(u64).init(allocator);

        var values = std.mem.tokenizeAny(u8, line, ": ");
        calibration.result = try std.fmt.parseInt(u64, values.next().?, 10);
        while (values.next()) |value| {
            const number = try std.fmt.parseInt(u64, value, 10);
            try value_list.append(number);
        }
        calibration.values = try value_list.toOwnedSlice();
        try list.append(calibration);
    }
    return try list.toOwnedSlice();
}

const Calibration = struct { result: u64, values: []u64 };
/// Check if the calibration equation works by trying all possible combinations
/// of operators. Returns the calibration result if the equation can be made to
/// work, null if not.
fn checkCalibration(allocator: std.mem.Allocator, calibration: Calibration) !?u64 {
    var list = std.ArrayList(u64).init(allocator);
    defer list.deinit();

    std.debug.print("\ncheck calibration for {d}: {any}...", .{ calibration.result, calibration.values });

    // first operations
    try list.append(calibration.values[0] + calibration.values[1]);
    try list.append(calibration.values[0] * calibration.values[1]);
    try list.append(concat(calibration.values[0], calibration.values[1]));
    for (calibration.values[2..]) |value| {
        // go backwards through all items in list and replace the value with
        // two values for both operations
        var i: usize = list.items.len - 1;
        while (true) {
            const last = list.orderedRemove(i);
            // add +
            const a = last + value;
            if (a <= calibration.result)
                try list.append(a);
            // mul *
            const m = last * value;
            if (m <= calibration.result)
                try list.append(m);
            // concat |
            const c = concat(last, value);
            if (c <= calibration.result)
                try list.append(c);

            if (i == 0)
                break;
            i -= 1;
        }
    }

    for (list.items) |value| {
        if (value == calibration.result) {
            std.debug.print(" {d}.", .{value});
            return value;
        }
    }

    std.debug.print(" null.", .{});
    return null;
}

fn concat(first: u64, second: u64) u64 {
    const num_digits = std.math.log10(second);
    return std.math.pow(u64, 10, num_digits + 1) * first + second;
}

test concat {
    try expectEqual(156, concat(15, 6));
    try expectEqual(11, concat(1, 1));
    try expectEqual(12345, concat(12, 345));
}

test checkCalibration {
    const allocator = std.testing.allocator;
    const example =
        \\190: 10 19
        \\3267: 81 40 27
        \\83: 17 5
        \\156: 15 6
        \\7290: 6 8 6 15
        \\161011: 16 10 13
        \\192: 17 8 14
        \\21037: 9 7 18 13
        \\292: 11 6 16 20
    ;
    const parsed = try parseInput(allocator, example);
    defer {
        for (parsed) |calibration| {
            allocator.free(calibration.values);
        }
        allocator.free(parsed);
    }
    std.debug.print("\n{any}\n", .{parsed});

    try expectEqual(190, (try checkCalibration(allocator, parsed[0])).?);
    try expectEqual(3267, (try checkCalibration(allocator, parsed[1])).?);
    try expectEqual(null, try checkCalibration(allocator, parsed[2]));
    try expectEqual(156, (try checkCalibration(allocator, parsed[3])).?);
    try expectEqual(7290, (try checkCalibration(allocator, parsed[4])).?);
    try expectEqual(null, try checkCalibration(allocator, parsed[5]));
    try expectEqual(192, (try checkCalibration(allocator, parsed[6])).?);
    try expectEqual(null, try checkCalibration(allocator, parsed[7]));
    try expectEqual(292, (try checkCalibration(allocator, parsed[8])).?);
}
