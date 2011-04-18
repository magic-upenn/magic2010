#include "MagHmc5843.h"
#include "TWI_Master.h"
#include <avr/interrupt.h>

volatile uint8_t TWI_transBuff[10];
volatile uint8_t TWI_recBuff[10];
volatile uint16_t magCntr = 0;
volatile uint8_t TWI_targetSlaveAddress;
volatile uint8_t TWI_operation;

int MagInit()
{
	TWI_Master_Initialise();
	TWI_targetSlaveAddress = 0x1E;		// MHCMC6352's address
	TWI_transBuff[0] = (TWI_targetSlaveAddress<<TWI_ADR_BITS) | (FALSE<<TWI_READ_BIT);
	TWI_transBuff[1] = 0x00;
  TWI_transBuff[2] = 0x18;
  TWI_transBuff[3] = 0x00;
  TWI_transBuff[4] = 0x00; 
	sei();								// enable interrupts
	TWI_Start_Transceiver_With_Data(TWI_transBuff,5);
	TWI_operation = SEND_DATA; 		// Set the next operation
}


int MagGetData(uint16_t * data)
{
  int ret = -1;

  // Check if the TWI Transceiver has completed an operation.
	if ( ! TWI_Transceiver_Busy() )                              
	{
	    // Check if the last operation was successful
		if ( TWI_statusReg.lastTransOK )
		{
			// Determine what action to take now
			if (TWI_operation == SEND_DATA)
			{ 
				TWI_operation = REQUEST_DATA; 						// Set next operation
			}
			else if (TWI_operation == REQUEST_DATA)
			{ 
				// Request data from slave
				TWI_recBuff[0] = (TWI_targetSlaveAddress<<TWI_ADR_BITS) | (TRUE<<TWI_READ_BIT);
				TWI_Start_Transceiver_With_Data(TWI_recBuff,8); // 3 = TWI_recBuff[0] byte + heading high byte + heading low byte
				TWI_operation = READ_DATA_FROM_BUFFER; 			// Set next operation        
			}
			else if (TWI_operation == READ_DATA_FROM_BUFFER)
			{ 
				// Get the received data from the transceiver buffer
				TWI_Get_Data_From_Transceiver(TWI_recBuff);
        
        data[0] = magCntr;
        data[1] = (uint16_t)TWI_recBuff[1] << 8 | TWI_recBuff[2];
        data[2] = (uint16_t)TWI_recBuff[3] << 8 | TWI_recBuff[4];
        data[3] = (uint16_t)TWI_recBuff[5] << 8 | TWI_recBuff[6];
        magCntr++;
        
        TWI_operation = WAIT_FOR_REQUEST;
        ret = 0;
			}
      else if (TWI_operation == WAIT_FOR_REQUEST)
      {
        TWI_operation = REQUEST_DATA;    					// Set next operation
      }
		}
		else // Got an error during the last transmission
		{
			// Use TWI status information to detemine cause of failure and take appropriate actions. 
			//TWI_Act_On_Failure_In_Last_Transmission(TWI_Get_State_Info( ));
		}
	} //end of TWI status check


  return ret;
}
