/*=================================================================================================================================================================================
   Design       : Dual-port Block RAM-based FIFO

   Description  : Fully synthesisable and configurable RAM-based FIFO.
                  - Data array infers Dual-port Block RAM on FPGA synthesisers.
                  - Configurable Data width.
                  - Configurable Depth.
                  - Empty signal de-assertion has one cycle latency. Full and Empty signal assertion has zero cycle latency.
                  
   Developer    : Mitu Raj, chip@chipmunklogic.com at Chipmunk Logic ™, https://chipmunklogic.com
   Date         : Feb-17-2021
=================================================================================================================================================================================*/

/*=================================================================================================================================================================================
                                                                                 R A M   F I F O
=================================================================================================================================================================================*/

module my_ram_fifo #(
                       parameter DATA_W           = 8           ,        // Data width
                       parameter DEPTH            = 8                    // Depth
                    )

                    (
                       /* Global */                    	
                       input                   clk              ,        // Clock
                       input                   rstn             ,        // Active-low Synchronous Reset                      

                       /* Enqueue side */                       
                       input                   i_wren           ,        // Write Enable
                       input  [DATA_W - 1 : 0] i_wrdata         ,        // Write-data                    
                       output                  o_full           ,        // Full signal
                       
                       /* Dequeue side */   
                       input                   i_rden           ,        // Read Enable
                       output [DATA_W - 1 : 0] o_rddata         ,        // Read-data                    
                       output                  o_empty                   // Empty signal
                    );


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Internal Registers / Signals
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
logic  [$clog2 (DEPTH) - 1 : 0] wrptr_rg        ;        // Write pointer
logic  [$clog2 (DEPTH) - 1 : 0] rdptr_rg        ;        // Read pointer
logic  [$clog2 (DEPTH) - 1 : 0] nxt_rdptr       ;        // Next Read pointer
logic  [$clog2 (DEPTH) - 1 : 0] rdaddr          ;        // Read-address to RAM
logic  
logic                           wren            ;        // Write Enable signal generated iff FIFO is not full
logic                           rden            ;        // Read Enable signal generated iff FIFO is not empty
logic                           full            ;        // Full signal
logic                           empty           ;        // Empty signal
logic                           empty_rg        ;        // Empty signal (registered)
logic                           state_rg        ;        // State
logic                           ex_rg           ;        // Exception


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Instantiation of RAM
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
ram #(

   .DATA_W       ( DATA_W )        ,
   .DEPTH        ( DEPTH  )

)

ram  (

   .clk          ( clk           ) ,          

   .i_wren       ( wren          ) ,
   .i_waddr      ( wrptr_rg      ) ,
   .i_wdata      ( i_wrdata      ) ,

   .i_raddr      ( rdaddr        ) ,
   .o_rdata      ( o_rddata      )

) ;


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Synchronous logic to write to and read from FIFO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
always @ (posedge clk) begin
   
   // Reset
   if (!rstn) begin      
      
      // Internal Registers           
      wrptr_rg  <= 0    ;
      rdptr_rg  <= 0    ; 
      state_rg  <= 1'b0 ;
      ex_rg     <= 1'b0 ;

   end
   
   // Out of reset
   else begin   
      
      
      /* FIFO write logic */            
      if (wren) begin         
         
         if (wrptr_rg == DEPTH - 1) begin
            wrptr_rg <= 0               ;        // Reset write pointer  
         end

         else begin
            wrptr_rg <= wrptr_rg + 1    ;        // Increment write pointer            
         end

      end

      /* FIFO read logic */
      if (rden) begin         

         if (rdptr_rg == DEPTH - 1) begin
            rdptr_rg <= 0               ;        // Reset read pointer
         end

         else begin
            rdptr_rg <= rdptr_rg + 1    ;        // Increment read pointer            
         end

      end
      
      // State where FIFO is emptied
      if (state_rg == 1'b0) begin

         ex_rg <= 1'b0 ;

         if (wren && !rden) begin
            state_rg <= 1'b1 ;                        
         end 
         else if (wren && rden && (rdaddr == wrptr_rg)) begin
            ex_rg    <= 1'b1 ;        // Exceptional case where same address is being read and written in FIFO ram
         end

      end
      
      // State where FIFO is filled up
      else begin
         if (!wren && rden) begin
            state_rg <= 1'b0 ;            
         end
      end

      // Empty signal registered
      empty_rg <= empty ;      

   end

end


/*---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   Continuous Assignments
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

// Full and Empty internal
assign full      = (wrptr_rg == rdptr_rg) && (state_rg == 1'b1)            ;
assign empty     = ((wrptr_rg == rdptr_rg) && (state_rg == 1'b0)) || ex_rg ;

// Write and Read Enables internal
assign wren      = i_wren & !full                                          ;  
assign rden      = i_rden & !empty & !empty_rg                             ;

// Full and Empty to output
assign o_full      = full                                                  ;
assign o_empty     = empty || empty_rg                                     ;

// Read-address to RAM
assign nxt_rdptr   = (rdptr_rg == DEPTH - 1) ? 'b0 : rdptr_rg + 1          ;
assign rdaddr      = rden ? nxt_rdptr : rdptr_rg                           ;
 

endmodule

/*=================================================================================================================================================================================
                                                                                 R A M   F I F O
=================================================================================================================================================================================*/
