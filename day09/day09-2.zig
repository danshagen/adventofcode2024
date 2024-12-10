const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const input = @embedFile("input.txt");

    std.debug.print("\nDefragmenting disk...\n", .{});
    const disk_map = try parseInput(allocator, input[0 .. input.len - 1]);
    defer allocator.free(disk_map);
    defragDisk(disk_map);

    var checksum: usize = 0;
    for (disk_map, 0..) |block, idx| {
        // check if checked all files and reched free space
        if (block != null)
            checksum += idx * block.?;
    }
    std.debug.print("\n\ndisk checksum: {d}", .{checksum});
}

const DiskMap = []Block;
const Block = ?u16; // file id or null (free space)

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !DiskMap {
    // std.debug.print("\ninput: {s}", .{input});
    var list = std.ArrayList(Block).init(allocator);
    var id: u16 = 0;
    var i: usize = 0;
    while (i < input.len) {
        // first: file
        var file_len = input[i] - '0';
        while (file_len > 0) : (file_len -= 1)
            try list.append(id);

        // second: free space
        if (i + 1 == input.len)
            break;
        var free_len = input[i + 1] - '0';
        while (free_len > 0) : (free_len -= 1)
            try list.append(null);
        id += 1;
        i += 2;
    }

    // print disk map
    std.debug.print("\n", .{});
    for (list.items) |block| {
        if (block != null) {
            std.debug.print("{d}", .{block.?});
        } else {
            std.debug.print(".", .{});
        }
    }

    return list.toOwnedSlice();
}

test parseInput {
    const allocator = std.testing.allocator;
    const example = "2333133121414131402";

    const disk_map = try parseInput(allocator, example);
    defer allocator.free(disk_map);
}

fn defragDisk(disk_map: DiskMap) void {
    var file_index: usize = disk_map.len - 1;

    defrag_loop: while (file_index > 0) {
        // find file and length
        // skip over free space
        while (disk_map[file_index] == null)
            file_index -= 1;
        const file_end = file_index;
        const file_id = disk_map[file_index].?;
        while (disk_map[file_index] == file_id) {
            if (file_index == 0)
                break :defrag_loop;
            file_index -= 1;
        }
        const file_start = file_index + 1;
        const file_len = file_end - file_start + 1;

        // std.debug.print("\n", .{});
        // for (0..file_start) |_|
        //     std.debug.print(" ", .{});
        // for (0..file_len) |_|
        //     std.debug.print("^", .{});

        // find free space large enough for file
        var free_index: usize = 0;
        var free_len: usize = 0;
        while (free_len < file_len) {
            if (disk_map[free_index] == null) {
                free_len += 1;
            } else {
                free_len = 0;
            }
            free_index += 1;
            if (free_index == file_index or free_index == disk_map.len)
                continue :defrag_loop;
        }
        const free_start = free_index - free_len;

        // std.debug.print("\n", .{});
        // for (0..free_start) |_|
        //     std.debug.print(" ", .{});
        // for (0..free_len) |_|
        //     std.debug.print("v", .{});

        // move file to space
        for (0..file_len) |i| {
            disk_map[free_start + i] = disk_map[file_start + i];
            disk_map[file_start + i] = null;
        }

        // std.debug.print("\n", .{});
        // for (disk_map) |block| {
        //     if (block != null) {
        //         std.debug.print("{d}", .{block.?});
        //     } else {
        //         std.debug.print(".", .{});
        //     }
        // }
    }
}

test defragDisk {
    const allocator = std.testing.allocator;
    const example = "2333133121414131402";

    const disk_map = try parseInput(allocator, example);
    defer allocator.free(disk_map);

    defragDisk(disk_map);

    var checksum: usize = 0;
    for (disk_map, 0..) |block, idx| {
        if (block != null)
            checksum += idx * block.?;
    }
    try expectEqual(2858, checksum);
}

test edgecase {
    const example = "354631466260";

    const disk_map = try parseInput(allocator, example);
    defer allocator.free(disk_map);

    defragDisk(disk_map);

    var checksum: usize = 0;
    for (disk_map, 0..) |block, idx| {
        if (block != null)
            checksum += idx * block.?;
    }
    try expectEqual(1325, checksum);
}
