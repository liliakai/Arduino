#include <EEPROM.h>
#include <SPI.h>

#define u8	unsigned char		// Unsigned 8bit memory type(0 to 255)
#define s8	char			// Signed 8bit memory type(-128 to 127)
#define u16	unsigned int		// Unsigned 16bit memory type(0 to 65,535)
#define s16	int			// Signed 16bit memory type(-32,768 to 32,767)
#define u24	unsigned short long*	// Unsigned 24bit memory type(0 to 16,777,215)
#define s24	short long*		// Signed 24bit memory type(-8,388,608 to 8,388,608)
#define u32     unsigned long*		// Unsigned 32bit memory type(0 to 4,294,967,295)
#define s32	long*			// Signed 32bit memory type(-2,147,483,648 to 2,147,483,648)
#define bool    unsigned char


//MCP3901 Reset Pin
#define RESET           LATBbits.LATB3 
#define DM              TRISBbits.TRISB3
// Chip Select
#define CS_mp3901	LATFbits.LATF1
#define DCS		TRISFbits.TRISF1
// Data Ready Pin
#define DR 		LATFbits.LATF6 
#define DDR		TRISFbits.TRISF6
// Modulator 0 Output Pin
#define MOD0 		LATDbits.LATD8 
#define DMOD0		TRISDbits.TRISD8
// Modulator 1 Output Pin
#define MOD1 		LATDbits.LATD9 
#define DMOD1		TRISDbits.TRISD9

//MCP3901 Internal Register Addresses
#define CHANNEL0 0x00
#define CHANNEL1 0x03
#define MOD 0x06
#define PHASE 0x07
#define GAIN 0x08
#define STATUSCOM 0x09
#define CONFIG 0x0A
#define CONFIGL 0x0B
#define CONFIGH 0x0A

//COMMAND BYTES FOR MCP3901
#define CHANNEL0_R 	0b00000001 // Channel 0 Register (0x00), Read
#define CHANNEL1_R 	0b00000111 // Channel 1 Register (0x03), Read
#define MOD_R 		0b00001101 // Modulators Register (0x06), Read
#define PHASE_W 	0b00001110 // Phase Register (0x07), Write
#define PHASE_R 	0b00001111 // Phase Register (0x07), Read
#define GAIN_W 		0b00010000 // Gain Register (0x08), Write
#define GAIN_R 		0b00010001 // Gain Register (0x08), Read
#define STATUSCOM_W	0b00010010 // Status_Com Register (0x09), Write
#define STATUSCOM_R	0b00010011 // Status_Com Register (0x09), Read
#define CONFIG_W	0b00010100 // Config Register (0x0A), Write
#define CONFIG_R	0b00010101 // Config Register (0x0A), Read

//MCP3901 Bits
//Gain
#define CH1_PGA2	7
#define CH1_PGA1	6
#define CH1_PGA0	5
#define BOOST_CH1	4
#define BOOST_CH0	3
#define CH0_PGA2	2
#define CH0_PGA1	1
#define CH0_PGA0	0
//ConfigH
#define PRE1		7
#define PRE0		6
#define OSR1		5
#define OSR0		4
#define CH1WIDTH	3	
#define CH0WIDTH	2
#define CH1MODOUT	1
#define CH0MODOUT	0
//ConfigL
#define CH1RESET	7
#define CH0RESET	6	
#define CH1SHDN		5
#define CH0SHDN		4
#define CH1OFF		3
#define CH0OFF		2
#define EXT_VREF	1
#define EXT_CLK		0
//StatusCOM
#define READ1		7
#define READ0		6
#define DR_LTY		5
#define DR_HIZ		4
#define CH1DRCONFIG	3
#define CH0DRCONFIG	2
#define CH1DRSTATUS	1
#define CH0DRSTATUS	0

//Address Loop Setting Types
#define NONE 0
#define GROUPS 1
#define TYPES 2
#define ALL 3

//DR pin output types
#define BOTH 3
#define CH1DR 2
#define CH0DR 1
#define LAG 0

//#define nop() {__asm__ volatile ("nop");}
#define nop() 

//globals
u8 ConfigHValue, ConfigLValue, GainValue, StatusComValue;


/*****************************************************
 * 
 * Local Prototypes
 * 
 *****************************************************/
void SetBit(u8 *address, u8 value);
void ClearBit(u8 *address, u8 value);
void SetPRE(u8 value);
void SetOSR(u8 value);
void SetGain(u8 ch0gain, u8 ch1gain);
void SetCH0Gain(u8 value);
void SetCH1Gain(u8 value);
void AddressLoop(u8 value);
void ExtVref(u8 value);
void ExtCLK(u8 value);
void DRHIZ(u8 value);
void DRLTY(u8 value);
void DRPin(u8 value);
void WidthCH0(u8 value);
void WidthCH1(u8 value);
void OffsetCH0(u8 value);
void OffsetCH1(u8 value);
void ShutdownADCs(u8 value0, u8 value1);
void ShutdownCH0(u8 value);
void ShutdownCH1(u8 value);
void ResetADCs(u8 value0, u8 value1);
void ResetCH0(u8 value);
void ResetCH1(u8 value);
void BoostADCs(u8 value0, u8 value1);
void BoostCH0(u8 value);
void BoostCH1(u8 value);
void ModulatorCH0(u8 value);
void ModulatorCH1(u8 value);
void Write3901(u8 command, u8 data);
void Write3901Config(u8 datah, u8 datal);
u8 Read3901(u8 command);
void Read_3901_CS_STAY_LOW(u8 command);

/**************************************************
 * 
 * Set Bit
 * 
 * 	- Low level routine to set internal bits for eventual
 * 
 * 		command transfer
 * 
 ***************************************/
void SetBit(u8 *ptrnumber, u8 value)
{
  u8 number;
  number = *ptrnumber;

  if(value == 0) {
    number = number | 1;        // set bit 0
  }

  if(value == 1) {
    number = number | 2;        // set bit 1
  }

  if (value == 2) {
    number = number | 4;        // set bit 2
  }

  if(value == 3) {
    number = number | 8;        // set bit 3
  }

  if(value == 4) {
    number = number | 16;        // set bit 4
  }

  if(value == 5) {
    number = number | 32;        // set bit 5
  }

  if(value == 6) {
    number = number | 64;        // set bit 6
  }

  if(value == 7) {
    number = number | 128;        // set bit 7
  }

  *ptrnumber = number;
}//END SETBIT

/**************************************************
 * 
 * Clear Bit
 * 
 * 	- Low level routine to clear internal bits for 
 * 
 * 		command transfer which follows
 * 
 ***************************************/
void ClearBit(u8 *ptrnumber, u8 value){
  u8 number;
  number = *ptrnumber;

  if(value == 0) {
    number = number & ~1;        // clear bit 0
  }
  if(value == 1) {
    number = number & ~2;        // clear bit 1
  }

  if (value == 2) {
    number = number & ~4;        // clear bit 2
  }
  if(value == 3) {
    number = number & ~8;        // clear bit 3
  }

  if(value == 4) {
    number = number & ~16;        // clear bit 4
  }
  if(value == 5) {
    number = number & ~32;        // clear bit 5
  }
  if(value == 6) {
    number = number & ~64;        // clear bit 6
  }

  if(value == 7) {
    number = number & ~128;        // clear bit 7
  }

  *ptrnumber = number;
}//END CLEARBIT

/**************************************************
 * 
 * Address Loop
 * 
 * 	- Put the MCP3901 in one of 4 possible configurations
 * 
 * 		for looping the ADC read
 * 
 * 	
 * 
 ***************************************/

void AddressLoop(u8 value){
  if(value == 0){
    ClearBit(&StatusComValue,READ1);
    ClearBit(&StatusComValue,READ0);
    Write3901(STATUSCOM, StatusComValue);
  }

  if(value == 1){
    ClearBit(&StatusComValue,READ1);
    SetBit(&StatusComValue,READ0);
    Write3901(STATUSCOM, StatusComValue);
  }

  if(value == 2){
    SetBit(&StatusComValue, READ1);
    ClearBit(&StatusComValue, READ0);
    Write3901(STATUSCOM, StatusComValue);
  }

  if(value == 3){
    SetBit(&StatusComValue, READ1);
    ClearBit(&StatusComValue, READ0);
    Write3901(STATUSCOM, StatusComValue);
  }
}//end AddressLoop

/**************************************************
 * 
 * ExtVref
 * 
 * 	- Contol the VREF setting for lower power, when
 * 
 * 		using External VREF
 * 
 * 	
 * 
 ***************************************/
void ExtVref(u8 value) {

  if(value == 1) {
    SetBit(&ConfigLValue,EXT_VREF);
  }

  if(value == 0) {
    ClearBit(&ConfigLValue,EXT_VREF);
  }

  Write3901(CONFIGL, ConfigLValue);
}//END Ext VREF


/**************************************************
 * 
 * ExtCLK
 * 
 * 	- Contol the EXTCLK setting for lower power, when
 * 
 * 		using External Clock
 * 
 * 	
 * 
 ***************************************/
void ExtCLK(u8 value) {

  if(value == 1)  {
    SetBit(&ConfigLValue,EXT_CLK);
  }

  if(value == 0) {
    ClearBit(&ConfigLValue,EXT_CLK);
  }

  Write3901(CONFIGL, ConfigLValue);
}//END ExtCLK


/**************************************************
 * 
 * DRHIZ
 * 
 * 	- When set this bit puts a logic high on the SDO
 * 
 * 	 when data is NOT ready. When clear, HIz and external
 * 
 * 	pullup resistor is required.
 * 
 * 	
 * 
 ***************************************/
void DRHIZ(u8 value)
{
  if(value == 1)
  {
    SetBit(&StatusComValue,DR_HIZ);
  }
  if(value == 0){
    ClearBit(&StatusComValue,DR_HIZ);
  }
  Write3901(STATUSCOM, StatusComValue);//Write3901(STATUSCOM, 0b10100000);

}//END DRHIZ


/**************************************************
 * 
 * DRLTY
 * 
 * 	- When set the delta sigma operates in a true latency
 * 
 * 	mode, all filter orders settle. when clear, data is ready
 * 
 * 	after each filter order.
 * 
 * 	
 * 
 ***************************************/
void DRLTY(u8 value) {
  if(value == 1)  {
    SetBit(&StatusComValue,DR_LTY);
  }
  if(value == 0){
    ClearBit(&StatusComValue,DR_LTY);
  }
  Write3901(STATUSCOM, StatusComValue);

}//END DRLTY

void DRPin(u8 value) {
  if(value == BOTH)
  {
    SetBit(&StatusComValue,CH1DRCONFIG);
    SetBit(&StatusComValue,CH0DRCONFIG);
  }
  if(value == CH1DR){
    SetBit(&StatusComValue,CH1DRCONFIG);
    ClearBit(&StatusComValue,CH0DRCONFIG);
  }
  if(value == CH0DR){
    ClearBit(&StatusComValue,CH1DRCONFIG);
    SetBit(&StatusComValue,CH0DRCONFIG);
  }
  if(value == LAG){
    ClearBit(&StatusComValue,CH1DRCONFIG);
    ClearBit(&StatusComValue,CH0DRCONFIG);
  }
  Write3901(STATUSCOM, StatusComValue);
}//END DRPin

void ModulatorCH0(u8 value){
  if(value == 1)  {
    SetBit(&ConfigHValue,CH0MODOUT);
  }
  if(value == 0){
    ClearBit(&ConfigHValue,CH0MODOUT);
  }
  Write3901(CONFIGH, ConfigHValue);
}//END ModulatorCH0

void ModulatorCH1(u8 value) {
  if(value == 1)  {
    SetBit(&ConfigHValue,CH1MODOUT);
  }
  if(value == 0){
    ClearBit(&ConfigHValue,CH1MODOUT);
  }
  Write3901(CONFIGH, ConfigHValue);
}//END ModulatorCH0

void WidthCH0(u8 value) {
  if(value == 24)  {
    SetBit(&ConfigHValue,CH0WIDTH);
  }
  if(value == 16){
    ClearBit(&ConfigHValue,CH0WIDTH);
  }
  Write3901(CONFIGH, ConfigHValue);
}//END Width CH0

void WidthCH1(u8 value) {
  if(value == 24)  {
    SetBit(&ConfigHValue,CH1WIDTH);
  }
  if(value == 16) {
    ClearBit(&ConfigHValue,CH1WIDTH);
  }
  Write3901(CONFIGH, ConfigHValue);
}//END Width CH1
void OffsetCH0(u8 value) {
  if(value == 1)
  {
    SetBit(&ConfigLValue,CH0OFF);
  }
  if(value == 0){
    ClearBit(&ConfigLValue,CH0OFF);
  }
  Write3901(CONFIGL, ConfigLValue);
}//END Offset CH0

void OffsetCH1(u8 value) {
  if(value == 1) {
    SetBit(&ConfigLValue,CH1OFF);
  }

  if(value == 0) {
    ClearBit(&ConfigLValue,CH1OFF);
  }

  Write3901(CONFIGL, ConfigLValue);
}//END Offset CH1

/**************************************************
 * 
 * GAIN
 * 
 * 	- Control the PGA gains - self explanatory
 * 
 * 	
 * 
 ***************************************/

void SetGain(u8 value0, u8 value1) {  

  GainValue = 0x00;

  if(value0 == 1){
    ClearBit(&GainValue,CH0_PGA2);
    ClearBit(&GainValue,CH0_PGA1);
    ClearBit(&GainValue,CH0_PGA0);
  }

  if(value0 == 2){
    ClearBit(&GainValue,CH0_PGA2);
    ClearBit(&GainValue,CH0_PGA1);
    SetBit(&GainValue,CH0_PGA0);
  }

  if(value0 == 4){
    ClearBit(&GainValue,CH0_PGA2);
    SetBit(&GainValue,CH0_PGA1);
    ClearBit(&GainValue,CH0_PGA0);
  }
  if(value0 ==8){
    ClearBit(&GainValue,CH0_PGA2);
    SetBit(&GainValue,CH0_PGA1);    
    SetBit(&GainValue,CH0_PGA0);
  }
  if(value0 == 16){
    SetBit(&GainValue,CH0_PGA2);
    ClearBit(&GainValue,CH0_PGA1);
    ClearBit(&GainValue,CH0_PGA0);
  }
  if(value0 ==32){
    SetBit(&GainValue,CH0_PGA2);
    ClearBit(&GainValue,CH0_PGA1);
    SetBit(&GainValue,CH0_PGA0);
  }
  if(value1 == 1){
    ClearBit(&GainValue,CH1_PGA2);
    ClearBit(&GainValue,CH1_PGA1);
    ClearBit(&GainValue,CH1_PGA0);

  }
  if(value1 == 2){
    ClearBit(&GainValue,CH1_PGA2);
    ClearBit(&GainValue,CH1_PGA1);
    SetBit(&GainValue,CH1_PGA0);
  }
  if(value1 == 4){
    ClearBit(&GainValue,CH1_PGA2);
    SetBit(&GainValue,CH1_PGA1);
    ClearBit(&GainValue,CH1_PGA0);
  }
  if(value1 ==8){
    ClearBit(&GainValue,CH1_PGA2);
    SetBit(&GainValue,CH1_PGA1);
    SetBit(&GainValue,CH1_PGA0);
  }
  if(value1 == 16){
    SetBit(&GainValue,CH1_PGA2);
    ClearBit(&GainValue,CH1_PGA1);
    ClearBit(&GainValue,CH1_PGA0);
  }
  if(value1 ==32){
    SetBit(&GainValue,CH1_PGA2);
    ClearBit(&GainValue,CH1_PGA1);
    SetBit(&GainValue,CH1_PGA0);
  }
  Write3901(GAIN, GainValue);
}

/**************************************************
 * 
 * Set CH0 GAIN
 * 
 * 	- Control the CH0 PGA gain - self explanatory
 * 
 * 	
 * 
 ***************************************/
void SetCH0Gain(u8 value){
  //GainValue = 0x00;
  if(value == 1){
    ClearBit(&GainValue,CH0_PGA2);
    ClearBit(&GainValue,CH0_PGA1);
    ClearBit(&GainValue,CH0_PGA0);

  }
  if(value == 2){
    ClearBit(&GainValue,CH0_PGA2);
    ClearBit(&GainValue,CH0_PGA1);
    SetBit(&GainValue,CH0_PGA0);
  }
  if(value == 4){
    ClearBit(&GainValue,CH0_PGA2);
    SetBit(&GainValue,CH0_PGA1);
    ClearBit(&GainValue,CH0_PGA0);
  }
  if(value ==8){
    ClearBit(&GainValue,CH0_PGA2);
    SetBit(&GainValue,CH0_PGA1);
    SetBit(&GainValue,CH0_PGA0);
  }
  if(value == 16){
    SetBit(&GainValue,CH0_PGA2);
    ClearBit(&GainValue,CH0_PGA1);
    ClearBit(&GainValue,CH0_PGA0);
  }
  if(value ==32){
    SetBit(&GainValue,CH0_PGA2);
    ClearBit(&GainValue,CH0_PGA1);
    SetBit(&GainValue,CH0_PGA0);
  }
  Write3901(GAIN, GainValue);
}//END SET CH0 GAIN

/**************************************************
 * 
 * Set CH1 GAIN
 * 
 * 	- Control the CH1 PGA gain - self explanatory
 * 
 * 	
 * 
 ***************************************/
void SetCH1Gain(u8 value)
{
  //GainValue = 0x00;
  if(value == 1){
    ClearBit(&GainValue,CH1_PGA2);
    ClearBit(&GainValue,CH1_PGA1);
    ClearBit(&GainValue,CH1_PGA0);
  }
  if(value == 2){
    ClearBit(&GainValue,CH1_PGA2);
    ClearBit(&GainValue,CH1_PGA1);
    SetBit(&GainValue,CH1_PGA0);
  }
  if(value == 4){
    ClearBit(&GainValue,CH1_PGA2);
    SetBit(&GainValue,CH1_PGA1);
    ClearBit(&GainValue,CH1_PGA0);
  }
  if(value ==8){
    ClearBit(&GainValue,CH1_PGA2);
    SetBit(&GainValue,CH1_PGA1);
    SetBit(&GainValue,CH1_PGA0);
  }
  if(value == 16){
    SetBit(&GainValue,CH1_PGA2);
    ClearBit(&GainValue,CH1_PGA1);
    ClearBit(&GainValue,CH1_PGA0);
  }
  if(value ==32){
    SetBit(&GainValue,CH1_PGA2);
    ClearBit(&GainValue,CH1_PGA1);
    SetBit(&GainValue,CH1_PGA0);
  }
  Write3901(GAIN, GainValue);
}//END SET CH1 GAIN

/**************************************************
 * 
 * PRE Scaler
 * 
 * 	- Control the Interl Clock Precale
 * 
 * 	
 * 
 ***************************************/
void SetPRE(u8 value) {
  if(value == 1){
    ClearBit(&ConfigHValue,PRE1);
    ClearBit(&ConfigHValue,PRE0);
    Write3901Config(ConfigHValue, ConfigLValue);
  }
  if(value == 2){
    ClearBit(&ConfigHValue,PRE1);
    SetBit(&ConfigHValue,PRE0);
    Write3901Config(ConfigHValue, ConfigLValue);
  }
  if(value == 4){
    SetBit(&ConfigHValue, PRE1);
    ClearBit(&ConfigHValue, PRE0);
    Write3901Config(ConfigHValue, ConfigLValue);
  }
  if(value == 8){
    SetBit(&ConfigHValue,PRE1);
    SetBit(&ConfigHValue,PRE0);
    Write3901Config(ConfigHValue, ConfigLValue);
  }
}//end set PREscaler
/**************************************************
 * 
 * OSR Control
 * 
 * 	- Control the device oversampling Ratio
 * 
 * 	
 * 
 ***************************************/

void SetOSR(u8 value) {

  ConfigHValue = 0x00;
  ConfigLValue = 0x00;

  if(value == 32){
    ClearBit(&ConfigHValue,OSR1);
    ClearBit(&ConfigHValue,OSR0);
    Write3901Config(ConfigHValue, ConfigLValue);
  }

  if(value == 64){
    ClearBit(&ConfigHValue,OSR1);
    SetBit(&ConfigHValue,OSR0);
    Write3901Config(ConfigHValue, ConfigLValue);
  }

  if(value == 128){
    SetBit(&ConfigHValue, OSR1);
    ClearBit(&ConfigHValue, OSR0);
    Write3901Config(ConfigHValue, ConfigLValue);
  }

  if(value == 255){
    SetBit(&ConfigHValue,OSR1);
    SetBit(&ConfigHValue,OSR0);
    Write3901Config(ConfigHValue, ConfigLValue);
  }
}//end set OSR

/**************************************************
 * 
 * Shutdown ADCs
 * 
 * 	- when high the ADCs are low power
 * 
 * 	
 * 
 ***************************************/
void ShutdownADCs(u8 value0, u8 value1) {
  if(value0){
    SetBit(&ConfigLValue, CH0SHDN);
  }
  if(!value0){
    ClearBit(&ConfigLValue,CH0SHDN);
  }
  if(value1 == 1) {
    SetBit(&ConfigLValue,CH1SHDN);
  }
  if(value1 == 0) {
    ClearBit(&ConfigLValue,CH1SHDN);
  }
  Write3901Config(CONFIGL, ConfigLValue);
}//end ShutdownADCs


/**************************************************
 * 
 * Shutdown CH0
 * 
 * 	- when high CH0 is low power
 * 
 * 	
 * 
 ***************************************/
void ShutdownCH0(u8 value) {
  if(value) {
    SetBit(&ConfigLValue, CH0SHDN);
  }
  if(!value){
    ClearBit(&ConfigLValue,CH0SHDN);
  }
  Write3901Config(CONFIGL, ConfigLValue);
}//end shutdown CH0

/**************************************************
 * 
 * Shutdown CH1
 * 
 * 	- when high CH1 is low power
 * 
 * 	
 * 
 ***************************************/
void ShutdownCH1(u8 value) {
  if(value){
    SetBit(&ConfigLValue, CH1SHDN);
  }
  if(!value){
    ClearBit(&ConfigLValue,CH1SHDN);
  }
  Write3901Config(CONFIGL, ConfigLValue);
}//end shutdown CH0

/**************************************************
 * 
 * Reset ADCs
 * 
 * 	- when high the ADCs are SINC FILTER FLUSHED
 * 
 * 	
 * 
 ***************************************/
void ResetADCs(u8 value0, u8 value1) {
  if(value0 == 1) {
    SetBit(&ConfigLValue,CH0RESET);
  }
  if(value0 == 0) {
    ClearBit(&ConfigLValue,CH0RESET);
  }
  if(value1 == 1){
    SetBit(&ConfigLValue,CH1RESET);
  }
  if(value1 == 0){
    ClearBit(&ConfigLValue,CH1RESET);
  }
  Write3901Config(ConfigHValue, ConfigLValue);
}//END RESETADCs

/**************************************************
 * 
 * Reset CH0
 * 
 * 	- when high CH0 IS SINC FILTER FLUSHED
 * 
 * 	
 * 
 ***************************************/
void ResetCH0(u8 value) {
  if(value == 1){
    SetBit(&ConfigLValue,CH0RESET);
  }
  if(value == 0){
    ClearBit(&ConfigLValue,CH0RESET);
  }
  Write3901Config(ConfigHValue, ConfigLValue);
}//END RESET

/**************************************************
 * 
 * Reset CH1
 * 
 * 	- when high CH1 IS SINC FILTER FLUSHED
 * 
 * 	
 * 
 ***************************************/
void ResetCH1(u8 value) {
  if(value == 1){
    SetBit(&ConfigLValue,CH1RESET);
  }
  if(value == 0){
    ClearBit(&ConfigLValue,CH1RESET);
  }
  Write3901Config(ConfigHValue, ConfigLValue);

}//END RESET

/**************************************************
 * 
 * Boost ADCs
 * 
 * 	- when high the ADCs can run up to 64ksps with 16MHz XTAL
 * 
 * 	
 * 
 ***************************************/
void BoostADCs(u8 value0, u8 value1){
  if(value0 == 1){
    SetBit(&GainValue,BOOST_CH0);
  }
  if(value0 == 0){
    ClearBit(&GainValue,BOOST_CH0);
  }

  if(value1 == 1){
    SetBit(&GainValue,BOOST_CH1);
  }
  if(value1 == 0){
    ClearBit(&GainValue,BOOST_CH1);
  }
  Write3901Config(GAIN, GainValue);
}//END BOOSTADCs

/**************************************************
 * 
 * Boost CH0
 * 
 * 	- when high CH0 can run up to 64ksps with 16MHz XTAL
 * 
 * 	
 * 
 ***************************************/
void BoostCH0(u8 value){
  if(value == 1){
    SetBit(&GainValue,BOOST_CH0);
  }
  if(value == 0){
    ClearBit(&GainValue,BOOST_CH0);
  }
  Write3901Config(GAIN, GainValue);
}//END BOOST

/**************************************************
 * 
 * Boost CH1
 * 
 * 	- when high CH1 can run up to 64ksps with 16MHz XTAL
 * 
 * 	
 * 
 ***************************************/
void BoostCH1(u8 value) {
  if(value == 1){
    SetBit(&GainValue,BOOST_CH1);
  }
  if(value == 0){
    ClearBit(&GainValue,BOOST_CH1);
  }
  Write3901Config(GAIN, GainValue);
}//END BOOST

/*************************************************/
void Write3901(u8 address, u8 data)
{
  unsigned long t;
#if 0
  Serial.print("send: 0x");
  Serial.print(address, HEX);
  Serial.print(" 0x");
  Serial.println(data, HEX);
#endif 
  u8 i;
  address = address * 2; //shift to left by 1

  CS_mp3901=0;
  delay(1);

  //send out the command byte
  t=SPI.transfer(address);
  delay(1);

  //send out the data byte
  t=SPI.transfer(data);
  delay(1);

  CS_mp3901=1;
}//End Write MCP3901


/*************************************************/
u8 Read3901(u8 address) {
  //NEED TO GO BACK TO 8 BIT SPI WIDE MODE
  nop();
}//end Read3901

void Read_3901_CS_STAY_LOW(u8 address) {
  unsigned long t;
  u8 i;
  address = address * 2; //shift to left by 1
  address = address +1; //set bit 0 to HIGH FOR R/W BIT READ

  CS_mp3901=0;
  delay(1);
  t=SPI.transfer(address);
  delay(1);
  //CS_mp3901=1;
  //LEAVE CHIP SELECT LOW AND THEN GO WAIT ON DR INTERRUPTS AND SEND MORE CLOCKS THEN

}//end Read3901

/*************************************************/
void Write3901Config(u8 high, u8 low) {
  CS_mp3901=0;
  delay(1);
  SPI.transfer(CONFIG_W);
  delay(1);
  SPI.transfer(high);
  delay(1);
  SPI.transfer(low);
  delay(1);
  CS_mp3901=1;
}//End Write MCP3901


void readADC(unsigned long* chan1){
  byte b[3];
  unsigned long d1;
  
  CS_mp3901=0;
  SPI.transfer(CHANNEL0_R); // control byte
  for (int i=0; i < 3; ++i) {
    b[i] = SPI.transfer(0);
  }
  CS_mp3901=1;

  d1= ( b[0] << 16) | (b[1] << 8) | b[2];
 
  if (d1 & 0x800000)
    d1 = 0;
 
  *chan1 = d1;
 
}
void readADC(unsigned long* chan1, unsigned long* chan2){
  byte b[6];
  unsigned long d1, d2;

  CS_mp3901=0;
  SPI.transfer(CHANNEL0_R); // control byte
  for (int i=0; i < 6; ++i) {
    b[i] = SPI.transfer(0);
  }
  CS_mp3901=1;

  d1= ( b[0] << 16) | (b[1] << 8) | b[2];
  d2= ( b[3] << 16) | (b[4] << 8) | b[5];

  if (d1 & 0x800000)
    d1 = 0;
//  if (d2 & 0x800000)
//    d2 = 0;

  *chan1 = d1;
  *chan2 = d2;


  /*
      CS_mp3901=0;
   SPI.transfer(CHANNEL0_R); // control byte
   t1 = SPI.transfer(0);
   t2 = SPI.transfer(0);
   t3 = SPI.transfer(0);  
   t4 = SPI.transfer(0);
   t5 = SPI.transfer(0);
   t6 = SPI.transfer(0);  
   CS_mp3901=1;
   
   chan1= ( t1 << 16) | (t2 << 8) | t3;
   chan2= ( t4 << 16) | (t5 << 8) | t6;
   
   if (chan1 & 0x800000)
   chan1 = 0;
   if (chan2 & 0x800000)
   chan2 = 0;
   */
}

void beginADC() {
  SPI.setDataMode(SPI_MODE0);          // adc communication via SPI library
  SPI.setBitOrder(MSBFIRST);
  SPI.setClockDivider(SPI_CLOCK_DIV8); // 80Mhz sys clock / 8 = 5Mhz SPI bus clock (10Mhz max)
  SPI.begin();

  // adc configs
  ConfigHValue = 0x00;
  ConfigLValue = 0x00;
  GainValue = 0x00;
  StatusComValue = 0x00;
  AddressLoop(TYPES);
  DRLTY(0);
  DRHIZ(1);
  SetGain(1,1);  //   3-800 mV range
  SetOSR(32);   // initial oversampling rate
  ExtCLK(0);
  ExtVref(0);
  WidthCH0(24);
  WidthCH1(24);  
}

