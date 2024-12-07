const std = @import("std");
const mem = std.mem;

input: []const u8,
allocator: mem.Allocator,

const Rule = struct {
    lhs: i64,
    rhs: i64,
};

fn trimAndParseInt(buf: []const u8) !i64 {
    const trimmed = std.mem.trim(u8, buf, " ");
    return try std.fmt.parseInt(i64, trimmed, 10);
}

fn parseRule(input: []const u8) !?Rule {
    if (std.mem.count(u8, input, "|") != 1) {
        return null;
    }

    var nums = std.mem.splitScalar(u8, input, '|');
    const lhs = nums.next().?;
    const rhs = nums.next().?;
    std.log.debug("\n\nnums {s}|{s}", .{ lhs, rhs });
    return .{
        .lhs = try trimAndParseInt(lhs),
        .rhs = try trimAndParseInt(rhs),
    };
}

fn parseRules(this: *const @This()) ![]Rule {
    var rules = std.ArrayList(Rule).init(this.allocator);
    defer rules.deinit();
    var lines = std.mem.splitScalar(u8, this.input, '\n');
    while (lines.next()) |line| {
        const maybeRule = try parseRule(line);
        if (maybeRule) |rule| {
            try rules.append(rule);
        }
    }

    return rules.toOwnedSlice();
}

fn parseUpdate(input: []const u8, allocator: std.mem.Allocator) !?[]i64 {
    if (std.mem.count(u8, input, ",") == 0) {
        return null;
    }

    var updates = std.ArrayList(i64).init(allocator);
    defer updates.deinit();

    var nums = std.mem.splitScalar(u8, input, ',');
    while (nums.next()) |num| {
        try updates.append(try trimAndParseInt(num));
    }

    return try updates.toOwnedSlice();
}

fn parseUpdates(this: *const @This()) ![][]i64 {
    var updates = std.ArrayList([]i64).init(this.allocator);
    defer updates.deinit();
    var lines = std.mem.splitScalar(u8, this.input, '\n');
    while (lines.next()) |line| {
        const maybeUpdate = try parseUpdate(line, this.allocator);
        if (maybeUpdate) |update| {
            try updates.append(update);
        }
    }

    return updates.toOwnedSlice();
}

fn isPageBefore(rule: Rule, page: i64, updates: []i64) bool {
    const iup = std.mem.indexOf(i64, updates, &[_]i64{page});
    const rup = std.mem.indexOf(i64, updates, &[_]i64{rule.rhs});

    return iup != null and rup != null and iup.? < rup.?;
}

fn isPageAfter(rule: Rule, page: i64, updates: []i64) bool {
    const iup = std.mem.indexOf(i64, updates, &[_]i64{page});
    const rup = std.mem.indexOf(i64, updates, &[_]i64{rule.rhs});

    return iup != null and rup != null and iup.? > rup.?;
}

fn pageDist(rule: Rule, update: []i64) i64 {
    const lpos = @as(i64, @intCast(std.mem.indexOf(i64, update, &[_]i64{rule.lhs}) orelse 0));
    const rpos = @as(i64, @intCast(std.mem.indexOf(i64, update, &[_]i64{rule.rhs}) orelse 0));

    return lpos - rpos;
}

fn findMidNumber(update: []i64) ?i64 {
    if (update.len % 2 == 0 or update.len < 3) return null;

    return update[update.len - (update.len + 1) / 2];
}

fn findRules(update: []i64, rules: []Rule, allocator: std.mem.Allocator) ![]Rule {
    var result = std.ArrayList(Rule).init(allocator);
    defer result.deinit();
    for (rules) |rule| {
        if (isRuleApplicable(rule, update)) {
            try result.append(rule);
        }
    }

    return result.toOwnedSlice();
}

fn isRuleApplicable(rule: Rule, update: []i64) bool {
    if (std.mem.count(i64, update, &[_]i64{rule.lhs}) < 1 or std.mem.count(i64, update, &[_]i64{rule.rhs}) < 1) {
        return false;
    }

    return true;
}

const SortUpdateCtx = struct { rules: []Rule, update: []i64 };

fn updateLessThan(context: SortUpdateCtx, lhs: i64, rhs: i64) bool {
    for (context.rules) |rule| {
        if (rule.lhs == lhs and rule.rhs == rhs) {
            std.log.err("matched rule sorted {d} {d} {any}\n", .{ lhs, rhs, rule });
            return true;
        }

        if (rule.lhs == rhs and rule.rhs == lhs) {
            std.log.err("matched rule unsorted {d} {d} {any}\n", .{ lhs, rhs, rule });
            return false;
        }
    }

    return false;
}

pub fn part1(this: *const @This()) !?i64 {
    const rules = try parseRules(this);
    const updates = try parseUpdates(this);
    std.log.debug("rules {any}\nupdates {any}\n", .{ rules, updates });

    var result: i64 = 0;

    for (updates) |update| {
        var inOrderCount: usize = 0;
        const actualRules = try findRules(update, rules, this.allocator);

        for (update) |page| {
            for (actualRules) |rule| {
                if (rule.lhs == page and isPageBefore(rule, page, update)) {
                    inOrderCount += 1;
                    std.log.debug("\n\nlhs rule {any} page {d} {any}\n", .{ rule, page, inOrderCount });
                }
                if (rule.rhs == page and isPageAfter(rule, page, update)) {
                    inOrderCount += 1;
                    std.log.debug("\n\nrhs rule {any} page {d} {any}\n", .{ rule, page, inOrderCount });
                }
            }
        }

        if (inOrderCount == actualRules.len) {
            std.log.debug("\n\nfound ordered line: {any}", .{update});
            const maybeId = findMidNumber(update);
            if (maybeId) |mid| {
                result += mid;
            }
        }
        this.allocator.free(actualRules);
    }

    for (updates) |update| {
        this.allocator.free(update);
    }

    this.allocator.free(rules);
    this.allocator.free(updates);
    return result;
}

pub fn part2(this: *const @This()) !?i64 {
    const rules = try parseRules(this);
    const updates = try parseUpdates(this);
    std.log.err("rules {any}\nupdates {any}\n", .{ rules, updates });

    var result: i64 = 0;

    for (updates) |origUpdate| {
        var inOrderCount: usize = 0;
        const update = try this.allocator.alloc(i64, origUpdate.len);
        std.mem.copyForwards(i64, update, origUpdate);
        const actualRules = try findRules(update, rules, this.allocator);

        for (update) |page| {
            for (actualRules) |rule| {
                if (rule.lhs == page and isPageBefore(rule, page, update)) {
                    inOrderCount += 1;
                    std.log.debug("\n\nlhs rule {any} page {d} {any}\n", .{ rule, page, inOrderCount });
                }
                if (rule.rhs == page and isPageAfter(rule, page, update)) {
                    inOrderCount += 1;
                    std.log.debug("\n\nrhs rule {any} page {d} {any}\n", .{ rule, page, inOrderCount });
                }
            }
        }

        if (inOrderCount != actualRules.len) {
            std.log.err("\n\nfound unordered line: {any}", .{update});
            // orderUpdate(actualRules, &update);
            std.mem.sort(i64, update, SortUpdateCtx{ .rules = rules, .update = update }, updateLessThan);
            std.log.err("\n\nordered line: {any}", .{update});
            const maybeId = findMidNumber(update);
            if (maybeId) |mid| {
                result += mid;
            }
        }
        this.allocator.free(actualRules);

        this.allocator.free(update);
    }

    for (updates) |update| {
        this.allocator.free(update);
    }

    this.allocator.free(rules);
    this.allocator.free(updates);
    return result;
}

test "it should parse a single rule" {
    const rule = try parseRule("33|89");
    try std.testing.expectEqual(33, rule.?.lhs);
    try std.testing.expectEqual(89, rule.?.rhs);
}

test "it should parse a single update line" {
    const update = try parseUpdate("399,122,34", std.testing.allocator);
    try std.testing.expectEqual(399, update.?[0]);
    try std.testing.expectEqual(122, update.?[1]);
    try std.testing.expectEqual(34, update.?[2]);
    std.testing.allocator.free(update.?);
}

test "it should check ordered update" {
    const rule = try parseRule("122|89");
    const update = try parseUpdate("399,122,34,89,122", std.testing.allocator);
    const isBefore = isPageBefore(rule.?, 122, update.?);
    const midNumber = findMidNumber(update.?);
    try std.testing.expect(isBefore);
    try std.testing.expectEqual(34, midNumber.?);
    std.testing.allocator.free(update.?);
}

test "it should check unordered update" {
    const rule = try parseRule("122|89");
    const update = try parseUpdate("89,122,34,89,122", std.testing.allocator);
    const isBefore = isPageBefore(rule.?, 122, update.?);
    try std.testing.expect(!isBefore);
    std.testing.allocator.free(update.?);
}

test "it should do solve parts" {
    const allocator = std.testing.allocator;
    const input =
        \\ 47|53
        \\ 97|13
        \\ 97|61
        \\ 97|47
        \\ 75|29
        \\ 61|13
        \\ 75|53
        \\ 29|13
        \\ 97|29
        \\ 53|29
        \\ 61|53
        \\ 97|53
        \\ 61|29
        \\ 47|13
        \\ 75|47
        \\ 97|75
        \\ 47|61
        \\ 75|61
        \\ 47|29
        \\ 75|13
        \\ 53|13
        \\
        \\ 75,47,61,53,29
        \\ 97,61,53,29,13
        \\ 75,29,13
        \\ 75,97,47,61,53
        \\ 61,13,29
        \\ 97,13,75,29,47
    ;

    const problem: @This() = .{
        .input = input,
        .allocator = allocator,
    };

    try std.testing.expectEqual(143, try problem.part1());
    try std.testing.expectEqual(123, try problem.part2());
}
