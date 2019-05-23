import Common::*;
import MemoryTypes::*;
import CacheTypes::*;
import RegFile::*;

interface DRAM;
    method Action req(LineReq req);
    method ActionValue#(Line) resp;
endinterface

// This typedef 
typedef Bit#(24) DRAMLineAddr;

module mkSimDRAM#(Integer latency)(DRAM);
    Reg#(Bit#(8)) latency_counter <- mkReg(0);
    Reg#(Maybe#(Line)) delayed_resp <- mkReg(Invalid);
    `ifdef SIM
    RegFile#(DRAMLineAddr, Line) mem <- mkRegFileFullLoad("zerosDRAM.vmh");
    // what is the initialization 
    `else
    RegFile#(DRAMLineAddr, Line) mem <- mkRegFileFullLoad("mem.vmh");
    // what is the initialization 
    `endif

    rule decLatencyCounter(latency_counter != 0);
        latency_counter <= latency_counter - 1;
    endrule

    method Action req(LineReq r) if (latency_counter == 0 && !isValid(delayed_resp));
        if (r.op == Ld) begin
            // load
            Line resp = mem.sub(truncate(r.lineAddr));
            delayed_resp <= Valid(resp);
            latency_counter <= fromInteger(latency);
        end else begin
            // store
            mem.upd(truncate(r.lineAddr), r.data);
        end
    endmethod

    method ActionValue#(Line) resp if (latency_counter == 0 && isValid(delayed_resp));
        delayed_resp <= Invalid;
        return fromMaybe(?, delayed_resp);
    endmethod
endmodule
