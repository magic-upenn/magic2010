#ifdef _MSC_VER         // is Microsoft compiler?
#	if _MSC_VER < 1300  // is 'old' VC 6 compiler?
#		pragma warning( disable : 4786 ) // 'identifier was truncated to '255' characters in the debug information'
#	endif // #if _MSC_VER < 1300
#endif // #ifdef _MSC_VER
#include <iostream>
#include <apps/Common/exampleHelper.h>
#ifdef __linux__
	typedef void* HDISP;
	typedef void TDisp;
#else
#	include <windows.h>
#	include <process.h>
#	include <mvDisplay/Include/mvDisplayWindow.h>
#endif // #ifdef __linux__
#include <mvIMPACT_CPP/mvIMPACT_acquire_GenICam.h>

using namespace std;
using namespace mvIMPACT::acquire;

static bool g_boTerminated = false;

//-----------------------------------------------------------------------------
struct ThreadParameter
//-----------------------------------------------------------------------------
{
	Device* pDev;
	TDisp*  pDisp;
	ThreadParameter( Device* p, TDisp* pD ) : pDev(p), pDisp(pD) {}
};

#ifdef __linux__
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
#endif // #ifdef __linux__

//-----------------------------------------------------------------------------
unsigned int DMR_CALL liveThread( void* pData )
//-----------------------------------------------------------------------------
{
	ThreadParameter* pThreadParam = reinterpret_cast<ThreadParameter*>(pData);

	// establish access to the statistic properties
	Statistics statistics(pThreadParam->pDev);
	// create an interface to the device found
	FunctionInterface fi(pThreadParam->pDev);

	// Send all requests to the capture queue. There can be more then 1 queue for some device, but for this sample
	// we will work with the default capture queue. If a device supports more then one capture or result
	// queue, this will be stated in the manual. If nothing is set about it, the device supports one
	// queue only. This loop will send all requests currently available to the driver. To modify the number of requests
	// modify the property 'requestCount' of an instance of the class 'mvIMPACT::acquire::SystemSettings' or the property
	// 'mvIMPACT::acquire::Device::defaultRequestCount' BEFORE opening the device.
	while( fi.imageRequestSingle() == DMR_NO_ERROR ) {};
	// and start the acquisition(this is prepare the driver for data capture and tell the device to start streaming data)
	const int acquisitionStartResult = fi.acquisitionStart();
	if( acquisitionStartResult != DMR_NO_ERROR )
	{
		cout << "Calling 'fi.acquisitionStart()' did return an error: " << acquisitionStartResult << "(" << ImpactAcquireException::getErrorCodeAsString( acquisitionStartResult ) << ")" << endl;
	}

	// run thread loop
	int requestNr = INVALID_ID;
	unsigned int cnt = 0;
	const unsigned int timeout_ms = 500;
	// we always have to keep at least 2 images as the display module might want to repaint the image, thus we
	// can free it unless we have a assigned the display to a new buffer.
	int lastRequestNr = INVALID_ID;
	while( !g_boTerminated )
	{
		// wait for results from the default capture queue
		requestNr = fi.imageRequestWaitFor( timeout_ms );
		if( fi.isRequestNrValid( requestNr ) )
		{
			const Request* pRequest = fi.getRequest( requestNr );
			if( fi.isRequestOK( pRequest ) )
			{
				// within this scope we have a valid buffer of data that can be an image or any other
				// chunk of data.
				++cnt;
				// here we can display some statistical information every 100th image
				if( cnt%100 == 0 )
				{
					cout << "Info from " << pThreadParam->pDev->serial.read()
						<< ": " << statistics.framesPerSecond << ", "
						<< statistics.errorCount << ", " << statistics.captureTime_s << endl;
				}
#ifdef __linux__
				cout << "Image captured(" << pRequest->imageWidth.read() << "x" << pRequest->imageHeight.read() << ")" << endl;
#else
				mvDispSetImage( pThreadParam->pDisp, pRequest->imageData.read(), pRequest->imageWidth.read(), pRequest->imageHeight.read(), pRequest->imagePixelPitch.read()*8, pRequest->imageLinePitch.read() );
				mvDispUpdate( pThreadParam->pDisp );
#endif	// #ifdef __linux__
			}
			else
			{
				cout << "Error: " << pRequest->requestResult.readS() << endl;
			}
			if( fi.isRequestNrValid( lastRequestNr ) )
			{
				// this image has been displayed thus the buffer is no longer needed...
				fi.imageRequestUnlock( lastRequestNr );
			}
			lastRequestNr = requestNr;
			// send a new image request into the capture queue
			fi.imageRequestSingle();
		}
		else
		{
			// If the error code is -2119(DEV_WAIT_FOR_REQUEST_FAILED), the documentation will provide
			// additional information under TDMR_ERROR in the interface reference
			cout << "imageRequestWaitFor failed (" << requestNr << ", " << ImpactAcquireException::getErrorCodeAsString( requestNr ) << ")"
				<< ", timeout value too small?" << endl;
		}
#ifdef __linux__
		g_boTerminated = waitForInput( 0, STDOUT_FILENO ) == 0 ? false : true; // break by STDIN
#endif // #ifdef __linux__
	}

	// and start the acquisition(this is tell the device to stop streaming data and stop the acquisition engine in the driver)
	const int acquisitionStopResult = fi.acquisitionStop();
	if( acquisitionStopResult != DMR_NO_ERROR )
	{
		cout << "Calling 'fi.acquisitionStop()' did return an error: " << acquisitionStopResult << "(" << ImpactAcquireException::getErrorCodeAsString( acquisitionStopResult ) << ")" << endl;
	}

#ifndef __linux__
	// stop the display from showing freed memory
	mvDispSetImage( pThreadParam->pDisp, 0, 0, 0, 0, 0 );
#endif // #ifndef __linux__

	// In this sample all the next lines are redundant as the device driver will be
	// closed now, but in a real world application a thread like this might be started
	// several times an then it becomes crucial to clean up correctly.

	// free the last potential locked request
	if( fi.isRequestNrValid( requestNr ) )
	{
		fi.imageRequestUnlock( requestNr );
	}
	// clear the request queue
	fi.imageRequestReset( 0, 0 );
	// extract and unlock all requests that are now returned as 'aborted'
	while( ( requestNr = fi.imageRequestWaitFor( 0 ) ) >= 0 )
	{
		cout << "Request " << requestNr << " did return with status " << fi.getRequest( requestNr )->requestResult.readS() << endl;
		fi.imageRequestUnlock( requestNr );
	}
	return 0;
}

//-----------------------------------------------------------------------------
// This function will allow to select devices that support the GenICam interface
// layout(these are devices, that are claim to be compliant with the GenICam standard)
// and that are bound to drivers that support the user controlled start and stop
// of the internal acquisition engine. Other devices will not be listed for
// selection as the code of the example relies on these features in the code.
bool isDeviceSupportedBySample( const Device* const pDev )
//-----------------------------------------------------------------------------
{
	if( !pDev->interfaceLayout.isValid() &&
		!pDev->acquisitionStartStopBehaviour.isValid() )
	{
		return false;
	}

	vector<pair<string, TDeviceInterfaceLayout> > dict;
	pDev->interfaceLayout.getTranslationDict( dict );
	if( dict.empty() )
	{
		return false;
	}

	vector<pair<string, TDeviceInterfaceLayout> >::size_type dictSize = dict.size();
	for( vector<pair<string, TDeviceInterfaceLayout> >::size_type i=0; i<dictSize; i++ )
	{
		if( dict[i].second == dilGenICam )
		{
			return true;
		}
	}

	return false;
}

//-----------------------------------------------------------------------------
int main( int /*argc*/, char* /*argv*/[] )
//-----------------------------------------------------------------------------
{
	DeviceManager devMgr;
	Device* pDev = getDeviceFromUserInput( devMgr, isDeviceSupportedBySample );
	if( !pDev )
	{
		cout << "Unable to continue!";
		cout << "Press [ENTER] to end the application" << endl;
		cin.get();
		return 1;
	}

	try
	{
		// features from 'mvIMPACT_CPP/mvIMPACT_acquire_GenICam.h' will only be available when the 'GenICam' interface
		// layout is used.
		pDev->interfaceLayout.write( dilGenICam );
		cout << "Interface layout of device " << pDev->serial.read() << "(" << pDev->product.read() << ") set to '" << pDev->interfaceLayout.readS() << "'." << endl << endl;
		// for devices that use a streaming based data transfer mechanism manually controlling the start and stop
		// of the data stream has some advantages. E.g. the user can pre-fill the acquisition engines buffer queue
		// with the desired number of buffers BEFORE the devices starts to send data, while in automatic mode the device
		// will be started when the first buffer is requested which might lead to an empty queue quickly when frame
		// rates are high.
		pDev->acquisitionStartStopBehaviour.write( assbUser );
		cout << "Acquisition start/stop behaviour(" << pDev->acquisitionStartStopBehaviour.docString() << ") of device " << pDev->serial.read() << "(" << pDev->product.read() << ") set to '" << pDev->acquisitionStartStopBehaviour.readS() << "'." << endl << endl;
		cout << "Initialising the device. This might take some time..." << endl << endl;
		pDev->open();
	}
	catch( const ImpactAcquireException& e )
	{
		// this e.g. might happen if the same device is already opened in another process...
		cout << "An error occurred while opening the device " << pDev->serial.read()
			<< "(error code: " << e.getErrorCodeAsString() << "). Press [ENTER] to end the application..." << endl;
		cin.get();
		return 1;
	}

	// now display some SFNC(Standard Feature Naming Convention) compliant features(see http://www.emva.org to find out more
	// about the standard and to download the latest SFNC document version)
	//
	// IMPORTANT:
	//
	// The SFNC unfortunately does NOT define numerical values for enumerations, thus a device independent piece of software
	// should use the enum-strings defined in the SFNC to ensure interoperability between devices. This is slightly slower
	// but should not cause problems in real world applications. When the device type AND GenICam XML file version is
	// guaranteed to be constant for a certain version of software, the driver internal code generator can be used to create
	// and interface header, that has numerical constants for enumerations as well. See device driver documentation under
	// 'Use Cases -> GenICam to mvIMPACT Acquire code generator' for details.
	mvIMPACT::acquire::GenICam::DeviceControl dc(pDev);
	displayPropertyDataWithValidation( dc.deviceVendorName, "DeviceVendorName" );
	cout << endl;
	displayPropertyDataWithValidation( dc.deviceModelName, "DeviceModelName" );
	cout << endl;

	// show the current exposure time allow the user to change it
	mvIMPACT::acquire::GenICam::AcquisitionControl ac(pDev);
	displayAndModifyPropertyDataWithValidation( ac.exposureTime, "ExposureTime" );

	// show the current pixel format, width and height and allow the user to change it
	mvIMPACT::acquire::GenICam::ImageFormatControl ifc(pDev);
	displayAndModifyPropertyDataWithValidation( ifc.pixelFormat, "PixelFormat" );
	displayAndModifyPropertyDataWithValidation( ifc.width, "Width" );
	displayAndModifyPropertyDataWithValidation( ifc.height, "Height" );

	// start the execution of the 'live' thread.
	cout << "Press [ENTER] to end the application" << endl;

#ifdef __linux__
	ThreadParameter threadParam(pDev, 0);
	liveThread( &threadParam );
#else
	// initialise display window
	// IMPORTANT: It's NOT save to create multiple display windows in multiple threads!!!
	string windowTitle( "mvIMPACT_acquire sample, Device " + pDev->serial.read() );
	HDISP hDisp = mvInitDisplayWindow( windowTitle.c_str() );
	mvShowDisplayWindow( hDisp );
	unsigned int dwThreadID;
	ThreadParameter threadParam(pDev, mvGetDisplayStructure( hDisp ));
	HANDLE hThread = (HANDLE)_beginthreadex( 0, 0, liveThread, (LPVOID)(&threadParam), 0, &dwThreadID);
	cin.get();
	g_boTerminated = true;
	WaitForSingleObject( hThread, INFINITE );
	CloseHandle( hThread );
	mvDestroyImageWindow( hDisp );
#endif	// #ifdef __linux__
	return 0;
}
