import ProcTypes::*;

function DecodedInst decode(Bit#(32) inst);
    let opcode = inst[6:0];
    let funct3 = inst[14:12];
    let funct7 = inst[31:25];
    let dst     = inst[11:7];
    let src1    = inst[19:15];
    let src2    = inst[24:20];
    let csr    = inst[31:20];

    Word immI = signExtend(inst[31:20]);
    Word immS = signExtend({ inst[31:25], inst[11:7] });
    Word immB = signExtend({ inst[31], inst[7], inst[30:25], inst[11:8], 1'b0});
    Word immU = signExtend({ inst[31:12], 12'b0 });
    Word immJ = signExtend({ inst[31], inst[19:12], inst[20], inst[30:21], 1'b0});

    DecodedInst dInst = ?;
    dInst.iType = Unsupported;
    dInst.dst = tagged Invalid;
    dInst.src1 = tagged Invalid;
    dInst.src2 = tagged Invalid;
    case(opcode)
        opOp: begin
            if (funct7 == 7'b0000000) begin
                case (funct3)
                    fnADD:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Add,  iType: OP };
                    fnSLT:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Slt,  iType: OP };
                    fnSLTU: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Sltu, iType: OP };
                    fnXOR:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Xor,  iType: OP };
                    fnOR:   dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Or,   iType: OP };
                    fnAND:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: And,  iType: OP };
                    fnSLL:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Sll,  iType: OP };
                    fnSR:   dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Srl,  iType: OP };
                endcase
            end else if (funct7 == 7'b0100000) begin
                case (funct3)
                    fnADD:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Sub,  iType: OP };
                    fnSR:   dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: Sra,  iType: OP };
                endcase
            end//  else if (funct7 == 7'b0000001) begin
        //         // Multiply instruction
        //         case (funct3)
        //             fnMUL:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Valid src2, imm: ?, brFunc: ?, aluFunc: ?,  iType: MUL };
        //         endcase
        //     end
        end
        opOpImm: begin
            case (funct3)
                fnADD:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Add,  iType: OPIMM };
                fnSLT:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Slt,  iType: OPIMM };
                fnSLTU: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Sltu, iType: OPIMM };
                fnXOR:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Xor,  iType: OPIMM };
                fnOR:   dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Or,   iType: OPIMM };
                fnAND:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: And,  iType: OPIMM };
                fnSLL:  begin
                    if (funct7 == 7'b0000000) begin
                        dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Sll, iType: OPIMM };
                    end
                end
                fnSR: begin
                    if (funct7 == 7'b0000000) begin
                        dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Srl, iType: OPIMM };
                    end else if (funct7 == 7'b0100000) begin
                        dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: Sra, iType: OPIMM };
                    end
                end
            endcase
        end
        opBranch: begin
            case(funct3)
                fnBEQ:  dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immB, brFunc: Eq,  aluFunc: ?, iType: BRANCH };
                fnBNE:  dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immB, brFunc: Neq, aluFunc: ?, iType: BRANCH };
                fnBLT:  dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immB, brFunc: Lt,  aluFunc: ?, iType: BRANCH };
                fnBGE:  dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immB, brFunc: Ge,  aluFunc: ?, iType: BRANCH };
                fnBLTU: dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immB, brFunc: Ltu, aluFunc: ?, iType: BRANCH };
                fnBGEU: dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immB, brFunc: Geu, aluFunc: ?, iType: BRANCH };
            endcase
        end
        opLui:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Invalid,   src2: tagged Invalid, imm: immU, brFunc: ?, aluFunc: ?, iType: LUI };
        opJal:  dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Invalid,   src2: tagged Invalid, imm: immJ, brFunc: ?, aluFunc: ?, iType: JAL };
        opJalr: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: ?, iType: JALR };
        opLoad: if (funct3 == fnLW) begin
            dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Valid src1, src2: tagged Invalid, imm: immI, brFunc: ?, aluFunc: ?, iType: LOAD };
        end
        opStore: if (funct3 == fnSW) begin
            dInst = DecodedInst { dst: tagged Invalid, src1: tagged Valid src1, src2: tagged Valid src2, imm: immS, brFunc: ?, aluFunc: ?, iType: STORE };
        end
        opAuipc: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Invalid,   src2: tagged Invalid, imm: immU, brFunc: ?, aluFunc: ?, iType: AUIPC };
        // opSystem: begin
        //     if (funct3 == fnCSR && src1 == 0) begin
        //         case (csr)
        //             csrCycle:   dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Invalid, src2: tagged Invalid, imm: ?, brFunc: ?, aluFunc: ?, iType: RDCYCLE };
        //             csrInstret: dInst = DecodedInst { dst: tagged Valid dst, src1: tagged Invalid, src2: tagged Invalid, imm: ?, brFunc: ?, aluFunc: ?, iType: RDINSTRET };
        //         endcase
        //     end
        // end
    endcase
    return dInst;
endfunction
