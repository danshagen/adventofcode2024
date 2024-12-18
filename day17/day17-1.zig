const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nProcessing...\n", .{});
    const input = @embedFile("input.txt");
    var processor = try parseInput(allocator, input);
    std.debug.print("\nparsed: {any}\n", .{processor});

    var outputs = std.ArrayList(u32).init(allocator);
    while (!processor.halted) {
        processor.print();
        if (processor.process()) |output| {
            try outputs.append(output);
        }
    }
    processor.print();

    std.debug.print("\n\noutputs: ", .{});
    for (outputs.items) |output| {
        std.debug.print("{d},", .{output});
    }
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !Processor {
    var values = std.mem.tokenizeAny(u8, input, "Register ABC:Program, \n");
    const a = try std.fmt.parseInt(u32, values.next().?, 10);
    const b = try std.fmt.parseInt(u32, values.next().?, 10);
    const c = try std.fmt.parseInt(u32, values.next().?, 10);

    var program = std.ArrayList(u3).init(allocator);
    while (values.next()) |value| {
        const byte = try std.fmt.parseInt(u3, value, 10);
        try program.append(byte);
    }

    return .{
        .A = a,
        .B = b,
        .C = c,
        .IP = 0,
        .program = try program.toOwnedSlice(),
        .halted = false,
    };
}

const Opcode = enum(u3) {
    adv = 0,
    bxl = 1,
    bst = 2,
    jnz = 3,
    bxc = 4,
    out = 5,
    bdv = 6,
    cdv = 7,
};

const Processor = struct {
    A: u32,
    B: u32,
    C: u32,
    IP: u32, // instruction pointer
    program: []u3,
    halted: bool,

    const Self = @This();

    fn print(self: *Self) void {
        std.debug.print("\n\nIP: {d: >8} A: {d: >8} B: {d: >8} C: {d: >8}", .{
            self.IP,
            self.A,
            self.B,
            self.C,
        });
    }

    /// process the next instruction
    fn process(self: *Self) ?u32 {
        std.debug.assert(!self.halted);
        var output: ?u32 = null;

        // get opcode and literal
        const opcode: Opcode = @enumFromInt(self.program[self.IP]);
        const literal: u3 = self.program[self.IP + 1];
        const combo: u32 = switch (literal) {
            0...3 => literal,
            4 => self.A,
            5 => self.B,
            6 => self.C,
            7 => 0, // should not happen
        };
        std.debug.print("\n{s} {d}/{d}", .{ @tagName(opcode), literal, combo });

        // increment IP
        self.IP += 2;

        // process opcode
        switch (opcode) {
            Opcode.adv => {
                // A = A / 2**combo
                const denominator = std.math.pow(u32, 2, combo);
                const result = self.A / denominator;
                std.debug.print(" | A / 2 ** combo = {d} / 2**{d} = {d} / {d} = {d}", .{ self.A, combo, self.A, denominator, result });
                self.A = result;
            },
            Opcode.bxl => {
                // B = literal XOR B
                self.B = self.B ^ literal;
            },
            Opcode.bst => {
                // B = combo % 8
                self.B = combo % 8;
            },
            Opcode.jnz => {
                // if A != 0 jump IP = literal
                if (self.A != 0)
                    self.IP = literal;
            },
            Opcode.bxc => {
                // B = B ^ C
                self.B = self.B ^ self.C;
            },
            Opcode.out => {
                // output = combo % 8
                output = combo % 8;
            },
            Opcode.bdv => {
                // B = A / 2**combo
                const denominator = std.math.pow(u32, 2, combo);
                const result = self.A / denominator;
                std.debug.print(" | A / 2 ** combo = {d} / 2**{d} = {d} / {d} = {d}", .{ self.A, combo, self.A, denominator, result });
                self.B = result;
            },
            Opcode.cdv => {
                // C = A / 2**combo
                const denominator = std.math.pow(u32, 2, combo);
                const result = self.A / denominator;
                std.debug.print(" | A / 2 ** combo = {d} / 2**{d} = {d} / {d} = {d}", .{ self.A, combo, self.A, denominator, result });
                self.C = result;
            },
        }

        // check for valid IP
        if (self.IP >= self.program.len)
            self.halted = true;

        if (output != null)
            std.debug.print("\noutput: {d}", .{output.?});
        return output;
    }
};

test Processor {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const example =
        \\Register A: 729
        \\Register B: 0
        \\Register C: 0
        \\
        \\Program: 0,1,5,4,3,0
    ;

    var processor = try parseInput(allocator, example);
    std.debug.print("\nparsed: {any}\n", .{processor});

    var outputs = std.ArrayList(u32).init(allocator);
    while (!processor.halted) {
        processor.print();
        if (processor.process()) |output| {
            try outputs.append(output);
        }
    }
    processor.print();

    std.debug.print("\n\noutputs: ", .{});
    for (outputs.items) |output| {
        std.debug.print("{d},", .{output});
    }

    const correct_outputs = [_]u32{ 4, 6, 3, 5, 6, 3, 5, 2, 1, 0 };
    try expectEqual(correct_outputs.len, outputs.items.len);
    for (correct_outputs, outputs.items) |correct, output| {
        try expectEqual(correct, output);
    }

    // run single examples
    // If register C contains 9, the program 2,6 would set register B to 1
    processor.halted = false;
    processor.IP = 0;

    processor.C = 9;
    var example_1 = [_]u3{ 2, 6 };
    processor.program = example_1[0..];
    _ = processor.process();
    try expectEqual(1, processor.B);

    // If register A contains 10, the program 5,0,5,1,5,4 would output 0,1,2.
    processor.halted = false;
    processor.IP = 0;
    outputs.clearRetainingCapacity();

    processor.A = 10;
    var example_2 = [_]u3{ 5, 0, 5, 1, 5, 4 };
    processor.program = example_2[0..];
    while (!processor.halted) {
        processor.print();
        if (processor.process()) |output| {
            try outputs.append(output);
        }
    }
    const correct_outputs_2 = [_]u32{ 0, 1, 2 };
    try expectEqual(correct_outputs_2.len, outputs.items.len);
    for (correct_outputs_2, outputs.items) |correct, output| {
        try expectEqual(correct, output);
    }

    // If register A contains 2024, the program 0,1,5,4,3,0 would output 4,2,5,6,7,7,7,7,3,1,0 and leave 0 in register A.
    processor.halted = false;
    processor.IP = 0;
    outputs.clearRetainingCapacity();

    processor.A = 2024;
    var example_3 = [_]u3{ 0, 1, 5, 4, 3, 0 };
    processor.program = example_3[0..];
    while (!processor.halted) {
        processor.print();
        if (processor.process()) |output| {
            try outputs.append(output);
        }
    }
    const correct_outputs_3 = [_]u32{ 4, 2, 5, 6, 7, 7, 7, 7, 3, 1, 0 };
    try expectEqual(correct_outputs_3.len, outputs.items.len);
    for (correct_outputs_3, outputs.items) |correct, output| {
        try expectEqual(correct, output);
    }
    try expectEqual(0, processor.A);

    // If register B contains 29, the program 1,7 would set register B to 26.
    processor.halted = false;
    processor.IP = 0;

    processor.B = 29;
    var example_4 = [_]u3{ 1, 7 };
    processor.program = example_4[0..];
    while (!processor.halted) {
        processor.print();
        _ = processor.process();
    }

    try expectEqual(26, processor.B);

    // If register B contains 2024 and register C contains 43690, the program 4,0 would set register B to 44354.
    processor.halted = false;
    processor.IP = 0;

    processor.B = 2024;
    processor.C = 43690;
    var example_5 = [_]u3{ 4, 0 };
    processor.program = example_5[0..];
    while (!processor.halted) {
        processor.print();
        _ = processor.process();
    }

    try expectEqual(44354, processor.B);
}
