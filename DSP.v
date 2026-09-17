module DSP(A,B,C,D,
         clk,CARRYIN,
         OPMODE,BCIN,RSTA,RSTB,RSTC,RSTD,RSTP,RSTM,RSTCARRYIN,RSTOPMODE,
         CEA,CEB,CEC,CED,CEP,CEM,CECARRYIN,CEOPMODE,
         PCIN,BCOUT,POUT,
         P,M,CARRYOUT,CARRYOUTF);
/*
parameters for DSP48A1
*/
parameter A0REG=0;
parameter A1REG=1;
parameter B0REG=0;
parameter B1REG=1;

parameter CREG=1;
parameter DREG=1;
parameter MREG=1;
parameter PREG=1;
parameter CARRYINREG=1;
parameter CARRYOUTREG=1;
parameter OPMODEREG=1;
parameter CARRYINSEL="OPMODE[5]";//or "CARRYIN"
parameter B_INPUT="DIRECT";//or "CASCADE"
parameter RSTTYPE="SYNC";//or "ASYNC"

/*
Inputs for DSP48A1
*/

input [17:0] A;
input [17:0] B;
input [17:0] BCIN;
input [47:0] C;
input [17:0] D;
input CARRYIN;
input clk;
input [7:0] OPMODE;
input CEA,CEB,CEC,CED,CEP,CEM,CECARRYIN,CEOPMODE;
input RSTA,RSTB,RSTC,RSTD,RSTP,RSTM,RSTCARRYIN,RSTOPMODE;
input [47:0] PCIN;

/*
Outputs for DSP48A1
*/
output  [35:0] M;
output [47:0] P;
output CARRYOUT;
output CARRYOUTF;
output [47:0] POUT;
output [17:0] BCOUT;


//PART1: REGs for A,B,C,D,OPMODE
//Opmode reg
wire [7:0] OPMODE_reg;
REG_pipe #(.width(8),.REG_EN(OPMODEREG),.REG_type(RSTTYPE)) OPMODE_REG(.D(OPMODE),.Q(OPMODE_reg),.rst(RSTOPMODE),.clk(clk),.CE(CEOPMODE));

//B input mux
wire [17:0] B_Cascade;
generate 
    if(B_INPUT=="DIRECT") begin
        assign B_Cascade = B;
    end
    else if(B_INPUT=="CASCADE") begin
        assign B_Cascade = BCIN;
    end
    else begin
        assign B_Cascade = 18'b0;
    end
endgenerate

//Regs for A,B,C,D
wire [17:0] A0_reg,B0_reg,D0_reg;
wire [47:0] C0_reg;

REG_pipe #(.width(18),.REG_EN(A0REG),.REG_type(RSTTYPE)) A0_REG(.D(A),.Q(A0_reg),.rst(RSTA),.clk(clk),.CE(CEA));
REG_pipe #(.width(18),.REG_EN(B0REG),.REG_type(RSTTYPE)) B0_REG(.D(B_Cascade),.Q(B0_reg),.rst(RSTB),.clk(clk),.CE(CEB));
REG_pipe #(.width(18),.REG_EN(DREG),.REG_type(RSTTYPE)) D0_REG(.D(D),.Q(D0_reg),.rst(RSTD),.clk(clk),.CE(CED));
REG_pipe #(.width(48),.REG_EN(CREG),.REG_type(RSTTYPE)) C0_REG(.D(C),.Q(C0_reg),.rst(RSTC),.clk(clk),.CE(CEC));


//Pre_ADDER/SUBTRACTOR

wire [17:0] pre_adder_out;
assign pre_adder_out = OPMODE_reg[6] ? (D0_reg - B0_reg) : (D0_reg + B0_reg);

wire [17:0] pre_adder_out_mux;
assign pre_adder_out_mux = OPMODE_reg[4] ? pre_adder_out:B0_reg;


//PART2: MULTIPLIER
wire [17:0] B1_reg;
wire [17:0] A1_reg;

REG_pipe #(.width(18),.REG_EN(B1REG),.REG_type(RSTTYPE)) B1_REG(.D(pre_adder_out_mux),.Q(B1_reg),.rst(RSTB),.clk(clk),.CE(CEB));
REG_pipe #(.width(18),.REG_EN(A1REG),.REG_type(RSTTYPE)) A1_REG(.D(A0_reg),.Q(A1_reg),.rst(RSTA),.clk(clk),.CE(CEA));
assign BCOUT = B1_reg;

wire [35:0] M_reg;
wire [35:0] M_out;
assign M_reg = A1_reg * B1_reg;

REG_pipe #(.width(36),.REG_EN(MREG),.REG_type(RSTTYPE)) M_REG(.D(M_reg),.Q(M_out),.rst(RSTM),.clk(clk),.CE(CEM));
assign M = M_out;

//PART3: POST_ADDER/SUBTRACTOR

//D:A:B Concatenation
wire [47:0] DAB_concat;
assign DAB_concat = {D0_reg[11:0],A1_reg[17:0],B1_reg[17:0]};

//mux X
reg [47:0] mux_X_out;
always@(*) begin
  case(OPMODE_reg[1:0])

    2'b00: mux_X_out = 48'b0;
    2'b01: mux_X_out = {12'b0,M};
    2'b10: mux_X_out = P;
    2'b11: mux_X_out = DAB_concat;
    default: mux_X_out = 48'b0;

  endcase

end


//mux Z
reg [47:0] mux_Z_out;
always@(*) begin
  case(OPMODE_reg[3:2])

    2'b00: mux_Z_out = 48'b0;
    2'b01: mux_Z_out = PCIN;
    2'b10: mux_Z_out = P;
    2'b11: mux_Z_out = C0_reg;

    default: mux_Z_out = 48'b0;

  endcase

end



//Carry in for post adder/subtractor
wire post_adder_carry_in_mux;
generate
    if(CARRYINSEL=="OPMODE[5]") begin
        assign post_adder_carry_in_mux = OPMODE_reg[5];
    end
    else if(CARRYINSEL=="CARRYIN") begin
        assign post_adder_carry_in_mux = CARRYIN;
    end
endgenerate

wire CIN_reg;
REG_pipe #(.width(1),.REG_EN(CARRYINREG),.REG_type(RSTTYPE)) POST_ADDER_CARRY_IN_REG(.D(post_adder_carry_in_mux),.Q(CIN_reg),.rst(RSTCARRYIN),.clk(clk),.CE(CECARRYIN));

//POST adder/subtractor
wire [47:0] post_adder_out;
wire carry_out_from_post_adder;
assign {carry_out_from_post_adder,post_adder_out} = OPMODE_reg[7] ? (mux_Z_out - (mux_X_out + CIN_reg)) : (mux_Z_out + (mux_X_out + CIN_reg));


//Carry out reg
wire carry_out_reg;
REG_pipe #(.width(1),.REG_EN(CARRYOUTREG),.REG_type(RSTTYPE)) CARRYOUT_REG(.D(carry_out_from_post_adder),.Q(carry_out_reg),.rst(RSTCARRYIN),.clk(clk),.CE(CECARRYIN));
assign CARRYOUT = carry_out_reg;
assign CARRYOUTF = carry_out_from_post_adder;

//P reg
wire [47:0] P_reg;
REG_pipe #(.width(48),.REG_EN(PREG),.REG_type(RSTTYPE)) P_REG(.D(post_adder_out),.Q(P_reg),.rst(RSTP),.clk(clk),.CE(CEP));
assign P = P_reg;
assign POUT = P_reg;

endmodule