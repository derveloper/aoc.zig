const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const mulPattern: []const u8 = "mul(";

const MulFacs = struct { a: i64, b: i64 };

const Symbol = enum(u8) {
    Char,
    Digit,
    LParen,
    RParen,
    Comma,
    Mul,
    Number,
    Do,
    Dont,
};

const Token = struct {
    symbol: Symbol,
    value: i64,
};

fn isDigit(d: u8) bool {
    return d >= 48 and d <= 57;
}

fn isSpecial(d: u8) bool {
    return switch (d) {
        '(', ')', ',' => true,
        else => false,
    };
}

fn isMul(buf: []const u8) bool {
    return std.mem.startsWith(u8, buf, "mul");
}

fn isDo(buf: []const u8) bool {
    return std.mem.startsWith(u8, buf, "do");
}

fn isDont(buf: []const u8) bool {
    return std.mem.startsWith(u8, buf, "don't");
}

fn parseInput(input: []const u8, allocator: std.mem.Allocator) ![]Token {
    var tokens = std.ArrayList(Token).init(allocator);
    defer tokens.deinit();

    var pos: usize = 0;
    while (pos < input.len) : (pos += 1) {
        const token = input[pos];

        if (isDigit(token)) {
            var digits = std.ArrayList(u8).init(allocator);
            defer digits.deinit();
            try digits.append(token);
            var npos: usize = 1;
            while (pos + npos < input.len and isDigit(input[pos + npos])) {
                try digits.append(input[pos + npos]);
                npos += 1;
            }
            try tokens.append(.{ .symbol = Symbol.Number, .value = try std.fmt.parseInt(i64, digits.items, 10) });
            pos += npos - 1;
        } else if (pos + 5 < input.len and isDont(input[pos .. pos + 5])) {
            try tokens.append(.{ .symbol = Symbol.Dont, .value = 0 });
            pos += 4;
        } else if (pos + 2 < input.len and isDo(input[pos .. pos + 2])) {
            try tokens.append(.{ .symbol = Symbol.Do, .value = 0 });
            pos += 1;
        } else if (pos + 3 < input.len and isMul(input[pos .. pos + 3])) {
            try tokens.append(.{ .symbol = Symbol.Mul, .value = 0 });
            pos += 2;
        } else if (!isSpecial(token)) {
            try tokens.append(.{ .symbol = Symbol.Char, .value = token });
        } else if (token == '(') {
            try tokens.append(.{ .symbol = Symbol.LParen, .value = token });
        } else if (token == ')') {
            try tokens.append(.{ .symbol = Symbol.RParen, .value = token });
        } else if (token == ',') {
            try tokens.append(.{ .symbol = Symbol.Comma, .value = token });
        }
    }

    return tokens.toOwnedSlice();
}

pub fn part1(this: *const @This()) !?i64 {
    const facs = try parseInput(this.input, this.allocator);
    std.log.debug("facs: {any}", .{facs});
    var pos: usize = 0;
    var result: i64 = 0;
    while (pos < facs.len - 6) : (pos += 1) {
        const isMulSym = facs[pos].symbol == Symbol.Mul;
        const isLParen = facs[pos + 1].symbol == Symbol.LParen;
        const isNumber1 = facs[pos + 2].symbol == Symbol.Number;
        const isComma = facs[pos + 3].symbol == Symbol.Comma;
        const isNumber2 = facs[pos + 4].symbol == Symbol.Number;
        const isRParen = facs[pos + 5].symbol == Symbol.RParen;

        if (isMulSym and isLParen and isNumber1 and isComma and isNumber2 and isRParen) {
            result += (facs[pos + 2].value * facs[pos + 4].value);
        }
    }

    this.allocator.free(facs);

    return result;
}

pub fn part2(this: *const @This()) !?i64 {
    const facs = try parseInput(this.input, this.allocator);
    std.log.debug("facs: {any}", .{facs});
    var pos: usize = 0;
    var result: i64 = 0;
    var enabled = true;
    while (pos < facs.len - 6) : (pos += 1) {
        if (facs[pos].symbol == Symbol.Do) {
            enabled = true;
        } else if (facs[pos].symbol == Symbol.Dont) {
            enabled = false;
        }
        const isMulSym = facs[pos].symbol == Symbol.Mul;
        const isLParen = facs[pos + 1].symbol == Symbol.LParen;
        const isNumber1 = facs[pos + 2].symbol == Symbol.Number;
        const isComma = facs[pos + 3].symbol == Symbol.Comma;
        const isNumber2 = facs[pos + 4].symbol == Symbol.Number;
        const isRParen = facs[pos + 5].symbol == Symbol.RParen;

        if (enabled and isMulSym and isLParen and isNumber1 and isComma and isNumber2 and isRParen) {
            result += (facs[pos + 2].value * facs[pos + 4].value);
        }
    }

    this.allocator.free(facs);

    return result;
}

test "it should do nothing" {
    const allocator = std.testing.allocator;
    const input = "mul(232,23098)sel(mul(3,,3)mul(32,54)dddmul(33,44";

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    const facs = try parseInput(input, allocator);
    std.log.err("\n\nfacs: {any}\n\n", .{facs});
    try std.testing.expectEqual(0, facs[0].value);
    try std.testing.expectEqual('(', facs[1].value);
    try std.testing.expectEqual(232, facs[2].value);
    try std.testing.expectEqual(',', facs[3].value);
    try std.testing.expectEqual(23098, facs[4].value);
    try std.testing.expectEqual(')', facs[5].value);

    try std.testing.expectEqual(5360464, try problem.part1());
    try std.testing.expectEqual(5360464, try problem.part2());

    allocator.free(facs);
}
