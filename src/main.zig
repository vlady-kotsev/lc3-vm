const std = @import("std");
const lc3_vm = @import("lc3_vm");
const VmError = lc3_vm.errors.VmError;
const Vm = lc3_vm.vm.Vm;
// const logly = @import("logly");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        return VmError.InvalidArgs;
    }

    var vm = try Vm.init(allocator);
    defer vm.deinit();

    // const logger = try logly.Logger.init(allocator);
    // defer logger.deinit();

    // // Entire log lines are colored by level!
    // try logger.info("Logly-Zig is working!", @src());
}
