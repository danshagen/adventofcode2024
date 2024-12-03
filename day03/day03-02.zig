const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    const input = @embedFile("input.txt");
    std.debug.print("Multiplying and summing...\n", .{});
    const result: u64 = try mullItOver(input);
    std.debug.print("result: {d}\n", .{result});
}

fn mullItOver(input: []const u8) !u64 {
    var sum: u64 = 0;
    var index: usize = 0;
    // find all occurances of mul(
    while (std.mem.indexOf(u8, input[index..], "mul(")) |start| {
        // check for conditionals: happening before
        const dont = std.mem.indexOf(u8, input[index..], "don't()");
        if (dont != null and dont.? < start) {
            const do = std.mem.indexOf(u8, input[index..], "do()");
            if (do != null) {
                index += do.?;
                continue; // restart after do()
            } else {
                // no do() found until end: finished
                break;
            }
        }

        const data = input[index + start + 4 ..]; // slice starting after 'mul('
        const comma = std.mem.indexOf(u8, data, ",");
        const end = std.mem.indexOf(u8, data, ")");
        std.debug.print("'{s}' start: {d}, comma: {d}, end: {d} ", .{ data[0..end.?], start, comma.?, end.? });
        // find matching ) and check it is within range XXX,XXX (7 letters)
        // check that comma is before end bracket
        if (end != null and end.? <= 7 and comma.? < end.?) {
            std.debug.print("i: '{s}' j: '{s}'\n", .{ data[0..comma.?], data[comma.? + 1 .. end.?] });
            const i: u64 = try std.fmt.parseInt(u64, data[0..comma.?], 10);
            const j: u64 = try std.fmt.parseInt(u64, data[comma.? + 1 .. end.?], 10);
            sum += i * j;
            index += start + 4 + end.?;
        } else {
            // no matching brace or too far away, skip over 4 characters (length of "mul(")
            std.debug.print("skip\n", .{});
            index += start + 4;
        }
    }
    return sum;
}

test mullItOver {
    const example = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";

    try expectEqual(48, mullItOver(example));
}
