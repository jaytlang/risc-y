import Common::*;
import CacheTypes::*;
import DRAM::*;
import Cache::*;

import MemoryTypes::*;
import BRAM::*;
import Vector::*;
import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;



/*interface Memory;
    method Action req(MemReq memReq);
    method ActionValue#(Word) resp;
    method Tuple2#(Bit#(32), Bit#(32)) peekCnt; // peek hit and miss counts
    method Bit#(32) getHitCount;
    method Bit#(32) getMissCount;
endinterface*/

interface MemorySystem;
   interface Memory iCache;
   interface Memory dCache;
endinterface


module mkMemorySystem(MemorySystem);
   Vector#(2, Cache#(6)) caches = ?;
   caches <- replicateM(mkCache);
   
   Integer latency = 0; 
   
   DRAM dram <- mkSimDRAM(latency);
   
   FIFO#(Bit#(1)) nextResp <- mkSizedFIFO(latency+1);
   
   Vector#(2, Array#(Reg#(Bit#(64)))) totalCnts <- replicateM(mkCReg(2,0));
   // Vector#(2, Array#(Reg#(Bit#(64)))) missCnts <- replicateM(mkCReg(2,0));
   Vector#(2, Reg#(Bit#(64))) missCnts <- replicateM(mkReg(0));
   
   Reg#(Bit#(64)) cycles <- mkReg(0);
   rule doCycle;
       cycles <= cycles + 1;
       if ( cycles > 10000000 ) begin
           $display("FAILED: Your processor timed out");
           $finish;
       end
   endrule
   
   for (Integer i=0; i < 2; i=i+1) begin
      rule connectDramReq;
         let lineReq <- caches[i].lineReq();
         dram.req(lineReq);
         if (lineReq.op == Ld) begin
            missCnts[i] <= missCnts[i] + 1;
            nextResp.enq(fromInteger(i));
         end
      endrule

      rule connectDramResp if (nextResp.first == fromInteger(i));
         // $display("%t, dram resped to %d", $time, i);
         nextResp.deq;
         let resp <- dram.resp;
         caches[i].lineResp(resp);
      endrule
   end

   
   interface Memory iCache;
      method Action req(MemReq r);
         caches[0].req(r);
         totalCnts[0][0] <= totalCnts[0][0] + 1;
      endmethod
   
      method ActionValue#(Word) resp = caches[0].resp;
   endinterface   
   
   interface Memory dCache;
      method Action req(MemReq r);
         if (r.op == St) begin
            if (r.addr == 'h4000_0000) begin
                // Writing to STDOUT
                $write("%c", r.data[7:0]);
            end 
            else if (r.addr == 'h4000_0004) begin
                // Write integer to STDOUT
                $write("%0d", r.data);
            end 
            else if (r.addr == 'h4000_1000) begin
               // Exiting Simulation
               $display("Total Clock Cycles = %d\n", cycles);
                if (r.data == 0) begin
                    $display("PASSED");
                end 
                else begin
                    $display("FAILED %0d", r.data);
                end
               // $display("i-cache hitCnt = %d, missCnt = %d", totalCnts[0][1] - missCnts[0], missCnts[0]);
               // $display("d-cache hitCnt = %d, missCnt = %d", totalCnts[1][0] - missCnts[1], missCnts[1]);
                $finish;
            end
         end
         totalCnts[1][0] <= totalCnts[1][0] + 1;
         caches[1].req(r);
      endmethod
    
      method ActionValue#(Word) resp = caches[1].resp;
   endinterface   

endmodule
