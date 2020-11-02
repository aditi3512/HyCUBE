////////////////////////////////////////////////////////////////////////////////
////                                                                        ////
//// Project Name: HyCUBE (Verilog, SystemVerilog)                          ////
////                                                                        ////
//// Module Name: simple_alu                                                ////
////                                                                        ////
////                                                                        ////
////  This file is part of the HyCUBE project                               ////
////  https://github.com/aditi3512/HyCUBE                                   ////
////                                                                        ////
////  Author(s):                                                            ////
////      NUS.                                                              ////
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
module simple_alu(op_predicate, op_LHS, op_RHS, op_SHIFT, operation, result);

parameter width = 32;

input [32:0] op_RHS;
input [32:0] op_LHS;
input [32:0] op_SHIFT;
input [31:0] op_predicate;

input [5:0] operation;

output [31:0] result;

reg [31:0] result;

wire [32:0] op_2;
assign op_2 = (operation[5]) ? op_SHIFT : op_LHS;

always_comb
begin: alu
case(operation[4:0])
	5'b00000: result = {32{1'b0}};//nop
	5'b00001: result = (op_RHS[31:0] + op_2[31:0]); //add
	5'b00010: result = (op_RHS[31:0] - op_2[31:0]) ; //sub
	5'b00011: result = ($signed(op_RHS[31:0]) * $signed(op_2[31:0])) ; //mult
//	5'b00101: result = ($signed(op_RHS[31:0]) / $signed(op_2[31:0])); //div
	5'b01000: result = (op_RHS[31:0] << op_2[31:0]); // ls
	5'b01001: result = (op_RHS[31:0] >> op_2[31:0]); // rs
	5'b01010: result = (op_RHS[31:0] >>> op_2[31:0]); // ars
	5'b01011: result = (op_RHS[31:0] & op_2[31:0]); //bitwise and
	5'b01100: result = (op_RHS[31:0] | op_2[31:0]); //bitwise or
	5'b01101: result = (op_RHS[31:0] ^ op_2[31:0]); //bitwise xor
	5'b10000: begin
			if (operation[5]==1'b0) begin
				if (op_LHS[32] == 1'b1) 
					result = op_LHS[31:0]; //select
				else if (op_RHS[32] == 1'b1) 
					result = op_RHS[31:0]; //select
				else 
					result = {32{1'b0}};
			end
			else begin
				result = op_SHIFT[31:0];
			end
	end
	5'b10001: begin
			if (operation[5]==1'b0) 
				result = op_RHS[31:0]; //cmerge
			else
				result = op_SHIFT[31:0]; //cmerge
		end	
	5'b10010: result = {{31{1'b0}},(op_RHS[31:0] == op_2[31:0])}; //cmp
	5'b10011: result = {{31{1'b0}},($signed (op_RHS[31:0]) < $signed(op_2[31:0]))}; //clt
	5'b10100: result = (op_predicate[31:0] | op_RHS[31:0] | op_2[31:0]); //br
	5'b10101: result = {{31{1'b0}},($signed(op_2[31:0]) < $signed(op_RHS[31:0]))}; //cgt
	5'b11111: result = op_2[31:0]; //movc	
	default: result = {32{1'b0}};
endcase
end
/*
else begin
case(operation[4:0])
	5'b00000: result = {32{1'b0}}; //nop
//        5'b00001: result = (op_RHS[31:0] + op_SHIFT[31:0]); //add
//        5'b00010: result = (op_RHS[31:0] - op_SHIFT[31:0]) ; //sub
//        5'b00011: result = (op_RHS[31:0] * op_SHIFT[31:0]) ; //mult
//        5'b00101: result = (op_RHS[31:0] / op_SHIFT[31:0]); //div
        5'b01000: result = (op_RHS[31:0] << op_SHIFT[31:0]); // ls
        5'b01001: result = (op_RHS[31:0] >> op_SHIFT[31:0]); // rs
        5'b01010: result = (op_RHS[31:0] >>> op_SHIFT[31:0]); // ars
        5'b01011: result = (op_RHS[31:0] & op_SHIFT[31:0]); //bitwise and
        5'b01100: result = (op_RHS[31:0] | op_SHIFT[31:0]); //bitwise or
        5'b01101: result = (op_RHS[31:0] ^ op_SHIFT[31:0]); //bitwise xor
        5'b10000: begin 
//				if (op_SHIFT[32] == 1'b1) 
                       			result = op_SHIFT[31:0]; //select
				else if (op_RHS[32] == 1'b1) 
                        		result = op_RHS[31:0]; //select
				else 
				result = {32{1'b0}};

	end
	5'b10001: result = op_SHIFT[31:0]; //cmerge
        5'b10010: result = {{31{1'b0}},(op_RHS[31:0] == op_SHIFT[31:0])}; //cmp
	5'b10011: result = {{31{1'b0}},($signed(op_RHS[31:0]) < $signed(op_SHIFT[31:0]))}; //clt
        5'b10100: result = (op_predicate[31:0] | op_RHS[31:0] | op_SHIFT[31:0]); //br
	5'b10101: result = {{31{1'b0}},($signed(op_SHIFT[31:0]) < $signed(op_RHS[31:0]))}; //cgt
        5'b11111: result = op_SHIFT[31:0]; //movc        
        default: result = {32{1'b0}};
endcase
end
*/


endmodule
