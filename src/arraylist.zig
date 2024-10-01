const std = @import("std");

const ArrayListError = error{ CannotExpandMemory, IndexOutOfBounds, InitializingNonEmptyArray };

/// Basic ArrayList implementation
fn ArrayList(comptime T: type) type {
    return struct {
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

        /// Initialize the starting capacity for the array
        fn init_capacity(self: *Self, capacity: usize) !void {
            if (self.len > 0) {
                return ArrayListError.InitializingNonEmptyArray;
            }
            const ptr = try self.allocator.alloc(T, capacity);
            self.items = ptr;
            self.capacity = capacity;
        }

        /// Destroy all resources
        fn deinit(self: *Self) void {
            self.allocator.free(self.items);
        }

        /// Return the active slice for the backing array
        fn getSlice(self: Self) []T {
            return self.items[0..self.len];
        }

        /// Create a standard amount of extra memory for a new item
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

        /// Make sure that enough memory exists for the given capacity
        fn ensure_capacity(self: *Self, capacity: usize) !void {
            const slice = try self.allocator.realloc(self.items, capacity);
            self.items = slice;
            self.capacity = capacity;
        }

        /// Just for fun, this supports negative indexing:)
        /// Grab the value at the given index
        fn get(self: Self, index: isize) !T {
            if (index >= self.len or (index < 0 and @abs(index) > self.len)) {
                return ArrayListError.IndexOutOfBounds;
            }
            return self.items[
                if (index < 0) @intCast(@as(isize, self.len) + index) else @intCast(index)
            ];
        }

        /// Just for fun, this supports negative indexing:)
        /// Grab the value at the given index, removing it from the array
        fn pop(self: *Self, index: usize) !T {
            if (index >= self.len or (index < 0 and @abs(index) > self.len)) {
                return ArrayListError.IndexOutOfBounds;
            }
            const idx: usize = if (index < 0) @intCast(@as(isize, self.len) + index) else @intCast(index);
            const value = self.items[idx];
            self.len -= 1; // 'remove' the item
            @memcpy(self.items[idx..self.len], self.items[idx + 1 .. self.len + 1]);
            return value;
        }

        /// Add the given value to the end of the array
        fn append(self: *Self, value: T) !void {
            if (self.len == self.capacity) {
                try self.reallocate();
            }
            self.items[self.len] = value;
            self.len += 1;
        }

        /// Add a given slice to the end of the array
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

test "Get" {
    var array = try ArrayList(i32).init(std.testing.allocator);
    try array.init_capacity(2);
    defer array.deinit();

    try array.append(1);
    try array.append(2);
    try array.append(3);

    // positive indexing
    try std.testing.expectEqual(3, try array.get(2));
    try std.testing.expectError(ArrayListError.IndexOutOfBounds, array.get(3));

    // negative indexing
    try std.testing.expectEqual(1, try array.get(-3));
    try std.testing.expectError(ArrayListError.IndexOutOfBounds, array.get(-4));
}

test "Pop" {
    var array = try ArrayList(i32).init(std.testing.allocator);
    try array.init_capacity(2);
    defer array.deinit();

    try array.append(1);
    try array.append(2);
    try array.append(3);

    const value = try array.pop(1);
    try std.testing.expectEqual(2, value);
    try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 3 }, array.getSlice());
}

test "Capacity Error" {
    var array = try ArrayList(i32).init(std.testing.allocator);
    defer array.deinit();

    try array.append(1);
    try array.append(2);
    try array.append(3);
    try std.testing.expectError(ArrayListError.InitializingNonEmptyArray, array.init_capacity(2));
}
