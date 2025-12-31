module BinarySMToTwosComp #(parameter N = 8)(
    input [N-1:0] A,  // Sign-magnitude input
    output [N-1:0] B  // Two's complement output
);

    wire sign = A[N-1];        // Sign bit
    wire [N-2:0] magnitude = A[N-2:0];

    wire [N-2:0] twos_comp_mag = ~magnitude + 1'b1;

    assign B = sign ? {1'b1, twos_comp_mag} : A;  // MSB = 1 if negative

endmodule
