import RegFile::*;
import ProcTypes::*;

// next address predictor 
interface NAP#(numeric type logn);
    method Word predicted(Word pc);
    method Action update(Word pc, Word nextPC);
endinterface

module mkBTB(NAP#(logn));
    RegFile#(RIndx, Word) tagArr <- mkRegFileFull;
    RegFile#(RIndx, Word) targetArr <- mkRegFileFull;

    method Word predicted(Word pc);
	RIndx index = truncate(pc >> 2);
	let tag = tagArr.sub(index);
	let target = targetArr.sub(index);
	if (tag == pc) return target; else return (pc+4);

    endmethod

	
    method Action update(Word pc, Word nextPc);	
	RIndx index = truncate(pc >> 2);
	tagArr.upd(index, pc);
	targetArr.upd(index, nextPc);
	
    endmethod

	
endmodule
