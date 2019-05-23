// Ehr.bsv

// CM for Ehr#(2,t) ehr:
//
//                  |   ehr[0]._read    ehr[0]._write   ehr[1]._read    ehr[1]._write
// -----------------+---------------------------------------------------------------
// ehr[0]._read     |       CF              <               CF              <
// ehr[0]._write    |       >               C               <               <
// ehr[1]._read     |       CF              >               CF              <
// ehr[1]._write    |       >               >               >               C

import Vector::*;
import RWire::*;
import RevertingVirtualReg::*;



typedef Vector#(n, Reg#(t)) Ehr#(numeric type n, type t);

module mkEhr#(t reset_val)(Ehr#(n, t)) provisos (Bits#(t, tSz));
   Array#(Reg#(t)) _m <- mkCReg(valueOf(n), reset_val);
   Vector#(n, Reg#(Bool)) double_write_error <- replicateM(mkRevertingVirtualReg(True));
   Vector#(n, Reg#(t)) _ifc;
   for (Integer i = 0 ; i < valueOf(n) ; i = i+1) begin
      _ifc[i] = interface Reg;
                   method t _read;
                      return _m[i];
                      endmethod
                   method Action _write(t x) if (double_write_error[i]);
                      double_write_error[i] <= False;
                      _m[i] <= x;
                      endmethod
                endinterface;
          end
   return _ifc;
   endmodule
