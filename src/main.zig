const std = @import("std");
const lc3_vm = @import("lc3_vm");
const VmError = lc3_vm.errors.VmError;
const Vm = lc3_vm.vm.Vm;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    
    const args = try lc3_vm.handleArgs(allocator);
    defer std.process.argsFree(allocator, args);

    var vm = try Vm.init(allocator);
    defer vm.deinit();

    try vm.run(args[1]);
}
