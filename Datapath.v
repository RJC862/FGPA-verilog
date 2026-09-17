`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Penn State
// Engineer: Ryan Cao
// 
// Create Date: 3/22/2026
// Design Name: Lab 3 - Instruction Fetch and Decode
// Module Name: datapath
// Project Name: Lab 3 - Instruction Fetch and Decode
// Target Devices: XC7Z010-CLG400-1
// Description: Implementation of IF and ID stages of a 5-stage pipelined CPU
// 
// Instructions to implement:
//   Address 100: lw $v0, 00($at)  ->  lw $2, 0($1)
//   Address 104: lw $v1, 04($at)  ->  lw $3, 4($1)
//   Assume register $at ($1) has value 0
//
//////////////////////////////////////////////////////////////////////////////////

//==============================================================================
// TOP-LEVEL DATAPATH MODULE
//==============================================================================
// This module connects all the pipeline stages together.
// Input:  clk - clock signal
// Output: None (all signals are internal)
//
// You need to:
// 1. Declare all internal wires to connect the modules
// 2. Instantiate all 9 modules and connect them properly
// 3. Decode the instruction fields (op, rs, rt, rd, func, imm) from dinstOut
//==============================================================================

module Datapath(
    input clk,
    output [31:0] wbData
);

    // TODO: Declare wires for IF stage
    // Hint: You need wires for pc, nextpc, instOut
    wire [31:0] pc, pc4, nextpc, instOut, npc, bpc, da, jpc;
    wire [1:0] pcsrc;
    
    // TODO: Declare wire for IF/ID pipeline register output
    wire [31:0] dinstOut;
    // Hint: dinstOut holds the instruction in the ID stage
    
    // TODO: Decode instruction fields from dinstOut
    // Hint: Use assign statements to extract:
    //   Example: op    = dinstOut[31:26]  (6 bits - opcode)
    wire [5:0] op, func;
    wire [4:0] rs,rt,rd;
    wire [15:0] imm;
    assign op = dinstOut[31:26];
    assign rs = dinstOut[25:21];
    assign rt = dinstOut[20:16];
    assign rd = dinstOut[15:11];
    assign shamt = dinstOut[10:6];
    assign func = dinstOut[5:0];
    assign imm = dinstOut[15:0];
    
    
    // TODO: Declare wires for control unit outputs
    // Hint: wreg, m2reg, wmem, aluc[3:0], aluimm, regrt
    wire wreg,m2reg,wmem,aluimm,regrt;
    wire [3:0] aluc;
    wire [1:0] fwda, fwdb;
    wire [31:0] fwva, fwvb;
    // TODO: Declare wires for ID stage
    // Hint: destReg[4:0], qa[31:0], qb[31:0], imm32[31:0]
    wire [4:0] destReg;
    wire [31:0] qa, qb, imm32;
    // TODO: Declare wires for ID/EXE pipeline register outputs
    // Hint: Use 'e' prefix for EXE stage signals (ewreg, em2reg, etc.)
    
    wire ewreg, em2reg, ewmem, ealuimm;
    wire [3:0] ealuc;
    wire [4:0] edestReg;
    wire [31:0] eqa, eqb, eimm32;
    
    // ALUMux output wire
    wire [31:0] b;
    
    // wires for EXE/MEM stage
    wire mwreg, mm2reg, mwmem;
    wire [4:0] mdestReg;
    wire [31:0] r, mr, mqb, mdo;
    
    // Wires for MEM/WB stage
    wire wwreg, wm2reg;
    wire [4:0] wdestReg;
    wire [31:0] wr, wdo, wbData;
    
    //==========================================================================
    // STAGE 1: INSTRUCTION FETCH (IF) - Instantiate modules
    //==========================================================================

    // TODO: Instantiate PC (Program Counter)
    PC pc1(clk, nextpc, pc);
    // TODO: Instantiate PCAdd4 (PC + 4 Adder)
    PCAdd4 pcadd4 (pc, pc4);
    // instantiate the PCMux
    PCMux(pcsrc, pc4, bpc, da, jpc, nextpc);
    // TODO: Instantiate IM (Instruction Memory)
    IM im1(pc,instOut);
    // TODO: Instantiate IFID (IF/ID Pipeline Register)
    IFID ifid(clk, instOut, dinstOut);
    //==========================================================================
    // STAGE 2: INSTRUCTION DECODE (ID) - Instantiate modules
    //==========================================================================
    
    // TODO: Instantiate CU (Control Unit)
    CU cu(op, func, rs, rt, mdestReg, mm2reg, mwreg, edestReg, em2reg, ewreg, wreg, m2reg, wmem, jal, aluc, aluimm, shift, regrt, rsrtequ, sext, fwdb, fwda, pcsrc, wpcir);
    // TODO: Instantiate Regfile (Register File)
    Regfile rfile(rs, rt, wdestReg, wbData, wwreg, clk, qa, qb);
    // TODO: Instantiate Mux (Regrt Multiplexer)
    Mux mux(rd, rt, regrt, destReg);
    // TODO: Instantiate Ext (Sign Extender)
    
    // forwarding muxes
    FWDMux fwdamux(fwda, qa, r, mr, mdo, fwva);
    FWDMux fwdbmux(fwdb, qb, r, mr, mdo, fwvb);
    
    Ext ext(imm, imm32);
    // TODO: Instantiate IDEXE (ID/EXE Pipeline Register)
    IDEXE idexe(clk, wreg, m2reg, wmem, aluc, aluimm, destReg, fwva, fwvb, imm32, ewreg, em2reg, ewmem, ealuc, ealuimm, edestReg, eqa, eqb, eimm32);
    //==========================================================================
    // STAGE 3: INSTRUCTION EXECUTE (EXE) - Instantiate modules
    //==========================================================================
    // Implement ALUMux, ALU, EXEMEM
    ALUMux alumux(ealuimm, eqb, eimm32, b);
    ALU alu(b, eqa, ealuc, r);
    EXEMEM exemem (clk, ewreg, em2reg, ewmem, edestReg, eqb, r, mwreg, mm2reg, mwmem, mdestReg, mr, mqb); 
    

    //==========================================================================
    // STAGE 4: MEMORY (MEM) - Instantiate modules
    //==========================================================================
    DM datamem(clk, mr, mqb, mwmem, mdo);
    MEMWB memwb(clk, mwreg, mm2reg, mdestReg, mr, mdo, wwreg, wm2reg, wdestReg, wr, wdo);
    
    //==========================================================================
    // STAGE 5: WRITEBACK (WB) - Instantiate modules
    //==========================================================================
    
    WbMux wbmux(wr, wdo, wm2reg, wbData);
endmodule

//==============================================================================
// STAGE 1: INSTRUCTION FETCH (IF) MODULES
//==============================================================================

//------------------------------------------------------------------------------
// PC - Program Counter
//------------------------------------------------------------------------------
// Holds the address of the current instruction being fetched.
// Starts at address 100 as specified in the lab.
//
// Inputs:
//   clk     - clock signal (update PC on positive edge)
//   nextpc  - the next PC value (PC + 4)
//
// Outputs:
//   pc      - current program counter value (32 bits)
//
// Hints:
//   - Use an initial block to set pc = 100
//   - Use always @(posedge clk) to update pc with nextpc
//   - Use non-blocking assignment (<=) in sequential logic
//------------------------------------------------------------------------------

module PC(
    input clk,
    input [31:0] nextpc,
    output reg [31:0] pc
);
    // TODO: Implement the program counter
    // Initialize pc to 100, update to nextpc on each clock edge
    initial begin
        pc <= 100;
    end
    
    always@(posedge clk) begin
        pc <= nextpc;
    end
endmodule

// chooses the source for the next PC
module PCMux(
    input [1:0] pcsrc,
    input [31:0] pc4,
    input [31:0] bpc,
    input [31:0] da,
    input [31:0] jpc,
    output reg [31:0] npc
);

    always@(*) begin
        case (pcsrc)
            0: npc = pc4; // no jump or branch
            1: npc = bpc; // branch instruction target address
            2: npc = da; // target address of jr instruction
            3: npc = jpc; // target address of j or jal instruction
        endcase
    end
endmodule
//------------------------------------------------------------------------------
// PCAdd4 - PC + 4 Adder
//------------------------------------------------------------------------------
// Calculates the address of the next sequential instruction.
//
// Inputs:
//   pc      - current program counter value (32 bits)
//
// Outputs:
//   nextpc  - next program counter value (pc + 4) (32 bits)
//
// Hints:
//   - This is combinational logic, use always @(*)
//------------------------------------------------------------------------------

module PCAdd4(
    input [31:0] pc,
    output reg [31:0] nextpc
);
    // TODO: Implement the PC + 4 adder
    always@(*) begin
        nextpc <= pc + 4;
    end
endmodule


//------------------------------------------------------------------------------
// IM - Instruction Memory
//------------------------------------------------------------------------------
// Stores the program instructions. Read-only memory.
// Address 100 (index 25) and 104 (index 26) contain the lw instructions.
//
// Inputs:
//   pc      - program counter (address to read from) (32 bits)
//
// Outputs:
//   instOut - instruction at the given address (32 bits)
//
// Hints:
//   - Declare a reg array: reg [31:0] instructions [0:127]
//   - Use initial block 
//------------------------------------------------------------------------------

module IM(
    input [31:0] pc,
    output reg [31:0] instOut
);
    // TODO: Declare instruction memory array
    reg [31:0] instructions [0:127];
    
    // TODO: Initialize instructions at index 25 and 26
    initial begin
        instructions[25] = 32'b00000000001000100001100000100000; // add $3, $1, $2
        instructions[26] = 32'b00000001001000110010000000100010; // sub $4, $9, $3
        instructions[27] = 32'b00000000011010010010100000100101; // or $5, $3, $9
        instructions[28] = 32'b00000000011010010011000000100110; // xor $6, $3, $9
        instructions[29] = 32'b00000000011010010011100000100100; // and $7, $3, $9
    end
    
    // TODO: Read instruction based on pc (use pc >> 2 or pc / 4 as index)
    always @(*)begin
        instOut <= instructions[pc >> 2];
    end
endmodule


//------------------------------------------------------------------------------
// IFID - IF/ID Pipeline Register
//------------------------------------------------------------------------------
// Stores the instruction fetched in IF stage for use in ID stage.
// Updates on the positive edge of the clock.
//
// Inputs:
//   clk     - clock signal
//   instOut - instruction from instruction memory (32 bits)
//
// Outputs:
//   dinstOut - instruction passed to ID stage (32 bits)
//
// Hints:
//   - Use always @(posedge clk)
//   - Use non-blocking assignment (<=)
//------------------------------------------------------------------------------

module IFID(
    input clk,
    input [31:0] instOut,
    output reg [31:0] dinstOut
);
    // TODO: Implement the IF/ID pipeline register
    always@(posedge clk) begin
        dinstOut <= instOut;
    end
endmodule


//==============================================================================
// STAGE 2: INSTRUCTION DECODE (ID) MODULES
//==============================================================================

//------------------------------------------------------------------------------
// CU - Control Unit
//------------------------------------------------------------------------------
// Generates control signals based on the opcode and function code.
//
// Inputs:
//   op      - opcode field from instruction (6 bits)
//   func    - function field from instruction (6 bits)
//
// Outputs:
//   wreg    - write enable for register file (1 bit)
//   m2reg   - memory to register (1 = load data from memory) (1 bit)
//   wmem    - write enable for data memory (1 bit)
//   aluc    - ALU control signals (4 bits)
//   aluimm  - ALU source B select (1 = use immediate) (1 bit)
//   regrt   - register destination select (0 = rd, 1 = rt) (1 bit)
//
// Hints:
//   - Use a case statement on the opcode
//   - Add a default case to handle undefined opcodes
//------------------------------------------------------------------------------

module CU(
    input [5:0] op,
    input [5:0] func,
    input [4:0] rs,
    input [4:0] rt,
    input [4:0] mdestReg,
    input mm2reg,
    input mwreg,
    input [4:0] edestReg,
    input em2reg,
    input ewreg,
    output reg wreg,
    output reg m2reg,
    output reg wmem,
    output reg jal,
    output reg [3:0] aluc,
    output reg aluimm,
    output reg shift,
    output reg regrt,
    output reg rsrtequ,
    output reg sext,
    output reg [1:0] fwdb,
    output reg [1:0] fwda,
    output reg [1:0] pcsrc,
    output reg wpcir
);
    // TODO: Implement the control unit using a case statement
    
    reg stall;
    reg i_rs;
    reg i_rt;
    
    always@(*)begin
    
        case(op)
            // Load Word opcode
            6'b100011: begin
                i_rs = 1;
                i_rt = 1;
                regrt = 1;
                aluimm = 1;
                m2reg = 1;
                wmem = 0;
                wreg = 1;
                aluc = 4'b0010;
            end
            
            //Store Word opcode
            6'b101011: begin
                i_rs = 1;
                i_rt = 1;
                aluimm = 1;
                wreg = 0;
                wmem = 1;
                aluc = 4'b0010;
            end
            
            //R-type instruction opcode
            6'b000000: begin
                i_rs = 1;
                i_rt = 1;
                regrt = 0;
                aluimm = 0;
                m2reg = 0;
                wreg = 1;
                wmem = 0;
                
                // Analyzing function bitfield
                case(func) 
                    6'b100000: aluc = 4'b0010; // add
                    6'b100010: aluc = 4'b0110; // subtract
                    6'b100100: aluc = 4'b0000; // AND
                    6'b100101: aluc = 4'b0001; // OR
                    6'b100110: aluc = 4'b0011; // XOR
                    6'b101010: aluc = 4'b0111; // slt
                endcase
            end
            
            //beq instruction opcode
            6'b000100: begin
                i_rs = 0;
                i_rt = 0;
                aluc = 0;
                wreg = 0;
                wmem = 0;
                aluc = 4'b0110;
            end
                
            default: begin
                wreg = 1;
                m2reg = 0;
                wmem = 0;
                aluimm = 0;
                regrt = 0;
                aluc = 4'b0010;
            end
        endcase
        
        // forwarding logic
        if (rs == mdestReg && mm2reg == 1) fwda = 2'b11; // load word dependency 
        else if (rs == mdestReg) fwda = 2'b10; // MEM to ALU forwarding
        else if (rs == edestReg) fwda = 2'b01; // ALU to ALU forwarding
        else fwda = 2'b00; // no hazards
        
        if (rt == mdestReg && mm2reg == 1) fwdb = 2'b11; // load word dependency
        else if (rt == mdestReg) fwdb = 2'b10; // MEM to ALU forwarding
        else if (rt == edestReg) fwdb = 2'b01; // ALU to ALU forwarding
        else fwdb = 2'b00; // no hazards
        
        if (
    end
    
endmodule


//------------------------------------------------------------------------------
// Regfile - Register File
//------------------------------------------------------------------------------
// Contains 32 general-purpose registers. Provides two read ports.
// All registers should be initialized to 0.
//
// Inputs:
//   rs      - source register 1 address (5 bits)
//   rt      - source register 2 address (5 bits)
//
// Outputs:
//   qa      - data from register rs (32 bits)
//   qb      - data from register rt (32 bits)
//
// Hints:
//   - Declare a reg array: reg [31:0] registers [0:31]
//   - Use a for loop in initial block to set all registers to 0
//   - Use always @(*) for combinational read logic
//------------------------------------------------------------------------------

module Regfile(
    input [4:0] rs,
    input [4:0] rt,
    input [4:0] wdestReg,
    input [31:0] wbData,
    input wwreg,
    input clk,
    output reg [31:0] qa,
    output reg [31:0] qb
);
    // TODO: Declare register array
    reg [31:0] registers [0:31];
    
    
    integer i;
    
    // initialize register words
    initial begin
        registers[0] = 32'h00000000;
        registers[1] = 32'hA00000AA;
        registers[2] = 32'h10000011;
        registers[3] = 32'h20000022;
        registers[4] = 32'h30000033;
        registers[5] = 32'h40000044;
        registers[6] = 32'h50000055;
        registers[7] = 32'h60000066;
        registers[8] = 32'h70000077;
        registers[9] = 32'h80000088;
        registers[10] = 32'h90000099;
        
        for ( i = 11; i < 32; i = i + 1) begin
            registers[i] = 0;
        end
    end
    
    always@(negedge clk) begin
        if (wwreg == 1) registers[wdestReg] <= wbData;
    end
    // TODO: Read registers based on rs and rt
    always@(*) begin
        qa = registers[rs];
        qb = registers[rt];
    end
endmodule


//------------------------------------------------------------------------------
// Mux - Regrt Multiplexer
//------------------------------------------------------------------------------
// Selects the destination register number.
// For R-type instructions, destination is rd.
// For I-type instructions (like lw), destination is rt.
//
// Inputs:
//   rd      - destination register for R-type (5 bits)
//   rt      - destination register for I-type (5 bits)
//   regrt   - select signal (0 = rd, 1 = rt)
//
// Outputs:
//   destReg - selected destination register (5 bits)
//
// Hints:
//   - Use if-else
//   - When regrt = 0, select rd
//   - When regrt = 1, select rt
//------------------------------------------------------------------------------

module Mux(
    input [4:0] rd,
    input [4:0] rt,
    input regrt,
    output reg [4:0] destReg
);
    // TODO: Implement the multiplexer
    always@(*) begin
        if(regrt == 1)
            destReg = rt;
        else
            destReg = rd;
    end
        
endmodule


// forwarding mux in the ID stage
// regdata is either qa or qb
module FWDMux(
    input [1:0] sel,
    input [31:0] regdata,
    input [31:0] r,
    input [31:0] mr,
    input [31:0] mdo,
    output reg [31:0] result
);

    always@(*) begin
        case (sel)
            0: result = regdata;
            1: result = r;
            2: result = mr;
            3: result = mdo;
        endcase
    end
endmodule

//------------------------------------------------------------------------------
// Ext - Immediate Extender
//------------------------------------------------------------------------------
// Extends the 16-bit immediate value to 32 bits using sign extension.
//
// Inputs:
//   imm     - 16-bit immediate value from instruction
//
// Outputs:
//   imm32   - 32-bit sign-extended immediate
//
// Hints:
//   - Use concatenation with replication
//   - imm[15] is the sign bit
//   - Replicate the sign bit 16 times and concatenate with original imm
//------------------------------------------------------------------------------

module Ext(
    input [15:0] imm,
    output reg [31:0] imm32
);
    // TODO: Implement sign extension
    always@(*)begin
        imm32 <= {{16{imm[15]}}, imm};
    end
endmodule


//------------------------------------------------------------------------------
// IDEXE - ID/EXE Pipeline Register
//------------------------------------------------------------------------------
// Stores all control signals and data from ID stage for use in EXE stage.
// Updates on the positive edge of the clock.
//
// Inputs:
//   clk     - clock signal
//   wreg    - write register enable (1 bit)
//   m2reg   - memory to register (1 bit)
//   wmem    - write memory enable (1 bit)
//   aluc    - ALU control (4 bits)
//   aluimm  - ALU immediate select (1 bit)
//   destReg - destination register (5 bits)
//   qa      - register data A (32 bits)
//   qb      - register data B (32 bits)
//   imm32   - sign-extended immediate (32 bits)
//
// Outputs (active in EXE stage, prefix 'e'):
//   ewreg   - write register enable
//   em2reg  - memory to register
//   ewmem   - write memory enable
//   ealuc   - ALU control
//   ealuimm - ALU immediate select
//   edestReg - destination register
//   eqa     - register data A
//   eqb     - register data B
//   eimm32  - sign-extended immediate
//
// Hints:
//   - Use always @(posedge clk)
//   - Use non-blocking assignments (<=)
//   - Transfer each input to its corresponding output
//------------------------------------------------------------------------------

module IDEXE(
    input clk,
    input wreg,
    input m2reg,
    input wmem,
    input [3:0] aluc,
    input aluimm,
    input [4:0] destReg,
    input [31:0] qa,
    input [31:0] qb,
    input [31:0] imm32,
    output reg ewreg,
    output reg em2reg,
    output reg ewmem,
    output reg [3:0] ealuc,
    output reg ealuimm,
    output reg [4:0] edestReg,
    output reg [31:0] eqa,
    output reg [31:0] eqb,
    output reg [31:0] eimm32
);
    // TODO: Implement the ID/EXE pipeline register
    always@(posedge clk) begin
        ewreg <= wreg;
        em2reg <= m2reg;
        ewmem <= wmem;
        ealuc <= aluc;
        ealuimm <= aluimm;
        edestReg <= destReg;
        eqa <= qa;
        eqb <= qb;
        eimm32 <= imm32;
    end
    
endmodule

// ALUMux selects between eqb and eimm32 according to ealuimm
module ALUMux(
    input ealuimm,
    input [31:0] eqb,
    input [31:0] eimm32,
    output reg [31:0] b
);

    always@(*) begin
        if (ealuimm == 0) b <= eqb;
        else b <= eimm32;
    end
endmodule   
    


// ALU operates on b and eqa depending on ealuc, outputting to r
module ALU(
    input [31:0] b,
    input [31:0] eqa,
    input [3:0] ealuc,
    output reg [31:0] r
);

    always@(*) begin
        case(ealuc)
            // add
            4'b0010: r <= b + eqa;
            
            // subtract
            4'b0110: r <= eqa - b;
            
            // AND
            4'b0000: r <= b & eqa;
            
            // OR
            4'b0001: r <= b | eqa;
            
            // XOR
            4'b0011: r <= b ^ eqa;

        endcase
    end


endmodule
    
    
    
// pipeline register EXE/MEM
module EXEMEM(
    input clk, 
    input ewreg, 
    input em2reg, 
    input ewmem, 
    input [4:0] edestReg, 
    input [31:0] eqb,
    input [31:0] r, 
    output reg mwreg, 
    output reg mm2reg,
    output reg mwmem, 
    output reg [4:0] mdestReg, 
    output reg [31:0] mr, 
    output reg [31:0] mqb
);

    always@(posedge clk) begin
        mwreg <= ewreg;
        mm2reg <= em2reg;
        mwmem <= ewmem;
        mdestReg <= edestReg;
        mr <= r;
        mqb <= eqb;
    end
endmodule
    
    
    
module DM(
    input clk,
    input [31:0] mr, 
    input [31:0] mqb, 
    input mwmem, 
    output reg [31:0] mdo
);

    reg [31:0] dm [0:63];
    
    // Initializing first 10 words in data memory
    initial begin
        dm[0] = 32'hA00000AA;
        dm[1] = 32'h10000011;
        dm[2] = 32'h20000022;
        dm[3] = 32'h30000033;
        dm[4] = 32'h40000044;
        dm[5] = 32'h50000055;
        dm[6] = 32'h60000066;
        dm[7] = 32'h70000077;
        dm[8] = 32'h80000088;
        dm[9] = 32'h90000099;
    end
    
    // reading from data memory on any edge
    always@(*) begin
        mdo = dm[mr >> 2];
    end
    
    // writing to data memory on negedge
    always@(negedge clk) begin
        if (mwmem == 1) begin
            dm[mr >> 2] <= mqb;
        end
    end
endmodule;
    
module MEMWB(
    input clk, 
    input mwreg, 
    input mm2reg, 
    input [4:0] mdestReg, 
    input [31:0] mr, 
    input [31:0] mdo, 
    output reg wwreg, 
    output reg wm2reg, 
    output reg [4:0] wdestReg, 
    output reg [31:0] wr, 
    output reg [31:0] wdo
);

    always@(posedge clk) begin
        wwreg <= mwreg;
        wm2reg <= mm2reg;
        wdestReg <= mdestReg;
        wr <= mr;
        wdo <= mdo;
    end
endmodule
    
    
module WbMux(
    input [31:0] wr,
    input [31:0] wdo,
    input wm2reg,
    output reg [31:0] wbData
);

    always@(*) begin
        if (wm2reg==0) wbData = wr;
        else wbData = wdo;
    end
endmodule
    
    
    
    
    
    
    
    
    
    
    
    
    
