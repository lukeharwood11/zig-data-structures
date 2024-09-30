const std = @import("std");
const ll = @import("linkedlist.zig");

pub fn main() !void {
    // testing allocations
    // why doesn't this work if I replace it with the GeneralPurposeAllocator?
    const allocator = std.heap.page_allocator;
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();
    const mem = try allocator.alloc(i32, 2);
    defer allocator.free(mem);
    std.debug.print("{any}", .{allocator.resize(mem, 4)});
}
