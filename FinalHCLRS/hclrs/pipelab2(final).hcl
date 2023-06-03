# -*-sh-*- # this line enables partial syntax highlighting in emacs

wire loadUse:1; 

loadUse = [	
	E_icode == MRMOVQ && (E_dstM == d_srcA || E_dstM == d_srcB) : 1; 
	1 : 0; 
]; 

stall_F = loadUse; 
stall_D = loadUse; 
bubble_E = loadUse; 


######### The PC #############
register fF { pc:64 = 0; }


########## Fetch #############
pc = F_pc;

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
	f_icode in { JXX } : i10bytes[8..72];
	1 : i10bytes[16..80];
];

wire offset:64;
offset = [
	f_icode in { HALT, NOP, RET } : 1;
	f_icode in { RRMOVQ, OPQ, PUSHQ, POPQ } : 2;
	f_icode in { JXX, CALL } : 9;
	1 : 10;
];

f_valP = F_pc + offset;

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
	D_icode in {RMMOVQ} : D_rA;
	1 : REG_NONE;
];
reg_srcB = [
	D_icode in {RMMOVQ, MRMOVQ} : D_rB;
	1 : REG_NONE;
];

d_Stat = D_Stat; 
d_icode = D_icode; 
d_ifun = D_ifun; 
d_valC = D_valC; 
d_valA = [
	reg_srcA == REG_NONE: 0; 
	reg_srcA == m_dstM : m_valM; 
	reg_srcA == W_dstM : W_valM; 
	1 : reg_outputA; 	
]; 

d_valB = [
	reg_srcB == REG_NONE: 0; 
	reg_srcB == m_dstM : m_valM; 
	reg_srcB == W_dstM : W_valM;
	1 : reg_outputB; 
];

d_dstM = [
	d_icode == MRMOVQ : D_rA; 
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

	dstM: 4 = REG_NONE; 
	srcA: 4 = REG_NONE; 
	srcB: 4 = REG_NONE; 
}


wire operand1:64, operand2:64;

operand1 = [
	E_icode in { MRMOVQ, RMMOVQ } : E_valC;
	1: 0;
];
operand2 = [
	E_icode in { MRMOVQ, RMMOVQ } : E_valB;
	1: 0;
];

e_valE = [
	E_icode in { MRMOVQ, RMMOVQ } : operand1 + operand2;
	1 : 0;
];

e_Stat = E_Stat; 
e_icode = E_icode;

e_valA = E_valA;  
e_dstM = E_dstM; 

########## Memory #############
register eM {
	Stat: 3 = STAT_AOK; 

	icode: 4 = NOP; 
	valE: 64 = 0xBADBADBAD; 
	valA: 64 = 0xBADBADBAD; 
	
	dstM: 4 = REG_NONE; 
}


mem_readbit = M_icode in { MRMOVQ };
mem_writebit = M_icode in { RMMOVQ };
mem_addr = [
	M_icode in { MRMOVQ, RMMOVQ } : M_valE;
        1: 0xBADBADBAD;
];
mem_input = [
	M_icode in { RMMOVQ } : M_valA;
        1: 0xBADBADBAD;
];

m_Stat = M_Stat; 
m_icode = M_icode; 

m_valE = M_valE; 
m_valM = mem_output; 

m_dstM = M_dstM; 

########## Writeback #############
register mW {
	Stat: 3 = STAT_AOK; 	

	icode: 4 = NOP; 
	
	valE: 64 = 0xBADBADBAD; 
	valM: 64 = 0xBADBADBAD; 
	dstM: 4 = REG_NONE; 
}


reg_dstM = [ 
	W_icode in {MRMOVQ} : W_dstM;
	1: REG_NONE;
];
reg_inputM = [
	W_icode in {MRMOVQ} : W_valM;
        1: 0xBADBADBAD;
];


Stat = W_Stat; 

f_pc = f_valP;



