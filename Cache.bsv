import FIFOF::*;         // FIFO library distributed as part of the Bluespec compiler
import SpecialFIFOs::*;
import CacheTypes::*;
import MemoryTypes::*;
import CAU::*;
import Common::*;

// interface Cache#(numeric type logNumLines);
//    // methods for the processor to interact with the cache
//    method Action req(MemReq req);
//    method ActionValue#(Word) resp();
//    // methods for the cache to interact with DRAM
//    method ActionValue#(LineReq) lineReq;
//    method Action lineResp(Line r);
// endinterface

// ReqStatus is used to keep track of the state of the current request
typedef enum {
   Ready,              // The cache is ready for a new request
   WaitCAUResp,        // Waiting for the CAUs to respond
   SendReq,            // The cache needs to send a request to read a line from DRAM
   WaitDramResp        // The cache is waiting for the DRAM to respond with the read data
   } ReqStatus deriving(Bits, Eq, FShow);
// ReqStatus state transitions:
//     Current State       Next State
//     Ready            -> WaitCAUResp
//     WaitCAUResp      -> (if miss and evicting dirty line) SendReq
//                         (if miss and not evicting dirty line) WaitDramResp
//                         (if hit) Ready
//     SendReq          -> WaitDramResp
//     WaitDramResp     -> Ready

// Direct-mapped cache with write-back and write-allocate policies
// This is the same as the mkBlockingCache from lecture
module mkCache(Cache#(lgCacheLines)) provisos(
   Add#(a__, lgCacheLines, LogMaxNumCacheLines)
   );
   
   function CacheIndex getIndex(Word byteAddress);
      return truncate(byteAddress>>6) & ((1<<fromInteger(valueOf(lgCacheLines)))-1);
   endfunction
      
   function CacheTag getTag(Word byteAddress) ;
      return truncateLSB(byteAddress) >> fromInteger(valueOf(lgCacheLines));
   endfunction

   function WordOffset getWordOffset(Word byteAddress);
      return truncate(byteAddress >> 2);
   endfunction

   
   Bool verbose = False;
   // The CAU module contains one way of data, tags, and status bits
   CAU #(lgCacheLines) cau <- mkCAU();

   // Registers for holding the current state of the cache and how far along
   // it is in processing a request.
   // Reg#(MemReq)    currReq   <- mkRegU;
   // Reg#(MemReq)    currReqReg[2]   <- mkCRegU(2);
   // Reg#(MemReq)    currReq = currReqReg[1];
   FIFOF#(MemReq) currReqQ <- mkLFIFOF;
   Reg#(ReqStatus) state     <- mkReg(WaitCAUResp);

   // Instantiate FIFOs for some of the interface methods
   // mkSizedFIFO(1) creates a FIFO module with only one element. This module
   // is part of the FIFO package provided with the Bluespec compiler. The
   // FIFO#(t) interface has enq, first, and deq methods.
   FIFOF#(Word)     hitQ      <- mkBypassFIFOF;
   FIFOF#(LineReq)  lineReqQ  <- mkSizedFIFOF(1);
   FIFOF#(Line)     lineRespQ <- mkSizedFIFOF(1);
   
   Reg#(Bit#(32)) hitCount <- mkReg(0);
   Reg#(Bit#(32)) missCount <- mkReg(0);
   
   // There is one rule per state except for the ready state. During the ready
   // state, the cache is waiting for the processor to send a memory request
   // through the req interface method.
   rule waitCAUResponse (state == WaitCAUResp); // This guard is actually not required. Why?
      // Get the response from the CAU. This response is a tagged
      // union of type CAUResp (see CAU.bsv).
      let x <- cau.resp;
      let currReq = currReqQ.first;
      if (verbose) $display("[%t]...%m WaitCAUResp ", $time, fshow(currReq), fshow(x));
      case (x.hitMiss)
         LdHit: begin
                   hitCount <= hitCount + 1;
                   Word v = x.ldValue;
                   hitQ.enq(v);
                   // state <= Ready;
                   currReqQ.deq;
                end
         StHit: begin
                   hitCount <= hitCount + 1;
                   // state <= Ready;
                   currReqQ.deq;
                end
         Miss: begin
                  missCount <= missCount + 1;
                  let oldTaggedLine = x.taggedLine;
                  if (oldTaggedLine.status == Dirty) begin
                     // Write the old dirty data back to DRAM.
                     // let evictLineAddr = {oldTaggedLine.tag, getIndex(currReq.addr)};
                     LineAddr evictLineAddr = (oldTaggedLine.tag << fromInteger(valueOf(lgCacheLines))) | zeroExtend(getIndex(currReq.addr));
                     if (verbose) $display("Dirty Miss!!!: oldtag = %h, index = %h, evictLineAddr = %h, lgCLs = %d", oldTaggedLine.tag, getIndex(currReq.addr), evictLineAddr, valueOf(lgCacheLines));
                     lineReqQ.enq(LineReq{op: St, lineAddr: evictLineAddr, data: oldTaggedLine.line});
                     // Go to the SendReq state because we still need to send a
                     // load to DRAM to get the data for the miss.
                     state <= SendReq;
                  end 
                  else begin
                     // No writeback required, we can directly load the new line.
                     // let newLineAddr = {getTag(currReq.addr), getIndex(currReq.addr)};
                     LineAddr newLineAddr = truncateLSB(currReq.addr);//(getTag(currReq.addr) << fromInteger(valueOf(lgCacheLines))) | zeroExtend(getIndex(currReq.addr));
                     lineReqQ.enq(LineReq{ op: Ld, lineAddr: newLineAddr, data: ?});
                     // We have already send to load request to DRAM for the new
                     // line, so we go to the WaitDramResp state to wait for the
                     // response.
                     state <= WaitDramResp;
                  end
               end
      endcase
   endrule

   rule sendNewLineReq(state == SendReq);
      // Send request for the new line with the corresponding line address
      let currReq = currReqQ.first;
      // let lineAddr = {getTag(currReq.addr), getIndex(currReq.addr)};
      LineAddr lineAddr = truncateLSB(currReq.addr);//(getTag(currReq.addr) << fromInteger(valueOf(lgCacheLines))) | zeroExtend(getIndex(currReq.addr));
      lineReqQ.enq(LineReq{ op: Ld, lineAddr: lineAddr, data: ?});
      // Wait for the response from DRAM
      if (verbose) $display("[%t]...%m SendNewLineReq to addr %h ", $time, lineAddr, fshow(currReq));
      state <= WaitDramResp;
   endrule

   rule waitDramResp(state == WaitDramResp);
      // The cache is waiting for the read response from DRAM
      // Get the response from lineRespQ
      let line = lineRespQ.first();
      lineRespQ.deq();
      let currReq = currReqQ.first;
      currReqQ.deq;
      // reconstruct the index tag and offset from the current request's address
      let index = getIndex(currReq.addr);
      let tag = getTag(currReq.addr);
      let wordOffset = getWordOffset(currReq.addr);
      if (currReq.op == Ld) begin
         // For a load, respond with the correct word from the line ...
         hitQ.enq(line[wordOffset]);
         // ... and insert the line into the CAU as clean
         cau.update(index, TaggedLine{line: line, status: Clean, tag: tag});
      end 
      else begin
         // For a store, update the line from the DRAM ...
         line[wordOffset] = currReq.data;
         // ... and insert the line into the CAU as dirty
         cau.update(index, TaggedLine{line: line, status: Dirty, tag: tag});
      end
      // The current request has been handled, and the cache is ready to
      // handle a new request.
      // state <= Ready;
      state <= WaitCAUResp;
      if (verbose) $display("[%t]...%m WaitDramResp ", $time, fshow(currReq), " ", fshow(line) );
   endrule

   method Action req(MemReq r);// if (state == Ready && hitQ.notFull);
      // Store the current request in a register for later
      // currReq <= r;
      // currReqReg[1] <= r;
      if (verbose) $display("[%t]...%m req ", $time, fshow(r));
      currReqQ.enq(r);
      // Send the memory request to the CAU
      cau.req(r);
      // Wait for the response from the CAU
      // state <= WaitCAUResp;
   endmethod

   // These three methods are just interfacing with their corresponding FIFO
   method ActionValue#(Word) resp;
      if (verbose) $display("[%t]...%m resp = %h", $time, hitQ.first);
      hitQ.deq();
      return hitQ.first;
   endmethod

   method ActionValue#(LineReq) lineReq();
      lineReqQ.deq();
      return lineReqQ.first();
   endmethod

   method Action lineResp (Line r);
      lineRespQ.enq(r);
   endmethod
   
   method Bit#(32) getHitCount = hitCount._read;
   method Bit#(32) getMissCount = missCount._read;
endmodule

