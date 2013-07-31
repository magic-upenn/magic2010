#ifdef _MSC_VER	// is Microsoft compiler?
#	if _MSC_VER < 1300	// is 'old' VC 6 compiler?
#		pragma warning( disable : 4786 ) // 'identifier was truncated to '255' characters in the debug information'
#	endif // #if _MSC_VER < 1300
#endif // #ifdef _MSC_VER
#include <iostream>
#include <algorithm>
#include <map>
#include <apps/Common/exampleHelper.h>
#include <mvIMPACT_CPP/mvIMPACT_acquire.h>
#ifndef __linux__
#	include <mvDisplay/Include/mvDisplayWindow.h>
#else
	typedef void* HDISP;
	typedef void TDisp;
#endif // __linux__

using namespace mvIMPACT::acquire;
using namespace std;

typedef map<string, Property> StringPropMap;

//-----------------------------------------------------------------------------
void populatePropertyMap( StringPropMap& m, ComponentIterator it, const string& currentPath = "" )
//-----------------------------------------------------------------------------
{
	while( it.isValid() )
	{
		string fullName( currentPath );
		if( fullName != "" )
		{
			fullName += "/";
		}
		fullName += it.name();
		if( it.isList() )
		{
			populatePropertyMap( m, it.firstChild(), fullName );
		}
		else if( it.isProp() )
		{
			m.insert( make_pair( fullName, Property( it ) ) );
		}
		++it;
		// method object will be ignored...
	}
}

//-----------------------------------------------------------------------------
void singleCapture( const FunctionInterface& fi, TDisp* pDisp, int maxWaitTime_ms )
//-----------------------------------------------------------------------------
{
	// send a request to the default request queue of the device and
	// wait for the result.
	fi.imageRequestSingle();
	// wait for the image send to the default capture queue
	int requestNr = fi.imageRequestWaitFor( maxWaitTime_ms );

	// check if the image has been captured without any problems
	if( fi.isRequestNrValid( requestNr ) )
	{
		const Request* pRequest = fi.getRequest( requestNr );
		if( fi.isRequestOK( pRequest ) )
		{
			// everything went well. Display the result...
#ifndef __linux__
			mvDispSetImage( pDisp, pRequest->imageData.read(), pRequest->imageWidth.read(), pRequest->imageHeight.read(), pRequest->imagePixelPitch.read()*8, pRequest->imageLinePitch.read() );
			mvDispUpdate( pDisp );
#else
			cout << "Image captured(" << pRequest->imageWidth.read() << "x" << pRequest->imageHeight.read() << ")" << endl;
			// Workaround to avoid compiler warning
			pDisp = pDisp;
#endif	// __linux__
		}
		else
		{
			cout << "A request has been returned, but the acqusition was not successful. Reason: " << pRequest->requestResult.readS() << endl;
		}
		// ... unlock the request again, so that the driver can use it again
		fi.imageRequestUnlock( requestNr );
	}
	else
	{
		cout << "The acquisition failed: " << ImpactAcquireException::getErrorCodeAsString( requestNr ) << endl;
	}
	// in any case clear the queue to have consistent behaviour the next time this function gets called
	// as otherwise an image not ready yet might be returned directly when this function gets called the next time
	fi.imageRequestReset( 0, 0 );
	// extract and unlock all requests that are now returned as 'aborted'
	while( ( requestNr = fi.imageRequestWaitFor( 0 ) ) >= 0 )
	{
		fi.imageRequestUnlock( requestNr );
	}
}

//-----------------------------------------------------------------------------
bool isDeviceSupportedBySample( const Device* const pDev )
//-----------------------------------------------------------------------------
{
	if( !pDev->interfaceLayout.isValid() )
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

	cout << "This sample is meant for devices that support the GenICam interface layout only. Other devices might be installed" << endl
		<< "but won't be recognized by the application." << endl
		<< endl;

	Device* pDev = getDeviceFromUserInput( devMgr, isDeviceSupportedBySample );
	if( !pDev )
	{
		cout << "Unable to continue!";
		cout << "Press [ENTER] to end the application" << endl;
		cin.get();
		return 0;
	}

	cout << "Initialising the device. This might take some time..." << endl;
	try
	{
		pDev->interfaceLayout.write( dilGenICam );
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
	// create a function interface to the device
	FunctionInterface fi( pDev );

#ifndef __linux__
	// initialise a display window
	HDISP hDisp = mvInitDisplayWindow( "mvIMPACT_acquire sample" );
	TDisp* pDisp = mvGetDisplayStructure( hDisp );
	mvShowDisplayWindow( hDisp );
#else
	TDisp* pDisp = 0;
	// Workaround to avoid compiler warning
	pDisp = pDisp;
#endif	// __linux__

	// obtain all the settings related properties available for this device
	// Only work with the 'Base' setting. For more information please refer to the manual (working with settings)
	StringPropMap propertyMap;
	DeviceComponentLocator locator(pDev, dltSetting, "Base");
	populatePropertyMap( propertyMap, ComponentIterator(locator.searchbase_id()).firstChild() );
	locator = DeviceComponentLocator(pDev, dltRequest);
	populatePropertyMap( propertyMap, ComponentIterator(locator.searchbase_id()).firstChild() );
	locator = DeviceComponentLocator(pDev, dltSystemSettings);
	populatePropertyMap( propertyMap, ComponentIterator(locator.searchbase_id()).firstChild(), string("SystemSettings") );
	locator = DeviceComponentLocator(pDev, dltInfo);
	populatePropertyMap( propertyMap, ComponentIterator(locator.searchbase_id()).firstChild(), string("Info") );
	populatePropertyMap( propertyMap, ComponentIterator(pDev->hDev()).firstChild(), string("Device") );
	string cmd;
	int timeout_ms = 500;
	bool boRun = true;
	while( boRun )
	{
		cout << "enter quit, snap, list, help or the name of the property you want to modify followed by [ENTER]: ";
		cin >> cmd;

		if( cmd == "snap" )
		{
			singleCapture( fi, pDisp, timeout_ms );
		}
		else if( cmd == "list" )
		{
			for_each( propertyMap.begin(), propertyMap.end(), DisplayProperty() );
		}
		else if( cmd == "help" )
		{
			cout << "quit: terminates the sample" << endl
				<< "snap: takes and displays one image with the current settings" << endl
				<< "list: displays all properties available for this device" << endl
				<< "help: displays this help text" << endl
				<< "timeout: set a new timeout(in ms) used as a max. timeout to wait for an image" << endl
				<< "the full name of a property must be specified" << endl;
		}
		else if( cmd == "quit" )
		{
			boRun = false;
			continue;
		}
		else if( cmd == "timeout" )
		{
			cout << "Enter the new timeout to be passed to the imageRequestWaitFor function: ";
			cin >> timeout_ms;
		}
		else
		{
			StringPropMap::const_iterator it = propertyMap.find( cmd );
			if( it == propertyMap.end() )
			{
				cout << "unknown command or property" << endl;
			}
			else
			{
				displayPropertyData( it->second );
				if( it->second.hasDict() )
				{
					cout << "This function expects the string representation as input!" << endl;
				}
				modifyPropertyValue( it->second );
			}
		}
	}

#ifndef __linux__
	// free resources
	mvDestroyImageWindow( hDisp );
#endif	// __linux__
	return 0;
}
