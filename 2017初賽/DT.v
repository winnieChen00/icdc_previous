module DT(
	input clk, 
	input reset,
	output reg done ,
	output reg sti_rd ,
	output reg[9:0]sti_addr ,
	input [15:0]sti_di,
	output reg res_wr ,
	output reg res_rd ,
	output reg [13:0]res_addr ,
	output reg [7:0]res_do,
	input [7:0]res_di);

	parameter IDLE = 0, READ = 1, WRITE = 2, REST = 3, FORW_RD = 4, FORW_WR = 5, BACK_RD = 6, BACK_WR = 7, FINISH = 8;
	reg [3:0]state, next_state;
	reg [14:0]count;

	always@(posedge clk or negedge reset)begin  
			if(~reset)
					state <= IDLE;
			else
					state <= next_state;
	end

	always@(*)begin
			case(state)													
					IDLE:next_state = READ;
					READ:next_state = WRITE; 

					WRITE:begin
							if(count == 16383)		
									next_state = REST;
							else if(count[3:0] == 15 && sti_addr < 1023)
									next_state = READ;
							else
									next_state = WRITE;
					end

					REST: next_state = FORW_RD;

					FORW_RD:begin
							if(res_addr == 16255)
									next_state = BACK_RD;
							else
									next_state = (count == 4) ? FORW_WR : FORW_RD;  
					end
					FORW_WR:next_state = FORW_RD;
					BACK_RD:begin
							if(res_addr == 128)
									next_state = FINISH;
							else
									next_state = (count == 4) ? BACK_WR : BACK_RD;
					end
					BACK_WR:next_state = BACK_RD;

					FINISH:	 next_state = FINISH;
					default: next_state = IDLE;
			endcase
	end

	always@(posedge clk or negedge reset)begin     
			if(~reset)
					sti_rd <= 0;
			else if(state == READ)
					sti_rd <= 1;
			else 
					sti_rd <= 0;
	end

	always@(posedge clk or negedge reset)begin
			if(~reset)
					count <= 0;
			else if(state == WRITE)
					count <= count + 1;
			else if(state == READ)
					count <= count;
			else if(state == FORW_RD)begin
					if(res_di == 0 && count == 0)
							count <= 0;
					else
							count <= count + 1;
			end
			else if(state == BACK_RD)begin
					if(res_di == 0 && count == 0)
							count <= 0;
					else
							count <= count + 1;
			end
			else
					count <= 0;
	end

	always@(posedge clk or negedge reset)begin
			if(~reset)
					res_addr <= 0;
			else if(state == WRITE || next_state == WRITE)
					res_addr <= count;
			else if(state == REST)
					res_addr <= 129;
			else if(state == FORW_RD)begin
					if(res_di == 0 && count == 0) 
							res_addr <= res_addr + 1;
					else begin
							case(count)
								4'h0: res_addr <= res_addr - 129;
								4'h1: res_addr <= res_addr + 1;
								4'h2: res_addr <= res_addr + 1;
								4'h3: res_addr <= res_addr + 126;
								4'h4: res_addr <= res_addr + 1;
								default: res_addr <= res_addr;
						endcase
					end
			end
			else if(state == FORW_WR)begin
					if(res_addr[6:0] == 126)
							res_addr <= res_addr + 3;
					else
							res_addr <= res_addr + 1;
			end
			else if(state == BACK_RD)begin
					if(res_di == 0 && count == 0)
							res_addr <= res_addr - 1;
					else begin
							case(count)
								4'h0: res_addr <= res_addr + 129;
								4'h1: res_addr <= res_addr - 1;
								4'h2: res_addr <= res_addr - 1;
								4'h3: res_addr <= res_addr - 126;
								4'h4: res_addr <= res_addr - 1;
								default: res_addr <= res_addr;
							endcase
					end
			end	
			else if(state == BACK_WR)begin
					if(res_addr[6:0] == 1)
							res_addr <= res_addr - 3;
					else
							res_addr <= res_addr - 1;
			end
			else
					res_addr <= res_addr;
	end

	always@(posedge clk or negedge reset)begin
			if(~reset)
					res_do <= 0;
			else if(state == WRITE)
					res_do <= sti_di[15-count[3:0]];
			else if(state == FORW_RD) begin
					if(count == 1)
						res_do <= res_di+1;
					else
						res_do <= (res_do < res_di+1) ? res_do : res_di+1;
			end
			else if(state == BACK_RD)begin
					if(count == 0)
						res_do <= res_di;
					else
						res_do <= (res_do < (res_di+1)) ? res_do : (res_di+1);
			end
			else
					res_do <= res_do;
	end

	always@(posedge clk or negedge reset)begin
			if(~reset)
					sti_addr <= 0;
			else if(next_state == READ && count != 0)
					sti_addr <= sti_addr + 1;
			else
					sti_addr <= sti_addr;
			
	end

	always@(posedge clk or negedge reset)begin
			if(~reset)
					res_rd <= 0;
			else if(next_state == FORW_RD || next_state == BACK_RD)
					res_rd <= 1;
			else
					res_rd <= 0;
	end

	always@(posedge clk or negedge reset)begin
			if(~reset)
					res_wr <= 0;
			else if(state == WRITE)
					res_wr <= 1;
			else if(next_state == FORW_WR || next_state == BACK_WR)
					res_wr <= 1;
			else
					res_wr <= 0;
	end

	always@(posedge clk or negedge reset)begin
			if(~reset)
					done <= 0;
			else if(state == FINISH)
					done <= 1;
			else
					done <= 0;
	end
			
endmodule
