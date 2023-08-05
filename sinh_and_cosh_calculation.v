module float_add(a,b,s);//single precision floating point adder
input [31:0] a,b;
output reg [31:0] s;

reg as,bs,ss;
reg [7:0] ae,be,se;
reg [23:0] am,bm,sm;
reg carry;
integer i;
always @ (*) begin
am={1'b1,a[22:0]};
bm={1'b1,b[22:0]};
ae=a[30:23];
be=b[30:23];
as=a[31];
bs=b[31];

if(ae<be) begin
am=am>>(be-ae);
se=be;
end 
else if(be<ae) begin
bm=bm>>(ae-be);
se=ae;
end
else se=ae;

if(as==bs) 
begin 
    {carry,sm}=am+bm;
    ss=as;
    if(carry)
    begin
    se=se+1;
    s={ss,se,sm[23:1]};
    end 
    else begin
    s={ss,se,sm[22:0]};
    end
end 
else if(am>bm) 
begin
    sm=am-bm;
    ss=as;
    i=23;
    while(i>0 && sm[i]==0)
    begin
    i=i-1;
    end
    se=se-(23-i);
    sm=sm<<(24-i);
    s={ss,se,sm[23:1]};
end 
else 
begin
    sm=bm-am;
    ss=bs;
    i=23;
        while(i>0 && sm[i]==0)
        begin
        i=i-1;
        end
    se=se-(23-i);
    sm=sm<<(24-i);
    s={ss,se,sm[23:1]};
end
    
end
endmodule

module float_div(a,b,s);//single precision floating point divider
input [31:0] a,b;
output reg [31:0] s;
reg as,bs,ss;
reg [7:0] ae,be,se;
reg [23:0] am,sm;
reg [47:0] bm;
always @ * begin
am={1'b1,a[22:0]};
bm={1'b1,b[22:0],23'd0};
ae=a[30:23];
be=b[30:23];
as=a[31];
bs=b[31];
ss=as^bs;
sm=bm/am;
se=be-ae+8'd127;
if(sm[30]==0) begin
sm=sm>>1;
se=se+1;
end else begin
sm=sm;
se=se;
end
s={ss,se,sm[22:0]};
end
endmodule

module multiplyx (input s,input[31:0]a,output reg [31:0]A);//modules for finding sign
always@(*) begin
if(s==0) begin 
A=a;
end
else begin
A[31]=1;
A[30:0]=a[30:0];
end
end
endmodule

module multiplyy (input s,input[31:0]a,output reg [31:0]A);//modules for finding sign
always@(*) begin
if(s==1) begin 
A=a;
end
else begin
A[31]=1;
A[30:0]=a[30:0];
end
end
endmodule

module cordic_sin_cos(zin, sinho, cosho, tanho);
input [31:0] zin;
output [31:0]sinho, cosho, tanho;

output [31:0] yy1;
wire [31:0] X1[0:9];
wire [31:0] Y1[0:9];
wire [31:0] Z1[0:9];
wire [31:0] xin=32'b00111111100000000000000000000000;
wire [31:0] yin=32'b00000000000000000000000000000000;
wire [31:0] xt,yt,zt,X,Y,Z,ZZ;
wire [31:0]  zc[0:9];
wire [31:0] xc[0:9];
wire [31:0] yc[0:9];
wire [31:0] w1[0:9];
wire [31:0] w2[0:9];
wire [31:0] w3,w4;
assign xc[1]=xin;
assign yc[1]=yin;
assign zc[1]= zin;
assign xc[2]=xin;
assign yc[2]= 32'b00111111000000000000000000000000;

float_add f10({1'b0,zin[30:0]},{1'b1,atan_table[00][30:0]},zc[2]);

wire signed [31:0] atan_table [0:9];

   assign atan_table[00] = 32'b00111111000011001001111101010100; // 26.565 degrees -> atan(2^-1)
   assign atan_table[01] = 32'b00111110100000101100010101111000; // 14.036 degrees -> atan(2^-2)
   assign atan_table[02] = 32'b00111110000000001010110001001001; // atan(2^-3)
   assign atan_table[03] = 32'b00111101100000000010101011000100;  // 2^-4
   assign atan_table[04] = 32'b00111101000000000000101010101100;  //2^-5
   assign atan_table[05] = 32'b00111100100000000000001010101011; //2^-6
   assign atan_table[06] = 32'b00111100000000000000000010101011; //2^-7
   assign atan_table[07] = 32'b00111011100000000000000000101011; //2^-8
   assign atan_table[08] = 32'b00111011000000000000000000001011;//2^-9
//   assign atan_table[10] = 32'b00111101011001010010111011011100;  //10
//   assign atan_table[11] = 32'b00111100111001010010111011011110;   //11
//   assign atan_table[12] = 32'b00111100011001010010111011100100;   //12

genvar i;
generate
for(i=3;i<=13;i=i+1) begin:XYZ
    if(i==4) begin
    assign w3={yc[i-1][31],yc[i-1][30:23]-(i-1),yc[i-1][22:0]};
    assign w4={xc[i-1][31],xc[i-1][30:23]-(i-1),xc[i-1][22:0]};
    multiplyx m4(zc[i-1][31],w4,X);
    multiplyx m5(zc[i-1][31],w3,Y);
    multiplyy m6(zc[i-1][31],atan_table[i-2],Z);
    float_add f1(xc[i-1],Y,xt); 
    float_add f2(yc[i-1],X,yt);
    float_add f3(zc[i-1],Z,zt);
    
    assign w1[i-1]={yt[31],yt[30:23]-(i-1),yt[22:0]};
    assign w2[i-1]={xt[31],xt[30:23]-(i-1),xt[22:0]};
    multiplyx m1(zt[31],w2[i-1],X1[i]);
    multiplyx m2(zt[31],w1[i-1],Y1[i]);
    multiplyy m3(zt[31],atan_table[i-2],Z1[i]);
    float_add f4(xt,Y1[i],xc[i]); 
    float_add f5(yt,X1[i],yc[i]);
    float_add f6(zt,Z1[i],zc[i]);
    end
    
    else begin
    assign w1[i-1]={yc[i-1][31],yc[i-1][30:23]-(i-1),yc[i-1][22:0]};
    assign w2[i-1]={xc[i-1][31],xc[i-1][30:23]-(i-1),xc[i-1][22:0]};
    multiplyx m1(zc[i-1][31],w2[i-1],X1[i]);
    multiplyx m2(zc[i-1][31],w1[i-1],Y1[i]);
    multiplyy m3(zc[i-1][31],atan_table[i-2],Z1[i]);
    float_add f7(xc[i-1],Y1[i],xc[i]); 
    float_add f8(yc[i-1],X1[i],yc[i]);
    float_add f9(zc[i-1],Z1[i],zc[i]);
    end
    end
endgenerate

assign sinho={zin[31],yc9[30:0]};
assign cosho=xc[9];
float_div ff(cosho,sinho,tanho);
endmodule
