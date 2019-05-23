// Copyright (c) 2016-2018 Massachusetts Institute of Technology

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Vector::*;

interface Scoreboard#(numeric type size);
    method Action insert(Maybe#(Bit#(5)) dst);
    method Action remove;
    method Bool search1(Maybe#(Bit#(5)) src1);
    method Bool search2(Maybe#(Bit#(5)) src2);
endinterface

// search < insert
// search < remove
// insert CF remove
module mkScoreboard(Scoreboard#(size));
    function Bool isFound(Maybe#(Bit#(5)) x, Maybe#(Bit#(5)) y);
        return isValid(x) && isValid(y) && x == y && fromMaybe(0, x)!=0;
    endfunction

    SearchFIFO#(size, Maybe#(Bit#(5)), Maybe#(Bit#(5))) f <- mkSearchFIFO(isFound);

    method insert = f.enq;
    method remove = f.deq;
    method search1 = f.search;
    method search2 = f.search;
endmodule

// scoreboard for bypassing
// search < insert
// search > remove
// insert CF remove
module mkBypassingScoreboard(Scoreboard#(size));
    function Bool isFound(Maybe#(Bit#(5)) x, Maybe#(Bit#(5)) y);
        return isValid(x) && isValid(y) && x == y && fromMaybe(0, x)!=0;
    endfunction

    SearchFIFO#(size, Maybe#(Bit#(5)), Maybe#(Bit#(5))) f <- mkPipelineSearchFIFO(isFound);

    method insert = f.enq;
    method remove = f.deq;
    method search1 = f.search;
    method search2 = f.search;
endmodule

// SearchFIFO used by Scoreboard

interface SearchFIFO#(numeric type size, type dataType, type searchType);
    method Action enq(dataType x);
    method Action deq;
    method dataType first;
    method Action clear;
    method Bool notEmpty;
    method Bool notFull;
    method Bool search(searchType x);
endinterface

// {search, notEmpty, notFull} < {enq, deq} < clear
// first < deq
module mkSearchFIFO#(function Bool isMatch(searchType s, dataType d))(SearchFIFO#(size, dataType, searchType)) provisos (Bits#(dataType, dataSize));
    // use valid bits to make search logic smaller
    Vector#(size, Reg#(Maybe#(dataType))) data <- replicateM(mkReg(tagged Invalid));
    Reg#(Bit#(TLog#(size))) enqP <- mkReg(0);
    Reg#(Bit#(TLog#(size))) deqP <- mkReg(0);
    Reg#(Bool) full <- mkReg(False);
    Reg#(Bool) empty <- mkReg(True);
    // EHRs to avoid conflicts between enq and deq
    Array#(Reg#(Bool)) deqReq <- mkCReg(3, False);
    Array#(Reg#(Maybe#(dataType))) enqReq <- mkCReg(3, tagged Invalid);

    // Canonicalize rule to handle enq and deq.
    // These attributes are statically checked by the compiler.
    (* no_implicit_conditions *)    // CAN_FIRE == guard (True)
    rule canonicalize;
        Bool enqueued = False;
        let nextEnqP = enqP;
        Bool dequeued = False;
        let nextDeqP = deqP;

        // enqueue logic
        if (enqReq[2] matches tagged Valid .enqVal) begin
            enqueued = True;
            nextEnqP = (enqP == fromInteger(valueOf(size) - 1)) ? 0 : enqP + 1;
        end

        // dequeue logic
        if (deqReq[2] == True) begin
            dequeued = True;
            nextDeqP = (deqP == fromInteger(valueOf(size) - 1)) ? 0 : deqP + 1;
        end

        // update data
        for (Integer i = 0 ; i < valueOf(size) ; i = i+1) begin
            Bool update = False;
            Maybe#(dataType) newValue = tagged Invalid;
            if (fromInteger(i) == enqP && isValid(enqReq[2])) begin
                update = True;
                newValue = enqReq[2];
            end else if (fromInteger(i) == deqP && deqReq[2]) begin
                update = True;
                newValue = tagged Invalid;
            end
            // should perform at most two writes, but avoids false conflicts
            if (update) begin
                data[i] <= newValue;
            end
        end

        // update empty and full if an element was enqueued or dequeued
        if (enqueued || dequeued) begin
            full <= (nextEnqP == nextDeqP) ? enqueued : False;
            empty <= (nextEnqP == nextDeqP) ? dequeued : False;
            enqP <= nextEnqP;
            deqP <= nextDeqP;
        end

        // clear request EHRs
        enqReq[2] <= tagged Invalid;
        deqReq[2] <= False;
    endrule

    method Action enq(dataType x) if (!full && !isValid(enqReq[0]));
        enqReq[0] <= tagged Valid x;
    endmethod
    method Action deq if (!empty && !deqReq[0]);
        deqReq[0] <= True;
    endmethod
    method dataType first if (!empty && !deqReq[0]);
        return fromMaybe(?, data[deqP]);
    endmethod
    method Action clear;
        writeVReg(data, replicate(tagged Invalid));
        enqP <= 0;
        deqP <= 0;
        full <= False;
        empty <= True;
        // clear any pending enq or deq
        enqReq[1] <= tagged Invalid;
        deqReq[1] <= False;
    endmethod

    method Bool notEmpty if (!isValid(enqReq[0]) && !deqReq[0]);
        return !empty;
    endmethod
    method Bool notFull if (!isValid(enqReq[0]) && !deqReq[0]);
        return !full;
    endmethod

    // different search implementations
    // search < {enq, deq}
    method Bool search(searchType x) if (!isValid(enqReq[0]) && !deqReq[0]);
        // helper function for isMatch when dataType has valid bits
        function Bool maybeIsMatch(searchType s, Maybe#(dataType) md);
            return md matches tagged Valid. d ? isMatch(s, d) : False;
        endfunction
        return any(id, map(compose(maybeIsMatch(x), readReg), data));
    endmethod
endmodule

// {notEmpty, notFull} < deq < search < enq < clear
// first < deq
module mkPipelineSearchFIFO#(function Bool isMatch(searchType s, dataType d))(SearchFIFO#(size, dataType, searchType)) provisos (Bits#(dataType, dataSize));
    // use valid bits to make search logic smaller
    Vector#(size, Reg#(Maybe#(dataType))) data <- replicateM(mkReg(tagged Invalid));
    Reg#(Bit#(TLog#(size))) enqP <- mkReg(0);
    Reg#(Bit#(TLog#(size))) deqP <- mkReg(0);
    Reg#(Bool) full <- mkReg(False);
    Reg#(Bool) empty <- mkReg(True);
    // EHRs to avoid conflicts between enq and deq
    Array#(Reg#(Bool)) deqReq <- mkCReg(3, False);
    Array#(Reg#(Maybe#(dataType))) enqReq <- mkCReg(3, tagged Invalid);

    // Canonicalize rule to handle enq and deq.
    // These attributes are statically checked by the compiler.
    // (* fire_when_enabled *)         // WILL_FIRE == CAN_FIRE // XXX: Not used due to clear conflict
    (* no_implicit_conditions *)    // CAN_FIRE == guard (True)
    rule canonicalize;
        Bool enqueued = False;
        let nextEnqP = enqP;
        Bool dequeued = False;
        let nextDeqP = deqP;

        // enqueue logic
        if (enqReq[2] matches tagged Valid .enqVal) begin
            enqueued = True;
            nextEnqP = (enqP == fromInteger(valueOf(size) - 1)) ? 0 : enqP + 1;
            // perform state updates
            // data[enqP] <= tagged Valid enqVal;
            // enqP <= nextEnqP;
        end

        // dequeue logic
        if (deqReq[2] == True) begin
            dequeued = True;
            nextDeqP = (deqP == fromInteger(valueOf(size) - 1)) ? 0 : deqP + 1;
            // perform state updates
            // data[deqP] <= tagged Invalid;
            // deqP <= nextDeqP;
        end

        // update data
        // this is done in this way to avoid a false conflict detected by the
        // compiler (enqReq[2] is valid, deqReq[2] is true, and enqP == deqP)
        for (Integer i = 0 ; i < valueOf(size) ; i = i+1) begin
            Bool update = False;
            Maybe#(dataType) newValue = tagged Invalid;
            if (fromInteger(i) == enqP && isValid(enqReq[2])) begin
                update = True;
                newValue = enqReq[2];
            end else if (fromInteger(i) == deqP && deqReq[2]) begin
                update = True;
                newValue = tagged Invalid;
            end
            // should perform at most two writes, but avoids false conflicts
            if (update) begin
                data[i] <= newValue;
            end
        end

        // update empty and full if an element was enqueued or dequeued
        if (enqueued || dequeued) begin
            full <= (nextEnqP == nextDeqP) ? enqueued : False;
            empty <= (nextEnqP == nextDeqP) ? dequeued : False;
            enqP <= nextEnqP;
            deqP <= nextDeqP;
        end

        // clear request EHRs
        enqReq[2] <= tagged Invalid;
        deqReq[2] <= False;
    endrule

    method Action enq(dataType x) if (!full && !isValid(enqReq[0]));
        enqReq[0] <= tagged Valid x;
    endmethod
    method Action deq if (!empty && !deqReq[0]);
        deqReq[0] <= True;
    endmethod
    method dataType first if (!empty && !deqReq[0]);
        return fromMaybe(?, data[deqP]);
    endmethod
    method Action clear;
        writeVReg(data, replicate(tagged Invalid));
        enqP <= 0;
        deqP <= 0;
        full <= False;
        empty <= True;
        // clear any pending enq or deq
        enqReq[1] <= tagged Invalid;
        deqReq[1] <= False;
    endmethod

    method Bool notEmpty if (!isValid(enqReq[0]));
        // old implementation:
        // return !empty;

        // TODO: make this more efficient
        // compute dataPostDeq by considering deqReq[1]
        Vector#(size, Maybe#(dataType)) dataPostDeq = readVReg(data);
        if (deqReq[1]) begin
            dataPostDeq[deqP] = tagged Invalid;
        end
        return any(isValid, dataPostDeq);
    endmethod
    method Bool notFull if (!isValid(enqReq[0]) && !deqReq[0]);
        return !full;
    endmethod

    // Alternate search implementation with the scheulde:
    //   deq < search < enq
    method Bool search(searchType x) if (!isValid(enqReq[0]));
        // compute dataPostDeq by considering deqReq[1]
        Vector#(size, Maybe#(dataType)) dataPostDeq = readVReg(data);
        if (deqReq[1]) begin
            dataPostDeq[deqP] = tagged Invalid;
        end
        // helper function for isMatch when dataType has valid bits
        function Bool maybeIsMatch(searchType s, Maybe#(dataType) md);
            return md matches tagged Valid. d ? isMatch(s, d) : False;
        endfunction
        return any(id, map(maybeIsMatch(x), dataPostDeq));
    endmethod
endmodule

