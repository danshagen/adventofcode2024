const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = @embedFile("input.txt");
    std.debug.print("Searching for X-MAS...", .{});
    const num_xmas = howManyMas(try parseIntoArray(input, allocator));
    std.debug.print("Found X-MAS {d} times!", .{num_xmas});
}

fn parseIntoArray(input: []const u8, allocator: std.mem.Allocator) ![]const []const u8 {
    var list = std.ArrayList([]const u8).init(allocator);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try list.append(line);
    }
    return list.items;
}

fn howManyMas(matrix: []const []const u8) usize {
    var found: usize = 0;
    // find all X
    for (matrix, 0..) |row, y| {
        var index: usize = 0;
        while (std.mem.indexOf(u8, row[index..], "A")) |start| {
            const x = index + start;

            // check if there is MAS in all the directions
            std.debug.print("\nA at {d},{d} ", .{ x, y });

            // check if too near edge
            if (x > 0 and y > 0 and x + 1 < row.len and y + 1 < matrix.len) {
                const ul = matrix[y - 1][x - 1];
                const u = matrix[y - 1][x];
                const ur = matrix[y - 1][x + 1];
                const l = matrix[y][x - 1];
                const dl = matrix[y + 1][x - 1];
                const d = matrix[y + 1][x];
                const dr = matrix[y + 1][x + 1];
                const r = matrix[y][x + 1];
                std.debug.print("{c}{c}{c} {c} {c} {c}{c}{c} ", .{ ul, u, ur, l, r, dl, d, dr });

                if (((ul == 'M' and dr == 'S') or (ul == 'S' and dr == 'M')) and ((ur == 'M' and dl == 'S') or (ur == 'S' and dl == 'M'))) {
                    std.debug.print("X ", .{});
                    found += 1;
                }
            }
            index += start + 1;
            if (index >= row.len)
                break;
        }
    }
    return found;
}

test howManyMas {
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
    try expectEqual(9, howManyMas(matrix));
}
