////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Project Name: HyCUBE (Verilog, SystemVerilog)                          ////
////                                                                        ////
//// Module Name: spi_fsm                                                   ////
////                                                                        ////
////                                                                        ////
////  This file is part of the HyCUBE project                               ////
////  https://github.com/aditi3512/HyCUBE                                   ////
////                                                                        ////
////  Author(s):                                                            ////
////      NUS                                                               ////
////                                                                        ////
////  Refer to Readme.txt for more information                              ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Copyright 2020 Author(s)						    ////
//// Permission is hereby granted, free of charge, to any person 	    ////
//// obtaining a copy of this software and associated documentation 	    ////
//// files (the "Software"), to deal in the Software without restriction,   ////
//// including without limitation the rights to use, copy, modify, merge,   ////
//// publish, distribute, sublicense, and/or sell copies of the Software,   ////
//// and to permit persons to whom the Software is furnished to do so, 	    ////
//// subject to the following conditions:				    ////
////									    ////
//// The above copyright notice and this permission notice shall be 	    ////
//// included in all copies or substantial portions of the Software.	    ////
////									    ////
//// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 	    ////
//// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     ////
//// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. ////
//// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 	    ////
//// ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 	    ////	
//// CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION     ////
//// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.	    ////
////                                                                        ////
//// You should have received a copy of the MIT                             ////
//// License along with this source; if not, download it                    ////
//// from https://opensource.org/licenses/MIT                               ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////

//Author = Manupa
//Date 2017-07-24

module spi_fsm (
	clk,
	reset,
	en,

	//to fifo betwen spi slave and this fsm
	tdata_out,
	tdata_we_out,

	//from spi slave
	rdata_in,
	done_in,

	//to HyCUBE
	DA_out,
	DA_valid_out,
	Data_in,
	Data_valid_in,
	DoA_out,
	start_exec_out,
	hycube_done_in,
	rw_out
	);

localparam DATA_WIDTH=16;
localparam SPI_DATA_WIDTH=8;
localparam STATE_WIDTH=2;
localparam MINI_STATE_WIDTH=4;
localparam ADDR_IN_WIDTH=16;
localparam SIZE_IN_WIDTH=16;
localparam DATA_OUT_WIDTH=16;
localparam DATA_OUT_VALID_WIDTH=2;

localparam CMEM_ADDR_WIDTH=12;
localparam DMEM_ADDR_WIDTH=12;
localparam BYTE_COUNT_WIDTH=CMEM_ADDR_WIDTH+1;


//States
localparam STATE_IDLE=0;
localparam STATE_WR=1;
localparam STATE_EXEC=2;
localparam STATE_RD=3;

//mini-States
localparam MINI_STATE_ADDRESS=0;
localparam MINI_STATE_SIZE=1;
localparam MINI_STATE_DATA_ODD=2;
localparam MINI_STATE_DATA_EVEN=3;
localparam MINI_STATE_RD_LAST=4;
localparam MINI_STATE_EXEC_1=5;
localparam MINI_STATE_EXEC_2=6;
localparam MINI_STATE_EXEC_3=7;
localparam MINI_STATE_ERROR=8;

//DOA
localparam DOA_DATA=0;
localparam DOA_ADDR=1;


//-----------------------------
// IO
//-----------------------------

input clk;
input reset;
input en;

//to fifo betwen spi slave and this fsm
output [SPI_DATA_WIDTH-1:0] tdata_out;
output 						tdata_we_out;

//from spi slave
input  [SPI_DATA_WIDTH-1:0] rdata_in;
input  						done_in;

//to HyCUBE
output [DATA_WIDTH-1:0] 			DA_out;
output [DATA_OUT_VALID_WIDTH-1:0]	DA_valid_out;
input  [DATA_WIDTH-1:0]				Data_in;
input								Data_valid_in;
output								DoA_out;
output								rw_out;

output								start_exec_out;
input								hycube_done_in;


//-----------------------------
// Wires and Registers
//-----------------------------

reg 								done_reg;
reg    [SPI_DATA_WIDTH - 1:0]		rdata_reg;
wire 						    	done_posedge_wire;

reg    [STATE_WIDTH - 1:0]			state;
reg   [STATE_WIDTH - 1:0]      	    next_state;
reg    [BYTE_COUNT_WIDTH - 1:0] 	byte_count_reg;

reg    [ADDR_IN_WIDTH - 1:0]    	addr_reg;
wire   [ADDR_IN_WIDTH - 2 - 1:0]    addr_wire;
reg    [SIZE_IN_WIDTH - 1:0]    	size_reg;

reg    [DATA_OUT_WIDTH - 1:0]		data_to_hycube_reg;
reg    [DATA_OUT_VALID_WIDTH-1:0]	data_to_hycube_valid;
reg 								data_to_hycube_doa_reg;
reg  								rw_reg;

reg    [MINI_STATE_WIDTH-1:0]		mini_state;

reg    [SPI_DATA_WIDTH-1:0]			tdata_reg;
reg 								tdata_reg_valid;
reg 								start_exec_reg;

reg    [DATA_OUT_WIDTH - 1:0]		data_to_master_reg;

reg 								hycube_done_reg;
	
//-----------------------------
// Implementation
//-----------------------------

//Output assignment

assign tdata_out = tdata_reg;
assign DA_out = data_to_hycube_reg;
assign DA_valid_out = data_to_hycube_valid;
assign DoA_out = data_to_hycube_doa_reg;
assign rw_out = rw_reg;
assign start_exec_out = start_exec_reg;
assign tdata_we_out = tdata_reg_valid;


always @(posedge clk)  begin
	if(reset) begin
		hycube_done_reg <= 1'b1;
	end
	else begin
		hycube_done_reg <= hycube_done_in;
	end
end


//useful addr
assign addr_wire = addr_reg[ADDR_IN_WIDTH - 2 - 1:0];

always @(posedge clk) begin
	if (reset) begin
		done_reg <= 1'b0;
	end
	else if (en) begin
		done_reg <= done_in;
	end
end


//Collect a byte from SPI_Slave
assign done_posedge_wire = (done_in == 1 && done_reg == 0);

always @(posedge clk) begin
	if (reset) begin
		// reset
		rdata_reg <= {SPI_DATA_WIDTH{1'b0}};
	end
	else if (en) begin
		if(done_posedge_wire) begin // posedge detection
			rdata_reg <= rdata_in;
		end
	end
end

always @(posedge clk) begin
	if (reset) begin
		// reset
		byte_count_reg <= {BYTE_COUNT_WIDTH{1'b0}};
		mini_state <= MINI_STATE_ADDRESS;

		data_to_hycube_valid <= {DATA_OUT_VALID_WIDTH{1'b0}};
		data_to_hycube_reg <= {DATA_OUT_WIDTH{1'b0}};
		data_to_hycube_doa_reg <= DOA_ADDR;

		size_reg <= {SIZE_IN_WIDTH{1'b0}};
		addr_reg <= {ADDR_IN_WIDTH{1'b0}};

		data_to_master_reg <= {DATA_OUT_WIDTH{1'b0}};
		tdata_reg <= 8'h0;
		tdata_reg_valid <= 1'b0;

		start_exec_reg <= 1'b0; 

	end
	else if (en) begin
		case(state)
			STATE_IDLE : begin
				start_exec_reg <= 1'b0;

				if(state != next_state) begin
					tdata_reg <= {{(SPI_DATA_WIDTH-STATE_WIDTH){1'b0}},next_state};
					tdata_reg_valid <= 1'b1;
				end
				else begin
					tdata_reg_valid <= 1'b0;
				end

				if(done_posedge_wire == 1'b1) begin
					if(byte_count_reg == 1) begin
						byte_count_reg <= {BYTE_COUNT_WIDTH{1'b0}};
						addr_reg <= {rdata_in,rdata_reg};
					end
					else begin
						byte_count_reg <= byte_count_reg + 1;
					end
				end
			end
			STATE_WR : begin
				start_exec_reg <= 1'b0;

				if(state != next_state) begin
					tdata_reg <= {{(SPI_DATA_WIDTH-STATE_WIDTH){1'b0}},next_state};
					tdata_reg_valid <= 1'b1;
				end
				else begin
					tdata_reg_valid <= 1'b0;
				end

					case(mini_state)
						MINI_STATE_ADDRESS : begin
                            data_to_hycube_valid <= 2'b00;
                            if(done_posedge_wire == 1'b1) begin
                                if(byte_count_reg == 1) begin
                                    byte_count_reg <= {BYTE_COUNT_WIDTH{1'b0}};
                                    addr_reg <= {rdata_in,rdata_reg};
                                    
                                    if(rdata_in[7:6] == 2'b01) begin
                                        mini_state <= MINI_STATE_SIZE;
                                    end
                                end
                                else begin
                                    byte_count_reg <= byte_count_reg + 1;
                                end
                            end
						end
						MINI_STATE_SIZE : begin
                            if(done_posedge_wire == 1'b1) begin
                                if(byte_count_reg == 1) begin
                                    byte_count_reg <= {BYTE_COUNT_WIDTH{1'b0}};
                                    size_reg <= {2'b00,rdata_in[5:0],rdata_reg};
    
                                    if(rdata_reg[0]==1) begin //odd
                                        mini_state <= MINI_STATE_DATA_ODD;
                                    end
                                    else begin //even
                                        mini_state <= MINI_STATE_DATA_EVEN;
                                    end
                                end
                                else begin
                                    byte_count_reg <= byte_count_reg + 1;
                                end
							end
						end
						MINI_STATE_DATA_EVEN : begin
                            if(done_posedge_wire == 1'b1) begin
                                if(byte_count_reg == size_reg-1) begin
                                    byte_count_reg <= {BYTE_COUNT_WIDTH{1'b0}};
                                    size_reg <= {SIZE_IN_WIDTH{1'b0}};
                                    //addr_reg <= {ADDR_IN_WIDTH{1'b0}};
                                    mini_state <= MINI_STATE_ADDRESS;
    
                                    if(byte_count_reg[0] == 1) begin
                                        data_to_hycube_reg <= {rdata_in,rdata_reg};
                                        data_to_hycube_doa_reg <= DOA_DATA;
                                        data_to_hycube_valid <= 2'b11;
                                    end
                                    else begin
                                    `ifdef ASSERTS_ON
                                        assert(0);
                                    `endif
                                    end
                                end
                                else begin
                                    if(byte_count_reg[0] == 1) begin
                                        data_to_hycube_reg <= {rdata_in,rdata_reg};
                                        data_to_hycube_doa_reg <= DOA_DATA;
                                        data_to_hycube_valid <= 2'b11;
                                    end
                                    else begin
                                        data_to_hycube_doa_reg <= DOA_ADDR;
                                        data_to_hycube_reg <= addr_wire + byte_count_reg;
                                        data_to_hycube_valid <= 2'b11;
                                    end
                                    byte_count_reg <= byte_count_reg+1;
                                end
							end
							else begin
								data_to_hycube_valid <= 2'b00;
							end
						end
						MINI_STATE_DATA_ODD : begin
							if(byte_count_reg == size_reg) begin
							// wating for an extra cycle 
								byte_count_reg <= {BYTE_COUNT_WIDTH{1'b0}};
								size_reg <= {SIZE_IN_WIDTH{1'b0}};
//								addr_reg <= {ADDR_IN_WIDTH{1'b0}};
								mini_state <= MINI_STATE_ADDRESS;

								if(byte_count_reg[0] == 1) begin
									data_to_hycube_doa_reg <= DOA_DATA;
									data_to_hycube_reg <= {8'b0,rdata_reg};
									data_to_hycube_valid <= 2'b01;
								end
								else begin
									//should not come here
								`ifdef ASSERTS_ON
                                        assert(0);
                                `endif
								end
							end
							else begin
                                if(done_posedge_wire == 1'b1) begin
                                    if(byte_count_reg[0] == 1) begin
                                        data_to_hycube_doa_reg <= DOA_DATA;
                                        data_to_hycube_reg <= {rdata_in,rdata_reg};
                                        data_to_hycube_valid <= 2'b11;
                                    end
                                    else begin
                                        data_to_hycube_doa_reg <= DOA_ADDR;
                                        data_to_hycube_reg <= addr_wire + byte_count_reg;
                                        data_to_hycube_valid <= 2'b11;
                                    end
                                    byte_count_reg <= byte_count_reg+1;
								end
								else begin
									data_to_hycube_valid <= 2'b00;
								end
							end
						end
						default : begin
							mini_state <= MINI_STATE_ERROR;
						end
					endcase
			end
			STATE_EXEC : begin
			    case(mini_state)
			         MINI_STATE_EXEC_1 : begin
			             start_exec_reg <= 1'b1;
			             mini_state <= MINI_STATE_EXEC_3;
			             tdata_reg_valid <= 1'b0;
			         end
			         MINI_STATE_EXEC_2 : begin
					 	 mini_state <= MINI_STATE_EXEC_3;
			         end
			         MINI_STATE_EXEC_3 : begin
                        if(hycube_done_in == 1'b1 && hycube_done_reg == 1'b0) begin
                            start_exec_reg <= 1'b0;
         

                            if(tdata_reg != 8'hf2) begin
                            	tdata_reg <= 8'hf2;
                            	tdata_reg_valid <= 1'b1;
                            end
                            else begin
                            	tdata_reg_valid <= 1'b0;
                            end
                        end
                        else if(state != next_state) begin
							tdata_reg <= {{(SPI_DATA_WIDTH-STATE_WIDTH){1'b0}},next_state};
							tdata_reg_valid <= 1'b1;
						end
						else begin
							tdata_reg_valid <= 1'b0;
						end
			         end
					default : begin
						mini_state <= MINI_STATE_ERROR;
					end
			    endcase	
			    
                if(done_posedge_wire == 1'b1) begin
                    if(byte_count_reg == 1) begin
                        byte_count_reg <= {BYTE_COUNT_WIDTH{1'b0}};
                        addr_reg <= {rdata_in,rdata_reg};
                    end
                    else begin
                        byte_count_reg <= byte_count_reg + 1;
                    end
                end
			end
			STATE_RD : begin
				start_exec_reg <= 1'b0;

				if(state != next_state) begin
					tdata_reg <= {{(SPI_DATA_WIDTH-STATE_WIDTH){1'b0}},next_state};
					tdata_reg_valid <= 1'b1;
				end
				else begin
					tdata_reg_valid <= 1'b0;
				end


				case(mini_state)
					MINI_STATE_ADDRESS : begin

						if(done_posedge_wire) begin
							if(byte_count_reg == 1) begin
								byte_count_reg <= {BYTE_COUNT_WIDTH{1'b0}};
								addr_reg <= {rdata_in,rdata_reg};

								if(rdata_in[7:6] == STATE_RD) begin
									mini_state <= MINI_STATE_SIZE;
								end
							end
							else begin
								byte_count_reg <= byte_count_reg + 1;
							end
						end
					end
					MINI_STATE_SIZE : begin

						if(done_posedge_wire) begin
							if(byte_count_reg == 1) begin
								byte_count_reg <= {BYTE_COUNT_WIDTH{1'b0}};
                                size_reg <= {2'b00,rdata_in[5:0],rdata_reg};

								//giving the first address a cycle prior
								data_to_hycube_doa_reg <= DOA_ADDR;
								data_to_hycube_reg <= addr_wire;
								data_to_hycube_valid <= 2'b11;

								if(rdata_reg[0]==1) begin //odd
									mini_state <= MINI_STATE_DATA_ODD;
								end
								else begin //even
									mini_state <= MINI_STATE_DATA_EVEN;
								end

							end
							else begin
								byte_count_reg <= byte_count_reg + 1;
							end
						end
					end
					MINI_STATE_DATA_ODD : begin
						if(byte_count_reg == size_reg -1) begin
							data_to_hycube_valid <= 2'b00;
							if(byte_count_reg[0] == 0) begin
								if(Data_valid_in) begin
									data_to_master_reg <= Data_in;
								end
								
								if(done_posedge_wire == 1'b1) begin
									byte_count_reg <= {BYTE_COUNT_WIDTH{1'b0}};
									size_reg <= {SIZE_IN_WIDTH{1'b0}};
//									addr_reg <= {ADDR_IN_WIDTH{1'b0}};
									mini_state <= MINI_STATE_RD_LAST;

									if(Data_valid_in == 1'b1) begin
										tdata_reg <= Data_in[7:0];
									end
									else begin
										tdata_reg <= data_to_master_reg[7:0];
									end
									tdata_reg_valid <= 1'b1;
								end
								else begin
									tdata_reg_valid <= 1'b0;
								end
							end
							else begin
							`ifdef ASSERTS_ON
                                assert(0);
                            `endif
							end
						end
						else begin
							if(byte_count_reg[0] == 1) begin
								tdata_reg_valid <= 1'b0;
								if(done_posedge_wire == 1'b1) begin
									data_to_hycube_doa_reg <= DOA_DATA;
								//	data_to_hycube_reg <= {rdata_in,rdata_reg};
									data_to_hycube_reg <= addr_wire + byte_count_reg + 1;
									data_to_hycube_valid <= 2'b11;


									tdata_reg <= data_to_master_reg[15:8];
									byte_count_reg <= byte_count_reg+1;
									tdata_reg_valid <= 1'b1;
								end
							end
/* Aditi to fix READ
                                else begin
                                    if(byte_count_reg[0] == 1) begin
                                        data_to_hycube_reg <= {rdata_in,rdata_reg};
                                        data_to_hycube_doa_reg <= DOA_DATA;
                                        data_to_hycube_valid <= 2'b11;
                                    end
                                    else begin
                                        data_to_hycube_doa_reg <= DOA_ADDR;
                                        data_to_hycube_reg <= addr_wire + byte_count_reg;
                                        data_to_hycube_valid <= 2'b11;
                                    end
                                    byte_count_reg <= byte_count_reg+1;
                                end
*/
							else begin
								data_to_hycube_valid <= 2'b00;

								if(Data_valid_in) begin
									data_to_master_reg <= Data_in;
								end

								if(done_posedge_wire == 1'b1) begin
									if(Data_valid_in == 1'b1) begin
										tdata_reg <= Data_in[7:0];
									end
									else begin
										tdata_reg <= data_to_master_reg[7:0];
									end
									tdata_reg_valid <= 1'b1;
									byte_count_reg <= byte_count_reg+1;
								end
								else begin
									tdata_reg_valid <= 1'b0;
								end
							end
						end
					end
					MINI_STATE_DATA_EVEN : begin
						if(byte_count_reg == size_reg) begin
							data_to_hycube_valid <= 2'b00;
							if(byte_count_reg[0] == 0) begin
								tdata_reg_valid <= 1'b0;
								if(done_posedge_wire == 1'b1) begin
									byte_count_reg <= {BYTE_COUNT_WIDTH{1'b0}};
									size_reg <= {SIZE_IN_WIDTH{1'b0}};
//									addr_reg <= {ADDR_IN_WIDTH{1'b0}};
									mini_state <= MINI_STATE_ADDRESS;

									tdata_reg <= data_to_master_reg[15:8];
								end
							end
							else begin
							`ifdef ASSERTS_ON
                                assert(0);
                            `endif
							end
						end
						else begin
							if(byte_count_reg[0] == 1) begin
								tdata_reg_valid <= 1'b0;

								if(done_posedge_wire == 1'b1) begin
									data_to_hycube_doa_reg <= DOA_DATA;
								//	data_to_hycube_reg <= {rdata_in,rdata_reg};
									data_to_hycube_reg <= addr_wire + byte_count_reg + 1;
									data_to_hycube_valid <= 2'b11;

									tdata_reg <= data_to_master_reg[15:8];
									byte_count_reg <= byte_count_reg+1;
									tdata_reg_valid <= 1'b1;
								end
							end
/*Aditi to fix READ
                                else begin
                                    if(byte_count_reg[0] == 1) begin
                                        data_to_hycube_reg <= {rdata_in,rdata_reg};
                                        data_to_hycube_doa_reg <= DOA_DATA;
                                        data_to_hycube_valid <= 2'b11;
                                    end
                                    else begin
                                        data_to_hycube_doa_reg <= DOA_ADDR;
                                        data_to_hycube_reg <= addr_wire + byte_count_reg;
                                        data_to_hycube_valid <= 2'b11;
                                    end
                                    byte_count_reg <= byte_count_reg+1;
                                end
*/
							else begin
								data_to_hycube_valid <= 2'b00;

								if(Data_valid_in) begin
									data_to_master_reg <= Data_in;
								end

								if(done_posedge_wire == 1'b1) begin
									if(Data_valid_in == 1'b1) begin
										tdata_reg <= Data_in[7:0];
									end
									else begin
										tdata_reg <= data_to_master_reg[7:0];
									end
									tdata_reg_valid <= 1'b1;
									byte_count_reg <= byte_count_reg+1;
								end
								else begin
									tdata_reg_valid <= 1'b0;
								end
							end
						end
					end
					MINI_STATE_RD_LAST : begin
						tdata_reg_valid <= 1'b0;
						data_to_hycube_valid <= 2'b00;
						if(done_posedge_wire == 1) begin
							mini_state <= MINI_STATE_ADDRESS;
						end
					end
					default : begin
						mini_state <= MINI_STATE_ERROR;
					end
				endcase
			end
		endcase

	    if(state != next_state) begin
            case(next_state)
               STATE_IDLE : begin
                   mini_state <= MINI_STATE_ADDRESS;
               end
               STATE_WR : begin
                   mini_state <= MINI_STATE_ADDRESS;
               end
               STATE_EXEC : begin
                   mini_state <= MINI_STATE_EXEC_1;
               end
               STATE_RD : begin
                   mini_state <= MINI_STATE_ADDRESS;
               end
            endcase
	    end

	end
end

always @(posedge clk) begin
	if (reset) begin
		// reset
		state <= STATE_IDLE;
	end
	else if (en) begin
		state <= next_state;
	end
end

//state change logic
always @(*) begin
	if(mini_state == MINI_STATE_ERROR) begin
		next_state = STATE_IDLE;
	end
	else begin
	    case(addr_reg[15:14])
	        2'b00 : begin
	            next_state = STATE_IDLE;
	        end
	        2'b01 : begin
	            next_state = STATE_WR;
	        end
	        2'b10 : begin
	            next_state = STATE_EXEC;
	        end
	        2'b11 : begin
	            next_state = STATE_RD;
	        end
	    endcase
	end
end


//rw combinotorial set acccording to current state
always @(*) begin
	case(state)
		STATE_IDLE : begin
			rw_reg = 1'b1;
		end
		STATE_RD : begin
			rw_reg = 1'b1;
		end
		STATE_EXEC : begin
			rw_reg = 1'b1;
		end
		STATE_WR : begin
			rw_reg = 1'b0;
		end
	endcase
end

endmodule
