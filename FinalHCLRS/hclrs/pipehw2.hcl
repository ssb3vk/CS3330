# -*-sh-*- # this line enables partial syntax highlighting in emacs

wire loadUse:1, conditionsMet:1, rethazard:1, retBubble:1; 

loadUse = [	
	E_icode in {MRMOVQ, POPQ} && (E_dstM == d_srcA || E_dstM == d_srcB) : 1; 
	1 : 0; 
]; 

conditionsMet = E_icode == JXX && !e_Cnd;  #checking for JXX mispredictions
	

rethazard = [
	D_icode == RET : 1;
	E_icode == RET : 1;
	M_icode == RET : 1;
	1 : 0; 
]; 

retBubble = [
	W_icode == RET : 1; 
	1 : 0; 
]; 


stall_F = loadUse || rethazard; 
stall_D = loadUse; 
bubble_D = conditionsMet || !loadUse && rethazard;
bubble_E = conditionsMet || loadUse;
bubble_M = [
	m_Stat in {STAT_HLT, STAT_INS} || W_Stat in {STAT_HLT, STAT_INS}: 1;
	1 : 0;  
]; 
stall_W = [
	W_Stat in {STAT_HLT, STAT_INS} : 1; 
	1 : 0; 
];

#[
#	E_icode == JXX && e_Cnd == 0 : 1;
#	1 : loadUse; 
#]; 


######### The PC #############
register fF { predPC:64 = 0; }


########## Fetch #############
pc = [ #page 448 of textbook
	# Mispredicted branch. Fetch at incremented PC	
	M_icode == JXX && !M_Cnd : M_valA; 
	# Completion of RET instruction
	W_icode == RET : W_valM; 
	# Default: use predicted value of PC
	1 : F_predPC;
]; 

f_Stat = [
	f_icode == HALT : STAT_HLT;
	f_icode > 0xb : STAT_INS;
	1 : STAT_AOK;
];

f_icode = i10bytes[4..8];
f_ifun = i10bytes[0..4];
f_rA = i10bytes[12..16];
f_rB = i10bytes[8..12];

f_valC = [
	f_icode in { JXX, CALL } : i10bytes[8..72];
	1 : i10bytes[16..80];
];

wire offset:64;
offset = [
	f_icode in { HALT, NOP, RET } : 1;
	f_icode in { RRMOVQ, OPQ, PUSHQ, POPQ } : 2;
	f_icode in { JXX, CALL } : 9;
	1 : 10;
];

f_valP = pc + offset;

########## Decode #############
register fD {
	Stat: 3 = STAT_AOK; 

	icode: 4 = NOP; 
	ifun: 4 = 0; 
	rA: 4 = REG_NONE; 
	rB: 4 = REG_NONE; 
	valC: 64 = 0xBADBADBAD; 

	valP: 64 = 0xBADBADBAD; 
}


reg_srcA = [
	D_icode in {POPQ, RET} : REG_RSP; 	
	D_icode in {RRMOVQ, RMMOVQ, OPQ, PUSHQ, CALL} : D_rA;
	1 : REG_NONE;
];
reg_srcB = [
	D_icode in {IRMOVQ, RMMOVQ, MRMOVQ, OPQ} : D_rB;
	D_icode in {PUSHQ, POPQ, CALL, RET} : REG_RSP; 
	1 : REG_NONE;
];

d_Stat = D_Stat; 
d_icode = D_icode; 
d_ifun = D_ifun; 
d_valC = D_valC; 
d_valA = [
	d_icode in {JXX, CALL} : D_valP; # need this line of code, exposed by jxx.yo	
	(reg_dstE == reg_srcA) && (reg_dstE != REG_NONE) : reg_inputE;
	reg_srcA == REG_NONE: 0; 
	reg_srcA == e_dstE : e_valE; 
	reg_srcA == m_dstM : m_valM; 
	reg_srcA == m_dstE : m_valE; 
	reg_srcA == W_dstM : W_valM;
	reg_srcA == W_dstE : W_valE; 
	1 : reg_outputA; 	
]; 

d_valB = [
	reg_srcB == REG_NONE: 0; 
	W_dstE == D_rB : W_valE;	
	reg_srcB == e_dstE : e_valE;
	reg_srcB == m_dstM : m_valM; 	
	reg_srcB == m_dstE : m_valE;
	reg_srcB == W_dstM : W_valM; 
	reg_srcB == W_dstE : W_valE; 
	1 : reg_outputB; 
];

d_dstE = [
	d_icode in {IRMOVQ, RRMOVQ, OPQ} : D_rB; 
	d_icode in {POPQ, PUSHQ, CALL, RET} : REG_RSP; 
	1 : REG_NONE; 
];

d_dstM = [
	d_icode in {MRMOVQ, POPQ, PUSHQ} : D_rA; #used for 
	1 : REG_NONE; 
]; 

d_srcA = reg_srcA; 
d_srcB = reg_srcB; 

########## Execute #############
register dE {
	Stat: 3 = STAT_AOK; 

	icode: 4 = NOP; 
	ifun: 4 = 0; 
	
	valC: 64 = 0xBADBADBAD; 	
	valA: 64 = 0xBADBADBAD; 
	valB: 64 = 0xBADBADBAD; 

	dstE: 4 = REG_NONE; 
	dstM: 4 = REG_NONE; 
	srcA: 4 = REG_NONE; 
	srcB: 4 = REG_NONE; 
}


wire ALUA:64, ALUB:64;

ALUA = [
	E_icode in { MRMOVQ, RMMOVQ, IRMOVQ } : E_valC;
	E_srcA != REG_NONE && E_srcA == W_dstM : W_valM; 	
	E_srcA != REG_NONE && E_srcA == M_dstE : M_valE;
	E_srcA != REG_NONE && E_srcA == W_dstE : W_valE;	
	1: E_valA;
];
ALUB = [
	E_srcB != REG_NONE && E_srcB == M_dstE : M_valE; 
	E_srcB != REG_NONE && E_srcB == W_dstE : W_valE;	
	E_icode in { MRMOVQ, RMMOVQ, PUSHQ, POPQ, CALL, RET } : E_valB; # needed for PUSH/POP
	1: E_valB;
];

e_valE = [
	E_icode in {IRMOVQ, RRMOVQ} : ALUA; 	
	E_icode in {RMMOVQ, MRMOVQ} : ALUB + ALUA;
	E_icode in {PUSHQ, CALL}	: ALUB - 8; 
	E_icode in {POPQ, RET}	: ALUA + 8; #changed from ALUB
	E_ifun == 0 : ALUB + ALUA; 
	E_ifun == 1 : ALUB - ALUA; 
	E_ifun == 2 : ALUB & ALUA; 
	E_ifun == 3 : ALUA ^ ALUB;
	1 : 0;
];

register cC {
	SF:1 = 0; 
	ZF:1 = 1; 
}

stall_C = (e_icode != OPQ) && !(m_Stat in {STAT_HLT, STAT_INS}) && !(W_Stat in {STAT_HLT, STAT_INS}); 
c_ZF = (e_valE == 0); 
c_SF = (e_valE >= 0x8000000000000000);

e_Cnd = [
	E_ifun == ALWAYS  : 1; 
	E_ifun == 1 : C_SF || C_ZF; 
	E_ifun == 2  : C_SF; 
	E_ifun == 3  : C_ZF; 
	E_ifun == 4 : !C_ZF; 
	E_ifun == 5 : !C_SF || C_ZF; 
	E_ifun == 6  : !C_SF && !C_ZF ; 	
	1	: 0; 
]; 

e_Stat = E_Stat; 
e_icode = E_icode;

e_dstE = [
	!e_Cnd && e_icode == CMOVXX : REG_NONE; 
	1	: E_dstE;
]; 

e_valA = [
	e_icode in {RET} : ALUB; 
	E_srcA != REG_NONE && E_srcA == M_dstE : M_valE; # CAn i do this to account for irmovq follwed by rmmovq
	1 : E_valA;
];
  
e_dstM = E_dstM; 

########## Memory #############
register eM {
	Stat: 3 = STAT_AOK; 
	icode: 4 = NOP; 

	Cnd: 1 = 0;

	valE: 64 = 0xBADBADBAD; 
	valA: 64 = 0xBADBADBAD; 
	
	dstE: 4 = REG_NONE;
	dstM: 4 = REG_NONE; 
}


mem_readbit = M_icode in { MRMOVQ, POPQ, RET };
mem_writebit = M_icode in { RMMOVQ, PUSHQ, CALL };
mem_addr = [
	M_icode in {POPQ, RET} : M_valA; 		
	M_icode in { MRMOVQ, RMMOVQ, PUSHQ,CALL } : M_valE;
        1: 0xBADBADBAD;
];
mem_input = [
	M_icode in { RMMOVQ, PUSHQ, CALL } : M_valA;
        1: 0xBADBADBAD;
];

m_Stat = M_Stat; 
m_icode = M_icode; 

m_dstE = M_dstE; 
m_dstM = M_dstM; 

m_valE = M_valE; 
m_valM = mem_output; 

########## Writeback #############
register mW {
	Stat: 3 = STAT_AOK; 	

	icode: 4 = NOP; 
	
	dstE: 4 = REG_NONE; 
	dstM: 4 = REG_NONE; 

	valE: 64 = 0xBADBADBAD; 
	valM: 64 = 0xBADBADBAD; 
	
}

reg_dstE = [
	W_icode in {IRMOVQ, RRMOVQ, OPQ, PUSHQ, POPQ, CALL, RET} : W_dstE;
	1 : REG_NONE;
];


reg_inputE = [ # unlike book, we handle the "forwarding" actions (something + 0) here
	W_icode == RRMOVQ : W_valE;
	W_icode in {IRMOVQ, OPQ, PUSHQ, POPQ, CALL, RET} : W_valE;
        1: 0xBADBADBAD;
];

reg_dstM = [ 
	W_icode in {MRMOVQ, POPQ, RET} : W_dstM;
	1: REG_NONE;
];
reg_inputM = [
	W_icode in {MRMOVQ, POPQ, RET} : W_valM;
        1: 0xBADBADBAD;
];


Stat = W_Stat; 

f_predPC = [ #page 449 textbook
	f_icode in {JXX, CALL} : f_valC;
	f_Stat != STAT_AOK : pc;
	1 : f_valP;
]; 



