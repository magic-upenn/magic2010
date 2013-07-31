#include <apps/Common/exampleHelper_C.h>
#include <mvDeviceManager/Include/mvDeviceManager.h>
#include <stdio.h>
#include <stdlib.h>
#ifdef _WIN32
#	include <conio.h>
#	include <mvDisplay/Include/mvDisplayWindow.h>
#	include <process.h>
#	include <windows.h>
#	define USE_MV_DISPLAY_LIB // only available for Windows
#	define LIVE_LOOP_CALL __stdcall
#elif defined(linux)
#	include <string.h>
#	include <sys/socket.h>
#	include <unistd.h>
#	define LIVE_LOOP_CALL
#	if defined(__x86_64__) || defined(__powerpc64__) // -m64 makes GCC define __powerpc64__
		typedef uint64_t UINT_PTR;
#	elif defined(__i386__) || defined(__arm__) || defined(__powerpc__) // and -m32 __powerpc__
		typedef uint32_t UINT_PTR;
#	else
#		error unsupported target platform
#	endif
#else
#	error unsupported target platform
#endif // #ifdef _WIN32

#define BUF_SIZE (512) // should always be enough, but could be done nicer by checking if buffer to small is returned from a function and then perform a re-allocation...
#define MAX_REQUESTS (4)

static int g_boTerminated = 0;

//-----------------------------------------------------------------------------
typedef struct CaptureParameter
//-----------------------------------------------------------------------------
{
	HDRV	hDrv;
#ifdef USE_MV_DISPLAY_LIB
	HDISP	hDisp;
#endif // #ifdef USE_MV_DISPLAY_LIB
} CaptureParameter;

#ifdef linux
	//-----------------------------------------------------------------------------
	// returns 0 if timeout, else 1
	unsigned waitForInput( int maxwait_sec, int fd )
	//-----------------------------------------------------------------------------
	{
		fd_set rfds;
		struct timeval tv;

		FD_ZERO(&rfds);
		FD_SET(fd, &rfds);

		tv.tv_sec = maxwait_sec ;
		tv.tv_usec = 0;

		return select( fd+1, &rfds, NULL, NULL, &tv );
	}
#endif // #ifdef linux

//-----------------------------------------------------------------------------
void checkDigitalIO_common( HDRV hDrv )
//-----------------------------------------------------------------------------
{
	HOBJ				hDigitalPins, hObj;
	unsigned int		pinCount;
	TPROPHANDLING_ERROR objResult;
	char				buf[BUF_SIZE];

	hDigitalPins = getDriverList( hDrv, "DigitalInputs", 0, dmltIOSubSystem );
	if( hDigitalPins == INVALID_ID )
	{
		printf( "Can't detect digital inputs. Test skipped.\n" );
	}
	else
	{
		objResult = OBJ_GetElementCount( hDigitalPins, &pinCount );
		if( objResult == PROPHANDLING_NO_ERROR )
		{
			objResult = OBJ_GetFirstChild( hDigitalPins, &hObj );
			while( ( objResult == PROPHANDLING_NO_ERROR ) && ( (short)hObj != INVALID_ID ) )
			{
				objResult |= OBJ_GetName( hObj, buf, BUF_SIZE );
				printf( "pin %s detected (handle: 0x%x).\n", buf, hObj );
				objResult |= OBJ_GetNextSibling( hObj, &hObj );
			}
		}
	}

	hDigitalPins = getDriverList( hDrv, "DigitalOutputs", 0, dmltIOSubSystem );
	if( hDigitalPins == INVALID_ID )
	{
		printf( "Can't detect digital outputs. Test skipped.\n" );
	}
	else
	{
		objResult = OBJ_GetElementCount( hDigitalPins, &pinCount );
		if( objResult == PROPHANDLING_NO_ERROR )
		{
			objResult = OBJ_GetFirstChild( hDigitalPins, &hObj );
			while( ( objResult == PROPHANDLING_NO_ERROR ) && ( (short)hObj != INVALID_ID ) )
			{
				objResult |= OBJ_GetName( hObj, buf, BUF_SIZE );
				printf( "pin %s detected (handle: 0x%x).\n", buf, hObj );
				objResult |= OBJ_GetNextSibling( hObj, &hObj );
			}
		}
	}
}

//-----------------------------------------------------------------------------
// this function will only work correctly for the mvBlueFOX as this stuff is
// highly device specific. Please look in the mvIMPACT_acquire.h file in the 
// source code of the classes IOSubSystemBlueFOX or IOSubSystemFrameGrabber
// how to obtain handles to the digital inputs and outputs for various devices
void checkDigitalIO_mvBlueFOX( HDRV hDrv )
//-----------------------------------------------------------------------------
{
	HOBJ				hPropDigitalInputs, hPropDigitalOutputs;
	unsigned int		noOfDigitalPins, i;
	TPROPHANDLING_ERROR objResult;
	int					value;

	hPropDigitalInputs = getIOSubSystemProp( hDrv, "DigitalInputs" );
	if( hPropDigitalInputs == INVALID_ID )
	{
		printf( "Can't detect digital inputs. Test skipped.\n" );
	}
	else
	{
		objResult = OBJ_GetValCount( hPropDigitalInputs, &noOfDigitalPins );
		if( objResult == PROPHANDLING_NO_ERROR )
		{
			for( i=0; i<noOfDigitalPins; i++ )
			{
				OBJ_GetI( hPropDigitalInputs, &value, i );
				printf( "pin %d: %d\n", i, value );
			}
		}
	}

	hPropDigitalOutputs = getIOSubSystemProp( hDrv, "DigitalOutputs" );
	if( hPropDigitalOutputs == INVALID_ID )
	{
		printf( "Can't detect digital outputs. Test skipped.\n" );
	}
	else
	{
		objResult = OBJ_GetValCount( hPropDigitalOutputs, &noOfDigitalPins );
		if( objResult == PROPHANDLING_NO_ERROR )
		{
			for( i=0; i<noOfDigitalPins; i++ )
			{
				OBJ_SetI( hPropDigitalOutputs, 1, i );
				printf( "setting pin %d to high\n", i );
			}
		}
	}
}

//-----------------------------------------------------------------------------
void selectInputChannel( HDRV hDrv )
//-----------------------------------------------------------------------------
{
	HOBJ hVideoChannel;
	HOBJ hPinDescription;
	int maxChannel;
	int minChannel;
	int channel;
	TPROPHANDLING_ERROR result;
	char* pPinDescription;
	int run = 1;

	hVideoChannel = getSettingProp( hDrv, "Base", "Connector/VideoChannel" );
	hPinDescription = getSettingProp( hDrv, "Base", "Connector/PinDescription" );

	if( ( hVideoChannel == INVALID_ID ) || ( hPinDescription == INVALID_ID ) )
	{
		printf( "This device doesn't seem to offer multiple input channels.\n" );
		return;
	}

	if( ( result = OBJ_GetI( hVideoChannel, &maxChannel, PROP_MAX_VAL ) ) != PROPHANDLING_NO_ERROR )
	{
		printf( "Failed to read max value from property 'VideoChannel'. Error code: %d\n", result );
		return;
	}
	if( ( result = OBJ_GetI( hVideoChannel, &minChannel, PROP_MIN_VAL ) ) != PROPHANDLING_NO_ERROR )
	{
		printf( "Failed to read min value from property 'VideoChannel'. Error code: %d\n", result );
		return;
	}

	while( run )
	{
		if( ( result = OBJ_GetI( hVideoChannel, &channel, 0 ) ) != PROPHANDLING_NO_ERROR )
		{
			printf( "Failed to read current value from property 'VideoChannel'. Error code: %d\n", result );
		}
		if( ( result = getStringValue( hPinDescription, &pPinDescription, 0 ) ) != PROPHANDLING_NO_ERROR )
		{
			printf( "Failed to read current value from property 'PinDescription'. Error code: %d\n", result );
		}
		printf( "Current input channel: %d(%s) [min: %d, max: %d].\n", channel, pPinDescription, minChannel, maxChannel );
		free( pPinDescription );
		printf( "Please enter the desired input channel for running this sample and -1 to leave this loop: " );
		channel = getIntValFromSTDIn();
		if( channel == -1 )
		{
			run = 0;
			continue;
		}

		if( ( result = OBJ_SetI( hVideoChannel, channel, 0 ) ) != PROPHANDLING_NO_ERROR )
		{
			printf( "Failed to set value to property 'VideoChannel'. Error code: %d\n", result );
		}
	}
}

//-----------------------------------------------------------------------------
// this function will only work correctly for the mvBlueFOX as this stuff is
// highly device specific.
void longTimeIntegration_mvBlueFOX( CaptureParameter* pCapParams, int exposureTime_ms )
//-----------------------------------------------------------------------------
{
	int requestNr = INVALID_ID;
	TPROPHANDLING_ERROR propHandlingError = PROPHANDLING_NO_ERROR;
	TDMR_ERROR dmrError = DMR_NO_ERROR;
	ImageBuffer* pIB = 0;
	HDRV hDrv = pCapParams->hDrv;
#ifdef USE_MV_DISPLAY_LIB
	TDisp* pDisp = mvGetDisplayStructure( pCapParams->hDisp );
#endif // #ifdef USE_MV_DISPLAY_LIB
	HOBJ hPropTriggerMode = getSettingProp( hDrv, "Base", "TriggerMode" );
	HOBJ hPropTriggerSource = getSettingProp( hDrv, "Base", "TriggerSource" );
	HOBJ hPropImageRequestTimeout_ms = getSettingProp( hDrv, "Base", "ImageRequestTimeout_ms" );
	HOBJ hPropDigitalOutputs = getIOSubSystemProp( hDrv, "DigitalOutputs" );

	if( ( hPropTriggerMode == INVALID_ID ) || ( hPropTriggerSource == INVALID_ID ) ||
		( hPropImageRequestTimeout_ms == INVALID_ID ) || ( hPropDigitalOutputs == INVALID_ID ) )
	{
		printf( "Failed to obtain one or more features needed to configure the mvBlueFOX for user controlled long time integration mode.\n" );
		printf( "Handle values: 0x%x, 0x%x, 0x%x, 0x%x.\n", hPropTriggerMode, hPropTriggerSource, hPropImageRequestTimeout_ms, hPropDigitalOutputs );
		return;
	}

	if( ( propHandlingError = OBJ_SetI( hPropTriggerMode, ctmOnHighExpose, 0 ) ) != PROPHANDLING_NO_ERROR )
	{
		printf( "Failed to configure trigger mode(error: %d).\n", propHandlingError );
		return;
	}

	if( ( propHandlingError = OBJ_SetI( hPropTriggerSource, ctsDigOut0, 0 ) ) != PROPHANDLING_NO_ERROR )
	{
		printf( "Failed to configure trigger source(error: %d).\n", propHandlingError );
		return;
	}

	if( ( propHandlingError = OBJ_SetI( hPropImageRequestTimeout_ms, exposureTime_ms + 500, 0 ) ) != PROPHANDLING_NO_ERROR )
	{
		printf( "Failed to configure image request timeout(error: %d).\n", propHandlingError );
		return;
	}

	if( ( dmrError = DMR_ImageRequestSingle( hDrv, 0, 0 ) ) != DMR_NO_ERROR )
	{
		printf( "Failed to request an image(error: %d).\n", dmrError );
		return;
	}

	// switch on digital output 0
	if( ( propHandlingError = OBJ_SetI( hPropDigitalOutputs, 1, 0 ) ) != PROPHANDLING_NO_ERROR )
	{
		printf( "Failed to modify digital output(error: %d).\n", propHandlingError );
		return;
	}

#ifdef _WIN32
	Sleep( exposureTime_ms );
#else
	usleep( 1000 * exposureTime_ms );
#endif // #ifdef _WIN32

	// switch off digital output 0
	if( ( propHandlingError = OBJ_SetI( hPropDigitalOutputs, 0, 0 ) ) != PROPHANDLING_NO_ERROR )
	{
		printf( "Failed to modify digital output(error: %d).\n", propHandlingError );
		return;
	}

	// wait should return immediately as the exposure period has elapsed already
	dmrError = DMR_ImageRequestWaitFor( hDrv, 500, 0, &requestNr );
	if( dmrError == DMR_NO_ERROR )
	{
		if( ( dmrError = DMR_GetImageRequestBuffer( hDrv, requestNr, &pIB ) ) == DMR_NO_ERROR )
		{
#ifdef USE_MV_DISPLAY_LIB
			// display the captured image
			mvDispSetImage( pDisp, pIB->vpData, pIB->iWidth, pIB->iHeight, pIB->pChannels[0].iPixelPitch*8, pIB->pChannels[0].iLinePitch );
			mvDispUpdate( pDisp );
#endif // #ifdef USE_MV_DISPLAY_LIB
		}
		else
		{
			printf( "DMR_GetImageRequestBuffer: ERROR! Code %d\n", dmrError );
		}
		DMR_ImageRequestUnlock( hDrv, requestNr );
	}

	// restore previous values
	OBJ_RestoreDefault( hPropTriggerMode );
	OBJ_RestoreDefault( hPropTriggerSource );
	OBJ_RestoreDefault( hPropImageRequestTimeout_ms );
}

//-----------------------------------------------------------------------------
unsigned int LIVE_LOOP_CALL liveLoop( void* pData )
//-----------------------------------------------------------------------------
{
#ifdef USE_MV_DISPLAY_LIB
	TDisp*			pDisp;
#endif // #ifdef USE_MV_DISPLAY_LIB
	HDRV			hDrv;
	TDMR_ERROR		result;
	ImageBuffer*	pIB;
	RequestResult	ReqRes;
	int				i, frameCount;
	HOBJ			hPropFPS;
	HOBJ			hPropExpose_us;
	HOBJ			hPropWidth;
	double			fps;
	int				requestNr;
	int				lastRequestNr;
	int				expose_us;
	int				currentWidth;
	int				width;

	hDrv = ((CaptureParameter*)pData)->hDrv;
#ifdef USE_MV_DISPLAY_LIB
	pDisp = mvGetDisplayStructure( ((CaptureParameter*)pData)->hDisp );
#endif // #ifdef USE_MV_DISPLAY_LIB
	pIB = 0;
	frameCount = 0;
	fps = 0.0;
	expose_us = 10000;
	requestNr = -1;
	currentWidth = 0;
	width = 0;
	// we always have to keep at least 2 images as the display module might want to repaint the image, thus we
	// can free it unless we have a assigned the display to a new buffer.
	lastRequestNr = -1;

	// try to loacte the frames per second property
	if( ( hPropFPS = getStatisticProp( hDrv, "FramesPerSecond" ) ) == INVALID_ID )
	{
		printf( "Couldn't locate frames per second property! Unable to continue!\n" );
		return 0;
	}

	// try to locate the expose time property
	if( ( hPropExpose_us = getSettingProp( hDrv, "Base", "Expose_us" ) ) == INVALID_ID )
	{
		printf( "Couldn't locate expose property! Will not modify the exposure time!\n" );
	}

	// try to locate the Aoi/W property
	if( ( hPropWidth = getSettingProp( hDrv, "Base", "Camera/Aoi/W" ) ) == INVALID_ID )
	{
		printf( "Couldn't locate width property!\n" );
	}
	else
	{
		OBJ_GetI( hPropWidth, &width, 0 );
	}

	// prefill the default capture queue
	for( i=0; i<MAX_REQUESTS-1; i++ )
	{
		DMR_ImageRequestSingle( hDrv, 0, 0 );
	}

	// run thread loop
	while( !g_boTerminated )
	{
		// please note, that the value stored in the property 'ImageRequestTimeout_ms' specifies the
		// maximum time a request will remain in the queue. If no complete image has been taken until
		// then, RequestResult.result will contain 'rrTimeout', so to allow long wait times, this
		// property needs to be modified as well, as it's default is 2000 ms.
		// In this sample this can be achieved by calling 'getSettingProp( hDrv, "Base", "ImageRequestTimeout_ms" )'
		result = DMR_ImageRequestWaitFor( hDrv, 500, 0, &requestNr );
		if( result == DMR_NO_ERROR )
		{
			// check if the request contains a valid image
			result = DMR_GetImageRequestResultEx( hDrv, requestNr, &ReqRes, sizeof(ReqRes), 0, 0 );
			if( ( result == DMR_NO_ERROR ) && ( ReqRes.result == rrOK ) )
			{
				// display statistical information every 100th image
				frameCount = frameCount + 1;
				if( ( frameCount % 100 ) == 0 )
				{
					OBJ_GetF( hPropFPS, &fps, 0 );
					if( hPropExpose_us != INVALID_ID )
					{
						expose_us = ( ( expose_us + 10000 ) % 30000 ) + 10000;
						OBJ_SetI( hPropExpose_us, expose_us, 0 );
						printf( "current expose time(us): %d\n", expose_us );
					}
					if( hPropWidth != INVALID_ID )
					{
						OBJ_GetI( hPropWidth, &currentWidth, 0 );
						if( currentWidth == width )
						{
							currentWidth = width / 2;
						}
						else
						{
							currentWidth = width;
						}
						OBJ_SetI( hPropWidth, currentWidth, 0 );
					}
					printf( "frames per second: %.5f.\n", fps );
				}
				if( ( result = DMR_GetImageRequestBuffer( hDrv, requestNr, &pIB ) ) == DMR_NO_ERROR )
				{
#ifdef USE_MV_DISPLAY_LIB
					// display the captured image
					mvDispSetImage( pDisp, pIB->vpData, pIB->iWidth, pIB->iHeight, pIB->pChannels[0].iPixelPitch*8, pIB->pChannels[0].iLinePitch );
					mvDispUpdate( pDisp );
#endif // #ifdef USE_MV_DISPLAY_LIB
					// do your processing here
				}
				else
				{
					printf( "DMR_GetImageRequestBuffer: ERROR! Code %d\n", result );
				}
			}
			else
			{
				// this can happen e.g. when a triggered acquisition timed out (missing trigger signal)
				// A request does not remain in teh queue forever, but is removed after the max. queue time has elapsed. This timeout
				// is defined by the 'ImageRequestTimeout_ms' property. If this timeout has elapsed and no
				// image has been captured, the RequestResult.result parameter will not contain 'rrOK', but the
				// request still needs to be unlocked for the driver as it has been returned to the user.
				printf( "DMR_GetImageRequestResult: ERROR! Return value: %d, request result: %d.\n", result, ReqRes.result );
			}
			if( lastRequestNr >= 0 )
			{
				// this image has been displayed thus the buffer is no longer needed...
				DMR_ImageRequestUnlock( hDrv, lastRequestNr );
			}
			lastRequestNr = requestNr;
			DMR_ImageRequestSingle( hDrv, 0, 0 );
		}
		else
		{
			printf( "DMR_ImageRequestWaitFor: ERROR! Code %d\n", result );
		}
#ifdef linux
		g_boTerminated = waitForInput( 0, STDOUT_FILENO ) == 0 ? 0 : 1; // break by STDIN
#endif // #ifndef _WIN32
	}

#ifdef USE_MV_DISPLAY_LIB
	// stop the display from showing freed memory
	mvDispSetImage( pDisp, 0, 0, 0, 0, 0 );
#endif // #ifdef USE_MV_DISPLAY_LIB
	// free the last potential locked request
	if( requestNr >= 0 )
	{
		DMR_ImageRequestUnlock( hDrv,  requestNr );
	}
	// clear the request queue
	printf( "DMR_ImageRequestReset: %d\n", DMR_ImageRequestReset( hDrv, 0, 0 ) );
	// extract and unlock all requests that are now returned as 'aborted'
	while( DMR_ImageRequestWaitFor( hDrv, 0, 0, &requestNr ) == DMR_NO_ERROR )
	{
		DMR_ImageRequestUnlock( hDrv, requestNr );
	}
	printf( "DMR_ReleaseImageRequestBufferDesc: %d\n", DMR_ReleaseImageRequestBufferDesc( &pIB ) );
	return 0;
}

//-----------------------------------------------------------------------------
void captureLoop( CaptureParameter* pCaptureParams )
//-----------------------------------------------------------------------------
{
#ifdef _WIN32
	HANDLE                     hThread = NULL;
	unsigned int               threadID = 0;
#endif // #ifdef _WIN32

	printf( "Press [ENTER] to end the continuous acquisition.\n" );
	g_boTerminated = 0;
#ifdef _WIN32
	hThread = (HANDLE)_beginthreadex( 0, 0, liveLoop, (LPVOID)(pCaptureParams), 0, &threadID);
	_getch();
	g_boTerminated = 1;
	WaitForSingleObject( hThread, INFINITE );
	CloseHandle( hThread );
#else
	liveLoop( pCaptureParams );
#endif // #ifdef _WIN32
}

//-----------------------------------------------------------------------------
int main( int argc, char* argv[] )
//-----------------------------------------------------------------------------
{
	HDMR             hDMR = INVALID_ID;
	HDRV             hDrv = INVALID_ID;
	HDEV             hDevice = INVALID_ID;
	TDMR_ERROR       result = DMR_NO_ERROR;
	CaptureParameter captureParameter;
	unsigned int     deviceCount = 0;
	unsigned int     i = 0;
	HOBJ             hPropSerial = INVALID_ID;
	HOBJ             hPropFamily = INVALID_ID;
	char*            pStringBuffer = NULL;
	unsigned int     deviceNumber = 0;
	HOBJ             hPropDeviceClass = INVALID_ID;
	int              deviceClass = dcGeneric;

	// get rid of warnings
	argc = argc;
	argv = argv;
	
	// try to initialise the library.
	if( ( result = DMR_Init( &hDMR ) ) != DMR_NO_ERROR )
	{
		printf( "DMR_Init failed (code: %d)\n", result );
		END_APPLICATION;
	}

	if( ( result = DMR_GetDeviceCount( &deviceCount ) ) != DMR_NO_ERROR )
	{
		printf( "DMR_GetDeviceCount failed (code: %d(%s))\n", result, DMR_ErrorCodeToString( result ) );
		END_APPLICATION;
	}

	if( deviceCount == 0 )
	{
		printf( "No MATRIX VISION mvIMPACT Acquire compliant device detected.\n" );
		END_APPLICATION;
	}

	printf( "%d MATRIX VISION mvIMPACT Acquire compliant devices detected.\n", deviceCount );
	for( i=0; i<deviceCount; i++ )
	{
		// try to get access to the device
		if( ( result = DMR_GetDevice( &hDevice, dmdsmSerial, "*", i, '*' ) ) != DMR_NO_ERROR )
		{
			printf( "DMR_GetDevice(%d) failed (code: %d(%s))\n", i, result, DMR_ErrorCodeToString( result ) );
			END_APPLICATION;
		}
		if( ( hPropSerial = getDeviceProp( hDevice, "Serial" ) ) == INVALID_ID )
		{
			printf( "Failed to obtain device serial property for device %d.\n", i );
			continue;
		}
		getStringValue( hPropSerial, &pStringBuffer, 0 );
		printf( "[%d]: %s.\n", i, pStringBuffer );
		free( pStringBuffer );
	}

	printf( "Please enter the number in front of the listed device followed by [ENTER] to open it: " );
	deviceNumber = getIntValFromSTDIn();

	// try to get access to the selected device
	if( ( result = DMR_GetDevice( &hDevice, dmdsmSerial, "*", deviceNumber, '*' ) ) != DMR_NO_ERROR )
	{
		printf( "DMR_GetDevice(%d) failed (code: %d(%s))\n", deviceNumber, result, DMR_ErrorCodeToString( result ) );
		printf( "DMR_Close: %d\n", DMR_Close() );
		END_APPLICATION;
	}

	if( ( hPropFamily = getDeviceProp( hDevice, "Family" ) ) == INVALID_ID )
	{
		printf( "Failed to obtain device family property for device %d.\n", i );
		END_APPLICATION;
	}
	getStringValue( hPropFamily, &pStringBuffer, 0 );

	// try to initialise this device
	if( ( result = DMR_OpenDevice( hDevice, &hDrv ) ) != DMR_NO_ERROR )
	{
		printf( "DMR_OpenDevice failed (code: %d)\n", result );
		printf( "DMR_Close: %d\n", DMR_Close() );
		END_APPLICATION;
	}

	if( OBJ_GetHandle( hDevice, "DeviceClass", &hPropDeviceClass ) == PROPHANDLING_NO_ERROR )
	{
		if( ( OBJ_GetI( hPropDeviceClass, &deviceClass, 0 ) == PROPHANDLING_NO_ERROR ) && ( deviceClass == dcFrameGrabber ) )
		{
			selectInputChannel( hDrv );
		}
	}

	// "Base" is the default setting, that always exists. Other settings can be created by deriving
	// a new setting from "Base" via DMR_CreateSetting()
	// try to locate the trigger mode and source properties. These properties will not be available for every device
	// as not every device will support external trigger signal inputs!
	modifyIntEnumProperty( hDrv, "Base", "TriggerMode" );
	modifyIntEnumProperty( hDrv, "Base", "TriggerSource" );

#ifdef USE_MV_DISPLAY_LIB
	// create a window to display the captured images
	captureParameter.hDisp = mvInitDisplayWindow( "ContinuousCapture sample(plain 'C')" );
	mvShowDisplayWindow( captureParameter.hDisp );
#endif // #ifdef USE_MV_DISPLAY_LIB
	captureParameter.hDrv = hDrv;

	if( strcmp( pStringBuffer, "mvBlueFOX" ) == 0 )
	{
		longTimeIntegration_mvBlueFOX( &captureParameter, 3000 );
		checkDigitalIO_mvBlueFOX( hDrv );
	}
	else
	{
		checkDigitalIO_common( hDrv );
	}
	free( pStringBuffer );
	pStringBuffer = 0;

	printf( "Press any key to end live acquisition.\n" );

	captureLoop( &captureParameter );

#ifdef USE_MV_DISPLAY_LIB
	mvDestroyImageWindow( captureParameter.hDisp );
#endif // #ifdef USE_MV_DISPLAY_LIB

	printf( "DMR_CloseDevice: %d\n", DMR_CloseDevice( hDrv, hDevice ) );
	printf( "DMR_Close: %d\n", DMR_Close() );
	END_APPLICATION;
}
