//lab 5
//Group 21(E/17/027,E/17/219)

//please execute "CPUTB.v" to test the CPU

//including the module libraries
`include "REG.v"
`include "ALU.v"
`include "CONTROLUNIT.v"
`include "COMPLEMENTER.v"
`include "MUX_8bits.v"
`include "MUX_32bits.v"
`include "PCADDER_32bits.v"

module cpu(PC, INSTRUCTION, CLK, RESET);

	input CLK,RESET;			//these are the inputs that gets the clock and reset
	input [31:0] INSTRUCTION;	//32bit instruction input from the instruction memory
	output reg [31:0] PC;		//programme counter as the output
	
	reg [31:0] PCPLUS4;			//holds the current pc value + 4 to store the next pc value(default) 
	wire [31:0] PCMUXRESULT;	//output from the mux which selects either default value or the no of instructions as the next pc value
	
	initial PCPLUS4=1'b0;		//initially pc+4 is set to 0
	
	always @ (posedge CLK)		//this always block handles the PC updating and new pc values generating in the corresponding time slots
	begin	
		if(RESET==1) begin		//if the reset is enable set pc to 0
			#1 PC =  0;
		end else begin			//otherwise set pc to the next pc value as the output of the mux
			#1 PC= PCMUXRESULT;
		end
	end
	
	reg [2:0] READREG1,READREG2,WRITEREG; //declaring buses for get the values for the registers from the instruction
	reg [7:0] OPCODE;					  //declaring the opcode register to store the opcode from the instruction
	reg [7:0] IMMRDIATE;  				  //declaring the immedaite register to get the immediate value form the instruction
	wire WRITEENABLE;					  //declaring a wire to indicate the instruction is writeenable or not
	reg [7:0] OFFSET;					  //declaring a reg to store the offset from the instruction
	
	always @ (INSTRUCTION)				   //in this always block the instruction is divided into the corresponding sections
	begin
		
		READREG1 = INSTRUCTION[10:8];		
		READREG2 = INSTRUCTION[2:0];
		WRITEREG = INSTRUCTION[18:16];
		OPCODE = INSTRUCTION[31:24];
		IMMRDIATE = INSTRUCTION[7:0];
		OFFSET = INSTRUCTION[23:16];		//getting bits from 16 to 23 as the number of insturctions
												
	end
	
	reg [31:0] ADDOPERAND;		//to store the ADDITION operand for the PC 
	
	always @(OFFSET)			//this always block produces the (pc + 4 * no of instrctions) as a 32 bit value 
	begin
	
		ADDOPERAND={{22{OFFSET[7]}},OFFSET,2'b00};
	
	end
	
	always @ (PC) #1 PCPLUS4 = PC + 4 ;	//this always block does the pc and 4 addition
	
	//====================================================================
	//following code piece will instatiate corresponding modules for the cpu
	//the nessary wires are delared to get the corresponding output from the each module

	wire [31:0] PCPLUSOFFSET;									//declaring a 32bit bus to store the output of the pc adder
	
	pcadder mypcadder(PCPLUS4,ADDOPERAND,INSTRUCTION,PCPLUSOFFSET);			//instatiating a 32 bit adder to get the addition to be updated for the pc

	wire SELECT3;												//to control the mux which outputs the next pc value
	
	pcmux mypcmux(PCPLUS4,PCPLUSOFFSET,SELECT3,PCMUXRESULT);	//instatiating the pc mux(if SELECT3=0 PCPLUSOFFSET else PCPLUS4)
	
	wire ZERO,BEQSIGNAL,ANDOUT;									//declaring corresponding values to get each outputs
	
	and(ANDOUT,ZERO,BEQSIGNAL);									//anding ZERO signal and BEQSIGNAL and assign the output to ANDOUT signal							
	
	wire JSIGNAL;												//declaring JSIGNAL 
	
	or(SELECT3,JSIGNAL,ANDOUT);									//oring JSIGNAL and ANDOUT ans assign that to SELECT3	
	
	wire [7:0] REGOUT1,REGOUT2,ALURESULT;						//to handle the registerfile
	
	//instatiating the registerfile
	reg_file myregfile(ALURESULT,REGOUT1,REGOUT2,WRITEREG,READREG1,READREG2, WRITEENABLE, CLK, RESET);
	
	wire [7:0] NEGATIVEVALUE;									//to the the output of the 2scomplement unit
	
	complementer my2scomplement(REGOUT2,NEGATIVEVALUE);			//instatiating the 2scomplement unit
	
	wire [7:0] MUX1OUT; 										//this will be the operand2 or -operand2
	wire SELECT1;												//this wire is coming from the control unit-if it is 0 then add if it is 1 then sub
	
	mux mymux1(REGOUT2,NEGATIVEVALUE,SELECT1,MUX1OUT);			//instatiating the first mux
	
	wire [7:0] MUX2OUT;											//this will be immedaite value or some form of operand 2
	wire SELECT2;												//this wire is coming from the control unit-if it is 0 then immedaite if it is 1 then operand2
	
	mux mymux2(IMMRDIATE,MUX1OUT,SELECT2,MUX2OUT);				//instatiating the second mux
	
	wire [2:0] ALUOP;											//this will be taken to decoding and to generate control signals
	
	alu myalu(REGOUT1, MUX2OUT, ALURESULT,ZERO, ALUOP);			//instatiating the alu 
	
	//intatiating the control unit
	controlunit myctrlunit(OPCODE,SELECT1,SELECT2,ALUOP,WRITEENABLE,BEQSIGNAL,JSIGNAL);
	
endmodule

