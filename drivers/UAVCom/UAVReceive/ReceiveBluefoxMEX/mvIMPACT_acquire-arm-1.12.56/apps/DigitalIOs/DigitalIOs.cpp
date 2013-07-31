#ifdef _MSC_VER	// is Microsoft compiler?
#	if _MSC_VER < 1300	// is 'old' VC 6 compiler?
#		pragma warning( disable : 4786 ) // 'identifier was truncated to '255' characters in the debug information'
#	endif // #if _MSC_VER < 1300
#endif // #ifdef _MSC_VER
#include <stdio.h>
#include <cstdlib>
#include <iostream>
#include <apps/Common/exampleHelper.h>
#include <mvIMPACT_CPP/mvIMPACT_acquire.h>

using namespace std;
using namespace mvIMPACT::acquire;

//-----------------------------------------------------------------------------
template<typename _Ty>
_Ty bitMask( _Ty bitcnt )
//-----------------------------------------------------------------------------
{
	if( bitcnt <= 1 )
	{
		return 1;
	}
	return ( ( 1 << ( bitcnt - 1 ) ) | bitMask( bitcnt-1 ) );
}

//-----------------------------------------------------------------------------
string getStringFromCIN( void )
//-----------------------------------------------------------------------------
{
	cout << endl << ">>> ";
	string cmd;
	cin >> cmd;
	// remove the '\n' from the stream
	std::cin.get();
	return cmd;
}

//-----------------------------------------------------------------------------
int getIntFromCIN( void )
//-----------------------------------------------------------------------------
{
	return atoi( getStringFromCIN().c_str() );
}

//-----------------------------------------------------------------------------
int getHEXFromCIN( void )
//-----------------------------------------------------------------------------
{
	int result = 0;
	sscanf( getStringFromCIN().c_str(), "%i", &result );
	return result;
}

//-----------------------------------------------------------------------------
template<typename _Ty>
void hexToCOUT( const _Ty& param )
//-----------------------------------------------------------------------------
{
	cout.setf( std::ios::hex, std::ios::basefield );
	cout << "0x" << param;
	cout.unsetf( std::ios::hex );
}

//-----------------------------------------------------------------------------
void modifySyncOutput( SyncOutput* p )
//-----------------------------------------------------------------------------
{
	displayPropertyData( p->frequency_Hz );
	modifyPropertyValue( p->frequency_Hz );
	displayPropertyData( p->lowPart_pc );
	modifyPropertyValue( p->lowPart_pc );
}

//-----------------------------------------------------------------------------
void displayCommonIOFeatures( IOSubSystem& ioss )
//-----------------------------------------------------------------------------
{
	// display available features
	cout << "This device has" << endl;

	const unsigned int inputCount = ioss.getInputCount();
	cout << "  " << inputCount << " digital input(s)" << endl;
	// display the state and name of each individual digital input
	for( unsigned int i=0; i<inputCount; i++ )
	{
		cout << "   [" << i << "]: " << ioss.input( i )->getDescription() << "(current state: " << ioss.input( i )->get() << ")" << endl;
	}
	cout << endl;

	if( inputCount > 0 )
	{
		// read the state of all digital inputs in a single function call
		cout << "All input registers can be queried with a single function call: Calling 'readInputRegister' returned ";
		hexToCOUT( ioss.readInputRegister() );
		cout << endl;
		cout << "From the LSB to the MSB a '1' in this result indicates, that this input is currently connected to a signal" << endl
			<< "that is interpreted as a logial '1'. E.g. 0x13 indicates that inputs 0, 1 and 4 are currently in 'high' state." << endl;
	}

	const unsigned int outputCount = ioss.getOutputCount();
	cout << "  " << outputCount << " digital output(s)" << endl;
	if( outputCount > 0 )
	{
		unsigned int readOnlyAccessMask = 0;
		bool boRun = true;
		while( boRun )
		{
			// display the state and name of each individual digital output
			for( unsigned int j=0; j<outputCount; j++ )
			{
				DigitalOutput* pOutput = ioss.output( j );
				cout << "   [" << j << "]: " << pOutput->getDescription() << "(current state: " << pOutput->get() << ", " << ( pOutput->isWriteable() ? "" : "NOT " ) << "manually switchable)" << endl;
				if( !pOutput->isWriteable() )
				{
					readOnlyAccessMask |= 1 << j;
				}
			}
			cout << endl;
			cout << "Enter the number of a digital output followed by [ENTER] to modify its state or 'c' followed by [ENTER] to continue." << endl;
			string cmd(getStringFromCIN());
			if( cmd == "c" )
			{
				boRun = false;
				continue;
			}
			unsigned int index = static_cast<unsigned int>(atoi( cmd.c_str() ));
			if( ( index >= outputCount ) || !isdigit( cmd[0] ) )
			{
				cout << "Invalid selection" << endl;
				continue;
			}

			DigitalOutput* pOutput = ioss.output( index );
			if( !pOutput->isWriteable() )
			{
				cout << pOutput->getDescription() << " is not manually switchable." << endl;
				continue;
			}
			cout << "Please enter the number in front of the function that shall be called followed by [ENTER]:" << endl;
			cout << "  [0]: set" << endl
				<< "  [1]: reset" << endl
				<< "  [2]: flip" << endl;
			int newMode = getIntFromCIN();
			switch( newMode )
			{
			case 0:
				pOutput->set();
				break;
			case 1:
				pOutput->reset();
				break;
			case 2:
				pOutput->flip();
				break;
			default:
				cout << "Invalid selection." << endl;
				break;
			}
		}

		// read the state of all digital outputs in a single function call
		cout << "All output registers can be queried with a single function call." << endl
			<< endl
			<< "From the LSB to the MSB a '1' in this result indicates, that this output is currently switched to 'high' or 'active' state" << endl
			<< endl
			<< "E.g. 0x22 indicates that outputs 1 and 5 (zero-based) are currently in 'high' state." << endl;
		const unsigned int fullOutputMask = bitMask( outputCount );
		boRun = true;
		while( boRun )
		{
			cout << "Calling 'readOutputRegister' returned ";
			hexToCOUT( ioss.readOutputRegister() );
			cout << endl;
			cout << "Please enter 'y' followed by [ENTER] to modify all digital outputs with a single function" << endl
				<< "call or anything else followed by [ENTER] to continue." << endl;
			if( getStringFromCIN() != "y" )
			{
				boRun = false;
				continue;
			}
			cout << "Please enter the bitmask in hex that contains the new values for the digital outputs followed by [ENTER]: ";
			unsigned int value = static_cast<unsigned int>(getHEXFromCIN());
			if( value & ~fullOutputMask )
			{
				value &= fullOutputMask;
				cout << "WARNING: More bits then outputs specified. Bitmask truncated to ";
				hexToCOUT( value );
				cout << endl;
			}
			cout << "Please enter the bitmask in hex that contains '1's for outputs that shall be affected by this operation followed by [ENTER]: ";
			unsigned int mask = static_cast<unsigned int>(getHEXFromCIN());
			if( readOnlyAccessMask & mask )
			{
				cout << "WARNING: At least one selected output is not manually switchable: Mask: ";
				hexToCOUT( mask );
				cout << ", read-only access mask: ";
				hexToCOUT( readOnlyAccessMask );
				cout << endl;
				cout << "No digital outputs have been modified." << endl
					<< endl;
				continue;
			}
			ioss.writeOutputRegister( value, mask );
		}
	}

	cout << "This device also has" << endl;
	cout << "  " << ioss.RTCtrProgramCount() << " hardware realtime controller(s)." << endl
		<< endl;
	if( ioss.RTCtrProgramCount() > 0 )
	{
		cout << "How to program the HRTC (Hardware RealTime Controller) is not part of this sample, but the manual will contain a separate chapter on this topic.";
	}

	cout << "  " << ioss.getPulseStartConfigurationCount() << " pulse start configuration(s)." << endl
		<< endl;
}

//-----------------------------------------------------------------------------
void mvBlueCOUGARIOAccess( Device* pDev )
//-----------------------------------------------------------------------------
{
	IOSubSystemBlueCOUGAR ioss(pDev);
	displayCommonIOFeatures( ioss );
	if( ioss.digitalInputThreshold_mV.isValid() )
	{
		cout << "This device also supports the " << ioss.digitalInputThreshold_mV.name() << " property." << endl;
		displayPropertyData( ioss.digitalInputThreshold_mV );
	}
	
	const unsigned int outputCount = ioss.getOutputCount();
	if( outputCount > 0 )
	{
		// show how to set and unset output lines into 'expose active' state. In this mode the specified output
		// will switch its state when starting and stopping the exposure of the image sensor.
		OutputSignalGeneratorBlueDevice osg(pDev);
		bool boRun = true;
		while( boRun )
		{
			set<unsigned int> validOutputsForExposeActiveSignals;
			for( unsigned int j=0; j<outputCount; j++ )
			{
				DigitalOutput* pOutput = ioss.output( j );
				if( osg.canCreateExposeActiveSignal( pOutput ) )
				{
					validOutputsForExposeActiveSignals.insert( j );
					bool boInversionActive = osg.isSignalInverted( pOutput );
					bool boActive = osg.isOutputModeActive( pOutput, ddomExposureActive );
					cout << "   [" << j << "]: " << pOutput->getDescription() << " can be used to create an 'expose active' signal(currently "
						<< ( boActive ? "" : "NOT " ) << "active and " << ( boInversionActive ? "" : "NOT " ) << "inverted)"
						<< "(inversion " << ( osg.canInvertSignal( pOutput ) ? "" : "NOT " ) << "possible)" << endl;
				}
			}
			cout << "Select the index of an output whos current configuration shall be changed followed by [ENTER] or 'c'" << endl
				<< "followed by [ENTER] to continue: ";
			string cmd(getStringFromCIN());
			if( cmd == "c" )
			{
				boRun = false;
				continue;
			}
			unsigned int index = static_cast<unsigned int>(atoi( cmd.c_str() ));
			if( validOutputsForExposeActiveSignals.find( index ) == validOutputsForExposeActiveSignals.end() )
			{
				cout << "Invalid selection." << endl;
				continue;
			}
			DigitalOutput* pOutput = ioss.output( index );
			cout << "What shall be done with this output(" << pOutput->getDescription() << ")?" << endl
				<< "  [0]: remove 'exposure active' signal" << endl
				<< "  [1]: define 'exposure active' signal" << endl
				<< "  [2]: define inverted 'exposure active' signal" << endl;
			int newMode = getIntFromCIN();
			switch( newMode )
			{
			case 0:
				osg.undefineSignal( pOutput );
				break;
			case 1:
				osg.setOutputMode( pOutput, ddomExposureActive );
				break;
			case 2:
				osg.setOutputMode( pOutput, ddomExposureActive, true );
				break;
			default:
				cout << "Invalid selection." << endl;
				break;
			}
		}
	}
}

//-----------------------------------------------------------------------------
void mvBlueFOXIOAccess( Device* pDev )
//-----------------------------------------------------------------------------
{
	IOSubSystemBlueFOX ioss(pDev);
	displayCommonIOFeatures( ioss );
	if( ioss.digitalInputThreshold.isValid() )
	{
		cout << "This device also supports the '" << ioss.digitalInputThreshold.name() << "' property." << endl;
		displayPropertyData( ioss.digitalInputThreshold );
	}
	CameraSettingsBlueFOX cs(pDev);
	cout << "To use a digital output in 'expose active' mode, the property '" << cs.flashMode.name() << "' can be used." << endl
		<< "If a delay between switching the output and starting the frame exposure is needed, this can be achieved by " << endl
		<< "writing to the property '" << cs.flashToExposeDelay_us.name() << "'." << endl;
}

//-----------------------------------------------------------------------------
void frameGrabberIOAccess( Device* pDev )
//-----------------------------------------------------------------------------
{
	IOSubSystemFrameGrabber ioss(pDev);
	displayCommonIOFeatures( ioss );

	const unsigned int HDOutputCount = ioss.getHDOutputCount();
	const unsigned int VDOutputCount = ioss.getVDOutputCount();
	if( ( HDOutputCount > 0 ) || ( VDOutputCount > 0 ) )
	{
		cout << "This device also offers" << endl;
		bool boRun = true;
		while( boRun )
		{
			cout << "  " << HDOutputCount << " HD output(s)" << endl;
			for( unsigned int i=0; i<HDOutputCount; i++ )
			{
				SyncOutput* p = ioss.HDOutput( i );
				cout << "   [" << i << "]: " << p->getDescription() << "(" << p->frequency_Hz << ", " << p->lowPart_pc << ")" << endl;
			}
			cout << endl;

			cout << "  " << VDOutputCount << " VD output(s)" << endl;
			for( unsigned int j=0; j<VDOutputCount; j++ )
			{
				SyncOutput* p = ioss.VDOutput( j );
				cout << "   [" << j << "]: " << p->getDescription() << "(" << p->frequency_Hz << ", " << p->lowPart_pc << ")" << endl;
			}
			cout << "HD and VD output signals are currently switched to '" << ioss.syncOutputMode.readS() << "' mode." << endl;

			cout << "Please enter the number in front of the function that shall be called followed by [ENTER] or 'c' followed by [ENTER] to continue:" << endl;
			cout << "  [0]: modify the properties a HD output" << endl
				<< "  [1]: modify the properties a VD output" << endl
				<< "  [2]: modify the " << ioss.syncOutputMode.name() << " property." << endl;
			string cmd(getStringFromCIN());
			if( cmd == "c" )
			{
				boRun = false;
				continue;
			}

			unsigned int cmdIndex = static_cast<unsigned int>(atoi( cmd.c_str() ));
			if( ( cmdIndex > 2 ) || !isdigit( cmd[0] ) )
			{
				cout << "Invalid selection" << endl;
				continue;
			}
			switch( cmdIndex )
			{
			case 0:
				{
					cout << "Please enter the index of the HD-output you want to modify followed by [ENTER]: ";
					string cmd(getStringFromCIN());
					unsigned int index = static_cast<unsigned int>(atoi( cmd.c_str() ));
					if( ( index >= HDOutputCount ) || !isdigit( cmd[0] ) )
					{
						cout << "Invalid selection" << endl;
						continue;
					}
					modifySyncOutput( ioss.HDOutput( index ) );
				}
				break;
			case 1:
				{
					cout << "Please enter the index of the VD-output you want to modify followed by [ENTER]: ";
					string cmd(getStringFromCIN());
					unsigned int index = static_cast<unsigned int>(atoi( cmd.c_str() ));
					if( ( index >= VDOutputCount ) || !isdigit( cmd[0] ) )
					{
						cout << "Invalid selection" << endl;
						continue;
					}
					modifySyncOutput( ioss.VDOutput( index ) );
				}
				break;
			case 2:
				displayPropertyData( ioss.syncOutputMode );
				modifyPropertyValue( ioss.syncOutputMode );
			default:
				break;
			}
		}
	}
	else
	{
		cout << "HD and VD output signals are not supported by this device." << endl;
	}

	const unsigned int outputCount = ioss.getOutputCount();
	if( outputCount > 0 )
	{
		// show how to define and undefine certain output signals for frame grabber devices
		OutputSignalGeneratorFrameGrabber osg(pDev);
	}
}

//-----------------------------------------------------------------------------
int main( int /*argc*/, char* /*argv*/[] )
//-----------------------------------------------------------------------------
{
	DeviceManager devMgr;
	Device* pDev = getDeviceFromUserInput( devMgr );
	if( !pDev )
	{
		cout << "Unable to continue!";
		cout << "Press [ENTER] to end the application" << endl;
		cin.get();
		return 0;
	}

	if( pDev->family.read() == "mvBlueFOX" )
	{
		mvBlueFOXIOAccess( pDev );
	}
	else if( pDev->family.read() == "mvBlueCOUGAR" )
	{
		mvBlueCOUGARIOAccess( pDev );
	}
	else if( pDev->deviceClass.read() == dcFrameGrabber )
	{
		frameGrabberIOAccess( pDev );
	}
	else
	{
		cout << "Device " << pDev->serial.read() << "(" << pDev->product << ") is not supported by this sample" << endl;
		cout << "Press [ENTER] to end the application" << endl;
		cin.get();
		return 0;
	}

	cout << "Press [ENTER] to end the application" << endl;
	cin.get();

	return 0;
}
