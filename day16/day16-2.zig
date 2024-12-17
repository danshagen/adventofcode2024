const std = @import("std");
const expectEqual = std.testing.expectEqual;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("\nFinding best path...\n", .{});
    const input = @embedFile("input.txt");
    const parsed = try parseInput(allocator, input);
    const total_cost = try findBestPath(allocator, parsed.map, parsed.start, parsed.end);
    std.debug.print("\n\nbest path cost: {d}", .{total_cost});
}

const Position = @Vector(2, i16);

const Map = struct { map: [][]const u8, start: Position, end: Position };

fn parseInput(allocator: std.mem.Allocator, input: []const u8) !Map {
    var start: Position = undefined;
    var end: Position = undefined;
    var map = std.ArrayList([]const u8).init(allocator);

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var y: i16 = 0;
    while (lines.next()) |line| {
        for (line, 0..) |ch, x| {
            if (ch == 'S')
                start = .{ @intCast(x), y };
            if (ch == 'E')
                end = .{ @intCast(x), y };
        }
        try map.append(line);
        y += 1;
    }

    return .{ .map = try map.toOwnedSlice(), .start = start, .end = end };
}

const Node = struct {
    position: Position,
    direction: Position,
};

const PriorityNode = struct { node: Node, priority: usize };

fn lessThan(context: void, a: PriorityNode, b: PriorityNode) std.math.Order {
    _ = context;
    return std.math.order(a.priority, b.priority);
}

const all_directions: [4]Position = .{
    .{ 1, 0 }, // right
    .{ 0, 1 }, // down
    .{ -1, 0 }, // left
    .{ 0, -1 }, // up
};

fn findBestPath(allocator: std.mem.Allocator, map: [][]const u8, start: Position, end: Position) !usize {
    // setup frontier as priority queue
    var frontier = std.PriorityQueue(PriorityNode, void, lessThan).init(allocator, {});

    // initialise with start position and direction
    const start_node: Node = .{ .position = start, .direction = .{ 1, 0 } }; // starting to the right
    try frontier.add(.{ .node = start_node, .priority = 0 });

    // hashmap for storing paths
    var came_from = std.AutoHashMap(Node, *std.ArrayList(Node)).init(allocator);

    // save costs
    var cost_so_far = std.AutoHashMap(Node, usize).init(allocator);
    try cost_so_far.put(start_node, 0);

    // init arraylist for neighbour nodes
    var neighbours = std.ArrayList(Node).init(allocator);

    while (frontier.count() > 0) {
        // get highest priority Node
        const current = frontier.remove();

        // get neighbours
        neighbours.clearRetainingCapacity(); // empty list
        for (all_directions) |direction| {
            const possible_neighbour: Node = .{
                .position = current.node.position + direction,
                .direction = direction,
            };
            const x = possible_neighbour.position[0];
            const y = possible_neighbour.position[1];
            // check bounds: is not necessary because of walls 3,8(0-1): 3,9(10) 3,9(0-1)
            // check for wall
            if (map[@intCast(y)][@intCast(x)] == '#')
                continue;

            try neighbours.append(possible_neighbour);
        }

        // for all neighbours (that are walkable)
        for (neighbours.items) |next| {
            // 1 extra cost and additional 1000 if we need to turn
            var new_cost: usize = cost_so_far.get(current.node).?;
            if (!std.meta.eql(next.direction, current.node.direction)) {
                new_cost += 1001;
            } else {
                new_cost += 1;
            }

            if (!cost_so_far.contains(next) or new_cost <= cost_so_far.get(next).?) {
                try cost_so_far.put(next, new_cost);
                try frontier.add(.{ .node = next, .priority = new_cost });

                var list: ?*std.ArrayList(Node) = came_from.get(next);
                if (list == null) {
                    list = try allocator.create(std.ArrayList(Node));
                    list.?.* = std.ArrayList(Node).init(allocator);
                    try came_from.put(next, list.?);
                }
                // only add if not already there
                var already_in_list = false;
                for (list.?.items) |node| {
                    if (std.meta.eql(node, current.node))
                        already_in_list = true;
                }
                if (!already_in_list)
                    try list.?.append(current.node);
                std.debug.print("\n{d},{d}({d}{d}): ", .{ next.position[0], next.position[1], next.direction[0], next.direction[1] });
                for (list.?.items) |node| {
                    std.debug.print("{d},{d}({d}{d}) ", .{ node.position[0], node.position[1], node.direction[0], node.direction[1] });
                }
            }
        }
    }

    // check if there is the end node (with any direction)
    var total_cost: usize = 1E10; // impossibly high cost
    var end_node: Node = undefined;
    for (all_directions) |direction| {
        if (cost_so_far.get(.{ .position = end, .direction = direction })) |cost| {
            std.debug.print("\n found end node with cost {d}\n", .{cost});
            if (cost < total_cost) {
                total_cost = cost;
                end_node = .{ .position = end, .direction = direction };
            }
        }
    }

    // go from the end to the start nodes and put every stepped on Node into hash map
    var best_path_nodes = std.AutoHashMap(Position, void).init(allocator);
    var path_nodes = std.ArrayList(Node).init(allocator);
    try path_nodes.append(end_node);
    while (path_nodes.items.len > 0) {
        // while there are more nodes to check
        const current = path_nodes.pop();
        std.debug.print("\npath: {d},{d}({d}{d}): ", .{ current.position[0], current.position[1], current.direction[0], current.direction[1] });
        try best_path_nodes.put(current.position, {});

        // stop at start
        if (std.meta.eql(start_node, current))
            continue;

        // look up nodes on the path as well
        const before_nodes: *std.ArrayList(Node) = came_from.get(current).?;
        for (before_nodes.items) |before| {
            std.debug.print("{d},{d}({d}{d}) ", .{ before.position[0], before.position[1], before.direction[0], before.direction[1] });
            try path_nodes.append(before);
        }
    }

    return best_path_nodes.count();
}

test parseInput {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const example =
        \\USE EXAMPLE FROM TEX
    ;

    const parsed = try parseInput(allocator, example);

    // ADD RESULT FROM EXAMPLE
    try expectEqual(0, try findBestPath(allocator, parsed.map, parsed.start, parsed.end));
}
