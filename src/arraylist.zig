const std = @import("std");

const ArrayListError = error{CannotExpandMemory};

/// Basic ArrayList implementation
fn ArrayList(comptime T: type) type {
    return struct {
        const Config = struct {
            initial_capacity: usize = 100,
        };
        const Self = @This();

        allocator: std.mem.Allocator,
        len: usize,
        capacity: usize,
        items: []T,

        fn init(allocator: std.mem.Allocator) !Self {
            return .{
                .allocator = allocator,
                .len = 0,
                .capacity = 0,
                .items = &[_]T{},
            };
        }

        fn init_capacity(self: *Self, capacity: usize) !void {
            const ptr = try self.allocator.alloc(T, capacity);
            self.items = ptr;
            self.capacity = capacity;
        }

        fn reallocate(self: *Self) !void {
            const c: usize = if (self.capacity != 0) self.capacity * 2 else 2;
            try self.ensure_capacity(c);
            // This doesn't work with the GeneralPurposeAllocator/testing allocator, not sure why?
            // if (self.allocator.resize(self.items, new_capacity)) {
            //     self.capacity = new_capacity;
            // } else {
            //     return ArrayListError.CannotExpandMemory;
            // }
        }

        fn ensure_capacity(self: *Self, capacity: usize) !void {
            const slice = try self.allocator.realloc(self.items, capacity);
            self.items = slice;
            self.capacity = capacity;
        }

        fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }

        fn getSlice(self: Self) []T {
            return self.items[0..self.len];
        }

        fn append(self: *Self, value: T) !void {
            if (self.len == self.capacity) {
                try self.reallocate();
            }
            self.items[self.len] = value;
            self.len += 1;
        }

        fn expand(self: *Self, value: []const T) !void {
            const new_len = self.len + value.len;
            if (new_len > self.capacity) {
                try self.ensure_capacity(new_len * 2);
            }
            @memcpy(self.items[self.len..new_len], value);
            self.len = new_len;
        }
    };
}

test "Creation" {
    var array = try ArrayList(i32).init(std.testing.allocator);
    defer array.deinit();
}

test "Append" {
    var array = try ArrayList(i32).init(std.testing.allocator);
    defer array.deinit();

    try array.append(1);
    try array.append(2);
    try array.append(3);
    const expected: [3]i32 = .{ 1, 2, 3 };
    try std.testing.expectEqualSlices(i32, &expected, array.getSlice());
}

test "Expand Capacity" {
    var array = try ArrayList(i32).init(std.testing.allocator);
    try array.init_capacity(2);
    defer array.deinit();

    try array.append(1);
    try array.append(2);
    try array.append(3);

    const expected: [3]i32 = .{ 1, 2, 3 };
    try std.testing.expectEqualSlices(i32, &expected, array.getSlice());
    try std.testing.expectEqual(4, array.capacity);
    try std.testing.expectEqual(3, array.len);
}

test "Expand" {
    var array = try ArrayList(i32).init(std.testing.allocator);
    defer array.deinit();

    {
        const arr = [_]i32{ 1, 2, 3, 4 };
        try array.expand(arr[0..]);
    }
    try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 2, 3, 4 }, array.getSlice());
}
