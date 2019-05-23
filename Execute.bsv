// import Common::*;
import ProcTypes::*;
import ALU::*;


// ALU
///////////////////////////////////////////////////////////////////////////

// `include "hiddenALU.bsv"




function Bool aluBr(Word a, Word b, BrFunc brFunc);
    Bool res = case (brFunc)
        Eq:     (a == b);
        Neq:    (a != b);
        Lt:     signedLT(a, b);
        Ltu:    (a < b);
        Ge:     signedGE(a, b);
        Geu:    (a >= b);
        AT:     True;
        NT:     False;
    endcase;
    return res;
endfunction


function ExecInst execute( DecodedInst dInst, Word rVal1, Word rVal2, Word pc );
    let imm = dInst.imm;
    let brFunc = dInst.brFunc;
    let aluFunc = dInst.aluFunc;
    Word data = ?;
    Word nextPc = ?;
    Word addr = ?;
    case (dInst.iType) matches
        OP: begin data = alu(rVal1, rVal2, aluFunc); nextPc = pc+4; end
        OPIMM: begin data = alu(rVal1, imm, aluFunc); nextPc = pc+4; end
        BRANCH: begin nextPc = aluBr(rVal1, rVal2, brFunc) ? pc+imm : pc+4; end
        LUI: begin data = imm; nextPc = pc+4; end
        JAL: begin data = pc+4; nextPc = pc+imm; end
        JALR: begin data = pc+4; nextPc = rcaN(rVal1,imm,0) & ~1; end
        LOAD: begin addr = rcaN(rVal1, imm, 0); nextPc = pc+4; end
        STORE: begin data = rVal2; addr = rcaN(rVal1, imm, 0); nextPc = pc+4; end
        AUIPC: begin data = rcaN(pc, imm, 0); nextPc = pc+4; end
    endcase
    ExecInst eInst = ?;
    eInst.iType = dInst.iType;
    eInst.dst = dInst.dst;
    eInst.data = data;
    eInst.addr = addr;
    eInst.nextPc = nextPc;
    return eInst;
endfunction


