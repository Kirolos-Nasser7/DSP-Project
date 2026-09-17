module DSP_tb;

// signal declaration
reg [17:0] A,B,D;
reg [17:0] BCIN;
reg [47:0] C,PCIN;
reg [7:0] OPMODE;
reg CARRYIN;
reg clk;
reg CEA,CEB,CEC,CED,CEP,CEM,CECARRYIN,CEOPMODE;
reg RSTA,RSTB,RSTC,RSTD,RSTP,RSTM,RSTCARRYIN,RSTOPMODE;

wire  [35:0] M;
wire [47:0] P;
wire CARRYOUT,CARRYOUTF;
wire [47:0] POUT;
wire [17:0] BCOUT;

// Instantiate the DSP module
DSP DUT(.A(A),.B(B),.C(C),.D(D),
         .clk(clk),.CARRYIN(CARRYIN),
         .OPMODE(OPMODE),.BCIN(BCIN),.RSTA(RSTA),.RSTB(RSTB),.RSTC(RSTC),.RSTD(RSTD),.RSTP(RSTP),.RSTM(RSTM),.RSTCARRYIN(RSTCARRYIN),.RSTOPMODE(RSTOPMODE),
         .CEA(CEA),.CEB(CEB),.CEC(CEC),.CED(CED),.CEP(CEP),.CEM(CEM),.CECARRYIN(CECARRYIN),.CEOPMODE(CEOPMODE),
         .PCIN(PCIN),
         .BCOUT(BCOUT),
         .POUT(POUT),
         .P(P),
         .M(M),
         .CARRYOUT(CARRYOUT),
         .CARRYOUTF(CARRYOUTF)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz clock
end

// Test stimulus

initial begin

//reset operations
RSTA = 1; RSTB = 1; RSTC = 1; RSTD = 1; RSTP = 1; RSTM = 1; RSTCARRYIN = 1; RSTOPMODE = 1;

CEA = $random; 
CEB = $random; 
CEC = $random; 
CED = $random; 
CEP = $random; 
CEM = $random; 
CECARRYIN = $random; 
CEOPMODE = $random;

A=$random; 
B=$random; 
C=$random; 
D=$random; 
BCIN=$random; 
OPMODE=$random; 
CARRYIN=$random; 
PCIN=$random;

// give reset time for pipeline
repeat(3) @(negedge clk);

if(M !== 36'b0 || P !== 48'b0 || CARRYOUT !== 1'b0 || CARRYOUTF !== 1'b0 || POUT !== 48'b0 || BCOUT !== 18'b0) begin
    $display("Reset failed!");
end else begin
    $display("Reset successful.");
end

// Release reset
RSTA = 0; RSTB = 0; RSTC = 0; RSTD = 0; RSTP = 0; RSTM = 0; RSTCARRYIN = 0; RSTOPMODE = 0;

CEA = 1; 
CEB = 1; 
CEC = 1; 
CED = 1; 
CEP = 1; 
CEM = 1; 
CECARRYIN = 1; 
CEOPMODE = 1;


//path 1:
A=20; B=10; C=350; D=25;
OPMODE=8'b11011101;
CARRYIN=$random; BCIN=$random; PCIN=$random;

repeat(4) @(negedge clk);

if(P !== 48'h32 || POUT !== 48'h32  || BCOUT !== 18'hf || M !== 36'h12c || CARRYOUTF !== 1'b0 || CARRYOUT !== 1'b0) begin
    $display("Test case 1 failed!");
    $display("Expected P=32, M=12c, BCOUT=f, CARRYOUT=0, CARRYOUTF=0");
    $display("Got P=%h, M=%h, BCOUT=%h, CARRYOUT=%b, CARRYOUTF=%b", P, M, BCOUT, CARRYOUT, CARRYOUTF);
    $stop;
end else begin
    $display("Test case 1 passed.");
end


//path 2:
A=20; B=10; C=350; D=25;
OPMODE=8'b00010000;
CARRYIN=$random; BCIN=$random; PCIN=$random;

repeat(3) @(negedge clk);

if(P !== 48'h0 || POUT !== 48'h0  || BCOUT !== 18'h23 || M !== 36'h2bc || CARRYOUTF !== 1'b0 || CARRYOUT !== 1'b0) begin
    $display("Test case 2 failed!");
    $display("Expected P=0, M=2bc, BCOUT=23, CARRYOUT=0, CARRYOUTF=0");
    $display("Got P=%h, M=%h, BCOUT=%h, CARRYOUT=%b, CARRYOUTF=%b", P, M, BCOUT, CARRYOUT, CARRYOUTF);
    $stop;
end else begin
    $display("Test case 2 passed.");
end


//path 3:
A=20; B=10; C=350; D=25;
OPMODE=8'b00001010;
CARRYIN=$random; BCIN=$random; PCIN=$random;

repeat(3) @(negedge clk);

if(P !== 48'h0 || POUT !== 48'h0  || BCOUT !== 18'ha || M !== 36'hc8 || CARRYOUTF !== 1'b0 || CARRYOUT !== 1'b0) begin
    $display("Test case 3 failed!");
    $display("Expected P=0, M=c8, BCOUT=a, CARRYOUT=0, CARRYOUTF=0");
    $display("Got P=%h, M=%h, BCOUT=%h, CARRYOUT=%b, CARRYOUTF=%b", P, M, BCOUT, CARRYOUT, CARRYOUTF);
    $stop;
end else begin
    $display("Test case 3 passed.");
end


//path 4:
A=5; B=6; C=350; D=25;
OPMODE = 8'b10100111;
CARRYIN=$random; BCIN=$random; PCIN=3000;

repeat(3) @(negedge clk);

if(P !== 48'hfe6fffec0bb1 || POUT !== 48'hfe6fffec0bb1  || BCOUT !== 18'h6 || M !== 36'h1e || CARRYOUTF !== 1'b1 || CARRYOUT !== 1'b1) begin
    $display("Test case 4 failed!");
    $display("Expected P=fe6fffec0bb1, M=1e, BCOUT=6, CARRYOUT=1, CARRYOUTF=1");
    $display("Got P=%h, M=%h, BCOUT=%h, CARRYOUT=%b, CARRYOUTF=%b", P, M, BCOUT, CARRYOUT, CARRYOUTF);
    $stop;
end else begin
    $display("Test case 4 passed.");
end

$display("All test cases passed.");
$stop;

end

endmodule