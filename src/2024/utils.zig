const std = @import("std");

pub fn trimAndParseInt(buf: []const u8) !i64 {
    const trimmed = std.mem.trim(u8, buf, " ");
    return try std.fmt.parseInt(i64, trimmed, 10);
}
