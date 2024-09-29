const std = @import("std");

const LinkedListError = error{
    EmptyList,
    IndexOutOfBounds,
};

fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();
        const Node = struct {
            value: T,
            next: ?*Node = null,
        };

        head: ?*Node,
        len: usize,
        allocator: std.mem.Allocator,

        fn init(allocator: std.mem.Allocator) Self {
            return .{
                .len = 0,
                .head = null,
                .allocator = allocator,
            };
        }

        /// Adds a value to the end of the list
        /// This is an O(n) operation
        fn append(self: *Self, value: T) !void {
            const node = try self.allocator.create(Node);
            node.value = value;
            node.next = null;
            if (self.head) |head| {
                var cur = head;
                while (cur.next) |next| cur = next;
                cur.next = node;
            } else {
                self.head = node;
            }
            self.len += 1;
        }

        /// Adds a value to the front of the list
        /// This is an O(1) operation
        fn prepend(self: *Self, value: T) !void {
            const node = try self.allocator.create(Node);
            node.value = value;
            node.next = self.head;
            self.head = node;
            self.len += 1;
        }

        /// Destroys all nodes and cleans up resources
        fn deinit(self: *Self) void {
            var cur = self.head;
            while (cur) |ptr| {
                cur = ptr.next;
                self.allocator.destroy(ptr);
            }
        }

        /// Grabs value at index given
        /// Returns a LinkedListError.IndexOutOfBounds if invalid index is given
        /// This is an O(n) operation
        fn get(self: Self, index: usize) LinkedListError!T {
            var cur = self.head;
            var idx: usize = 0;
            while (cur) |node| : ({
                cur = node.next;
                idx += 1;
            }) {
                if (idx == index) {
                    return node.value;
                }
            }
            return LinkedListError.IndexOutOfBounds;
        }

        /// Removes the first element from the list
        /// This is an O(1) operation
        fn pop(self: *Self) LinkedListError!T {
            if (self.head) |head| {
                defer self.allocator.destroy(head);
                self.head = head.next;
                self.len -= 1;
                return head.value;
            } else {
                return LinkedListError.EmptyList;
            }
        }
    };
}

test "Creation" {
    const allocator = std.testing.allocator;
    const list = LinkedList(i32).init(allocator);
    try std.testing.expect(list.head == null);
    try std.testing.expect(list.len == 0);
}

test "Append" {
    const allocator = std.testing.allocator;
    var list = LinkedList(i32).init(allocator);
    defer list.deinit();
    try list.append(10);
    try list.append(202);
    try list.append(42);

    const node = list.head.?;
    try std.testing.expect(node.value == 10);
    var last_node = node;
    while (last_node.next) |next| last_node = next;
    try std.testing.expect(last_node.value == 42);
    try std.testing.expect(list.len == 3);
}

test "Prepend" {
    const allocator = std.testing.allocator;
    var list = LinkedList(i32).init(allocator);
    defer list.deinit();

    try list.prepend(10);
    var head = list.head.?;
    try std.testing.expect(head.value == 10);

    try list.prepend(20);
    head = list.head.?;
    try std.testing.expect(head.value == 20);

    try list.prepend(30);
    head = list.head.?;
    try std.testing.expect(head.value == 30);
    try std.testing.expect(list.len == 3);
}

test "Pop" {
    const allocator = std.testing.allocator;
    var list = LinkedList(i32).init(allocator);
    defer list.deinit();

    try list.append(10);
    try std.testing.expect(list.len == 1);
    const val = try list.pop();
    try std.testing.expect(val == 10);
    try std.testing.expect(list.len == 0);
}

test "Get" {
    const allocator = std.testing.allocator;
    var list = LinkedList(i32).init(allocator);
    defer list.deinit();

    try list.append(10);
    try list.append(15);
    try std.testing.expect(try list.get(0) == 10);
    try std.testing.expect(try list.get(1) == 15);
}
