//-----------------------------------------------------------------------------
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include "exampleHelper_C.h"

//-----------------------------------------------------------------------------
int getIntValFromSTDIn( void )
//-----------------------------------------------------------------------------
{
	int value;
	int conversionResult = 0;
#if defined(_MSC_VER) && (_MSC_VER >= 1400) // is at least VC 2005 compiler?
	conversionResult = scanf_s( "%d", &value );
#else
	conversionResult = scanf( "%d", &value );
#endif // #if defined(_MSC_VER) && (_MSC_VER >= 1400)
	if( conversionResult != 1 )
	{
		printf( "Conversion error: Expected: 1, conversion result: %d.\n", conversionResult );
	}
	return value;
}

//-----------------------------------------------------------------------------
int getPropI( HOBJ hProp, int index )
//-----------------------------------------------------------------------------
{
	int value = 0;
	TPROPHANDLING_ERROR result = PROPHANDLING_NO_ERROR;
	if( ( result = OBJ_GetI( hProp, &value, index ) ) != PROPHANDLING_NO_ERROR )
	{
		printf( "getPropI: Failed to read property value(%s).\n", DMR_ErrorCodeToString( result ) );
		exit( 666 );
	}
	return value;
}

//-----------------------------------------------------------------------------
void setPropI( HOBJ hProp, int value, int index )
//-----------------------------------------------------------------------------
{
	TPROPHANDLING_ERROR result = PROPHANDLING_NO_ERROR;
	if( ( result = OBJ_SetI( hProp, value, index ) ) != PROPHANDLING_NO_ERROR )
	{
		printf( "setPropI: Failed to write property value(%s).\n", DMR_ErrorCodeToString( result ) );
		exit( 666 );
	}
}

//-----------------------------------------------------------------------------
void* getPropP( HOBJ hProp, int index )
//-----------------------------------------------------------------------------
{
	void* value = 0;
	TPROPHANDLING_ERROR result = PROPHANDLING_NO_ERROR;
	if( ( result = OBJ_GetP( hProp, &value, index ) ) != PROPHANDLING_NO_ERROR )
	{
		printf( "getPropP: Failed to read property value(%s).\n", DMR_ErrorCodeToString( result ) );
		exit( 666 );
	}
	return value;
}

//-----------------------------------------------------------------------------
void setPropP( HOBJ hProp, void* value, int index )
//-----------------------------------------------------------------------------
{
	TPROPHANDLING_ERROR result = PROPHANDLING_NO_ERROR;
	if( ( result = OBJ_SetP( hProp, value, index ) ) != PROPHANDLING_NO_ERROR )
	{
		printf( "setPropP: Failed to write property value(%s).\n", DMR_ErrorCodeToString( result ) );
		exit( 666 );
	}
}

//-----------------------------------------------------------------------------
// This function will try to obtain the handle to a certain driver feature list
HOBJ getDriverList( HDRV hDrv, const char* pName, const char* pAddListName, TDMR_ListType type )
//-----------------------------------------------------------------------------
{
	TDMR_ERROR dmrResult;
	HOBJ hObj = INVALID_ID;
	HLIST baseList;

	// try to loacte the base list for these property
	if( ( dmrResult = DMR_FindList( hDrv, pAddListName, type, 0, &baseList ) ) == DMR_NO_ERROR )
	{
		// try to loacte the property
		TPROPHANDLING_ERROR objResult;
		if( ( objResult = OBJ_GetHandleEx( baseList, pName, &hObj, smIgnoreProperties | smIgnoreMethods, INT_MAX ) ) != PROPHANDLING_NO_ERROR )
		{
			printf( "OBJ_GetHandle for %s failed: %d Handle: %d. This list might not be supported by this device\n", pName, objResult, hObj );
		}
	}
	else
	{
		printf( "DMR_FindList failed: %d. Lists of type %d are not available for this device\n", dmrResult, type );
	}
	return hObj;
}

//-----------------------------------------------------------------------------
// This function will try to obtain the handle to a certain driver property
HOBJ getDriverProperty( HDRV hDrv, const char* pPropName, const char* pAddListName, TDMR_ListType type )
//-----------------------------------------------------------------------------
{
	TDMR_ERROR dmrResult;
	HOBJ hProp = INVALID_ID;
	HLIST baseList;

	// try to loacte the base list for these property
	if( ( dmrResult = DMR_FindList( hDrv, pAddListName, type, 0, &baseList ) ) == DMR_NO_ERROR )
	{
		// try to loacte the property
		TPROPHANDLING_ERROR objResult;
		if( ( objResult = OBJ_GetHandleEx( baseList, pPropName, &hProp, smIgnoreLists | smIgnoreMethods, INT_MAX ) ) != PROPHANDLING_NO_ERROR )
		{
			printf( "OBJ_GetHandle for %s failed: %d Handle: %d. This property might not be supported by this device\n", pPropName, objResult, hProp );
		}
	}
	else
	{
		printf( "DMR_FindList failed: %d. Lists of type %d are not available for this device\n", dmrResult, type );
	}
	return hProp;
}

//-----------------------------------------------------------------------------
HOBJ getDeviceProp( HDEV hDev, const char* pPropName )
//-----------------------------------------------------------------------------
{
	TPROPHANDLING_ERROR objResult;
	HOBJ hProp;

	// try to loacte the property
	if( ( objResult = OBJ_GetHandle( hDev, pPropName, &hProp ) ) != PROPHANDLING_NO_ERROR )
	{
		printf( "OBJ_GetHandle failed: %d Handle: %d\n", objResult, hProp );
	}
	return hProp;
}

//-----------------------------------------------------------------------------
HOBJ getInfoProp( HDRV hDrv, const char* pPropName )
//-----------------------------------------------------------------------------
{
	return getDriverProperty( hDrv, pPropName, 0, dmltInfo );
}

//-----------------------------------------------------------------------------
HOBJ getIOSubSystemProp( HDRV hDrv, const char* pPropName )
//-----------------------------------------------------------------------------
{
	return getDriverProperty( hDrv, pPropName, 0, dmltIOSubSystem );
}

//-----------------------------------------------------------------------------
HOBJ getRequestCtrlProp( HDRV hDrv, const char* pRequestCtrlName, const char* pPropName )
//-----------------------------------------------------------------------------
{
	return getDriverProperty( hDrv, pPropName, pRequestCtrlName, dmltRequestCtrl );
}

//-----------------------------------------------------------------------------
HOBJ getRequestProp( HDRV hDrv, int requestNr, const char* pPropName )
//-----------------------------------------------------------------------------
{
	char buf[32];
	sprintf( buf, "Entry %d", requestNr );
	return getDriverProperty( hDrv, pPropName, buf, dmltRequest );
}

//-----------------------------------------------------------------------------
HOBJ getSettingProp( HDRV hDrv, const char* pSettingName, const char* pPropName )
//-----------------------------------------------------------------------------
{
	return getDriverProperty( hDrv, pPropName, pSettingName, dmltSetting );
}

//-----------------------------------------------------------------------------
HOBJ getStatisticProp( HDRV hDrv, const char* pPropName )
//-----------------------------------------------------------------------------
{
	return getDriverProperty( hDrv, pPropName, 0, dmltStatistics );
}

//-----------------------------------------------------------------------------
HOBJ getSystemSettingProp( HDRV hDrv, const char* pPropName )
//-----------------------------------------------------------------------------
{
	return getDriverProperty( hDrv, pPropName, 0, dmltSystemSettings );
}

//-----------------------------------------------------------------------------
TPROPHANDLING_ERROR getStringValue( HOBJ hObj, char** pBuf, int index )
//-----------------------------------------------------------------------------
{
	size_t bufSize = DEFAULT_STRING_SIZE_LIMIT;
	TPROPHANDLING_ERROR result = PROPHANDLING_NO_ERROR;
	static const int BUFFER_INCREMENT_FACTOR = 2;

	*pBuf = (char*)calloc( 1, bufSize );
	while( ( result = OBJ_GetS( hObj, *pBuf, bufSize, index ) ) == PROPHANDLING_INPUT_BUFFER_TOO_SMALL )
	{
		bufSize *= BUFFER_INCREMENT_FACTOR;
		*pBuf = (char*)realloc( *pBuf, bufSize );
	}
	if( result != PROPHANDLING_NO_ERROR )
	{
		printf( "Error while reading string property value(%d).\n", result );
	}
	return result;
}

//-----------------------------------------------------------------------------
void modifyIntEnumProperty( HDRV hDrv, const char* pSettingName, const char* pPropName )
//-----------------------------------------------------------------------------
{
	HOBJ			hProp = INVALID_ID;
	unsigned int	dictValCount = 0;
	int*			dictVals = NULL;
	TDMR_ERROR		result = DMR_NO_ERROR;

	printf( "Trying to modify property %s:\n", pPropName );
	if( ( hProp = getSettingProp( hDrv, pSettingName, pPropName ) ) != INVALID_ID )
	{
		if( ( result = processDict( hProp, &dictVals, &dictValCount ) ) == DMR_NO_ERROR )
		{
			int value = 0;
			printf( "Please select one of the values listed above: " );
			value = getIntValFromSTDIn();
			free( dictVals );
			// set the new trigger mode
			if( ( result = OBJ_SetI( hProp, value, 0 ) ) != DMR_NO_ERROR )
			{
				printf( "Failed to set new value for %s. Error code: %d(%s).\n", pPropName, result, DMR_ErrorCodeToString( result ) );
			}
		}
	}
}

//-----------------------------------------------------------------------------
TPROPHANDLING_ERROR processDict( HOBJ m_hObj, int** pDictValues, unsigned int* pDictValCnt )
//-----------------------------------------------------------------------------
{
	TPROPHANDLING_ERROR funcResult = PROPHANDLING_NO_ERROR;
	char** ppBuf = 0;
	unsigned int i = 0;
	size_t bufSize = 0;
	const size_t BUFFER_INCREMENT_FACTOR = 6;

	if( ( funcResult = OBJ_GetDictSize( m_hObj, pDictValCnt ) ) != PROPHANDLING_NO_ERROR )
	{
		return funcResult;
	}

	*pDictValues = (int*)calloc( *pDictValCnt, sizeof(int) );
	ppBuf = (char**)calloc( *pDictValCnt, sizeof(char*) );
	bufSize = DEFAULT_STRING_SIZE_LIMIT;
	for( i=0; i<*pDictValCnt; i++ )
	{
		ppBuf[i] = (char*)calloc( 1, bufSize );
	}

	while( ( funcResult = OBJ_GetIDictEntries( m_hObj, ppBuf, bufSize, *pDictValues, (size_t)*pDictValCnt ) ) == PROPHANDLING_INPUT_BUFFER_TOO_SMALL )
	{
		bufSize *= BUFFER_INCREMENT_FACTOR;
		for( i=0; i<*pDictValCnt; i++ )
		{
			ppBuf[i] = (char*)realloc( ppBuf[i], bufSize );
		}
	}

	if( funcResult == PROPHANDLING_NO_ERROR )
	{
		printf( "Got the following dictionary:\n" );
		for( i=0; i<*pDictValCnt; i++ )
		{
			printf( "[%d]: %s(numerical rep: %d)\n", i, ppBuf[i], (*pDictValues)[i] );
		}
	}

	// free memory again
	for( i=0; i<*pDictValCnt; i++ )
	{
		free( ppBuf[i] );
	}
	free( ppBuf );
	return funcResult;
}
