`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.08.2017 12:52:00
// Design Name: 
// Module Name: syn_fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module syn_fifo(clk_rd, clk_wr, chip_en, rst, we, re, data_in, data_out);

parameter DEPTH_P2 = 2; // depth = 2^ DEPTH_P2;
parameter WIDTH = 8;
parameter DEPTH = (1<<DEPTH_P2);

input clk_rd, clk_wr, rst;
input we, re;
input [WIDTH-1:0] data_in;
input chip_en;

output [WIDTH-1:0] data_out;

/*----------------------------------*/

reg empty, full;
wire [WIDTH-1:0] data_out;
// reg [DEPTH_P2:0]depth;

wire clk_rd, clk_wr, rst, we, re;
wire [WIDTH-1:0] data_in;
// reg reload;
/*----------------------------------*/

reg [DEPTH_P2:0] wr_ptr;
reg [DEPTH_P2:0] rd_ptr;
wire [DEPTH_P2:0] wr_ptr_pl;
wire [DEPTH_P2:0] rd_ptr_pl;
reg [DEPTH_P2:0] wp_s;
reg [DEPTH_P2:0] rp_s;

/*----------------------------------*/

reg [WIDTH-1:0]regfile[DEPTH-1:0];

/*----------------------------------*/


always @ (posedge clk_wr ) begin
    if (rst==1'b1) begin
        wr_ptr <= 0;
    end 
    else if (chip_en) begin
        if (we & ~full) begin
            regfile[wr_ptr[DEPTH_P2-1 :0]] <= data_in;
            wr_ptr <= wr_ptr_pl;
        end
    end
end

assign wr_ptr_pl = wr_ptr + 1'b1;
                        
always @ (posedge clk_rd or posedge rst) begin
    if (rst==1'b1) begin
        rd_ptr <= 0;
        // data_out <= 8'b01010101;
    end 
    else if (chip_en) begin
        if (re & ~empty) begin
//            data_out <= regfile[rd_ptr[DEPTH_P2-1 :0]];
            rd_ptr <= rd_ptr_pl;
        end
        
        if (re) begin
            if(~empty) begin
                // data_out <= regfile[rd_ptr[DEPTH_P2-1 :0]];
            end
            else begin
                // data_out <= 8'b01010101;
            end
        end
        
    end                        
end  

assign rd_ptr_pl = rd_ptr + 1'b1;


/*----------------------------------*/
// Synchronization Logic
//

// write pointer
always @(posedge clk_rd)        wp_s <= wr_ptr;

// read pointer
always @(posedge clk_wr)        rp_s <= rd_ptr;

/*----------------------------------*/
// Registered Full & Empty Flags
//

always @(posedge clk_rd)
        empty <= (wp_s == rd_ptr) | (re & (wp_s == rd_ptr_pl));

always @(posedge clk_wr)
        full <= ((wr_ptr[DEPTH_P2-1:0] == rp_s[DEPTH_P2-1:0]) & (wr_ptr[DEPTH_P2] != rp_s[DEPTH_P2])) | (we & (wr_ptr_pl[DEPTH_P2-1:0] == rp_s[DEPTH_P2-1:0]) & (wr_ptr_pl[DEPTH_P2] != rp_s[DEPTH_P2]));




/*----------------------------------*/
assign data_out = (empty) ? 8'b01010101 : regfile[rd_ptr[DEPTH_P2-1 :0]];

endmodule
