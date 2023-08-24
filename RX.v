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
    output     [31:0]       RX_COUNT              
    );

/******************** define signal *******************/    
    reg                 rx_ack; 
    reg                 rx_req_delay1 ;
    reg                 rx_req_delay2 ;

    wire    [1:0]       m_axis_tkeep; 
    reg  	            m_axis_tvalid;
	reg   	            m_axis_tlast;

	wire  				rx_en;
	reg  				rx_done;

    reg     [7:0]       done_count; 
    reg     [31:0]      rx_count; 
    
    wire                rx_req_edge;
    reg                 rx_req_edge_flag;
/***********************״̬��***************************/   
    parameter [1:0]     IDLE            = 2'b01, 
                         RECEIVE         = 2'b10;
    reg     [1:0]       mst_exec_state;    

/********************** assign *************************/ 
    assign      M_AXIS_TDATA        =   rx_en ? RX_DATA : M_AXIS_TDATA;
    assign      M_AXIS_TVALID       =   m_axis_tvalid;
    assign      M_AXIS_TLAST        =   1'b0;
    assign      M_AXIS_TKEEP        =   m_axis_tkeep; 
	assign 		m_axis_tkeep		=	2'b11;  
    assign      RX_DONE             =   rx_done;
    assign      RX_COUNT            =   rx_count;
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
        .pos_edge   ( ),    //������
        .neg_edge   ( ),    //�½���  
        .data_edge  (rx_req_edge)     //���ݱ���
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
	                mst_exec_state <= RECEIVE;
	            end
	            else
	            begin
	                mst_exec_state <= IDLE;
	            end
	        RECEIVE: 
	            if (rx_done)
	            begin
	                mst_exec_state <= IDLE;
	            end
	            else
	            begin
	                mst_exec_state <= RECEIVE;
	            end
	        endcase
	end

    always @( posedge clk )
    begin
        if (!rst_n)
        begin
            m_axis_tvalid <= 1'b0;
        end
        else if (rx_req_edge) begin
            m_axis_tvalid <= 1'b1;
        end
        else if (M_AXIS_TREADY)begin
            m_axis_tvalid <= 1'b0;
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
        else if (mst_exec_state == RECEIVE && done_count == 8'd100) begin
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
            rx_count <= 32'b0;
        end
        else if (rx_en) begin
            rx_count <= rx_count + 1'b1;
        end
        else if(mst_exec_state == IDLE && rx_req_edge)begin
            rx_count <= 32'b0;
        end  
    end  


    /* always ģ��
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