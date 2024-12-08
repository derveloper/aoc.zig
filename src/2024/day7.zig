const std = @import("std");
const mem = std.mem;
const ut = @import("utils.zig");

input: []const u8,
allocator: mem.Allocator,

const TestLine = struct {
    value: i64,
    numbers: []i64,
};

fn permuteOperators(n: usize, allocator: mem.Allocator) ![][]const u8 {
    const ops = [_]u8{ '+', '*', '|' };

    var permOps = std.ArrayList([]const u8).init(allocator);
    defer permOps.deinit();

    try permOps.append("");

    for (0..n) |_| {
        var newPermOps = std.ArrayList([]const u8).init(allocator);

        errdefer {
            for (newPermOps.items) |o| {
                allocator.free(o);
            }
            newPermOps.deinit();
        }

        for (permOps.items) |pop| {
            for (ops) |op| {
                const newOp = try std.fmt.allocPrint(allocator, "{s}{c}", .{ pop, op });
                try newPermOps.append(newOp);
            }
        }
        for (permOps.items) |o| {
            allocator.free(o);
        }
        permOps.deinit();
        permOps = newPermOps;
    }

    return try permOps.toOwnedSlice();
}

fn parseLine(input: []const u8, allocator: std.mem.Allocator) !TestLine {
    var valueWithNums = std.mem.tokenizeScalar(u8, input, ':');

    var nums = std.ArrayList(i64).init(allocator);
    defer nums.deinit();

    const value: i64 = try ut.trimAndParseInt(valueWithNums.next().?);
    var numStrings = mem.tokenizeScalar(u8, valueWithNums.next().?, ' ');

    while (numStrings.next()) |num| {
        try nums.append(try ut.trimAndParseInt(num));
    }

    return TestLine{
        .value = value,
        .numbers = try nums.toOwnedSlice(),
    };
}

fn parseInput(this: *const @This()) ![]TestLine {
    var lines = std.mem.tokenizeScalar(u8, this.input, '\n');
    var testLines = std.ArrayList(TestLine).init(this.allocator);
    defer testLines.deinit();
    while (lines.next()) |line| {
        const testLine = try parseLine(line, this.allocator);
        try testLines.append(testLine);
    }

    return testLines.toOwnedSlice();
}

pub fn part1(this: *const @This()) !?i64 {
    const lines = try parseInput(this);
    var result: i64 = 0;

    lines: for (lines) |line| {
        const ops = try permuteOperators(line.numbers.len - 1, this.allocator);
        for (ops) |op| {
            const expr = try this.allocator.alloc(i64, op.len + line.numbers.len);
            defer this.allocator.free(expr);
            var i: usize = 0;
            var opc: usize = 0;
            while (i < expr.len) {
                for (line.numbers) |num| {
                    expr[i] = num;
                    if (i < expr.len - 1) {
                        expr[i + 1] = op[opc];
                    }
                    i += 2;
                    opc += 1;
                }
            }
            i = 0;
            var tmp: i64 = 0;
            // std.log.err("expr: {d}", .{expr});
            while (i < expr.len) {
                if (i == 0) {
                    const lhs = expr[i];
                    const cop = expr[i + 1];
                    const rhs = expr[i + 2];
                    if (cop == '+') {
                        tmp = lhs + rhs;
                    }
                    if (cop == '*') {
                        tmp = lhs * rhs;
                    }
                    if (cop == '|') {
                        const tmpStr = try std.fmt.allocPrint(this.allocator, "{d}{d}", .{ lhs, rhs });
                        const comb = try std.fmt.parseInt(i64, tmpStr, 10);
                        this.allocator.free(tmpStr);
                        tmp = comb;
                    }
                    i += 3;
                } else {
                    const cop = expr[i];
                    const rhs = expr[i + 1];
                    if (cop == '+') {
                        tmp = tmp + rhs;
                    }
                    if (cop == '*') {
                        tmp = tmp * rhs;
                    }
                    if (cop == '|') {
                        const tmpStr = try std.fmt.allocPrint(this.allocator, "{d}{d}", .{ tmp, rhs });
                        const comb = try std.fmt.parseInt(i64, tmpStr, 10);
                        this.allocator.free(tmpStr);
                        tmp = comb;
                    }
                    i += 2;
                }
            }
            // std.log.err("found tmp: {any}", .{tmp});
            if (tmp == line.value) {
                result += line.value;
                // std.log.err("found line: {any}", .{line});
                continue :lines;
            }
        }
    }
    return result;
}

pub fn part2(this: *const @This()) !?i64 {
    _ = this;
    return null;
}

test "it should do nothing" {
    const allocator = std.testing.allocator;
    const input =
        \\ 190: 10 19
        \\ 3267: 81 40 27
        \\ 83: 17 5
        \\ 156: 15 6
        \\ 7290: 6 8 6 15
        \\ 161011: 16 10 13
        \\ 192: 17 8 14
        \\ 21037: 9 7 18 13
        \\ 292: 11 6 16 20
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    const nums = try permuteOperators(2, allocator);
    for (nums) |num| {
        std.log.err("perm: {s}", .{num});
        allocator.free(num);
    }

    try std.testing.expectEqual(11387, try problem.part1());
    try std.testing.expectEqual(null, try problem.part2());
}
