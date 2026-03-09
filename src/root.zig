const std = @import("std");
const vm = @import("core/vm.zig");
pub const errors = @import("core/error.zig");

// pub const VmError = errors.VmError;

fn run() void {
    //@{Load Arguments}
    //@{Setup}

    //* since exactly one condition flag should be set at any given time, set the Z flag */
    vm.regs[vm.Reg.R_COND] = vm.Flags.FL_ZRO;

    //* set the PC to starting position */
    //* 0x3000 is the default */
    vm.regs[vm.Reg.R_PC] = vm.PC_START;

    const running = true;
    while (running) {
        //* FETCH */
        //uint16_t instr = mem_read(reg[R_PC]++);
        //uint16_t op = instr >> 12;
        const op: u16 = 10;
        switch (op) {
            .OP_ADD => {
                //@{ADD}
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
