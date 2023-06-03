########## the PC and condition codes registers #############
register fF { pc:64 = 0; }


########## Fetch #############
pc = F_pc;

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

stall_F = 
	f_Stat in {STAT_HLT, STAT_INS}; 

f_Stat = [
	f_icode == HALT : STAT_HLT;
	f_icode > 0xb : STAT_INS;
	1 : STAT_AOK;
];


########## Decode #############
register fD { 
	Stat: 3 = STAT_AOK;	
	icode: 4 = NOP; #icode for nop 
	ifun: 4 = 0; 
	rA: 4 = REG_NONE; 
	rB: 4 = REG_NONE; 
	valC: 64 = 0xBADBADBAD; 
	valP: 64 = 0xBADBADBAD;  
}



d_valC = D_valC; 
d_Stat = D_Stat; 
d_icode = D_icode;
d_ifun = D_ifun;  

# source selection


#destination selection. Do we have to do this or am I just wrong? 
d_dstE = [
	d_icode in {IRMOVQ, RRMOVQ, OPQ} : D_rB;
	1 : REG_NONE;
];

d_dstM = [
	1 : REG_NONE; 
]; 

reg_srcA = [
	d_icode in {RRMOVQ, OPQ} : D_rA;
	1 : REG_NONE;
]; 

reg_srcB = [
	d_icode in {OPQ}	: D_rB; 	
	d_icode in {PUSHQ, POPQ, CALL, RET}	: REG_RSP; #RSP is number 4 
	1		: D_rB; 
];

d_valA = [
	(reg_dstE == reg_srcA) && (reg_dstE != REG_NONE) : reg_inputE;
	1	: reg_outputA;  
]; 

d_valB = [
	W_dstE == D_rB : W_valE; 
	1	: reg_outputB; 
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

wire ALUA: 64, ALUB: 64; 

ALUA = [
	E_srcA != REG_NONE && E_srcA == M_dstE : M_valE;
	E_srcA != REG_NONE && E_srcA == W_dstE : W_valE; 
	E_icode in {RMMOVQ, MRMOVQ, IRMOVQ} : E_valC; 
	1	: E_valA; 
]; 

ALUB = [
	#E_srcB != REG_NONE && E_srcB == M_dstM : M_valA; 
	#E_srcB != REG_NONE && E_srcB == W_dstM : W_valM; 
	E_srcB != REG_NONE && E_srcB == M_dstE : M_valE; 
	E_srcB != REG_NONE && E_srcB == W_dstE : W_valE; 
	1	: E_valB; 
]; 

e_valE = [
	E_icode in {IRMOVQ, RRMOVQ} : ALUA; 	
	E_icode in {RMMOVQ, MRMOVQ} : ALUB + ALUA;
	E_icode in {PUSHQ, CALL}	: ALUB - 8; 
	E_icode in {POPQ, RET}	: ALUB + 8; 
	E_ifun == 0 : ALUB + ALUA; 
	E_ifun == 1 : ALUB - ALUA; 
	E_ifun == 2 : ALUB & ALUA; 
	E_ifun == 3 : ALUA ^ ALUB; 
	1	: 0xBADBADBAD
];

# condition codes implementation: 

register cC {
	SF:1 = 0; 
	ZF:1 = 1; 
}

stall_C = (e_icode != OPQ); 
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

e_dstM = E_dstM; 
e_valA = E_valA;  

########## Memory #############
register eM {
	Stat: 3 = STAT_AOK; 
	icode: 4 = NOP; 
	
	Cnd: 1 = 0; 

	dstE: 4 = REG_NONE; 
	dstM: 4 = REG_NONE; 
	valA: 64 = 0xBADBADBAD; 
	valE: 64 = 0xBADBADBAD;

}

m_Stat = M_Stat; 
m_icode = M_icode;
m_dstE = M_dstE;
m_dstM = M_dstM;   
m_valE = M_valE; 
m_valM = M_valA; 

########## Writeback #############
register mW {
	icode: 4 = NOP; #icode for nop 
	Stat: 3 = STAT_AOK; 
	dstE: 4 = REG_NONE; 
	dstM: 4 = REG_NONE; 
	valE: 64 = 0xBADBADBAD; 
	valM: 64 = 0xBADBADBAD; 
}

Stat = W_Stat; 

# destination selection
reg_dstE = [
	W_icode in {IRMOVQ, RRMOVQ, OPQ} : W_dstE;
	1 : REG_NONE;
];


reg_inputE = [ # unlike book, we handle the "forwarding" actions (something + 0) here
	W_icode == RRMOVQ : W_valE;
	W_icode in {IRMOVQ, OPQ} : W_valE;
        1: 0xBADBADBAD;
];


########## PC and Status updates #############

f_pc = f_valP;



