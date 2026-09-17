module REG_pipe(D,Q,rst,clk,CE);
parameter width=18;
parameter REG_EN=1;
parameter REG_type="SYNC";

input [width-1:0] D;
output reg [width-1:0] Q;
input rst;
input clk;
input CE;

generate
    if(REG_EN) begin
        if(REG_type=="SYNC") begin
            always@(posedge clk) begin
              if (rst) begin
                Q <= 0;
              end else if (CE) begin
                Q <= D;
              end
            end
          
        end
        else if(REG_type=="ASYNC") begin
            always@(posedge clk or posedge rst) begin
              if (rst) begin
                Q <= 0;
              end else if (CE) begin
                Q <= D;
              end
            end
        end
    end
    else  begin
        //no reg
        always@(*) begin
            Q = D;
        end
    end
endgenerate
endmodule