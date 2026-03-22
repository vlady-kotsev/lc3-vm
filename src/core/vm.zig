const std = @import("std");
const Allocator = std.mem.Allocator;
const VmError = @import("error.zig").VmError;
const data = @import("data.zig");
const Register = data.Register;
const Flag = data.Flag;
const utils = @import("utils.zig");
const OpCode = data.OpCode;
const VmMemory = @import("memory.zig").VmMemory;

pub const Vm = struct {
    memory: VmMemory,
    registers: std.AutoHashMap(Register, u16),
    allocator: Allocator,
    reader: *std.Io.Reader,
    writer: *std.Io.Writer,
    running: bool,

    const Self = @This();

    var reader_buffer: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&reader_buffer);

    var writer_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&writer_buffer);

    // === Public methods ===
    pub fn init(allocator: Allocator) !Self {
        var vm = Self{
            .memory = try VmMemory.init(allocator),
            .allocator = allocator,
            .registers = std.AutoHashMap(Register, u16).init(allocator),
            .reader = &stdin_reader.interface,
            .writer = &stdout_writer.interface,
            .running = true,
        };

        try vm.registers.put(.R_R0, 0);
        try vm.registers.put(.R_R1, 0);
        try vm.registers.put(.R_R2, 0);
        try vm.registers.put(.R_R3, 0);
        try vm.registers.put(.R_R4, 0);
        try vm.registers.put(.R_R5, 0);
        try vm.registers.put(.R_R6, 0);
        try vm.registers.put(.R_R7, 0);
        try vm.registers.put(.R_PC, data.PC_START);
        try vm.registers.put(.R_COND, @intFromEnum(Flag.FL_ZRO));

        return vm;
    }

    pub fn deinit(self: *Self) void {
        self.memory.deinit();
        self.registers.deinit();
    }

    pub fn run(self: *Self, file_name: []const u8) !void {
        // Load program in memory
        try self.readFile(file_name);

        utils.setupSignalHandler();
        utils.disableInputBuffering();
        defer utils.restoreInputBuffering();

        while (self.running) {
            const pc = try self.getProgramCounter();
            const instruction_payload = try self.memory.read(pc);
            try self.registers.put(.R_PC, pc +% 1);

            const op: OpCode = std.enums
                .fromInt(OpCode, (instruction_payload >> 12)) orelse return VmError.InvalidOpCode;

            switch (op) {
                .OP_ADD => {
                    try self.handleAdd(instruction_payload);
                },
                .OP_AND => {
                    try self.handleAnd(instruction_payload);
                },
                .OP_NOT => {
                    try self.handleNot(instruction_payload);
                },
                .OP_BR => {
                    try self.handleBranch(instruction_payload);
                },
                .OP_JMP => {
                    try self.handleJump(instruction_payload);
                },
                .OP_JSR => {
                    try self.handleJumpRegister(instruction_payload);
                },
                .OP_LD => {
                    try self.handleLoad(instruction_payload);
                },
                .OP_LDI => {
                    try self.handleLoadIndirect(instruction_payload);
                },
                .OP_LDR => {
                    try self.handleLoadRegister(instruction_payload);
                },
                .OP_LEA => {
                    try self.handleLoadEffectiveAddress(instruction_payload);
                },
                .OP_ST => {
                    try self.handleStore(instruction_payload);
                },
                .OP_STI => {
                    try self.handleStoreIndirect(instruction_payload);
                },
                .OP_STR => {
                    try self.handleStoreRegister(instruction_payload);
                },
                .OP_TRAP => {
                    try self.handleTrap(instruction_payload);
                },
                .OP_RES, .OP_RTI => {
                    @panic("OP_RES or OP_RTI encountered");
                },
            }
        }
        // @{Shutdown}
    }

    // === Private methods ===
    fn updateFlags(self: *Self, reg: Register) !void {
        const regValue = self.registers
            .get(reg) orelse return VmError.InvalidRegister;

        if (regValue == 0) {
            try self.registers.put(.R_COND, @intFromEnum(Flag.FL_ZRO));
        } else if ((regValue >> 15) != 0) {
            try self.registers.put(.R_COND, @intFromEnum(Flag.FL_NEG));
        } else {
            try self.registers.put(.R_COND, @intFromEnum(Flag.FL_POS));
        }
    }

    fn handleAdd(self: *Self, instruction_payload: u16) !void {
        const destination_register = std.enums
            .fromInt(Register, (instruction_payload >> 9) & 0b111) orelse return VmError.InvalidRegister;

        const source_register1 = std.enums
            .fromInt(Register, (instruction_payload >> 6) & 0b111) orelse return VmError.InvalidRegister;
        const first_operand = self.registers
            .get(source_register1) orelse return VmError.InvalidRegister;

        const immediate_flag = (instruction_payload >> 5) & 0b1;

        const second_operand = blk: {
            if (immediate_flag == 1) {
                break :blk utils.signExtend(instruction_payload & 0b11111, 5);
            } else {
                const source_register2 = std.enums
                    .fromInt(Register, instruction_payload & 0b111) orelse return VmError.InvalidRegister;

                break :blk self.registers
                    .get(source_register2) orelse return VmError.InvalidRegister;
            }
        };

        const result = first_operand +% second_operand;
        try self.registers.put(destination_register, result);

        try self.updateFlags(destination_register);
    }

    fn handleAnd(self: *Self, instruction_payload: u16) !void {
        const destination_register = std.enums
            .fromInt(Register, (instruction_payload >> 9) & 0b111) orelse return VmError.InvalidRegister;

        const source_register1 = std.enums
            .fromInt(Register, (instruction_payload >> 6) & 0b111) orelse return VmError.InvalidRegister;
        const first_operand = self.registers
            .get(source_register1) orelse return VmError.InvalidRegister;

        const immediate_flag = (instruction_payload >> 5) & 0b1;

        const second_operand = blk: {
            if (immediate_flag == 1) {
                break :blk utils.signExtend(instruction_payload & 0b11111, 5);
            } else {
                const source_register2 = std.enums
                    .fromInt(Register, instruction_payload & 0b111) orelse return VmError.InvalidRegister;

                break :blk self.registers
                    .get(source_register2) orelse return VmError.InvalidRegister;
            }
        };

        const result = first_operand & second_operand;
        try self.registers.put(destination_register, result);

        try self.updateFlags(destination_register);
    }

    fn handleNot(self: *Self, instruction_payload: u16) !void {
        const destination_register = std.enums
            .fromInt(Register, (instruction_payload >> 9) & 0b111) orelse return VmError.InvalidRegister;

        const source_register = std.enums
            .fromInt(Register, (instruction_payload >> 6) & 0b111) orelse return VmError.InvalidRegister;
        const operand = self.registers
            .get(source_register) orelse return VmError.InvalidRegister;

        const result = ~operand;
        try self.registers.put(destination_register, result);

        try self.updateFlags(destination_register);
    }

    fn handleBranch(self: *Self, instruction_payload: u16) !void {
        const condition_flag = (instruction_payload >> 9) & 0b111;

        const current_flag = self.registers
            .get(Register.R_COND) orelse return VmError.InvalidRegister;

        if ((condition_flag & current_flag) != 0) {
            const pc_offset = utils.signExtend((instruction_payload & 0b1_1111_1111), 9);
            const current_pc = try self.getProgramCounter();
            try self.registers.put(.R_PC, current_pc +% pc_offset);
        }
    }

    fn handleJump(self: *Self, instruction_payload: u16) !void {
        const base_register = std.enums
            .fromInt(Register, (instruction_payload >> 6) & 0b111) orelse return VmError.InvalidRegister;
        const jump_value = self.registers
            .get(base_register) orelse return VmError.InvalidRegister;

        try self.registers.put(Register.R_PC, jump_value);
    }

    fn handleJumpRegister(self: *Self, instruction_payload: u16) !void {
        const long_flag = (instruction_payload >> 11) & 1;
        const pc = try self.getProgramCounter();

        try self.registers.put(.R_R7, pc);

        if (long_flag == 1) {
            const long_pc_offset = utils.signExtend((instruction_payload & 0b111_1111_1111), 11);
            try self.registers.put(.R_PC, pc +% long_pc_offset);
        } else {
            const base_register = std.enums
                .fromInt(Register, (instruction_payload >> 6) & 0b111) orelse return VmError.InvalidRegister;
            const jump_value = self.registers
                .get(base_register) orelse return VmError.InvalidRegister;

            try self.registers.put(.R_PC, jump_value);
        }
    }

    fn handleLoad(self: *Self, instruction_payload: u16) !void {
        const destination_register = std.enums
            .fromInt(Register, (instruction_payload >> 9) & 0b111) orelse return VmError.InvalidRegister;
        const pc_offset = utils.signExtend((instruction_payload & 0b111_111_111), 9);
        const pc = try self.getProgramCounter();
        const value = try self.memory.read(pc +% pc_offset);
        try self.registers.put(destination_register, value);

        try self.updateFlags(destination_register);
    }

    fn handleLoadIndirect(self: *Self, instruction_payload: u16) !void {
        const destination_register = std.enums
            .fromInt(Register, (instruction_payload >> 9) & 0b111) orelse return VmError.InvalidRegister;

        const pc_offset = utils.signExtend((instruction_payload & 0b111_111_111), 9);
        // mem_read(mem_read(reg[R_PC] + pc_offset));
        const pc = try self.getProgramCounter();
        const value = try self.memory.read(try self.memory.read(pc +% pc_offset));
        try self.registers.put(destination_register, value);

        try self.updateFlags(destination_register);
    }

    fn handleLoadRegister(self: *Self, instruction_payload: u16) !void {
        const destination_register = std.enums
            .fromInt(Register, (instruction_payload >> 9) & 0b111) orelse return VmError.InvalidRegister;
        const base_register = std.enums
            .fromInt(Register, ((instruction_payload >> 6) & 0b111)) orelse return VmError.InvalidRegister;

        const base = self.registers.get(base_register) orelse return VmError.InvalidRegister;

        const offset = utils
            .signExtend((instruction_payload & 0b11_1111), 6);

        const value = try self.memory.read(base +% offset);

        try self.registers.put(destination_register, value);

        try self.updateFlags(destination_register);
    }

    fn handleLoadEffectiveAddress(self: *Self, instruction_payload: u16) !void {
        const destination_register = std.enums
            .fromInt(Register, (instruction_payload >> 9) & 0b111) orelse return VmError.InvalidRegister;
        const offset = utils.signExtend((instruction_payload & 0b1_1111_1111), 9);
        const pc = try self.getProgramCounter();

        try self.registers.put(destination_register, pc +% offset);
        try self.updateFlags(destination_register);
    }

    fn handleStore(self: *Self, instruction_payload: u16) !void {
        const source_register = std.enums
            .fromInt(Register, (instruction_payload >> 9) & 0b111) orelse return VmError.InvalidRegister;
        const value = self.registers.get(source_register) orelse return VmError.InvalidRegister;

        const offset = utils.signExtend((instruction_payload & 0b1_1111_1111), 9);
        const pc = try self.getProgramCounter();

        try self.memory.write(pc +% offset, value);
    }

    fn handleStoreIndirect(self: *Self, instruction_payload: u16) !void {
        const source_register = std.enums
            .fromInt(Register, (instruction_payload >> 9) & 0b111) orelse return VmError.InvalidRegister;
        const value = self.registers.get(source_register) orelse return VmError.InvalidRegister;

        const offset = utils.signExtend((instruction_payload & 0b1_1111_1111), 9);
        const pc = try self.getProgramCounter();

        try self.memory.write(try self.memory.read(pc +% offset), value);
    }

    fn handleStoreRegister(self: *Self, instruction_payload: u16) !void {
        const source_register = std.enums
            .fromInt(Register, (instruction_payload >> 9) & 0b111) orelse return VmError.InvalidRegister;
        const value = self.registers.get(source_register) orelse return VmError.InvalidRegister;

        const destination_register = std.enums
            .fromInt(Register, (instruction_payload >> 6) & 0b111) orelse return VmError.InvalidRegister;
        const base_address = self.registers.get(destination_register) orelse return VmError.InvalidRegister;

        const offset = utils.signExtend((instruction_payload & 0b11_1111), 6);

        try self.memory.write(base_address +% offset, value);
    }

    fn handleTrap(self: *Self, instruction_payload: u16) !void {
        const pc = try self.getProgramCounter();
        try self.registers.put(.R_R7, pc);

        const trap_instruction = std.enums
            .fromInt(data.TrapCode, instruction_payload & 0b1111_1111) orelse return VmError.InvalidTrapCode;
        switch (trap_instruction) {
            .TRAP_GETC => {
                const char: u16 = @intCast(try self.reader.takeByte());
                try self.registers.put(.R_R0, char);
                try self.updateFlags(.R_R0);
            },
            .TRAP_OUT => {
                const char: u8 = @truncate(self.registers.get(.R_R0).?);
                try self.writer.print("{c}", .{char});
                try self.writer.flush();
            },
            .TRAP_PUTS => {
                var index: u16 = self.registers.get(.R_R0).?;
                var value = try self.memory.read(index);
                while (value != 0) {
                    const char: u8 = @truncate(value);
                    try self.writer.print("{c}", .{char});

                    index += 1;
                    value = try self.memory.read(index);
                }
                try self.writer.flush();
            },
            .TRAP_IN => {
                try self.writer.print("Enter a character: ", .{});
                try self.writer.flush();
                const char: u8 = @truncate(try self.reader.takeByte());
                try self.writer.print("{c}", .{char});
                try self.writer.flush();

                try self.registers.put(.R_R0, @intCast(char));
                try self.updateFlags(.R_R0);
            },
            .TRAP_PUTSP => {
                var index: u16 = self.registers.get(.R_R0).?;
                var value = try self.memory.read(index);
                while (value != 0) {
                    const char1: u8 = @truncate(value);
                    try self.writer.print("{c}", .{char1});
                    const char2: u8 = @truncate((value >> 8));
                    if (char2 != 0) {
                        try self.writer.print("{c}", .{char2});
                    }

                    index += 1;
                    value = try self.memory.read(index);
                }
                try self.writer.flush();
            },
            .TRAP_HALT => {
                try self.writer.print("HALT\n", .{});
                try self.writer.flush();

                self.running = false;
            },
        }
    }

    fn getProgramCounter(self: *const Self) !u16 {
        if (self.registers
            .get(Register.R_PC)) |pc|
        {
            return pc;
        } else {
            return VmError.InvalidRegister;
        }
    }

    fn readFile(self: *Self, file_name: []const u8) !void {
        var buffer: [data.MEMORY_MAX * 2]u8 = undefined;
        const file = try std.fs.cwd().readFile(file_name, &buffer);
        if (file.len % 2 != 0) {
            return VmError.InvalidFile;
        }
        const origin: u16 = std.mem.readInt(u16, file[0..2], .big);
        if (origin != data.PC_START) {
            return VmError.InvalidOrigin;
        }

        var file_index: usize = 2;
        var program_index = origin;

        while (file_index < file.len) : (file_index += 2) {
            try self.memory.write(program_index, std.mem.readInt(u16, file[file_index..][0..2], .big));
            program_index += 1;
        }
    }
};
