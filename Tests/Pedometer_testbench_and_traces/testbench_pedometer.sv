
// Simulation precision
`timescale 1ns/1ns

// Clock period
`define CYCLE                       (50)
`define HALF_CYCLE                  (`CYCLE / 2.0)

`define REF_CYCLE                   (50)
`define REF_HALF_CYCLE              (`REF_CYCLE / 2.0)

`define SCAN_CYCLE                  (`CYCLE * 4.0)
`define SCAN_HALF_CYCLE             (`SCAN_CYCLE / 2.0)

// Active simulation cycles (started to count after all the initialization)
`define NUM_SIM_CYCLES              2000

// Generic names to be used in the testbench
`define TESTBENCH_NAME              network_fixed_flexible_tb
`define TEST_MODULE_NAME            chip 
`define TEST_INSTANCE_NAME          `TEST_MODULE_NAME
`define TEST_DUMP_NAME              `TESTBENCH_NAME
`define NUM_INST		    2564
`define DMEM_SIZE		    2048
`define READ_DELAY 		    0 //changed from 10
`define WRITE_DELAY 		    0 //changed from 5
`define READ_TASK_DELAY 	    0 //chaned from 10

// Testbench
module `TESTBENCH_NAME;

//------------------------------------------------------------------------------
// Parameters
//------------------------------------------------------------------------------
import TopPkg::*;
import SMARTPkg::*;

localparam NUM_RESET_SYNC_STAGES        = 2;
localparam NIC_OUTPUT_FIFO_DEPTH        = 1;
localparam ROUTER_NUM_VCS               = 8;
`ifdef FLEXIBLE_FLIT_ENABLE
localparam NUM_SSRS                     = NUM_HOPS_PER_CYCLE;
`endif

localparam ROUTER_NUM_INPUT_PORTS       = 6;
localparam ROUTER_NUM_OUTPUT_PORTS      = 7;


//------------------------------------------------------------------------------
// IO
//------------------------------------------------------------------------------
wire                                    reset_pll_pad;
wire                                    i__pll_clk_ref_pad;
wire                                    o__pll_clk_out_locked_pad;
wire                                    o__pll_clk_out_divided_pad;

wire                                    reset_network_pad;
logic                                   reset_pll;
logic                                   i__pll_clk_ref;
logic                                   o__pll_clk_out_locked;
logic                                   o__pll_clk_out_divided;

logic                                   reset_network;

logic [31:0]				num_inst;
logic [4:0]				clk_cnt;
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Simulation required signals
//------------------------------------------------------------------------------
integer                                 num_sim_cycles;
event                                   initial_signals;
event                                   start_stimulus;
//------------------------------------------------------------------------------

wire [15:0] scan_data;
reg [15:0] data_in;
reg [15:0] addr_in;
wire [15:0] data_out;
reg scan_data_or_addr;
wire bist_success;
reg spi_en;

reg scan_start_exec;
reg chip_en;
reg bist_en;
reg read_write;
wire data_out_valid;
reg [1:0] data_addr_valid;

reg [5:0] clkSel;
reg [3:0] divSel;
reg [1:0] fixdivSel;
reg vcoEn, clkExtEn, clkExt, dlIn0, dlIn1, dlIn2, clkEn;
wire clkOut_Mon;

assign data_out = scan_data;
assign scan_data = (~read_write) ? data_in : {16{1'bz}};
//------------------------------------------------------------------------------
// Test module instantiation
//------------------------------------------------------------------------------
`TEST_MODULE_NAME
    #(
	.NUM_RESET_SYNC_STAGES          (NUM_RESET_SYNC_STAGES),
        .NIC_OUTPUT_FIFO_DEPTH          (NIC_OUTPUT_FIFO_DEPTH),
        .ROUTER_NUM_VCS                 (ROUTER_NUM_VCS)
        `ifdef FLEXIBLE_FLIT_ENABLE
        ,
        .NUM_SSRS                       (NUM_SSRS)
        `endif
     )
    `TEST_INSTANCE_NAME(
	.clk(i__pll_clk_ref),
    	.reset_network (reset_network_pad),
	.sck (sck),
	.ss (ss),
	.sdin (sdin),
	.sdout (sdout),
	.scan_data (scan_data),
	.scan_data_or_addr(scan_data_or_addr),
	.read_write(read_write),
	.data_out_valid (data_out_valid),
	.data_addr_valid (data_addr_valid),
    	.scan_start_exec (scan_start_exec),
    	.exec_end (exec_end),
    	.chip_en (chip_en),
    	.spi_en (spi_en),
    	.bist_success (bist_success),
    	.bist_en (bist_en),
	.vcoEn (1'b0),
        .clkExtEn (1'b1),
        .clkExt (i__pll_clk_ref_pad),
        .clkSel (clkSel),
        .divSel (divSel),
        .fixdivSel (fixdivSel),
        .dlIn0 (dlIn0),
        .dlIn1 (dlIn1),
        .dlIn2 (dlIn2),
        .clkEn (1'b1),
        .clkOut_Mon (clkOut_Mon),
    	.scan_chain_out(scan_out_wire),
    	.scan_chain_in(1'b0),
    	.scan_chain_en(1'b0),
    	.scan_chain_sel_0(),
    	.scan_chain_sel_1(),
    	.scan_chain_sel_2(),
    	.scan_chain_sel_3()
	);




assign reset_pll_pad                    = reset_pll;
assign i__pll_clk_ref_pad               = i__pll_clk_ref;
assign o__pll_clk_out_locked            = o__pll_clk_out_locked_pad;
assign o__pll_clk_out_divided           = o__pll_clk_out_divided_pad;
assign reset_network_pad                = reset_network;



//------------------------------------------------------------------------------
// Support module instantiation
//------------------------------------------------------------------------------
clock_generator
    #(
        .HALF_CYCLE                     (`REF_HALF_CYCLE),
        .SCAN_CLOCK                     (0),
        .INIT_VALUE                     (1'b0)
    )
    system_clk(
        .clk                            (i__pll_clk_ref),
        .clk_delay                      (),
        .clk_count                      ()
    );
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Stimulus
//------------------------------------------------------------------------------
initial
begin: start_stimulus_block
    // Wait until the start_stimulus is triggered
    @ (start_stimulus);
end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
// Initial values
//------------------------------------------------------------------------------
initial
begin: initial_signals_block
    @ (initial_signals);
    	chip_en = 1'b0;
    	spi_en = 1'b0;
	read_write = 1'b0;
    	clk_cnt = 1'b0;
    	num_inst = 32'b0;
    	scan_start_exec = 1'b0;
	bist_en = 1'b0;
	//scan_data = 16'b0000000000000000;
	scan_data_or_addr = 1'b0;
	clkSel = 6'd0;
        divSel = 4'd0;
        fixdivSel = 2'd0;
        clkEn = 1'b0;
        vcoEn = 1'b0;
        clkExtEn = 1'b0;

end
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Simulation control flow
//------------------------------------------------------------------------------
initial
begin: simulation_control_flow
    $set_toggle_region(network_fixed_flexible_tb.chip);
    //$toggle_start();

    reset_pll       = 1'b0;
    reset_network   = 1'b0;
	

    $display("ASK reset_network is", reset_network);
    // Initial interface signals
    -> initial_signals;

    // Free run clock before reset to make sure the reset can really "reset"
    #(`SCAN_CYCLE)
#1000
    reset_pll       = 1'b1;
    reset_network   = 1'b1;
//wangbo: show reset
    $display("ASK reset_network is", reset_network);


    // PLL requires at least 20 REF_CYLCE before removing the reset_pll
    #2000
    reset_pll = 1'b0;

    // Wait until the PLL indicates that the clock is locked
@ (posedge i__pll_clk_ref_pad);
    // Remove the reset_network
    //wangbo: extend removal time of reset for fifo
    #200
    reset_network = 1'b0;

    $display("ASK reset_network after clock locked is", reset_network);
    // Trigger the start of the stimulus
    -> start_stimulus;

    // Determine the specified simulation cycle
    if(!$value$plusargs("NUM_SIM_CYCLES=%d", num_sim_cycles))
    begin
        num_sim_cycles = `NUM_SIM_CYCLES;
    end

@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);

@(posedge i__pll_clk_ref_pad);
chip_en = 1'b1;
clkEn = 1'b1;
divSel = 4'd1;
vcoEn = 1'b0;
clkExtEn = 1'b1;

@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);

@(posedge i__pll_clk_ref_pad);
bist_en = 1'b1;

@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);

@(posedge i__pll_clk_ref_pad);
bist_en = 1'b0;

@(posedge i__pll_clk_ref_pad);
begin
for (num_inst =0; num_inst< `NUM_INST; num_inst++)
begin
        @(posedge i__pll_clk_ref_pad);
	#0.1
        	initialize_addrSRAM;
		addr_SRAM;
        @(posedge i__pll_clk_ref_pad);
	#0.1
	data_addr_valid <= 2'b00;
        @(posedge i__pll_clk_ref_pad);
	#0.1
        @(posedge i__pll_clk_ref_pad);
	#0.1
        	initialize_dataSRAM;
		data_SRAM;
        @(posedge i__pll_clk_ref_pad);
	#0.1
	data_addr_valid <= 2'b00;
        @(posedge i__pll_clk_ref_pad);
	#0.1
        @(posedge i__pll_clk_ref_pad);
end
end


@(posedge i__pll_clk_ref_pad);

@(posedge i__pll_clk_ref_pad);
read_write = 1'b1;
@(posedge i__pll_clk_ref_pad);
@(posedge i__pll_clk_ref_pad);

    $display("[%16d] ASK : START EXEC", $realtime);
@(posedge i__pll_clk_ref_pad);
$toggle_start();
scan_start_exec = 1'b1;


    $display("[%16d] ASK : END EXEC", $realtime);
@(posedge exec_end);
@(posedge i__pll_clk_ref_pad);
begin
for (int i =0; i<32; i++)
	@(posedge i__pll_clk_ref_pad);
scan_start_exec = 1'b0;
end



@(posedge i__pll_clk_ref_pad);
data_in = 6128;
scan_data_or_addr = 1;
read_write = 0;
data_addr_valid = 2'b11;

@(posedge i__pll_clk_ref_pad);
scan_data_or_addr = 0;
read_write = 1;

@(posedge i__pll_clk_ref_pad);
read_write = 1;

@(posedge i__pll_clk_ref_pad);
data_in = 266;
scan_data_or_addr = 1;
read_write = 0;
data_addr_valid = 2'b11;

@(posedge i__pll_clk_ref_pad);
scan_data_or_addr = 0;
read_write = 1;

@(posedge i__pll_clk_ref_pad);
read_write = 1;

@(posedge i__pll_clk_ref_pad);
read_write = 1;

@(posedge i__pll_clk_ref_pad);
data_addr_valid = 2'b00;




    // Wait until the specified simulation time and call $finish
    #(`CYCLE*num_sim_cycles)
    $toggle_stop();
    //$toggle_report("my_saif",1.0e-12, "network_fixed_flexible_tb");
     $toggle_report("hycube.saif",1.0e-12, "network_fixed_flexible_tb.chip.hycube");



    // Finish the simulation
    $finish();
end
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

task initialize_dataSRAM;
begin
reg [15:0] Memory0 [2563:0];
integer tracefile0;

           tracefile0 <= $fopen("totaldata_corr.trc", "r");
           $readmemb ("totaldata_corr.trc", Memory0);
           data_in <= Memory0[num_inst];
           $fclose(tracefile0);
end
endtask

task initialize_addrSRAM;
begin
reg [15:0] Memory1 [2563:0];
integer tracefile1;

           tracefile1 <= $fopen("totaladdr_corr.trc", "r");
           $readmemb ("totaladdr_corr.trc", Memory1);
           data_in <= Memory1[num_inst];
           $fclose(tracefile1);
end
endtask


task addr_SRAM;
begin
    $display("[%16d] ASK : Control SRAM Initialize", $realtime);
        scan_start_exec <= 1'b0;
        chip_en <= 1'b1;
        scan_data_or_addr <= 1'b1; // it is address
        read_write <= 1'b0;
        data_addr_valid <= 2'b11;
end
endtask

task data_SRAM;
begin
        scan_start_exec <= 1'b0;
        chip_en <= 1'b1;
        scan_data_or_addr <= 1'b0; // it is data
        read_write <= 1'b0;
        data_addr_valid <= 2'b11;
end
endtask



//------------------------------------------------------------------------------
// Dump wave
//------------------------------------------------------------------------------
initial
begin: dump_wave
`ifdef VPD
    //string test_dump_name = $psprintf("/var/tmp/thilini/%s.vpd", `STRINGIFY(`TEST_DUMP_NAME));
    // Dump VCD+ (VPD)
    $vcdplusfile("test.vpd");
    $vcdpluson;
    $vcdplusmemon;
`endif

`ifdef VCD
    // Dump VCD
    //string test_dump_name = $psprintf("/var/tmp/thilini/%s.vcd", `STRINGIFY(`TEST_DUMP_NAME));
    $dumpfile("test.vcd");
    $dumpvars(0, `TESTBENCH_NAME);
`endif
end
endmodule

