const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

fn parseInput(input: []const u8, allocator: std.mem.Allocator) anyerror![][]const u8 {
    var linesIter = std.mem.splitScalar(u8, input, '\n');
    var lines = std.ArrayList([]const u8).init(allocator);
    defer lines.deinit();
    while (linesIter.next()) |line| {
        try lines.append(line);
    }

    return try lines.toOwnedSlice();
}

fn searchRight(input: [][]const u8, x: usize, y: usize) bool {
    const len = input[y].len;
    const lenExceeded = x + 4 > len;
    if (lenExceeded) {
        return false;
    }

    const fwd = std.mem.startsWith(u8, input[y][x .. x + 4], "XMAS");
    const bck = std.mem.startsWith(u8, input[y][x .. x + 4], "SAMX");

    return fwd or bck;
}

const Dir = enum {
    RU,
    RD,
};

fn searchDiagonalXMas(dir: Dir, input: [][]const u8, x: usize, y: usize) bool {
    const len = input.len;

    const heightUndershot = y < 3;
    const heightExceeded = y + 4 > len;
    const widthExceeded = x + 4 > input[y].len;

    if (dir == Dir.RD and !heightUndershot and !widthExceeded) {
        if (input[y].len < 3 or input[y - 1].len < 3 or input[y - 2].len < 3 or input[y - 3].len < 3) {
            return false;
        }
        const xmas = [_]u8{
            input[y][x],
            input[y - 1][x + 1],
            input[y - 2][x + 2],
            input[y - 3][x + 3],
        };
        const fwd = std.mem.startsWith(u8, &xmas, "XMAS");
        const bck = std.mem.startsWith(u8, &xmas, "SAMX");

        if (fwd or bck) {
            return true;
        }
    }

    if (dir == Dir.RU and !heightExceeded and !widthExceeded) {
        if (input[y].len < 3 or input[y + 1].len < 3 or input[y + 2].len < 3 or input[y + 3].len < 3) {
            return false;
        }
        const xmas = [_]u8{
            input[y][x],
            input[y + 1][x + 1],
            input[y + 2][x + 2],
            input[y + 3][x + 3],
        };

        const fwd = std.mem.startsWith(u8, &xmas, "XMAS");
        const bck = std.mem.startsWith(u8, &xmas, "SAMX");

        if (fwd or bck) {
            return true;
        }
    }

    return false;
}

fn searchDiagonalMas(input: [][]const u8, x: usize, y: usize) bool {
    if (input[y][x] != 'A') {
        return false;
    }

    if (y + 1 >= input.len) return false;
    if (y < 1) return false;
    if (input[y + 1].len == 0) return false;
    if (x + 1 >= input[y - 1].len) return false;
    if (input[y - 1].len == 0) return false;
    if (x + 1 >= input[y + 1].len) return false;

    const masL = [_]u8{
        input[y + 1][x - 1],
        input[y][x],
        input[y - 1][x + 1],
    };

    const masR = [_]u8{
        input[y - 1][x - 1],
        input[y][x],
        input[y + 1][x + 1],
    };
    const fwdL = std.mem.startsWith(u8, &masL, "MAS");
    const bckL = std.mem.startsWith(u8, &masL, "SAM");

    const fwdR = std.mem.startsWith(u8, &masR, "MAS");
    const bckR = std.mem.startsWith(u8, &masR, "SAM");

    const foo: u256 = 0;
    _ = foo;

    const fw1 = fwdL or bckL;
    const fw2 = fwdR or bckR;

    if (fw1 and fw2) {
        return true;
    }

    return false;
}

fn searchDown(input: [][]const u8, x: usize, y: usize) bool {
    const len = input.len;
    const heightExceeded = y + 4 > len;

    if (heightExceeded or input[y].len < 1 or input[y + 1].len < 1 or input[y + 2].len < 1 or input[y + 3].len < 1) {
        return false;
    }

    const xmas = [_]u8{
        input[y][x],
        input[y + 1][x],
        input[y + 2][x],
        input[y + 3][x],
    };

    const fwd = std.mem.startsWith(u8, &xmas, "XMAS");
    const bck = std.mem.startsWith(u8, &xmas, "SAMX");

    return fwd or bck;
}

pub fn part1(this: *const @This()) !?i64 {
    const input = try parseInput(this.input, this.allocator);
    std.log.debug("data {any}", .{input});
    var result: i64 = 0;
    for (0..input.len) |y| {
        for (0..input[y].len) |x| {
            std.log.debug("pos: ({d},{d})\n", .{ x, y });
            if (searchRight(input, x, y)) {
                result += 1;
            }

            if (searchDown(input, x, y)) {
                result += 1;
            }

            if (searchDiagonalXMas(Dir.RD, input, x, y)) {
                result += 1;
            }

            if (searchDiagonalXMas(Dir.RU, input, x, y)) {
                result += 1;
            }
        }
    }
    this.allocator.free(input);
    return result;
}

pub fn part2(this: *const @This()) !?i64 {
    const input = try parseInput(this.input, this.allocator);
    std.log.debug("data {any}", .{input});
    var result: i64 = 0;
    for (0..input.len) |y| {
        for (0..input[y].len) |x| {
            if (searchDiagonalMas(input, x, y)) {
                result += 1;
            }
        }
    }
    this.allocator.free(input);
    return result;
}

test "it should do nothing" {
    const allocator = std.testing.allocator;
    const input =
        \\ MMMSXXMASM
        \\ MSAMXMSMSA
        \\ AMXSXMAAMM
        \\ MSAMASMSMX
        \\ XMASAMXAMM
        \\ XXAMMXXAMA
        \\ SMSMSASXSS
        \\ SAXAMASAAA
        \\ MAMMMXMMMM
        \\ MXMXAXMASX
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(18, try problem.part1());
    try std.testing.expectEqual(9, try problem.part2());
}
