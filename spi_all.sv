////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Project Name: HyCUBE (Verilog, SystemVerilog)                          ////
////                                                                        ////
//// Module Name: spi_all                                                   ////
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

module spi_all(
  reset_network,
  ss,
  sck,
  sdin,
  sdout,
  clkOut,
  chip_en,
  DA_out_spi,
  DA_valid_out_spi,
  data_out,
  data_out_valid,
  spi_en,
  DoA_out_spi,
  start_exec_out_spi,
  exec_end,
  rw_out_spi
  );


localparam DATA_WIDTH=16;
localparam SPI_DATA_WIDTH=8;

input logic                             reset_network;
input logic                             sck;
input logic                             ss;
input logic                             sdin;
output logic                            sdout;

input logic                             clkOut;
input logic                             chip_en;
input logic                             exec_end;
input [DATA_WIDTH-1:0]                  data_out;
input logic                             data_out_valid;
input logic                             spi_en;

output [DATA_WIDTH-1:0] DA_out_spi;
output [1:0] DA_valid_out_spi;
output DoA_out_spi;
output rw_out_spi;
output start_exec_out_spi;

`ifndef SPI_BLACKBOX

wire   SLVdone;
wire   [SPI_DATA_WIDTH-1:0] SLVrdata;
wire   [SPI_DATA_WIDTH-1:0] data_in_fifo;
wire   we_fifo;
wire   [SPI_DATA_WIDTH-1:0] s_tdata;
wire   re;

spi_fsm spi_fsm(
        .clk (clkOut),
        .reset (reset_network),
        .en (chip_en),
        //to fifo betwen spi slave and this fsm
        .tdata_out (data_in_fifo),
        .tdata_we_out (we_fifo),

        //from spi slave
        .rdata_in (SLVrdata),
        .done_in (SLVdone),

        //to hycube
        .DA_out (DA_out_spi),
        .DA_valid_out (DA_valid_out_spi),
        .Data_in (data_out),
        .Data_valid_in (data_out_valid&&spi_en),
        .DoA_out (DoA_out_spi),
        .start_exec_out (start_exec_out_spi),
        .hycube_done_in (exec_end),
        .rw_out (rw_out_spi)
);

syn_fifo syn_fifo(
        .chip_en (chip_en),
        .rst (reset_network),
        .clk_rd (sck),
        .re (re),
        .data_out (s_tdata),
        .clk_wr (clkOut),
        .we (we_fifo),
        .data_in (data_in_fifo)
);

spi_slave spi_slv (
        .rstb (~reset_network),
        .tdata (s_tdata),
        .tdata_re (re),
        .mlb (1'b0),
        .ss (ss),
        .sck (sck),
        .sdin (sdin),
        .sdout (sdout),
        .done (SLVdone),
        .rdata (SLVrdata)
);

`endif

endmodule
