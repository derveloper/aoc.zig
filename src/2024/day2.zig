input: []const u8,
allocator: mem.Allocator,

const std = @import("std");
const mem = std.mem;

fn isAsc(left: i64, right: i64) bool {
    return right > left;
}

fn isInRange(left: i64, right: i64) bool {
    const diff = @abs(left - right);
    return diff > 0 and diff < 4;
}

fn parseReports(this: *const @This()) ![][]i64 {
    var reportLines = std.mem.splitScalar(u8, this.input, '\n');
    var reportsInt = std.ArrayList([]i64).init(this.allocator);
    defer reportsInt.deinit();
    while (reportLines.next()) |reportLine| {
        var reportInt = std.ArrayList(i64).init(this.allocator);
        defer reportInt.deinit();
        var reportTokens = std.mem.tokenizeScalar(u8, reportLine, ' ');
        while (reportTokens.next()) |token| {
            try reportInt.append(try std.fmt.parseInt(i64, token, 10));
        }
        try reportsInt.append(try reportInt.toOwnedSlice());
    }

    return try reportsInt.toOwnedSlice();
}

fn isReportSafe(report: []i64) bool {
    var i: usize = 0;
    var asc: ?bool = null;

    if (report.len < 2) {
        return false;
    }

    while (i < report.len - 1) : (i += 1) {
        if (asc == null) {
            asc = isAsc(report[i], report[i + 1]);
        }

        if (asc != isAsc(report[i], report[i + 1]) or !isInRange(report[i], report[i + 1])) {
            return false;
        }
    }

    return true;
}

pub fn part1(this: *const @This()) !?i64 {
    const reports = try parseReports(this);
    var safeReports: i64 = 0;
    for (reports) |report| {
        if (isReportSafe(report)) {
            safeReports += 1;
        }
    }

    return safeReports;
}

pub fn part2(this: *const @This()) !?i64 {
    const reports = try parseReports(this);
    var safeReports: i64 = 0;
    for (reports) |report| {
        var safeBruteReports: i64 = 0;
        for (0..report.len) |i| {
            var ll = std.ArrayList(i64).init(this.allocator);
            for (report, 0..) |r, j| {
                if (i != j) {
                    try ll.append(r);
                }
            }
            if (isReportSafe(ll.items)) {
                safeBruteReports += 1;
            }
        }

        if (safeBruteReports > 0) {
            safeReports += 1;
        }
    }

    return safeReports;
}

test "part 2" {
    try std.testing.expectEqual(1, try part2(&.{
        .input = "7 6 4 2 1",
        .allocator = std.testing.allocator,
    }));

    try std.testing.expectEqual(1, try part2(&.{
        .input = "1 3 2 4 5",
        .allocator = std.testing.allocator,
    }));

    try std.testing.expectEqual(1, try part2(&.{
        .input = "8 6 4 4 1",
        .allocator = std.testing.allocator,
    }));

    try std.testing.expectEqual(0, try part2(&.{
        .input = "1 2 7 8 9",
        .allocator = std.testing.allocator,
    }));

    try std.testing.expectEqual(0, try part2(&.{
        .input = "9 7 6 2 1",
        .allocator = std.testing.allocator,
    }));
}
