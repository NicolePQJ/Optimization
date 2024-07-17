module fp_mult(//single precision 32 bits
//inputs
input logic [31:0]    dataA,
input logic [31:0]    dataB,
input logic clock,

//outputs
output logic [31:0]   result
);

//internal signals
//1 bit for sign, 8 bits for exponent, 23 bits for mantissa
logic          sign_a; 
logic          sign_b;
logic          sign_result;
logic [7:0]    exp_a;
logic [7:0]    exp_b;
logic [8:0]    exp_result;
logic [8:0]    exp_result_final;
logic [23:0]   mantissa_a;//need to append the default 1 to front
logic [23:0]   mantissa_b;
logic [47:0]   mantissa_result;//max 48 bits
logic [22:0]   normalized_mantissa;

//extract components from input data
//sign bits
assign sign_a = dataA[31];
assign sign_b = dataB[31];
//exponent
assign exp_a = dataA[30:23];
assign exp_b = dataB[30:23];
//mantissa
assign mantissa_a = {1'b1, dataA[22:0]};
assign mantissa_b = {1'b1, dataB[22:0]};

//multiply mantissa
//after multiplication, binary point after bit 46
assign mantissa_result = mantissa_a * mantissa_b;

//add exponents and adjust for bias
assign exp_result = exp_a + exp_b - 8'd127;

//update sign bit
assign sign_result = sign_a ^ sign_b;

//first pipeline stage
logic          sign_result_1;
logic [7:0]    exp_a_1;
logic [7:0]    exp_b_1;
logic [31:0]   dataA_1;
logic [31:0]   dataB_1;

always_ff @(posedge clock) begin
    sign_result_1 <= sign_result;
    exp_a_1 <= exp_a;
    exp_b_1 <= exp_b;
    dataA_1 <= dataA;
    dataB_1 <= dataB;
end

//normalize mantissa (only need first 23 bits)
always_ff @(posedge clock) begin
    if (mantissa_result[47]) begin
        exp_result_final = exp_result + 1'b1;
        normalized_mantissa = mantissa_result[46:23];
    end
    else begin
        normalized_mantissa = mantissa_result[45:22];
        exp_result_final = exp_result;
    end
end

//check for overflow
assign overflow = exp_result_final[8];

//second pipeline stage
logic          sign_result_2;
logic [7:0]    exp_a_2;
logic [7:0]    exp_b_2;
logic [31:0]   dataA_2;
logic [31:0]   dataB_2;
logic          overflow_2;
logic [8:0]    exp_result_final_2;
logic [22:0]   normalized_mantissa_2;

always_ff @(posedge clock) begin
    sign_result_2 <= sign_result;
    exp_a_2 <= exp_a;
    exp_b_2 <= exp_b;
    dataA_2 <= dataA;
    dataB_2 <= dataB;
    overflow_2 <= overflow;
    exp_result_final_2 <= exp_result_final;
    normalized_mantissa_2 <= normalized_mantissa;
end
//handle edge cases (infinity, NaN, zero)
//NaN*anything = NaN
//Infinity * zero = NaN
//Infinity * Infinity = infinity
//zero * zero = 0
//when overflow = infinity
always@(posedge clock) begin
    //infinity or Nan
    if (exp_a_2==8'hff || exp_b_2==8'hff) begin
        //infinity if (a infinity && 0<b<=31'h7f000000), or vice versa, otherwise NaN
        if ((exp_a_2==8'hff && dataA_2[22:0]==0 && dataB_2>0 && dataB_2[30:0]<=31'h7f000000)
           ||(exp_b_2==8'hff && dataB_2[22:0]==0 && dataA_2>0 && dataA_2[30:0]<=31'h7f000000)) begin
            result = {sign_result_2, 8'hff, 23'b0};
           end
        else begin
            result = {sign_result_2, 8'hff, 23'b1};
        end
    end
    else if (dataA_2==32'b0 || dataB_2==32'b0) begin
        result = 32'b0;
    end
    else if (overflow) begin
        result = {sign_result_2, 8'hff, 23'b0};
    end
    else begin
        result = {sign_result_2, exp_result_final_2[7:0], normalized_mantissa_2};
    end
end


endmodule