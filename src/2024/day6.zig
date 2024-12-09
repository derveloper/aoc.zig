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
    const map = try parseInput(this);

    var pos = Pos{ .x = 0, .y = 0, .dir = Heading.up };

    for (map.items, 0..) |row, y| {
        for (row.items, 0..) |tile, x| {
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

    // std.log.err("start: ({d},{d})", .{ pos.x, pos.y });

    const Vec2 = struct { x: usize, y: usize };
    var visited = std.AutoHashMap(Vec2, bool).init(this.allocator);
    defer visited.deinit();

    // try visited.put(Vec2{ .x = pos.x, .y = pos.y }, true);

    while (step(pos, map)) |next| {
        // std.log.err("next: ({d},{d}) {any}", .{ next.x, next.y, next.dir });
        if (visited.get(Vec2{ .x = pos.x, .y = pos.y }) == null)
            try visited.put(Vec2{ .x = pos.x, .y = pos.y }, true);
        pos = next;
    }

    try visited.put(Vec2{ .x = pos.x, .y = pos.y }, true);

    var result: i64 = 0;
    for (map.items, 0..) |row, y| {
        for (row.items, 0..) |tile, x| {
            if (visited.get(Vec2{ .x = x, .y = y })) |_| {
                std.debug.print("X", .{});
                result += 1;
            } else {
                std.debug.print("{c}", .{@intFromEnum(tile)});
            }
        }
        std.debug.print("\n", .{});
    }

    for (map.items) |row| {
        row.deinit();
    }

    map.deinit();

    return result;
}

fn isVisitedPos(pos: Pos, visited: std.ArrayList(Pos)) bool {
    for (visited.items) |v| {
        // std.log.err("searching {any}", .{pos});
        if (pos.x == v.x and pos.y == v.y and pos.dir == v.dir) {
            // std.log.err("found {any}", .{pos});
            return true;
        }
    }

    return false;
}

pub fn part2(this: *const @This()) !?i64 {
    const map = try parseInput(this);

    var loops: i64 = 0;

    for (0..map.items.len) |y| {
        for (0..map.items[y].items.len) |x| {
            var pos = Pos{ .x = 0, .y = 0, .dir = Heading.up };

            for (map.items, 0..) |row, yy| {
                for (row.items, 0..) |tile, xx| {
                    switch (tile) {
                        Tile.gd, Tile.gl, Tile.gr, Tile.gu => {
                            pos.x = xx;
                            pos.y = yy;
                            pos.dir = @enumFromInt(@intFromEnum(tile));
                        },
                        else => {},
                    }
                }
            }
            // std.log.err("starting pos: {any} {d},{d}", .{ pos, x, y });

            var visitedPos = std.ArrayList(Pos).init(this.allocator);
            defer visitedPos.deinit();
            const origTile = map.items[y].items[x];

            if (map.items[y].items[x] != Tile.obstruction and (pos.x != x or pos.y != y)) {
                map.items[y].items[x] = Tile.obstruction;
            } else {
                continue;
            }
            var steps: usize = 0;

            try visitedPos.append(pos);
            while (step(pos, map)) |next| {
                if (isVisitedPos(next, visitedPos)) {
                    // std.log.err("loop detected! {d},{d} {any} {any}", .{ x, y, next, pos });
                    loops += 1;
                    map.items[y].items[x] = origTile;
                    break;
                }
                pos = next;
                try visitedPos.append(pos);
                steps += 1;
            }
            map.items[y].items[x] = origTile;
        }
    }

    // var result: i64 = 0;
    // for (map.items, 0..) |row, y| {
    //     for (row.items, 0..) |tile, x| {
    //         if (visited.get(Vec2{ .x = x, .y = y })) |_| {
    //             std.debug.print("X", .{});
    //             result += 1;
    //         } else {
    //             std.debug.print("{c}", .{@intFromEnum(tile)});
    //         }
    //     }
    //     std.debug.print("\n", .{});
    // }

    for (map.items) |row| {
        row.deinit();
    }

    map.deinit();

    return loops;
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

    // try std.testing.expectEqual(41, try problem.part1());

    try std.testing.expectEqual(6, try problem.part2());
}
