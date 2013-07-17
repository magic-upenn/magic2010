//-----------------------------------------------------------------------------
#ifndef exampleHelper_CH
#define exampleHelper_CH exampleHelper_CH
//-----------------------------------------------------------------------------
#include <mvDeviceManager/Include/mvDeviceManager.h>

#ifdef _WIN32
#	define GET_A_KEY _getch()
#else
#	define GET_A_KEY getchar()
#endif // #ifdef _WIN32

#define END_APPLICATION										\
	printf( "Press any key to end the application.\n" );	\
	GET_A_KEY;												\
	return 0;												\

int   getIntValFromSTDIn( void );
int   getPropI( HOBJ hProp, int index );
void  setPropI( HOBJ hProp, int value, int index );
void* getPropP( HOBJ hProp, int index );
void  setPropP( HOBJ hProp, void* value, int index );

HOBJ getDriverList( HDRV hDrv, const char* pName, const char* pAddListName, TDMR_ListType type );
HOBJ getDriverProperty( HDRV hDrv, const char* pPropName, const char* pAddListName, TDMR_ListType type );
HOBJ getDeviceProp( HDEV hDev, const char* pPropName );
HOBJ getInfoProp( HDRV hDrv, const char* pPropName );
HOBJ getIOSubSystemProp( HDRV hDrv, const char* pPropName );
HOBJ getRequestCtrlProp( HDRV hDrv, const char* pRequestCtrlName, const char* pPropName );
HOBJ getRequestProp( HDRV hDrv, int requestNr, const char* pPropName );
HOBJ getSettingProp( HDRV hDrv, const char* pSettingName, const char* pPropName );
HOBJ getStatisticProp( HDRV hDrv, const char* pPropName );
HOBJ getSystemSettingProp( HDRV hDrv, const char* pPropName );

/// \brief Reads the value of a feature as a string
/// \note
/// pBuf must be freed by the caller
TPROPHANDLING_ERROR getStringValue( HOBJ hObj, char** pBuf, int index );
void modifyIntEnumProperty( HDRV hDrv, const char* pSettingName, const char* pPropName );
/// \brief Shows how to read the translation dictionary of a property and returns all the 
/// interger values in the dict.
///
/// \note
/// \a pDictValues must be freed by the caller.
TPROPHANDLING_ERROR processDict( HOBJ m_hObj, int** pDictValues, unsigned int* pDictValCnt );

#endif // exampleHelper_CH
