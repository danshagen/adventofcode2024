const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const input = @embedFile("input.txt");

    std.debug.print("\nCalculating secret and sum of secrets...\n", .{});
    const parsed = try parseInput(allocator, input);
    defer allocator.free(parsed);
    const best = try findMostBananas(allocator, parsed, 2000);
    std.debug.print("\n\nMost bananas possible: {d}", .{best});
}

const Secret = u24;
const Price = i8;
const Sequence = [4]Price;

fn parseInput(allocator: std.mem.Allocator, input: []const u8) ![]Secret {
    var list = std.ArrayList(Secret).init(allocator);
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const number = try std.fmt.parseInt(Secret, line, 10);
        try list.append(number);
    }
    return list.toOwnedSlice();
}

fn findMostBananas(allocator: std.mem.Allocator, initial: []Secret, num: usize) !usize {
    // keep a hashmap of sequences and their prices (sum up for each trader)
    var sequences = std.AutoHashMap(Sequence, usize).init(allocator);
    // keep a set of sequences for each trader: only the first occurance of a sequence is possible
    var sequence_set = std.AutoHashMap(Sequence, void).init(allocator);

    for (initial) |initial_secret| {
        var secret: Secret = initial_secret;
        var sequence: Sequence = undefined;
        sequence_set.clearRetainingCapacity();

        var price: Price = undefined;
        var last_price: Price = @intCast(secret % 10);

        std.debug.print("\ninitial {d}... ", .{initial_secret});
        for (0..num) |i| {
            // calculate secret
            secret = (secret << 6) ^ secret;
            secret = (secret >> 5) ^ secret;
            secret = (secret << 11) ^ secret;
            // calculate price and price_change
            price = @intCast(secret % 10);
            const price_change = price - last_price;
            last_price = price;
            sequence[3] = sequence[2];
            sequence[2] = sequence[1];
            sequence[1] = sequence[0];
            sequence[0] = price_change;
            // add to sequences (if the sequence did not happen yet)
            if (i >= 4 and !sequence_set.contains(sequence)) {
                try sequence_set.put(sequence, {});

                var bananas = if (sequences.contains(sequence)) sequences.get(sequence).? else 0;
                bananas += @intCast(price);
                try sequences.put(sequence, bananas);
            }
        }
        std.debug.print("{d}th: {d}", .{ num, secret });
    }

    var all_sequences = sequences.iterator();
    var best_sequence: Sequence = undefined;
    var most_bananas: usize = 0;
    while (all_sequences.next()) |entry| {
        // if the sequences yields more bananas
        if (entry.value_ptr.* > most_bananas) {
            most_bananas = entry.value_ptr.*;
            best_sequence = entry.key_ptr.*;
        }
    }
    return most_bananas;
}
