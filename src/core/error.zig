//const std = @import("std");

pub const VmError = error{
    InvalidArgs,
    InvalidRegister,
    InvalidOpCode,
    InvalidOrigin,
    InvalidFile,
    InvalidMemoryAddress,
    InvalidTrapCode,
};
