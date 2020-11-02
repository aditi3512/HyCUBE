////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Project Name: HyCUBE (Verilog, SystemVerilog)                          ////
////                                                                        ////
//// Module Name: chip_with_pad                                             ////
////                                                                        ////
////                                                                        ////
////  This file is part of HyCUBE                                           ////
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

module chip_with_pad(
    reset_network_pad,
    sck_pad,
    ss_pad,
    sdin_pad,
    sdout_pad,
    scan_data_pad,
    scan_data_pad_out,
    scan_data_or_addr_pad,
    read_write_pad,
    data_out_valid_pad,
    data_addr_valid_pad,
    scan_start_exec_pad,
    exec_end_pad,
    chip_en_pad,
    bist_success_pad,
    spi_en_pad,
    bist_en_pad,
    vcoEn_pad,
    clkExtEn_pad,
    clkExt_pad,
    clkSel_pad,
    divSel_pad,
    fixdivSel_pad,
    dlIn0_pad,
    dlIn1_pad,
    dlIn2_pad,
    clkEn_pad,
    clkOut_Mon_pad,
    scan_chain_out_pad,
    scan_chain_in_pad,
    scan_chain_en_pad,
    scan_chain_sel_0_pad,
    scan_chain_sel_1_pad,
    scan_chain_sel_2_pad,
    scan_chain_sel_3_pad
);

input reset_network_pad;
input sck_pad;
input ss_pad;
input sdin_pad;
output sdout_pad;

input bist_en_pad;
output bist_success_pad;
input scan_start_exec_pad;
output exec_end_pad;
output data_out_valid_pad;
input [1:0] data_addr_valid_pad;
input chip_en_pad;
input [15:0] scan_data_pad;
output [15:0] scan_data_pad_out;
input scan_data_or_addr_pad;
input read_write_pad;
input spi_en_pad;

input [5:0] clkSel_pad;
input [3:0] divSel_pad;
input [1:0] fixdivSel_pad;
input vcoEn_pad;
input clkExtEn_pad;
input clkExt_pad;
input dlIn0_pad;
input dlIn1_pad;
input dlIn2_pad;
input clkEn_pad;
output clkOut_Mon_pad;

output  [3:0] scan_chain_out_pad;
input   scan_chain_in_pad;
input   scan_chain_en_pad;

input [1:0] scan_chain_sel_0_pad;
input [1:0] scan_chain_sel_1_pad;
input [1:0] scan_chain_sel_2_pad;
input [1:0] scan_chain_sel_3_pad;

//------------------Internal signals----------------------------


wire [1:0] data_addr_valid;       
wire [15:0] scan_data;             

wire [5:0] clkSel;
wire [3:0] divSel;
wire [1:0] fixdivSel;


wire [3:0] scan_chain_out;

wire [1:0] scan_chain_sel_0;
wire [1:0] scan_chain_sel_1;
wire [1:0] scan_chain_sel_2;
wire [1:0] scan_chain_sel_3;

//--------------------Submodules------------------------------------

chip chip_u1 (
        .reset_network (reset_network),
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
        .vcoEn (vcoEn),
        .clkExtEn (clkExtEn),
        .clkExt (clkExt),
        .clkSel (clkSel),
        .divSel (divSel),
        .fixdivSel (fixdivSel),
        .dlIn0 (dlIn0),
        .dlIn1 (dlIn1),
        .dlIn2 (dlIn2),
        .clkEn (clkEn),
        .clkOut_Mon (clkOut_Mon),
    	.scan_chain_out (scan_chain_out),
    	.scan_chain_in (scan_chain_in),
    	.scan_chain_en (scan_chain_en),
    	.scan_chain_sel_0 (scan_chain_sel_0),
    	.scan_chain_sel_1 (scan_chain_sel_1),
    	.scan_chain_sel_2 (scan_chain_sel_2),
    	.scan_chain_sel_3 (scan_chain_sel_3)
);


 PVDD3AC_G 
	reset_network_receiver(
	.AVDD (reset_network_pad), 
	.TACVDD (reset_network) 
	);


 PVDD3AC_G 
	sck_receiver(
	.AVDD (sck_pad), 
	.TACVDD (sck) 
	);


 PVDD3AC_G 
	ss_receiver(
	.AVDD (ss_pad), 
	.TACVDD (ss) 
	);


 PVDD3AC_G 
	sdin_receiver(
	.AVDD (sdin_pad), 
	.TACVDD (sdin) 
	);


 PVDD3AC_G 
	sdout_receiver(
	.AVDD (sdout), 
	.TACVDD (sdout_pad) 
	);



 PVDD3AC_G 
	scan_data_receiver_0_in(
	.AVDD (scan_data_pad[0]), 
	.TACVDD (scan_data[0]) 
	);

 PVDD3AC_G
        scan_data_receiver_0_out(
        .AVDD (scan_data[0]),
        .TACVDD (scan_data_pad_out[0])
        );

 PVDD3AC_G 
	scan_data_receiver_1_in(
	.AVDD (scan_data_pad[1]), 
	.TACVDD (scan_data[1]) 
	);

 PVDD3AC_G
        scan_data_receiver_1_out(
        .AVDD (scan_data[1]),
        .TACVDD (scan_data_pad_out[1])
        );

 PVDD3AC_G 
	scan_data_receiver_2_in(
	.AVDD (scan_data_pad[2]), 
	.TACVDD (scan_data[2]) 
	);

 PVDD3AC_G
        scan_data_receiver_2_out(
        .AVDD (scan_data[2]),
        .TACVDD (scan_data_pad_out[2])
        );

 PVDD3AC_G 
	scan_data_receiver_3_in(
	.AVDD (scan_data_pad[3]), 
	.TACVDD (scan_data[3]) 
	);

 PVDD3AC_G
        scan_data_receiver_3_out(
        .AVDD (scan_data[3]),
        .TACVDD (scan_data_pad_out[3])
        );

 PVDD3AC_G 
	scan_data_receiver_4_in(
	.AVDD (scan_data_pad[4]), 
	.TACVDD (scan_data[4]) 
	);

 PVDD3AC_G
        scan_data_receiver_4_out(
        .AVDD (scan_data[4]),
        .TACVDD (scan_data_pad_out[4])
        );

 PVDD3AC_G 
	scan_data_receiver_5_in(
	.AVDD (scan_data_pad[5]), 
	.TACVDD (scan_data[5]) 
	);

 PVDD3AC_G
        scan_data_receiver_5_out(
        .AVDD (scan_data[5]),
        .TACVDD (scan_data_pad_out[5])
        );

 PVDD3AC_G 
	scan_data_receiver_6_in(
	.AVDD (scan_data_pad[6]), 
	.TACVDD (scan_data[6]) 
	);

 PVDD3AC_G
        scan_data_receiver_6_out(
        .AVDD (scan_data[6]),
        .TACVDD (scan_data_pad_out[6])
        );

 PVDD3AC_G 
	scan_data_receiver_7_in(
	.AVDD (scan_data_pad[7]), 
	.TACVDD (scan_data[7]) 
	);

 PVDD3AC_G
        scan_data_receiver_7_out(
        .AVDD (scan_data[7]),
        .TACVDD (scan_data_pad_out[7])
        );

 PVDD3AC_G 
	scan_data_receiver_8_in(
	.AVDD (scan_data_pad[8]), 
	.TACVDD (scan_data[8]) 
	);

 PVDD3AC_G
        scan_data_receiver_8_out(
        .AVDD (scan_data[8]),
        .TACVDD (scan_data_pad_out[8])
        );

 PVDD3AC_G 
	scan_data_receiver_9_in(
	.AVDD (scan_data_pad[9]), 
	.TACVDD (scan_data[9])
	);

 PVDD3AC_G
        scan_data_receiver_9_out(
        .AVDD (scan_data[9]),
        .TACVDD (scan_data_pad_out[9])
        );

 PVDD3AC_G 
	scan_data_receiver_10(
	.AVDD (scan_data_pad[10]), 
	.TACVDD (scan_data[10]) 
	);

 PVDD3AC_G
        scan_data_receiver_10_out(
        .AVDD (scan_data[10]),
        .TACVDD (scan_data_pad_out[10])
        );

 PVDD3AC_G 
	scan_data_receiver_11_in(
	.AVDD (scan_data_pad[11]), 
	.TACVDD (scan_data[11]) 
	);

 PVDD3AC_G
        scan_data_receiver_11_out(
        .AVDD (scan_data[11]),
        .TACVDD (scan_data_pad_out[11])
        );

 PVDD3AC_G 
	scan_data_receiver_12_in(
	.AVDD (scan_data_pad[12]), 
	.TACVDD (scan_data[12]) 
	);

 PVDD3AC_G
        scan_data_receiver_12_out(
        .AVDD (scan_data[12]),
        .TACVDD (scan_data_pad_out[12])
        );

 PVDD3AC_G 
	scan_data_receiver_13_in(
	.AVDD (scan_data_pad[13]), 
	.TACVDD (scan_data[13]) 
	);

 PVDD3AC_G
        scan_data_receiver_13_out(
        .AVDD (scan_data[13]),
        .TACVDD (scan_data_pad_out[13])
        );

 PVDD3AC_G 
	scan_data_receiver_14_in(
	.AVDD (scan_data_pad[14]), 
	.TACVDD (scan_data[14]) 
	);

 PVDD3AC_G
        scan_data_receiver_14_out(
        .AVDD (scan_data[14]),
        .TACVDD (scan_data_pad_out[14])
        );

 PVDD3AC_G 
	scan_data_receiver_15_in(
	.AVDD (scan_data_pad[15]), 
	.TACVDD (scan_data[15]) 
	);

 PVDD3AC_G
        scan_data_receiver_15_out(
        .AVDD (scan_data[15]),
        .TACVDD (scan_data_pad_out[15])
        );

 PVDD3AC_G 
	scan_data_or_addr_receiver(
	.AVDD (scan_data_or_addr_pad), 
	.TACVDD (scan_data_or_addr) 
	);


 PVDD3AC_G 
	read_write_receiver(
	.AVDD (read_write_pad), 
	.TACVDD (read_write) 
	);


 PVDD3AC_G 
	data_out_valid_receiver(
	.AVDD (data_out_valid), 
	.TACVDD (data_out_valid_pad) 
	);


 PVDD3AC_G 
	data_addr_valid_receiver_0(
	.AVDD (data_addr_valid_pad[0]), 
	.TACVDD (data_addr_valid[0]) 
	);


 PVDD3AC_G 
	data_addr_valid_receiver_1(
	.AVDD (data_addr_valid_pad[1]), 
	.TACVDD (data_addr_valid[1]) 
	);


 PVDD3AC_G 
	scan_start_exec_receiver(
	.AVDD (scan_start_exec_pad), 
	.TACVDD (scan_start_exec) 
	);


 PVDD3AC_G 
	exec_end_receiver(
	.AVDD (exec_end), 
	.TACVDD (exec_end_pad) 
	);


 PVDD3AC_G 
	chip_en_receiver(
	.AVDD (chip_en_pad), 
	.TACVDD (chip_en) 
	);


 PVDD3AC_G 
	spi_en_receiver(
	.AVDD (spi_en_pad), 
	.TACVDD (spi_en) 
	);


 PVDD3AC_G 
	bist_success_receiver(
	.AVDD (bist_success), 
	.TACVDD (bist_success_out) 
	);


 PVDD3AC_G 
	bist_en_receiver(
	.AVDD (bist_en_pad), 
	.TACVDD (bist_en) 
	);


 PVDD3AC_G 
	vcoEn_receiver(
	.AVDD (vcoEn_pad), 
	.TACVDD (vcoEn) 
	);


 PVDD3AC_G 
	clkExtEn_receiver(
	.AVDD (clkExtEn_pad), 
	.TACVDD (clkExtEn) 
	);


 PVDD3AC_G 
	clkExt_receiver(
	.AVDD (clkExt_pad), 
	.TACVDD (clkExt)
	);



 PVDD3AC_G 
	clkSel_receiver_0(
	.AVDD (clkSel_pad[0]), 
	.TACVDD (clkSel[0]) 
	);



 PVDD3AC_G 
	clkSel_receiver_1(
	.AVDD (clkSel_pad[1]), 
	.TACVDD (clkSel[1]) 
	);



 PVDD3AC_G 
	clkSel_receiver_2(
	.AVDD (clkSel_pad[2]), 
	.TACVDD (clkSel[2]) 
	);



 PVDD3AC_G 
	clkSel_receiver_3(
	.AVDD (clkSel_pad[3]), 
	.TACVDD (clkSel[3]) 
	);



 PVDD3AC_G 
	clkSel_receiver_4(
	.AVDD (clkSel_pad[4]), 
	.TACVDD (clkSel[4]) 
	);



 PVDD3AC_G 
	clkSel_receiveri_5(
	.AVDD (clkSel_pad[5]), 
	.TACVDD (clkSel[5]) 
	);



 PVDD3AC_G 
	divSel_receiver_0(
	.AVDD (divSel_pad[0]), 
	.TACVDD (divSel[0]) 
	);



 PVDD3AC_G 
	divSel_receiver_1(
	.AVDD (divSel_pad[1]), 
	.TACVDD (divSel[1]) 
	);



 PVDD3AC_G 
	divSel_receiver_2(
	.AVDD (divSel_pad[2]), 
	.TACVDD (divSel[2]) 
	);



 PVDD3AC_G 
	divSel_receiver_3(
	.AVDD (divSel_pad[3]), 
	.TACVDD (divSel[3]) 
	);



 PVDD3AC_G 
	fixdivSel_receiver_0(
	.AVDD (fixdivSel_pad[0]), 
	.TACVDD (fixdivSel[0]) 
	);


 PVDD3AC_G 
	fixdivSel_receiver_1(
	.AVDD (fixdivSel_pad[1]), 
	.TACVDD (fixdivSel[1]) 
	);


 PVDD3AC_G 
	dlIn0_receiver(
	.AVDD (dlIn0_pad), 
	.TACVDD (dlIn0) 
	);


 PVDD3AC_G 
	dlIn1_receiver(
	.AVDD (dlIn1_pad), 
	.TACVDD (dlIn1) 
	);


 PVDD3AC_G 
	dlIn2_receiver(
	.AVDD (dlIn2_pad), 
	.TACVDD (dlIn2) 
	);


 PVDD3AC_G 
	clkEn_receiver(
	.AVDD (clkEn_pad), 
	.TACVDD (clkEn) 
	);


 PVDD3AC_G 
	clkOut_Mon_receiver(
	.AVDD (clkOut_Mon), 
	.TACVDD (clkOut_Mon_pad) 
	);



 PVDD3AC_G 
	scan_chain_out_0_receiver(
	.AVDD (scan_chain_out[0]), 
	.TACVDD (scan_chain_out_pad[0]) 
	);


 PVDD3AC_G 
	scan_chain_out_1_receiver(
	.AVDD (scan_chain_out[1]), 
	.TACVDD (scan_chain_out_pad[1]) 
	);



 PVDD3AC_G 
	scan_chain_out_2_receiver(
	.AVDD (scan_chain_out[2]), 
	.TACVDD (scan_chain_out_pad[2]) 
	);


 PVDD3AC_G 
	scan_chain_out_3_receiver(
	.AVDD (scan_chain_out[3]), 
	.TACVDD (scan_chain_out_pad[3]) 
	);

 PVDD3AC_G 
	scan_chain_in_receiver(
	.AVDD (scan_chain_in_pad), 
	.TACVDD (scan_chain_in) 
	);

 PVDD3AC_G 
	scan_chain_en_receiver(
	.AVDD (scan_chain_en_pad), 
	.TACVDD (scan_chain_en)
	);


 PVDD3AC_G 
	scan_chain_sel_0_0_receiver(
	.AVDD (scan_chain_sel_0_pad[0]), 
	.TACVDD (scan_chain_sel_0[0]) 
	);

 PVDD3AC_G 
	scan_chain_sel_0_1_receiver(
	.AVDD (scan_chain_sel_0_pad[1]), 
	.TACVDD (scan_chain_sel_0[1]) 
	);



 PVDD3AC_G 
	scan_chain_sel_1_0_receiver(
	.AVDD (scan_chain_sel_1_pad[0]), 
	.TACVDD (scan_chain_sel_1[0]) 
	);

 PVDD3AC_G 
	scan_chain_sel_1_1_receiver(
	.AVDD (scan_chain_sel_1_pad[1]), 
	.TACVDD (scan_chain_sel_1[1]) 
	);



 PVDD3AC_G 
	scan_chain_sel_2_0_receiver(
	.AVDD (scan_chain_sel_2_pad[0]), 
	.TACVDD (scan_chain_sel_2[0]) 
	);

 PVDD3AC_G 
	scan_chain_sel_2_1_receiver(
	.AVDD (scan_chain_sel_2_pad[1]), 
	.TACVDD (scan_chain_sel_2[1]) 
	);


 PVDD3AC_G 
	scan_chain_sel_3_0_receiver(
	.AVDD (scan_chain_sel_3_pad[0]), 
	.TACVDD (scan_chain_sel_3[0]) 
	);

 PVDD3AC_G 
	scan_chain_sel_3_1_receiver(
	.AVDD (scan_chain_sel_3_pad[1]), 
	.TACVDD (scan_chain_sel_3[1]) 
	);


endmodule

