////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Project Name: HyCUBE (Verilog, SystemVerilog)                          ////
////                                                                        ////
//// Module Name: hycube                                                    ////
////                                                                        ////
////                                                                        ////
////  This file is part of the Ethernet IP core project                     ////
////  https://github.com/aditi3512/HyCUBE                                   ////
////                                                                        ////
////  Author(s):                                                            ////
////      NUS                                                               ////
////                                                                        ////
////  Refer to Readme.txt for more information                              ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Copyright (C) 2014, 2015 Authors                                       ////
////                                                                        ////
//// This source file may be used and distributed without                   ////
//// restriction provided that this copyright statement is not              ////
//// removed from the file and that any derivative work contains            ////
//// the original copyright notice and the associated disclaimer.           ////
////                                                                        ////
//// This source file is free software; you can redistribute it             ////
//// and/or modify it under the terms of the GNU Lesser General             ////
//// Public License as published by the Free Software Foundation;           ////
//// either version 2.1 of the License, or (at your option) any             ////
//// later version.                                                         ////
////                                                                        ////
//// This source is distributed in the hope that it will be                 ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied             ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR                ////
//// PURPOSE.  See the GNU Lesser General Public License for more           ////
//// details.                                                               ////
////                                                                        ////
//// You should have received a copy of the GNU Lesser General              ////
//// Public License along with this source; if not, download it             ////
//// from http://www.opencores.org/lgpl.shtml                               ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////

module hycube(
    clk,
    reset,
    chip_en,
    data,
    data_inout,
    scan_data_or_addr,
    read_write,
    data_out_valid,
    data_addr_valid,
    scan_start_exec,
    exec_end,
    bist_success,
    bist_en,
    scan_out,
    scan_in,
    scan_en,
    scan_chain_sel_0,
    scan_chain_sel_1,
    scan_chain_sel_2,
    scan_chain_sel_3
);

input logic                             reset;
input logic                             clk;
input logic                             chip_en;

input logic                             bist_en;
output logic                            bist_success;
input  logic                            scan_start_exec;

output  logic                           data_out_valid;
input  [1:0]                            data_addr_valid;

input [15:0]                            data;
output [15:0]                           data_inout;
input  logic                            scan_data_or_addr;
input  logic                            read_write;
output logic                            exec_end;

output [3:0] 				scan_out;
input	logic				scan_in;
input	logic				scan_en;

input [1:0] 				scan_chain_sel_0;
input [1:0] 				scan_chain_sel_1;
input [1:0] 				scan_chain_sel_2;
input [1:0] 				scan_chain_sel_3;

//-----------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
import TopPkg::*;
import SMARTPkg::*;

parameter NUM_RESET_SYNC_STAGES         = 2;

parameter NIC_OUTPUT_FIFO_DEPTH         = 1;
parameter ROUTER_NUM_VCS                = 8;

localparam TILE_NUM_INPUT_PORTS         = 6;
localparam TILE_NUM_OUTPUT_PORTS        = 7;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// IO
//------------------------------------------------------------------------------


reg start_exec;
reg exec_end;
wire scan_init_dm;
assign scan_init_dm = ~scan_start_exec;
reg [15:0] data_inout;
reg [15:0] address;
reg [15:0] address_wire;
reg [15:0] scan_data;
reg [15:0] scan_data_reg;
reg [63:0] look_up_table_reg;
reg [63:0] cm_data;
reg [31:0] dm_data;
reg [31:0] dm_bit_en;
reg [63:0] cm_bit_en;
reg bist_success;
reg [1:0] data_addr_valid_reg;
reg data_or_addr_reg;
wire chip_en_dm0;
wire chip_en_dm4;
wire chip_en_dm8;
wire chip_en_dm12;
//----------------------------------------------------------------------
//----------------------SPI-Network logic-------------------------------
//----------------------------------------------------------------------
// Determines if input is data or address
	
always @ (posedge clk)
begin
if (reset)
begin
	data_addr_valid_reg <=2'b00;
	data_or_addr_reg <= 1'b0;
end
else if (chip_en) begin
	data_addr_valid_reg <=data_addr_valid;
	data_or_addr_reg <=scan_data_or_addr;
end // chip en
end //always

assign scan_data = data;

always @ (posedge clk)
begin
if (reset) begin
        address <=0;
end
else if (chip_en) begin
        if (data_addr_valid==2'b11 && scan_data_or_addr==1'b1) begin
                address <= data;
end
end
end

reg [3:0] dm_en;

//Based on address, determines if data memory is to be enabled
always @ (posedge clk)
begin
if (reset) begin
	dm_en = 4'b0000;
end
else begin
        if(scan_data_or_addr==1'b1 || address[12]==1'b0 || data_addr_valid== 2'b00 || address[13] == 1'b1)
                dm_en = 4'b0000;
        else begin //this is if it is a DM
                case(address[11:10])
                2'b00: dm_en = 4'b0001;
                2'b01: dm_en = 4'b0010;
                2'b10: dm_en = 4'b0100;
                2'b11: dm_en = 4'b1000;
		default: dm_en = 4'b0000;
                endcase //case
        end //else this is if it is a DM
end
end

assign chip_en_dm0 = (dm_en == 4'b0001) ? 1'b0 : 1'b1;
assign chip_en_dm4 = (dm_en == 4'b0010) ? 1'b0 : 1'b1;
assign chip_en_dm8 = (dm_en == 4'b0100) ? 1'b0 : 1'b1;
assign chip_en_dm12 = (dm_en == 4'b1000) ? 1'b0 : 1'b1;


//Data memory Byte addressable
always @ (posedge clk)
begin
if (reset) begin
	dm_data = {scan_data[15:0],{16{1'b0}}};
	dm_bit_en = {{16{1'b1}},{16{1'b1}}};
end
else begin
if (address[12]==1'b1 && address[13]==1'b0) begin
        if(address[1]==1'b0) begin
                if (data_addr_valid==2'b01) begin
                        dm_data = {{24{1'b0}},scan_data[7:0]};
                        dm_bit_en = {{24{1'b1}},{8{1'b0}}};
                end
                else if (data_addr_valid==2'b10) begin
                        dm_data = {{16{1'b0}},scan_data[15:8],{8{1'b0}}};
                        dm_bit_en = {{16{1'b1}},{8{1'b0}},{8{1'b1}}};
                end
                else if (data_addr_valid==2'b11) begin
                        dm_data = {{16{1'b0}},scan_data[15:0]};
                        dm_bit_en = {{16{1'b1}},{16{1'b0}}};
                end
                else if (data_addr_valid==2'b00) begin
                        dm_data = {{16{1'b0}},scan_data[15:0]};
                        dm_bit_en = {{16{1'b1}},{16{1'b1}}};
                end
        end // address[1] is 0
        else if(address[1]==1'b1) begin
                if (data_addr_valid==2'b01) begin
                        dm_data = {{8{1'b0}},scan_data[7:0],{16{1'b0}}};
                        dm_bit_en = {{8{1'b1}},{8{1'b0}},{16{1'b1}}};
                end
                else if (data_addr_valid==2'b10) begin
                        dm_data = {scan_data[15:8],{24{1'b0}}};
                        dm_bit_en = {{8{1'b0}},{24{1'b1}}};
                end
                else if (data_addr_valid==2'b11) begin
                        dm_data = {scan_data[15:0],{16{1'b0}}};
                        dm_bit_en = {{16{1'b0}},{16{1'b1}}};
                end
                else if (data_addr_valid==2'b00) begin
                        dm_data = {scan_data[15:0],{16{1'b0}}};
                        dm_bit_en = {{16{1'b1}},{16{1'b1}}};
                end
        end // address[1] is 0
	else begin                        
		dm_data = {scan_data[15:0],{16{1'b0}}};
		dm_bit_en = {{16{1'b1}},{16{1'b1}}};
	end	
end // address[12] is 1-DM
else begin                        
	dm_data = {scan_data[15:0],{16{1'b0}}};
	dm_bit_en = {{16{1'b1}},{16{1'b1}}};
end	
end
end

//Control memory is byte addressable
always @ (posedge clk)
begin
if (reset) begin
	cm_data = {{64{1'b0}}};
	cm_bit_en = {{8{1'b1}},{8{1'b1}},{48{1'b1}}};
end
else begin
if (address[12]==1'b0 && address[13]==1'b0) begin
        if(address[2:1]==2'b00) begin
                if (data_addr_valid==2'b01) begin
                        cm_data = {{56{1'b0}},scan_data[7:0]};
			cm_bit_en = {{56{1'b1}},{8{1'b0}}};
                end
                else if (data_addr_valid==2'b10) begin
                        cm_data = {{48{1'b0}},scan_data[15:8],{8{1'b0}}};
			cm_bit_en = {{48{1'b1}},{8{1'b0}},{8{1'b1}}};
                end
                else if (data_addr_valid==2'b11) begin
                        cm_data = {{48{1'b0}},scan_data[15:0]};
			cm_bit_en = {{48{1'b1}},{8{1'b0}},{8{1'b0}}};
                end
                else if (data_addr_valid==2'b00) begin
                        cm_data = {{48{1'b0}},scan_data[15:0]};
			cm_bit_en = {{48{1'b1}},{8{1'b1}},{8{1'b1}}};
                end
        end
        else if(address[2:1]==2'b01) begin
                if (data_addr_valid==2'b01) begin
                        cm_data = {{40{1'b0}},scan_data[7:0],{16{1'b0}}};
			cm_bit_en = {{40{1'b1}},{8{1'b0}},{16{1'b1}}};
                end
                else if (data_addr_valid==2'b10) begin
                        cm_data = {{32{1'b0}},scan_data[15:8],{8{1'b0}},{16{1'b0}}};
			cm_bit_en = {{32{1'b1}},{8{1'b0}},{24{1'b1}}};
                end
                else if (data_addr_valid==2'b11) begin
                        cm_data = {{32{1'b0}},scan_data[15:0],{16{1'b0}}};
			cm_bit_en = {{32{1'b1}},{16{1'b0}},{16{1'b1}}};
                end
                else if (data_addr_valid==2'b00) begin
                        cm_data = {{32{1'b0}},scan_data[15:0],{16{1'b0}}};
			cm_bit_en = {{32{1'b1}},{16{1'b1}},{16{1'b1}}};
                end
        end
        else if(address[2:1]==2'b10) begin
                if (data_addr_valid==2'b01) begin
                        cm_data = {{24{1'b0}},scan_data[7:0],{32{1'b0}}};
			cm_bit_en = {{24{1'b1}},{8{1'b0}},{32{1'b1}}};
                end
                else if (data_addr_valid==2'b10) begin
                        cm_data = {{16{1'b0}},scan_data[15:8],{8{1'b0}},{32{1'b0}}};
			cm_bit_en = {{16{1'b1}},{8{1'b0}},{40{1'b1}}};
                end
                else if (data_addr_valid==2'b11) begin
                        cm_data = {{16{1'b0}},scan_data[15:0],{32{1'b0}}};
			cm_bit_en = {{16{1'b1}},{16{1'b0}},{32{1'b1}}};
                end
                else if (data_addr_valid==2'b00) begin
                        cm_data = {{16{1'b0}},scan_data[15:0],{32{1'b0}}};
			cm_bit_en = {{16{1'b1}},{16{1'b1}},{32{1'b1}}};
                end
        end
        else if(address[2:1]==2'b11) begin
                if (data_addr_valid==2'b01) begin
                        cm_data = {{8{1'b0}},scan_data[7:0],{48{1'b0}}};
			cm_bit_en = {{8{1'b1}},{8{1'b0}},{48{1'b1}}};
                end
                else if (data_addr_valid==2'b10) begin
                        cm_data = {scan_data[15:8],{8{1'b0}},{48{1'b0}}};
			cm_bit_en = {{8{1'b0}},{8{1'b1}},{48{1'b1}}};
                end
                else if (data_addr_valid==2'b11) begin
                        cm_data = {scan_data[15:0],{48{1'b0}}};
			cm_bit_en = {{8{1'b0}},{8{1'b0}},{48{1'b1}}};
                end
                else if (data_addr_valid==2'b00) begin
                        cm_data = {scan_data[15:0],{48{1'b0}}};
			cm_bit_en = {{8{1'b1}},{8{1'b1}},{48{1'b1}}};
                end
        end
	else begin
		cm_data = {{64{1'b0}}};
		cm_bit_en = {{8{1'b1}},{8{1'b1}},{48{1'b1}}};
	end
end //address[12] is 0 -CM
else begin
	cm_data = {{64{1'b0}}};
	cm_bit_en = {{8{1'b1}},{8{1'b1}},{48{1'b1}}};
end
end
end 

reg [15:0] cm_en;
reg [63:0] cm_bit_en0;
reg [63:0] cm_bit_en1;
reg [63:0] cm_bit_en2;
reg [63:0] cm_bit_en3;
reg [63:0] cm_bit_en4;
reg [63:0] cm_bit_en5;
reg [63:0] cm_bit_en6;
reg [63:0] cm_bit_en7;
reg [63:0] cm_bit_en8;
reg [63:0] cm_bit_en9;
reg [63:0] cm_bit_en10;
reg [63:0] cm_bit_en11;
reg [63:0] cm_bit_en12;
reg [63:0] cm_bit_en13;
reg [63:0] cm_bit_en14;
reg [63:0] cm_bit_en15;

//Based on address, determines if control memory is to be enabled
always @ (posedge clk)
begin
if (reset) begin
	cm_en = 16'b0000000000000000;
end
else begin
        if(data_addr_valid==2'b00 || scan_data_or_addr==1'b1 || (address[12]==1'b1) || (address[13]==1'b1)) begin
                cm_en = 16'b0000000000000000;
	end
        else begin //this is if it is a CM
                case(address[11:8])
                4'b0000: cm_en = 16'b0000000000000001;
                4'b0001: cm_en = 16'b0000000000000010;
                4'b0010: cm_en = 16'b0000000000000100;
                4'b0011: cm_en = 16'b0000000000001000;
                4'b0100: cm_en = 16'b0000000000010000;
                4'b0101: cm_en = 16'b0000000000100000;
                4'b0110: cm_en = 16'b0000000001000000;
                4'b0111: cm_en = 16'b0000000010000000;
                4'b1000: cm_en = 16'b0000000100000000;
                4'b1001: cm_en = 16'b0000001000000000;
                4'b1010: cm_en = 16'b0000010000000000;
                4'b1011: cm_en = 16'b0000100000000000;
                4'b1100: cm_en = 16'b0001000000000000;
                4'b1101: cm_en = 16'b0010000000000000;
                4'b1110: cm_en = 16'b0100000000000000;
                4'b1111: cm_en = 16'b1000000000000000;
		default : cm_en = 16'b0000000000000000;
                endcase //case
        end //else this is if it is a DM
end
end

assign cm_bit_en0 = (cm_en == 16'b0000000000000001) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en1 = (cm_en == 16'b0000000000000010) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en2 = (cm_en == 16'b0000000000000100) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en3 = (cm_en == 16'b0000000000001000) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en4 = (cm_en == 16'b0000000000010000) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en5 = (cm_en == 16'b0000000000100000) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en6 = (cm_en == 16'b0000000001000000) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en7 = (cm_en == 16'b0000000010000000) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en8 = (cm_en == 16'b0000000100000000) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en9 = (cm_en == 16'b0000001000000000) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en10 = (cm_en == 16'b0000010000000000) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en11 = (cm_en == 16'b0000100000000000) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en12 = (cm_en == 16'b0001000000000000) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en13 = (cm_en == 16'b0010000000000000) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en14 = (cm_en == 16'b0100000000000000) ? cm_bit_en : {64{1'b1}};
assign cm_bit_en15 = (cm_en == 16'b1000000000000000) ? cm_bit_en : {64{1'b1}};
	
//Look-up table
always @ (posedge clk)
begin
if (reset)
begin
        look_up_table_reg <= {64{1'b0}};
end
else if (chip_en)
begin
        if (address[13] == 1'b1) begin
                if(address[1:0]==2'b00) look_up_table_reg[15:0] <= scan_data;
                if(address[1:0]==2'b01) look_up_table_reg[31:16] <= scan_data;
                if(address[1:0]==2'b10) look_up_table_reg[47:32] <= scan_data;
                if(address[1:0]==2'b11) look_up_table_reg[63:48] <= scan_data;
        end
end
end

always @ (posedge clk)
begin
if (reset)
begin
        start_exec <= 1'b0;
end
else if (chip_en)
begin
                start_exec <= scan_start_exec;
end
end

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Internal signals
//------------------------------------------------------------------------------
logic [NUM_RESET_SYNC_STAGES-1:0]       r__reset__pff;

FlitFixed                w__flit_in                          [NUM_TILES_Y-1:0][NUM_TILES_X-1:0][TILE_NUM_INPUT_PORTS-1-2:0];
FlitFixed                w__flit_out                         [NUM_TILES_Y-1:0][NUM_TILES_X-1:0][TILE_NUM_OUTPUT_PORTS-1-3:0];
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Submodule
//------------------------------------------------------------------------------
//logic scan_chain_en_out [NUM_TILES_Y-1:0][NUM_TILES_X-1:0];
//logic scan_chain_in_out [NUM_TILES_Y-1:0][NUM_TILES_X-1:0];
logic scan_chain_out_out [NUM_TILES_Y-1:0][NUM_TILES_X-1:0];

logic [63:0] data_out_cm_out [NUM_TILES_Y-1:0][NUM_TILES_X-1:0];
logic rd_en_shifted_out [NUM_TILES_Y-1:0][NUM_TILES_X-1:0];
logic [4:0] addr_shifted_out [NUM_TILES_Y-1:0][NUM_TILES_X-1:0];
logic [8:0] addr_dm_out [NUM_TILES_Y-1:0][NUM_TILES_X-1:0];
logic [31:0] bit_en_out [NUM_TILES_Y-1:0][NUM_TILES_X-1:0];
logic [31:0] data_in_dm_out [NUM_TILES_Y-1:0][NUM_TILES_X-1:0];
logic rd_en_dm_out [NUM_TILES_Y-1:0][NUM_TILES_X-1:0];
logic wr_en_dm_out [NUM_TILES_Y-1:0][NUM_TILES_X-1:0];
wire [4:0] addr;
wire [8:0] addr_dm_shifted0;
wire [31:0] bit_en_shifted0;
wire [31:0] data_in_dm_shifted0;
wire chip_en_dm_shifted0;
wire wr_en_dm_shifted0;

wire [31:0] data_out_dm0;

wire [8:0] addr_dm_shifted4;
wire [31:0] bit_en_shifted4;
wire [31:0] data_in_dm_shifted4;
wire chip_en_dm_shifted4;
wire wr_en_dm_shifted4;

wire [31:0] data_out_dm4;

wire [8:0] addr_dm_shifted8;
wire [31:0] bit_en_shifted8;
wire [31:0] data_in_dm_shifted8;
wire chip_en_dm_shifted8;
wire wr_en_dm_shifted8;

wire [31:0] data_out_dm8;


wire [8:0] addr_dm_shifted12;
wire [31:0] bit_en_shifted12;
wire [31:0] data_in_dm_shifted12;
wire chip_en_dm_shifted12;
wire wr_en_dm_shifted12;

wire [31:0] data_out_dm12;

wire clk_shifted;
wire clk_shifted1;

//buf (clk_shifted, clk);
//buf (clk_shifted2, clk_shifted1);
//buf (clk_shifted, clk_shifted2);
`ifndef DC_ONLY
assign #1  clk_shifted = clk;
assign clk_shifted1 = clk;
`else
assign  clk_shifted = clk;
assign  clk_shifted1 = clk;

//DEL1D1BWPLVT clk_shifted1ns (clk,clk_shifted1);
//DEL1D1BWPLVT clk_shifted2ns (clk_shifted1,clk_shifted);
`endif

reg [8:0] addr0_bist;
reg [31:0] data_in0_bist;
reg [31:0] bit_en0_bist;
reg chip_en0_bist;
reg wr_en0_bist;
reg [8:0] addr4_bist;
reg [31:0] data_in4_bist;
reg [31:0] bit_en4_bist;
reg chip_en4_bist;
reg wr_en4_bist;
reg [8:0] addr8_bist;
reg [31:0] data_in8_bist;
reg [31:0] bit_en8_bist;
reg chip_en8_bist;
reg wr_en8_bist;
reg [8:0] addr12_bist;
reg [31:0] data_in12_bist;
reg [31:0] bit_en12_bist;
reg chip_en12_bist;
reg wr_en12_bist;
reg [1:0] count_dm_bist;


//BIST test
always @(posedge clk)
begin
if (reset) begin
	addr0_bist <= {9{1'b1}};
	data_in0_bist <= {32{1'b1}};
	bit_en0_bist <= {32{1'b1}};
	chip_en0_bist <= 1'b1;
	wr_en0_bist <= 1'b1;
	addr4_bist <= {9{1'b1}};
	data_in4_bist <= {32{1'b1}};
	bit_en4_bist <= {32{1'b1}};
	chip_en4_bist <= 1'b1;
	wr_en4_bist <= 1'b1;
	addr8_bist <= {9{1'b1}};
	data_in8_bist <= {32{1'b1}};
	bit_en8_bist <= {32{1'b1}};
	chip_en8_bist <= 1'b1;
	wr_en8_bist <= 1'b1;
	addr12_bist <= {9{1'b1}};
	data_in12_bist <= {32{1'b1}};
	bit_en12_bist <= {32{1'b1}};
	chip_en12_bist <= 1'b1;
	wr_en12_bist <= 1'b1;
	count_dm_bist <= 0;	
end
else if (chip_en&&bist_en) begin
	if (count_dm_bist==0) begin
        	addr0_bist <= 9'b000011111;
	        data_in0_bist <= {{16{1'b0}},{16{1'b1}}};
	        bit_en0_bist <= {32{1'b0}};
	        chip_en0_bist <= 0;
	        wr_en0_bist <= 0;
	        addr4_bist <= 9'b000011111;
	        data_in4_bist <= {{16{1'b0}},{16{1'b1}}};
	        bit_en4_bist <= {32{1'b0}};
	        chip_en4_bist <= 1;
	        wr_en4_bist <= 0;
	        addr8_bist <= 9'b000011111;
	        data_in8_bist <= {{16{1'b1}},{16{1'b0}}};
	        bit_en8_bist <= {32{1'b0}};
	        chip_en8_bist <= 0;
	        wr_en8_bist <= 0;
	        addr12_bist <= 9'b000011111;
	        data_in12_bist <= {{16{1'b0}},{16{1'b1}}};
        	bit_en12_bist <= {32{1'b0}};
	        chip_en12_bist <= 1;
        	wr_en12_bist <= 0;
	end
	if (count_dm_bist==1) begin
        	addr0_bist <= 9'b110011111;
	        data_in0_bist <= {{16{1'b1}},{16{1'b0}}};
	        bit_en0_bist <= {32{1'b0}};
	        chip_en0_bist <= 1;
	        wr_en0_bist <= 0;
	        addr4_bist <= 9'b110011111;
	        data_in4_bist <= {{8{1'b1}},{8{1'b0}},{8{1'b1}},{8{1'b0}}};
	        bit_en4_bist <= {32{1'b0}};
	        chip_en4_bist <= 0;
	        wr_en4_bist <= 0;
	        addr8_bist <= 9'b110011111;
	        data_in8_bist <= {{16{1'b1}},{16{1'b0}}};
	        bit_en8_bist <= {32{1'b0}};
	        chip_en8_bist <= 1;
	        wr_en8_bist <= 0;
	        addr12_bist <= 9'b110011111;
	        data_in12_bist <= {{8{1'b0}},{8{1'b1}},{8{1'b0}},{8{1'b1}}};
        	bit_en12_bist <= {32{1'b0}};
	        chip_en12_bist <= 0;
        	wr_en12_bist <= 0;
	end
	if (count_dm_bist==2) begin
        	addr0_bist <= 9'b110011111;
	        data_in0_bist <= {{16{1'b0}},{16{1'b1}}};
	        bit_en0_bist <= {32{1'b0}};
	        chip_en0_bist <= 0;
	        wr_en0_bist <= 1;
	        addr4_bist <= 9'b110011111;
	        data_in4_bist <= {{16{1'b1}},{16{1'b0}}};
	        bit_en4_bist <= {32{1'b0}};
	        chip_en4_bist <= 1;
	        wr_en4_bist <= 1;
	        addr8_bist <= 9'b110011111;
	        data_in8_bist <= {{16{1'b0}},{16{1'b1}}};
	        bit_en8_bist <= {32{1'b0}};
	        chip_en8_bist <= 0;
	        wr_en8_bist <= 1;
	        addr12_bist <= 9'b110011111;
	        data_in12_bist <= {{16{1'b1}},{16{1'b0}}};
        	bit_en12_bist <= {32{1'b0}};
	        chip_en12_bist <= 1;
        	wr_en12_bist <= 1;
	end
	if (count_dm_bist==3) begin
        	addr0_bist <= 9'b000011111;
	        data_in0_bist <= {{16{1'b0}},{16{1'b1}}};
	        bit_en0_bist <= {32{1'b0}};
	        chip_en0_bist <= 1;
	        wr_en0_bist <= 1;
	        addr4_bist <= 9'b000011111;
	        data_in4_bist <= {{16{1'b1}},{16{1'b0}}};
	        bit_en4_bist <= {32{1'b0}};
	        chip_en4_bist <= 0;
	        wr_en4_bist <= 1;
	        addr8_bist <= 9'b000011111;
	        data_in8_bist <= {{16{1'b0}},{16{1'b1}}};
	        bit_en8_bist <= {32{1'b0}};
	        chip_en8_bist <= 1;
	        wr_en8_bist <= 1;
	        addr12_bist <= 9'b000011111;
	        data_in12_bist <= {{16{1'b1}},{16{1'b0}}};
        	bit_en12_bist <= {32{1'b0}};
	        chip_en12_bist <= 0;
        	wr_en12_bist <= 1;
	end
	count_dm_bist <= count_dm_bist + 1;
end
end

always @(posedge clk) begin
if (reset) begin
	bist_success <= 1'b0;
end
else if (chip_en && bist_en) begin
	if (data_out_dm0==32'hff00ff00 && data_out_dm4==32'h0000ffff && data_out_dm8==32'h00ff00ff && data_out_dm12==32'hffff0000 && data_out_cm_out[0][0]==64'hffff0000ffffffff && data_out_cm_out[0][1]==64'hffff0000ffffffff && data_out_cm_out[0][2]==64'hffff0000ffffffff && data_out_cm_out[0][3]==64'hffff0000ffffffff && data_out_cm_out[1][0]==64'hffff0000ffffffff && data_out_cm_out[1][1]==64'hffff0000ffffffff && data_out_cm_out[1][2]==64'hffff0000ffffffff && data_out_cm_out[1][3]==64'hffff0000ffffffff && data_out_cm_out[2][0]==64'hffff0000ffffffff && data_out_cm_out[2][1]==64'hffff0000ffffffff && data_out_cm_out[2][2]==64'hffff0000ffffffff && data_out_cm_out[2][3]==64'hffff0000ffffffff && data_out_cm_out[3][0]==64'hffff0000ffffffff && data_out_cm_out[3][1]==64'hffff0000ffffffff && data_out_cm_out[3][2]==64'hffff0000ffffffff && data_out_cm_out[3][3]==64'hffff0000ffffffff)
		bist_success <= 1'b1;
	else
		bist_success <= 1'b0;
end
else
	bist_success <= 1'b0;
end

//DATA MEMORY

TSDN40LPA512X32M4F data_mem0 (            //2K each
.AA (addr_dm_shifted0),
.DA (data_in_dm_shifted0),
.BWEBA (bit_en_shifted0),
.WEBA (wr_en_dm_shifted0),
.CEBA (chip_en_dm_shifted0),
.CLKA (clk_shifted),
.AB (addr_dm_shifted4),
.DB (data_in_dm_shifted4),
.BWEBB (bit_en_shifted4),
.WEBB (wr_en_dm_shifted4),
.CEBB (chip_en_dm_shifted4),
.CLKB (clk_shifted),
.PD (1'b0),
.AMA (addr0_bist),
.DMA (data_in0_bist),
.BWEBMA (bit_en0_bist),
.WEBMA (wr_en0_bist),
.CEBMA (chip_en0_bist),
.AMB (addr4_bist),
.DMB (data_in4_bist),
.BWEBMB (bit_en4_bist),
.WEBMB (wr_en4_bist),
.CEBMB (chip_en4_bist),
.BIST (bist_en),
.CLKM (clk_shifted),
.QA (data_out_dm0),
.QB (data_out_dm4)
  );

always @(posedge clk)
if (reset)
	exec_end <= 1'b1;
else if (scan_start_exec==1'b1 && start_exec==1'b0)
	exec_end <= 1'b0;
else if (chip_en&&((addr_dm_shifted0==9'b111111111 || addr_dm_shifted4==9'b111111111) && (data_in_dm_shifted0[31:24] == {{7{1'b0}},1'b1} || data_in_dm_shifted4[31:24] == {{7{1'b0}},1'b1})))
	exec_end <= 1'b1;

TSDN40LPA512X32M4F data_mem1 (
.AA (addr_dm_shifted8),
.DA (data_in_dm_shifted8),
.BWEBA (bit_en_shifted8),
.WEBA (wr_en_dm_shifted8),
.CEBA (chip_en_dm_shifted8),
.CLKA (clk_shifted),
.AB (addr_dm_shifted12),
.DB (data_in_dm_shifted12),
.BWEBB (bit_en_shifted12),
.WEBB (wr_en_dm_shifted12),
.CEBB (chip_en_dm_shifted12),
.CLKB (clk_shifted),
.PD (1'b0),
.AMA (addr8_bist),
.DMA (data_in8_bist),
.BWEBMA (bit_en8_bist),
.WEBMA (wr_en8_bist),
.CEBMA (chip_en8_bist),
.AMB (addr12_bist),
.DMB (data_in12_bist),
.BWEBMB (bit_en12_bist),
.WEBMB (wr_en12_bist),
.CEBMB (chip_en12_bist),
.BIST (bist_en),
.CLKM (clk_shifted),
.QA (data_out_dm8),
.QB (data_out_dm12)
  );

wire [31:0] dm_data_out;
assign dm_data_out = (chip_en_dm_shifted0 == 1'b0) ? data_out_dm0[31:0] : (chip_en_dm_shifted4 == 1'b0) ? data_out_dm4[31:0] :(chip_en_dm_shifted8 == 1'b0) ? data_out_dm8[31:0] :(chip_en_dm_shifted12 == 1'b0) ? data_out_dm12[31:0] : 32'b0;


//------------------------------------------------------------------------------

generate
genvar i, j, k;

for(i = 0; i < NUM_TILES_Y; i++)
begin: y
    for(j = 0; j < NUM_TILES_X; j++)
    begin: x
        TileXYId                        my_xy_id;

        `ifdef GATE_SIM
        FlitFixed [TILE_NUM_INPUT_PORTS-1-2:0]         my_flit_in;
        FlitFixed [TILE_NUM_OUTPUT_PORTS-1-3:0]        my_flit_out;

        logic [$bits(FlitFixed)*(TILE_NUM_INPUT_PORTS-2)-1:0]         my_gate_flit_in;
        logic [$bits(FlitFixed)*(TILE_NUM_OUTPUT_PORTS-3)-1:0]        my_gate_flit_out;
        `endif
        FlitFixed        my_flit_in                      [TILE_NUM_INPUT_PORTS-1-2:0];
        FlitFixed        my_flit_out                     [TILE_NUM_OUTPUT_PORTS-1-3:0];
        assign my_xy_id.x   = j[$clog2(NUM_TILES_X)-1:0];
        assign my_xy_id.y   = i[$clog2(NUM_TILES_Y)-1:0];

`ifdef DEBUG_TRACE
//Debug statements
wire [32:0] my_flit_in_0;
wire [32:0] my_flit_in_1;
wire [32:0] my_flit_in_2;
wire [32:0] my_flit_in_3;

assign my_flit_in_0 = my_flit_in[0];
assign my_flit_in_1 = my_flit_in[1];
assign my_flit_in_2 = my_flit_in[2];
assign my_flit_in_3 = my_flit_in[3];


wire [32:0] w__flit_in_000;
wire [32:0] w__flit_in_001;
wire [32:0] w__flit_in_002;
wire [32:0] w__flit_in_003;

wire [32:0] w__flit_in_100;
wire [32:0] w__flit_in_101;
wire [32:0] w__flit_in_102;
wire [32:0] w__flit_in_103;

wire [32:0] w__flit_in_110;
wire [32:0] w__flit_in_111;
wire [32:0] w__flit_in_112;
wire [32:0] w__flit_in_113;

assign w__flit_in_000 = w__flit_in[2][2][0];  //[x][y][Direction]
assign w__flit_in_001 = w__flit_in[2][2][1];
assign w__flit_in_002 = w__flit_in[2][2][2];
assign w__flit_in_003 = w__flit_in[2][2][3];

assign w__flit_in_100 = w__flit_in[1][0][0];
assign w__flit_in_101 = w__flit_in[1][0][1];
assign w__flit_in_102 = w__flit_in[1][0][2];
assign w__flit_in_103 = w__flit_in[1][0][3];

assign w__flit_in_110 = w__flit_in[1][1][0];
assign w__flit_in_111 = w__flit_in[1][1][1];
assign w__flit_in_112 = w__flit_in[1][1][2];
assign w__flit_in_113 = w__flit_in[1][1][3];

wire [32:0] w__flit_out_000;
wire [32:0] w__flit_out_001;
wire [32:0] w__flit_out_002;
wire [32:0] w__flit_out_003;

wire [32:0] w__flit_out_100;
wire [32:0] w__flit_out_101;
wire [32:0] w__flit_out_102;
wire [32:0] w__flit_out_103;

wire [32:0] w__flit_out_110;
wire [32:0] w__flit_out_111;
wire [32:0] w__flit_out_112;
wire [32:0] w__flit_out_113;

assign w__flit_out_000 = w__flit_out[0][0][0];
assign w__flit_out_001 = w__flit_out[0][0][1];
assign w__flit_out_002 = w__flit_out[0][0][2];
assign w__flit_out_003 = w__flit_out[0][0][3];

assign w__flit_out_100 = w__flit_out[1][0][0];
assign w__flit_out_101 = w__flit_out[1][0][1];
assign w__flit_out_102 = w__flit_out[1][0][2];
assign w__flit_out_103 = w__flit_out[1][0][3];

assign w__flit_out_110 = w__flit_out[1][1][0];
assign w__flit_out_111 = w__flit_out[1][1][1];
assign w__flit_out_112 = w__flit_out[1][1][2];
assign w__flit_out_113 = w__flit_out[1][1][3];

`endif
//------------------------------------------------------------------------------
// Data memory
//------------------------------------------------------------------------------
wire [4:0] loop_start;
wire [4:0] loop_end;
wire [63:0] data_in;
wire wr_en;
wire [4:0] addr;
wire [8:0] addr_dm;
wire [31:0] bit_en;
wire [31:0] data_in_dm;
wire rd_en_dm;
wire wr_en_dm;
wire is_dm_tile;

reg wr_en_shifted;
reg rd_en_shifted;

wire scan_chain_out;
        //----------------------------------------------------------------------
        // Flit, Credit, SSR
        //----------------------------------------------------------------------
        assign my_flit_in[EAST]     = w__flit_in[i][j][EAST];
        assign my_flit_in[SOUTH]    = w__flit_in[i][j][SOUTH];
        assign my_flit_in[WEST]     = w__flit_in[i][j][WEST];
        assign my_flit_in[NORTH]    = w__flit_in[i][j][NORTH];

        assign w__flit_out[i][j][EAST]      = my_flit_out[EAST];
        assign w__flit_out[i][j][SOUTH]     = my_flit_out[SOUTH];
        assign w__flit_out[i][j][WEST]      = my_flit_out[WEST];
        assign w__flit_out[i][j][NORTH]     = my_flit_out[NORTH];

        //----------------------------------------------------------------------

        `ifdef GATE_SIM
        //----------------------------------------------------------------------
        // Gate level connection
        //----------------------------------------------------------------------
        assign my_gate_flit_in                      = my_flit_in;
        assign `LINK_DELAY my_flit_out           = my_gate_flit_out;

        //----------------------------------------------------------------------
        `endif

wire [31:0] data_out_dm;
//modify to specify data into tile by wangbo
assign data_out_dm = (my_xy_id==4'b0000) ? data_out_dm0[31:0] : (my_xy_id==4'b0100) ? data_out_dm4[31:0] : (my_xy_id==4'b1000) ? data_out_dm8[31:0] : (my_xy_id==4'b1100) ? data_out_dm12[31:0] : 32'b0;


assign is_dm_tile = (my_xy_id==4'b0000) ? 1'b1 : (my_xy_id==4'b0001) ? 1'b0 : (my_xy_id==4'b0010) ? 1'b0 : (my_xy_id==4'b0011) ? 1'b0 : (my_xy_id==4'b0100) ? 1'b1 : (my_xy_id==4'b0101) ? 1'b0 : (my_xy_id==4'b0110) ? 1'b0 : (my_xy_id==4'b0111) ? 1'b0 : (my_xy_id==4'b1000) ? 1'b1 : (my_xy_id==4'b1001) ? 1'b0 : (my_xy_id==4'b1010) ? 1'b0 : (my_xy_id==4'b1011) ? 1'b0 : (my_xy_id==4'b1100) ? 1'b1 : (my_xy_id==4'b1101) ? 1'b0 : (my_xy_id==4'b1110) ? 1'b0 : 1'b0 ;


wire [63:0] data_out;
reg [4:0] addr_shifted;
reg [63:0] control_reg_data;
//assign wr_en_shifted = (!start_exec) ? read_write : 1'b1;
//assign rd_en_shifted = (start_exec) ? 1'b0 : ~read_write;

always @(posedge clk) begin
if (reset) begin
	wr_en_shifted <= 1'b1;
	rd_en_shifted <= 1'b1;
end
else if(chip_en) begin
	if (scan_start_exec) begin
		rd_en_shifted <= 1'b0;
		wr_en_shifted <= 1'b1;
	end
	else begin
		rd_en_shifted <= ~read_write;
		wr_en_shifted <= read_write;
	end
end
end

wire [5:0] loop_end_dash;

assign loop_end_dash = (loop_end < loop_start) ? (loop_end + 6'b100000) : loop_end;  //incase loopstart (say 30) addr is greater than loopend address (say 5)


//wangbo
assign addr_dm_out[i][j] = addr_dm;
assign bit_en_out[i][j] = bit_en;
assign data_in_dm_out[i][j] = data_in_dm;
assign rd_en_dm_out[i][j] = rd_en_dm;
assign wr_en_dm_out[i][j] = wr_en_dm;
assign rd_en_shifted_out[i][j] = rd_en_shifted;
assign data_out_cm_out[i][j] = data_out;
assign scan_chain_en = scan_en;
assign scan_chain_in = scan_in;
assign scan_chain_out_out[i][j] = scan_chain_out;

reg [4:0] jumpl_reg;
always @(posedge clk)
begin
if (reset)
	jumpl_reg <= 5'b00000;
else if(chip_en) begin
	jumpl_reg <= control_reg_data[34:30];
end
end

always @(posedge clk)
begin
if (reset)
	addr_shifted <= 5'b00000;
else if (chip_en) begin
	if (start_exec) begin
		if (control_reg_data[34:30]==5'b11110 && jumpl_reg != 5'b11110) begin
			addr_shifted <= control_reg_data[49:45];
		end
		else if ((addr_shifted >= loop_end_dash) || (addr_shifted < loop_start)) begin
			addr_shifted <= loop_start;
		end
		else begin
			addr_shifted <= addr_shifted + 1;
		end
	end
	else begin 
		addr_shifted <= address[7:3];
	end
end
end

assign addr_shifted_out[i][j] = addr_shifted;
reg [63:0] cm_bit_en_shifted;

//assign cm_bit_en_shifted = (my_xy_id==4'b0000) ? cm_bit_en0 : (my_xy_id==4'b0001) ? cm_bit_en1 : (my_xy_id==4'b0010) ? cm_bit_en2 :(my_xy_id==4'b0011) ? cm_bit_en3 :(my_xy_id==4'b0100) ? cm_bit_en4 :(my_xy_id==4'b0101) ? cm_bit_en5 :(my_xy_id==4'b0110) ? cm_bit_en6 :(my_xy_id==4'b0111) ? cm_bit_en7 :(my_xy_id==4'b1000) ? cm_bit_en8 :(my_xy_id==4'b1001) ? cm_bit_en9 :(my_xy_id==4'b1010) ? cm_bit_en10 :(my_xy_id==4'b1011) ? cm_bit_en11 :(my_xy_id==4'b1100) ? cm_bit_en12 :(my_xy_id==4'b1101) ? cm_bit_en13 :(my_xy_id==4'b1110) ? cm_bit_en14 :(my_xy_id==4'b1111) ? cm_bit_en15 : {64{1'b1}};
always @(posedge clk) begin
if (reset)
	cm_bit_en_shifted <= {64{1'b1}};
else if (chip_en) begin
	if (my_xy_id==4'b0000)
		cm_bit_en_shifted <= cm_bit_en0;
	else if (my_xy_id==4'b0001)
		cm_bit_en_shifted <= cm_bit_en1;
	else if (my_xy_id==4'b0010)
		cm_bit_en_shifted <= cm_bit_en2;
	else if (my_xy_id==4'b0011)
		cm_bit_en_shifted <= cm_bit_en3;
	else if (my_xy_id==4'b0100)
		cm_bit_en_shifted <= cm_bit_en4;
	else if (my_xy_id==4'b0101)
		cm_bit_en_shifted <= cm_bit_en5;
	else if (my_xy_id==4'b0110)
		cm_bit_en_shifted <= cm_bit_en6;
	else if (my_xy_id==4'b0111)
		cm_bit_en_shifted <= cm_bit_en7;
	else if (my_xy_id==4'b1000)
		cm_bit_en_shifted <= cm_bit_en8;
	else if (my_xy_id==4'b1001)
		cm_bit_en_shifted <= cm_bit_en9;
	else if (my_xy_id==4'b1010)
		cm_bit_en_shifted <= cm_bit_en10;
	else if (my_xy_id==4'b1011)
		cm_bit_en_shifted <= cm_bit_en11;
	else if (my_xy_id==4'b1100)
		cm_bit_en_shifted <= cm_bit_en12;
	else if (my_xy_id==4'b1101)
		cm_bit_en_shifted <= cm_bit_en13;
	else if (my_xy_id==4'b1110)
		cm_bit_en_shifted <= cm_bit_en14;
	else if (my_xy_id==4'b1111)
		cm_bit_en_shifted <= cm_bit_en15;
	else 
		cm_bit_en_shifted <= {64{1'b1}};
end
end

reg [63:0] cm_data_shifted;
always @(posedge clk) begin
if (reset) begin
	cm_data_shifted <= 64'b0;
end
else if (chip_en) begin
	cm_data_shifted <= cm_data;
end
end

reg [4:0] cm_addr_bist;
reg [63:0] cm_data_in_bist;
reg [63:0] cm_bit_en_bist;
reg cm_wr_en_bist;
reg cm_rd_en_bist;
reg [1:0] cm_count_bist;

always @(posedge clk) begin
if (reset) begin
	cm_addr_bist <= 5'b11111;
	cm_data_in_bist <= {64{1'b1}};
	cm_bit_en_bist <= {64{1'b1}};
	cm_wr_en_bist <= 1'b1;
	cm_rd_en_bist <= 1'b1;
	cm_count_bist <= 0;
end
else if (chip_en&&bist_en) begin
	if (cm_count_bist==0) begin
		cm_addr_bist <= 5'b10101;
		cm_data_in_bist <= {{16{1'b1}},{16{1'b0}},{32{1'b1}}};
		cm_bit_en_bist <= {64{1'b0}};
		cm_wr_en_bist <= 0;
		cm_rd_en_bist <= 1;
	end
	if (cm_count_bist==1) begin
		cm_addr_bist <= 5'b10111;
		cm_data_in_bist <= {{16{1'b1}},{16{1'b0}},{32{1'b1}}};
		cm_bit_en_bist <= {64{1'b0}};
		cm_wr_en_bist <= 0;
		cm_rd_en_bist <= 1;
	end
	if (cm_count_bist==2) begin
		cm_addr_bist <= 5'b10111;
		cm_data_in_bist <= {{16{1'b1}},{16{1'b0}},{32{1'b1}}};
		cm_bit_en_bist <= {64{1'b0}};
		cm_wr_en_bist <= 1;
		cm_rd_en_bist <= 0;
	end
	if (cm_count_bist==3) begin
		cm_addr_bist <= 5'b10101;
		cm_data_in_bist <= {{16{1'b1}},{16{1'b0}},{32{1'b1}}};
		cm_bit_en_bist <= {64{1'b0}};
		cm_wr_en_bist <= 1;
		cm_rd_en_bist <= 0;
	end
	cm_count_bist <= cm_count_bist + 1;
end
end

TS6N40LPA24X64M2F control_mem (
.AA (addr_shifted),
.D (cm_data_shifted),
.BWEB (cm_bit_en_shifted),
.WEB (wr_en_shifted),
.CLKW (clk_shifted),
.AB (addr_shifted),
.REB (rd_en_shifted),
.CLKR (clk_shifted),
.PD (1'b0),
.AMA (cm_addr_bist),
.DM (cm_data_in_bist),
.BWEBM (cm_bit_en_bist),
.WEBM (cm_wr_en_bist),
.AMB (cm_addr_bist),
.REBM (cm_rd_en_bist),
.BIST (bist_en),
.Q (data_out)
);

`ifdef VCS_ONLY
always @(posedge clk_shifted)
begin
if (reset) begin

end

else begin
	if (addr_shifted >= 5'd24) begin
	$display ("ASK address is greater than 24 = %b and from testbench is %b at core %d", addr_shifted, address[7:3], my_xy_id);
	assert (addr_shifted >= 5'd24); 
	end
end
end
`endif

always @(posedge clk)
begin
if (r__reset__pff[NUM_RESET_SYNC_STAGES-1])
control_reg_data <= {{43{1'b0}},{21{1'b1}}};
else 
	if (chip_en&&start_exec)
		control_reg_data <= data_out;
end

        tile
        //    `ifndef GATE_SIM
        //   #(
        //        .NIC_OUTPUT_FIFO_DEPTH  (NIC_OUTPUT_FIFO_DEPTH),
        //        .ROUTER_NUM_VCS         (ROUTER_NUM_VCS)
        //    )
        //    `endif
            tile(
                .clk                                (clk_shifted1),
                .reset                              (r__reset__pff[NUM_RESET_SYNC_STAGES-1]),
                `ifdef GATE_SIM
                .i__flit_in                         (my_gate_flit_in),
                .o__flit_out                        (my_gate_flit_out),
                `else
                .i__flit_in                         (my_flit_in),
                .o__flit_out                        (my_flit_out),
                `endif
		.control_reg_data		    (control_reg_data),
		.is_dm_tile			    (is_dm_tile),
		.start_exec			    (start_exec),
		.loop_start		    	    (loop_start),
		.loop_end		    	    (loop_end),
		.look_up_table		    	    (look_up_table_reg),
		.data_in_dm			    (data_in_dm),
		.data_out_dm			    (data_out_dm),
		.addr_dm			    (addr_dm),
		.bit_en				    (bit_en),
		.rd_en_dm			    (rd_en_dm),
		.wr_en_dm			    (wr_en_dm),
		.scan_en			    (scan_chain_en),
		.scan_in			    (scan_chain_in),
		.scan_out			    (scan_chain_out)
            );
    end
end



`ifndef LINK_PHYSICAL
for(i = 0; i < NUM_TILES_Y; i++)
begin: y_connection
    for(j = 0; j < NUM_TILES_X; j++)
    begin: x_connection

        //----------------------------------------------------------------------
        // Flit and credit
        //----------------------------------------------------------------------
        // East
        if(j < (NUM_TILES_X-1))
        begin: flit_east
            assign w__flit_in[i][j][EAST]   = w__flit_out[i][j + 1][WEST];
        end
        else
        begin: flit_east_out
            assign w__flit_in[i][j][EAST]   = '0;
        end

        // South
        if(i >= 1)
        begin: flit_south
            assign w__flit_in[i][j][NORTH]      = w__flit_out[i - 1][j][SOUTH];
        end
        else
        begin: flit_south_out
            assign w__flit_in[i][j][NORTH]      = '0;
        end

        // West
        if(j >= 1)
        begin: flit_west
            assign w__flit_in[i][j][WEST]   = w__flit_out[i][j - 1][EAST];
        end
        else
        begin: flit_west_out
            assign w__flit_in[i][j][WEST]   = '0; 
        end

        // North
        if(i < (NUM_TILES_Y-1))
        begin: flit_north
            assign w__flit_in[i][j][SOUTH]      = w__flit_out[i + 1][j][NORTH];
        end
        else
        begin: flit_north_out
            assign w__flit_in[i][j][SOUTH]      = '0;
        end
        //----------------------------------------------------------------------

    end
end
`else
// Only works for NUM_TILES_Y == NUM_TILES_X == 8, FLIT_WIDTH == 64, CREDIT_WIDTH == 4+1, SSR_WIDTH == 4
for(i = 0; i < NUM_TILES_Y; i++)
begin: horizontal
    logic [32:0]                        my_flit_in_east     [2:0];
    logic [32:0]                        my_flit_out_east    [2:0];
    logic [32:0]                        my_flit_in_west     [2:0];
    logic [32:0]                        my_flit_out_west    [2:0];

    for(j = 0; j < NUM_TILES_X-1; j++)
    begin: flit
        assign my_flit_in_east[j]   = w__flit_out[i][j][EAST];
        assign my_flit_in_west[j]   = w__flit_out[i][NUM_TILES_X-j-1][WEST];

        `ifdef LINK_DELAY
        assign `LINK_DELAY w__flit_in[i][j+1][WEST]                     = my_flit_out_east[j];
        assign `LINK_DELAY w__flit_in[i][NUM_TILES_X-j-2][EAST]         = my_flit_out_west[j];
        `else
        assign w__flit_in[i][j+1][WEST]                     = my_flit_out_east[j];
        assign w__flit_in[i][NUM_TILES_X-j-2][EAST]         = my_flit_out_west[j];
        `endif

    end

    assign w__flit_in[i][0][WEST]               = '0;
    assign w__flit_in[i][NUM_TILES_X-1][EAST]   = '0;

    link_physical_horizontal
        link_east(
            .i__flit_in_0               (my_flit_in_east[0]),
            .i__flit_in_1               (my_flit_in_east[1]),
            .i__flit_in_2               (my_flit_in_east[2]),
            .o__flit_out_0              (my_flit_out_east[0]),
            .o__flit_out_1              (my_flit_out_east[1]),
            .o__flit_out_2              (my_flit_out_east[2])
        );

    link_physical_horizontal
        link_west(
            .i__flit_in_0               (my_flit_in_west[0]),
            .i__flit_in_1               (my_flit_in_west[1]),
            .i__flit_in_2               (my_flit_in_west[2]),
            .o__flit_out_0              (my_flit_out_west[0]),
            .o__flit_out_1              (my_flit_out_west[1]),
            .o__flit_out_2              (my_flit_out_west[2])
        );

end

for(i = 0; i < NUM_TILES_X; i++)
begin: vertical
    logic [32:0]                        my_flit_in_north    [2:0];
    logic [32:0]                        my_flit_out_north   [2:0];
    logic [32:0]                        my_flit_in_south    [2:0];
    logic [32:0]                        my_flit_out_south   [2:0];

    for(j = 0; j < NUM_TILES_Y-1; j++)
    begin: flit
        assign my_flit_in_south[j]          = w__flit_out[j][i][SOUTH];
        assign my_flit_in_north[j]          = w__flit_out[NUM_TILES_Y-j-1][i][NORTH];

        `ifdef LINK_DELAY
        assign `LINK_DELAY w__flit_in[j+1][i][NORTH]                                = my_flit_out_south[j];
        assign `LINK_DELAY w__flit_in[NUM_TILES_Y-j-2][i][SOUTH]                    = my_flit_out_north[j];
        `else
        assign w__flit_in[j+1][i][NORTH]                                = my_flit_out_south[j];
        assign w__flit_in[NUM_TILES_Y-j-2][i][SOUTH]                    = my_flit_out_north[j];
        `endif
    end

    assign w__flit_in[0][i][NORTH]                  = '0;
    assign w__flit_in[NUM_TILES_Y-1][i][SOUTH]      = '0;

    link_physical_vertical
        link_north(
            .i__flit_in_0               (my_flit_in_north[0]),
            .i__flit_in_1               (my_flit_in_north[1]),
            .i__flit_in_2               (my_flit_in_north[2]),
            .o__flit_out_0              (my_flit_out_north[0]),
            .o__flit_out_1              (my_flit_out_north[1]),
            .o__flit_out_2              (my_flit_out_north[2])
        );

    link_physical_vertical
        link_south(
            .i__flit_in_0               (my_flit_in_south[0]),
            .i__flit_in_1               (my_flit_in_south[1]),
            .i__flit_in_2               (my_flit_in_south[2]),
            .o__flit_out_0              (my_flit_out_south[0]),
            .o__flit_out_1              (my_flit_out_south[1]),
            .o__flit_out_2              (my_flit_out_south[2])
        );

end

`endif

endgenerate


//Determines the input to the data memory - if from HyCUBE/tile or from external program input

assign addr_dm_shifted0 = (!start_exec) ? address[10:2] : addr_dm_out[0][0];
assign bit_en_shifted0 = (!start_exec) ? dm_bit_en : bit_en_out[0][0];
assign data_in_dm_shifted0 = (!start_exec) ? dm_data : data_in_dm_out[0][0];
assign chip_en_dm_shifted0 = (!start_exec) ? chip_en_dm0 : rd_en_dm_out[0][0];
assign wr_en_dm_shifted0 = (!start_exec) ? read_write : wr_en_dm_out[0][0];

assign addr_dm_shifted4 = (!start_exec) ? address[10:2] : addr_dm_out[1][0];
assign bit_en_shifted4 = (!start_exec) ? dm_bit_en : bit_en_out[1][0];
assign data_in_dm_shifted4 = (!start_exec) ? dm_data : data_in_dm_out[1][0];
assign chip_en_dm_shifted4 = (!start_exec) ? chip_en_dm4 : rd_en_dm_out[1][0];
assign wr_en_dm_shifted4 = (!start_exec) ? read_write : wr_en_dm_out[1][0];

assign addr_dm_shifted8 = (!start_exec) ? address[10:2] : addr_dm_out[2][0];
assign bit_en_shifted8 = (!start_exec) ? dm_bit_en : bit_en_out[2][0];
assign data_in_dm_shifted8 = (!start_exec) ? dm_data : data_in_dm_out[2][0];
assign chip_en_dm_shifted8 = (!start_exec) ? chip_en_dm8 : rd_en_dm_out[2][0];
assign wr_en_dm_shifted8 = (!start_exec) ? read_write : wr_en_dm_out[2][0];

assign addr_dm_shifted12 = (!start_exec) ? address[10:2] : addr_dm_out[3][0];
assign bit_en_shifted12 = (!start_exec) ? dm_bit_en : bit_en_out[3][0];
assign data_in_dm_shifted12 = (!start_exec) ? dm_data : data_in_dm_out[3][0];
assign chip_en_dm_shifted12 = (!start_exec) ? chip_en_dm12 : rd_en_dm_out[3][0];
assign wr_en_dm_shifted12 = (!start_exec) ? read_write : wr_en_dm_out[3][0];

assign scan_out[0] = (scan_chain_sel_0==2'b00) ? scan_chain_out_out[0][0] : (scan_chain_sel_0==2'b01) ? scan_chain_out_out[0][1] : (scan_chain_sel_0==2'b10) ? scan_chain_out_out[0][2] :  scan_chain_out_out[0][3];

assign scan_out[1] = (scan_chain_sel_1==2'b00) ? scan_chain_out_out[1][0] : (scan_chain_sel_1==2'b01) ? scan_chain_out_out[1][1] : (scan_chain_sel_1==2'b10) ? scan_chain_out_out[1][2] :  scan_chain_out_out[1][3];

assign scan_out[2] = (scan_chain_sel_2==2'b00) ? scan_chain_out_out[2][0] : (scan_chain_sel_2==2'b01) ? scan_chain_out_out[2][1] : (scan_chain_sel_2==2'b10) ? scan_chain_out_out[2][2] :  scan_chain_out_out[2][3];

assign scan_out[3] = (scan_chain_sel_3==2'b00) ? scan_chain_out_out[3][0] : (scan_chain_sel_3==2'b01) ? scan_chain_out_out[3][1] : (scan_chain_sel_3==2'b10) ? scan_chain_out_out[3][2] :  scan_chain_out_out[3][3];

wire [63:0] cm_data_out;
reg [15:0] cm_addr_out;



always @(posedge clk) begin
if (reset) begin
        cm_addr_out <= {16{1'b0}};
end
else if (chip_en&&read_write) begin
	cm_addr_out <= address [15:0];
end
end

assign cm_data_out = ((cm_addr_out[11:8]==4'b0000)&&(!start_exec)&&(~rd_en_shifted_out[0][0])) ? data_out_cm_out[0][0] : ((cm_addr_out[11:8]==4'b0001)&&(!start_exec)&&(~rd_en_shifted_out[0][1])) ? data_out_cm_out[0][1] : ((cm_addr_out[11:8]==4'b0010)&&(!start_exec)&&(~rd_en_shifted_out[0][2])) ? data_out_cm_out[0][2] : ((cm_addr_out[11:8]==4'b0011)&&(!start_exec)&&(~rd_en_shifted_out[0][3])) ? data_out_cm_out[0][3] : ((cm_addr_out[11:8]==4'b0100)&&(!start_exec)&&(~rd_en_shifted_out[1][0])) ? data_out_cm_out[1][0] : ((cm_addr_out[11:8]==4'b0101)&&(!start_exec)&&(~rd_en_shifted_out[1][1])) ? data_out_cm_out[1][1] : ((cm_addr_out[11:8]==4'b0110)&&(!start_exec)&&(~rd_en_shifted_out[1][2])) ? data_out_cm_out[1][2] : ((cm_addr_out[11:8]==4'b0111)&&(!start_exec)&&(~rd_en_shifted_out[1][3])) ? data_out_cm_out[1][3] : ((cm_addr_out[11:8]==4'b1000)&&(!start_exec)&&(~rd_en_shifted_out[2][0])) ? data_out_cm_out[2][0] : ((cm_addr_out[11:8]==4'b1001)&&(!start_exec)&&(~rd_en_shifted_out[2][1])) ? data_out_cm_out[2][1] : ((cm_addr_out[11:8]==4'b1100)&&(!start_exec)&&(~rd_en_shifted_out[2][2])) ? data_out_cm_out[2][2] : ((cm_addr_out[11:8]==4'b1011)&&(!start_exec)&&(~rd_en_shifted_out[2][3])) ? data_out_cm_out[2][3] : ((cm_addr_out[11:8]==4'b1100)&&(!start_exec)&&(~rd_en_shifted_out[3][0])) ? data_out_cm_out[3][0] : ((cm_addr_out[11:8]==4'b1101)&&(!start_exec)&&(~rd_en_shifted_out[3][1])) ? data_out_cm_out[3][1] : ((cm_addr_out[11:8]==4'b1110)&&(!start_exec)&&(~rd_en_shifted_out[3][2])) ? data_out_cm_out[3][2] : data_out_cm_out[3][3];


always @(posedge clk) begin
if (reset) begin
        data_inout <= {16{1'b0}};
	data_out_valid <= 1'b0;
end
else if (chip_en) begin
	if (read_write && data_addr_valid_reg==2'b11 && data_or_addr_reg==1'b0) begin
        if(address[12]==1'b1 && address[13]==1'b0) begin
			data_out_valid <= 1'b1;
                if(address[1]==1'b0) begin
                        data_inout <= dm_data_out[15:0];
		end
                else if (address[1]==1'b1) begin
                        data_inout <= dm_data_out[31:16];
		end
        end
	//else begin
        else if(cm_addr_out[12]==1'b0 && cm_addr_out[13]==1'b0) begin
			data_out_valid <= 1'b1;
		if(cm_addr_out[2:1]==2'b00) begin
			data_inout <= cm_data_out[15:0];
		end
		else if(cm_addr_out[2:1]==2'b01) begin
			data_inout <= cm_data_out[31:16];
		end
		else if(cm_addr_out[2:1]==2'b10) begin
			data_inout <= cm_data_out[47:32];
		end
		else if(cm_addr_out[2:1]==2'b11) begin
			data_inout <= cm_data_out[63:48];
		end

        end
	else begin
		data_inout <= 16'b0;
		data_out_valid <= 1'b0;
	end
	end
	else begin
		data_inout <= 16'b0;
		data_out_valid <= 1'b0;
	end
end
end


//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Reset synchronizer
//------------------------------------------------------------------------------
always_ff @ (posedge clk)
begin
    if(reset == 1'b1)
    begin
        r__reset__pff <= '1;
    end
    else if (chip_en) 
    begin
        r__reset__pff <= {r__reset__pff[NUM_RESET_SYNC_STAGES-2:0], 1'b0};
    end
end
//------------------------------------------------------------------------------


endmodule

