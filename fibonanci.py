import os

PROJECT_DIR = "D:/kairo/32multi/project_1"
os.makedirs(PROJECT_DIR, exist_ok=True)
IMEM_PATH = os.path.join(PROJECT_DIR, "imem.hex")

def R_TYPE(f7, rs2, rs1, f3, rd, op=0b0110011): return ((f7 & 0x7F) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((f3 & 0x7) << 12) | ((rd & 0x1F) << 7) | op
def I_TYPE(imm, rs1, f3, rd, op=0b0010011): return ((imm & 0xFFF) << 20) | ((rs1 & 0x1F) << 15) | ((f3 & 0x7) << 12) | ((rd & 0x1F) << 7) | op
def S_TYPE(imm, rs2, rs1, f3, op=0b0100011): imm12 = imm & 0xFFF; return ((imm12 >> 5) << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((f3 & 0x7) << 12) | ((imm12 & 0x1F) << 7) | op
def B_TYPE(imm, rs2, rs1, f3, op=0b1100011): imm13 = imm & 0x1FFE; b12 = (imm13 >> 12) & 1; b11 = (imm13 >> 11) & 1; b10_5 = (imm13 >> 5) & 0x3F; b4_1 = (imm13 >> 1) & 0xF; return (b12 << 31) | (b10_5 << 25) | ((rs2 & 0x1F) << 20) | ((rs1 & 0x1F) << 15) | ((f3 & 0x7) << 12) | (b4_1 << 8) | (b11 << 7) | op

fib_program = [
    # --- KHỞI TẠO ---
    I_TYPE(9,  0, 0b000, 4),             # 0x00: ADDI x4, x0, 9     (x4 = i = 9 lần lặp)
    S_TYPE(0,  0, 0, 0b010),             # 0x04: SW   x0, 0(x0)     (MEM[0] = a = 0)
    I_TYPE(1,  0, 0b000, 6),             # 0x08: ADDI x6, x0, 1     (x6 = 1)
    S_TYPE(4,  6, 0, 0b010),             # 0x0C: SW   x6, 4(x0)     (MEM[4] = b = 1)

    # --- VÒNG LẶP --- (PC = 0x10)
    I_TYPE(0,  0, 0b010, 2, 0b0000011),  # 0x10: LW   x2, 0(x0)     (Load a)
    I_TYPE(4,  0, 0b010, 3, 0b0000011),  # 0x14: LW   x3, 4(x0)     (Load b)
    R_TYPE(0,  3, 2, 0b000, 5),          # 0x18: ADD  x5, x2, x3    (c = a + b) -> [Load-Use Stall]
    S_TYPE(0,  3, 0, 0b010),             # 0x1C: SW   x3, 0(x0)     (Lưu a mới = b)
    S_TYPE(4,  5, 0, 0b010),             # 0x20: SW   x5, 4(x0)     (Lưu b mới = c) -> [Forwarding]
    I_TYPE(-1, 4, 0b000, 4),             # 0x24: ADDI x4, x4, -1    (i = i - 1)
    B_TYPE(-24, 0, 4, 0b001),            # 0x28: BNE  x4, x0, loop  (Nhảy lại 0x10 nếu i != 0) -> [Flush 2 nhịp]

    # --- KẾT THÚC --- (PC = 0x2C)
    I_TYPE(4,  0, 0b010, 7, 0b0000011),  # 0x2C: LW   x7, 4(x0)     (Load kết quả cuối vào x7)
    B_TYPE(0,  0, 0, 0b000)              # 0x30: BEQ  x0, x0, end   (Vòng lặp vô hạn)
]

imem_bytes = [0x00] * 1024
for idx, word in enumerate(fib_program):
    base = idx * 4
    imem_bytes[base + 0] = (word >> 0)  & 0xFF
    imem_bytes[base + 1] = (word >> 8)  & 0xFF
    imem_bytes[base + 2] = (word >> 16) & 0xFF
    imem_bytes[base + 3] = (word >> 24) & 0xFF

with open(IMEM_PATH, "w") as f:
    for b in imem_bytes:
        f.write(f"{b:02x}\n")

print(f"[SUCCESS] Đã tạo imem.hex chứa chương trình Fibonacci(10) dùng BNE.")