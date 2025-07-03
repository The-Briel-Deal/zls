const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    const out = std.io.getStdOut().writer();

    var arena_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const alloc = arena_alloc.allocator();

    const current_pid: i32 = std.os.linux.getpid();
    var buf: [10]u8 = undefined;
    const pid_str = try std.fmt.bufPrint(&buf, "{d}", .{current_pid});
    var gdbserver = std.process.Child.init(&[_][]const u8{ "gdbserver", "--attach", "localhost:2222", pid_str }, alloc);
    gdbserver.stdout_behavior = .Pipe;
    gdbserver.stderr_behavior = .Pipe;
    try gdbserver.spawn();
    std.Thread.sleep(3 * 1000 * 1000 * 1000);
    var stdout_str: std.ArrayListUnmanaged(u8) = .empty;
    var stderr_str: std.ArrayListUnmanaged(u8) = .empty;
    try gdbserver.collectOutput(alloc, &stdout_str, &stderr_str, 10_000);
    std.debug.print("\nstdout: {}\n\nstderr: {}\n", .{stdout_str, stderr_str});
    for (builtin.test_functions) |t| {
        t.func() catch |err| {
            try std.fmt.format(out, "{s} fail: {}\n", .{ t.name, err });
            continue;
        };
        try std.fmt.format(out, "{s} passed\n", .{t.name});
    }
}
