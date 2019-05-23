import FIFO::*;
import SpecialFIFOs::*;

`ifdef MEM_LAT
typedef `MEM_LAT MemLat;
`else
typedef 1 MemLat;
`endif

typedef TSub#(MemLat, 1) NumFIFOs; // deduct 1 latency from bram


// (* synthesize *)
module mkMemory(Memory);
    BRAM_Configure cfg = defaultValue();
    cfg.loadFormat = tagged Hex "mem.vmh";
    BRAM1Port#(Bit#(14), Word) bram <- mkBRAM1Server(cfg);
    
    `ifdef MEM_LAT
    Vector#(NumFIFOs, FIFO#(Word)) latChannel <- replicateM(mkPipelineFIFO);
   
    rule doGetResp;
        let x <- bram.portA.response.get();
        latChannel[0].enq(x);
        // $display("bram resp at %t", $time);
    endrule
   
      
    for (Integer i = 0; i < valueOf(NumFIFOs) - 1 ; i=i+1) begin
        rule doConection;
            let v = latChannel[i].first;
            latChannel[i].deq;
            latChannel[i+1].enq(v);
        endrule
    end
    `endif
   

    method Action req(MemReq memReq);
        if (memReq.op == St) begin
            if (memReq.addr == 'h4000_0000) begin
                // Writing to STDOUT
                $write("%c", memReq.data[7:0]);
            end else if (memReq.addr == 'h4000_0004) begin
                // Write integer to STDOUT
                $write("%0d", memReq.data);
            end else if (memReq.addr == 'h4000_1000) begin
                // Exiting Simulation
                if (memReq.data == 0) begin
                    $display("PASSED");
                end else begin
                    $display("FAILED %0d", memReq.data);
                end
                $finish;
            end
        end
        // $display("bram req at %t", $time);
        bram.portA.request.put(BRAMRequest{
                write: memReq.op == St,
                responseOnWrite: False,
                address: truncate(memReq.addr >> 2),
                datain: memReq.data});
    endmethod
    method ActionValue#(Word) resp();
        `ifdef MEM_LAT
        let x = latChannel[valueOf(NumFIFOs)-1].first;
        latChannel[valueOf(NumFIFOs)-1].deq;
        `else
        let x <- bram.portA.response.get();
        `endif
        return x;
    endmethod
endmodule
