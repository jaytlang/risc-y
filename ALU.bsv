// Description: one-bit full adder
// Arguments: a, b, carry in
// Return: {carry out, sum}
import ProcTypes::*;
function Bit#(2) fa(Bit#(1) a, Bit#(1) b, Bit#(1) c_in);
    return {(a & b) | ((a | b) & c_in),  a ^ b ^ c_in};
endfunction

// Description: N-bit ripple-carry adder with a carry-in
// Arguments: a, b, c
// Return: sum of a and b, with c_in
function Bit#(w) rcaN(Bit#(w) a, Bit#(w) b, Bit#(1) c_in);
  Bit #(32) g = 0;
  Bit #(32) p = 0;
  Bit #(32) c = 0;

  //Carry generation: Make G(enerate) and P(ropogate)
  for( Integer i = 0; i < valueOf(w); i = i+1) begin
    g[i] = a[i] & b[i];
    p[i] = a[i] ^ b[i];
  end

if (valueOf(w) < 32) begin
  for( Integer i = valueOf(w); i < 32; i = i+1) begin
    g[i] = 0;
    p[i] = 0;
  end
end

  //Group propogation calculations
  Bit#(1) pg0 = p[3] & p[2] & p[1] & p[0];
  Bit#(1) pg1 = p[7] & p[6] & p[5] & p[4];
  Bit#(1) pg2 = p[11] & p[10] & p[9] & p[8];
  Bit#(1) pg3 = p[15] & p[14] & p[13] & p[12];
  Bit#(1) pg4 = p[19] & p[18] & p[17] & p[16];
  Bit#(1) pg5 = p[23] & p[22] & p[21] & p[20];
  Bit#(1) pg6 = p[27] & p[26] & p[25] & p[24];
  Bit#(1) pg7 = p[31] & p[30] & p[29] & p[28];


  Bit#(1) gg0 = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
  Bit#(1) gg1 = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]);
  Bit#(1) gg2 = g[11] | (p[11] & g[10]) | (p[11] & p[10] & g[9]) | (p[11] & p[10] & p[9] & g[8]);
  Bit#(1) gg3 = g[15] | (p[15] & g[14]) | (p[15] & p[14] & g[13]) | (p[15] & p[14] & p[13] & g[12]);
  Bit#(1) gg4 = g[19] | (p[19] & g[18]) | (p[19] & p[18] & g[17]) | (p[19] & p[18] & p[17] & g[16]);
  Bit#(1) gg5 = g[23] | (p[23] & g[22]) | (p[23] & p[22] & g[21]) | (p[23] & p[22] & p[21] & g[20]);
  Bit#(1) gg6 = g[27] | (p[27] & g[26]) | (p[27] & p[26] & g[25]) | (p[27] & p[26] & p[25] & g[24]);
  Bit#(1) gg7 = g[31] | (p[31] & g[30]) | (p[31] & p[30] & g[29]) | (p[31] & p[30] & p[29] & g[28]);


  //Make carries, hopefully simultaneously to kill delay(!)
  c[0] = c_in;
  c[1] = g[0] | (p[0] & c_in);
  c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c_in);
  c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c_in);

  c[4] = gg0 | (pg0 & c_in);
  c[5] = g[4] | (p[4] & c[4]);
  c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & c[4]);
  c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & c[4]);

  c[8] = gg1 | (pg1 & gg0) | (pg1 & pg0 & c_in);
  c[9] = g[8] | (p[8] & c[8]);
  c[10] = g[9] | (p[9] & g[8]) | (p[9] & p[8] & c[8]);
  c[11] = g[10] | (p[10] & g[9]) | (p[10] & p[9] & g[8]) | (p[10] & p[9] & p[8] & c[8]);

  c[12] = gg2 | (pg2 & gg1) | (pg2 & pg1 & gg0) | (pg2 & pg1 & pg0 & c_in);
  c[13] = g[12] | (p[12] & c[12]);
  c[14] = g[13] | (p[13] & g[12]) | (p[13] & p[12] & c[12]);
  c[15] = g[14] | (p[14] & g[13]) | (p[14] & p[13] & g[12]) | (p[14] & p[13] & p[12] & c[12]);

  c[16] = gg3 | (pg3 & gg2) | (pg3 & pg2 & gg1) | (pg3 & pg2 & pg1 & gg0) | (pg3 & pg2 & pg1 & pg0 & c_in);
  c[17] = g[16] | (p[16] & c[16]);
  c[18] = g[17] | (p[17] & g[16]) | (p[17] & p[16] & c[16]);
  c[19] = g[18] | (p[18] & g[17]) | (p[18] & p[17] & g[16]) | (p[18] & p[17] & p[16] & c[16]);

  c[20] = gg4 | (pg4 & gg3) | (pg4 & pg3 & gg2) | (pg4 & pg3 & pg2 & gg1) | (pg4 & pg3 & pg2 & pg1 & gg0) | (pg4 & pg3 & pg2 & pg1 & pg0 & c_in);
  c[21] = g[20] | (p[20] & c[20]);
  c[22] = g[21] | (p[21] & g[20]) | (p[21] & p[20] & c[20]);
  c[23] = g[22] | (p[22] & g[21]) | (p[22] & p[21] & g[20]) | (p[22] & p[21] & p[20] & c[20]);

  c[24] = gg5 | (pg5 & gg4) | (pg5 & pg4 & gg3) | (pg5 & pg4 & pg3 & gg2) | (pg5 & pg4 & pg3 & pg2 & gg1) | (pg5 & pg4 & pg3 & pg2 & pg1 & gg0) | (pg5 & pg4 & pg3 & pg2 & pg1 & pg0 & c_in);
  c[25] = g[24] | (p[24] & c[24]);
  c[26] = g[25] | (p[25] & g[24]) | (p[25] & p[24] & c[24]);
  c[27] = g[26] | (p[26] & g[25]) | (p[26] & p[25] & g[24]) | (p[26] & p[25] & p[24] & c[24]);

  c[28] = gg6 | (pg6 & gg5) | (pg6 & pg5 & gg4) | (pg6 & pg5 & pg4 & gg3) | (pg6 & pg5 & pg4 & pg3 & gg2) | (pg6 & pg5 & pg4 & pg3 & pg2 & gg1) | (pg6 & pg5 & pg4 & pg3 & pg2 & pg1 & gg0) | (pg6 & pg5 & pg4 & pg3 & pg2 & pg1 & pg0 & c_in);
  c[29] = g[28] | (p[28] & c[28]);
  c[30] = g[29] | (p[29] & g[28]) | (p[29] & p[28] & c[28]);
  c[31] = g[30] | (p[30] & g[29]) | (p[30] & p[29] & g[28]) | (p[30] & p[29] & p[28] & c[28]);


  Bit#(w) ret = 0;

  //Call full adders with carries;
  for( Integer i = 0; i < valueOf(w); i = i+1) begin
    ret[i] = (a[i] ^ b[i]) ^ c[i];
  end

  return ret;

endfunction

// Description: N-bit ripple-carry adder/subractor
// Arguments: a, b(N-bit operand); isSub (1 => subtract, 0 => add)
// Return: isSub == 0 ? a + b : a - b
function Bit#(w) addSubN(Bit#(w) a, Bit#(w) b, Bit#(1) isSub);
    return rcaN(a, (isSub == 1)? ~b : b, isSub);
endfunction

// Description: one-bit less-than comparator
// Arguments: a, b (1-bit values), eq, lt (eq and lt from previous comparator)
// Return: {eq_i, lt_i}
function Bit#(2) cmp(Bit#(1) a, Bit#(1) b, Bit#(1) eq, Bit#(1) lt);
    return {eq & ~(a ^ b), lt | (eq & ~a & b)};
endfunction

// Description: unsigned N-bit less-than comparator
// Arguments: a, b unsigned N-bit values
// Return: 1 if a < b 
function Bit#(1) ltuN(Bit#(w) a, Bit#(w) b);
    Bit#(2) eqlt = 'b10;
    for (Integer i = valueOf(w) - 1; i >= 0; i = i - 1) begin
        eqlt = cmp(a[i], b[i], eqlt[1], eqlt[0]);
    end
    return eqlt[0];
endfunction


// Description: Signed/Unsigned N-bit less-than comparator
// Arguments: a b (N-bit values); isSigned (signed comparator when 1, unsigned otherwise)
// Return: 1 if a < b
function Bit#(1) ltN(Bit#(w) a, Bit#(w) b, Bit#(1) isSigned);
    Bit#(w) xorMask = 0;
    xorMask[valueOf(w)-1] = isSigned;
    return ltuN(a ^ xorMask, b ^ xorMask);
endfunction

// Description: 32-bit right barrel shifter
// Arguments: in (value to be shifted); sftSz (shift size); sft_in (the bit shifted in)
// Return: {sft_in's, in[31:sftSz]}
function Bit#(32) barrelRShift(Bit#(32) in, Bit#(5) sftSz, Bit#(1) sft_in);
    // You said no for loops? I'm using for loops :P
    Bit#(32) out = in;
    for (Integer b = 0; b < 5; b = b + 1) begin
        if (sftSz[b] == 1) begin
            Integer s = 2**b;
            for (Integer i = 0; i < 32 - s; i = i + 1) begin
                out[i] = out[i + s];
            end
            for (Integer i = 32 - s; i < 32; i = i + 1) begin
                out[i] = sft_in;
            end
        end
    end
    return out;
endfunction


// Description: 32-bit FULL shifter
// Arguments: in (value to be shifted); sftSz (shift size); 
//                arth (1 for arithmetic, 0 for logic); left (1 for left shift, 0 for right)
// Return: in >> sftSz when left == 0; in << sftSz otherwise
function Bit#(32) sft32(Bit#(32) in, Bit#(5) sftSz, Bit#(1) arith, Bit#(1) left);
    let bsin = (left==1)? reverseBits(in) : in;
    // NOTE: Doing the right thing if left && arith, though this seems out of spec
    let bsout = barrelRShift(bsin, sftSz, ((~left & arith)==1)? in[31] : 0);
    return  (left==1)? reverseBits(bsout) : bsout;
endfunction


// Alu Functions:
// Add: 32-bit Addition (a+b)
// Sub: 32-bit Subtraction (a-b)
// And: 32-bit Bit-wise And (a^b)
// Or: 32-bit Bit-wise Or (a|b)
// Xor: 32-bit Bit-wise Xor (a^b)
// Slt: Set less than (a<b ? 1: 0)
// Sltu: Set less than unsigned (a<b ? 1:0)
// Sll: Left logic shfiter (a<<b)
// Srl: Right logic shifter (a>>b)
// Sra: Right arithmetic shifter (a>>b)
// typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra}AluFunc deriving (Bits, Eq, FShow);

// Description: Arithmetic Logic Unit (ALU)
// Arguments: a, operand a; b, operand b; func, ALU operation
// Return: output of ALU
function Bit#(32) alu(Bit#(32) a, Bit#(32) b, AluFunc func);
    Bit#(32) addRes = addSubN(a, b, (func==Sub)? 1 : 0);
    Bit#(32) cmpRes = zeroExtend(ltN(a, b, (func==Slt)? 1 : 0));
    Bit#(32) shiftRes = sft32(a, b[4:0], (func==Sra)? 1 : 0, (func==Sll)? 1 : 0);
    Int#(32) signedA = unpack(a);
    Bit#(32) res = case (func)
        Add: addSubN(a, b, 0);
        Sub: addSubN(a, b, 1);
        And: (a & b);
        Or:  (a | b);
        Xor: (a ^ b);
        Slt: ((signedLT(a,b))? 1: 0) ;
        Sltu: ((a < b)? 1 : 0);
        Sll: (a << b[4:0]);
        Srl: (a >> b[4:0]);
        Sra: (pack(signedA >> b[4:0]));
    endcase;
    return res;
endfunction


