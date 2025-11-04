from __future__ import annotations
import re
import sys
import argparse
from pathlib import Path
from dataclasses import dataclass
from typing import List, Dict, Tuple, Optional

REG_RE = re.compile(r"^(R|r)(1[0-5]|[0-9])$")
COMMENT_RE = re.compile(r"(;|#|//).*?$")
LABEL_RE = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$")

def parse_int(token: str) -> int:
    s = token.replace("_", "").strip()
    neg = s.startswith("-")
    if s.startswith(("+", "-")):
        s = s[1:]
    if s.lower().startswith("0x"):
        val = int(s, 16)
    elif s.lower().startswith("0b"):
        val = int(s, 2)
    else:
        val = int(s, 10)
    return -val if neg else val

def reg_id(tok: str) -> int:
    m = REG_RE.match(tok.strip())
    if not m:
        raise ValueError(f"Bad register '{tok}' (use R0..R15).")
    idx = int(m.group(2))
    if not (0 <= idx <= 15):
        raise ValueError(f"Register out of range '{tok}' (0..15).")
    return idx

def fit_unsigned(x: int, bits: int) -> int:
    if x < 0 or x > (1 << bits) - 1:
        raise ValueError(f"Unsigned {bits}-bit immediate out of range: {x}")
    return x

def fit_signed(x: int, bits: int) -> int:
    lo, hi = -(1 << (bits - 1)), (1 << (bits - 1)) - 1
    if x < lo or x > hi:
        raise ValueError(f"Signed {bits}-bit immediate out of range: {x}")
    return x & ((1 << bits) - 1)

def tokenize_operands(op_str: str) -> List[str]:
    toks = [t.strip() for t in op_str.split(",") if t.strip() != ""]
    return toks

R_FUNCTS = {
    "ADD":  0b001000,
    "SUB":  0b001001,
    "INC":  0b001010,
    "DEC":  0b001011,
    "SLT":  0b001100,
    "SGT":  0b001101,
    "AND":  0b010000,
    "OR":   0b010001,
    "XOR":  0b010010,
    "NOR":  0b010011,
    "NOT":  0b010100,
    "SL":   0b011000,
    "SRL":  0b011001,
    "SRA":  0b011010,
    "HAM":  0b100000,
    "MOVE": 0b101000,
    "CMOV": 0b101001,
}
R_OPCODE = 0

I_OPCODES = {
    "ADDI": 0b001000,
    "SUBI": 0b001001,
    "ANDI": 0b010000,
    "ORI":  0b010001,
    "XORI": 0b010010,
    "SLAI": 0b011000,
    "SRLI": 0b011001,
    "SRAI": 0b011010,
    "LUI":  0b100001,
    "LD":   0b101010,
    "ST":   0b101011,
    "BMI":  0b110001,
    "BPL":  0b110010,
    "BZ":   0b110011,
    "SLI":  0b011000,
}

J_OPCODES = { "BR": 0b110000 }
PC_OPCODES = { "HALT": 0b111000, "NOP": 0b111001 }

ALL_MNEMONICS = set(R_FUNCTS) | set(I_OPCODES) | set(J_OPCODES) | set(PC_OPCODES)

@dataclass
class AsmLine:
    addr: int
    text: str
    mnemonic: Optional[str]
    operands: List[str]
    raw: str
    line_no: int

REG_RE = re.compile(r"^(R|r)(1[0-5]|[0-9])$")
COMMENT_RE = re.compile(r"(;|#|//).*?$")
LABEL_RE = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$")

def preprocess(lines: List[str]) -> List[str]:
    out = []
    for ln in lines:
        ln = COMMENT_RE.sub("", ln)
        out.append(ln.rstrip("\n"))
    return out

def pass1(lines: List[str], base_addr: int = 0):
    pc = base_addr
    parsed: List[AsmLine] = []
    labels: Dict[str, int] = {}
    for i, line in enumerate(lines, start=1):
        raw = line
        line = line.strip()
        if not line:
            continue
        m = LABEL_RE.match(line)
        if m:
            label, rest = m.group(1), m.group(2)
            if label in labels:
                raise ValueError(f"Duplicate label '{label}' (line {i}).")
            labels[label] = pc
            line = rest.strip()
            if not line:
                continue
        if not line:
            continue
        parts = line.split(None, 1)
        mnemonic = parts[0].upper()
        ops_str = parts[1] if len(parts) > 1 else ""
        if mnemonic not in ALL_MNEMONICS:
            raise ValueError(f"Unknown mnemonic '{mnemonic}' on line {i}: {raw}")
        operands = [t.strip() for t in ops_str.split(",") if t.strip() != ""]
        parsed.append(AsmLine(addr=pc, text=line, mnemonic=mnemonic, operands=operands, raw=raw, line_no=i))
        pc += 4
    return parsed, labels

def encode_R(mn: str, ops: List[str], line_no: int) -> int:
    funct = R_FUNCTS[mn]
    opcode = R_OPCODE
    rs = rt = rd = shamt = 0
    if mn in ("SL", "SRL", "SRA"):
        if len(ops) != 3:
            raise ValueError(f"{mn} expects 'rd, rs, shamt' (line {line_no}).")
        rd = reg_id(ops[0]); rs = reg_id(ops[1]); shamt = fit_unsigned(parse_int(ops[2]), 5); rt = 0
    elif mn in ("INC", "DEC", "NOT", "HAM", "MOVE", "CMOV"):
        if len(ops) != 2:
            raise ValueError(f"{mn} expects 'rd, rs' (line {line_no}).")
        rd = reg_id(ops[0]); rs = reg_id(ops[1]); rt = 0; shamt = 0
    else:
        if len(ops) != 3:
            raise ValueError(f"{mn} expects 'rd, rs, rt' (line {line_no}).")
        rd = reg_id(ops[0]); rs = reg_id(ops[1]); rt = reg_id(ops[2]); shamt = 0
    inst = 0
    inst |= (opcode & 0x3F) << 26
    inst |= (rs & 0xF) << 22
    inst |= (rt & 0xF) << 18
    inst |= (rd & 0xF) << 14
    inst |= (shamt & 0x1F) << 9
    inst |= (funct & 0x3F) << 3
    return inst  # [2:0] unused

def parse_mem_operand(tok: str):
    m = re.match(r"^([+-]?(?:0x[0-9a-fA-F]+|0b[01_]+|\d+))(?:\s*)\((R|r)(1[0-5]|[0-9])\)$", tok.strip())
    if not m:
        raise ValueError(f"Bad memory operand '{tok}'. Expected like 12(R3) or -8(R0).")
    imm = parse_int(m.group(1))
    rs = int(m.group(3))
    return imm, rs

def encode_I(mn: str, ops: List[str], labels: Dict[str, int], curr_pc: int, line_no: int) -> int:
    opcode = I_OPCODES[mn]
    rs = rt = 0
    imm16 = 0
    if mn in ("LD", "ST"):
        if len(ops) != 2:
            raise ValueError(f"{mn} expects 'rt, imm(rs)' (line {line_no}).")
        rt = reg_id(ops[0])
        disp, rs = parse_mem_operand(ops[1])
        imm16 = fit_signed(disp, 16)
    elif mn in ("BMI", "BPL", "BZ"):
        if len(ops) != 2:
            raise ValueError(f"{mn} expects 'rs, label|offset' (line {line_no}).")
        rs = reg_id(ops[0])
        target = ops[1]
        if target in labels:
            delta_bytes = labels[target] - (curr_pc + 4)
        else:
            delta_bytes = parse_int(target)
        if delta_bytes % 4 != 0:
            raise ValueError(f"Branch target not word-aligned (line {line_no}).")
        word_off = delta_bytes // 4
        imm16 = fit_signed(word_off, 16)
        rt = 0
    elif mn == "LUI":
        if len(ops) != 2:
            raise ValueError(f"LUI expects 'rt, imm16' (line {line_no}).")
        rt = reg_id(ops[0]); rs = 0; imm16 = fit_unsigned(parse_int(ops[1]), 16)
    else:
        if len(ops) != 3:
            raise ValueError(f"{mn} expects 'rt, rs, imm16' (line {line_no}).")
        rt = reg_id(ops[0]); rs = reg_id(ops[1])
        signed = mn in ("ADDI", "SUBI", "SLAI", "SRLI", "SRAI")
        val = parse_int(ops[2])
        imm16 = fit_signed(val, 16) if signed else fit_unsigned(val, 16)
    inst = 0
    inst |= (opcode & 0x3F) << 26
    inst |= (rs & 0xF) << 22
    inst |= (rt & 0xF) << 18
    inst |= (imm16 & 0xFFFF) << 2  # immediate in bits [17:2]
    return inst

def encode_J(mn: str, ops: List[str], labels: Dict[str, int], line_no: int) -> int:
    if mn != "BR":
        raise ValueError(f"Unsupported J-type '{mn}'.")
    if len(ops) != 1:
        raise ValueError(f"BR expects 'label|absolute' (line {line_no}).")
    opcode = J_OPCODES[mn]
    if ops[0] in labels:
        target = labels[ops[0]] // 4  # absolute word address
    else:
        target = parse_int(ops[0])
    target = fit_unsigned(target, 26)
    inst = 0
    inst |= (opcode & 0x3F) << 26
    inst |= target & 0x03FFFFFF
    return inst

def encode_PC(mn: str) -> int:
    opcode = PC_OPCODES[mn]
    inst = (opcode & 0x3F) << 26
    return inst

def encode_one(rec, labels: Dict[str, int]) -> int:
    mn = rec.mnemonic
    if mn in R_FUNCTS:
        return encode_R(mn, rec.operands, rec.line_no)
    if mn in I_OPCODES:
        return encode_I(mn, rec.operands, labels, rec.addr, rec.line_no)
    if mn in J_OPCODES:
        return encode_J(mn, rec.operands, labels, rec.line_no)
    if mn in PC_OPCODES:
        return encode_PC(mn)
    raise ValueError(f"Internal: unhandled mnemonic {mn}")

def format_word(w: int, kind: str) -> str:
    if kind == "hex32":
        return f"{w:08x}"
    elif kind == "HEX32":
        return f"{w:08X}"
    elif kind == "bin32":
        return f"{w:032b}"
    else:
        raise ValueError("format must be one of: hex32, HEX32, bin32")

def write_output(words, fmt: str, out_path: Path):
    with out_path.open("w") as f:
        if fmt == "memh":
            for w in words:
                f.write(f"{w:08X}\n")
        elif fmt in ("hex32", "HEX32", "bin32"):
            for w in words:
                f.write(format_word(w, fmt) + "\n")
        else:
            raise ValueError("Unknown --format. Use memh | hex32 | HEX32 | bin32")

def make_listing(recs, words) -> str:
    out = []
    for r, w in zip(recs, words):
        out.append(f"{r.addr:08x}: {w:08X}    {r.raw.strip()}")
    return "\n".join(out)

def assemble(text: str, base_addr: int = 0):
    lines = text.splitlines()
    clean = []
    for ln in lines:
        ln = COMMENT_RE.sub("", ln)
        clean.append(ln.rstrip("\n"))
    recs, labels = pass1(clean, base_addr=base_addr)
    words = [encode_one(r, labels) for r in recs]
    return recs, labels, words

def main(argv=None):
    p = argparse.ArgumentParser(description="MiniRISC Assembler")
    p.add_argument("input", type=Path, help="assembly file (.asm)")
    p.add_argument("-o", "--output", type=Path, help="output file (default: input with .hex)")
    p.add_argument("--format", default="memh", choices=["memh","hex32","HEX32","bin32"],
                   help="output format; memh is $readmemh-friendly (default)")
    p.add_argument("--list", dest="listfile", type=Path, help="optional listing file")
    p.add_argument("--base-addr", type=lambda x: parse_int(x), default=0,
                   help="base address (default 0)")
    args = p.parse_args(argv)

    asm_text = args.input.read_text()
    recs, labels, words = assemble(asm_text, base_addr=args.base_addr)
    out = args.output or args.input.with_suffix(".hex")
    write_output(words, args.format, out)
    if args.listfile:
        args.listfile.write_text(make_listing(recs, words))
    print(f"Assembled {len(words)} instructions -> {out}")
    if args.listfile:
        print(f"Wrote listing -> {args.listfile}")
    if labels:
        print("Labels:")
        for k in sorted(labels):
            print(f"  {k}: 0x{labels[k]:08X} ({labels[k]//4})")

if __name__ == "__main__":
    # When run without args, demonstrate with a tiny program like the one in the screenshot.
    if len(sys.argv) == 1:
        demo = """
; Program to calculate sum 1+...+5 into R2 and store at MEM[0]
ADDI R1, R0, 5
ADDI R2, R0, 0
LOOP:
ADD  R2, R2, R1
SUBI R1, R1, 1
BPL  R1, LOOP
ST   R2, 0(R0)
HALT
"""
        recs, labels, words = assemble(demo, base_addr=0)
        print(make_listing(recs, words))
    else:
        main()
