const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Tile = enum(u8) {
    floor = '.',
    obstruction = '#',
    gd = 'v',
    gu = '^',
    gr = '>',
    gl = '<',
};

fn parseInput(this: *const @This()) !std.ArrayList(std.ArrayList(Tile)) {
    var lines = mem.tokenizeScalar(u8, this.input, '\n');
    var map = std.ArrayList(std.ArrayList(Tile)).init(this.allocator);
    while (lines.next()) |line| {
        var row = try std.ArrayList(Tile).initCapacity(this.allocator, line.len);
        const trimmed = std.mem.trim(u8, line, " ");
        for (trimmed) |t| {
            std.log.err("t: {d}", .{t});
            try row.append(@enumFromInt(t));
        }
        try map.append(row);
    }

    return map;
}

const Heading = enum(u8) {
    up = '^',
    down = 'v',
    left = '<',
    right = '>',
};

const Pos = struct { x: usize, y: usize, dir: Heading };

fn step(pos: Pos, map: std.ArrayList(std.ArrayList(Tile))) ?Pos {
    switch (pos.dir) {
        Heading.up => {
            if (pos.y == 0) return null;

            if (map.items[pos.y - 1].items[pos.x] != Tile.obstruction) {
                return Pos{ .dir = pos.dir, .x = pos.x, .y = pos.y - 1 };
            } else {
                return Pos{ .dir = Heading.right, .x = pos.x, .y = pos.y };
            }
        },
        Heading.down => {
            if (pos.y + 1 == map.items.len) return null;

            if (map.items[pos.y + 1].items[pos.x] != Tile.obstruction) {
                return Pos{ .dir = pos.dir, .x = pos.x, .y = pos.y + 1 };
            } else {
                return Pos{ .dir = Heading.left, .x = pos.x, .y = pos.y };
            }
        },
        Heading.left => {
            if (pos.x == 0) return null;

            if (map.items[pos.y].items[pos.x - 1] != Tile.obstruction) {
                return Pos{ .dir = pos.dir, .x = pos.x - 1, .y = pos.y };
            } else {
                return Pos{ .dir = Heading.up, .x = pos.x, .y = pos.y };
            }
        },
        Heading.right => {
            if (pos.x + 1 == map.items[pos.y].items.len) return null;

            if (map.items[pos.y].items[pos.x + 1] != Tile.obstruction) {
                return Pos{ .dir = pos.dir, .x = pos.x + 1, .y = pos.y };
            } else {
                return Pos{ .dir = Heading.down, .x = pos.x, .y = pos.y };
            }
        },
    }
}

pub fn part1(this: *const @This()) !?i64 {
    var result: i64 = 0;
    const map = try parseInput(this);

    var pos = Pos{ .x = 0, .y = 0, .dir = Heading.up };
    var width: usize = 0;
    var height: usize = 0;

    for (map.items, 0..) |row, y| {
        height = y;
        for (row.items, 0..) |tile, x| {
            width = x;
            switch (tile) {
                Tile.gd, Tile.gl, Tile.gr, Tile.gu => {
                    pos.x = x;
                    pos.y = y;
                    pos.dir = @enumFromInt(@intFromEnum(tile));
                },
                else => {},
            }
        }
    }

    width += 1;
    height += 1;

    std.log.err("start: ({d},{d})", .{ pos.x, pos.y });

    const Vec2 = struct { x: usize, y: usize };
    var visited = std.AutoHashMap(Vec2, bool).init(this.allocator);
    defer visited.deinit();

    while (step(pos, map)) |next| {
        const wasVisited = visited.get(Vec2{ .x = next.x, .y = next.y });
        try visited.put(Vec2{ .x = next.x, .y = next.y }, true);
        std.log.err("next: ({d},{d}) {any}", .{ next.x, next.y, next.dir });
        pos = next;
        if (wasVisited == null) {
            result += 1;
        }
    }

    for (map.items) |row| {
        row.deinit();
    }

    map.deinit();

    return result;
}

pub fn part2(this: *const @This()) !?i64 {
    _ = this;
    return null;
}

test "it should do nothing" {
    const allocator = std.testing.allocator;
    const input =
        \\ ....#.....
        \\ .........#
        \\ ..........
        \\ ..#.......
        \\ .......#..
        \\ ..........
        \\ .#..^.....
        \\ ........#.
        \\ #.........
        \\ ......#...
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(41, try problem.part1());
    try std.testing.expectEqual(null, try problem.part2());
}
