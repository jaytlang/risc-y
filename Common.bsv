import Vector::*;
import RevertingVirtualReg::*;
import ProcTypes::*;
`include "ProjectDefs.bsv"

// imports used by the hidden files
`include "hiddenImports.bsv"

// Register File
///////////////////////////////////////////////////////////////////////////
interface RFile2R1W;
    method Word rd1(RIndx rindx);
    method Word rd2(RIndx rindx);
    method Action wr(RIndx rindx, Word data);
       method Action displayRFileInSimulation;    
endinterface

module mkRFile2R1W(RFile2R1W);
    Vector#(32, Reg#(Word)) rfile <- replicateM(mkReg(0));

    method Word rd1(RIndx rindx);
        return rfile[rindx];
    endmethod
    method Word rd2(RIndx rindx);
        return rfile[rindx];
    endmethod
    method Action wr(RIndx rindx, Word data);
        if (rindx != 0) begin
            rfile[rindx] <= data;
        end
    endmethod

   method Action displayRFileInSimulation;
        for (Integer i = 0 ; i < 32 ; i = i+1) begin
           $display("x%0d = 0x%x", i, rfile[i]);
        end
        $write("{x31, ..., x0} = 0x");
        for (Integer i = 31 ; i >= 0 ; i = i-1) begin
            $write("%x", rfile[i]);
        end
        $write("\n");
    endmethod
endmodule




// Memory
///////////////////////////////////////////////////////////////////////////

interface Memory;
    method Action req(MemReq memReq);
    method ActionValue#(Word) resp;
endinterface

// This includes the code for mkMemory
`include "hiddenMemory.bsv"

// mkReg and mkRegU replacemen for _write C _write
module mkReg#(t reset_val)(Reg#(t)) provisos (Bits#(t, tSz));
    Reg#(t) _r <- Prelude::mkReg(reset_val);
    // This reverting virtual reg is used to force _write C _write
    Reg#(Bool) double_write_error <- mkRevertingVirtualReg(True);
    method t _read;
        return _r._read;
    endmethod
    method Action _write(t x) if (double_write_error);
        double_write_error <= False;
        _r <= x;
    endmethod
endmodule

module mkRegU(Reg#(t)) provisos (Bits#(t, tSz));
    Reg#(t) _r <- Prelude::mkRegU;
    // This reverting virtual reg is used to force _write C _write
    Reg#(Bool) double_write_error <- mkRevertingVirtualReg(True);
    method t _read;
        return _r._read;
    endmethod
    method Action _write(t x) if (double_write_error);
        double_write_error <= False;
        _r <= x;
    endmethod
endmodule

interface BypassReg#(type t);
    method t oldValue;
    method t newValue;
    method Action _write(t x);
endinterface

module mkBypassReg#(t reset_val)(BypassReg#(t)) provisos (Bits#(t, tSz));
    Array#(Reg#(t)) _r <- mkCReg(2, reset_val);
    // This reverting virtual reg is used to force _write C _write
    Reg#(Bool) double_write_error <- mkRevertingVirtualReg(True);
    method t oldValue;
        return _r[0];
    endmethod
    method t newValue;
        return _r[1];
    endmethod
    method Action _write(t x) if (double_write_error);
        double_write_error <= False;
        _r[0] <= x;
    endmethod
endmodule

