
//------------------------------------------------------------------------------
// First-word fall-through synchronous FIFO with synchronous reset
//
// If the fifo is empty and there is a valid data at the input, this data is 
// visible at the output in the following cycle.
//------------------------------------------------------------------------------
module fifo_base (
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
parameter  DATA_WIDTH   = 64;
parameter  DEPTH        = 3;
parameter  DEPTH_1_OPTIMIZATION = 0;

localparam ADDR_WIDTH   = $clog2(DEPTH);
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
output logic [DATA_WIDTH-1:0]           oa__all_data            [DEPTH-1:0];
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Signals
//------------------------------------------------------------------------------
logic                                   w__push;
logic                                   w__wr_clk;

logic        [DATA_WIDTH-1:0]           r__buffer__pff          [DEPTH-1:0];
//------------------------------------------------------------------------------


// Make special case for DEPTH=1 FIFO
generate 

if((DEPTH == 1) && (DEPTH_1_OPTIMIZATION == 1))
begin: depth_1
    //--------------------------------------------------------------------------
    // Internal signals
    //--------------------------------------------------------------------------
    logic                               w__data_valid__next;
    logic                               r__data_valid__pff;
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // Output assignments
    //--------------------------------------------------------------------------
    assign o__data_in_ready         = (((r__data_valid__pff == 1'b0) || (i__data_out_ready == 1'b1)) && (reset == 1'b0));
    assign o__data_in_ready__next   = ((w__data_valid__next == 1'b0) && (reset == 1'b0));
    assign o__data_out_valid        = r__data_valid__pff;
    assign o__data_out              = r__buffer__pff[0];
    
    assign oa__all_data[0]          = r__buffer__pff[0];
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // Submodules
    //--------------------------------------------------------------------------
    clock_gater
        gate_update_clk (
            .clk                            (clk),
            .reset                          (reset),
            .i__enable                      (w__push),
            .o__gated_clk                   (w__wr_clk)
        );
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // Internal data valid state and push signal
    //--------------------------------------------------------------------------
    always_comb
    begin
        if(r__data_valid__pff == 1'b1)
        begin
            if((i__data_out_ready == 1'b1) || (i__clear_all == 1'b1))
            begin
                // Currently latched one is consumed and can store the incoming one if valid
                w__data_valid__next = i__data_in_valid;
                w__push             = i__data_in_valid;
            end
            else
            begin
                // Currently latched one is not yet consumed
                w__data_valid__next = 1'b1;
                w__push             = 1'b0;
            end
        end
        else
        begin
            // Currently no latched one and can store the incoming one if valid
            w__data_valid__next = i__data_in_valid;
            w__push             = i__data_in_valid;
        end
    end

    always_ff @ (posedge clk)
    begin
        if(reset == 1'b1)
        begin
            r__data_valid__pff <= 1'b0;
        end
        else
        begin
            r__data_valid__pff <= w__data_valid__next;
        end
    end
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // Internal buffer data
    //--------------------------------------------------------------------------
    always_ff @ (posedge w__wr_clk)
    begin
        r__buffer__pff[0] <= i__data_in;
        //$display ("ASK in fifo base  wrt w__wr_clk r__buffer__pff[0] = %b", r__buffer__pff[0]);
        //$display ("ASK in fifo base  wrt w__wr_clk i__data_in = %b", i__data_in);
    end
    //--------------------------------------------------------------------------
end
else
begin: depth_others

    //--------------------------------------------------------------------------
    // Internal signals
    //--------------------------------------------------------------------------
    logic                               w__pop;

    logic                               w__empty__next;
    logic                               r__empty__pff;
    logic                               w__full__next;
    logic                               r__full__pff;
    
    logic [ADDR_WIDTH-1:0]              w__wr_addr;
    logic [ADDR_WIDTH-1:0]              w__wr_addr_next;
    logic [ADDR_WIDTH-1:0]              w__rd_addr;
    logic [ADDR_WIDTH-1:0]              w__rd_addr_next;
    //--------------------------------------------------------------------------

    //--------------------------------------------------------------------------
    // Output assignments
    //--------------------------------------------------------------------------
    assign o__data_in_ready         = ~r__full__pff & (~reset);         // When reset, ready should be low
    assign o__data_in_ready__next   = ~w__full__next;
    assign o__data_out_valid        = ~r__empty__pff;                   // When reset, this _will_ be low
    assign o__data_out              = r__buffer__pff[w__rd_addr];
    
    always_comb
    begin
        for(int i = 0; i < DEPTH; i++)
        begin
            oa__all_data[i] = r__buffer__pff[i];
        end
    end
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    // Submodules
    //--------------------------------------------------------------------------
    counter
        #(
            .NUM_COUNT                      (DEPTH),
            .COUNT_WIDTH                    (ADDR_WIDTH)
        )
        m_write_addr (
            .clk                            (clk),
            .reset                          (reset | i__clear_all),
            .i__inc                         (w__push),
            .o__count                       (w__wr_addr),
            .o__count__next                 (w__wr_addr_next)
        );
    
    counter
        #(
            .NUM_COUNT                      (DEPTH),
            .COUNT_WIDTH                    (ADDR_WIDTH)
        )
        m_read_addr (
            .clk                            (clk),
            .reset                          (reset | i__clear_all),
            .i__inc                         (w__pop),
            .o__count                       (w__rd_addr),
            .o__count__next                 (w__rd_addr_next)
        );
    
    clock_gater
        gate_update_clk (
            .clk                            (clk),
            .reset                          (reset),
            .i__enable                      (w__push),
            .o__gated_clk                   (w__wr_clk)
        );
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    // Internal push and pop signals
    //--------------------------------------------------------------------------
    always_comb
    begin
        w__push = i__data_in_valid && o__data_in_ready;
        w__pop  = o__data_out_valid && i__data_out_ready;
    end
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    // Internal full and empty states
    //--------------------------------------------------------------------------
    always_comb
    begin
        w__empty__next = r__empty__pff;
        if(w__push == 1'b1)
        begin
            w__empty__next = 1'b0;
        end
        else if((w__pop == 1'b1) && (w__rd_addr_next == w__wr_addr))
        begin
            w__empty__next = 1'b1;
        end
    
        w__full__next = r__full__pff;
        if(w__pop == 1'b1)
        begin
            w__full__next = 1'b0;
        end
        else if((w__push == 1'b1) && (w__wr_addr_next == w__rd_addr))
        begin
            w__full__next = 1'b1;
        end
    end
    
    always_ff @ (posedge clk)
    begin
        if(reset == 1'b1)
        begin
            r__empty__pff   <= 1'b1;
            r__full__pff    <= 1'b0;
        end
        else
        begin
            r__empty__pff   <= w__empty__next;
            r__full__pff    <= w__full__next;
        end
    end
    //--------------------------------------------------------------------------
    
    //--------------------------------------------------------------------------
    // Internal buffer data
    //--------------------------------------------------------------------------
    always_ff @ (posedge w__wr_clk)
    begin
        r__buffer__pff[w__wr_addr] <= i__data_in;
    end
    //--------------------------------------------------------------------------
end
endgenerate

/*
always @ (posedge clk)
begin
    $display ("ASK In FIFO base i__data_in = %b", i__data_in);
    $display ("ASK In FIFO base o__data_out = %b", o__data_out);
    $display ("ASK In FIFO base oa__all_data[0] = %b", oa__all_data[0]);
end
*/
endmodule
