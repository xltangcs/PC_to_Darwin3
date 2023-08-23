`timescale 1ns / 1ps
module rx_tb( );
reg                    clk                 ;
reg                    rst_n               ;
reg                    M_AXIS_TREADY       ;
reg        [15:0]      RX_DATA        ;
reg                    RX_REQ         ;

wire       [15:0]      M_AXIS_TDATA        ;
wire                   M_AXIS_TVALID       ;
wire       [1:0]       M_AXIS_TKEEP        ;
wire                   M_AXIS_TLAST        ;
wire                   RX_ACK         ;
wire                   RX_ACK_edge    ;
reg                    enable;

always #10 clk = ~clk;

initial begin
    clk  = 1'b0;
    rst_n = 1'b0;
    enable = 1'b1;
    #20
    rst_n = 1'b1;
    M_AXIS_TREADY <= 1'b1;
    RX_DATA <= 16'h1111;
    RX_REQ  <= 1'b1;
    #4000
    enable <= 1'b0;
    #6000
    $finish;                
end

always @(posedge clk) begin 
    if(!rst_n)
    begin
        RX_DATA <= 16'h0000;
        RX_REQ  <= 1'b0;
    end else if(RX_ACK_edge && enable)
    begin
        RX_DATA <= RX_DATA + 16'h1111;
        RX_REQ  <= ~RX_REQ;
    end
end


edge_detection RX_ACK_edge_detection(
    .clk        (clk      ),
    .rst_n      (rst_n    ),
    .data       (RX_ACK),
    .pos_edge   ( ),    //上升沿
    .neg_edge   ( ),    //下降沿  
    .data_edge  (RX_ACK_edge)     //数据边沿
);

RX u_rx(
    .clk             (clk            )    ,
    .rst_n           (rst_n          )    ,
    .M_AXIS_TREADY   (M_AXIS_TREADY  )    ,
    .RX_DATA         (RX_DATA  )    ,
    .RX_REQ          (RX_REQ    )    ,
    .M_AXIS_TDATA    (M_AXIS_TDATA   )    ,
    .M_AXIS_TVALID   (M_AXIS_TVALID  )    ,
    .M_AXIS_TKEEP    (M_AXIS_TKEEP   )    ,
    .M_AXIS_TLAST    (M_AXIS_TLAST   )    ,
    .RX_ACK          (RX_ACK    )       
    );



endmodule
