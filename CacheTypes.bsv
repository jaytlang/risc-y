import Vector::*;   // Vector library distributed as part of the Bluespec compiler
import Common::*;
import MemoryTypes::*;
// Types used in the Cache
////////////////////////////////////////

//// Cache Sizes

typedef 10 LogMaxNumCacheLines;

// We have 64 cache lines. We need the log base 2 of that number to get the
// index size for the cache.
// typedef 6 LogNumCacheLines;

//// Data Types

typedef Bit#(32) Word;
typedef Vector#(16, Word) Line; // 16*32 = 512 bits wide cache lines

//// Address Types

// The cache index is used to index into the cache lines
// the cache index size is sized to maximum cache size
typedef Bit#(LogMaxNumCacheLines) CacheIndex;

// There are 16 words per line, so the word offset is log_2(16) = 4 bits wide
typedef Bit#(4) WordOffset;

// tag size + index size + word offset size + byte offset size = 32,
// so the maximum tag size is 
// 32 - 0 (minimum index size) - 4 (word offset size) - 2 (byte offset size) = 26
typedef Bit#(26) CacheTag;

// The line address is just the portion of the byte address used to select lines from main memory.
// The line address is equal to the tag and index concatenated together
// or 32 minus word offset size minus byte offset size
typedef Bit#(26) LineAddr; // 20 + 6 or 32 - 4 - 2  

//// Additional Cache types

// Status for each cache line:
//     Invalid - the current line is invalid.
//     Clean - the current line is valid, and the value hasn't changed since it was read from main memory.
//     Dirty - the current line is valid, but has been written to since it was read from main memory.
typedef enum { Invalid = 0, Clean = 1, Dirty = 2 } CacheStatus deriving (Bits, Eq, FShow);

// TaggedLine is a combination of the data, the tag, and the status of the cache line
typedef struct {
    Line        line;
    CacheStatus status;
    CacheTag tag;
} TaggedLine deriving (Bits, Eq, FShow);

// Memory Request Types
////////////////////////////////////////

// LineReq is a line-based memory request. Addresses are all line addresses and
// the data is a line.
typedef struct {
    MemOp    op;
    LineAddr lineAddr;
    Line     data;
} LineReq deriving(Bits, Eq, FShow);

// Address Helper Functions
////////////////////////////////////////

// function CacheIndex getIndex(Word byteAddress) = truncate(byteAddress>>6);
   
// function CacheTag getTag(Word byteAddress) = truncateLSB(byteAddress);

function WordOffset getWordOffset(Word byteAddress) = truncate(byteAddress >> 2);


interface Cache#(numeric type logNumLines);
    // methods for the processor to interact with the cache
    method Action req(MemReq req);
    method ActionValue#(Word) resp();
    // methods for the cache to interact with DRAM
    method ActionValue#(LineReq) lineReq;
    method Action lineResp(Line r);
    // methods for getting the cache hit and miss counts
    method Bit#(32) getHitCount;
    method Bit#(32) getMissCount;   
endinterface
