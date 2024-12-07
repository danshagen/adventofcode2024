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
        // std.debug.print("\ncheck calibration for {d}: {any}... ", .{ calibration.result, calibration.values });
        if (try checkCalibration(calibration)) {
            sum += calibration.values[calibration.values.len / 2];
        }
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
fn checkCalibration(calibration: Calibration) !bool {
    // compare the value with the result, if there is only one element in values
    if (calibration.values.len == 1)
        return calibration.result == calibration.values[0];

    // go through values backwards and check recursively
    const value = calibration.values[calibration.values.len - 1];
    const result = calibration.result;

    // addition -> subtraction
    // skip, if value is smaller
    if (result > value) {
        const a = result - value;
        if (try checkCalibration(.{ .result = a, .values = calibration.values[0 .. calibration.values.len - 1] })) {
            // std.debug.print("+", .{});
            return true;
        }
    }

    // multiplication -> division
    // skip, if remainder is not 0
    const rem = result % value;
    if (rem == 0) {
        const m = result / value;
        if (try checkCalibration(.{ .result = m, .values = calibration.values[0 .. calibration.values.len - 1] })) {
            // std.debug.print("*", .{});
            return true;
        }
    }

    // concat -> try to remove value
    if (result > value) {
        var num_digits: usize = 0;
        var _value = value;
        while (_value > 0) {
            _value /= 10;
            num_digits += 1;
        }
        var c = result - value;
        // skip if there is a remainder -> value was not a subset of result
        // (correct would be for example: 1234 - 34 = 1200, 1200 % 100 = 0)
        if (c % std.math.pow(u64, 10, num_digits) == 0) {
            c /= num_digits * std.math.pow(u64, 10, num_digits);
            if (try checkCalibration(.{ .result = c, .values = calibration.values[0 .. calibration.values.len - 1] })) {
                // std.debug.print("|", .{});
                return true;
            }
        }
    }

    return false;
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

    try expectEqual(true, try checkCalibration(parsed[0]));
    try expectEqual(true, try checkCalibration(parsed[1]));
    try expectEqual(false, try checkCalibration(parsed[2]));
    try expectEqual(true, try checkCalibration(parsed[3]));
    try expectEqual(true, try checkCalibration(parsed[4]));
    try expectEqual(false, try checkCalibration(parsed[5]));
    try expectEqual(true, try checkCalibration(parsed[6]));
    try expectEqual(false, try checkCalibration(parsed[7]));
    try expectEqual(true, try checkCalibration(parsed[8]));
}
