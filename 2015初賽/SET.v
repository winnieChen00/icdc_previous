module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output busy;
output valid;
output [7:0] candidate;


reg busy;
reg valid;
reg [7:0] candidate;
reg  [3:0] x1,x2,x3,y1,y2,y3;
reg  [3:0] r1,r2,r3;
reg  [3:0] x,y;
wire [7:0]t1,t2,t3;
wire [5:0]rr1,rr2,rr3;
assign t1=((x-x1)*(x-x1)+(y-y1)*(y-y1));
assign t2=((x-x2)*(x-x2)+(y-y2)*(y-y2));
assign t3=((x-x3)*(x-x3)+(y-y3)*(y-y3));
assign rr1=(r1*r1);
assign rr2=(r2*r2);
assign rr3=(r3*r3);

always@(*) begin
		x1 = central[23:20];
		y1 = central[19:16];
		x2 = central[15:12];
		y2 = central[11:8];
		x3 = central[7:4];
		y3 = central[3:0];
		r1 = radius[11:8];
		r2 = radius[7:4];
		r3 = radius[3:0];
end
always@(posedge clk or posedge rst)begin
	if(rst) begin
		x<=1;
	end
	else if(en) begin
		x<=1;
	end
	else begin
		if(x<8)
			x<=x+1;
		else
			x<=1;
	end
end
always@(posedge clk or posedge rst)begin
	if(rst) begin
		y<=1;
	end
	else if(en) begin
		y<=1;
	end
	else begin
		if(x==8 && y<8)
			y<=y+1;
	end
end
always@(posedge clk)begin
	if(rst) begin
		candidate<=0;
	end
	else if(en) begin
		candidate<=0;
	end
	else begin
		case(mode)
		2'b00: begin
				if(t1<=rr1)
					candidate<=candidate+1;
			end
		2'b01:begin
				if((t1<=rr1) && (t2<=rr2))
					candidate<=candidate+1;
			end
		2'b10:begin
				if((t1<=rr1) ^ (t2<=rr2))
					candidate<=candidate+1;
			end
		2'b11:begin
				if(!(((t1<=rr1)^(t2<=rr2))^(t3<=rr3)) && (((t1<=rr1)||(t2<=rr2))||(t3<=rr3)))
					candidate<=candidate+1;
			end
		endcase
	end
end 
always@(posedge clk or posedge rst)begin
	if(rst) begin
		valid<=0;
	end
	else if(x==8 && y==8) begin
		valid<=1;
	end
	else begin
		valid<=0;
	end
end
always@(posedge clk or posedge rst)begin
	if(rst) begin
		busy<=0;
	end
	else if(valid) begin
		busy<=0;
	end
	else begin
		busy<=1;
	end
end


endmodule


