//-----------------------------------------------------------------------------
// NOTE: Sample only for linux side cause of the used select!
//-----------------------------------------------------------------------------
#ifndef linux
#	error Sample only for linux side!!
#endif	// linux
#include <stdio.h>
#include <unistd.h>
#include <iostream>
#include <apps/Common/exampleHelper.h>
#include <mvIMPACT_CPP/mvIMPACT_acquire.h>

#ifdef MALLOC_TRACE
#	include <mcheck.h>
#endif	// MALLOC_TRACE

#define PRESS_A_KEY_AND_RETURN			\
	cout << "Press a key..." << endl;	\
	getchar(); \
	return 0;

using namespace std;
using namespace mvIMPACT::acquire;

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

//-----------------------------------------------------------------------------
unsigned int liveLoop( Device* pDev, bool boStoreFrames, const string& settingName, bool boSingleShotMode )
//-----------------------------------------------------------------------------
{
	cout << " == " << __FUNCTION__ << " - establish access to the statistic properties...." << endl;
	// establish access to the statistic properties
	Statistics statistics( pDev );
	cout << " == " << __FUNCTION__ << " - create an interface to the device found...." << endl;
	// create an interface to the device found
	FunctionInterface fi( pDev );

	if( !settingName.empty() )
	{
		cout << "Trying to load setting " << settingName << "..." << endl;
		int result = fi.loadSetting( settingName );
		if( result != DMR_NO_ERROR )
		{
			cout << "loadSetting( \"" << settingName << "\" ); call failed: " << ImpactAcquireException::getErrorCodeAsString( result ) << endl;
		}
	}

#if 0
	// if running mvBlueFOX on an embedded system (e.g. ARM) with USB 1.1 it may be necessary to change
	// a few settings and timeouts like this:

	// get other settings
	SettingsBlueFOX setting( pDev );

	// set request timeout higher because USB 1.1 on ARM is soooo slow
	setting.cameraSetting.imageRequestTimeout_ms.write( 5000 );
	// use on Demand mode
	setting.cameraSetting.triggerMode.write( ctmOnDemand );
#endif

#if 0
	// this section contains special settings that might be interesting for mvBlueCOUGAR or mvBlueLYNX-M7
	// related embedded devices
	CameraSettingsBlueCOUGAR cs(pDev);
	int maxWidth = cs.aoiWidth.read( plMaxValue );
	cs.aoiWidth.write( maxWidth );
	//cs.autoGainControl.write( agcOff );
	//cs.autoExposeControl.write( aecOff );
	//cs.exposeMode.write( cemOverlapped );
	//cs.pixelClock_KHz.write( cpc40000KHz );
	//cs.expose_us.write( 5000 );
#endif

	// If this is color sensor, we will NOT convert the Bayer data into a RGB image as this
	// will cost a lot of time on an embedded system
	ImageProcessing ip(pDev);
	if( ip.colorProcessing.isValid() )
	{
		ip.colorProcessing.write( cpmRaw );
	}

	SystemSettings ss(pDev);
	// Prefill the capture queue with ALL buffers currently available. In case the acquisition engine is operated
	// manually, buffers can only be queued when they have been queued before the acquisition engine is started as well.
	// Even though there can be more then 1, for this sample we will work with the default capture queue
	int requestResult = DMR_NO_ERROR;
	int requestCount = 0;

	if( boSingleShotMode )
	{
		fi.imageRequestSingle();
		++requestCount;
	}
	else
	{
		while( ( requestResult = fi.imageRequestSingle() ) == DMR_NO_ERROR )
		{
			++requestCount;
		}
	}

	if( requestResult != DEV_NO_FREE_REQUEST_AVAILABLE )
	{
		cout << "Last result: "<< requestResult << "(" << ImpactAcquireException::getErrorCodeAsString( requestResult ) << "), ";
	}
	cout << requestCount << " buffers requested";

	if( ss.requestCount.isConstDefined( plMaxValue ) )
	{
		cout << ", max request count: " << ss.requestCount.read( plMaxValue );
	}
	cout << endl;

	const bool boManualAcquisitionEngineControl = pDev->acquisitionStartStopBehaviour.isValid() && ( pDev->acquisitionStartStopBehaviour.read() == assbUser );
	if( boManualAcquisitionEngineControl )
	{
		cout << "Manual start/stop of acquisition engine requested." << endl;
		const int startResult = fi.acquisitionStart();
		cout << "Result of start: " << startResult << "("
			<< ImpactAcquireException::getErrorCodeAsString( startResult ) << ")" << endl;
	}
	cout << "Press <<ENTER>> to end the application!!" << endl;

	// run thread loop
	const Request* pRequest = 0;
	const unsigned int timeout_ms = 8000;	// USB 1.1 on an embedded system needs a large timeout for the first image
	int requestNr = -1;
	bool boLoopRunning = true;
	unsigned int cnt = 0;
	while( boLoopRunning )
	{
		// wait for results from the default capture queue
		requestNr = fi.imageRequestWaitFor( timeout_ms );
		if( fi.isRequestNrValid( requestNr ) )
		{
			pRequest = fi.getRequest( requestNr );
			if( fi.isRequestOK( pRequest ) )
			{
				++cnt;
				// here we can display some statistical information every 100th image
				if( cnt%100 == 0 )
				{
					cout << cnt << ": Info from " << pDev->serial.read()
						<< ": " << statistics.framesPerSecond << ", "
						<< statistics.errorCount << ", " << statistics.captureTime_s <<" Image count: " << cnt 
						<< " (dimensions: " << pRequest->imageWidth.read() << "x" << pRequest->imageHeight.read() << ", format: " << pRequest->imagePixelFormat.readS();
					if( pRequest->imageBayerMosaicParity.read() != bmpUndefined )
					{
						cout << ", " << pRequest->imageBayerMosaicParity.name() << ": " << pRequest->imageBayerMosaicParity.readS();
					}
					cout << "), line pitch: " << pRequest->imageLinePitch.read() << endl;
					if( boStoreFrames )
					{
						ostringstream oss;
						oss << "Image" << cnt << "." << pRequest->imageWidth.read() << "x" << pRequest->imageHeight.read() << "." << pRequest->imagePixelFormat.readS();
						if( pRequest->imageBayerMosaicParity.read() != bmpUndefined )
						{
							oss << "(BayerPattern=" << pRequest->imageBayerMosaicParity.readS() << ")";
						}
						oss << ".raw";
						FILE* fp = fopen( oss.str().c_str(), "wb" );
						if( fp )
						{
							fwrite( pRequest->imageData.read(), pRequest->imageSize.read(), 1, fp );
							fclose( fp );
						}
					}
				}
			}
			else
			{
				cout << "*** Error: A request has been returned with the following result: " << pRequest->requestResult << endl;
			}

			// this image has been displayed thus the buffer is no longer needed...
			fi.imageRequestUnlock( requestNr );
			// send a new image request into the capture queue
			fi.imageRequestSingle();
			if( boManualAcquisitionEngineControl && boSingleShotMode )
			{
				const int startResult = fi.acquisitionStart();
				if( startResult != DMR_NO_ERROR )
				{
					cout << "Result of start: " << startResult << "("
						<< ImpactAcquireException::getErrorCodeAsString( startResult ) << ")" << endl;
				}
			}
		}
		else
		{
			cout << "*** Error: Result of waiting for a finished request: " << requestNr << "("
				<< ImpactAcquireException::getErrorCodeAsString( requestNr ) << "). Timeout value too small?" << endl;
		}

		boLoopRunning = waitForInput( 0, STDOUT_FILENO ) == 0 ? true : false; // break by STDIN
	}

	if( boManualAcquisitionEngineControl && !boSingleShotMode )
	{
		const int stopResult = fi.acquisitionStop();
		cout << "Manually stopping acquisition engine. Result: " << stopResult << "("
			<< ImpactAcquireException::getErrorCodeAsString( stopResult ) << ")" << endl;
	}
	cout << " == " << __FUNCTION__ << " - free resources...." << endl;
	// free resources
	fi.imageRequestReset( 0, 0 );
	return 0;
}

//-----------------------------------------------------------------------------
int main( int argc, char* argv[] )
//-----------------------------------------------------------------------------
{
#ifdef MALLOC_TRACE
	mtrace();
#endif	// MALLOC_TRACE
	cout << " ++ starting application...." << endl;

	bool boStoreFrames = false;
	string settingName;
	int width = -1;
	int height = -1;
	string pixelFormat;
	string acquisitionMode;
	string deviceSerial;
	for( int i=1; i<argc; i++ )
	{
		string arg(argv[i]);
		if( string( argv[i] ) == "-sf" )
		{
			boStoreFrames = true;
		}
		else if( arg.find( "-a" ) == 0 )
		{
			acquisitionMode = arg.substr( 2 );
		}
		else if( arg.find( "-h" ) == 0 )
		{
			height = atoi( arg.substr( 2 ).c_str() );
		}
		else if( arg.find( "-p" ) == 0 )
		{
			pixelFormat = arg.substr( 2 );
		}
		else if( arg.find( "-s" ) == 0 )
		{
			deviceSerial = arg.substr( 2 );
		}
		else if( arg.find( "-w" ) == 0 )
		{
			width = atoi( arg.substr( 2 ).c_str() );
		}
		else
		{
			// try to load this setting later on...
			settingName = string(argv[1]);
		}
	}

	if( argc <= 1 )
	{
		cout << "Available command line parameters:" << endl
			<< endl
			<< "-sf to store every 100th frame in raw format" << endl
			<< "-a<mode> to set the acquisition mode" << endl
			<< "-h<height> to set the AOI width" << endl
			<< "-p<pixelFormat> to set the pixel format" << endl
			<< "-s<serialNumber> to pre-select a certain device. If this device can be found no further user interaction is needed" << endl
			<< "-w<width> to set the AOI width" << endl
			<< "any other string will be interpreted as a name of a setting to load" << endl;
	}

	DeviceManager devMgr;
	Device* pDev = 0;
	if( !deviceSerial.empty() )
	{
		pDev = devMgr.getDeviceBySerial( deviceSerial );
		if( pDev )
		{
			switchFromGenericToGenICamInterface( pDev );
		}
	}
	if( !pDev )
	{
		pDev = getDeviceFromUserInput( devMgr );
	}
	if( pDev == 0 )
	{
		cout << "Unable to continue!";
		PRESS_A_KEY_AND_RETURN
	}

	// create an interface to the first MATRIX VISION device with the serial number sDevSerial
	if( pDev )
	{
		cout << "Initialising device: " << pDev->serial.read() << ". This might take some time..." << endl
			<< "Using interface layout '" << pDev->interfaceLayout.readS() << "'." << endl;
		try
		{
			pDev->open();
			switch( pDev->interfaceLayout.read() )
			{
			case dilGenICam:
				{
					DeviceComponentLocator locator(pDev, dltSetting, "Base");
					locator.bindSearchBase( locator.searchbase_id(), "Camera/GenICam" );
					PropertyI64 w, h, pf, am;
					locator.bindComponent( w, "Width" );
					locator.bindComponent( h, "Height" );
					locator.bindComponent( pf, "PixelFormat" );
					locator.bindComponent( am, "AcquisitionMode" );
					if( width > 0 )
					{
						w.write( width );
					}
					if( height > 0 )
					{
						h.write( height );
					}
					if( !pixelFormat.empty() )
					{
						pf.writeS( pixelFormat );
					}
					if( !acquisitionMode.empty() )
					{
						am.writeS( acquisitionMode );
					}
					acquisitionMode = am.readS();
					cout << "Device set up to " << pf.readS() << " " << w.read() << "x" << h.read() << endl;
				}
				break;
			case dilDeviceSpecific:
				{
					DeviceComponentLocator locator(pDev, dltSetting, "Base");
					locator.bindSearchBase( locator.searchbase_id(), "Camera/Aoi" );
					PropertyI w, h;
					locator.bindComponent( w, "W" );
					locator.bindComponent( h, "H" );
					if( width > 0 )
					{
						w.write( width );
					}
					if( height > 0 )
					{
						h.write( height );
					}
					cout << "Device set up to " << w.read() << "x" << h.read() << endl;
				}
				break;
			default:
				break;
			}
		}
		catch( ImpactAcquireException& e )
		{
			// this e.g. might happen if the same device is already opened in another process...
			cout << "*** " << __FUNCTION__ << " - An error occurred while opening the device " << pDev->serial.read()
				<< "(error code: " << e.getErrorCode() << ", " << e.getErrorCodeAsString() << "). Press any key to end the application..." << endl;
			PRESS_A_KEY_AND_RETURN
		}

		// start the execution of the 'live' loop.
		liveLoop( pDev, boStoreFrames, settingName, acquisitionMode == "SingleFrame" );
		cout << " == Will exit...." << endl;
		pDev->close();
		// do NOT delete pDev here! It will be destroyed automatically when the device manager (devMgr) is destroyed.
		// There is also no real need to close the device for the same reasons. Once the last instance of 'DeviceManager'
		// objects moves out of scope all devices open in the current process context will be closed automatically.
	}
	cout << " -- ending application...." << endl;

	return 0;
}
