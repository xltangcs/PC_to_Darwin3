module fifo_tb( );

parameter DATA_WIDTH = 16;
parameter ADDR_DEPTH = 14;


reg                    rece_done   ;
reg                     clk       ;
reg                     rst_n      ;
reg  [DATA_WIDTH-1:0]   s_tdata    ;
reg  [DATA_WIDTH/8-1:0] s_tkeep    ;
reg                     s_tvalid   ;
wire                    s_tready   ;
reg                     s_tlast    ;

wire [DATA_WIDTH-1:0]   m_tdata    ;
wire [DATA_WIDTH/8-1:0] m_tkeep    ;
wire                    m_tvalid   ;
reg                     m_tready   ;
wire                    m_tlast    ;



always #10 clk = ~clk; 

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        s_tdata <= 0;
    else if(s_tvalid && s_tready)
        s_tdata <= s_tdata + 1; 
end

initial begin
    clk = 0;
    rst_n  = 0;
    s_tkeep = 2'b11;
    s_tvalid = 0;  
    m_tready = 0; 
    rece_done = 0;
    #20
    rst_n = 1;
    s_tvalid = 1;
    
    
    #160
    s_tvalid = 0;
    #20
    rece_done = 1;
    #20
    m_tready = 1;

end





axis_fifo #(
    .DATA_WIDTH (16),
    .ADDR_DEPTH (14)
) u_axis_fifo(
    .s_aclk     (clk     )    ,
    .s_areset_n (rst_n )    ,
    .s_tdata    (s_tdata    )    ,
    .s_tkeep    (s_tkeep    )    ,
    .s_tvalid   (s_tvalid   )    ,
    .s_tready   (s_tready   )    ,
    .s_tlast    (s_tlast    )    ,
    .m_aclk     (clk     )    ,
    .m_areset_n (rst_n )    ,
    .m_tdata    (m_tdata    )    ,
    .m_tkeep    (m_tkeep    )    ,
    .m_tvalid   (m_tvalid   )    ,
    .m_tready   (m_tready   )    ,
    .m_tlast    (m_tlast    )    ,
    .RECE_DONE  (rece_done)
    
);

endmodule
