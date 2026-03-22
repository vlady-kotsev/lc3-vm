const std = @import("std");
const Allocator = std.mem.Allocator;

pub const vm = @import("core/vm.zig");
pub const errors = @import("core/error.zig");

pub fn handleArgs(allocator: Allocator) ![][:0]u8 {
    const args = try std.process.argsAlloc(allocator);
    if (args.len < 2) {
        return errors.VmError.InvalidArgs;
    }

    return args;
}
