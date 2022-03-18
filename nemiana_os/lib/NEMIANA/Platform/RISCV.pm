#!/usr/bin/env perl
#
package NEMIANA::Platform::RISCV;
use strict;
use warnings;
use Carp 'verbose', 'croak';
use Data::Dumper;
use Exporter 'import';

our @EXPORT_OK = qw/ECALL/;

sub ECALL { return 0x73;}
sub INST_SIZE {return 4;}

my %op_dict;
my %rev_op_dict;
while(my $line=<DATA>){
    if($line=~/define\s+([\d\w_]+)\s+\d+\'d(\d+)/){
	$rev_op_dict{$1}=$2;
    }
    elsif($line=~/define\s+([\d\w_]+)\s+\d+\'b(\d+)/){
	$op_dict{oct('0b'.$2)}=$1;
	$rev_op_dict{$1}=oct('0b'.$2);
    }
}

sub get_rev_op_dict{
    my ($key) = @_;
    return $rev_op_dict{$key};
}

sub CONST_TYPE_J {return 2;}
sub CONST_ALU_OR {return 22;}
sub CONST_ALU_LH {return 10;}
sub CONST_JALR {return 103;}
sub CONST_ALU_LB {return 9;}
sub CONST_ENABLE {return 1;}
sub CONST_ALU_BEQ {return 3;}
sub CONST_TYPE_S {return 5;}
sub CONST_BRANCH {return 99;}
sub CONST_LUI {return 55;}
sub CONST_ALU_LBU {return 12;}
sub CONST_STORE {return 35;}
sub CONST_ALU_SRL {return 25;}
sub CONST_ALU_LHU {return 13;}
sub CONST_ALU_XOR {return 21;}
sub CONST_ALU_LW {return 11;}
sub CONST_OP_TYPE_NONE {return 0;}
sub CONST_OP_TYPE_IMM {return 2;}
sub CONST_ALU_SLL {return 24;}
sub CONST_OP {return 51;}
sub CONST_ALU_AND {return 23;}
sub CONST_ALU_SLTU {return 20;}
sub CONST_JAL {return 111;}
sub CONST_ALU_BNE {return 4;}
sub CONST_ALU_SUB {return 18;}
sub CONST_ALU_ADD {return 17;}
sub CONST_TYPE_R {return 6;}
sub CONST_ALU_BLT {return 5;}
sub CONST_ALU_LUI {return 0;}
sub CONST_ALU_SW {return 16;}
sub CONST_ALU_SRA {return 26;}
sub CONST_TYPE_U {return 1;}
sub CONST_OP_TYPE_PC {return 3;}
sub CONST_ALU_BGE {return 6;}
sub CONST_LOAD {return 3;}
sub CONST_ALU_NOP {return 63;}
sub CONST_ALU_BGEU {return 8;}
sub CONST_REG_RD {return 1;}
sub CONST_OPIMM {return 19;}
sub CONST_ALU_JALR {return 2;}
sub CONST_OP_TYPE_REG {return 1;}
sub CONST_DISABLE {return 0;}
sub CONST_ALU_JAL {return 1;}
sub CONST_ALU_SH {return 15;}
sub CONST_TYPE_B {return 4;}
sub CONST_AUIPC {return 23;}
sub CONST_ALU_SLT {return 19;}
sub CONST_ALU_SB {return 14;}
sub CONST_TYPE_I {return 3;}
sub CONST_REG_NONE {return 0;}
sub CONST_ALU_BLTU {return 7;}
sub CONST_TYPE_NONE {return 0;}
sub CONST_SYSTEM {return 0x73;}
sub CONST_ECALL {return 0x73;}

my %dict = (
    TYPE_J=>'2',
    ALU_OR=>'22',
    ALU_LH=>'10',
    JALR=>'103',
    ALU_LB=>'9',
    ENABLE=>'1',
    ALU_BEQ=>'3',
    TYPE_S=>'5',
    BRANCH=>'99',
    LUI=>'55',
    ALU_LBU=>'12',
    STORE=>'35',
    ALU_SRL=>'25',
    ALU_LHU=>'13',
    ALU_XOR=>'21',
    ALU_LW=>'11',
    OP_TYPE_NONE=>'0',
    OP_TYPE_IMM=>'2',
    ALU_SLL=>'24',
    OP=>'51',
    ALU_AND=>'23',
    ALU_SLTU=>'20',
    JAL=>'111',
    ALU_BNE=>'4',
    ALU_SUB=>'18',
    ALU_ADD=>'17',
    TYPE_R=>'6',
    ALU_BLT=>'5',
    ALU_LUI=>'0',
    ALU_SW=>'16',
    ALU_SRA=>'26',
    TYPE_U=>'1',
    OP_TYPE_PC=>'3',
    ALU_BGE=>'6',
    LOAD=>'3',
    ALU_NOP=>'63',
    ALU_BGEU=>'8',
    REG_RD=>'1',
    OPIMM=>'19',
    ALU_JALR=>'2',
    OP_TYPE_REG=>'1',
    DISABLE=>'0',
    ALU_JAL=>'1',
    ALU_SH=>'15',
    TYPE_B=>'4',
    AUIPC=>'23',
    ALU_SLT=>'19',
    ALU_SB=>'14',
    TYPE_I=>'3',
    REG_NONE=>'0',
    ALU_BLTU=>'7',
    TYPE_NONE=>'0'
    );

sub dict  {
    my ($key) = @_;
    return $dict{$key};
}

sub cut {
    my ($val, $from, $to) = @_;

    return (($val & ((1<<($from+1))-1))>>$to)
    
}

sub decode {
    my ($insn) =@_;
    my %attr;

    if(!defined $insn){
	return;
    }
    
    my $opcode =cut($insn,6,0);
    my $funct3 =cut($insn,14,12);
    my $funct5 =cut($insn,32,27);
    my $rd     =cut($insn, 11,7);
    my $store_imm   =(cut($insn, 31,25) << 5) + cut($insn, 11, 7);
    if($store_imm > 4096){
	print STDERR "cut($insn, 31,25):",cut($insn, 31,25),"\n";
	print STDERR "cut($insn, 17,7):",cut($insn, 11,7),"\n";
	die "error: $store_imm";
    }
    if($store_imm >(1<<11)){
	$store_imm = $store_imm - (1<<12);
    }
    $attr{'store_imm'} = $store_imm;
    my $store_imm2   = cut($insn, 31,20);
    if($store_imm2 >(1<<11)){
	$store_imm2 = $store_imm2 - (1<<12);
    }
    $attr{'store_imm2'} = $store_imm2;
    $attr{'load_imm1'} = cut($insn, 31, 12);
    
    my $dstreg_num=0;
    $attr{'opcode'} = $opcode;
    
    $attr{'rd'} = $rd;
    { ## dummy

#push case_exp:$opcode
            if(($opcode)==CONST_LUI){
                $attr{'alucode'}=CONST_ALU_LUI;
                $attr{'reg_we'}=CONST_ENABLE;
                $attr{'is_load'}=CONST_DISABLE;
                $attr{'is_store'}=CONST_DISABLE;
                $attr{'aluop1_type'}=CONST_OP_TYPE_NONE;
                $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                $attr{'op_type'}=CONST_TYPE_U;
                $attr{'dst_type'}=CONST_REG_RD;
            }
            elsif(($opcode)==CONST_AUIPC){
                $attr{'alucode'}=CONST_ALU_ADD;
                $attr{'reg_we'}=CONST_ENABLE;
                $attr{'is_load'}=CONST_DISABLE;
                $attr{'is_store'}=CONST_DISABLE;
                $attr{'aluop1_type'}=CONST_OP_TYPE_IMM;
                $attr{'aluop2_type'}=CONST_OP_TYPE_PC;
                $attr{'op_type'}=CONST_TYPE_U;
                $attr{'dst_type'}=CONST_REG_RD;
            }
            elsif(($opcode)==CONST_JAL){
                $attr{'alucode'}=CONST_ALU_JAL;
                $attr{'is_load'}=CONST_DISABLE;
                $attr{'is_store'}=CONST_DISABLE;
                $attr{'aluop1_type'}=CONST_OP_TYPE_NONE;
                $attr{'aluop2_type'}=CONST_OP_TYPE_PC;
                $attr{'op_type'}=CONST_TYPE_J;
                $attr{'dst_type'}=CONST_REG_RD;
#push case_exp:$dstreg_num,$opcode
                    if(($dstreg_num)==0){
                        $attr{'reg_we'}=CONST_DISABLE;
                    }
                    else{
                        $attr{'reg_we'}=CONST_ENABLE;
                    }
#pop case_exp:$opcode
            }
            elsif(($opcode)==CONST_JALR){
                $attr{'alucode'}=CONST_ALU_JALR;
                $attr{'reg_we'}=CONST_ENABLE;
                $attr{'is_load'}=CONST_DISABLE;
                $attr{'is_store'}=CONST_DISABLE;
                $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                $attr{'aluop2_type'}=CONST_OP_TYPE_PC;
                $attr{'op_type'}=CONST_TYPE_I;
                $attr{'dst_type'}=CONST_REG_RD;
#push case_exp:$dstreg_num,$opcode
                    if(($dstreg_num)==0){
                        $attr{'reg_we'}=CONST_DISABLE;
                    }
                    else{
                        $attr{'reg_we'}=CONST_ENABLE;
                    }
#pop case_exp:$opcode
            }
            elsif(($opcode)==CONST_BRANCH){
#push case_exp:$funct3,$opcode
                    if(($funct3)==0){
                        $attr{'alucode'}=CONST_ALU_BEQ;
                        $attr{'reg_we'}=CONST_DISABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                        $attr{'op_type'}=CONST_TYPE_B;
                        $attr{'dst_type'}=CONST_REG_NONE;
                    }
                    elsif(($funct3)==1){
                        $attr{'alucode'}=CONST_ALU_BNE;
                        $attr{'reg_we'}=CONST_DISABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                        $attr{'op_type'}=CONST_TYPE_B;
                        $attr{'dst_type'}=CONST_REG_NONE;
                    }
                    elsif(($funct3)==4){
                        $attr{'alucode'}=CONST_ALU_BLT;
                        $attr{'reg_we'}=CONST_DISABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                        $attr{'op_type'}=CONST_TYPE_B;
                        $attr{'dst_type'}=CONST_REG_NONE;
                    }
                    elsif(($funct3)==5){
                        $attr{'alucode'}=CONST_ALU_BGE;
                        $attr{'reg_we'}=CONST_DISABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                        $attr{'op_type'}=CONST_TYPE_B;
                        $attr{'dst_type'}=CONST_REG_NONE;
                    }
                    elsif(($funct3)==6){
                        $attr{'alucode'}=CONST_ALU_BLTU;
                        $attr{'reg_we'}=CONST_DISABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                        $attr{'op_type'}=CONST_TYPE_B;
                        $attr{'dst_type'}=CONST_REG_NONE;
                    }
                    elsif(($funct3)==7){
                        $attr{'alucode'}=CONST_ALU_BGEU;
                        $attr{'reg_we'}=CONST_DISABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                        $attr{'op_type'}=CONST_TYPE_B;
                        $attr{'dst_type'}=CONST_REG_NONE;
                    }
                    else{
                        $attr{'alucode'}=CONST_ALU_NOP;
                        $attr{'reg_we'}=CONST_DISABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_NONE;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_NONE;
                        $attr{'op_type'}=CONST_TYPE_NONE;
                        $attr{'dst_type'}=CONST_REG_NONE;
                    }
#pop case_exp:$opcode
            }
            elsif(($opcode)==CONST_LOAD){
#push case_exp:$funct3,$opcode
                    if(($funct3)==0){
                        $attr{'alucode'}=CONST_ALU_LB;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_ENABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_I;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==1){
                        $attr{'alucode'}=CONST_ALU_LH;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_ENABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_I;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==2){
                        $attr{'alucode'}=CONST_ALU_LW;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_ENABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_I;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==4){
                        $attr{'alucode'}=CONST_ALU_LBU;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_ENABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_I;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==5){
                        $attr{'alucode'}=CONST_ALU_LHU;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_ENABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_I;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    else{
                        $attr{'alucode'}=CONST_ALU_NOP;
                        $attr{'reg_we'}=CONST_DISABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_NONE;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_NONE;
                        $attr{'op_type'}=CONST_TYPE_NONE;
                        $attr{'dst_type'}=CONST_REG_NONE;
                    }
#pop case_exp:$opcode
            }
            elsif(($opcode)==CONST_STORE){
#push case_exp:$funct3,$opcode
                    if(($funct3)==0){
                        $attr{'alucode'}=CONST_ALU_SB;
                        $attr{'reg_we'}=CONST_DISABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_ENABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_S;
                        $attr{'dst_type'}=CONST_REG_NONE;
                    }
                    elsif(($funct3)==1){
                        $attr{'alucode'}=CONST_ALU_SH;
                        $attr{'reg_we'}=CONST_DISABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_ENABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_S;
                        $attr{'dst_type'}=CONST_REG_NONE;
                    }
                    elsif(($funct3)==2){
                        $attr{'alucode'}=CONST_ALU_SW;
                        $attr{'reg_we'}=CONST_DISABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_ENABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_S;
                        $attr{'dst_type'}=CONST_REG_NONE;
                    }
                    else{
                        $attr{'alucode'}=CONST_ALU_NOP;
                        $attr{'reg_we'}=CONST_DISABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_NONE;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_NONE;
                        $attr{'op_type'}=CONST_TYPE_NONE;
                        $attr{'dst_type'}=CONST_REG_NONE;
                    }
#pop case_exp:$opcode
            }                             
            elsif(($opcode)==CONST_OPIMM){
#push case_exp:$funct3,$opcode
                    if(($funct3)==0){
                        $attr{'alucode'}=CONST_ALU_ADD;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_I;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==2){
                        $attr{'alucode'}=CONST_ALU_SLT;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_I;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==3){
                        $attr{'alucode'}=CONST_ALU_SLTU;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_I;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==4){
                        $attr{'alucode'}=CONST_ALU_XOR;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_I;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==6){
                        $attr{'alucode'}=CONST_ALU_OR;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_I;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==7){
                        $attr{'alucode'}=CONST_ALU_AND;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_I;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==1){
                        $attr{'alucode'}=CONST_ALU_SLL;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                        $attr{'op_type'}=CONST_TYPE_I;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==5){
#push case_exp:cut($funct5,3,3),$funct3,$opcode
                            if((cut($funct5,3,3))==0){
                                $attr{'alucode'}=CONST_ALU_SRL;
                                $attr{'reg_we'}=CONST_ENABLE;
                                $attr{'is_load'}=CONST_DISABLE;
                                $attr{'is_store'}=CONST_DISABLE;
                                $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                                $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                                $attr{'op_type'}=CONST_TYPE_I;
                                $attr{'dst_type'}=CONST_REG_RD;
                            }
                            elsif((cut($funct5,3,3))==1){
                                $attr{'alucode'}=CONST_ALU_SRA;
                                $attr{'reg_we'}=CONST_ENABLE;
                                $attr{'is_load'}=CONST_DISABLE;
                                $attr{'is_store'}=CONST_DISABLE;
                                $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                                $attr{'aluop2_type'}=CONST_OP_TYPE_IMM;
                                $attr{'op_type'}=CONST_TYPE_I;
                                $attr{'dst_type'}=CONST_REG_RD;
                            }
#pop case_exp:$funct3,$opcode
                    }
#pop case_exp:$opcode
            }
            elsif(($opcode)==CONST_OP){
#push case_exp:$funct3,$opcode
                    if(($funct3)==0){
#push case_exp:cut($funct5,3,3),$funct3,$opcode
                            if((cut($funct5,3,3))==0){
                                $attr{'alucode'}=CONST_ALU_ADD;
                                $attr{'reg_we'}=CONST_ENABLE;
                                $attr{'is_load'}=CONST_DISABLE;
                                $attr{'is_store'}=CONST_DISABLE;
                                $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                                $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                                $attr{'op_type'}=CONST_TYPE_R;
                                $attr{'dst_type'}=CONST_REG_RD;
                            }
                            elsif((cut($funct5,3,3))==1){
                                $attr{'alucode'}=CONST_ALU_SUB;
                                $attr{'reg_we'}=CONST_ENABLE;
                                $attr{'is_load'}=CONST_DISABLE;
                                $attr{'is_store'}=CONST_DISABLE;
                                $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                                $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                                $attr{'op_type'}=CONST_TYPE_R;
                                $attr{'dst_type'}=CONST_REG_RD;
                            }
#pop case_exp:$funct3,$opcode
                    }
                    elsif(($funct3)==1){
                        $attr{'alucode'}=CONST_ALU_SLL;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                        $attr{'op_type'}=CONST_TYPE_R;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==2){
                        $attr{'alucode'}=CONST_ALU_SLT;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                        $attr{'op_type'}=CONST_TYPE_R;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }                                
                    elsif(($funct3)==3){
                        $attr{'alucode'}=CONST_ALU_SLTU;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                        $attr{'op_type'}=CONST_TYPE_R;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==4){
                        $attr{'alucode'}=CONST_ALU_XOR;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                        $attr{'op_type'}=CONST_TYPE_R;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==5){
#push case_exp:cut($funct5,3,3),$funct3,$opcode
                            if((cut($funct5,3,3))==0){
                                $attr{'alucode'}=CONST_ALU_SRL;
                                $attr{'reg_we'}=CONST_ENABLE;
                                $attr{'is_load'}=CONST_DISABLE;
                                $attr{'is_store'}=CONST_DISABLE;
                                $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                                $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                                $attr{'op_type'}=CONST_TYPE_R;
                                $attr{'dst_type'}=CONST_REG_RD;
                            }
                            elsif((cut($funct5,3,3))==1){
                                $attr{'alucode'}=CONST_ALU_SRA;
                                $attr{'reg_we'}=CONST_ENABLE;
                                $attr{'is_load'}=CONST_DISABLE;
                                $attr{'is_store'}=CONST_DISABLE;
                                $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                                $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                                $attr{'op_type'}=CONST_TYPE_R;
                                $attr{'dst_type'}=CONST_REG_RD;
                            }
#pop case_exp:$funct3,$opcode
                    }
                    elsif(($funct3)==6){
                        $attr{'alucode'}=CONST_ALU_OR;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                        $attr{'op_type'}=CONST_TYPE_R;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
                    elsif(($funct3)==7){
                        $attr{'alucode'}=CONST_ALU_AND;
                        $attr{'reg_we'}=CONST_ENABLE;
                        $attr{'is_load'}=CONST_DISABLE;
                        $attr{'is_store'}=CONST_DISABLE;
                        $attr{'aluop1_type'}=CONST_OP_TYPE_REG;
                        $attr{'aluop2_type'}=CONST_OP_TYPE_REG;
                        $attr{'op_type'}=CONST_TYPE_R;
                        $attr{'dst_type'}=CONST_REG_RD;
                    }
#pop case_exp:$opcode
            }
            elsif(($opcode)==CONST_SYSTEM){
                $attr{'alucode'}=$funct3;
                $attr{'reg_we'}=CONST_DISABLE;
                $attr{'is_load'}=CONST_DISABLE;
                $attr{'is_store'}=CONST_DISABLE;
                $attr{'aluop1_type'}=CONST_OP_TYPE_NONE;
                $attr{'aluop2_type'}=CONST_OP_TYPE_NONE;
                $attr{'op_type'}=CONST_TYPE_I;
                $attr{'dst_type'}=CONST_REG_RD;
	    }
	    else{
                $attr{'alucode'}=CONST_ALU_NOP;
                $attr{'reg_we'}=CONST_DISABLE;
                $attr{'is_load'}=CONST_DISABLE;
                $attr{'is_store'}=CONST_DISABLE;
                $attr{'aluop1_type'}=CONST_OP_TYPE_NONE;
                $attr{'aluop2_type'}=CONST_OP_TYPE_NONE;
                $attr{'op_type'}=CONST_TYPE_NONE;
                $attr{'dst_type'}=CONST_REG_NONE;
            }
#pop case_exp:
    }
    $attr{'srcreg1_num'} = ($attr{'op_type'} == CONST_TYPE_U || $attr{'op_type'} == CONST_TYPE_J) ? 0 : cut($insn,19,15);
    $attr{'srcreg2_num'} = ($attr{'op_type'} == CONST_TYPE_U || $attr{'op_type'} == CONST_TYPE_J || $attr{'op_type'} == CONST_TYPE_I) ? 0 : cut($insn, 24,20);
    $attr{'dstreg_num'}  = ($attr{'dst_type'} == CONST_REG_RD) ? $rd : 0;

    if(($attr{'alucode'}==CONST_ALU_JAL) or 
       ($attr{'alucode'}==CONST_ALU_JALR)){
	if($attr{'dstreg_num'}==0){
	    $attr{'reg_we'} = CONST_DISABLE;
	}
	else{
	    $attr{'reg_we'} = CONST_ENABLE;
	}
    }

    return \%attr;
}

sub new {
    my ($class, $binary, $profile) = @_;

    my $self={};
    
    bless $self, $class;

    $self->{binary} = $binary;
    $self->{profile}= $profile;
    $self->{reg_size}  = $profile->{platform}->{regsize};
    $self->{ram} = $profile->{platform}->{ram};
    $self->{inst_size} = INST_SIZE;
    return $self;
}

sub is_writable {
    my ($self, $addr) = @_;
    return ($addr >= $self->{ram}->{start}) &&($addr <=$self->{ram}->{end});
}


sub get_pc {
    my ($self, $regfile) = @_;

    if(ref $regfile eq 'ARRAY'){
	my $pc = $regfile->[$self->{reg_size}];
	return $pc;
    }
    else{
	my $pc = $regfile->{$self->{reg_size}};
	return $pc;
    }
}

sub get_inst_code {
    my ($self, $addr) = @_;
    if(!exists $self->{binary}->{$addr}){
	print STDERR sprintf("Not Found%08x", $addr);
	croak("ERROR $addr!");
    }
    my $res = $self->{binary}->{$addr};
    $res += $self->{binary}->{$addr+1} <<8;
    $res += $self->{binary}->{$addr+2} <<16;
    $res += $self->{binary}->{$addr+3} <<24;

    return $res;
}

sub get_current_inst_code {
    my ($self, $processor) = @_;

    my $regfile = $processor->get_register_all();
    my $pc = $self->get_pc($regfile);
    my $inst_code = $self->get_inst_code($pc);
}


sub convert_str {
    my ($self, $current_pc, $next_reg, $count) = @_;
    
    my $next_pc = $next_reg->[$self->{reg_size}];
    my $inst_code = $self->get_inst_code($current_pc);
    my $res = read_trace_one_line_sub($current_pc, $inst_code, $next_reg, $next_pc,
				      $count, $self->{reg_size});
    return ($res, $next_pc);
}

sub read_trace_one_line_sub{
    my ($last_pc, $inst_code, $next_reg, $nextpc, $count, $reg_size) =@_;
    my $pc_num = $reg_size;
    
    my $inst_attr = decode($inst_code);

    my %str;
    $str{count}=$count;
    $str{reg}->{$pc_num}= $nextpc;
    
    $str{type}="unsuport:" . $inst_attr->{opcode};
    if($inst_attr->{opcode} == get_rev_op_dict('LOAD')){
	$str{type}  = 'load';
	if($inst_attr->{alucode} != get_rev_op_dict('ALU_NOP')){
	    my $value = $next_reg->[$inst_attr->{'dstreg_num'}];
	    $str{reg}->{$inst_attr->{'dstreg_num'}} = $value;
	    ## Load命令は'I-Type' format
	    my $addr =$next_reg->[$inst_attr->{'srcreg1_num'}] +  $inst_attr->{'store_imm2'};
	    if($inst_attr->{alucode} == get_rev_op_dict('ALU_LB')){
		$str{memory}{$addr} = $value & 0xff;
	    }
	    elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_LBU')){
		$str{memory}->{$addr} = $value & 0xff;
	    }
	    elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_LH')){
		$str{memory}->{$addr}   = $value & 0xff;
		$str{memory}->{$addr+1} = ($value>>8) & 0xff;
	    }
	    elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_LHU')){
		$str{memory}->{$addr}   = $value & 0xff;
		$str{memory}->{$addr+1} = ($value>>8) & 0xff;
	    }
	    else{
		$str{memory}->{$addr}   = $value       & 0xff;
		$str{memory}->{$addr+1} = ($value>>8)  & 0xff;
		$str{memory}->{$addr+2} = ($value>>16) & 0xff;
		$str{memory}->{$addr+3} = ($value>>24) & 0xff;
	    }
	}
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('LUI')){
	$str{type} = 'load';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = $next_reg->[$inst_attr->{'dstreg_num'}];
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('AUIPC')){
	$str{type} = 'load';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = $next_reg->[$inst_attr->{'dstreg_num'}];
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('STORE')){
	$str{type} = 'store';

	my $value = $next_reg->[$inst_attr->{'srcreg2_num'}];
	my $addr =$next_reg->[$inst_attr->{'srcreg1_num'}] +  $inst_attr->{'store_imm'};
	if($inst_attr->{alucode} == get_rev_op_dict('ALU_SB')){
	    $str{memory}->{$addr} = $value & 0xff;
	}
	elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_SH')){
	    $str{memory}->{$addr}   = $value & 0xff;
	    $str{memory}->{$addr+1} = ($value>>8) & 0xff;
	}
	else{
	    $str{memory}->{$addr}   = $value       & 0xff;
	    $str{memory}->{$addr+1} = ($value>>8)  & 0xff;
	    $str{memory}->{$addr+2} = ($value>>16) & 0xff;
	    $str{memory}->{$addr+3} = ($value>>24) & 0xff;
	}
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('JAL')){
	$str{type} = 'jal';
	$str{reg}->{$pc_num}=$nextpc;
	$str{reg}->{$inst_attr->{'dstreg_num'}}=$last_pc+4;
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('JALR')){
	$str{type} = 'jalr';
	$str{reg}->{$pc_num}=$nextpc;
	$str{reg}->{$inst_attr->{'dstreg_num'}}=$last_pc+4;
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('BRANCH')){
	$str{type} = 'branch';
	$str{reg}->{$pc_num}=$nextpc;
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('OPIMM')){
	$str{type}  = 'opimm';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = $next_reg->[$inst_attr->{'dstreg_num'}];
	if(!defined $next_reg->[$inst_attr->{'dstreg_num'}]){
	    print STDERR "undef:", $inst_attr->{'dstreg_num'},":", Dumper $next_reg, "\n";;
	}
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('OP')){
	$str{type}  = 'op';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = $next_reg->[$inst_attr->{'dstreg_num'}];
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('SYSTEM')){
	if($inst_code eq ECALL){
	    $str{'type'}  = 'ecall';
	}
	elsif($inst_attr->{alucode}  eq get_rev_op_dict('CSRRW')){
	    $str{'type'}='csrrw';
	    $str{reg}->{$inst_attr->{'dstreg_num'}} = $next_reg->[$inst_attr->{'dstreg_num'}]
	}
	else{
	    $str{'type'}  = 'SYSTEM';
	}
    }
    else{
	$str{'type'}='unknown';
    }
    return \%str;
}

sub get_next_str{
    my ($self, $processor, $count) =@_;

    my %reg = %{$processor->get_register_all()};
    $reg{0} =0;
    my $reg_value = \%reg;
    my $pc = $reg_value->{$self->{reg_size}};
    my $inst_code = $self->get_current_inst_code($processor);
    my $inst_attr = decode($inst_code);

#    print STDERR sprintf("inst:%08X, inst_attr=%s", $inst_code, Dumper $inst_attr);
    
    my %str;
    $str{count}=$count;
    $str{reg}->{$self->{reg_size}}= undef;
    
    $str{type}="unsuport:" . $inst_attr->{opcode};
    if($inst_attr->{opcode} == get_rev_op_dict('LOAD')){
	$str{type}  = 'load';
	if($inst_attr->{alucode} != get_rev_op_dict('ALU_NOP')){
	    $str{reg}->{$inst_attr->{'dstreg_num'}} = undef;
	    ## Load命令は'I-Type' format
	    my $addr =$reg_value->{$inst_attr->{'srcreg1_num'}} +  $inst_attr->{'store_imm2'};
	    if($inst_attr->{alucode} == get_rev_op_dict('ALU_LB')){
		$str{load_memory}{$addr} = undef;
	    }
	    elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_LBU')){
		$str{load_memory}->{$addr} = undef;
	    }
	    elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_LH')){
		$str{load_memory}->{$addr}   = undef;
		$str{load_memory}->{$addr+1} = undef;
	    }
	    elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_LHU')){
		$str{load_memory}->{$addr}   = undef;
		$str{load_memory}->{$addr+1} = undef;
	    }
	    else{
		$str{load_memory}->{$addr}   = undef;
		$str{load_memory}->{$addr+1} = undef;
		$str{load_memory}->{$addr+2} = undef;
		$str{load_memory}->{$addr+3} = undef;
	    }
	}
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('LUI')){
	$str{type} = 'load';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = $inst_attr->{load_imm1}<<12;
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('AUIPC')){
	$str{type} = 'load';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = $pc + $inst_attr->{load_imm1};
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('STORE')){
	$str{type} = 'store';

	my $value = $reg_value->{$inst_attr->{'srcreg2_num'}};
	my $addr  = $reg_value->{$inst_attr->{'srcreg1_num'}} +  $inst_attr->{'store_imm'};
	if($inst_attr->{alucode} == get_rev_op_dict('ALU_SB')){
	    $str{memory}->{$addr} = $value & 0xff;
	}
	elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_SH')){
	    $str{memory}->{$addr}   = $value & 0xff;
	    $str{memory}->{$addr+1} = ($value>>8) & 0xff;
	}
	else{
	    $str{memory}->{$addr}   = $value       & 0xff;
	    $str{memory}->{$addr+1} = ($value>>8)  & 0xff;
	    $str{memory}->{$addr+2} = ($value>>16) & 0xff;
	    $str{memory}->{$addr+3} = ($value>>24) & 0xff;
	}
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('JAL')){
	$str{type} = 'jal';
	$str{reg}->{$self->{reg_size}}=undef;
	$str{reg}->{$inst_attr->{'dstreg_num'}}=$pc+4;
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('JALR')){
	$str{type} = 'jalr';
	$str{reg}->{$self->{reg_size}}=undef;
	$str{reg}->{$inst_attr->{'dstreg_num'}}=$pc + 4;
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('BRANCH')){
	$str{type} = 'branch';
	$str{reg}->{$self->{reg_size}}=undef;
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('OPIMM')){
	$str{type}  = 'opimm';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = undef;
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('OP')){
	$str{type}  = 'op';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = undef;
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('SYSTEM')){
	if($inst_code eq ECALL){
	    $str{'type'}  = 'ecall';
	}
	elsif($inst_attr->{alucode}  eq get_rev_op_dict('CSRRW')){
	    $str{'type'}='csrrw';
	    $str{reg}->{$inst_attr->{'dstreg_num'}} = undef;
	}
	else{
	    $str{'type'}  = 'SYSTEM';
	}
    }
    else{
	$str{'type'}='unknown';
    }

    if(wantarray){
	return (\%str, $inst_attr);
    }
    else{
	return \%str;
    }
}

sub conv_str{
    my ($last_pc, $inst_code, $next_reg, $nextpc, $count, $reg_size) =@_;
    my $pc_num = $reg_size;
    
    my $inst_attr = decode($inst_code);

    my %str;
    $str{count}=$count;
    $str{reg}->{$pc_num}= $nextpc;
    
    $str{type}="unsuport:" . $inst_attr->{opcode};
    if($inst_attr->{opcode} == get_rev_op_dict('LOAD')){
	$str{type}  = 'load';
	if($inst_attr->{alucode} != get_rev_op_dict('ALU_NOP')){
	    my $value = $next_reg->[$inst_attr->{'dstreg_num'}];
	    $str{reg}->{$inst_attr->{'dstreg_num'}} = $value;
	    ## Load命令は'I-Type' format
	    my $addr =$next_reg->[$inst_attr->{'srcreg1_num'}] +  $inst_attr->{'store_imm2'};
	    if($inst_attr->{alucode} == get_rev_op_dict('ALU_LB')){
		$str{memory}{$addr} = $value & 0xff;
	    }
	    elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_LBU')){
		$str{memory}->{$addr} = $value & 0xff;
	    }
	    elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_LH')){
		$str{memory}->{$addr}   = $value & 0xff;
		$str{memory}->{$addr+1} = ($value>>8) & 0xff;
	    }
	    elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_LHU')){
		$str{memory}->{$addr}   = $value & 0xff;
		$str{memory}->{$addr+1} = ($value>>8) & 0xff;
	    }
	    else{
		$str{memory}->{$addr}   = $value       & 0xff;
		$str{memory}->{$addr+1} = ($value>>8)  & 0xff;
		$str{memory}->{$addr+2} = ($value>>16) & 0xff;
		$str{memory}->{$addr+3} = ($value>>24) & 0xff;
	    }
	}
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('LUI')){
	$str{type} = 'load';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = $next_reg->[$inst_attr->{'dstreg_num'}];
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('AUIPC')){
	$str{type} = 'load';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = $next_reg->[$inst_attr->{'dstreg_num'}];
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('STORE')){
	$str{type} = 'store';

	my $value = $next_reg->[$inst_attr->{'srcreg2_num'}];
	my $addr =$next_reg->[$inst_attr->{'srcreg1_num'}] +  $inst_attr->{'store_imm'};
	if($inst_attr->{alucode} == get_rev_op_dict('ALU_SB')){
	    $str{memory}->{$addr} = $value & 0xff;
	}
	elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_SH')){
	    $str{memory}->{$addr}   = $value & 0xff;
	    $str{memory}->{$addr+1} = ($value>>8) & 0xff;
	}
	else{
	    $str{memory}->{$addr}   = $value       & 0xff;
	    $str{memory}->{$addr+1} = ($value>>8)  & 0xff;
	    $str{memory}->{$addr+2} = ($value>>16) & 0xff;
	    $str{memory}->{$addr+3} = ($value>>24) & 0xff;
	}
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('JAL')){
	$str{type} = 'jal';
	$str{reg}->{$pc_num}=$nextpc;
	$str{reg}->{$inst_attr->{'dstreg_num'}}=$last_pc+4;
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('JALR')){
	$str{type} = 'jalr';
	$str{reg}->{$pc_num}=$nextpc;
	$str{reg}->{$inst_attr->{'dstreg_num'}}=$last_pc+4;
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('BRANCH')){
	$str{type} = 'branch';
	$str{reg}->{$pc_num}=$nextpc;
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('OPIMM')){
	$str{type}  = 'opimm';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = $next_reg->[$inst_attr->{'dstreg_num'}];
	if(!defined $next_reg->[$inst_attr->{'dstreg_num'}]){
	    print STDERR "undef:", $inst_attr->{'dstreg_num'},":", Dumper $next_reg, "\n";;
	}
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('OP')){
	$str{type}  = 'op';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = $next_reg->[$inst_attr->{'dstreg_num'}];
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('SYSTEM')){
	if($inst_code eq ECALL){
	    $str{'type'}  = 'ecall';
	}
	elsif($inst_attr->{alucode}  eq get_rev_op_dict('CSRRW')){
	    $str{'type'}='csrrw';
	    $str{reg}->{$inst_attr->{'dstreg_num'}} = $next_reg->[$inst_attr->{'dstreg_num'}]
	}
	else{
	    $str{'type'}  = 'SYSTEM';
	}
    }
    else{
	$str{'type'}='unknown';
    }
    return \%str;
}


sub is_system_call {
    my ($self, $inst_code) = @_;

    if($inst_code eq ECALL){
	return 1;
    }else{
	return;
    }
}


sub gen_str_from_trace{
    my ($self, $processor, $trace_info, $count) = @_;

    my %str;

    my $last_pc = $trace_info->{pc};
    my $next_pc = $last_pc + 4;  ## for RISC-V 32bit
    $str{count}=$count;
    my $pc_num = $self->{reg_size}; ## for RISC-V
    $str{reg}->{$pc_num}= $next_pc;
    my $inst_code = $trace_info->{inst};
    my $inst_attr = decode($inst_code);
    $str{type}="unsuport:" . $inst_attr->{opcode};
    
    if($inst_attr->{opcode} == get_rev_op_dict('LOAD')){
	$str{type}  = 'load';
	if($inst_attr->{alucode} != get_rev_op_dict('ALU_NOP')){
	    my $value = $trace_info->{dest};
	    $str{reg}->{$inst_attr->{'dstreg_num'}} = $value;
	    ## Load命令は'I-Type' format
	    ## 未対応(srcreg1_numではなくてその値とたさないといけない)
	    ##  20211228 : src でダイジョブ？
	    my $addr = $trace_info->{src};
	    if($inst_attr->{alucode} == get_rev_op_dict('ALU_LB')){
		$str{memory}{$addr} = $value & 0xff;
	    }
	    elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_LBU')){
		$str{memory}->{$addr} = $value & 0xff;
	    }
	    elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_LH')){
		$str{memory}->{$addr}   = $value & 0xff;
		$str{memory}->{$addr+1} = ($value>>8) & 0xff;
	    }
	    elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_LHU')){
		$str{memory}->{$addr}   = $value & 0xff;
		$str{memory}->{$addr+1} = ($value>>8) & 0xff;
	    }
	    else{
		$str{memory}->{$addr}   = $value       & 0xff;
		$str{memory}->{$addr+1} = ($value>>8)  & 0xff;
		$str{memory}->{$addr+2} = ($value>>16) & 0xff;
		$str{memory}->{$addr+3} = ($value>>24) & 0xff;
	    }
	}
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('LUI')){
	$str{type} = 'load';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = $trace_info->{dest};
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('AUIPC')){
	$str{type} = 'load';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = $trace_info->{dest};
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('STORE')){
	$str{type} = 'store';

	my $value = $trace_info->{src};
	my $addr  = $trace_info->{dest};
	if($inst_attr->{alucode} == get_rev_op_dict('ALU_SB')){
	    $str{memory}->{$addr} = $value & 0xff;
	}
	elsif($inst_attr->{alucode} == get_rev_op_dict('ALU_SH')){
	    $str{memory}->{$addr}   = $value & 0xff;
	    $str{memory}->{$addr+1} = ($value>>8) & 0xff;
	}
	else{
	    $str{memory}->{$addr}   = $value       & 0xff;
	    $str{memory}->{$addr+1} = ($value>>8)  & 0xff;
	    $str{memory}->{$addr+2} = ($value>>16) & 0xff;
	    $str{memory}->{$addr+3} = ($value>>24) & 0xff;
	}
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('JAL')){
	$str{type} = 'jal';
	$str{reg}->{$pc_num}=$trace_info->{dest};
	$str{reg}->{$inst_attr->{'dstreg_num'}}=$last_pc+4;
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('JALR')){
	$str{type} = 'jalr';
	$str{reg}->{$pc_num}=$trace_info->{dest};
	$str{reg}->{$inst_attr->{'dstreg_num'}}=$last_pc+4;
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('BRANCH')){
	$str{type} = 'branch';
	$str{reg}->{$pc_num}=$trace_info->{dest};
	my $reg_num = $inst_attr->{'dstreg_num'};
	my $value =$trace_info->{dest};
	print STDERR "BRANCH:$reg_num, $value\n";
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('OPIMM')){
	$str{type}  = 'opimm';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = $trace_info->{dest};
	my $reg_num = $inst_attr->{'dstreg_num'};
	my $value =$trace_info->{dest};
	print STDERR "OPIMM:$reg_num, $value\n";
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('OP')){
	$str{type}  = 'op';
	$str{reg}->{$inst_attr->{'dstreg_num'}} = $trace_info->{dest};
	my $reg_num = $inst_attr->{'dstreg_num'};
	my $value =$trace_info->{dest};
	print STDERR "OP:$reg_num, $value\n";
    }
    elsif($inst_attr->{opcode} == get_rev_op_dict('SYSTEM')){
	if($inst_code eq ECALL){
	    $str{'type'}  = 'ecall';
	}
	elsif($inst_attr->{alucode}  eq get_rev_op_dict('CSRRW')){
	    $str{'type'}='csrrw';
	    $str{reg}->{$inst_attr->{'dstreg_num'}} = $trace_info->{dest};
	}
	else{
	    $str{'type'}  = 'SYSTEM';
	}
    }
    else{
	$str{'type'}='unknown';
    }

    return \%str;
}


1;

__DATA__
`define LUI    7'b0110111
`define AUIPC  7'b0010111
`define JAL    7'b1101111
`define JALR   7'b1100111
`define BRANCH 7'b1100011
`define LOAD   7'b0000011
`define STORE  7'b0100011
`define OPIMM  7'b0010011
`define OP     7'b0110011
`define SYSTEM 7'b1110011

`define ALU_LUI   6'd0
`define ALU_JAL   6'd1
`define ALU_JALR  6'd2
`define ALU_BEQ   6'd3
`define ALU_BNE   6'd4
`define ALU_BLT   6'd5
`define ALU_BGE   6'd6
`define ALU_BLTU  6'd7
`define ALU_BGEU  6'd8
`define ALU_LB    6'd9
`define ALU_LH    6'd10
`define ALU_LW    6'd11
`define ALU_LBU   6'd12
`define ALU_LHU   6'd13
`define ALU_SB    6'd14
`define ALU_SH    6'd15
`define ALU_SW    6'd16
`define ALU_ADD   6'd17
`define ALU_SUB   6'd18
`define ALU_SLT   6'd19
`define ALU_SLTU  6'd20
`define ALU_XOR   6'd21
`define ALU_OR    6'd22
`define ALU_AND   6'd23
`define ALU_SLL   6'd24
`define ALU_SRL   6'd25
`define ALU_SRA   6'd26
`define ALU_NOP   6'd63
`define CSRRW     6'd2
