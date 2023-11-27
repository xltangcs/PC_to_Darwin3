module delay_3_clk(
    input   clk         ,
    input   rst_n       ,
    input   signal      ,
    output  signal_delay
);

reg                 signal_delay1 ;
reg                 signal_delay2 ;
reg                 signal_delay3 ;

always @(posedge clk) begin
    if(!rst_n) begin
        signal_delay1  <= 1'b0;
        signal_delay2  <= 1'b0;
        signal_delay3  <= 1'b0;
    end 
    else begin
        signal_delay1  <= signal     ;
        signal_delay2  <= signal_delay1;
        signal_delay3  <= signal_delay2;
    end
  end 

  assign signal_delay = signal_delay3;

endmodule