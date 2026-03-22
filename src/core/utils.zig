const std = @import("std");
const posix = std.posix;
const c = std.c;

pub fn signExtend(x: u16, num_bits: u4) u16 {
    var result = x;
    if ((result >> (num_bits - 1)) & 1 != 0) {
        result |= (@as(u16, 0xFFFF) << num_bits);
    }
    return result;
}

pub fn switchEndianess(value: u16) u16 {
    return (value >> 8) | (value << 8);
}

pub fn getChar() u16 {
    var buf: [1]u8 = undefined;
    const n = posix.read(posix.STDIN_FILENO, &buf) catch return 0;
    if (n == 0) return 0;
    return buf[0];
}

var original_tio: posix.termios = undefined;
pub fn disableInputBuffering() void {
    original_tio = posix.tcgetattr(posix.STDIN_FILENO) catch return;
    var new_tio = original_tio;
    new_tio.lflag.ICANON = false;
    new_tio.lflag.ECHO = false;
    posix.tcsetattr(posix.STDIN_FILENO, posix.TCSA.NOW, new_tio) catch return;
}

pub fn restoreInputBuffering() void {
    posix.tcsetattr(posix.STDIN_FILENO, posix.TCSA.NOW, original_tio) catch return;
}

fn handleInterrupt(_: c_int) callconv(.c) void {
    restoreInputBuffering();
    posix.exit(2);
}

pub fn setupSignalHandler() void {
    const act = posix.Sigaction{
        .handler = .{ .handler = handleInterrupt },
        .mask = posix.sigemptyset(),
        .flags = 0,
    };
    posix.sigaction(posix.SIG.INT, &act, null);
}

pub fn checkKey() bool {
    var fds = [1]c.pollfd{.{
        .fd = c.STDIN_FILENO,
        .events = 0x001, // POLLIN
        .revents = 0,
    }};
    return c.poll(&fds, fds.len, 0) > 0;
}
