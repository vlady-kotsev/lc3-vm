const std = @import("std");
const Allocator = std.mem.Allocator;
const data = @import("data.zig");
const VmError = @import("error.zig").VmError;
const utils = @import("utils.zig");

pub const VmMemory = struct {
    memory: []u16,
    allocator: Allocator,

    const Self = @This();

    pub fn init(allocator: Allocator) !Self {
        return Self{
            .memory = try allocator.alloc(u16, data.MEMORY_MAX),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.memory);
    }

    pub fn write(self: *Self, address: u16, value: u16) !void {
        if (address >= data.MEMORY_MAX) {
            return VmError.InvalidMemoryAddress;
        }

        self.memory[address] = value;
    }

    pub fn read(self: *Self, address: u16) !u16 {
        if (address >= data.MEMORY_MAX) {
            return VmError.InvalidMemoryAddress;
        }
        if (address == data.MR_KBSR) {
            if (utils.checkKey()) {
                try self.write(data.MR_KBSR, (1 << 15));
                try self.write(data.MR_KBDR, utils.getChar());
            } else {
                try self.write(data.MR_KBSR, 0);
            }
        }
        return self.memory[address];
    }
};
