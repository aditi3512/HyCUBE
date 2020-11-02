////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Project Name: HyCUBE (Verilog, SystemVerilog)                          ////
////                                                                        ////
//// Module Name: fifo                                                      ////
////                                                                        ////
////                                                                        ////
////  This file is part of the Ethernet IP core project                     ////
////  https://github.com/aditi3512/HyCUBE                                   ////
////                                                                        ////
////  Author(s):                                                            ////
////      MIT                                                               ////
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
//------------------------------------------------------------------------------
// First-word fall-through synchronous FIFO with synchronous reset
//------------------------------------------------------------------------------
module fifo(
    //--------------------------------------------------------------------------
    // Global signals
    //--------------------------------------------------------------------------
    clk,
    reset,

    //--------------------------------------------------------------------------
    // Input interface
    //--------------------------------------------------------------------------
    i__data_in_valid,
    i__data_in,
    o__data_in_ready,
    o__data_in_ready__next,

    //--------------------------------------------------------------------------
    // Output interface
    //--------------------------------------------------------------------------
    o__data_out_valid,
    o__data_out,
    i__data_out_ready
);

//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
parameter BYPASS_ENABLE = 1'b0;
parameter DATA_WIDTH    = 64;
parameter DEPTH         = 3;
parameter DEPTH_1_OPTIMIZATION = 0;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------
localparam  ADDR_WIDTH  = $clog2(DEPTH);
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Global signals
//------------------------------------------------------------------------------
input  logic                            clk;
input  logic                            reset;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Input interface
//------------------------------------------------------------------------------
input  logic                            i__data_in_valid;
input  logic [DATA_WIDTH-1:0]           i__data_in;
output logic                            o__data_in_ready;
output logic                            o__data_in_ready__next;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Output interface
//------------------------------------------------------------------------------
output logic                            o__data_out_valid;
output logic [DATA_WIDTH-1:0]           o__data_out;
input  logic                            i__data_out_ready;
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Sub-modules
//------------------------------------------------------------------------------
generate 
if(BYPASS_ENABLE == 1'b0)
begin: no_bypass
    fifo_base
        #(
            .DATA_WIDTH                 (DATA_WIDTH),
            .DEPTH                      (DEPTH),
            .DEPTH_1_OPTIMIZATION       (DEPTH_1_OPTIMIZATION)
        )
        base(
            .clk                        (clk),
            .reset                      (reset),
    
            .i__data_in_valid           (i__data_in_valid),
            .i__data_in                 (i__data_in),
            .o__data_in_ready           (o__data_in_ready),
            .o__data_in_ready__next     (o__data_in_ready__next),
    
            .o__data_out_valid          (o__data_out_valid),
            .o__data_out                (o__data_out),
            .i__data_out_ready          (i__data_out_ready),
            .oa__all_data               (),
            .i__clear_all               ('0)
        );
end
else
begin: bypass
    fifo_base_bypass
        #(
            .DATA_WIDTH                 (DATA_WIDTH),
            .DEPTH                      (DEPTH),
            .DEPTH_1_OPTIMIZATION       (DEPTH_1_OPTIMIZATION)
        )
        base (
            .clk                        (clk),
            .reset                      (reset),
        
            .i__data_in_valid           (i__data_in_valid),
            .i__data_in                 (i__data_in),
            .o__data_in_ready           (o__data_in_ready),
            .o__data_in_ready__next     (o__data_in_ready__next),
        
            .o__data_out_valid          (o__data_out_valid),
            .o__data_out                (o__data_out),
            .i__data_out_ready          (i__data_out_ready),
            .oa__all_data               (),
            .i__clear_all               ('0)
        );
end
endgenerate
//------------------------------------------------------------------------------
/*
always @ (posedge clk)
begin
    $display ("ASK In FIFO i__data_in = %b", i__data_in);
    $display ("ASK In FIFO o__data_out = %b", o__data_out);
end
*/
endmodule

