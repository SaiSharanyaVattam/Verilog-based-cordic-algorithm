module testbench();
reg [31:0] zin;
wire [31:0]sino, coso;
cordic_sin_cos UUT(zin, sino, coso);
initial begin
zin=32'b00111111001100110011001100110011;#10//0.7
zin=32'b01000000000000000000000000000000;#10//45
zin=32'b01000010001101000000000000000000;//30
end
endmodule
