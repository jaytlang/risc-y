import FIFO::*;
import Common::*;
import ProcTypes::*;
import Decode::*;
import Execute::*;
import Scoreboard::*;
import ScheduleMonitor::*;
import Vector::*;
import BuildVector::*;
import RFile::*;
import BTB::*;

import Ehr::*;

`ifdef MEM_SUB
import MemoryTypes::*;
import MemorySystem::*;
`endif



typedef struct {
   Word pc;
   Word ppc;
   Bool epoch;
   } F2D deriving(Bits, Eq);

typedef struct {
   Word pc;
   Word ppc;
   Bool epoch;
   DecodedInst dInst; 
   Word rVal1; 
   Word rVal2;
   } D2E deriving(Bits, Eq);

interface ProcIfc;
    method Bit#(32) getPC;
endinterface

(* synthesize *)
module mkProcessor(ProcIfc);
    Ehr#(2, Word)  pc <- mkEhr(0);    
    RFile2R1W   rf <- mkBypassRFile2R1W;
   
   `ifdef MEM_SUB
   let memsys <- mkMemorySystem;
   Memory     iMem = memsys.iCache;  //  req/res memory
   Memory     dMem = memsys.dCache;  //  req/res memory
   `else
   Memory     iMem <- mkMemory;  //  req/res memory
   Memory     dMem <- mkMemory;  //  req/res memory
   `endif

//   ScheduleMonitor monitor <- mkScheduleMonitor(stdout, vec("fetch", "decode", "execute"));

    //Pipeline FIFOs
    FIFO#(F2D) f2d <- mkSizedFIFO(3);
    FIFO#(D2E) d2e <- mkSizedFIFO(3);
    FIFO#(ExecInst) e2m <- mkSizedFIFO(3);    

    Reg#(Bool)  loadWaitReg <- mkReg(False);
    Reg#(RIndx) dstLoad <- mkReg(0);

    Reg#(Word)  fallbackPc <- mkRegU();
    Reg#(Bool)  hazardReg <- mkReg(False);
    Reg#(Word)  fetchedInst <- mkRegU;
    Reg#(Bool)  mispredictionReg <- mkReg(False);
   
    Reg#(Word)  nextPc <- mkRegU;
    Ehr#(2,Bool)  epoch <- mkEhr(False);

    NAP#(5) brPrdct <- mkBTB;

    // Instantiation of Scoreboard. 
    // An extra slot than needed is allocated to allow concurrent insert and remove when sb has n-1 items
    // Scoreboard#(2)  sb <- mkScoreboard;
    Scoreboard#(3)  sb <- mkBypassingScoreboard;

    
    Reg#(Bit#(64)) cycles <- mkReg(0);
    rule doCycle;
        cycles <= cycles + 1;
        if ( cycles > 10000000 ) begin
            $display("FAILED: Your processor timed out");
            $finish;
        end
    endrule


    rule doFetch(!mispredictionReg);
        let ppc = brPrdct.predicted(pc[1]);
        iMem.req(MemReq{op: Ld, addr: pc[1], data: ?});
        pc[1] <= ppc;
        f2d.enq(F2D {pc: pc[1], ppc: ppc, epoch: epoch[1]});    
//	monitor.record("fetch", "F");
    endrule

    rule doDecode;
        Word inst;
        if (!hazardReg) begin 
            inst <- iMem.resp();
        end 
        else begin
            inst = fetchedInst;
        end

        let x = f2d.first;
        let epochD = x.epoch;
        if (epochD == epoch[1]) begin  // right-path instruction
	    //monitor.record("decode", "D");
            let dInst = decode(inst); // rs1, rs2 are Maybe types
            // check for data hazard
            let hazard = (sb.search1(dInst.src1) || sb.search2(dInst.src2));
            // if no hazard detected
            if (!hazard) begin
                let rVal1 = rf.rd1(fromMaybe(?, dInst.src1));
                let rVal2 = rf.rd2(fromMaybe(?, dInst.src2));
                sb.insert(dInst.dst); // for detecting future data hazards
                d2e.enq(D2E {pc: x.pc, ppc: x.ppc, epoch: x.epoch, 
                             dInst: dInst, rVal1: rVal1, rVal2: rVal2});
                f2d.deq;
                hazardReg <= False;
            end
            // if hazard detected
            else begin 
                fetchedInst <= inst; 
                hazardReg <= True;
            end
        end
        else begin // wrong-path instruction
	    //monitor.record("decode", "s");
            hazardReg <= False;
            f2d.deq;
        end
     endrule

    rule doExecute(!loadWaitReg && !mispredictionReg);

        let x = d2e.first;          
        let pcE = x.pc; let ppc = x.ppc; let epochE = x.epoch; 
        let rVal1 = x.rVal1; let rVal2 = x.rVal2; 
        let dInst = x.dInst;
        d2e.deq;

        if (epochE == epoch[1]) begin  // right-path instruction
	    //monitor.record("execute", "E");
            let eInst = execute(dInst, rVal1, rVal2, pcE);
            if (eInst.iType == Unsupported) begin
                $display("Reached unsupported instruction");
                $display("Total Clock Cycles = %d", cycles);
                $display("Dumping the state of the processor");
                $display("pc = 0x%x", x.pc);
                rf.displayRFileInSimulation;
                $display("Quitting simulation.");
                $finish;
            end

            let misprediction = (eInst.nextPc != ppc);
            nextPc <= eInst.nextPc;
	    fallbackPc <= pcE;
            mispredictionReg <= misprediction;


            if (eInst.iType == LOAD) begin
                dMem.req(MemReq{op: Ld, addr: eInst.addr, data: ?});
                dstLoad <= fromMaybe(?, eInst.dst);
                loadWaitReg <= True;
            end 
            else if (eInst.iType == STORE) begin
                if ( eInst.addr == 'h4000_1000)
                    $display("Total Clock Cycles = %d", cycles);
                dMem.req(MemReq{op: St, addr: eInst.addr, 
                                data: eInst.data});
                sb.remove;
            end
            else begin
                if(isValid(eInst.dst)) begin
                    rf.wr(fromMaybe(?, eInst.dst), eInst.data);
                end
                sb.remove;
            end
        end
        else begin // F to pay respects
	   //monitor.record("execute", "x");
           sb.remove;
        end
    endrule

    rule doLoadWait(loadWaitReg);
        let data <- dMem.resp();
        rf.wr(dstLoad, data);
        loadWaitReg <= False;
        sb.remove;//(tagged Valid dstLoad);
	//monitor.record("execute", "L");
    endrule

    rule doRedirection (!loadWaitReg && mispredictionReg) ; // add guard when necessary
        // redirect the pc
	brPrdct.update(fallbackPc, nextPc);
        pc[0] <= nextPc;
        epoch[0] <= !epoch[0];
        mispredictionReg <= False;
       
        // execute by dequeing wrong-path instruction at the same time
        d2e.deq;
        sb.remove;
	//monitor.record("execute", "R");

	let ppc = brPrdct.predicted(nextPc);
        iMem.req(MemReq{op: Ld, addr: pc[0], data: ?}); //trick to increase clock cycle
        f2d.enq(F2D {pc: pc[0], ppc: ppc, epoch: epoch[0]});    

    endrule
    
    method Bit#(32) getPC;
        return pc[0];
    endmethod

endmodule
