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

package ScheduleMonitor;

import Vector::*;

interface ScheduleMonitor;
    method Action record(String ruleName, Char char);
endinterface

module mkScheduleMonitor#(File file, Vector#(n, String) ruleNames)(ScheduleMonitor);
    function Bit#(8) charToBits(Char c);
        return fromInteger(charToInteger(c));
    endfunction

    Reg#(Bool) init <- mkReg(False);
    Vector#(n, Reg#(Bit#(8))) schedWires <- replicateM(mkDWire(charToBits("_")));

    rule printSchedule;
        if (!init) begin
            // print legend too
            for (Integer i = 0 ; i < valueOf(n) ; i = i+1) begin
                for (Integer j = 0 ; j < i ; j = j+1) begin
                    $fwrite(file, " ");
                end
                $fdisplay(file, ruleNames[i]);
            end
            init <= True;
        end
        for (Integer i = 0 ; i < valueOf(n) ; i = i+1) begin
            $fwrite(file, "%c", schedWires[i]);
        end
        $fdisplay(file, "");
    endrule

    method Action record(String ruleName, Char char);
        if (findElem(ruleName, ruleNames) matches tagged Valid .index) begin
            schedWires[index] <= charToBits(char);
        end else begin
            $fdisplay(stderr, "ERROR: schedule monitor can't find rule named: %s", ruleName);
        end
    endmethod
endmodule

endpackage
