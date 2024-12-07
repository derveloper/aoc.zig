const std = @import("std");
const fs = std.fs;
const io = std.io;
const heap = std.heap;

const Problem = @import("problem");
const ansi = @import("ansi");

pub fn main() !void {
    const stdout = io.getStdOut().writer();

    var arena = heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const problem = Problem{
        .input = @embedFile("input"),
        .allocator = allocator,
    };

    var start = std.time.nanoTimestamp();
    if (try problem.part1()) |solution| {
        try stdout.print(ansi.color.Fg(.Green, "Part 1: "), .{});
        try stdout.print(ansi.color.Fg(.Yellow, "{any}\n"), .{solution});
        const t: f32 = @as(f32, @floatFromInt(std.time.nanoTimestamp() - start));
        try stdout.print(ansi.color.Fg(.Blue, "duration: {d}ms\n"), .{t / std.time.ns_per_ms});
    }

    start = std.time.nanoTimestamp();
    if (try problem.part2()) |solution| {
        try stdout.print(ansi.color.Fg(.Red, "------------------\n"), .{});
        try stdout.print(ansi.color.Fg(.Green, "Part 2: "), .{});
        try stdout.print(ansi.color.Fg(.Yellow, "{any}\n"), .{solution});
        const t: f32 = @as(f32, @floatFromInt(std.time.nanoTimestamp() - start));
        try stdout.print(ansi.color.Fg(.Blue, "duration: {d}ms\n"), .{t / std.time.ns_per_ms});
    }
}
