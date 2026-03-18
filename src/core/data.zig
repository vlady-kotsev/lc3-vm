pub const MEMORY_MAX = 1 << 16;
pub const PC_START = 0x3000;

pub const Register = enum(u8) {
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

pub const OpCode = enum(u8) {
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

pub const Flag = enum(u16) {
    FL_POS = 1 << 0, //* P */
    FL_ZRO = 1 << 1, //* Z */
    FL_NEG = 1 << 2, //* N */
};

pub const TrapCode = enum(u8) {
    TRAP_GETC = 0x20, // get character from keyboard, not echoed onto the terminal */
    TRAP_OUT = 0x21, // output a character */
    TRAP_PUTS = 0x22, // output a word string */
    TRAP_IN = 0x23, // get character from keyboard, echoed onto the terminal */
    TRAP_PUTSP = 0x24, // output a byte string */
    TRAP_HALT = 0x25, // halt the program */
};
