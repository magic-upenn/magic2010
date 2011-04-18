volatile uint8_t TWI_transBuff[10];
volatile uint8_t TWI_recBuff[10];

/*  
  uint8_t TWI_targetSlaveAddress, TWI_operation;
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
*/  


//start magnetometer stuff  
      
/*     
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
          
          magPacket[0] = magCntr;
          magPacket[1] = (uint16_t)TWI_recBuff[1] << 8 | TWI_recBuff[2];
          magPacket[2] = (uint16_t)TWI_recBuff[3] << 8 | TWI_recBuff[4];
          magPacket[3] = (uint16_t)TWI_recBuff[5] << 8 | TWI_recBuff[6];
          HostSendPacket(MMC_IMU_DEVICE_ID,MMC_MAG_RAW,
                        (uint8_t*)magPacket,(4)*sizeof(uint16_t));
          magCntr++;
          
          TWI_operation = WAIT_FOR_REQUEST;
				}
        else if (TWI_operation == WAIT_FOR_REQUEST)
        {
          if (len > 0)
            compassReqCntr++;
            
          if (compassReqCntr == 1)
          {
            TWI_operation = REQUEST_DATA;    					// Set next operation
            compassReqCntr = 0;
          }
        }
        
			}
			else // Got an error during the last transmission
			{
				// Use TWI status information to detemine cause of failure and take appropriate actions. 
				//TWI_Act_On_Failure_In_Last_Transmission(TWI_Get_State_Info( ));
			}
		} //end of TWI status check
  
  //end magnetometer stuff
  */



int ProcessIncomingRCPacket()
{
  int16_t v = (((int16_t)rcValsIn[RC_V_IND]) - RC_V_BIAS)/2;
  int16_t w = (((int16_t)rcValsIn[RC_W_IND]) - RC_W_BIAS)/2;
  
  v = v < 128 ? v : 127;
  v = v > -127 ? v : -127;
  w = w < 128 ? w : 127;
  w = w > -127 ? w : -127;
  
  //send the RC packet to the host so that it can know the current RC channel values
  //DO NOT send it without host requesting it
  //TODO: implement response to host request for current RC command
  //HostSendPacket(MMC_RC_DEVICE_ID,MMC_RC_DECODED,(uint8_t*)rcValsIn,7*sizeof(uint16_t));
  
  
  
  rcVelCmd[0]=(int8_t)v;
  rcVelCmd[1]=(int8_t)w;
  
  //set the flag so that the command can be sent to the motor controller whenever
  //the RS485 bus frees up
  rcCmdPending = 1;

  return 0;
}

void RCTimingReset(void)
{
  rclen = 0;
}

//timer1_init();
  //timer1_set_compa_callback(RCTimingReset);



//receive RC commands
    c = uart3_getchar();
    
    if (c != EOF)
    {
      TCNT1 = 0;
      rcPacketIn[rclen] = c;
    
      switch (rclen)
      {
        case 0:
        case 1:
          rclen++;
          break;
          
        
        default:
          rclen++;
          if (rclen & 0x01)  //process the first byte
          {
            rcChannel = (c & 0b00111100)>>2;        //extract the channel
            if (rcChannel < 0 || rcChannel> 6)
            {
              rclen = 0;
              break;
            }
            
            rcValsIn[rcChannel] = ((uint16_t)(c & 0x03))<<8;  //extract MSB part of the value
          }
          else             //process the second byte
          {
            rcValsIn[rcChannel] += c;                             //get the LSB
          }
          break;
      }
      
      if (rclen == 16)
      {
        ProcessIncomingRCPacket();
        rclen = 0;
        rcInitialized = 1;
        LED_RC_TOGGLE;
      }
    }








if (rcCmdPending && !rs485Blocked)
    {
      BusSendPacket(MMC_RC_DEVICE_ID,MMC_RC_DECODED,(uint8_t*)rcValsIn,7*sizeof(uint16_t));
    
    /*
      BusSendPacket(MMC_MOTOR_CONTROLLER_DEVICE_ID,
                  MMC_MOTOR_CONTROLLER_VELOCITY_SETTING,
                  (uint8_t*)rcVelCmd, 4);
    */
    
      //reset the timer
      rcCmdPending = 0;
    }
