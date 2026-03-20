const std = @import("std");
const Allocator = std.mem.Allocator;
const VmError = @import("error.zig").VmError;
const data = @import("data.zig");
const Register = data.Register;
const Flag = data.Flag;
const utils = @import("utils.zig");

pub const Vm = struct {
    memory: []u16,
    registers: std.AutoHashMap(Register, u16),
    allocator: Allocator,

    const Self = @This();
    // === Public methods ===
    pub fn init(allocator: Allocator) !Self {
        var vm = Self{
            .memory = try allocator.alloc(u16, data.MEMORY_MAX),
            .allocator = allocator,
            .registers = std.AutoHashMap(Register, u16).init(allocator),
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
        self.allocator.free(self.memory);
        self.registers.deinit();
    }

    pub fn run(self: *Self) !void {
        //@{Load Arguments}
        //@{Setup}
        const running = true;
        while (running) {
            //* FETCH */
            //uint16_t instr = mem_read(reg[R_PC]++);
            //uint16_t op = instr >> 12;
            const op: u16 = 10;
            const instruction_payload: u16 = 10;
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
                    //reg[R_R7] = reg[R_PC];

                    switch (instruction_payload & 0xFF) {
                        .TRAP_GETC => {
                            //@{TRAP GETC}
                        },
                        .TRAP_OUT => {
                            // @{TRAP OUT}
                        },
                        .TRAP_PUTS => {
                            //   @{TRAP PUTS}
                        },
                        .TRAP_IN => {
                            //@{TRAP IN}
                        },
                        .TRAP_PUTSP => {
                            //@{TRAP PUTSP}
                        },
                        .TRAP_HALT => {
                            //@{TRAP HALT}
                        },
                    }
                },
                .OP_RES, .OP_RTI => {
                    // Ignore
                },
                else => {
                    return VmError.InvalidOpCode;
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
        const value = try memoryRead(pc +% pc_offset);
        try self.registers.put(destination_register, value);

        try self.updateFlags(destination_register);
    }

    fn handleLoadIndirect(self: *Self, instruction_payload: u16) !void {
        const destination_register = std.enums
            .fromInt(Register, (instruction_payload >> 9) & 0b111) orelse return VmError.InvalidRegister;

        const pc_offset = utils.signExtend((instruction_payload & 0b111_111_111), 9);
        // mem_read(mem_read(reg[R_PC] + pc_offset));
        const pc = try self.getProgramCounter();
        const value = try memoryRead(try memoryRead(pc +% pc_offset));
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

        const value = try memoryRead(base +% offset);

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

        try memoryWrite(pc +% offset, value);
    }

    fn handleStoreIndirect(self: *Self, instruction_payload: u16) !void {
        const source_register = std.enums
            .fromInt(Register, (instruction_payload >> 9) & 0b111) orelse return VmError.InvalidRegister;
        const value = self.registers.get(source_register) orelse return VmError.InvalidRegister;

        const offset = utils.signExtend((instruction_payload & 0b1_1111_1111), 9);
        const pc = try self.getProgramCounter();

        try memoryWrite(try memoryRead(pc +% offset), value);
    }

    fn handleStoreRegister(self: *Self, instruction_payload: u16) !void {
        const source_register = std.enums
            .fromInt(Register, (instruction_payload >> 9) & 0b111) orelse return VmError.InvalidRegister;
        const value = self.registers.get(source_register) orelse return VmError.InvalidRegister;

        const destination_register = std.enums
            .fromInt(Register, (instruction_payload >> 6) & 0b111) orelse return VmError.InvalidRegister;
        const base_address = self.registers.get(destination_register) orelse return VmError.InvalidRegister;

        const offset = utils.signExtend((instruction_payload & 0b11_1111), 6);

        try memoryWrite(base_address +% offset, value);
    }

    fn memoryRead(address: u16) !u16 {
        _ = address;
        return 0;
    }

    fn memoryWrite(address: u16, value: u16) !void {
        _ = address;
        _ = value;
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
};
