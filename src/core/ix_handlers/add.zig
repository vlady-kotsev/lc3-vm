const vm = @import("../vm.zig");
const utils = @import("../utils.zig");
const Vm = vm.Vm;

pub fn opAdd(self: *Vm, instr: u16) !void {
    const destReg = (instr >> 9) & 7;
    const srcReg1 = (instr >> 6) & 7;

    const val1 = self.registers.get(@enumFromInt(srcReg1)) orelse unreachable;

    const immFlag = (instr >> 5) & 1;
    var val2: u16 = undefined;
    if (immFlag == 1) {
        val2 = utils.signExtend(instr & 31, 5);
    } else {
        const srcReg2 = instr & 7;
        val2 = self.registers.get(@enumFromInt(srcReg2)) orelse unreachable;
    }

    try self.registers.put(@enumFromInt(destReg), val1 + val2);
}
