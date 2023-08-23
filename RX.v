module RX(
    input                   clk                 ,
    input                   rst_n               ,
    input                   M_AXIS_TREADY       ,
    input       [15:0]      RX_DATA             ,
    input                   RX_REQ              ,
    
    output      [15:0]      M_AXIS_TDATA        ,
    output                  M_AXIS_TVALID       ,
    output      [1:0]       M_AXIS_TKEEP        ,
    output                  M_AXIS_TLAST        ,
    output                  RX_ACK              ,
    output                  RX_DONE             ,
    output      [31:0]      RX_COUNT              
    );

/******************** define signal *******************/    
    reg                 rx_ack; 
    reg                 rx_req_delay1 ;
    reg                 rx_req_delay2 ;

    wire                m_axis_tkeep; 
    reg  	            m_axis_tvalid;
	reg   	            m_axis_tlast;

	wire  				rx_en;
	reg  				rx_done;

    reg     [7:0]       done_count; 

    wire                rx_req_edge;
    reg                 rx_req_edge_flag;
/***********************状态机***************************/   
    parameter [1:0]     IDLE            = 2'b01, 
                        SEND            = 2'b10;
    reg     [1:0]       mst_exec_state;    

/********************** assign *************************/ 
    assign      M_AXIS_TDATA        =   rx_en ? RX_DATA : M_AXIS_TDATA;
    assign      M_AXIS_TVALID       =   m_axis_tvalid;
    assign      M_AXIS_TLAST        =   1'b0;
    assign      M_AXIS_TKEEP        =   m_axis_tkeep; 
	assign 		m_axis_tkeep		=	2'b11;  
    assign      RX_DONE             =   rx_done;

    assign      RX_ACK              =   rx_ack;  
	assign 		rx_en 				= 	M_AXIS_TREADY && M_AXIS_TVALID;                                                                     

/********************** delay *************************/ 
    always @(posedge clk) begin
        if(!rst_n) begin
            rx_req_delay1  <= 1'b0;
            rx_req_delay2  <= 1'b0;
        end 
        else begin
            rx_req_delay1  <= RX_REQ;
            rx_req_delay2  <= rx_req_delay1;
        end
      end     
/********************** edge detection ******************/ 
    edge_detection rx_req_west_edge_detection(
        .clk        (clk      ),
        .rst_n      (rst_n    ),
        .data       (rx_req_delay1),
        .pos_edge   ( ),    //上升沿
        .neg_edge   ( ),    //下降沿  
        .data_edge  (rx_req_edge)     //数据边沿
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
	            if (rx_req_edge)
	            begin
	                mst_exec_state <= SEND;
	            end
	            else
	            begin
	                mst_exec_state <= IDLE;
	            end
	        SEND: 
	            if (rx_done)
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
        if (!rst_n)
        begin
            rx_req_edge_flag <= 1'b0;
        end
        else if (rx_req_edge) begin
            rx_req_edge_flag <= 1'b1;
        end
        else if(rx_en) begin
            rx_req_edge_flag <= 1'b0;
        end
        else begin
            rx_req_edge_flag <= rx_req_edge_flag;
        end
    end

    always @( posedge clk )
    begin
        if (!rst_n)
        begin
            rx_ack <= 1'b0;
        end
        else if (rx_en) begin
            rx_ack <= ~rx_ack;
        end
        else begin
            rx_ack <= rx_ack;
        end  
    end

    always @( posedge clk )
    begin
        if (!rst_n)
        begin
            m_axis_tvalid <= 1'b0;
        end
        else if (~m_axis_tvalid && M_AXIS_TREADY && rx_req_edge_flag && (mst_exec_state == SEND)) begin
            m_axis_tvalid <= 1'b1;
        end
        else begin
            m_axis_tvalid <= 1'b0;
        end  
    end

    // always @( posedge clk )
    // begin
    //     if (!rst_n || rx_req_edge)
    //     begin
    //         m_axis_tlast <= 1'b0;
    //     end
    //     else if (~m_axis_tlast && done_count == 8'd100) begin
    //         m_axis_tlast <= 1'b1;
    //     end
    //     else begin
    //         m_axis_tlast <= 1'b0;
    //     end  
    // end   

    always @( posedge clk )
    begin
        if (!rst_n)
        begin
            done_count <= 1'b0;
        end
        else if (rx_en || rx_req_edge || rx_done) begin
            done_count <= 1'b0;
        end
        else begin
            done_count <= done_count + 1'b1;
        end  
    end

    always @( posedge clk )
    begin
        if (!rst_n)
        begin
            rx_done <= 1'b0;
        end
        else if (done_count == 8'd100) begin
            rx_done <= 1'b1;
        end
        else if (rx_req_edge) begin
            rx_done <= 1'b0;
        end  
        else begin
            rx_done <= rx_done;
        end
    end  

    always @( posedge clk )
    begin
        if (!rst_n)
        begin
            RX_COUNT <= 32'b0;
        end
        else if (rx_en) begin
            RX_COUNT <= RX_COUNT + 1'b1;
        end
        else if(mst_exec_state == IDLE)begin
            RX_COUNT <= 32'b0;
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