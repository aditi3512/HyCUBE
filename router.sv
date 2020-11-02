////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Project Name: HyCUBE (Verilog, SystemVerilog)                          ////
////                                                                        ////
//// Module Name: router                                                    ////
////                                                                        ////
////                                                                        ////
////  This file is part of the HyCUBE project                               ////
////  https://github.com/aditi3512/HyCUBE                                   ////
////                                                                        ////
////  Author(s):                                                            ////
////      NUS, MIT                                                          ////
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


//------------------------------------------------------------------------------
// SMART Router
//------------------------------------------------------------------------------
module router(
    clk,
    reset,

    i__sram_xbar_sel,

    i__flit_in,
    i__alu_out,
    i__treg,
    o__flit_out,
    regbypass,
    regWEN
);

//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
import SMARTPkg::*;

parameter NUM_VCS                       = 4;

localparam NUM_INPUT_PORTS              = 6;
localparam NUM_OUTPUT_PORTS             = 7;
localparam LOG_NUM_VCS                  = $clog2(NUM_VCS);
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// IO
//------------------------------------------------------------------------------

// General
input  logic                            clk;
input  logic                            reset;

input  logic [NUM_INPUT_PORTS-1:0]	i__sram_xbar_sel	        [NUM_OUTPUT_PORTS-1:0];

// Incoming flit and outgoing credit
input  FlitFixed         i__flit_in                      [NUM_INPUT_PORTS-1-2:0];
input  FlitFixed         i__alu_out;
input  FlitFixed         i__treg;

// Outgoing flit and incoming credit
output FlitFixed         o__flit_out                     [NUM_OUTPUT_PORTS-1:0];

input  [3:0] 				regbypass;
input  [3:0] 				regWEN;

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
`ifdef DEBUG_TRACE
//Debug
wire [32:0] o__flit_out_0;
wire [32:0] o__flit_out_1;
wire [32:0] o__flit_out_2;
wire [32:0] o__flit_out_3;
wire [32:0] o__flit_out_4;
wire [32:0] o__flit_out_5;
wire [32:0] o__flit_out_6;
assign o__flit_out_0 = o__flit_out[0];
assign o__flit_out_1 = o__flit_out[1];
assign o__flit_out_2 = o__flit_out[2];
assign o__flit_out_3 = o__flit_out[3];
assign o__flit_out_4 = o__flit_out[4];
assign o__flit_out_5 = o__flit_out[5];
assign o__flit_out_6 = o__flit_out[6];
`endif
//------------------------------------------------------------------------------
// Internal signals
//------------------------------------------------------------------------------

FlitFixed                w__flit_xbar_flit_out                   [NUM_OUTPUT_PORTS-1:0];

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Submodules
//------------------------------------------------------------------------------
    logic [NUM_INPUT_PORTS-1:0]         this_flit_xbar_sel              [NUM_OUTPUT_PORTS-1:0];
    FlitFixed                           this_flit_out_local             [NUM_INPUT_PORTS-1-2:0];
    FlitFixed                           this_flit_in                    [NUM_INPUT_PORTS-1:0];
    FlitFixed                           this_flit_xbar_flit_out         [NUM_OUTPUT_PORTS-1:0];

//Debug
wire [32:0] this_flit_in_E;
wire [32:0] this_flit_in_S;
wire [32:0] this_flit_in_W;
wire [32:0] this_flit_in_N;
wire [32:0] this_flit_in_ALU;
wire [32:0] this_flit_in_TREG;
assign this_flit_in_E = this_flit_in[0];
assign this_flit_in_S = this_flit_in[1];
assign this_flit_in_W = this_flit_in[2];
assign this_flit_in_N = this_flit_in[3];
assign this_flit_in_ALU = this_flit_in[4];
assign this_flit_in_TREG = this_flit_in[5];
wire [32:0] this_flit_out_R0;
wire [32:0] this_flit_out_R1;
wire [32:0] this_flit_out_R2;
wire [32:0] this_flit_out_R3;
assign this_flit_out_R0 = this_flit_out_local[0];
assign this_flit_out_R3 = this_flit_out_local[1];
assign this_flit_out_R1 = this_flit_out_local[2];
assign this_flit_out_R2 = this_flit_out_local[3];

    always_comb
    begin
        for(int j = 0; j < NUM_INPUT_PORTS-2; j++)
        begin
	    this_flit_in[j] 		= i__flit_in[j];
        end
	    this_flit_in[ALU_T] 	= i__alu_out;
	    this_flit_in[TREG]  	= i__treg;

        for(int j = 0; j < NUM_OUTPUT_PORTS; j++)
        begin
            for(int k = 0; k < NUM_INPUT_PORTS; k++)
            begin
                this_flit_xbar_sel[j][k] = i__sram_xbar_sel[j][k];
            end
        end
    end

always @(posedge clk)
if (reset)
begin
   for(int j = 0; j < NUM_INPUT_PORTS-2; j++)
   begin
	this_flit_out_local[j] <= {33{1'b0}};
   end
end
else 
begin
   for(int j = 0; j < NUM_INPUT_PORTS-2; j++)
   begin
	    if (regWEN[j] == 1'b1)  //ASKmanupa
	    begin
		this_flit_out_local[j] <= i__flit_in[j];
		$display("ASK router this_flit_out_local = %b", this_flit_out_local[j]);
	    end
   end
end
    always_comb
    begin
        for(int j = 0; j < NUM_OUTPUT_PORTS; j++)
        begin
            w__flit_xbar_flit_out[j] = this_flit_xbar_flit_out[j];
        end
    end

    xbar_bypass  
        #(
            .DATA_WIDTH                 ($bits(FlitFixed))
        )
        xbar_bypass(
            .i__sel                     (this_flit_xbar_sel),
            .i__data_in_local           (this_flit_out_local),
            .i__data_in_remote          (this_flit_in),
	    .regbypass			(regbypass),
            .o__data_out                (this_flit_xbar_flit_out)
        );

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Flit to neighbor router
//------------------------------------------------------------------------------
always_comb
begin
    for(int i = 0; i < (NUM_OUTPUT_PORTS); i++)
    begin
        o__flit_out[i] = w__flit_xbar_flit_out[i];
    end
end
//------------------------------------------------------------------------------


/*
always @ (posedge clk)
begin
    $display ("ASK In router i__flit_in = %b", i__flit_in[WEST]);
    $display ("ASK In router i__alu_out = %b %b", i__alu_out, my_xy_id);
    $display ("ASK In router i__sram_xbar_sel = %b %b", i__sram_xbar_sel[0], my_xy_id);
    $display ("ASK In router i__sram_xbar_sel = %b %b", i__sram_xbar_sel[4], my_xy_id);
    $display ("ASK In router i__sram_xbar_sel = %b %b", i__sram_xbar_sel[5], my_xy_id);
    $display ("ASK In router i__sram_xbar_sel = %b %b", i__sram_xbar_sel[6], my_xy_id);
//    $display ("ASK In router this_flit_xbar_sel = %b", this_flit_xbar_sel[0]);
    $display ("ASK In router o__flit_out0 = %b", o__flit_out[0]);
    $display ("ASK In router o__flit_out1 = %b", o__flit_out[1]);
    $display ("ASK In router o__flit_out2 = %b", o__flit_out[2]);
    $display ("ASK In router o__flit_out3 = %b", o__flit_out[3]);
    $display ("ASK In router o__flit_out4 = %b", o__flit_out[4]);
    $display ("ASK In router o__flit_out5 = %b", o__flit_out[5]);
    $display ("ASK In router o__flit_out6 = %b", o__flit_out[6]);
//    $display ("ASK In router i__nic_flit_in = %b", i__nic_flit_in);
//    $display ("ASK In router i__nic_flit_in.header = %b", i__nic_flit_in.header);
//    $display ("ASK In router o__nic_flit_out = %b", o__nic_flit_out);
//$display("ASK router this_flit_xbar_flit_out4 = %b", this_flit_xbar_flit_out[4]);
//$display("ASK router this_flit_xbar_flit_out5 = %b", this_flit_xbar_flit_out[5]);
//$display("ASK router this_flit_xbar_flit_out6 = %b", this_flit_xbar_flit_out[6]);
end
*/

endmodule


