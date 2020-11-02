////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Project Name: HyCUBE (Verilog, SystemVerilog)                          ////
////                                                                        ////
//// Module Name: fifo_base_bypass                                          ////
////                                                                        ////
////                                                                        ////
////  This file is part of HyCUBE                                           ////
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
//// You should have received a copy of the MIT                             ////
//// License along with this source; if not, download it                    ////
//// from https://opensource.org/licenses/MIT                               ////
////                                                                        ////
////////////////////////////////////////////////////////////////////////////////
//------------------------------------------------------------------------------
// First-word fall-through synchronous FIFO with synchronous reset
//
// If the fifo is empty and there is a valid data at the input, this data is 
// visible at the output in the same cycle.
//------------------------------------------------------------------------------
module fifo_base_bypass(
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
    i__data_out_ready,
    i__clear_all,
    oa__all_data
);

//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
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
input  logic                            i__clear_all;
output logic [DATA_WIDTH-1:0]           oa__all_data            [0:DEPTH-1];
//------------------------------------------------------------------------------

// Wires
logic                                   w__data_in_valid;
logic [DATA_WIDTH-1:0]                  w__data_in;
logic                                   w__data_in_ready;
logic                                   w__data_in_ready__next;
logic                                   w__data_out_valid;
logic [DATA_WIDTH-1:0]                  w__data_out;
logic                                   w__data_out_ready;


//------------------------------------------------------------------------------
// Sub-modules
//------------------------------------------------------------------------------
fifo_base
    #(
        .DATA_WIDTH                     (DATA_WIDTH),
        .DEPTH                          (DEPTH),
        .DEPTH_1_OPTIMIZATION           (DEPTH_1_OPTIMIZATION)
    )
    base (
        .clk                            (clk),
        .reset                          (reset),

        .i__data_in_valid               (w__data_in_valid),
        .i__data_in                     (w__data_in),
        .o__data_in_ready               (w__data_in_ready),
        .o__data_in_ready__next         (w__data_in_ready__next),

        .o__data_out_valid              (w__data_out_valid),
        .o__data_out                    (w__data_out),
        .i__data_out_ready              (w__data_out_ready),
        .oa__all_data                   (oa__all_data),
        .i__clear_all                   (i__clear_all)
    );
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// FIFO base input interface logic
//------------------------------------------------------------------------------
always_comb
begin
    w__data_in_valid    = i__data_in_valid;
    w__data_in          = i__data_in;

    if(w__data_out_valid == 1'b0)
    begin
        // FIFO base is empty
        if((i__data_in_valid == 1'b1) && (i__data_out_ready == 1'b1))
        begin
            // If there is a valid incoming data and it is popped out in the same cycle
            //  - Deassert the data in valid bit so that nothing is inserted into the FIFO
            w__data_in_valid = 1'b0;
        end
    end
end

always_comb
begin
    o__data_in_ready        = w__data_in_ready;
    o__data_in_ready__next  = w__data_in_ready__next;
end
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// FIFO base output interface logic
//------------------------------------------------------------------------------
always_comb
begin
    o__data_out_valid   = w__data_out_valid;
    o__data_out         = w__data_out;

    if((w__data_out_valid == 1'b0) && (reset == 1'b0))
    begin
        // FIFO base is empty and not in reset phase
        if(i__data_in_valid == 1'b1)
        begin
            // If there is a valid incoming data
            //  - Assert data out valid bit
            //  - Forward the incoming data to the output
            o__data_out_valid   = 1'b1;
            o__data_out         = i__data_in;
        end
    end
end

always_comb
begin
    // The FIFO base ignores the ready signal if there is no element in the FIFO
    // so it is valid to pass ready signal directly to the FIFO base without any 
    // condition
    w__data_out_ready = i__data_out_ready;
end
//------------------------------------------------------------------------------

/*
always @ (clk)
begin
    $display ("ASK In FIFO bypass i__data_in = %b", i__data_in);
    $display ("ASK In FIFO bypass o__data_out = %b", o__data_out);
end
*/

endmodule

