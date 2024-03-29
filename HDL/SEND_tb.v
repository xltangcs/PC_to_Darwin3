`timescale 1ns / 1ps
module SEND_tb( );
    reg                     clk             ;
    reg                     rst_n           ;
    reg       [15:0]        S_AXIS_TDATA    ;
    reg                     S_AXIS_TVALID   ;
    reg       [1:0]         S_AXIS_TKEEP    ;
    reg                     S_AXIS_TLAST    ;
    reg                     TX_ACK_WEST     ;
    wire                    S_AXIS_TREADY   ;
    wire      [15:0]        TX_DATA_WEST    ;
    wire                    SEND_DONE       ;
    wire                    TX_REQ_WEST     ;
    reg                     TX_REQ_WEST1;
    reg                     TX_REQ_WEST2;
    reg                     enable;
    
    always #10 clk = ~clk;
    
    always @(posedge clk) begin 
        if(S_AXIS_TREADY && S_AXIS_TVALID && enable) begin
            S_AXIS_TDATA <= S_AXIS_TDATA + 16'd0001;
        end
    end
    
    always @(posedge clk) begin 
        if(!rst_n) begin
            TX_ACK_WEST <= 1'b0;
            TX_REQ_WEST1 <= 1'b0;
            TX_REQ_WEST2 <= 1'b0;
        end else begin
            TX_REQ_WEST1 <= TX_REQ_WEST;
            TX_REQ_WEST2 <= TX_REQ_WEST1;
            TX_ACK_WEST  <= TX_REQ_WEST2;
        end
    end
    
    initial begin
        clk  = 1'b0;
        rst_n = 1'b0;
        TX_ACK_WEST = 1'b0;
        S_AXIS_TLAST = 1'b0;
        S_AXIS_TVALID = 1'b0;
        
        #30
        rst_n = 1'b1;
        S_AXIS_TDATA = 16'd0001;
        S_AXIS_TVALID = 1'b1;
        #20
        
        enable = 1'b1;
        #1620
        S_AXIS_TLAST = 1'b1;
        #20
        enable = 1'b0;
        #170
        @(posedge clk) begin
        S_AXIS_TVALID =1'b0;
        
        end;


        #1000
        @(posedge clk) begin
            S_AXIS_TVALID = 1'b1;
            enable = 1'b1;
        end


        #2000

        $finish;
    end

    send u_SEND(
        .clk           (clk           )     ,
        .rst_n         (rst_n         )     ,
        .S_AXIS_TDATA  (S_AXIS_TDATA  )     ,
        .S_AXIS_TVALID (S_AXIS_TVALID )     ,
        .S_AXIS_TKEEP  (S_AXIS_TKEEP  )     ,
        .S_AXIS_TLAST  (S_AXIS_TLAST  )     ,
        .TX_ACK        (TX_ACK_WEST   )     ,    
        .S_AXIS_TREADY (S_AXIS_TREADY )     ,
        .TX_DATA       (TX_DATA_WEST  )     ,
        .TX_REQ        (TX_REQ_WEST   )     ,
        .SEND_DONE     (SEND_DONE       )
    );

endmodule
