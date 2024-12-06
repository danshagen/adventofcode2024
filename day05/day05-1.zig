const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input = @embedFile("input.txt");
    const page_rules = try extractPageRules(input, allocator);
    const updates = try extractUpdates(input, allocator);

    std.debug.print("calculating sum of middle page numbers of correct updates...\n", .{});
    var sum: usize = 0;
    for (updates) |update| {
        if (getPrintMidlePage(update, page_rules)) |middle_page| {
            sum += middle_page;
        }
    }
    std.debug.print("sum of middle page numbers: {d}\n", .{sum});
}

const example =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
;

const Set = std.AutoHashMap(u32, void);
const Rules = std.AutoHashMap(u32, *Set);
fn extractPageRules(input: []const u8, allocator: std.mem.Allocator) !Rules {
    var map = std.AutoHashMap(u32, *Set).init(allocator);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        // check if this line contains report rules by whether there is a | character
        if (std.mem.indexOf(u8, line, "|") == null)
            continue;

        // extract first and second number
        var numbers = std.mem.tokenizeScalar(u8, line, '|');
        const first = try std.fmt.parseInt(u32, numbers.next().?, 10);
        const second = try std.fmt.parseInt(u32, numbers.next().?, 10);
        std.debug.assert(numbers.next() == null);

        // check if a rule for the first number already exists
        if (map.contains(first)) {
            const rule = map.get(first).?;
            // put into Set (HashMap(u32, void)) -> do not care if already exists, just put
            try rule.*.put(second, {});
            std.debug.print("\n{d} append {d}: ", .{ first, second });
            var it = rule.*.keyIterator();
            while (it.next()) |key| {
                std.debug.print("{d} ", .{key.*});
            }
        } else {
            const new_rule = try allocator.create(Set);
            new_rule.* = Set.init(allocator);
            try new_rule.*.put(second, {});
            try map.put(first, new_rule);
            std.debug.print("\n{d} create {d}: ", .{ first, second });
            var it = new_rule.*.keyIterator();
            while (it.next()) |key| {
                std.debug.print("{d} ", .{key.*});
            }
        }
    }

    return map;
}

test extractPageRules {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const page_rules = try extractPageRules(example, allocator);
    var rules = page_rules.iterator();
    std.debug.print("\n\nfinal:\n", .{});
    while (rules.next()) |rule| {
        std.debug.print("\n{d}: ", .{rule.key_ptr.*});
        var it = rule.value_ptr.*.keyIterator();
        while (it.next()) |key_ptr| {
            std.debug.print("{d} ", .{key_ptr.*});
        }
    }
}

fn extractUpdates(input: []const u8, allocator: std.mem.Allocator) ![]const []const u32 {
    var list = std.ArrayList([]u32).init(allocator);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        // check if this line contains updates by whether there is a comma
        if (std.mem.indexOf(u8, line, ",") == null)
            continue;

        var update = std.ArrayList(u32).init(allocator);
        var numbers = std.mem.tokenizeScalar(u8, line, ',');
        while (numbers.next()) |number| {
            try update.append(try std.fmt.parseInt(u32, number, 10));
        }
        try list.append(try update.toOwnedSlice());
    }

    return try list.toOwnedSlice();
}

test extractUpdates {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const updates = try extractUpdates(example, allocator);
    std.debug.print("\n{any}", .{updates});
}

fn getPrintMidlePage(pages: []const u32, rules: Rules) ?usize {
    // go through all numbers and check if any rules are broken
    // looking up a number gives the numbers that have to follow
    // this means, that if any numbers in the rule are found before
    // the print order is incorrect
    for (pages, 0..) |page, i| {
        // for all page numbers in print order
        if (rules.get(page)) |rule| {
            // check rule
            var rule_pages = rule.keyIterator();
            while (rule_pages.next()) |rule_page| {
                // check if any of the pages in the rules happen before our index
                if (std.mem.indexOfScalar(u32, pages, rule_page.*)) |rule_page_index| {
                    if (rule_page_index < i)
                        return null;
                }
            }
        }
    }

    return pages[pages.len / 2];
}

test getPrintMidlePage {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const page_rules = try extractPageRules(example, allocator);
    const updates = try extractUpdates(example, allocator);

    try expectEqual(61, getPrintMidlePage(updates[0], page_rules).?);
    try expectEqual(53, getPrintMidlePage(updates[1], page_rules).?);
    try expectEqual(29, getPrintMidlePage(updates[2], page_rules).?);
    try expectEqual(null, getPrintMidlePage(updates[3], page_rules));
    try expectEqual(null, getPrintMidlePage(updates[4], page_rules));
    try expectEqual(null, getPrintMidlePage(updates[5], page_rules));
}
