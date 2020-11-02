////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Project Name: HyCUBE (Verilog, SystemVerilog)                          ////
////                                                                        ////
//// Module Name: fifo_init                                                 ////
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
module fifo_init(
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
parameter INIT_VAL      = 1'b0;
parameter INC_INIT      = 1'b1;
parameter DATA_WIDTH    = 64;
parameter DEPTH         = 3;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------
localparam  ADDR_WIDTH  = $clog2(DEPTH);
typedef enum logic
{
    FIFO_INIT_RESET,
    FIFO_INIT_READY
} fifo_init_state;
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
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Output interface
//------------------------------------------------------------------------------
output logic                            o__data_out_valid;
output logic [DATA_WIDTH-1:0]           o__data_out;
input  logic                            i__data_out_ready;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------
logic                                   w__data_in_valid;
logic        [DATA_WIDTH-1:0]           w__data_in;
logic                                   w__data_in_ready;
logic                                   w__data_out_valid;
logic        [DATA_WIDTH-1:0]           w__data_out;
logic                                   w__data_out_ready;
logic                                   w__init;
logic                                   w__init_clk;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// States and next signals
//------------------------------------------------------------------------------
fifo_init_state                         w__state__next;
fifo_init_state                         r__state__pff;
logic        [ADDR_WIDTH-1:0]           w__init_addr__next;
logic        [ADDR_WIDTH-1:0]           r__init_addr__pff;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Submodules
//------------------------------------------------------------------------------
fifo
    #(
        .DATA_WIDTH                     (DATA_WIDTH),
        .DEPTH                          (DEPTH)
    )
    fifo (
        .clk                            (clk),
        .reset                          (reset),
        .i__data_in_valid               (w__data_in_valid),
        .i__data_in                     (w__data_in),
        .o__data_in_ready               (w__data_in_ready),
        .o__data_in_ready__next         (),
        .o__data_out_valid              (w__data_out_valid),
        .o__data_out                    (w__data_out),
        .i__data_out_ready              (w__data_out_ready)
    );

clock_gater
    gate_init_clk (
        .clk                            (clk),
        .reset                          (reset),
        .i__enable                      (w__init),
        .o__gated_clk                   (w__init_clk)
    );
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Block inputs/outputs while resetting
//------------------------------------------------------------------------------
assign o__data_out = w__data_out;

always_comb
begin
    w__data_in_valid    = i__data_in_valid;
    w__data_in          = i__data_in;
    o__data_in_ready    = w__data_in_ready;
    o__data_out_valid   = w__data_out_valid;
    w__data_out_ready   = i__data_out_ready;

    if(r__state__pff == FIFO_INIT_RESET)
    begin
        w__data_in_valid    = 1'b1;
        w__data_in          = r__init_addr__pff + INIT_VAL;
        o__data_in_ready    = 1'b0;
        o__data_out_valid   = 1'b0;
        w__data_out_ready   = 1'b0;
    end
end
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Switch states between reset and ready mode
//------------------------------------------------------------------------------
always_comb
begin
    w__init_addr__next = r__init_addr__pff;

    if(r__state__pff == FIFO_INIT_RESET)
    begin
        w__init_addr__next = r__init_addr__pff + 1'b1;
    end
end

always_comb
begin
    w__init = 1'b0;

    if((r__state__pff == FIFO_INIT_RESET) || (reset == 1'b1))
    begin
        w__init = 1'b1;
    end
end

always_comb
begin
    w__state__next = r__state__pff;

    if(r__init_addr__pff == {$unsigned(DEPTH-1)})
    begin
        w__state__next = FIFO_INIT_READY;
    end
end

always_ff @ (posedge w__init_clk)
begin
    if(reset == 1'b1)
    begin
        r__state__pff       <= FIFO_INIT_RESET;
        r__init_addr__pff   <= '0;
    end
    else
    begin
        r__state__pff       <= w__state__next;
        r__init_addr__pff   <= w__init_addr__next;
    end
end
//------------------------------------------------------------------------------

endmodule

