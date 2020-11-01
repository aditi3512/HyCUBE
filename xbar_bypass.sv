
//------------------------------------------------------------------------------
// Mux-based crossbar
//      - Specialized for 5 direction design (E, S, W, N, L)
//      - Each port has two inputs (local and remote)
//      - Only one can access the port
//      - 0 is local and 1 is remote
//------------------------------------------------------------------------------
module xbar_bypass(
    i__sel,
    i__data_in_local,
    i__data_in_remote,
    regbypass,
    o__data_out
);

//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
import TopPkg::MuxType;
import SMARTPkg::*;

parameter  DATA_WIDTH                   = 64;

localparam NUM_INPUT_PORTS              = 6;
localparam NUM_OUTPUT_PORTS             = 7;
localparam MuxType MUX_TYPE             = TopPkg::MUX_ONEHOT;
localparam SEL_WIDTH                    = NUM_INPUT_PORTS;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// IO
//------------------------------------------------------------------------------

input  logic [SEL_WIDTH-1:0]            i__sel                  [NUM_OUTPUT_PORTS-1:0];
input  FlitFixed                        i__data_in_local        [NUM_INPUT_PORTS-3:0];
input  FlitFixed                        i__data_in_remote       [NUM_INPUT_PORTS-1:0];
input  [3:0]				regbypass;
output FlitFixed                        o__data_out             [NUM_OUTPUT_PORTS-1:0];
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Internal connection
//------------------------------------------------------------------------------
logic [NUM_INPUT_PORTS-1:0]             w__sel_input        [NUM_OUTPUT_PORTS-1:0];

logic [NUM_INPUT_PORTS-1:0]                             w__sel_onehot       [NUM_OUTPUT_PORTS-1:0]; //ASKmanupa

logic [2:0]                             w__sel__next        [NUM_OUTPUT_PORTS-1:0];
logic [2:0]                             r__sel__pff         [NUM_OUTPUT_PORTS-1:0];
logic [2:0]                             w__sel_local__next;
logic [2:0]                             r__sel_local__pff;

FlitFixed                               w__flit_in          [NUM_OUTPUT_PORTS-1:0][5:0];  //ASKmanupa
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Submodule
//------------------------------------------------------------------------------
generate
genvar i;
for(i = 0; i < NUM_OUTPUT_PORTS; i++)
begin: mux
    encoder_onehot
        #(
            .NUM_BITS                   (6)
        )
        gen(
	    .i__onehot                  (w__sel_onehot[i]),
//	    .i__onehot                  (i__sel[i]),
            .o__valid                   (),
            .o__encode                  (w__sel__next[i])
        );
end
endgenerate

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Selection the output flit
//------------------------------------------------------------------------------
always_comb
begin
    for(int i = 0; i < NUM_OUTPUT_PORTS; i++)   //ASKmanupa
    begin
	if (w__sel__next[i] == 3'b111)
	o__data_out[i] = {33{1'b0}};
	else
        o__data_out[i] = w__flit_in[i][w__sel__next[i]];   //ASKtest
    end

end
//------------------------------------------------------------------------------
`ifdef DEBUG_TRACE
wire [32:0] o__data_out_0;
wire [32:0] o__data_out_1;
wire [32:0] o__data_out_2;
wire [32:0] o__data_out_3;
wire [32:0] o__data_out_4;
wire [32:0] o__data_out_5;
wire [32:0] o__data_out_6;
wire [2:0] w__sel__next_0;
wire [2:0] w__sel__next_1;
wire [2:0] w__sel__next_2;
wire [2:0] w__sel__next_3;
wire [2:0] w__sel__next_4;
wire [2:0] w__sel__next_5;
wire [2:0] w__sel__next_6;
wire [32:0] w__flit_in_00;
wire [32:0] w__flit_in_01;
wire [32:0] w__flit_in_02;
wire [32:0] w__flit_in_03;
wire [32:0] w__flit_in_04;
wire [32:0] w__flit_in_05;
wire [5:0] i__sel_00;
wire [5:0] i__sel_01;
wire [5:0] i__sel_02;
wire [5:0] i__sel_03;
wire [5:0] i__sel_04;
wire [5:0] i__sel_05;
wire [5:0] i__sel_06;
wire [5:0] w__sel_onehot_00;
wire [5:0] w__sel_onehot_01;
wire [5:0] w__sel_onehot_02;
wire [5:0] w__sel_onehot_03;
wire [5:0] w__sel_onehot_04;
wire [5:0] w__sel_onehot_05;
wire [5:0] w__sel_onehot_06;
wire [32:0] i__data_in_remote_0;
wire [32:0] i__data_in_remote_1;
wire [32:0] i__data_in_remote_2;
wire [32:0] i__data_in_remote_3;
wire [32:0] i__data_in_remote_4;
wire [32:0] i__data_in_remote_5;
assign i__data_in_remote_0 = i__data_in_remote[0];
assign i__data_in_remote_1 = i__data_in_remote[1];
assign i__data_in_remote_2 = i__data_in_remote[2];
assign i__data_in_remote_3 = i__data_in_remote[3];
assign i__data_in_remote_4 = i__data_in_remote[4];
assign i__data_in_remote_5 = i__data_in_remote[5];
assign o__data_out_0 = o__data_out[0];
assign o__data_out_1 = o__data_out[1];
assign o__data_out_2 = o__data_out[2];
assign o__data_out_3 = o__data_out[3];
assign o__data_out_4 = o__data_out[4];
assign o__data_out_5 = o__data_out[5];
assign o__data_out_6 = o__data_out[6];
assign w__sel__next_0 = w__sel__next[0];
assign w__sel__next_1 = w__sel__next[1];
assign w__sel__next_2 = w__sel__next[2];
assign w__sel__next_3 = w__sel__next[3];
assign w__sel__next_4 = w__sel__next[4];
assign w__sel__next_5 = w__sel__next[5];
assign w__sel__next_6 = w__sel__next[6];
assign w__flit_in_00 = w__flit_in[5][0];
assign w__flit_in_01 = w__flit_in[5][1];
assign w__flit_in_02 = w__flit_in[5][2];
assign w__flit_in_03 = w__flit_in[5][3];
assign w__flit_in_04 = w__flit_in[5][4];
assign w__flit_in_05 = w__flit_in[5][5];
assign w__sel_onehot_00 = w__sel_onehot[0];
assign w__sel_onehot_01 = w__sel_onehot[1];
assign w__sel_onehot_02 = w__sel_onehot[2];
assign w__sel_onehot_03 = w__sel_onehot[3];
assign w__sel_onehot_04 = w__sel_onehot[4];
assign w__sel_onehot_05 = w__sel_onehot[5];
assign w__sel_onehot_06 = w__sel_onehot[6];
assign i__sel_00 = i__sel[0];
assign i__sel_01 = i__sel[1];
assign i__sel_02 = i__sel[2];
assign i__sel_03 = i__sel[3];
assign i__sel_04 = i__sel[4];
assign i__sel_05 = i__sel[5];
assign i__sel_06 = i__sel[6];
`endif


//------------------------------------------------------------------------------
// Compute the selection signals
//------------------------------------------------------------------------------

// Input selection signals for each output port
always_comb
begin
    for(int i = 0; i < NUM_OUTPUT_PORTS; i++)
    begin
        w__sel_input[i] = i__sel[i];     //ASKmanupa
    end
end


// Final selection signals for each output port and cooresponding flit
always_comb
begin
    // EAST output port
    // 0 - SOUTH
    // 1 - NORTH
    // 2 - WEST
    // 3 - LOCAL
    // 4 - ALU OP1
    // 5 - ALU OP2
    // 6 - ALU Pred
if (regbypass[0] == 1'b1)   //read from register
begin
        w__sel_onehot[EAST][0]  = (w__sel_input[EAST][EAST] == 1'b1);
        w__flit_in[EAST][0]     = i__data_in_local[EAST];
end
else begin                  //read from wire/bypass
        w__sel_onehot[EAST][0]  = (w__sel_input[EAST][EAST] == 1'b1);
        w__flit_in[EAST][0]     = i__data_in_remote[EAST];
end
if (regbypass[3] == 1'b1)
begin
        w__sel_onehot[EAST][1]  = (w__sel_input[EAST][SOUTH] == 1'b1);
        w__flit_in[EAST][1]     = i__data_in_local[SOUTH];
end
else begin
        w__sel_onehot[EAST][1]  = (w__sel_input[EAST][SOUTH] == 1'b1);
        w__flit_in[EAST][1]     = i__data_in_remote[SOUTH];
end

if (regbypass[1] == 1'b1)
begin
        w__sel_onehot[EAST][2]  = (w__sel_input[EAST][WEST] == 1'b1);
        w__flit_in[EAST][2]     = i__data_in_local[WEST];
end
else begin
        w__sel_onehot[EAST][2]  = (w__sel_input[EAST][WEST] == 1'b1);
        w__flit_in[EAST][2]     = i__data_in_remote[WEST];
end

if (regbypass[2] == 1'b1)
begin
        w__sel_onehot[EAST][3]  = (w__sel_input[EAST][NORTH] == 1'b1);
        w__flit_in[EAST][3]     = i__data_in_local[NORTH];
end
else begin
        w__sel_onehot[EAST][3]  = (w__sel_input[EAST][NORTH] == 1'b1);
        w__flit_in[EAST][3]     = i__data_in_remote[NORTH];
end

    w__sel_onehot[EAST][4]  = (w__sel_input[EAST][ALU_T] == 1'b1);
    w__sel_onehot[EAST][5]  = (w__sel_input[EAST][TREG] == 1'b1);

    w__flit_in[EAST][4]     = i__data_in_remote[ALU_T];
    w__flit_in[EAST][5]     = i__data_in_remote[TREG];


    // SOUTH output port
    // 0 - EAST
    // 1 - WEST
    // 2 - NORTH
    // 3 - LOCAL
    // 4 - ALU OP1 
    // 5 - ALU OP2
    // 6 - ALU Pred
if (regbypass[0] == 1'b1)
begin
        w__sel_onehot[SOUTH][0]  = (w__sel_input[SOUTH][EAST] == 1'b1);
        w__flit_in[SOUTH][0]     = i__data_in_local[EAST];
end
else begin
        w__sel_onehot[SOUTH][0]  = (w__sel_input[SOUTH][EAST] == 1'b1);
        w__flit_in[SOUTH][0]     = i__data_in_remote[EAST];
end

if (regbypass[3] == 1'b1)
begin
        w__sel_onehot[SOUTH][1]  = (w__sel_input[SOUTH][SOUTH] == 1'b1);
        w__flit_in[SOUTH][1]     = i__data_in_local[SOUTH];
end
else begin
        w__sel_onehot[SOUTH][1]  = (w__sel_input[SOUTH][SOUTH] == 1'b1);
        w__flit_in[SOUTH][1]     = i__data_in_remote[SOUTH];
end

if (regbypass[1] == 1'b1)
begin
        w__sel_onehot[SOUTH][2]  = (w__sel_input[SOUTH][WEST] == 1'b1);
        w__flit_in[SOUTH][2]     = i__data_in_local[WEST];
end
else begin
        w__sel_onehot[SOUTH][2]  = (w__sel_input[SOUTH][WEST] == 1'b1);
        w__flit_in[SOUTH][2]     = i__data_in_remote[WEST];
end

if (regbypass[2] == 1'b1)
begin
        w__sel_onehot[SOUTH][3]  = (w__sel_input[SOUTH][NORTH] == 1'b1);
        w__flit_in[SOUTH][3]     = i__data_in_local[NORTH];
end
else begin
        w__sel_onehot[SOUTH][3]  = (w__sel_input[SOUTH][NORTH] == 1'b1);
        w__flit_in[SOUTH][3]     = i__data_in_remote[NORTH];
end

    w__sel_onehot[SOUTH][4] = (w__sel_input[SOUTH][ALU_T] == 1'b1);
    w__sel_onehot[SOUTH][5] = (w__sel_input[SOUTH][TREG] == 1'b1);

    w__flit_in[SOUTH][4]    = i__data_in_remote[ALU_T];
    w__flit_in[SOUTH][5]    = i__data_in_remote[TREG];


    // WEST output port
    // 0 - EAST
    // 1 - SOUTH
    // 2 - NORTH
    // 3 - LOCAL
    // 4 - ALU OP1
    // 5 - ALU OP2
    // 6 - ALU pred

if (regbypass[0] == 1'b1)
begin
        w__sel_onehot[WEST][0]  = (w__sel_input[WEST][EAST] == 1'b1);
        w__flit_in[WEST][0]     = i__data_in_local[EAST];
end
else begin
        w__sel_onehot[WEST][0]  = (w__sel_input[WEST][EAST] == 1'b1);
        w__flit_in[WEST][0]     = i__data_in_remote[EAST];
end

if (regbypass[3] == 1'b1)
begin
        w__sel_onehot[WEST][1]  = (w__sel_input[WEST][SOUTH] == 1'b1);
        w__flit_in[WEST][1]     = i__data_in_local[SOUTH];
end
else begin
        w__sel_onehot[WEST][1]  = (w__sel_input[WEST][SOUTH] == 1'b1);
        w__flit_in[WEST][1]     = i__data_in_remote[SOUTH];
end

if (regbypass[1] == 1'b1)
begin
        w__sel_onehot[WEST][2]  = (w__sel_input[WEST][WEST] == 1'b1);
        w__flit_in[WEST][2]     = i__data_in_local[WEST];
end
else begin
        w__sel_onehot[WEST][2]  = (w__sel_input[WEST][WEST] == 1'b1);
        w__flit_in[WEST][2]     = i__data_in_remote[WEST];
end

if (regbypass[2] == 1'b1)
begin
        w__sel_onehot[WEST][3]  = (w__sel_input[WEST][NORTH] == 1'b1);
        w__flit_in[WEST][3]     = i__data_in_local[NORTH];
end
else begin
        w__sel_onehot[WEST][3]  = (w__sel_input[WEST][NORTH] == 1'b1);
        w__flit_in[WEST][3]     = i__data_in_remote[NORTH];
end

    w__sel_onehot[WEST][4]  = (w__sel_input[WEST][ALU_T] == 1'b1);
    w__sel_onehot[WEST][5]  = (w__sel_input[WEST][TREG] == 1'b1);

    w__flit_in[WEST][4]     = i__data_in_remote[ALU_T];
    w__flit_in[WEST][5]     = i__data_in_remote[TREG];

    // NORTH output port
    // 0 - EAST
    // 1 - SOUTH
    // 2 - WEST
    // 3 - LOCAL
    // 4 - ALU OP1 
    // 5 - ALU OP2
    // 6 - ALU pred

if (regbypass[0] == 1'b1)
begin
        w__sel_onehot[NORTH][0]  = (w__sel_input[NORTH][EAST] == 1'b1);
        w__flit_in[NORTH][0]     = i__data_in_local[EAST];
end
else begin
        w__sel_onehot[NORTH][0]  = (w__sel_input[NORTH][EAST] == 1'b1);
        w__flit_in[NORTH][0]     = i__data_in_remote[EAST];
end

if (regbypass[3] == 1'b1)
begin
        w__sel_onehot[NORTH][1]  = (w__sel_input[NORTH][SOUTH] == 1'b1);
        w__flit_in[NORTH][1]     = i__data_in_local[SOUTH];
end
else begin
        w__sel_onehot[NORTH][1]  = (w__sel_input[NORTH][SOUTH] == 1'b1);
        w__flit_in[NORTH][1]     = i__data_in_remote[SOUTH];
end

if (regbypass[1] == 1'b1)
begin
        w__sel_onehot[NORTH][2]  = (w__sel_input[NORTH][WEST] == 1'b1);
        w__flit_in[NORTH][2]     = i__data_in_local[WEST];
end
else begin
        w__sel_onehot[NORTH][2]  = (w__sel_input[NORTH][WEST] == 1'b1);
        w__flit_in[NORTH][2]     = i__data_in_remote[WEST];
end

if (regbypass[2] == 1'b1)
begin
        w__sel_onehot[NORTH][3]  = (w__sel_input[NORTH][NORTH] == 1'b1);
        w__flit_in[NORTH][3]     = i__data_in_local[NORTH];
end
else begin
        w__sel_onehot[NORTH][3]  = (w__sel_input[NORTH][NORTH] == 1'b1);
        w__flit_in[NORTH][3]     = i__data_in_remote[NORTH];
end

    w__sel_onehot[NORTH][4] = (w__sel_input[NORTH][ALU_T] == 1'b1);
    w__sel_onehot[NORTH][5] = (w__sel_input[NORTH][TREG] == 1'b1);

    w__flit_in[NORTH][4]    = i__data_in_remote[ALU_T];
    w__flit_in[NORTH][5]    = i__data_in_remote[TREG];

    // ALU OP1 output port
    // 0 - EAST
    // 1 - SOUTH
    // 2 - WEST
    // 3 - NORTH
    // 4 - ALU OP1
    // 5 - ALU OP2
    // 6 - ALU pred

if (regbypass[0] == 1'b1)
begin
        w__sel_onehot[4][0]  = (w__sel_input[4][EAST] == 1'b1);
        w__flit_in[4][0]     = i__data_in_local[EAST];
end
else begin
        w__sel_onehot[4][0]  = (w__sel_input[4][EAST] == 1'b1);
        w__flit_in[4][0]     = i__data_in_remote[EAST];
end

if (regbypass[3] == 1'b1)
begin
        w__sel_onehot[4][1]  = (w__sel_input[4][SOUTH] == 1'b1);
        w__flit_in[4][1]     = i__data_in_local[SOUTH];
end
else begin
        w__sel_onehot[4][1]  = (w__sel_input[4][SOUTH] == 1'b1);
        w__flit_in[4][1]     = i__data_in_remote[SOUTH];
end

if (regbypass[1] == 1'b1)
begin
        w__sel_onehot[4][2]  = (w__sel_input[4][WEST] == 1'b1);
        w__flit_in[4][2]     = i__data_in_local[WEST];
end
else begin
        w__sel_onehot[4][2]  = (w__sel_input[4][WEST] == 1'b1);
        w__flit_in[4][2]     = i__data_in_remote[WEST];
end

if (regbypass[2] == 1'b1)
begin
        w__sel_onehot[4][3]  = (w__sel_input[4][NORTH] == 1'b1);
        w__flit_in[4][3]     = i__data_in_local[NORTH];
end
else begin
        w__sel_onehot[4][3]  = (w__sel_input[4][NORTH] == 1'b1);
        w__flit_in[4][3]     = i__data_in_remote[NORTH];
end

    w__sel_onehot[4][4] = (w__sel_input[4][ALU_T] == 1'b1);
    w__sel_onehot[4][5] = (w__sel_input[4][TREG] == 1'b1);

    w__flit_in[4][4]    = i__data_in_remote[ALU_T];
    w__flit_in[4][5]    = i__data_in_remote[TREG];


    // ALU OP2 output port
    // 0 - EAST
    // 1 - SOUTH
    // 2 - WEST
    // 3 - NORTH
    // 4 - ALU OP1
    // 5 - ALU OP2
    // 6 - ALU pred

if (regbypass[0] == 1'b1)
begin
        w__sel_onehot[5][0]  = (w__sel_input[5][EAST] == 1'b1);
        w__flit_in[5][0]     = i__data_in_local[EAST];
end
else begin
        w__sel_onehot[5][0]  = (w__sel_input[5][EAST] == 1'b1);
        w__flit_in[5][0]     = i__data_in_remote[EAST];
end

if (regbypass[3] == 1'b1)
begin
        w__sel_onehot[5][1]  = (w__sel_input[5][SOUTH] == 1'b1);
        w__flit_in[5][1]     = i__data_in_local[SOUTH];
end
else begin
        w__sel_onehot[5][1]  = (w__sel_input[5][SOUTH] == 1'b1);
        w__flit_in[5][1]     = i__data_in_remote[SOUTH];
end

if (regbypass[1] == 1'b1)
begin
        w__sel_onehot[5][2]  = (w__sel_input[5][WEST] == 1'b1);
        w__flit_in[5][2]     = i__data_in_local[WEST];
end
else begin
        w__sel_onehot[5][2]  = (w__sel_input[5][WEST] == 1'b1);
        w__flit_in[5][2]     = i__data_in_remote[WEST];
end

if (regbypass[2] == 1'b1)
begin
        w__sel_onehot[5][3]  = (w__sel_input[5][NORTH] == 1'b1);
        w__flit_in[5][3]     = i__data_in_local[NORTH];
end
else begin
        w__sel_onehot[5][3]  = (w__sel_input[5][NORTH] == 1'b1);
        w__flit_in[5][3]     = i__data_in_remote[NORTH];
end

    w__sel_onehot[5][4] = (w__sel_input[5][ALU_T] == 1'b1);
    w__sel_onehot[5][5] = (w__sel_input[5][TREG] == 1'b1);

    w__flit_in[5][4]    = i__data_in_remote[ALU_T];
    w__flit_in[5][5]    = i__data_in_remote[TREG];

    // ALU pred output port
    // 0 - EAST
    // 1 - SOUTH
    // 2 - WEST
    // 3 - NORTH
    // 4 - ALU OP1
    // 5 - ALU OP2
    // 6 - ALU pred

if (regbypass[0] == 1'b1)
begin
        w__sel_onehot[6][0]  = (w__sel_input[6][EAST] == 1'b1);
        w__flit_in[6][0]     = i__data_in_local[EAST];
end
else begin
        w__sel_onehot[6][0]  = (w__sel_input[6][EAST] == 1'b1);
        w__flit_in[6][0]     = i__data_in_remote[EAST];
end

if (regbypass[3] == 1'b1)
begin
        w__sel_onehot[6][1]  = (w__sel_input[6][SOUTH] == 1'b1);
        w__flit_in[6][1]     = i__data_in_local[SOUTH];
end
else begin
        w__sel_onehot[6][1]  = (w__sel_input[6][SOUTH] == 1'b1);
        w__flit_in[6][1]     = i__data_in_remote[SOUTH];
end

if (regbypass[1] == 1'b1)
begin
        w__sel_onehot[6][2]  = (w__sel_input[6][WEST] == 1'b1);
        w__flit_in[6][2]     = i__data_in_local[WEST];
end
else begin
        w__sel_onehot[6][2]  = (w__sel_input[6][WEST] == 1'b1);
        w__flit_in[6][2]     = i__data_in_remote[WEST];
end

if (regbypass[2] == 1'b1)
begin
        w__sel_onehot[6][3]  = (w__sel_input[6][NORTH] == 1'b1);
        w__flit_in[6][3]     = i__data_in_local[NORTH];
end
else begin
        w__sel_onehot[6][3]  = (w__sel_input[6][NORTH] == 1'b1);
        w__flit_in[6][3]     = i__data_in_remote[NORTH];
end

    w__sel_onehot[6][4] = (w__sel_input[6][ALU_T] == 1'b1);
    w__sel_onehot[6][5] = (w__sel_input[6][TREG] == 1'b1);

    w__flit_in[6][4]    = i__data_in_remote[ALU_T];
    w__flit_in[6][5]    = i__data_in_remote[TREG];

end

/*
always_ff @ (posedge clk)
begin
    if(reset == 1'b1)
    begin
        for(int i = 0; i < NUM_OUTPUT_PORTS; i++)
        begin
            r__sel__pff[i]  <= '0;
        end
        r__sel_local__pff   <= '0;
    end
    else
    begin
        r__sel__pff         <= w__sel__next;
        r__sel_local__pff   <= w__sel_local__next;
    end
end


always @(posedge clk)
begin
$display ("ASK In xbar bypass w__sel_input = %b", w__sel_input[0]);
$display ("ASK In xbar_bypass i__sel 0 1 2 3 4 5 6 = %b %b %b %b %b %b %b", i__sel[0], i__sel[1], i__sel[2], i__sel[3], i__sel[4], i__sel[5], i__sel[6]);
$display ("ASK In xbar_bypass w__sel_onehot 0 1 2 3 4 5 6 = %b %b %b %b %b %b", w__sel_onehot[0], w__sel_onehot[1], w__sel_onehot[2], w__sel_onehot[3], w__sel_onehot[4], w__sel_onehot[5]);
$display ("ASK In xbar_bypass w__sel__next 0 1 2 3 4 5 6 = %b %b %b %b %b %b %b", w__sel__next[0], w__sel__next[1], w__sel__next[2], w__sel__next[3], w__sel__next[4], w__sel__next[5], w__sel__next[6]);
//$display ("ASK In xbar_bypass i__data_in_local = %b", i__data_in_local[4]);

$display ("ASK In xbar_bypass w__flit_in65 = %b", w__flit_in[6][5]);
$display ("ASK In xbar_bypass w__flit_in64 = %b", w__flit_in[6][4]);
$display ("ASK In xbar_bypass w__flit_in63 = %b", w__flit_in[6][3]);
$display ("ASK In xbar_bypass w__flit_in62 = %b", w__flit_in[6][2]);
$display ("ASK In xbar_bypass w__flit_in61 = %b", w__flit_in[6][1]);
$display ("ASK In xbar_bypass w__flit_in60 = %b", w__flit_in[6][0]);

$display ("ASK In xbar_bypass w__flit_in04 = %b", w__flit_in[0][4]);
$display ("ASK In xbar_bypass w__flit_in14 = %b", w__flit_in[1][4]);
$display ("ASK In xbar_bypass w__flit_in24 = %b", w__flit_in[2][4]);
$display ("ASK In xbar_bypass w__flit_in34 = %b", w__flit_in[3][4]);
$display ("ASK In xbar_bypass w__flit_in44 = %b", w__flit_in[4][4]);
$display ("ASK In xbar_bypass w__flit_in54 = %b", w__flit_in[5][4]);

//$display ("ASK In xbar_bypass i__data_in_remote = %b", i__data_in_remote[4]);
$display ("ASK In xbar_bypass i__data_in_local = %b", i__data_in_local[0]);

$display ("ASK In xbar_bypass o__data_out6 = %b", o__data_out[6]);
$display ("ASK In xbar_bypass o__data_out5 = %b", o__data_out[5]);
$display ("ASK In xbar_bypass o__data_out4 = %b", o__data_out[4]);
$display ("ASK In xbar_bypass o__data_out = %b", o__data_out[3]);
$display ("ASK In xbar_bypass o__data_out = %b", o__data_out[2]);
$display ("ASK In xbar_bypass o__data_out = %b", o__data_out[1]);
$display ("ASK In xbar_bypass o__data_out = %b", o__data_out[0]);

$display ("ASK In xbar_bypass r__sel__pff = %b", r__sel__pff[4]);
$display ("ASK In xbar_bypass regbypass = %b", regbypass);
end
*/
//------------------------------------------------------------------------------



endmodule

