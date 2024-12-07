input: []const u8,
allocator: mem.Allocator,

const std = @import("std");
const mem = std.mem;

const TwoLists = struct {
    left: std.ArrayList(i64),
    right: std.ArrayList(i64),
};

fn parseInput(this: *const @This()) !TwoLists {
    var lines = std.mem.tokenizeScalar(u8, this.input, '\n');
    var listLeft = std.ArrayList(i64).init(this.allocator);
    var listRight = std.ArrayList(i64).init(this.allocator);

    while (lines.next()) |line| {
        std.log.debug("line: {s}\n", .{line});
        var cols = std.mem.tokenizeScalar(u8, line, ' ');
        const col1 = std.mem.trim(u8, cols.next().?, " ");
        const col2 = std.mem.trim(u8, cols.next().?, " ");
        std.log.debug("cols: {s}{s}\n", .{ col1, col2 });
        const valLeft = try std.fmt.parseInt(i64, col1, 10);
        const valRight = try std.fmt.parseInt(i64, col2, 10);

        try listLeft.append(valLeft);
        try listRight.append(valRight);
    }

    std.mem.sort(i64, listLeft.items, {}, std.sort.asc(i64));
    std.mem.sort(i64, listRight.items, {}, std.sort.asc(i64));

    return .{ .left = listLeft, .right = listRight };
}

pub fn part1(this: *const @This()) !?i64 {
    var result: i64 = 0;
    const lists = try parseInput(this);
    for (lists.left.items, 0..) |l, i| {
        const dist = @as(i64, @intCast(@abs(l - lists.right.items[i])));
        result += dist;
    }

    return result;
}

pub fn part2(this: *const @This()) !?i64 {
    const lists = try parseInput(this);
    var result: i64 = 0;
    for (lists.left.items) |ln| {
        var rcount: i64 = 0;
        for (lists.right.items) |rn| {
            if (ln == rn) {
                rcount += 1;
            }
        }

        if (rcount > 0) {
            result += ln * rcount;
        }
    }

    return result;
}
