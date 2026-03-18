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
                    //@{AND}
                },
                .OP_NOT => {
                    //@{NOT}
                },
                .OP_BR => {
                    //@{BR}
                },
                .OP_JMP => {
                    //@{JMP}
                },
                .OP_JSR => {
                    //@{JSR}
                },
                .OP_LD => {
                    //@{LD}
                },
                .OP_LDI => {
                    try self.handleLoadIndirect(instruction_payload);
                },
                .OP_LDR => {
                    //@{LDR}
                },
                .OP_LEA => {
                    //@{LEA}
                },
                .OP_ST => {
                    //@{ST}
                },
                .OP_STI => {
                    //@{STI}
                },
                .OP_STR => {
                    //@{STR}
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
            try self.registers.put(reg.R_COND, @intFromEnum(Flag.FL_ZRO));
        } else if (regValue >> 15) {
            try self.registers.put(reg.R_COND, @intFromEnum(Flag.FL_NEG));
        } else {
            try self.registers.put(reg.R_COND, @intFromEnum(Flag.FL_POS));
        }
    }

    fn handleAdd(self: *Self, instruction_payload: u16) !void {
        const destination_register = std.enums
            .fromInt(Register, @as(u8, (instruction_payload >> 9) & 0b111)) orelse return VmError.InvalidRegister;

        const source_register1 = std.enums
            .fromInt(Register, @as(u8, (instruction_payload >> 6) & 0b111)) orelse return VmError.InvalidRegister;
        const first_operand = self.registers
            .get(source_register1) orelse return VmError.InvalidRegister;

        const immediate_flag = (instruction_payload >> 5) & 0b1;

        const second_operand = blk: {
            if (immediate_flag == 1) {
                break :blk utils.signExtend(instruction_payload & 0b11111, 5);
            } else {
                const source_register2 = std.enums
                    .fromInt(Register, @as(u8, instruction_payload & 0b111)) orelse return VmError.InvalidRegister;

                break :blk self.registers
                    .get(source_register2) orelse return VmError.InvalidRegister;
            }
        };

        const result = first_operand + second_operand;
        try self.registers.put(destination_register, result);

        self.updateFlags(destination_register);
    }

    fn handleLoadIndirect(self: *Self, instruction_payload: u16) !void {
        const destination_register = std.enums
            .fromInt(Register, @as(u8, (instruction_payload >> 9) & 0b111)) orelse return VmError.InvalidRegister;

        const pc_offset = utils.signExtend((instruction_payload & 0b111_111_111), 9);
        // mem_read(mem_read(reg[R_PC] + pc_offset));
        const pc = self.registers.get(Register.R_PC) orelse return VmError.InvalidRegister;
        const value = try memoryRead(try memoryRead(pc + pc_offset));
        try self.registers.put(destination_register, value);

        self.updateFlags(destination_register);
    }

    fn memoryRead(address: u16) !u16 {
        _ = address;
        return 0;
    }
};
