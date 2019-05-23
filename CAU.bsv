import Common::*;
import MemoryTypes::*;
import CacheTypes::*;
import SRAM6004::*;
import FIFO::*;
import SpecialFIFOs::*;

interface CAU#(numeric type logNumCacheLines);
    method Action req(MemReq r);
    method ActionValue#(CAUResp) resp();
    // updates the cache line, tag, and status at the given index
    method Action update(CacheIndex index, TaggedLine newline);
endinterface


// CAU Hit and Miss type: Load Hit, Store Hit and Miss
typedef enum{LdHit, StHit, Miss} HitMissType deriving (Bits, Eq, FShow);

typedef struct{
    HitMissType hitMiss;    // Hit Miss Type
    Word ldValue;           // Value Returned in case of Load Hit
    TaggedLine taggedLine;  // Value Returned in case we had a dirty capacity miss
    } CAUResp deriving(Bits, Eq, FShow);


// CAU Internal Status 
typedef enum {Ready, Busy} CAUStatus deriving(Eq,FShow,Bits); 

module mkCAU(CAU#(lgCacheLines)) provisos(
   Add#(a__, lgCacheLines, LogMaxNumCacheLines) // lgCacheLines <= 10;
   );
   
   function CacheIndex getIndex(Word byteAddress);
      return truncate(byteAddress>>6) & ((1<<fromInteger(valueOf(lgCacheLines)))-1);
   endfunction
      
   function CacheTag getTag(Word byteAddress);
      return truncateLSB(byteAddress) >> fromInteger(valueOf(lgCacheLines));
   endfunction

   function WordOffset getWordOffset(Word byteAddress);
      return truncate(byteAddress >> 2);
   endfunction

   
   Bool verbose = False;
    // Instantiate three SRAMs: one for data, one for tags, and one for statuses.
    SRAM#(lgCacheLines, Line) dataArray <- mkSRAM;
    SRAM#(lgCacheLines, Bit#(TSub#(26, lgCacheLines))) tagArray <- mkSRAM;
    SRAM#(lgCacheLines, CacheStatus) statusArray <- mkSRAM;
    
    // Instantiate register for holding the CAU status
    Reg#(CAUStatus) status <- mkReg(Ready);
    
    // Instantiate register for holding current CAU request
    // Reg#(MemReq) currReq <- mkRegU;
   FIFO#(MemReq) currReqQ <- mkLFIFO;

   method Action req(MemReq r);// if (status == Ready);
        let index = getIndex(r.addr);
        // initiate reads to tagArray, dataArray, and statusArray;
      tagArray.rdReq(truncate(index));
      dataArray.rdReq(truncate(index));
      statusArray.rdReq(truncate(index));
        
        // store request r in currReg
        // currReq <= r;
      currReqQ.enq(r);
        // change the status register
        // status <= Busy;
      if (verbose) $display("[%t]...%m req index = %h", $time, index, fshow(r));
    endmethod

    method ActionValue#(CAUResp) resp(); // implicit guard: arrays needs to have been asked something to respond
        // status <= Ready;
        // Wait for responses from the tagArray, statusArray, and dataArray SRAMs for earlier requests
       let currReq = currReqQ.first;
       currReqQ.deq;

   
        let tag <- tagArray.resp;
        CacheStatus cstatus <- statusArray.resp;
        Line line <- dataArray.resp;
   


        // Get currTag, idx,wordOffset from currReq.addr 
        let currTag = getTag(currReq.addr);
        let index = getIndex(currReq.addr);
        let wordOffset = getWordOffset(currReq.addr);
   
       if (verbose) $display("[%t]...%m Resp ", $time, fshow(currReq), " ", fshow(cstatus), " currTag (tag, line) = %h (%h, %h)", currTag, tag, line);

        // Do tag match
        if (truncate(currTag) == tag && cstatus != Invalid) begin // Hit
            // In case of a Ld hit, return the word;
            if (currReq.op == Ld) begin // Ld Hit
                return CAUResp{hitMiss: LdHit, ldValue: line[wordOffset], taggedLine:? };
            end
            else begin // Store hit
                // In case of St hit, update the word
                line[wordOffset] = currReq.data;
                dataArray.wrReq(truncate(index), line);
                // mark the line as dirty
                statusArray.wrReq(truncate(index), Dirty);
                return CAUResp{hitMiss: StHit, ldValue:?, taggedLine:?};
            end
        end 
        else begin // Miss ld or st
            // Return the current cache line at the requested index, along with
            // its status and tag.
            return CAUResp{hitMiss: Miss, ldValue:?, taggedLine:TaggedLine {line: line, status: cstatus, tag: zeroExtend(tag)}};
        end
    endmethod

   method Action update(CacheIndex index, TaggedLine line);// if (status != Busy); // To not loose a read request there
        // update the SRAM arrays at index
      if (verbose) $display("[%t]...%m cau update %h ", $time, index, fshow(line));
        tagArray.wrReq(truncate(index), truncate(line.tag));
        dataArray.wrReq(truncate(index), line.line);
        statusArray.wrReq(truncate(index), line.status);
    endmethod
endmodule
