
module tile(
    clk,
    reset,

    i__flit_in,

    o__flit_out,

    control_reg_data,
//    tregsel,
    is_dm_tile,
    start_exec,
    loop_start,
    loop_end,
    look_up_table,
    data_in_dm,
    data_out_dm,
    addr_dm,    
    bit_en,    
    rd_en_dm,
    wr_en_dm
//    ace_master,
//    o__nic_config_scan_locked_out
);

//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
import TopPkg::ScanControl;
import SMARTPkg::*;

parameter NIC_OUTPUT_FIFO_DEPTH         = 8;
parameter ROUTER_NUM_VCS                = 8;


`ifdef FLEXIBLE_FLIT_ENABLE
parameter NUM_SSRS                      = NUM_HOPS_PER_CYCLE;
`endif

localparam NUM_INPUT_PORTS              = 6;
localparam NUM_OUTPUT_PORTS             = 7;
localparam ROUTER_NUM_INPUT_PORTS       = NUM_INPUT_PORTS;
localparam ROUTER_NUM_OUTPUT_PORTS      = NUM_OUTPUT_PORTS;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// IO
//------------------------------------------------------------------------------
input  logic                            clk;
input  logic                            reset;

input  FlitFixed         i__flit_in                      [NUM_INPUT_PORTS-1-2:0];

output FlitFixed         o__flit_out                     [NUM_OUTPUT_PORTS-1-3:0];

`ifdef FLEXIBLE_FLIT_ENABLE
input  SMARTSetupRequest                i__ssr_in                       [NUM_INPUT_PORTS-1:0][NUM_SSRS-1:0];
output SMARTSetupRequest                o__ssr_out                      [NUM_OUTPUT_PORTS-1:0];
input  Credit                           i__flexible_bypass_credit_in    [NUM_OUTPUT_PORTS-1:0];
output Credit                           o__flexible_bypass_credit_out   [NUM_INPUT_PORTS-1:0];
`endif

//input  [8:0]				operation;
input  [63:0]			        control_reg_data;
input  [63:0]			        look_up_table;
//input  logic			        tregsel;
input 	is_dm_tile;
input 	start_exec;
output [4:0] loop_start;
output [4:0] loop_end;
output [8:0] addr_dm;
output [31:0] bit_en;
input [31:0] data_out_dm;
output [31:0] data_in_dm;
output rd_en_dm;
output wr_en_dm;

//wangbo: add to make tile as blackbox for bottom-up synthesis
`ifndef TILE_BLACKBOX

//------------------------------------------------------------------------------
// Internal signals
//------------------------------------------------------------------------------

logic                    w__flit_xbar_bypass_input       [ROUTER_NUM_INPUT_PORTS-2:0];
DirectionOneHot          w__flit_xbar_bypass_output      [ROUTER_NUM_OUTPUT_PORTS-1:0];


logic                                   r__reset__pff;



logic [ROUTER_NUM_INPUT_PORTS-1:0]	i__sram_xbar_sel	[ROUTER_NUM_OUTPUT_PORTS-1:0];

FlitFixed         o__flit_out_wire                     [NUM_OUTPUT_PORTS-1:0];
FlitFixed         i__flit_in_wire                     [NUM_INPUT_PORTS-1:0];

wire [31:0] data_out_dm;
reg [31:0] data_out_dm_reg;
reg [8:0] addr_dm;
reg [31:0] bit_en;
reg [31:0] data_in_dm;
reg rd_en_dm;
reg wr_en_dm;
reg [63:0] control_reg_data;
wire [63:0] look_up_table;
//reg tregsel;

wire [31:0] lsu_alu_out;
reg not_to_execute_reg;
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
wire [5:0] i__sram_xbar_sel_0;
wire [5:0] i__sram_xbar_sel_1;
wire [5:0] i__sram_xbar_sel_2;
wire [5:0] i__sram_xbar_sel_3;
wire [5:0] i__sram_xbar_sel_4;
wire [5:0] i__sram_xbar_sel_5;
wire [5:0] i__sram_xbar_sel_6;
wire [32:0] i__flit_in_0;
wire [32:0] i__flit_in_1;
wire [32:0] i__flit_in_2;
wire [32:0] i__flit_in_3;
assign i__flit_in_0 = i__flit_in[0];
assign i__flit_in_1 = i__flit_in[1];
assign i__flit_in_2 = i__flit_in[2];
assign i__flit_in_3 = i__flit_in[3];
assign i__sram_xbar_sel_0 = i__sram_xbar_sel[0];
assign i__sram_xbar_sel_1 = i__sram_xbar_sel[1];
assign i__sram_xbar_sel_2 = i__sram_xbar_sel[2];
assign i__sram_xbar_sel_3 = i__sram_xbar_sel[3];
assign i__sram_xbar_sel_4 = i__sram_xbar_sel[4];
assign i__sram_xbar_sel_5 = i__sram_xbar_sel[5];
assign i__sram_xbar_sel_6 = i__sram_xbar_sel[6];
assign o__flit_out_0 = o__flit_out[0];
assign o__flit_out_1 = o__flit_out[1];
assign o__flit_out_2 = o__flit_out[2];
assign o__flit_out_3 = o__flit_out[3];
assign o__flit_out_4 = o__flit_out[4];
assign o__flit_out_5 = o__flit_out[5];
assign o__flit_out_6 = o__flit_out[6];
wire [32:0] i__flit_in_rhs;
assign i__flit_in_rhs = i__flit_in[4][32:0];

wire [32:0] i__flit_in_lhs;
assign i__flit_in_lhs = i__flit_in[5][32:0];

wire [32:0]  i__flit_in_pred;
assign i__flit_in_pred = i__flit_in[6][32:0];

`endif
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Submodule
//------------------------------------------------------------------------------



wire Cout;
wire [31:0] alu_out;
reg [31:0] alu_out_dm_tiles;
reg [32:0] tile_out;
reg [32:0] treg;
reg [32:0] op_rhs;
reg [32:0] op_lhs;
reg [32:0] op_predicate_reg;
wire [32:0] op_predicate;
wire [32:0] op_shift;
reg [5:0] operation;
reg [3:0] regbypass;
reg [3:0] regWEN;

reg [4:0] current_loop;
reg current_loop_prev_cycle;
reg [4:0] loop_start;
reg [4:0] loop_end;
reg [4:0] ls_lut;
reg [4:0] le_lut;
reg valid_lut;
reg [8:0] prev_cycle_p_i2_i1;
wire not_to_execute;
wire not_to_execute_all;
wire not_to_execute_select;

always @(posedge clk)
begin
if (reset)
	prev_cycle_p_i2_i1 <= 9'b111111111;
else if (start_exec)
	prev_cycle_p_i2_i1 <= control_reg_data[20:12];
end

always @(posedge clk)
begin
if (reset || control_reg_data[34:30]==5'b11110)
begin
	op_rhs <= {33{1'b0}};
	op_lhs <= {33{1'b0}};
	op_predicate_reg <= {33{1'b0}};
end
else
if (start_exec) 
begin
	if (control_reg_data[14:12]!=3'b111)
		op_rhs <= o__flit_out_wire[4][32:0];
	else if (operation[4:0] != 5'b00000)
		op_rhs <= {33{1'b0}};
	if (control_reg_data[17:15]!=3'b111)
		op_lhs <= o__flit_out_wire[5][32:0];
	else if (operation[4:0] != 5'b00000)
		op_lhs <= {33{1'b0}};
	if (control_reg_data[20:18]!=3'b111)
		op_predicate_reg <= o__flit_out_wire[6][32:0];
	else if (operation[4:0] != 5'b00000)
		op_predicate_reg <= {33{1'b0}};
end
end

assign op_predicate = (control_reg_data[63]) ? {op_predicate_reg[32:1], ~op_predicate_reg[0]} : op_predicate_reg[32:0];
assign op_shift = {1'b1,{5{control_reg_data[61]}},control_reg_data[61:35]};
assign operation = {control_reg_data[62],control_reg_data[34:30]};
assign regbypass = control_reg_data[24:21];
assign regWEN = control_reg_data[29:26];
assign not_to_execute_all = ((prev_cycle_p_i2_i1[2:0] != 3'b111 && op_rhs[32]==1'b0) || (control_reg_data[62] != 1'b1 && prev_cycle_p_i2_i1[5:3] != 3'b111 && op_lhs[32]==1'b0) || (prev_cycle_p_i2_i1[8:6] != 3'b111 && (op_predicate[32]==1'b0 ||op_predicate[31:0]=={32{1'b0}}) )) ? 1'b1 : 1'b0;
assign not_to_execute_select = ((op_rhs[32]==1'b0 && op_lhs[32]==1'b0) || (prev_cycle_p_i2_i1[8:6] != 3'b111 && (op_predicate[32]==1'b0 || op_predicate[31:0]=={32{1'b0}}))) ? 1'b1 : 1'b0;
assign not_to_execute = (control_reg_data[34:30]==5'b10000) ? not_to_execute_select :  not_to_execute_all;	

assign o__flit_out[0] = o__flit_out_wire[0];
assign o__flit_out[1] = o__flit_out_wire[1];
assign o__flit_out[2] = o__flit_out_wire[2];
assign o__flit_out[3] = o__flit_out_wire[3];


simple_alu 
	#(
	.width		(32)
	)
	a25_simple_alu (
//	.clk		(clk),
//	.reset		(reset),
//	.start_exec	(start_exec),
	.op_predicate	(op_predicate[31:0]), 
	.op_LHS		(op_lhs), 
	.op_RHS		(op_rhs), 
	.op_SHIFT	(op_shift), 
	.operation	(operation), 
	.result		(alu_out)
);


always @(posedge clk)
begin
if (reset)
begin	
	not_to_execute_reg <= 0;
	alu_out_dm_tiles <= {32{1'b0}};
end
else if (start_exec)
begin
	not_to_execute_reg <= not_to_execute;
	alu_out_dm_tiles <= alu_out;
end
end

assign tile_out [31:0] = (is_dm_tile) ? lsu_alu_out : alu_out;
assign tile_out [32] = (is_dm_tile) ? ~not_to_execute_reg : ~not_to_execute;

always @(posedge clk)
begin
if (reset)
begin
		current_loop <= 5'b00000;
		current_loop_prev_cycle <= 1'b0;
end
else if (start_exec)
begin
	if(operation[4:0]==5'b10110 || operation[4:0]==5'b10111)
	begin
		current_loop <= tile_out[4:0];
		current_loop_prev_cycle <= 1'b1;
	end
	else 
	begin
		current_loop_prev_cycle <= 1'b0;
	end
end
end

always_comb begin
case (current_loop)
look_up_table[5:1] : begin
	if (look_up_table[0]==1'b1) begin
		ls_lut <= look_up_table[10:6];
		le_lut <= look_up_table[15:11];
	end
	else begin
		ls_lut <= 5'b00000;
		le_lut <= 5'b00000;
	end
end
look_up_table[21:17] : begin
	if (look_up_table[16]==1'b1) begin
		ls_lut <= look_up_table[26:22];
		le_lut <= look_up_table[31:27];
	end
	else begin
		ls_lut <= look_up_table[10:6];
		le_lut <= look_up_table[15:11];
	end
end
look_up_table[37:33] : begin
	if (look_up_table[32]==1'b1) begin
		ls_lut <= look_up_table[42:38];
		le_lut <= look_up_table[47:43];
	end
	else begin
		ls_lut <= look_up_table[10:6];
		le_lut <= look_up_table[15:11];
	end
end
look_up_table[53:49] : begin
	if (look_up_table[48]==1'b1) begin
		ls_lut <= look_up_table[58:54];
		le_lut <= look_up_table[63:59];
	end
	else begin
		ls_lut <= look_up_table[10:6];
		le_lut <= look_up_table[15:11];
	end
end
default : begin
		ls_lut <= look_up_table[10:6];
		le_lut <= look_up_table[15:11];
end
endcase
end

always @(posedge clk)
begin
if (reset)
	loop_start <= 5'b00000;
else if (start_exec)
begin
if (operation[4:0]==5'b11110 || current_loop_prev_cycle==1'b1)
begin
	if (operation[4:0]==5'b11110)
	loop_start <= control_reg_data[39:35];
	else
	loop_start <= ls_lut;
end
end
end

always @(posedge clk)
begin
if (reset)
	loop_end <= 5'b00000;
else if (start_exec)
begin
if (operation[4:0]==5'b11110 || current_loop_prev_cycle==1'b1)
begin
	if (operation[4:0]==5'b11110)
	loop_end <= control_reg_data[44:40];
	else
	loop_end <= le_lut;
end
end
end

always @(posedge clk)   //TREG written or not
begin
if (reset)
	treg <= {33{1'b0}};
else if (start_exec)
begin
	if (control_reg_data[25]==1'b1) 
	begin
		treg <= tile_out;
	end
end
end



wire [5:0] ldst;
//assign ldst = {control_reg_data[34:30],control_reg_data[64]};
assign ldst = operation; 

reg [5:0] ldst_prev_cycle;;
reg [1:0] op_shift_prev_cycle;
reg [1:0] op_lhs_prev_cycle;

assign lsu_alu_out = (ldst_prev_cycle[4:0] == 5'b11000 || ldst_prev_cycle[4:0] == 5'b11001 || ldst_prev_cycle[4:0] == 5'b11010) ? data_out_dm_reg : alu_out_dm_tiles[31:0];

always @(posedge clk)
begin
if (reset)
begin
	ldst_prev_cycle <= 6'b000000;
	op_shift_prev_cycle <= 2'b00;
	op_lhs_prev_cycle <= 2'b00;
end
else
begin
	ldst_prev_cycle <= ldst;
	op_shift_prev_cycle <= op_shift[1:0];
	op_lhs_prev_cycle <= op_lhs[1:0];
end
end

always @(posedge clk)  //load store operations
begin
if (reset) 
begin
                data_out_dm_reg <= 32'b0;
end
else if (start_exec)
begin
casex(ldst)
6'b111000:
        begin
		data_out_dm_reg <= data_out_dm;
        end
6'b011000:
        begin
		data_out_dm_reg <= data_out_dm;
        end
6'b110110:
        begin
		data_out_dm_reg <= data_out_dm;
        end
6'b010110:
        begin
		data_out_dm_reg <= data_out_dm;
        end
6'b111001:
        begin
		if (op_shift[1:0] == 2'b00)
		begin
		data_out_dm_reg <= {{16{1'b0}},data_out_dm[15:0]};
		end
		else if (op_shift[1:0] == 2'b10)
		begin
		data_out_dm_reg <= {{16{1'b0}},data_out_dm[31:16]};
		end
		else
		begin
		data_out_dm_reg <= 32'b0;
		end
        end
6'b011001:
        begin
		if (op_lhs[1:0] == 2'b00)
		begin
		data_out_dm_reg <= {{16{1'b0}},data_out_dm[15:0]};
		end
		else if (op_lhs[1:0] == 2'b10)
		begin
		data_out_dm_reg <= {{16{1'b0}},data_out_dm[31:16]};
		end
		else
		begin
		data_out_dm_reg <= 32'b0;
		end
        end
6'b111010:
        begin
		if (op_shift[1:0]== 2'b00)
		begin
		data_out_dm_reg <= {{24{1'b0}},data_out_dm[7:0]};
		end
		else if (op_shift[1:0]== 2'b01)
		begin
		data_out_dm_reg <= {{24{1'b0}},data_out_dm[15:8]};
		end
		else if (op_shift[1:0]== 2'b10)
		begin
		data_out_dm_reg <= {{24{1'b0}},data_out_dm[23:16]};
		end
		else if (op_shift[1:0]== 2'b11)
		begin
		data_out_dm_reg <= {{24{1'b0}},data_out_dm[31:24]};
		end
		else
		begin
		data_out_dm_reg <= 32'b0;
		end
        end
6'b011010:
        begin
		if (op_lhs[1:0]== 2'b00)
		begin
		data_out_dm_reg <= {{24{1'b0}},data_out_dm[7:0]};
		end
		else if (op_lhs[1:0]== 2'b01)
		begin
		data_out_dm_reg <= {{24{1'b0}},data_out_dm[15:8]};
		end
		else if (op_lhs[1:0]== 2'b10)
		begin
		data_out_dm_reg <= {{24{1'b0}},data_out_dm[23:16]};
		end
		else if (op_lhs[1:0]== 2'b11)
		begin
		data_out_dm_reg <= {{24{1'b0}},data_out_dm[31:24]};
		end
		else
		begin
		data_out_dm_reg <= 32'b0;
		end
        end
default:
	begin
		data_out_dm_reg <= 32'b0;
	end
endcase
end
end


//always @(posedge clk)  //load store operations
always_comb
begin
if (~not_to_execute_all) begin
casex(ldst)
6'b111000:
        begin
		$display("LOAD CONST INST");
                rd_en_dm <= 1'b0;
		wr_en_dm <= 1'b1;
                addr_dm <= op_shift[10:2];
                data_in_dm <= {32{1'b0}};
		$display ("ASK TILE rd_en_dm = %b", rd_en_dm);
		$display ("ASK TILE wr_en_dm = %b", wr_en_dm);
		$display ("ASK TILE addr_dm = %b", addr_dm);
		if (op_shift[1:0] == 2'b00)
		bit_en <= 32'b0;
		else
		bit_en <= 32'b1;
        end
6'b011000:
        begin
		$display("LOAD INST");
                rd_en_dm <= 1'b0;
		wr_en_dm <= 1'b1;
                addr_dm <= op_lhs[10:2];
                data_in_dm <= {32{1'b0}};
		if (op_lhs[1:0] == 2'b00)
		bit_en <= 32'b0;
		else
		bit_en <= 32'b1;
        end
6'b110110:
        begin
		$display("LOADCL CONST INST");
                rd_en_dm <= 1'b0;
		wr_en_dm <= 1'b1;
                addr_dm <= op_shift[10:2];
                data_in_dm <= {32{1'b0}};
		if (op_shift[1:0] == 2'b00)
		bit_en <= 32'b0;
		else
		bit_en <= 32'b1;
        end
6'b010110:
        begin
		$display("LOADCL INST");
                rd_en_dm <= 1'b0;
		wr_en_dm <= 1'b1;
                addr_dm <= op_lhs[10:2];
                data_in_dm <= {32{1'b0}};
		if (op_lhs[1:0] == 2'b00)
		bit_en <= 32'b0;
		else
		bit_en <= 32'b1;
        end
6'b111001:
        begin
		$display("LOAD CONST 2bytes INST");
                rd_en_dm <= 1'b0;
		wr_en_dm <= 1'b1;
                addr_dm <= op_shift[10:2];
                data_in_dm <= {32{1'b0}};
		if (op_shift[1:0] == 2'b00)
		begin
		bit_en <= {{16{1'b1}},{16{1'b0}}};
		end
		else if (op_shift[1:0] == 2'b10)
		begin
		bit_en <= {{16{1'b0}},{16{1'b1}}};
		end
		else
		begin
		bit_en <= {{16{1'b1}},{16{1'b1}}};
		end
        end
6'b011001:
        begin
		$display("LOAD 2bytes INST");
                rd_en_dm <= 1'b0;
		wr_en_dm <= 1'b1;
                addr_dm <= op_lhs[10:2];
                data_in_dm <= {32{1'b0}};
		if (op_lhs[1:0] == 2'b00)
		begin
		bit_en <= {{16{1'b1}},{16{1'b0}}};
		end
		else if (op_lhs[1:0] == 2'b10)
		begin
		bit_en <= {{16{1'b0}},{16{1'b1}}};
		end
		else
		begin
		bit_en <= {{16{1'b1}},{16{1'b1}}};
		end
        end
6'b111010:
        begin
		$display("LOAD CONST 1byte INST");
                rd_en_dm <= 1'b0;
		wr_en_dm <= 1'b1;
                addr_dm <= op_shift[10:2];
                data_in_dm <= {32{1'b0}};
		if (op_shift[1:0] == 2'b00)
		begin
		bit_en <= {{24{1'b1}},{8{1'b0}}};
		end
		else if (op_shift[1:0] == 2'b01)
		begin
		bit_en <= {{16{1'b1}},{8{1'b0}},{8{1'b1}}};
		end
		else if (op_shift[1:0] == 2'b10)
		begin
		bit_en <= {{8{1'b1}},{8{1'b0}},{16{1'b1}}};
		end
		else if (op_shift[1:0] == 2'b11)
		begin
		bit_en <= {{8{1'b0}},{24{1'b1}}};
		end
		else
		begin
		bit_en <= {{24{1'b1}},{8{1'b0}}};
		end
        end
6'b011010:
        begin
		$display("LOAD 1byte INST");
                rd_en_dm <= 1'b0;
		wr_en_dm <= 1'b1;
                addr_dm <= op_lhs[10:2];
                data_in_dm <= {32{1'b0}};
		if (op_lhs[1:0] == 2'b00)
		begin
		bit_en <= {{24{1'b1}},{8{1'b0}}};
		end
		else if (op_lhs[1:0] == 2'b01)
		begin
		bit_en <= {{16{1'b1}},{8{1'b0}},{8{1'b1}}};
		end
		else if (op_lhs[1:0] == 2'b10)
		begin
		bit_en <= {{8{1'b1}},{8{1'b0}},{16{1'b1}}};
		end
		else if (op_lhs[1:0] == 2'b11)
		begin
		bit_en <= {{8{1'b0}},{24{1'b1}}};
		end
		else
		begin
		bit_en <= {{24{1'b1}},{8{1'b0}}};
		end
        end
6'b111011:
        begin
		$display("STORE CONST INST");
                rd_en_dm <= 1'b0;
		wr_en_dm <= 1'b0;
                addr_dm <= op_shift[10:2];
                data_in_dm <= op_rhs[31:0];
		if (op_shift[1:0] == 2'b00)
		bit_en <= 32'b0;
		else
		bit_en <= 32'b1;
	end
6'b011011:
        begin
		$display("STORE INST");
                rd_en_dm <= 1'b0;
		wr_en_dm <= 1'b0;
                addr_dm <= op_lhs[10:2];
                data_in_dm <= op_rhs[31:0];
		if (op_lhs[1:0] == 2'b00)
		bit_en <= 32'b0;
		else
		bit_en <= 32'b1;
	end
6'b111100:
        begin
		$display("STORE 2byte CONST INST");
                rd_en_dm <= 1'b0;
		wr_en_dm <= 1'b0;
                addr_dm <= op_shift[10:2];
		if (op_shift[1:0] == 2'b00) begin		
			bit_en <= {{16{1'b1}},{16{1'b0}}};
                	data_in_dm <= {{16{1'b0}},op_rhs[15:0]};
		end
		else if (op_shift[1:0] == 2'b10) begin		
			bit_en <= {{16{1'b0}},{16{1'b1}}};
                	data_in_dm <= {op_rhs[15:0],{16{1'b0}}};
		end
		else begin	
			assert (0);	
			bit_en <= {{16{1'b1}},{16{1'b1}}};
                	data_in_dm <= {{16{1'b0}},op_rhs[15:0]};
		end
	end
6'b011100:
        begin
		$display("STORE 2byte INST");
                rd_en_dm <= 1'b0;
		wr_en_dm <= 1'b0;
                addr_dm <= op_lhs[10:2];
		if (op_lhs[1:0] == 2'b00) begin		
			bit_en <= {{16{1'b1}},{16{1'b0}}};
                	data_in_dm <= {{16{1'b0}},op_rhs[15:0]};
		end
		else if (op_lhs[1:0] == 2'b10) begin		
			bit_en <= {{16{1'b0}},{16{1'b1}}};
                	data_in_dm <= {op_rhs[15:0],{16{1'b0}}};
		end
		else begin		
			assert (0);	
			bit_en <= {{16{1'b1}},{16{1'b1}}};
                	data_in_dm <= {{16{1'b0}},op_rhs[15:0]};
		end
	end
6'b111101:
        begin
		$display("STORE 1byte CONST INST");
                rd_en_dm <= 1'b0;
		wr_en_dm <= 1'b0;
                addr_dm <= op_shift[10:2];
		if (op_shift[1:0] == 2'b00) begin		
                	data_in_dm <= {{24{1'b0}},op_rhs[7:0]};
			bit_en <= {{24{1'b1}},{8{1'b0}}};
		end
		else if (op_shift[1:0] == 2'b01) begin
                	data_in_dm <= {{16{1'b0}},op_rhs[7:0],{8{1'b0}}};
			bit_en <= {{16{1'b1}},{8{1'b0}},{8{1'b1}}};
		end
		else if (op_shift[1:0] == 2'b10) begin
                	data_in_dm <= {{8{1'b0}},op_rhs[7:0],{16{1'b0}}};
			bit_en <= {{8{1'b1}},{8{1'b0}},{16{1'b1}}};
		end
		else if (op_shift[1:0] == 2'b11) begin
                	data_in_dm <= {op_rhs[7:0],{24{1'b0}}};
			bit_en <= {{8{1'b0}},{24{1'b1}}};
		end
		else begin
			bit_en <= {{24{1'b1}},{8{1'b0}}};
			assert (0);	
                	data_in_dm <= {{16{1'b0}},op_rhs[15:0]};
		end
		
	end
6'b011101:
        begin
		$display("STORE 1byte INST");
                rd_en_dm <= 1'b0;
		wr_en_dm <= 1'b0;
                addr_dm <= op_lhs[10:2];
		if (op_lhs[1:0] == 2'b00) begin		
                	data_in_dm <= {{24{1'b0}},op_rhs[7:0]};
			bit_en <= {{24{1'b1}},{8{1'b0}}};
		end
		else if (op_lhs[1:0] == 2'b01) begin
                	data_in_dm <= {{16{1'b0}},op_rhs[7:0],{8{1'b0}}};
			bit_en <= {{16{1'b1}},{8{1'b0}},{8{1'b1}}};
		end
		else if (op_lhs[1:0] == 2'b10) begin
                	data_in_dm <= {{8{1'b0}},op_rhs[7:0],{16{1'b0}}};
			bit_en <= {{8{1'b1}},{8{1'b0}},{16{1'b1}}};
		end
		else if (op_lhs[1:0] == 2'b11) begin
                	data_in_dm <= {op_rhs[7:0],{24{1'b0}}};
			bit_en <= {{8{1'b0}},{24{1'b1}}};
		end
		else begin
			bit_en <= {{24{1'b1}},{8{1'b0}}};
			assert (0);	
                	data_in_dm <= {{16{1'b0}},op_rhs[15:0]};
		end
	end
default:
	begin
		//$display("NOT LOAD OR STORE INST");
                rd_en_dm <= 1'b1;
                wr_en_dm <= 1'b1;
                addr_dm <= 9'b000000000 ;
                data_in_dm <= {32{1'b0}};
		bit_en <= {32{1'b1}};
	end
endcase
end
else begin
		rd_en_dm <= 1'b1;	
                wr_en_dm <= 1'b1;
                addr_dm <= 9'b000000000 ;
                data_in_dm <= {32{1'b0}};
		bit_en <= {32{1'b1}};
end
end

reg [5:0] xbar_input0;
reg [5:0] xbar_input1;
reg [5:0] xbar_input2;
reg [5:0] xbar_input3;
reg [5:0] xbar_input4;
reg [5:0] xbar_input5;
reg [5:0] xbar_input6;

/*
always @ (posedge clk)
begin
$display("ASK In tile control_reg_data = %b %b", control_reg_data, my_xy_id);
$display("ASK In tile i__flit_in = %b %b", i__flit_in[0][0], my_xy_id);
$display("ASK In tile i__sram_xbar_sel = %b %b", i__sram_xbar_sel[0], my_xy_id);
//$display("ASK In tile data_out_dm = %b %b", data_out_dm, my_xy_id);
$display("ASK In tile operation = %b", operation);
$display("ASK IN op_rhs = %b", op_rhs);
$display("ASK IN put_rhs = %b", put_rhs);
$display("ASK IN get = %b", get);
$display("ASK IN op_lhs = %b", op_lhs);
$display("ASK IN op_shift = %b", op_shift);
$display("ASK IN op_predicate = %b", op_predicate);
$display("ASK IN TILE ALU_OUT = %b", alu_out);
$display("ASK In tile tile_out = %b", tile_out);
end
*/
always @ (control_reg_data[20:18] or control_reg_data[17:15] or control_reg_data[14:12] or control_reg_data[11:9] or control_reg_data[8:6] or control_reg_data[5:3] or control_reg_data[2:0])
//always @(posedge clk)
begin
case (control_reg_data[2:0])
3'b000: begin
		xbar_input0 <= 6'b000001;
		i__sram_xbar_sel[0] <= 6'b000001;
		$display("ASK In tile xbar[0] = %b", i__sram_xbar_sel[0]);
	end
3'b001: begin
		xbar_input0 <= 6'b000010;
		i__sram_xbar_sel[0] <= 6'b000010;
		$display("ASK In tile xbar[1] = %b", i__sram_xbar_sel[0]);
	end
3'b010: begin
		xbar_input0 <= 6'b000100;
		i__sram_xbar_sel[0] <= 6'b000100;
		$display("ASK In tile xbar[2] = %b", i__sram_xbar_sel[0]);
	end
3'b011: begin
		xbar_input0 <= 6'b001000;
		i__sram_xbar_sel[0] <= 6'b001000;
	end
3'b100: begin
		xbar_input0 <= 6'b010000;
		i__sram_xbar_sel[0] <= 6'b010000;
		//$display("ASK In tile xbar[4] = %b %b", my_xy_id, i__sram_xbar_sel[0]);
		//$display("ASK In tile control_reg_data = %b", control_reg_data);
		//$display("ASK In tile i__sram_xbar_sel = %b %b", i__sram_xbar_sel[0], my_xy_id);
	end
3'b101: begin
		xbar_input0 <= 6'b100000;
		i__sram_xbar_sel[0] <= 6'b100000;
	end
default: begin
		xbar_input0 <= 6'b000000;
		i__sram_xbar_sel[0] <= 6'b000000;
	end
endcase
end

always @ (control_reg_data[20:18] or control_reg_data[17:15] or control_reg_data[14:12] or control_reg_data[11:9] or control_reg_data[8:6] or control_reg_data[5:3] or control_reg_data[2:0])
//always @(posedge clk)
begin
case (control_reg_data[5:3])
3'b000: begin   
                xbar_input1 <= 6'b000001;
                i__sram_xbar_sel[1] <= 6'b000001;
        end     
3'b001: begin   
                xbar_input1 <= 6'b000010;
                i__sram_xbar_sel[1] <= 6'b000010;
        end     
3'b010: begin   
                xbar_input1 <= 6'b000100;
                i__sram_xbar_sel[1] <= 6'b000100;
        end     
3'b011: begin
                xbar_input1 <= 6'b001000;
                i__sram_xbar_sel[1] <= 6'b001000;
        end     
3'b100: begin   
                xbar_input1 <= 6'b010000;
                i__sram_xbar_sel[1] <= 6'b010000;
        end     
3'b101: begin   
                xbar_input1 <= 6'b100000;
                i__sram_xbar_sel[1] <= 6'b100000;
        end     
default: begin  
                xbar_input1 <= 6'b000000;
                i__sram_xbar_sel[1] <= 6'b000000;
        end
endcase
end

always @ (control_reg_data[20:18] or control_reg_data[17:15] or control_reg_data[14:12] or control_reg_data[11:9] or control_reg_data[8:6] or control_reg_data[5:3] or control_reg_data[2:0])
//always @(posedge clk)
begin
case (control_reg_data[8:6])
3'b000: begin   
                xbar_input2 <= 6'b000001;
                i__sram_xbar_sel[2] <= 6'b000001;
        end     
3'b001: begin   
                xbar_input2 <= 6'b000010;
                i__sram_xbar_sel[2] <= 6'b000010;
        end     
3'b010: begin   
                xbar_input2 <= 6'b000100;
                i__sram_xbar_sel[2] <= 6'b000100;
        end     
3'b011: begin
                xbar_input2 <= 6'b001000;
                i__sram_xbar_sel[2] <= 6'b001000;
        end     
3'b100: begin   
                xbar_input2 <= 6'b010000;
                i__sram_xbar_sel[2] <= 6'b010000;
        end     
3'b101: begin   
                xbar_input2 <= 6'b100000;
                i__sram_xbar_sel[2] <= 6'b100000;
        end     
default: begin  
                xbar_input2 <= 6'b000000;
                i__sram_xbar_sel[2] <= 6'b000000;
        end
endcase
end

always @ (control_reg_data[20:18] or control_reg_data[17:15] or control_reg_data[14:12] or control_reg_data[11:9] or control_reg_data[8:6] or control_reg_data[5:3] or control_reg_data[2:0])
//always @(posedge clk)
begin
case (control_reg_data[11:9])
3'b000: begin   
                xbar_input3 <= 6'b000001;
                i__sram_xbar_sel[3] <= 6'b000001;
        end     
3'b001: begin   
                xbar_input3 <= 6'b000010;
                i__sram_xbar_sel[3] <= 6'b000010;
        end     
3'b010: begin   
                xbar_input3 <= 6'b000100;
                i__sram_xbar_sel[3] <= 6'b000100;
        end     
3'b011: begin
                xbar_input3 <= 6'b001000;
                i__sram_xbar_sel[3] <= 6'b001000;
        end     
3'b100: begin   
                xbar_input3 <= 6'b010000;
                i__sram_xbar_sel[3] <= 6'b010000;
        end     
3'b101: begin   
                xbar_input3 <= 6'b100000;
                i__sram_xbar_sel[3] <= 6'b100000;
        end     
default: begin  
                xbar_input3 <= 6'b000000;
                i__sram_xbar_sel[3] <= 6'b000000;
        end
endcase
end

always @ (control_reg_data[20:18] or control_reg_data[17:15] or control_reg_data[14:12] or control_reg_data[11:9] or control_reg_data[8:6] or control_reg_data[5:3] or control_reg_data[2:0])
//always @(posedge clk)
begin
case (control_reg_data[14:12])
3'b000: begin   
                xbar_input4 <= 6'b000001;
                i__sram_xbar_sel[4] <= 6'b000001;
        end     
3'b001: begin   
                xbar_input4 <= 6'b000010;
                i__sram_xbar_sel[4] <= 6'b000010;
        end     
3'b010: begin   
                xbar_input4 <= 6'b000100;
                i__sram_xbar_sel[4] <= 6'b000100;
        end     
3'b011: begin
                xbar_input4 <= 6'b001000;
                i__sram_xbar_sel[4] <= 6'b001000;
        end     
3'b100: begin   
                xbar_input4 <= 6'b010000;
                i__sram_xbar_sel[4] <= 6'b010000;
        end     
3'b101: begin   
                xbar_input4 <= 6'b100000;
                i__sram_xbar_sel[4] <= 6'b100000;
        end     
default: begin  
                xbar_input4 <= 6'b000000;
                i__sram_xbar_sel[4] <= 6'b000000;
        end
endcase
end

always @ (control_reg_data[20:18] or control_reg_data[17:15] or control_reg_data[14:12] or control_reg_data[11:9] or control_reg_data[8:6] or control_reg_data[5:3] or control_reg_data[2:0])
//always @(posedge clk)
begin
//if (control_reg_data[64] == 1'b0) begin //if ConstValid =0, continue as usual, else use control_reg_data[17:15] as 3 bits of constant
case (control_reg_data[17:15])
3'b000: begin   
                xbar_input5 <= 6'b000001;
                i__sram_xbar_sel[5] <= 6'b000001;
        end     
3'b001: begin   
                xbar_input5 <= 6'b000010;
                i__sram_xbar_sel[5] <= 6'b000010;
        end     
3'b010: begin   
                xbar_input5 <= 6'b000100;
                i__sram_xbar_sel[5] <= 6'b000100;
        end     
3'b011: begin
                xbar_input5 <= 6'b001000;
                i__sram_xbar_sel[5] <= 6'b001000;
        end     
3'b100: begin   
                xbar_input5 <= 6'b010000;
                i__sram_xbar_sel[5] <= 6'b010000;
        end     
3'b101: begin   
                xbar_input5 <= 6'b100000;
                i__sram_xbar_sel[5] <= 6'b100000;
        end     
default: begin  
                xbar_input5 <= 6'b000000;
                i__sram_xbar_sel[5] <= 6'b000000;
        end
endcase
//end
end

always @ (control_reg_data[20:18] or control_reg_data[17:15] or control_reg_data[14:12] or control_reg_data[11:9] or control_reg_data[8:6] or control_reg_data[5:3] or control_reg_data[2:0])
//always @(posedge clk)
begin
case (control_reg_data[20:18])
3'b000: begin   
                xbar_input6 <= 6'b000001;
                i__sram_xbar_sel[6] <= 6'b000001;
        end     
3'b001: begin   
                xbar_input6 <= 6'b000010;
                i__sram_xbar_sel[6] <= 6'b000010;
        end     
3'b010: begin   
                xbar_input6 <= 6'b000100;
                i__sram_xbar_sel[6] <= 6'b000100;
        end     
3'b011: begin
                xbar_input6 <= 6'b001000;
                i__sram_xbar_sel[6] <= 6'b001000;
        end     
3'b100: begin   
                xbar_input6 <= 6'b010000;
                i__sram_xbar_sel[6] <= 6'b010000;
        end     
3'b101: begin   
                xbar_input6 <= 6'b100000;
                i__sram_xbar_sel[6] <= 6'b100000;
        end     
default: begin  
                xbar_input6 <= 6'b000000;
                i__sram_xbar_sel[6] <= 6'b000000;
        end
endcase
end


router
    #(
        .NUM_VCS                        (ROUTER_NUM_VCS)
        `ifdef FLEXIBLE_FLIT_ENABLE
        ,
        .NUM_SSRS                       (NUM_SSRS)
        `endif
    )
    router(
        .clk                            (clk),
        .reset                          (r__reset__pff),
        .i__sram_xbar_sel               (i__sram_xbar_sel),
        .i__flit_in                     (i__flit_in),
        .i__alu_out                     (tile_out),
        .i__treg                        (treg),
        .o__flit_out                    (o__flit_out_wire),
        .regbypass			(regbypass),
        .regWEN				(regWEN)
    );
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Reset synchronizor
//------------------------------------------------------------------------------
always_ff @ (posedge clk)
begin
    r__reset__pff <= reset;
end
//------------------------------------------------------------------------------

//wangbo
`endif

endmodule
