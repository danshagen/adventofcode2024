const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

const input = @embedFile("input.txt");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("Calculating reactor safety (dampener on)...\n", .{});
    var reports = try Reports.init(input, allocator);
    var safety: u32 = 0;
    report_loop: while (try reports.next()) |report| {
        if (isReportSafe(report.items)) {
            safety += 1;
        } else {
            // dampener: remove one item and check again
            for (0..report.items.len) |i| {
                var cloned_report = try report.clone();
                defer cloned_report.deinit();

                _ = cloned_report.orderedRemove(i);
                if (isReportSafe(cloned_report.items)) {
                    safety += 1;
                    continue :report_loop;
                }
            }
        }
    }
    std.debug.print("reactor safety: {d}\n", .{safety});
}

/// Reports iterator: returns an ArrayList for each report in the string
const Reports = struct {
    lines: std.mem.TokenIterator(u8, std.mem.DelimiterType.scalar),
    _allocator: std.mem.Allocator,

    fn init(string: []const u8, allocator: std.mem.Allocator) !Reports {
        return Reports{ .lines = std.mem.tokenizeScalar(u8, string, '\n'), ._allocator = allocator };
    }

    fn next(self: *Reports) !?std.ArrayList(u32) {
        // check if there is more lines
        var list = std.ArrayList(u32).init(self._allocator);
        const line = self.lines.next();
        if (line == null)
            return null;

        var it = std.mem.tokenizeScalar(u8, line.?, ' ');
        while (it.next()) |value| {
            const number: u32 = try std.fmt.parseInt(u32, value, 10);
            try list.append(number);
        }

        return list;
    }
};

test Reports {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const example =
        \\7 6 4 2 1
        \\1 2 7 8 9
        \\9 7 6 2 1
        \\1 3 2 4 5
        \\8 6 4 4 1
        \\1 3 6 7 9
    ;

    var reports = try Reports.init(example, allocator);

    try expect(std.mem.eql(u32, &[_]u32{ 7, 6, 4, 2, 1 }, (try reports.next()).?.items));
    try expect(std.mem.eql(u32, &[_]u32{ 1, 2, 7, 8, 9 }, (try reports.next()).?.items));
    try expect(std.mem.eql(u32, &[_]u32{ 9, 7, 6, 2, 1 }, (try reports.next()).?.items));
    try expect(std.mem.eql(u32, &[_]u32{ 1, 3, 2, 4, 5 }, (try reports.next()).?.items));
    try expect(std.mem.eql(u32, &[_]u32{ 8, 6, 4, 4, 1 }, (try reports.next()).?.items));
    try expect(std.mem.eql(u32, &[_]u32{ 1, 3, 6, 7, 9 }, (try reports.next()).?.items));
    try expectEqual(null, try reports.next());
}

fn isReportSafe(report: []const u32) bool {
    const increasing: bool = report[1] > report[0];
    var last_value = report[0];
    for (report[1..]) |value| {
        const diff = @as(i64, value) - @as(i64, last_value);
        if (increasing) {
            if (diff < 1 or diff > 3)
                return false;
        } else {
            if (diff > -1 or diff < -3)
                return false;
        }
        last_value = value;
    }
    return true;
}

test isReportSafe {
    try expectEqual(true, isReportSafe(&[_]u32{ 7, 6, 4, 2, 1 }));
    try expectEqual(false, isReportSafe(&[_]u32{ 1, 2, 7, 8, 9 }));
    try expectEqual(false, isReportSafe(&[_]u32{ 9, 7, 6, 2, 1 }));
    try expectEqual(false, isReportSafe(&[_]u32{ 1, 3, 2, 4, 5 }));
    try expectEqual(false, isReportSafe(&[_]u32{ 8, 6, 4, 4, 1 }));
    try expectEqual(true, isReportSafe(&[_]u32{ 1, 3, 6, 7, 9 }));
}
