`timescale 1ps / 1ps
module tb ();
    reg [31:0] dataA;
    reg [31:0] dataB;
	reg clock;
    wire [31:0] result;

    fp_mult MyMultiplier(
        .dataA(dataA),
        .dataB(dataB),
		.clock(clock),
        .result(result)
    );

    always #1 clock = ~clock;
    task clock_cycle;
    input a;
    integer a;
    integer b;
    begin
        b=0;
        while(a!=b) begin
            @(posedge clock);
            b = b+1;
        end
    end
    endtask

    initial begin
	    clock = 1'b0;
        //when one data is 0
        dataA = 32'h00000000; //0
        dataB = 32'h41400000; //12
		clock_cycle(1);

        //when one is infinity
        dataA = 32'h7f800000; //infinity
        dataB = 32'h41400000;
        clock_cycle(1);

        //infinity * zero => 32'h7f800001
        dataA = 32'h7f800000; //infinity
        dataB = 32'h00000000; //0
        clock_cycle(1);

        //when there is a NaN
        dataA = 32'h7f800001; //NaN
        dataB = 32'h41400000;
        clock_cycle(1);

        //normal multiplication => 0x43080000
        dataA = 32'h41400000;
        dataB = 32'h41400000;
        clock_cycle(5);

        $stop;

    end

endmodule