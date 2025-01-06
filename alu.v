module true_complement(input b, input s1, input s0, output wire B);
  assign B = (s0 & b) | (s1 & ~b);
endmodule

module fulladder(input a, input b, input cin, output wire sum, input s2, output wire cout);
  assign sum = a ^ b ^ cin;
  assign cout = ((a & b) | (b & cin) | (a & cin)) & ~s2;
endmodule

module arithmatic_and_logical_conversion_unit(
  input a, 
  input b, 
  input s2, 
  input s1, 
  input s0, 
  output wire x, 
  output wire y
);
  wire temp_y;
  assign x = (a) | (b & s2 & ~s1 & ~s0) | (~b & s2 & s1 & ~s0);
  true_complement tc (.b(b), .s1(s1), .s0(s0), .B(temp_y));
  assign y = temp_y;
endmodule

module four_to_one_multiplexer(input a, input b, input c, input d, input sel0, input sel1, output mux_out);
  assign mux_out = (a & ~sel0 & ~sel1) | (b & sel0 & ~sel1) | (c & ~sel0 & sel1) | (d & sel0 & sel1);
endmodule

module shifter(input [63:0] xin, input carry, input s0, input s1, output [64:0] yout);
  wire [64:0] temp_shift = {carry, xin};
  genvar i;
  generate
    for (i = 0; i < 65; i = i + 1) begin : shifter_logic
      four_to_one_multiplexer fm(
        .a(temp_shift[i]),                            
        .b(temp_shift[(i+64)%65]),       
        .c(temp_shift[(i+1)%65]),       
        .d(1'b0),                                      
        .sel0(s0),
        .sel1(s1),
        .mux_out(yout[i])
      );
    end
  endgenerate
endmodule

module alu(
  input [63:0] a,
  input [63:0] b, 
  input s0, 
  input s1, 
  input s2, 
  input cin, 
  input sel0,
  input sel1,
  output [63:0] sum,
  output cout
);
  wire [63:0] x, y;
  wire [63:0] carry;
  wire [64:0] temp_sum;
  wire [63:0] temp_sum2;
  wire temp_carry;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : alu_logic
      wire temp_cin = (i == 0) ? cin : carry[i-1];
      arithmatic_and_logical_conversion_unit alcu (
        .a(a[i]), 
        .b(b[i]), 
        .s2(s2), 
        .s1(s1), 
        .s0(s0), 
        .x(x[i]), 
        .y(y[i])
      );
      fulladder fa (
        .a(x[i]), 
        .b(y[i]), 
        .cin((temp_cin & ~s2) ), 
        .sum(temp_sum2[i]), 
        .s2(s2),
        .cout(carry[i])
      );      
    end
  endgenerate
  assign temp_carry=carry[63];
  shifter sh(
    .xin(temp_sum2),
    .carry(temp_carry), 
    .s0(sel0),
    .s1(sel1),
    .yout(temp_sum)
  );
  assign sum = temp_sum[63:0];
  assign cout = temp_sum[64]; 
endmodule

