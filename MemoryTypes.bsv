// Memory
import Common::*;
//`ifdef PROC_FINAL_PROJ
import ProcTypes::*;
//`endif

typedef enum { Ld, St } MemOp deriving (Bits, Eq, FShow);

typedef struct {
    MemOp op;
    Word addr;
    Word data;
} MemReq deriving (Bits, Eq, FShow);

interface MemClient;
    method ActionValue#(MemReq) req;
    method Action resp(Word word);
endinterface


interface Memory;
    method Action req(MemReq memReq);
    method ActionValue#(Word) resp;
    method Tuple2#(Bit#(32), Bit#(32)) peekCnt; // peek hit and miss counts
    method Bit#(32) getHitCount;
    method Bit#(32) getMissCount;
endinterface





