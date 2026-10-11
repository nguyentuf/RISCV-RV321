import os

PROJECT_DIR = "D:/kairo/32multi/project_1"
os.makedirs(PROJECT_DIR, exist_ok=True)

IMEM_PATH           = os.path.join(PROJECT_DIR, "imem.hex")
EXPECTED_TRACE_PATH = os.path.join(PROJECT_DIR, "expected_trace.hex")
EXPECTED_REG_PATH   = os.path.join(PROJECT_DIR, "expected_regs.hex")
EXPECTED_DMEM_PATH  = os.path.join(PROJECT_DIR, "expected_dmem.hex")

def sign_extend(val, bits):
    if (val & (1 << (bits - 1))) != 0:
        val = val - (1 << bits)
    return val

def to_u32(val):
    return val & 0xFFFFFFFF

def to_s32(val):
    val = val & 0xFFFFFFFF
    return val - 0x100000000 if val & 0x80000000 else val

# ==============================================================================
# CÁC HÀM MÃ HÓA LỆNH RV32I (MINI-ASSEMBLER)
# ==============================================================================
def R_TYPE(f7, rs2, rs1, f3, rd, op=0b0110011):
    return ((f7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((f3 & 0x7) << 12) | ((rd & 0x1F) << 7) | op

def I_TYPE(imm, rs1, f3, rd, op=0b0010011):
    return ((imm & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | ((f3 & 0x7) << 12) | ((rd & 0x1F) << 7) | op

def S_TYPE(imm, rs2, rs1, f3, op=0b0100011):
    imm12 = imm & 0xFFF
    return ((imm12 >> 5) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((f3 & 0x7) << 12) | ((imm12 & 0x1F) << 7) | op

def B_TYPE(imm, rs2, rs1, f3, op=0b1100011):
    imm13 = imm & 0x1FFE
    b12   = (imm13 >> 12) & 1
    b11   = (imm13 >> 11) & 1
    b10_5 = (imm13 >> 5) & 0x3F
    b4_1  = (imm13 >> 1) & 0xF
    return (b12 << 31) | (b10_5 << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((f3 & 0x7) << 12) | (b4_1 << 8) | (b11 << 7) | op

def U_TYPE(imm20, rd, op):
    return ((imm20 & 0xFFFFF) << 12) | ((rd & 0x1F) << 7) | op

def J_TYPE(imm, rd, op=0b1101111):
    imm21  = imm & 0x1FFFFE
    b20    = (imm21 >> 20) & 1
    b19_12 = (imm21 >> 12) & 0xFF
    b11    = (imm21 >> 11) & 1
    b10_1  = (imm21 >> 1) & 0x3FF
    return (b20 << 31) | (b10_1 << 21) | (b11 << 20) | (b19_12 << 12) | ((rd & 0x1F) << 7) | op

# ==============================================================================
# CHƯƠNG TRÌNH KIỂM THỬ TOÀN BỘ 37 LỆNH RV32I
# ==============================================================================
program_words = [
    # --- 1. NHÓM U-TYPE (2 lệnh: LUI, AUIPC) ---
    U_TYPE(0x12345, 1, 0b0110111),          # 01. LUI   x1, 0x12345       -> x1 = 0x12345000
    U_TYPE(0x00001, 2, 0b0010111),          # 02. AUIPC x2, 0x00001       -> x2 = PC(0x04) + 0x1000 = 0x00001004

    # --- 2. NHÓM I-TYPE ALU (9 lệnh: ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI) ---
    I_TYPE(-10,     0, 0b000, 3),           # 03. ADDI  x3, x0, -10       -> x3 = -10 (0xFFFFFFF6)
    I_TYPE(20,      0, 0b000, 4),           # 04. ADDI  x4, x0, 20        -> x4 = 20  (0x00000014)
    I_TYPE(-5,      3, 0b010, 5),           # 05. SLTI  x5, x3, -5        -> x5 = 1   (-10 < -5 signed)
    I_TYPE(-5,      3, 0b011, 6),           # 06. SLTIU x6, x3, -5        -> x6 = 1   (0xFFFFFFF6 < 0xFFFFFFFB unsigned)
    I_TYPE(0x0FF,   4, 0b100, 7),           # 07. XORI  x7, x4, 0x0FF     -> x7 = 20 ^ 255 = 0xEB
    I_TYPE(0x0F0,   4, 0b110, 8),           # 08. ORI   x8, x4, 0x0F0     -> x8 = 20 | 240 = 0xF4
    I_TYPE(0x00F,   4, 0b111, 9),           # 09. ANDI  x9, x4, 0x00F     -> x9 = 20 & 15  = 0x04
    I_TYPE(0x003,   4, 0b001, 10),          # 10. SLLI  x10, x4, 3        -> x10 = 20 << 3 = 160 (0xA0)
    I_TYPE(0x002,   3, 0b101, 11),          # 11. SRLI  x11, x3, 2        -> x11 = 0xFFFFFFF6 >> 2 = 0x3FFFFFFD
    I_TYPE(0x402,   3, 0b101, 12),          # 12. SRAI  x12, x3, 2        -> x12 = -10 >>> 2 = -3 (0xFFFFFFFD)

    # --- 3. NHÓM R-TYPE ALU (10 lệnh: ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND) ---
    I_TYPE(3,       0, 0b000, 13),          # Chuẩn bị x13 = 3 (shamt)
    R_TYPE(0x00, 4,  3,  0b000, 14),        # 13. ADD   x14, x3, x4       -> x14 = -10 + 20 = 10
    R_TYPE(0x20, 4,  3,  0b000, 15),        # 14. SUB   x15, x3, x4       -> x15 = -10 - 20 = -30 (0xFFFFFFE2)
    R_TYPE(0x00, 13, 4,  0b001, 16),        # 15. SLL   x16, x4, x13      -> x16 = 20 << 3 = 160 (0xA0)
    R_TYPE(0x00, 4,  3,  0b010, 17),        # 16. SLT   x17, x3, x4       -> x17 = 1 (-10 < 20 signed)
    R_TYPE(0x00, 4,  3,  0b011, 18),        # 17. SLTU  x18, x3, x4       -> x18 = 0 (0xFFFFFFF6 > 20 unsigned)
    R_TYPE(0x00, 8,  7,  0b100, 19),        # 18. XOR   x19, x7, x8       -> x19 = 0xEB ^ 0xF4 = 0x1F
    R_TYPE(0x00, 13, 3,  0b101, 20),        # 19. SRL   x20, x3, x13      -> x20 = 0xFFFFFFF6 >> 3 = 0x1FFFFFFE
    R_TYPE(0x20, 13, 3,  0b101, 21),        # 20. SRA   x21, x3, x13      -> x21 = -10 >>> 3 = -2 (0xFFFFFFFE)
    R_TYPE(0x00, 8,  7,  0b110, 22),        # 21. OR    x22, x7, x8       -> x22 = 0xEB | 0xF4 = 0xFF
    R_TYPE(0x00, 8,  7,  0b111, 23),        # 22. AND   x23, x7, x8       -> x23 = 0xEB & 0xF4 = 0xE0

    # --- 4. NHÓM STORE (3 lệnh: SW, SH, SB) & LOAD (5 lệnh: LW, LH, LHU, LB, LBU) ---
    U_TYPE(0xdeadc, 24, 0b0110111),         # Chuẩn bị x24: LUI x24, 0xdeadc -> 0xdeadc000
    I_TYPE(-273,    24, 0b000, 24),         # ADDI x24, x24, -273            -> x24 = 0xdeadbeef
    S_TYPE(16, 24, 0, 0b010),               # 23. SW    x24, 16(x0)       -> MEM[16..19] = 0xdeadbeef
    S_TYPE(20, 24, 0, 0b001),               # 24. SH    x24, 20(x0)       -> MEM[20..21] = 0xbeef
    S_TYPE(22, 24, 0, 0b000),               # 25. SB    x24, 22(x0)       -> MEM[22]     = 0xef
    I_TYPE(16, 0,  0b010, 25, 0b0000011),   # 26. LW    x25, 16(x0)       -> x25 = 0xdeadbeef
    I_TYPE(20, 0,  0b001, 26, 0b0000011),   # 27. LH    x26, 20(x0)       -> x26 = 0xffffbeef (sign-ext)
    I_TYPE(20, 0,  0b101, 27, 0b0000011),   # 28. LHU   x27, 20(x0)       -> x27 = 0x0000beef (zero-ext)
    I_TYPE(22, 0,  0b000, 28, 0b0000011),   # 29. LB    x28, 22(x0)       -> x28 = 0xffffffef (sign-ext)
    I_TYPE(22, 0,  0b100, 29, 0b0000011),   # 30. LBU   x29, 22(x0)       -> x29 = 0x000000ef (zero-ext)

    # --- 5. NHÓM BRANCH (6 lệnh: BEQ, BNE, BLT, BGE, BLTU, BGEU - Test cả Not-Taken & Taken) ---
    # 31. BEQ
    B_TYPE(8,  4, 3, 0b000),                # BEQ  x3(-10), x4(20), +8    -> Not Taken
    B_TYPE(8,  3, 3, 0b000),                # BEQ  x3(-10), x3(-10), +8   -> Taken (nhảy qua lệnh dưới)
    I_TYPE(99, 0, 0b000, 30),               # (Bị bỏ qua)
    # 32. BNE
    B_TYPE(8,  3, 3, 0b001),                # BNE  x3(-10), x3(-10), +8   -> Not Taken
    B_TYPE(8,  4, 3, 0b001),                # BNE  x3(-10), x4(20), +8    -> Taken (nhảy qua lệnh dưới)
    I_TYPE(99, 0, 0b000, 30),               # (Bị bỏ qua)
    # 33. BLT (signed)
    B_TYPE(8,  3, 4, 0b100),                # BLT  x4(20), x3(-10), +8    -> Not Taken
    B_TYPE(8,  4, 3, 0b100),                # BLT  x3(-10), x4(20), +8    -> Taken
    I_TYPE(99, 0, 0b000, 30),               # (Bị bỏ qua)
    # 34. BGE (signed)
    B_TYPE(8,  4, 3, 0b101),                # BGE  x3(-10), x4(20), +8    -> Not Taken
    B_TYPE(8,  3, 4, 0b101),                # BGE  x4(20), x3(-10), +8    -> Taken
    I_TYPE(99, 0, 0b000, 30),               # (Bị bỏ qua)
    # 35. BLTU (unsigned: x4=20 < x3=0xFFFFFFF6)
    B_TYPE(8,  4, 3, 0b110),                # BLTU x3(0xFFFFFFF6), x4(20) -> Not Taken
    B_TYPE(8,  3, 4, 0b110),                # BLTU x4(20), x3(0xFFFFFFF6) -> Taken
    I_TYPE(99, 0, 0b000, 30),               # (Bị bỏ qua)
    # 36. BGEU (unsigned: x3=0xFFFFFFF6 >= x4=20)
    B_TYPE(8,  3, 4, 0b111),                # BGEU x4(20), x3(0xFFFFFFF6) -> Not Taken
    B_TYPE(8,  4, 3, 0b111),                # BGEU x3(0xFFFFFFF6), x4(20) -> Taken
    I_TYPE(99, 0, 0b000, 30),               # (Bị bỏ qua)

    # --- 6. NHÓM JUMP (2 lệnh: JAL, JALR) ---
    # 37. JAL & JALR
    J_TYPE(8, 30),                          # JAL  x30, +8                -> x30 = PC+4, nhảy qua lệnh dưới
    I_TYPE(99, 0, 0b000, 31),               # (Bị bỏ qua)
    I_TYPE(8, 30, 0b000, 31, 0b1100111),    # JALR x31, x30, 8            -> x31 = PC+4, nhảy tới x30 + 8 (nhảy qua lệnh dưới)
    I_TYPE(99, 0, 0b000, 30),               # (Bị bỏ qua)
    I_TYPE(77, 0, 0b000, 13),               # Lệnh chốt cuối: ADDI x13, x0, 77 -> x13 = 77 (0x4D)
]

# Xuất imem.hex (Little Endian theo từng byte)
imem_bytes = [0x00] * 1024
for idx, word in enumerate(program_words):
    base = idx * 4
    imem_bytes[base + 0] = (word >> 0)  & 0xFF
    imem_bytes[base + 1] = (word >> 8)  & 0xFF
    imem_bytes[base + 2] = (word >> 16) & 0xFF
    imem_bytes[base + 3] = (word >> 24) & 0xFF

with open(IMEM_PATH, "w") as f:
    for b in imem_bytes:
        f.write(f"{b:02x}\n")

# ==============================================================================
# GOLDEN MODEL CHẠY TỪNG CHU KỲ & XUẤT TRACE
# ==============================================================================
regs = [0] * 32
dmem = [0] * 4096
pc = 0

# Tổng số lệnh nạp là 59, trong đó có 8 lệnh nhảy Taken bỏ qua 8 lệnh dummy -> Thực chạy 51 chu kỳ
NUM_CYCLES = 51
trace_lines = []

for cycle in range(NUM_CYCLES):
    instr = (imem_bytes[pc+3] << 24) | (imem_bytes[pc+2] << 16) | (imem_bytes[pc+1] << 8) | imem_bytes[pc]
    opcode = instr & 0x7F
    rd     = (instr >> 7) & 0x1F
    func3  = (instr >> 12) & 0x7
    rs1    = (instr >> 15) & 0x1F
    rs2    = (instr >> 20) & 0x1F
    func7  = (instr >> 25) & 0x7F

    v_rs1 = regs[rs1]
    v_rs2 = regs[rs2]

    pc_curr   = pc
    pc_next   = to_u32(pc + 4)
    reg_write = 0
    wb_data   = 0
    mem_read  = 0
    mem_write = 0
    mem_addr  = 0
    mem_wdata = v_rs2

    if opcode == 0b0110011: # R-Type
        reg_write = 1
        if func3 == 0b000:   res = (v_rs1 - v_rs2) if (func7 == 0b0100000) else (v_rs1 + v_rs2)
        elif func3 == 0b100: res = v_rs1 ^ v_rs2
        elif func3 == 0b110: res = v_rs1 | v_rs2
        elif func3 == 0b111: res = v_rs1 & v_rs2
        elif func3 == 0b001: res = v_rs1 << (v_rs2 & 0x1F)
        elif func3 == 0b101: res = (to_s32(v_rs1) >> (v_rs2 & 0x1F)) if (func7 == 0b0100000) else (v_rs1 >> (v_rs2 & 0x1F))
        elif func3 == 0b010: res = 1 if to_s32(v_rs1) < to_s32(v_rs2) else 0
        elif func3 == 0b011: res = 1 if v_rs1 < v_rs2 else 0
        wb_data = to_u32(res)

    elif opcode == 0b0010011: # I-Type ALU
        reg_write = 1
        imm = sign_extend((instr >> 20) & 0xFFF, 12)
        u_imm = to_u32(imm)
        shamt = (instr >> 20) & 0x1F
        if func3 == 0b000:   res = v_rs1 + u_imm
        elif func3 == 0b100: res = v_rs1 ^ u_imm
        elif func3 == 0b110: res = v_rs1 | u_imm
        elif func3 == 0b111: res = v_rs1 & u_imm
        elif func3 == 0b001: res = v_rs1 << shamt
        elif func3 == 0b101: res = (to_s32(v_rs1) >> shamt) if (func7 == 0b0100000) else (v_rs1 >> shamt)
        elif func3 == 0b010: res = 1 if to_s32(v_rs1) < imm else 0
        elif func3 == 0b011: res = 1 if v_rs1 < u_imm else 0
        wb_data = to_u32(res)

    elif opcode == 0b0000011: # Load
        reg_write = 1
        imm = sign_extend((instr >> 20) & 0xFFF, 12)
        mem_addr = to_u32(v_rs1 + imm)
        if func3 == 0b000:
            mem_read = 0b0001
            res = sign_extend(dmem[mem_addr], 8)
        elif func3 == 0b001:
            mem_read = 0b0010
            res = sign_extend(dmem[mem_addr] | (dmem[mem_addr+1] << 8), 16)
        elif func3 == 0b010:
            mem_read = 0b1000
            res = dmem[mem_addr] | (dmem[mem_addr+1] << 8) | (dmem[mem_addr+2] << 16) | (dmem[mem_addr+3] << 24)
        elif func3 == 0b100:
            mem_read = 0b1001
            res = dmem[mem_addr]
        elif func3 == 0b101:
            mem_read = 0b1010
            res = dmem[mem_addr] | (dmem[mem_addr+1] << 8)
        wb_data = to_u32(res)

    elif opcode == 0b0100011: # Store
        imm = sign_extend(((instr >> 25) << 5) | ((instr >> 7) & 0x1F), 12)
        mem_addr = to_u32(v_rs1 + imm)
        if func3 == 0b000:
            mem_write = 0b0001
            dmem[mem_addr] = v_rs2 & 0xFF
        elif func3 == 0b001:
            mem_write = 0b0010
            dmem[mem_addr]   = v_rs2 & 0xFF
            dmem[mem_addr+1] = (v_rs2 >> 8) & 0xFF
        elif func3 == 0b010:
            mem_write = 0b1000
            dmem[mem_addr]   = v_rs2 & 0xFF
            dmem[mem_addr+1] = (v_rs2 >> 8) & 0xFF
            dmem[mem_addr+2] = (v_rs2 >> 16) & 0xFF
            dmem[mem_addr+3] = (v_rs2 >> 24) & 0xFF

    elif opcode == 0b1100011: # Branch
        imm = (((instr >> 31) & 1) << 12) | (((instr >> 7) & 1) << 11) | (((instr >> 25) & 0x3F) << 5) | (((instr >> 8) & 0xF) << 1)
        imm = sign_extend(imm, 13)
        taken = False
        if func3 == 0b000:   taken = (v_rs1 == v_rs2)
        elif func3 == 0b001: taken = (v_rs1 != v_rs2)
        elif func3 == 0b100: taken = (to_s32(v_rs1) < to_s32(v_rs2))
        elif func3 == 0b101: taken = (to_s32(v_rs1) >= to_s32(v_rs2))
        elif func3 == 0b110: taken = (v_rs1 < v_rs2)
        elif func3 == 0b111: taken = (v_rs1 >= v_rs2)
        if taken:
            pc_next = to_u32(pc + imm)

    elif opcode == 0b1101111: # JAL
        reg_write = 1
        imm = (((instr >> 31) & 1) << 20) | (((instr >> 12) & 0xFF) << 12) | (((instr >> 20) & 1) << 11) | (((instr >> 21) & 0x3FF) << 1)
        imm = sign_extend(imm, 21)
        wb_data = to_u32(pc + 4)
        pc_next = to_u32(pc + imm)

    elif opcode == 0b1100111: # JALR
        reg_write = 1
        imm = sign_extend((instr >> 20) & 0xFFF, 12)
        wb_data = to_u32(pc + 4)
        pc_next = to_u32(v_rs1 + imm)

    elif opcode == 0b0110111: # LUI
        reg_write = 1
        wb_data = instr & 0xFFFFF000

    elif opcode == 0b0010111: # AUIPC
        reg_write = 1
        wb_data = to_u32(pc + (instr & 0xFFFFF000))

    if reg_write and rd != 0:
        regs[rd] = wb_data
    regs[0] = 0

    trace_str = (
        f"{pc_curr:08x}"
        f"{instr:08x}"
        f"{pc_next:08x}"
        f"{reg_write:01x}"
        f"{rd:02x}"
        f"{wb_data:08x}"
        f"{mem_read:01x}"
        f"{mem_write:01x}"
        f"{mem_addr:08x}"
        f"{mem_wdata:08x}"
    )
    trace_lines.append(trace_str)
    pc = pc_next

with open(EXPECTED_TRACE_PATH, "w") as f:
    for line in trace_lines:
        f.write(line + "\n")

with open(EXPECTED_REG_PATH, "w") as f:
    for r in regs:
        f.write(f"{r:08x}\n")

with open(EXPECTED_DMEM_PATH, "w") as f:
    for b in dmem:
        f.write(f"{b:02x}\n")

print(f"[SUCCESS] Đã tạo bộ test 37 lệnh RV32I ({NUM_CYCLES} chu kỳ) thành công!")
