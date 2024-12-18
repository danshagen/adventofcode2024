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

    processor.disassemble();
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

    fn disassemble(self: *Self) void {
        std.debug.print("\n\nDissassembling: {any}", .{self.program});
        var ip: usize = 0;
        while (ip < self.program.len) {
            const opcode: Opcode = @enumFromInt(self.program[ip]);
            const literal: u3 = self.program[ip + 1];
            const combo: u32 = switch (literal) {
                0...3 => literal,
                4 => self.A,
                5 => self.B,
                6 => self.C,
                7 => 0, // should not happen
            };
            std.debug.print("\n   {s} {d} ({d: >8})", .{ @tagName(opcode), literal, combo });

            ip += 2;
        }
    }
};

test Processor {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const example =
        \\Register A: 117440
        \\Register B: 0
        \\Register C: 0
        \\
        \\Program: 0,3,5,4,3,0
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

    const correct_outputs = [_]u32{ 0, 3, 5, 4, 3, 0 };
    try expectEqual(correct_outputs.len, outputs.items.len);
    for (correct_outputs, outputs.items) |correct, output| {
        try expectEqual(correct, output);
    }

    processor.disassemble();
}
