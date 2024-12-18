const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nProcessing...\n", .{});
    const input = @embedFile("input.txt");
    var processor = try parseInput(allocator, input);
    processor.A = 107413700225434;
    std.debug.print("\nparsed: {any}\n", .{processor});

    var outputs = std.ArrayList(u64).init(allocator);
    processor.printHeader();
    while (!processor.halted) {
        if (processor.process()) |output| {
            try outputs.append(output);
        }
    }

    std.debug.print("\n\noutputs: ", .{});
    for (outputs.items) |output| {
        std.debug.print("{d},", .{output});
    }

    processor.disassemble();
}

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !Processor {
    var values = std.mem.tokenizeAny(u8, input, "Register ABC:Program, \n");
    const a = try std.fmt.parseInt(u64, values.next().?, 10);
    const b = try std.fmt.parseInt(u64, values.next().?, 10);
    const c = try std.fmt.parseInt(u64, values.next().?, 10);

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
    A: u64,
    B: u64,
    C: u64,
    IP: u64, // instruction pointer
    program: []u3,
    halted: bool,

    const Self = @This();

    fn printHeader(self: *Self) void {
        _ = self;
        std.debug.print("\nIP  . .  ___ |        A |        B |        V | calculation", .{});
        std.debug.print("\n-------------+----------+----------+----------+------------------------------------------------------", .{});
    }

    /// process the next instruction
    fn process(self: *Self) ?u64 {
        std.debug.assert(!self.halted);
        var output: ?u64 = null;

        // get opcode and literal
        const opcode: Opcode = @enumFromInt(self.program[self.IP]);
        const literal: u3 = self.program[self.IP + 1];
        const combo: u64 = switch (literal) {
            0...3 => literal,
            4 => self.A,
            5 => self.B,
            6 => self.C,
            7 => 0, // should not happen
        };

        std.debug.print("\n{d: >2}  {d} {d}  {s} | {d: >8} | {d: >8} | {d: >8} | ", .{
            self.IP,
            self.program[self.IP],
            self.program[self.IP + 1],
            @tagName(opcode),
            self.A,
            self.B,
            self.C,
        });

        // increment IP
        self.IP += 2;

        // process opcode
        switch (opcode) {
            Opcode.adv => {
                // A = A / 2**combo
                const denominator = std.math.pow(u64, 2, combo);
                const result = self.A / denominator;
                std.debug.print("A / 2 ** combo = {d} / 2**{d} = {d} / {d} = {d}", .{ self.A, combo, self.A, denominator, result });
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
                if (self.A != 0) {
                    self.IP = literal;
                    std.debug.print("jump {d}", .{self.IP});
                } else {
                    std.debug.print("no jump", .{});
                }
            },
            Opcode.bxc => {
                // B = B ^ C
                self.B = self.B ^ self.C;
            },
            Opcode.out => {
                // output = combo % 8
                output = combo % 8;
                std.debug.print("output {d}", .{output.?});
            },
            Opcode.bdv => {
                // B = A / 2**combo
                const denominator = std.math.pow(u64, 2, combo);
                const result = self.A / denominator;
                std.debug.print("A / 2 ** combo = {d} / 2**{d} = {d} / {d} = {d}", .{ self.A, combo, self.A, denominator, result });
                self.B = result;
            },
            Opcode.cdv => {
                // C = A / 2**combo
                const denominator = std.math.pow(u64, 2, combo);
                const result = self.A / denominator;
                std.debug.print("A / 2 ** combo = {d} / 2**{d} = {d} / {d} = {d}", .{ self.A, combo, self.A, denominator, result });
                self.C = result;
            },
        }

        // check for valid IP
        if (self.IP >= self.program.len)
            self.halted = true;

        return output;
    }

    fn disassemble(self: *const Self) void {
        std.debug.print("\n\nDissassembling: {any}", .{self.program});
        var ip: usize = 0;
        while (ip < self.program.len) {
            std.debug.print("\n {d} {d}   ", .{ self.program[ip], self.program[ip + 1] });

            const opcode: Opcode = @enumFromInt(self.program[ip]);
            const literal: u3 = self.program[ip + 1];
            const combo: u8 = switch (literal) {
                0...3 => '0' + @as(u8, @intCast(literal)),
                4 => 'A',
                5 => 'B',
                6 => 'C',
                7 => '!', // should not happen
            };
            switch (opcode) {
                Opcode.adv => {
                    // A = A / 2**combo
                    std.debug.print("adv 2**{c}", .{combo});
                },
                Opcode.bxl => {
                    // B = literal XOR B
                    std.debug.print("bxl {d}", .{literal});
                },
                Opcode.bst => {
                    // B = combo % 8
                    std.debug.print("bst {c} % 8", .{combo});
                },
                Opcode.jnz => {
                    // if A != 0 jump IP = literal
                    std.debug.print("jnz {d}", .{literal});
                },
                Opcode.bxc => {
                    // B = B ^ C
                    std.debug.print("bxc", .{});
                },
                Opcode.out => {
                    // output = combo % 8
                    std.debug.print("out {c} % 8", .{combo});
                },
                Opcode.bdv => {
                    // B = A / 2**combo
                    std.debug.print("bdv 2**{c}", .{combo});
                },
                Opcode.cdv => {
                    // C = A / 2**combo
                    std.debug.print("cdv 2**{c}", .{combo});
                },
            }

            ip += 2;
        }
        std.debug.print("\n", .{});
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

    var outputs = std.ArrayList(u64).init(allocator);
    processor.printHeader();
    while (!processor.halted) {
        if (processor.process()) |output| {
            try outputs.append(output);
        }
    }

    std.debug.print("\n\noutputs: ", .{});
    for (outputs.items) |output| {
        std.debug.print("{d},", .{output});
    }

    const correct_outputs = [_]u64{ 0, 3, 5, 4, 3, 0 };
    try expectEqual(correct_outputs.len, outputs.items.len);
    for (correct_outputs, outputs.items) |correct, output| {
        try expectEqual(correct, output);
    }

    processor.disassemble();
}
