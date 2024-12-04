const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = @embedFile("input.txt");
    std.debug.print("Searching for XMAS...", .{});
    const num_xmas = howManyXmas(try parseIntoArray(input, allocator));
    std.debug.print("Found XMAS {d} times!", .{num_xmas});
}

fn parseIntoArray(input: []const u8, allocator: std.mem.Allocator) ![]const []const u8 {
    var list = std.ArrayList([]const u8).init(allocator);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try list.append(line);
    }
    return list.items;
}

fn howManyXmas(matrix: []const []const u8) usize {
    var found: usize = 0;
    // find all X
    for (matrix, 0..) |row, y| {
        var index: usize = 0;
        while (std.mem.indexOf(u8, row[index..], "X")) |start| {
            const x = index + start;
            // check if there is MAS in all the directions
            std.debug.print("\nX at {d},{d} ", .{ x, y });
            // ←
            if (x >= 3) {
                for ("MAS", 1..) |char, i| {
                    if (row[x - i] != char)
                        break;
                } else {
                    found += 1;
                    std.debug.print("← ", .{});
                }
            }

            // →
            if (x + 3 < row.len) {
                for ("MAS", 1..) |char, i| {
                    if (row[x + i] != char)
                        break;
                } else {
                    found += 1;
                    std.debug.print("→ ", .{});
                }
            }

            // ↓
            if (y + 3 < matrix.len) {
                for ("MAS", 1..) |char, i| {
                    if (matrix[y + i][x] != char)
                        break;
                } else {
                    found += 1;
                    std.debug.print("↓ ", .{});
                }
            }

            // ↑
            if (y >= 3) {
                for ("MAS", 1..) |char, i| {
                    if (matrix[y - i][x] != char)
                        break;
                } else {
                    found += 1;
                    std.debug.print("↑ ", .{});
                }
            }

            // ↖
            if (x >= 3 and y >= 3) {
                for ("MAS", 1..) |char, i| {
                    if (matrix[y - i][x - i] != char)
                        break;
                } else {
                    found += 1;
                    std.debug.print("↖ ", .{});
                }
            }

            // ↗
            if (x + 3 < row.len and y >= 3) {
                for ("MAS", 1..) |char, i| {
                    if (matrix[y - i][x + i] != char)
                        break;
                } else {
                    found += 1;
                    std.debug.print("↗ ", .{});
                }
            }

            // ↘
            if (x + 3 < row.len and y + 3 < matrix.len) {
                for ("MAS", 1..) |char, i| {
                    if (matrix[y + i][x + i] != char)
                        break;
                } else {
                    found += 1;
                    std.debug.print("↘ ", .{});
                }
            }

            // ↙
            if (x >= 3 and y + 3 < matrix.len) {
                for ("MAS", 1..) |char, i| {
                    if (matrix[y + i][x - i] != char)
                        break;
                } else {
                    found += 1;
                    std.debug.print("↙ ", .{});
                }
            }

            index += start + 1;
            if (index >= row.len)
                break;
        }
    }
    return found;
}

test howManyXmas {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const example =
        \\MMMSXXMASM
        \\MSAMXMSMSA
        \\AMXSXMAAMM
        \\MSAMASMSMX
        \\XMASAMXAMM
        \\XXAMMXXAMA
        \\SMSMSASXSS
        \\SAXAMASAAA
        \\MAMMMXMMMM
        \\MXMXAXMASX
    ;

    const matrix = try parseIntoArray(example, allocator);
    try expectEqual(18, howManyXmas(matrix));
}
