module TX(
    input                   clk                 ,
    input                   rst_n               ,
    input       [15:0]      S_AXIS_TDATA        ,
    input                   S_AXIS_TVALID       ,
    input       [1:0]       S_AXIS_TKEEP        ,
    input                   S_AXIS_TLAST        ,
    input                   TX_ACK              ,    
    output                  S_AXIS_TREADY       ,
    output      [15:0]      TX_DATA             ,
    output                  TX_REQ              ,
    output                  TX_DONE
    );
/******************** define signal *******************/    
    reg     [15:0]      tx_data     ; 
    reg                 tx_req      ; 
    reg                 tx_ack_delay1 ;
    reg                 tx_ack_delay2 ;
    wire                tx_ack_edge   ;  
    reg                 tx_done;  
    
    reg                 s_axis_tready;  
    wire                tx_en; 
/***********************状态机***************************/   
    parameter [1:0]     IDLE            = 2'b01, 
                        SEND            = 2'b10;
    reg     [1:0]       mst_exec_state;    
/********************** assign *************************/ 
    assign      S_AXIS_TREADY       =   s_axis_tready;  
    assign      TX_DATA             =   tx_data     ;   
    assign      TX_REQ              =   tx_req     ;
    assign      tx_en               =   S_AXIS_TVALID && S_AXIS_TREADY;
    assign      TX_DONE             =   tx_done;
/********************** delay *************************/ 
    always @(posedge clk) begin
        if(!rst_n) begin
            tx_ack_delay1  <= 1'b0;
            tx_ack_delay2  <= 1'b0;
        end 
        else begin
            tx_ack_delay1  <= TX_ACK     ;
            tx_ack_delay2  <= tx_ack_delay1;
        end
      end 
/********************** edge detection********************** **/ 
    edge_detection tx_ack_edge_detection(
        .clk        (clk      ),
        .rst_n      (rst_n    ),
        .data       (tx_ack_delay1),
        .pos_edge   ( ),    //上升沿
        .neg_edge   ( ),    //下降沿  
        .data_edge  (tx_ack_edge)     //数据边沿
    );
/********************** always ****************************/
    always @(posedge clk)
    begin  
        if (!rst_n) 
	        begin
	            mst_exec_state <= IDLE;
	        end  
	    else
	        case (mst_exec_state)
	        IDLE: 
	            if (S_AXIS_TVALID)
	            begin
	                mst_exec_state <= SEND;
	            end
	            else
	            begin
	                mst_exec_state <= IDLE;
	            end
	        SEND: 
	            if (tx_done)
	            begin
	                mst_exec_state <= IDLE;
	            end
	            else
	            begin
	                mst_exec_state <= SEND;
	            end
	        endcase
	end

    always @( posedge clk )
    begin
        if (tx_en)
        begin
            tx_data <= S_AXIS_TDATA;
        end  
    end 

    always @( posedge clk )
    begin
        if (!rst_n)
        begin
            tx_req <= 1'b0;
        end
        else if (tx_en) begin
            tx_req <= ~tx_req     ;
        end
        else begin 
            tx_req <= tx_req     ;
        end  
    end

    always @( posedge clk )
    begin
        if (!rst_n)
        begin
            s_axis_tready <= 1'b1;
        end
        else if (tx_ack_edge && (mst_exec_state == SEND)) begin
            s_axis_tready <= 1'b1;
        end
        else if(S_AXIS_TVALID) begin
            s_axis_tready <= 1'b0;
        end  
    end   

    always @( posedge clk )
    begin
        if (!rst_n)
        begin
            tx_done <= 1'b0;
        end
        else if ( ~S_AXIS_TVALID && tx_ack_edge) begin
            tx_done <= 1'b1;
        end
    end 


/* always 模板
    always @( posedge clk )
    begin
        if (!rst_n)
        begin
            
        end
        else if ( ) begin
            
        end
        else begin
            
        end  
    end   
*/
endmodule   