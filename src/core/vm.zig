const std = @import("std");
const Allocator = std.mem.Allocator;
const add_handler = @import("./ix_handlers/add.zig");

pub const MEMORY_MAX = 1 << 16;
pub const PC_START = 0x3000;
pub const Reg = enum(u8) {
    R_R0,
    R_R1,
    R_R2,
    R_R3,
    R_R4,
    R_R5,
    R_R6,
    R_R7,
    R_PC,
    R_COND,
};

pub const Registers = std.AutoHashMap(Reg, u16);

pub const Vm = struct {
    memory: []u16,
    registers: Registers,
    allocator: Allocator,

    pub fn init(allocator: Allocator) !Vm {
        var vm = Vm{
            .memory = try allocator.alloc(u16, MEMORY_MAX),
            .allocator = allocator,
            .registers = std.AutoHashMap(Reg, u16).init(allocator),
        };

        try vm.registers.put(Reg.R_R0, 0);
        try vm.registers.put(Reg.R_R1, 0);
        try vm.registers.put(Reg.R_R2, 0);
        try vm.registers.put(Reg.R_R3, 0);
        try vm.registers.put(Reg.R_R4, 0);
        try vm.registers.put(Reg.R_R5, 0);
        try vm.registers.put(Reg.R_R6, 0);
        try vm.registers.put(Reg.R_R7, 0);
        try vm.registers.put(Reg.R_PC, PC_START);
        try vm.registers.put(Reg.R_COND, @intFromEnum(Flags.FL_ZRO));

        return vm;
    }

    pub fn deinit(self: *Vm) void {
        self.allocator.free(self.memory);
        self.registers.deinit();
    }

    pub fn updateFlags(self: *Vm, reg: Reg) !void {
        const regValue = self.registers.get(reg) orelse unreachable;

        if (regValue == 0) {
            try self.registers.put(reg.R_COND, Flags.FL_ZRO);
        } else if (regValue >> 15) {
            try self.registers.put(reg.R_COND, Flags.FL_NEG);
        } else {
            try self.registers.put(reg.R_COND, Flags.FL_POS);
        }
    }

    pub fn run(self: *Vm) !void {
        //@{Load Arguments}
        //@{Setup}

        const running = true;
        while (running) {
            //* FETCH */
            //uint16_t instr = mem_read(reg[R_PC]++);
            //uint16_t op = instr >> 12;
            const op: u16 = 10;
            const instr :u16 = 10;
            switch (op) {
                .OP_ADD => {
                   try add_handler.opAdd(self, instr);
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
                    //@{LDI}
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
                    //@{TRAP}
                },
                .OP_RES, .OP_RTI => {
                    // Ignore
                },
                else => {
                    //@{BAD OPCODE}
                },
            }
        }
        // @{Shutdown}
    }
};

pub const Ixs = enum(u16) {
    OP_BR, //* branch */
    OP_ADD, //* add  */
    OP_LD, //* load */
    OP_ST, //* store */
    OP_JSR, //* jump register */
    OP_AND, //* bitwise and */
    OP_LDR, //* load register */
    OP_STR, //* store register */
    OP_RTI, //* unused */
    OP_NOT, //* bitwise not */
    OP_LDI, //* load indirect */
    OP_STI, //* store indirect */
    OP_JMP, //* jump */
    OP_RES, //* reserved (unused) */
    OP_LEA, //* load effective address */
    OP_TRAP, //* execute trap */
};

pub const Flags = enum(u8) {
    FL_POS = 1 << 0, //* P */
    FL_ZRO = 1 << 1, //* Z */
    FL_NEG = 1 << 2, //* N */
};
