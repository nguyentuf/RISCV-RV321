import os

PROJECT_DIR = "D:/kairo/32multi/project_1"
os.makedirs(PROJECT_DIR, exist_ok=True)
IMEM_PATH = os.path.join(PROJECT_DIR, "imem.hex")
EXPECTED_REG_PATH = os.path.join(PROJECT_DIR, "expected_regs.hex")
EXPECTED_DMEM_PATH = os.path.join(PROJECT_DIR, "expected_dmem.hex")

def sign_extend(val, bits): return val - (1 << bits) if (val & (1 << (bits - 1))) != 0 else val
def to_u32(val): return val & 0xFFFFFFFF
def to_s32(val): val = val & 0xFFFFFFFF; return val - 0x100000000 if val & 0x80000000 else val

def R_TYPE(f7, rs2, rs1, f3, rd, op=0b0110011): return ((f7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((f3 & 0x7) << 12) | ((rd & 0x1F) << 7) | op
def I_TYPE(imm, rs1, f3, rd, op=0b0010011): return ((imm & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | ((f3 & 0x7) << 12) | ((rd & 0x1F) << 7) | op
def S_TYPE(imm, rs2, rs1, f3, op=0b0100011): imm12 = imm & 0xFFF; return ((imm12 >> 5) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((f3 & 0x7) << 12) | ((imm12 & 0x1F) << 7) | op
def B_TYPE(imm, rs2, rs1, f3, op=0b1100011): imm13 = imm & 0x1FFE; return (((imm13 >> 12) & 1) << 31) | (((imm13 >> 5) & 0x3F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((f3 & 0x7) << 12) | (((imm13 >> 1) & 0xF) << 8) | (((imm13 >> 11) & 1) << 7) | op
def J_TYPE(imm, rd, op=0b1101111): imm21 = imm & 0x1FFFFE; return (((imm21 >> 20) & 1) << 31) | (((imm21 >> 1) & 0x3FF) << 21) | (((imm21 >> 11) & 1) << 20) | (((imm21 >> 12) & 0xFF) << 12) | ((rd & 0x1F) << 7) | op
def U_TYPE(imm20, rd, op): return ((imm20 & 0xFFFFF) << 12) | ((rd & 0x1F) << 7) | op

# =========================================================================================
# CHƯƠNG TRÌNH BAO PHỦ 5 NHÓM TEST (ALU, LOAD/STORE, FORWARDING, STALL, CONTROL HAZARD)
# =========================================================================================
program = [
    # -------------------------------------------------------------------------------------
    # NHÓM 1: ALU & EDGE CASES (Số âm, tràn số, LUI, AUIPC, Shift)
    # -------------------------------------------------------------------------------------
    U_TYPE(0x12345, 1, 0b0110111),          # 0x00: LUI   x1, 0x12345       (x1 = 0x12345000)
    U_TYPE(0x00000, 2, 0b0010111),          # 0x04: AUIPC x2, 0             (x2 = 0x04)
    I_TYPE(-1, 0, 0b000, 3),                # 0x08: ADDI  x3, x0, -1        (x3 = 0xFFFFFFFF)
    I_TYPE(1, 0, 0b000, 4),                 # 0x0C: ADDI  x4, x0, 1         (x4 = 1)
    R_TYPE(0, 4, 3, 0b000, 5),              # 0x10: ADD   x5, x3, x4        (Tràn số: x5 = 0)
    R_TYPE(0x20, 4, 3, 0b000, 6),           # 0x14: SUB   x6, x3, x4        (Số âm: x6 = 0xFFFFFFFE)
    R_TYPE(0, 4, 3, 0b111, 7),              # 0x18: AND   x7, x3, x4        (x7 = 1)
    R_TYPE(0, 4, 3, 0b110, 8),              # 0x1C: OR    x8, x3, x4        (x8 = 0xFFFFFFFF)
    R_TYPE(0, 4, 3, 0b100, 9),              # 0x20: XOR   x9, x3, x4        (x9 = 0xFFFFFFFE)
    R_TYPE(0, 4, 3, 0b010, 10),             # 0x24: SLT   x10, x3, x4       (Signed: -1 < 1 -> x10 = 1)
    R_TYPE(0, 4, 3, 0b011, 11),             # 0x28: SLTU  x11, x3, x4       (Unsigned: 0xFFFFFFFF > 1 -> x11 = 0)
    I_TYPE(2, 4, 0b001, 12),                # 0x2C: SLLI  x12, x4, 2        (x12 = 4)
    I_TYPE(1, 3, 0b101, 13),                # 0x30: SRLI  x13, x3, 1        (x13 = 0x7FFFFFFF)
    I_TYPE(0x401, 3, 0b101, 14),            # 0x34: SRAI  x14, x3, 1        (x14 = 0xFFFFFFFF)

    # -------------------------------------------------------------------------------------
    # NHÓM 2 + 3: LOAD/STORE & FORWARDING (EX->EX, MEM->EX)
    # -------------------------------------------------------------------------------------
    I_TYPE(128, 0, 0b000, 15),              # 0x38: ADDI  x15, x0, 128      (Base Addr)
    R_TYPE(0, 15, 15, 0b000, 16),           # 0x3C: ADD   x16, x15, x15     (FORWARD EX->EX: x16 = 256)
    R_TYPE(0, 16, 15, 0b000, 17),           # 0x40: ADD   x17, x15, x16     (FORWARD MEM->EX: x17 = 384)
    S_TYPE(0, 3, 15, 0b010),                # 0x44: SW    x3, 0(x15)        (MEM[128] = 0xFFFFFFFF)
    S_TYPE(4, 15, 15, 0b001),               # 0x48: SH    x15, 4(x15)       (MEM[132] = 0x0080)
    S_TYPE(6, 16, 15, 0b000),               # 0x4C: SB    x16, 6(x15)       (MEM[134] = 0x00)

    # -------------------------------------------------------------------------------------
    # NHÓM 4: STALL (Load-Use Hazard)
    # -------------------------------------------------------------------------------------
    I_TYPE(0, 15, 0b000, 18, 0b0000011),    # 0x50: LB    x18, 0(x15)       (x18 = 0xFFFFFFFF)
    R_TYPE(0, 18, 18, 0b000, 19),           # 0x54: ADD   x19, x18, x18     (STALL 1 CYC -> x19 = 0xFFFFFFFE)
    I_TYPE(4, 15, 0b101, 20, 0b0000011),    # 0x58: LHU   x20, 4(x15)       (x20 = 0x00000080)

    # -------------------------------------------------------------------------------------
    # NHÓM 5: CONTROL HAZARD (BNE, BEQ, JAL, JALR)
    # -------------------------------------------------------------------------------------
    B_TYPE(8, 0, 0, 0b001),                 # 0x5C: BNE   x0, x0, +8        (Not Taken)
    B_TYPE(8, 19, 3, 0b001),                # 0x60: BNE   x3, x19, +8       (Taken -> FLUSH IF/ID & ID/EX)
    I_TYPE(99, 0, 0b000, 21),               # 0x64: Bị FLUSH (NOP)
    J_TYPE(8, 22),                          # 0x68: JAL   x22, +8           (Taken -> x22=0x6C, FLUSH)
    I_TYPE(99, 0, 0b000, 21),               # 0x6C: Bị FLUSH (NOP)
    I_TYPE(8, 22, 0b000, 23, 0b1100111),    # 0x70: JALR  x23, x22, 8       (Taken -> Nhảy tới 0x6C+8 = 0x74)
    I_TYPE(99, 0, 0b000, 21),               # 0x74: Bị FLUSH (NOP)
    I_TYPE(200, 0, 0b000, 24)               # 0x78: ADDI  x24, x0, 200      (Đích đến an toàn cuối cùng)
]

# Xuất imem.hex
imem_bytes = [0x00] * 1024
for idx, word in enumerate(program):
    for i in range(4): imem_bytes[idx*4 + i] = (word >> (i*8)) & 0xFF
with open(IMEM_PATH, "w") as f:
    for b in imem_bytes: f.write(f"{b:02x}\n")

# Chạy Simulator giả lập (Golden Model)
regs = [0] * 32
dmem = [0] * 4096
pc = 0

while pc < len(program) * 4:
    instr = (imem_bytes[pc+3] << 24) | (imem_bytes[pc+2] << 16) | (imem_bytes[pc+1] << 8) | imem_bytes[pc]
    if instr == 0: break
    op, rd, f3, rs1, rs2, f7 = instr & 0x7F, (instr >> 7) & 0x1F, (instr >> 12) & 0x7, (instr >> 15) & 0x1F, (instr >> 20) & 0x1F, (instr >> 25) & 0x7F
    next_pc = pc + 4
    v1, v2 = regs[rs1], regs[rs2]

    if op == 0b0110011:
        if f3==0: res = (v1-v2) if f7 else (v1+v2)
        elif f3==1: res = v1 << (v2 & 0x1F)
        elif f3==2: res = 1 if to_s32(v1) < to_s32(v2) else 0
        elif f3==3: res = 1 if v1 < v2 else 0
        elif f3==4: res = v1 ^ v2
        elif f3==5: res = (to_s32(v1) >> (v2 & 0x1F)) if f7 else (v1 >> (v2 & 0x1F))
        elif f3==6: res = v1 | v2
        elif f3==7: res = v1 & v2
        if rd: regs[rd] = to_u32(res)
    elif op == 0b0010011:
        imm = sign_extend((instr >> 20) & 0xFFF, 12)
        if f3==0: res = v1 + imm
        elif f3==1: res = v1 << (imm & 0x1F)
        elif f3==2: res = 1 if to_s32(v1) < imm else 0
        elif f3==3: res = 1 if v1 < to_u32(imm) else 0
        elif f3==4: res = v1 ^ imm
        elif f3==5: res = (to_s32(v1) >> (imm & 0x1F)) if f7 else (v1 >> (imm & 0x1F))
        elif f3==6: res = v1 | imm
        elif f3==7: res = v1 & imm
        if rd: regs[rd] = to_u32(res)
    elif op == 0b0000011:
        addr = to_u32(v1 + sign_extend((instr >> 20) & 0xFFF, 12))
        if f3==0: res = sign_extend(dmem[addr], 8)
        elif f3==1: res = sign_extend(dmem[addr] | (dmem[addr+1]<<8), 16)
        elif f3==2: res = dmem[addr] | (dmem[addr+1]<<8) | (dmem[addr+2]<<16) | (dmem[addr+3]<<24)
        elif f3==4: res = dmem[addr]
        elif f3==5: res = dmem[addr] | (dmem[addr+1]<<8)
        if rd: regs[rd] = to_u32(res)
    elif op == 0b0100011:
        addr = to_u32(v1 + sign_extend(((instr >> 25) << 5) | rd, 12))
        dmem[addr] = v2 & 0xFF
        if f3 >= 1: dmem[addr+1] = (v2 >> 8) & 0xFF
        if f3 == 2: dmem[addr+2] = (v2 >> 16) & 0xFF; dmem[addr+3] = (v2 >> 24) & 0xFF
    elif op == 0b1100011:
        imm = sign_extend((((instr >> 31)&1)<<12) | (((instr >> 7)&1)<<11) | (((instr >> 25)&0x3F)<<5) | (((instr >> 8)&0xF)<<1), 13)
        tk = False
        if f3==0: tk = (v1 == v2)
        elif f3==1: tk = (v1 != v2)
        elif f3==4: tk = (to_s32(v1) < to_s32(v2))
        elif f3==5: tk = (to_s32(v1) >= to_s32(v2))
        elif f3==6: tk = (v1 < v2)
        elif f3==7: tk = (v1 >= v2)
        if tk: next_pc = to_u32(pc + imm)
    elif op == 0b1101111:
        imm = sign_extend((((instr >> 31)&1)<<20) | (((instr >> 12)&0xFF)<<12) | (((instr >> 20)&1)<<11) | (((instr >> 21)&0x3FF)<<1), 21)
        if rd: regs[rd] = to_u32(pc + 4)
        next_pc = to_u32(pc + imm)
    elif op == 0b1100111:
        imm = sign_extend((instr >> 20) & 0xFFF, 12)
        if rd: regs[rd] = to_u32(pc + 4)
        next_pc = to_u32(v1 + imm)
    elif op == 0b0110111:
        if rd: regs[rd] = instr & 0xFFFFF000
    elif op == 0b0010111:
        if rd: regs[rd] = to_u32(pc + (instr & 0xFFFFF000))
    pc = next_pc

with open(EXPECTED_REG_PATH, "w") as f:
    for r in regs: f.write(f"{r:08x}\n")
with open(EXPECTED_DMEM_PATH, "w") as f:
    for b in dmem: f.write(f"{b:02x}\n")

print("[SUCCESS] Đã tạo mã máy 5 NHÓM TEST cùng file kiểm tra (expected_regs.hex, expected_dmem.hex)!")
