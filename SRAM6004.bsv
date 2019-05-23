import CacheTypes::*;
import Common::*;
import MemoryTypes::*;
import RegFile::*;
// import BRAMCore::*;
import RWBramCore::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
import Vector::*;

interface SRAM#(numeric type indexSz, type dataT);
   method Action rdReq(Bit#(indexSz) index);
   method Action wrReq(Bit#(indexSz) index, dataT wrData);
   method ActionValue#(dataT) resp;
endinterface

// schedule {wrReq < rdReq} CF resp;

module mkSRAM( SRAM#(addrSz, dataT) ) provisos (Bits#(dataT, dataSz));
    Integer memSz = valueOf(TExp#(addrSz));
    Bool hasOutputRegister = False;

    Vector#(TExp#(addrSz), Array#(Reg#(Bool))) rowIsInit <- replicateM(mkCReg(2, False));
    // BRAM_PORT#(Bit#(addrSz), dataT) bram <- mkBRAMCore1(memSz, hasOutputRegister);
   RWBramCore#(Bit#(addrSz), dataT) bram <- mkRWBramCore;

   FIFOF#(Tuple2#(Bool, Maybe#(dataT))) readPendingFifo <- mkLFIFOF;
   FIFO#(dataT) readRespFifo <- mkBypassFIFO;

   RWire#(Tuple2#(Bit#(addrSz), dataT)) wrReqWire <- mkRWire;
   rule propagateResp;
      readPendingFifo.deq;
      bram.deqRdResp;
      let {init, byPass} = readPendingFifo.first;
      if (init) begin
         readRespFifo.enq(isValid(byPass)? fromMaybe(?,byPass) : bram.rdResp);
      end 
      else begin
         readRespFifo.enq(unpack(0));
      end
   endrule

   method Action rdReq(Bit#(addrSz) a);// if (readPendingFifo.notFull);
      bram.rdReq(a);
      
      if ( wrReqWire.wget matches tagged Valid .v ) begin
         let {wrAddr, wrVal } = v;
         readPendingFifo.enq(tuple2(rowIsInit[a][1], a==wrAddr? tagged Valid wrVal: tagged Invalid));
      end
      else
         readPendingFifo.enq(tuple2(rowIsInit[a][1], tagged Invalid));
      // let write = (op == St);
      // bram.put(write, a, d);
      // if (!write) begin
      //    readPendingFifo.enq(rowIsInit[a]);
      // end 
      // else begin
      //    rowIsInit[a] <= True;
      // end
    endmethod
   
   
   method Action wrReq(Bit#(addrSz) index, dataT wrData);
      rowIsInit[index][0] <= True;
      wrReqWire.wset(tuple2(index, wrData));
      bram.wrReq(index, wrData);
   endmethod
   
   
    method ActionValue#(dataT) resp;
        readRespFifo.deq;
        return readRespFifo.first;
    endmethod
endmodule
