const std = @import("std");
const ll = @import("linkedlist.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var array = try std.ArrayList(i32).initCapacity(allocator, 1);
    defer array.deinit();
    try array.append(1);
    try array.append(2);
}
