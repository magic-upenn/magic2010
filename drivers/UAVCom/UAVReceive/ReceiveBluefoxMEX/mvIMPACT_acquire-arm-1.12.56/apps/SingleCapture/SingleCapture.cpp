#ifdef _MSC_VER	// is Microsoft compiler?
#	if _MSC_VER < 1300	// is 'old' VC 6 compiler?
#		pragma warning( disable : 4786 ) // 'identifier was truncated to '255' characters in the debug information'
#	endif // #if _MSC_VER < 1300
#endif // #ifdef _MSC_VER
#include <iostream>
#include <apps/Common/exampleHelper.h>
#include <mvIMPACT_CPP/mvIMPACT_acquire.h>
#ifdef _WIN32
#	include <mvDisplay/Include/mvDisplayWindow.h>
#endif // #ifdef _WIN32

using namespace mvIMPACT::acquire;
using namespace std;

#ifdef linux
#	define NO_DISPLAY
#else
#	undef NO_DISPLAY
#endif

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

	try
	{
		pDev->open();
	}
	catch( const ImpactAcquireException& e )
	{
		// this e.g. might happen if the same device is already opened in another process...
		cout << "An error occurred while opening the device(error code: " << e.getErrorCode() << "). Press [ENTER] to end the application..." << endl;
		cout << "Press [ENTER] to end the application" << endl;
		cin.get();
		return 0;
	}

	FunctionInterface fi( pDev );

	// send a request to the default request queue of the device and wait for the result.
	fi.imageRequestSingle();
	const int iMaxWaitTime_ms = 8000;   // USB 1.1 on an embedded system needs a large timeout for the first image.
	// wait for results from the default capture queue.
	int requestNr = fi.imageRequestWaitFor( iMaxWaitTime_ms );

	// check if the image has been captured without any problems.
	if( !fi.isRequestNrValid( requestNr ) )
	{
			// If the error code is -2119(DEV_WAIT_FOR_REQUEST_FAILED), the documentation will provide 
			// additional information under TDMR_ERROR in the interface reference
			cout << "imageRequestWaitFor failed (" << requestNr << ", " << ImpactAcquireException::getErrorCodeAsString( requestNr ) << ")"
				 << ", timeout value too small?" << endl;
		return 0;
	}

	const Request* pRequest = fi.getRequest( requestNr );
	if( !fi.isRequestOK( pRequest ) )
	{
		cout << "Error: " << pRequest->requestResult.readS() << endl;
		// if the application wouldn't terminate at this point this buffer HAS TO be unlocked before
		// it can be used again as currently it is under control of the user. However terminating the application
		// will free the resources anyway thus the call
		// fi.imageRequestUnlock( requestNr );
		// can be omitted here.
		return 0;
	}

#ifndef NO_DISPLAY
	cout << "Please note that there will be just one refresh for the display window, so if it is" << endl
		 << "hidden under another window the result will not be visible." << endl;
	// everything went well. Display the result
	// initialise display window
	HDISP hDisp = mvInitDisplayWindow( "mvIMPACT_acquire sample" );
	mvShowDisplayWindow( hDisp );
	// tell the display were to find the data
	TDisp* pDisp = mvGetDisplayStructure( hDisp );
	mvDispSetImage( pDisp, pRequest->imageData.read(), pRequest->imageWidth.read(), pRequest->imageHeight.read(), pRequest->imagePixelPitch.read()*8, pRequest->imageLinePitch.read() );
	mvDispUpdate( pDisp );
#endif // NO_DISPLAY
	cout << "Image captured( " << pRequest->imagePixelFormat.readS() << " " << pRequest->imageWidth.read() << "x" << pRequest->imageHeight.read() << " )" << endl;
	// unlock the buffer to let the driver know that you no longer need this buffer.
	fi.imageRequestUnlock( requestNr );

	cout << "Press [ENTER] to end the application" << endl;
	cin.get();
#ifndef NO_DISPLAY
	// free resources
	mvDestroyImageWindow( hDisp );
#endif // NO_DISPLAY
	return 0;
}
