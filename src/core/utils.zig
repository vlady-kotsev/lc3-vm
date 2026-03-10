const vm = @import("vm.zig");

pub fn signExtend(x: u16, num_bits: usize) u16 {
    if ((x >> (num_bits - 1)) & 1) {
        x |= (0xFFFF << num_bits);
    }
    return x;
}

