////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Project Name: HyCUBE (Verilog, SystemVerilog)                          ////
////                                                                        ////
//// Module Name: chip                                                      ////
////                                                                        ////
////                                                                        ////
////  This file is part of HyCUBE                                           ////
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

module chip(
    reset_network,
    sck,
    ss,
    sdin,
    sdout,
    scan_data,
    scan_data_or_addr,
    read_write,
    data_out_valid,
    data_addr_valid,
    scan_start_exec,
    exec_end,
    chip_en,
    bist_success,
    spi_en,
    bist_en,
    vcoEn, 
    clkExtEn, 
    clkExt, 
    clkSel, 
    divSel, 
    fixdivSel, 
    dlIn0, 
    dlIn1, 
    dlIn2, 
    clkEn, 
    clkOut_Mon,
    scan_chain_out,
    scan_chain_in,
    scan_chain_en,
    scan_chain_sel_0,
    scan_chain_sel_1,
    scan_chain_sel_2,
    scan_chain_sel_3
);

input logic                             reset_network;
input logic 				sck;
input logic 				ss;
input logic 				sdin;
output logic 				sdout;

input logic 				bist_en;
output logic 				bist_success;
input  logic                            scan_start_exec;
output  logic                           exec_end;
output  logic                           data_out_valid;
input  [1:0]                            data_addr_valid;
input  logic				chip_en;

inout [15:0] 				scan_data;
input  logic                            scan_data_or_addr;
input  logic                            read_write;
input logic				spi_en;

input [5:0] clkSel;
input [3:0] divSel;
input [1:0] fixdivSel;
input logic vcoEn;
input logic clkExtEn;
input logic clkExt;
input logic dlIn0;
input logic dlIn1;
input logic dlIn2;
input logic clkEn;
output clkOut_Mon;

output [3:0]                            scan_chain_out;
input   logic                           scan_chain_in;
input   logic                           scan_chain_en;

input [1:0]                             scan_chain_sel_0;
input [1:0]                             scan_chain_sel_1;
input [1:0]                             scan_chain_sel_2;
input [1:0]                             scan_chain_sel_3;

//-----------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
import TopPkg::*;
import SMARTPkg::*;

parameter NUM_RESET_SYNC_STAGES         = 2;

parameter NIC_OUTPUT_FIFO_DEPTH         = 1;
parameter ROUTER_NUM_VCS                = 8;

localparam DATA_WIDTH			= 16;
localparam SPI_DATA_WIDTH		= 8;

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// IO
//------------------------------------------------------------------------------
// Network


reg sdout;
reg bist_success;
//spi
wire[DATA_WIDTH-1:0] DA_out_spi;
wire [1:0] DA_valid_out_spi;
wire DoA_out_spi;
wire rw_out_spi;
wire start_exec_out_spi;
//hycube
wire [DATA_WIDTH-1:0] data_in_hycube;
wire [DATA_WIDTH-1:0] data_out_hycube;
wire data_or_address_hycube;
wire read_write_hycube;
wire data_out_valid_hycube;
wire [1:0] data_addr_valid_hycube;
wire start_exec_hycube;
wire scan_data_or_addr_hycube;
wire scan_start_exec_hycube;
wire logic clkOut;
//------------------------------------------------------------------------------
wire [DATA_WIDTH-1:0] data_out; //output
wire [DATA_WIDTH-1:0] data_in; //output

//------------------------------------------------------------------------------

assign data_in_hycube = spi_en ? DA_out_spi : data_in;
assign scan_data_or_addr_hycube = spi_en ? DoA_out_spi : scan_data_or_addr;
assign read_write_hycube = spi_en ? rw_out_spi : read_write;
assign data_addr_valid_hycube = spi_en ? DA_valid_out_spi : data_addr_valid;
assign scan_start_exec_hycube = spi_en ? start_exec_out_spi : scan_start_exec;

//------------------------------------------------------------------------------

assign data_in = scan_data;
assign scan_data = (~spi_en && read_write && ~scan_data_or_addr) ? data_out : {16{1'bz}};

//------------------------------------------------------------------------------
// Submodule
//------------------------------------------------------------------------------

hycube hycube(
    .clk (clkOut),
    .reset (reset_network),
    .chip_en (chip_en),
    .data (data_in_hycube),
    .data_inout (data_out),
    .scan_data_or_addr (scan_data_or_addr_hycube),
    .read_write	(read_write_hycube),
    .data_out_valid(data_out_valid),
    .data_addr_valid(data_addr_valid_hycube),
    .scan_start_exec (scan_start_exec_hycube),
    .exec_end (exec_end),
    .bist_success (bist_success),
    .bist_en (bist_en),
    .scan_out (scan_chain_out),
    .scan_in (scan_chain_in),
    .scan_en (scan_chain_en),
    .scan_chain_sel_0 (scan_chain_sel_0),
    .scan_chain_sel_1 (scan_chain_sel_1),
    .scan_chain_sel_2 (scan_chain_sel_2),
    .scan_chain_sel_3 (scan_chain_sel_3)

);

spi_all spi_all(
	.reset_network (reset_network),
	.ss (ss),
	.sck (sck),
	.sdin (sdin),
	.sdout (sdout),
	.clkOut (clkOut),
	.chip_en (chip_en),
	.DA_out_spi (DA_out_spi),
	.DA_valid_out_spi (DA_valid_out_spi),
	.data_out (data_out),
	.data_out_valid (data_out_valid),
	.spi_en (spi_en),
	.DoA_out_spi (DoA_out_spi),
	.start_exec_out_spi (start_exec_out_spi),
	.exec_end (exec_end),
	.rw_out_spi (rw_out_spi)
);

clkGen_top_blmux clkGen_top_blmux_u1(
	.rstn (~reset_network), 
	.vcoEn (vcoEn), 
        .clkExtEn (clkExtEn), 
	.clkExt (clkExt), 
	.clkSel (clkSel), 
	.divSel (divSel),
	.fixdivSel (fixdivSel), 
	.dlIn0 (dlIn0), 
	.dlIn1 (dlIn1), 
	.dlIn2 (dlIn2), 
	.clkEn (clkEn), 
	.clkOut_Mon (clkOut_Mon), 
	.clkOut (clkOut) 
);

endmodule

