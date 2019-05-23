// Register File
///////////////////////////////////////////////////////////////////////////
import ProcTypes::*;
import Vector::*;
import Common::*;
import Ehr::*;

interface RFile2R1W;
    method Word rd1(RIndx rindx);
    method Word rd2(RIndx rindx);
    method Action wr(RIndx rindx, Word data);
       method Action displayRFileInSimulation;    
endinterface

module mkBypassRFile2R1W(RFile2R1W);
    Vector#(32, Ehr#(2, Word)) rfile <- replicateM(mkEhr(0));

    method Action wr(RIndx rindx, Word data);
      if(rindx != 0) begin
	(rfile[rindx])[0] <= data;
      end
    endmethod

    method Word rd1(RIndx rindx);
	return (rfile[rindx])[1];
    endmethod

    method Word rd2(RIndx rindx);
	return (rfile[rindx])[1];
    endmethod

   method Action displayRFileInSimulation;
        for (Integer i = 0 ; i < 32 ; i = i+1) begin
           $display("x%0d = 0x%x", i, (rfile[i])[0]);
        end
        $write("{x31, ..., x0} = 0x");
        for (Integer i = 31 ; i >= 0 ; i = i-1) begin
            $write("%x", (rfile[i])[0]);
        end
        $write("\n");
   endmethod
endmodule

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

