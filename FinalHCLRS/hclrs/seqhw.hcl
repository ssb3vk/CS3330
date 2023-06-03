# An example file in our custom HCL variant, with lots of comments

register pP {  
    # our own internal register. P_pc is its output, p_pc is its input.
	pc:64 = 0; # 64-bits wide; 0 is its default value.
	
	# we could add other registers to the P register bank
	# register bank should be a lower-case letter and an upper-case letter, in that order.
	
	# there are also two other signals we can optionally use:
	# "bubble_P = true" resets every register in P to its default value
	# "stall_P = true" causes P_pc not to change, ignoring p_pc's value
} 

# "pc" is a pre-defined input to the instruction memory and is the 
# address to fetch 6 bytes from (into pre-defined output "i10bytes").
pc = P_pc;

# we can define our own input/output "wires" of any number of 0<bits<=80
wire opcode:8, icode:4;

# the x[i..j] means "just the bits between i and j".  x[0..1] is the 
# low-order bit, similar to what the c code "x&1" does; "x&7" is x[0..3]
opcode = i10bytes[0..8];   # first byte read from instruction memory
icode = opcode[4..8];      # top nibble of that byte

/* we could also have done i10bytes[4..8] directly, but I wanted to
 * demonstrate more bit slicing... and all 3 kinds of comments      */
// this is the third kind of comment

# named constants can help make code readable
const TOO_BIG = 0xC; # the first unused icode in Y86-64


#Implementation of irmovq, rrmovq, jmp, OPq:

wire byte2:8, valC:64, valE:64, rB:4, rA:4, ifun:4, conditionsMet:1; 
byte2 = i10bytes[8..16];  
rA = byte2[4..8];
rB = byte2[0..4];
ifun = opcode[0..4]; #uses the opcode value defined above

reg_srcA = [
	icode in {POPQ, RET}	: REG_RSP;
	1		: rA;
];

reg_srcB = [
	icode in {PUSHQ, POPQ, CALL, RET}	: REG_RSP; #RSP is number 4 
	1		: rB; 
];

valC = [
	icode in {IRMOVQ, RMMOVQ, MRMOVQ} : i10bytes[16..80];
	icode in {JXX, CALL} : i10bytes[8..72];
	1		: 0xBADBADBAD; 
];


reg_inputE = [
	icode in {PUSHQ, POPQ, OPQ, CALL, RET}	: valE; 	
	icode == IRMOVQ : valC;
	icode == RRMOVQ : reg_outputA;
	icode == MRMOVQ : mem_output; 
	1		: 0xBADBADBAD; 
]; 

reg_dstE = [
	!conditionsMet && icode == CMOVXX : REG_NONE;
	icode in {PUSHQ, POPQ, CALL, RET}	: REG_RSP;  
	icode in {IRMOVQ, RRMOVQ, OPQ} : rB; 
	icode == MRMOVQ : rA; 
	1		: REG_NONE; 
];

reg_inputM = [
	icode == POPQ	: mem_output; 
	1		: 0xBADBADBAD; 
];

reg_dstM = [
	icode == POPQ	: rA; 
	1		: REG_NONE; 
]; 

valE = [
	icode in {RMMOVQ, MRMOVQ} : reg_outputB + valC;
	icode in {PUSHQ, CALL}	: reg_outputB - 8; 
	icode in {POPQ, RET}	: reg_outputB + 8; 
	ifun == 0 : reg_outputB + reg_outputA; 
	ifun == 1 : reg_outputB - reg_outputA; 
	ifun == 2 : reg_outputB & reg_outputA; 
	ifun == 3 : reg_outputA ^ reg_outputB; 
	1	: 0xBADBADBAD
];

#rmmovq implementation details

mem_addr = [
	icode == POPQ	: reg_outputB;
	icode == RET	: reg_outputA;  	
	1	: valE; 
]; 

mem_readbit = [
	icode in {MRMOVQ, POPQ, RET} : 1; 
	1	: 0; 
]; 

mem_writebit = [
	icode in {PUSHQ, RMMOVQ, CALL}	: 1; # omitted from readbit as it is 0 regardless
	1	: 0; 
]; 

mem_input = [
	icode == RET	: reg_outputA; 
	icode == CALL	: P_pc + 9; 
	1	: reg_outputA; 
]; 

# condition codes implementation: 

register cC {
	SF:1 = 0; 
	ZF:1 = 1; 
}

stall_C = (icode != OPQ); 
c_ZF = (valE == 0); 
c_SF = (valE >= 0x8000000000000000); 

#some code for cmovXX

conditionsMet = [
	ifun == ALWAYS  : 1; 
	ifun == 1 : C_SF || C_ZF; 
	ifun == 2  : C_SF; 
	ifun == 3  : C_ZF; 
	ifun == 4 : !C_ZF; 
	ifun == 5 : !C_SF || C_ZF; 
	ifun == 6  : !C_SF && !C_ZF ; 	
	1	: 0; 
]; 

# some named constants are built-in: the icodes, ifuns, STAT_??? and REG_???


# Stat is a built-in output; STAT_HLT means "stop", STAT_AOK means 
# "continue".  The following uses the mux syntax described in the 
# textbook
Stat = [
	#icode in { CALL, RET } : STAT_INS; 
	icode > 11    : STAT_INS; 
	icode == HALT : STAT_HLT;
	1             : STAT_AOK;
];

wire pcadd: 4; # So have to declare wire here to use as mux? Ask later to Reiss. 
pcadd = [
	icode in { HALT, NOP, RET } : 1; #do we add one to PC even in halt? I am unsure. 
	icode in { RRMOVQ, CMOVXX, OPQ, PUSHQ, POPQ } : 2; 
	icode in { JXX, CALL } : 9; 
	icode in { IRMOVQ, RMMOVQ, MRMOVQ } : 10; 
	1		: 7; 
]; 

# to make progress, we have to update the PC...
# you may use math ops directly...

# previous implementation of program counter
# p_pc = P_pc + pcadd; 

p_pc = [
	icode == JXX && conditionsMet: valC; 
	icode == CALL	: valC; 
	icode == RET	: mem_output; 
	1		: P_pc + pcadd; 
]; 
