import FIFO::*;
import FIFOF::*;
import SpecialFIFOs::*;
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
import RWire::*;

import Ehr::*;
`define MEM_SUB

`ifdef MEM_SUB
import MemoryTypes::*;
import MemorySystem::*;
`endif

typedef struct {
   ExecInst exec;
   Bool valid;
   } E2M deriving(Bits, Eq);


typedef struct {
   Word pc;
   Word ppc;
   Bool epoch;
   } F2D deriving(Bits, Eq);


typedef struct { //breaking up the decode stage
   Word pc;
   Word ppc;
   DecodedInst dInst;
   Word rVal1;
   Word rVal2;
   Bool epoch;
   } D2H deriving(Bits, Eq);

typedef struct {
   Word pc;
   Word ppc;
   Bool epoch;
   DecodedInst dInst; 
   Word rVal1; 
   Word rVal2;
   } H2E deriving(Bits, Eq);

typedef struct {
   RIndx dst;
   Word data;
   } L2H deriving(Bits, Eq);

typedef struct {
   Maybe#(RIndx) dst;
   Word data;
   } E2H deriving(Bits, Eq);

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

   ScheduleMonitor monitor <- mkScheduleMonitor(stdout, vec("fetch", "decode", "hazard",  "execute", "load", "writeback"));

    //Pipeline FIFOs
    FIFO#(F2D) f2d <- mkSizedFIFO(2);
    FIFO#(D2H) d2h <- mkSizedFIFO(2);
    FIFO#(H2E) h2e <- mkSizedFIFO(2);

    FIFO#(E2M) e2m <- mkFIFO;    
    FIFO#(E2M) l2w <- mkFIFO;

    RWire#(E2H) e2hpass <- mkRWire();
    RWire#(Bool) exechazard <- mkRWire();
    RWire#(L2H) l2hpass <- mkRWire();

    Reg#(Word)  fallbackPc <- mkRegU();
    Reg#(Bool)  hazardReg <- mkReg(False);
    Reg#(DecodedInst)  fetcheddInst <- mkRegU;
    Reg#(Bool)  mispredictionReg <- mkReg(False);
   
    Reg#(Word)  nextPc <- mkRegU;
    Ehr#(2,Bool)  epoch <- mkEhr(False);

    NAP#(5) brPrdct <- mkBTB;

    // Instantiation of Scoreboard. 
    // An extra slot than needed is allocated to allow concurrent insert and remove when sb has n-1 items
    // Scoreboard#(2)  sb <- mkScoreboard;
    Scoreboard#(4)  sb <- mkBypassingScoreboard;

    
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
	monitor.record("fetch", "F");
    endrule


    rule doDecode; // this stage is really stupid and just does the decode
        let x = f2d.first; f2d.deq;
	let epochD = x.epoch;
	let inst <- iMem.resp();
	
	let dInst = decode(inst);	
	let rVal1 = rf.rd1(fromMaybe(?, dInst.src1));
	let rVal2 = rf.rd2(fromMaybe(?, dInst.src2));
	d2h.enq(D2H{pc: x.pc, ppc: x.ppc, dInst: dInst, rVal1: rVal1, rVal2: rVal2, epoch: epochD});
	monitor.record("decode", "D");

    endrule

    rule doHazard;
        let x = d2h.first;
	DecodedInst dInst;	

	if (!hazardReg) begin
	    dInst = x.dInst;
	end
	else begin
	    dInst = fetcheddInst;
	end

        let epochD = x.epoch;
        if (epochD == epoch[1]) begin  // right-path instruction
            // try instantiating values first then check for data hazard
            let hazard1 = sb.search1(dInst.src1);
	    let hazard2 = sb.search2(dInst.src2);
	    
	    let rVal1 = x.rVal1; let rVal2 = x.rVal2;    

	    let fromexecm = e2hpass.wget;//hopefully this doesn't conflict
	    let fromexec = fromMaybe(?, fromexecm);//this is an execinst
	    let fromloadm = l2hpass.wget;
	    let fromload = fromMaybe(?, fromloadm);
	    // if there's individual hazards remedy, then proceed with master plan

	    if (hazard1 && isValid(fromexecm) && (fromMaybe(?, dInst.src1) == fromMaybe(?, fromexec.dst))) begin
			hazard1 = !hazard1;
			rVal1 = fromexec.data;
    end
	    else if (hazard1 && isValid(fromloadm) && fromMaybe(?, dInst.src1) == fromload.dst) begin
			hazard1 = !hazard1;
			rVal1 = fromload.data;
	end

	    if (hazard2 && isValid(fromexecm) && fromMaybe(?, dInst.src2) == fromMaybe(?, fromexec.dst)) begin
			hazard2 = !hazard2;
			rVal2 = fromexec.data;
	    end
	    else if (hazard2 && isValid(fromloadm) && fromMaybe(?, dInst.src2) == fromload.dst) begin
			    hazard2 = !hazard2;
			    rVal2 = fromload.data;
	    end

	    if (fromMaybe(False, exechazard.wget) && isValid(fromexecm)) begin
		    if (fromMaybe(?, dInst.src1) == fromMaybe(?, fromexec.dst)) begin
			    hazard1 = True;
		    end
		    if (fromMaybe(?, dInst.src2) == fromMaybe(?, fromexec.dst)) begin
			    hazard2 = True;
		    end
	    end


            let hazard = (hazard1 || hazard2);
            if (!hazard) begin
	    	monitor.record("hazard", "M");
                sb.insert(dInst.dst); // for detecting future data hazards
                h2e.enq(H2E {pc: x.pc, ppc: x.ppc, epoch: x.epoch, 
                             dInst: dInst, rVal1: rVal1, rVal2: rVal2});
                d2h.deq;
                hazardReg <= False;
            end

            // if hazard detected
            else begin 
                fetcheddInst <= dInst; 
		monitor.record("hazard", "H");
                hazardReg <= True;
            end
        end
        else begin // wrong-path instruction
	    monitor.record("hazard", "s");
            hazardReg <= False;
            d2h.deq;
        end
     endrule

    rule doExecute(!mispredictionReg);
	monitor.record("execute", "E");
        let x = h2e.first;          
        let pcE = x.pc; let ppc = x.ppc; let epochE = x.epoch; 
        let rVal1 = x.rVal1; let rVal2 = x.rVal2; 
        let dInst = x.dInst;
        h2e.deq;

            let eInst = execute(dInst, rVal1, rVal2, pcE);
            if (eInst.iType == Unsupported && epochE == epoch[1]) begin
                $display("Reached unsupported instruction");
                $display("Dumping the state of the processor");
                $display("pc = 0x%x", x.pc);
                rf.displayRFileInSimulation;
                $display("Quitting simulation.");
                $finish;
            end

        if (epochE == epoch[1]) begin  // right-path instruction
            let misprediction = (eInst.nextPc != ppc);
            nextPc <= eInst.nextPc;
	    fallbackPc <= pcE;
            mispredictionReg <= misprediction;

	    if (eInst.iType == LOAD) begin
		    exechazard.wset(True);
	    end
	    else begin
		    exechazard.wset(False);
	    end

	    if (isValid(eInst.dst) && eInst.iType != STORE) begin
		    e2hpass.wset(E2H{dst: eInst.dst, data: eInst.data});
	    end
        end
	
	e2m.enq(E2M{exec: eInst, valid: (epochE == epoch[1])});	

    endrule

    rule doLoadWait;
	let y = e2m.first;
	let x = y.exec;
	let valid = y.valid;
	monitor.record("load", "L");
        e2m.deq;	

	if (valid) begin
	    if (x.iType == LOAD) begin	
                dMem.req(MemReq{op: Ld, addr: x.addr, data: ?});
	    end
	    else if (x.iType == STORE) begin
		dMem.req(MemReq{op: St, addr: x.addr, data: x.data}); end
	    else if (isValid(x.dst) && x.iType != LOAD) begin
		l2hpass.wset(L2H{dst: fromMaybe(?, x.dst), data: x.data});
	    end
	end

	l2w.enq(E2M{exec: x, valid: valid});
	
    endrule

    rule doWriteBack;
	monitor.record("writeback", "W");
	let y = l2w.first; l2w.deq;
	let valid = y.valid;
	let x = y.exec;

	if (valid) begin

		if (x.iType == LOAD) begin //we have a load
			let data <- dMem.resp;
			let dest = fromMaybe(?, x.dst);
			rf.wr(dest, data);
		end
		else if (isValid(x.dst)) begin
			rf.wr(fromMaybe(?, x.dst), x.data);
		end
	end
	sb.remove;

    endrule
    rule doRedirection (mispredictionReg) ; // add guard when necessary
        // redirect the pc
        mispredictionReg <= False;
	brPrdct.update(fallbackPc, nextPc);
        pc[0] <= nextPc;
        epoch[0] <= !epoch[0];
         
        // execute by dequeing wrong-path instruction outta decode
	// h2e.deq;
        // sb.remove;
	monitor.record("execute", "R");

        let ppc = brPrdct.predicted(nextPc+4);
        iMem.req(MemReq{op: Ld, addr: pc[0], data: ?}); //trick to increase clock cycle
        f2d.enq(F2D {pc: pc[0], ppc: ppc, epoch: epoch[0]});    

    endrule
    
    method Bit#(32) getPC;
        return pc[0];
    endmethod

endmodule
