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
        if (block == null)
            break;

        checksum += idx * block.?;
    }
    std.debug.print("\n\ndisk checksum: {d}", .{checksum});
}

const DiskMap = []Block;
const Block = ?u16; // file id or null (free space)

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !DiskMap {
    std.debug.print("\ninput: {s}", .{input});
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
    std.debug.print("\ndisk : ", .{});
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
    var first_space: usize = 0;
    var last_file: usize = disk_map.len - 1;

    defrag: while (first_space < last_file) {
        // search for first space
        while (disk_map[first_space] != null) {
            first_space += 1;
            if (first_space == disk_map.len or first_space == last_file)
                break :defrag;
        }
        // search for last file
        while (disk_map[last_file] == null) {
            last_file -= 1;
            if (last_file == 0 or last_file == first_space)
                break :defrag;
        }

        // switch them
        disk_map[first_space] = disk_map[last_file];
        disk_map[last_file] = null;

        // std.debug.print("\ndfrag: ", .{});
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
    try expectEqual(1928, checksum);
}
