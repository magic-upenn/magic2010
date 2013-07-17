/* Copyright KMel Robotics 2012. Must read KMEL_LICENSE.pdf for terms and conditions before use. */
/*
Vicon parser / wrapper
Author: Alex Kushleyev, Nov. 2011

Based on vicon sample code. See note below.
*/



///////////////////////////////////////////////////////////////////////////////
//
// Copyright (C) OMG Plc 2009.
// All rights reserved.  This software is protected by copyright
// law and international treaties.  No part of this software / document
// may be reproduced or distributed in any form or by any means,
// whether transiently or incidentally to some other use of this software,
// without the written permission of the copyright owner.
//
///////////////////////////////////////////////////////////////////////////////

#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <string.h>


#include "Client.h"
#include "ViconDriver2.hh"
#include "Timer.hh"


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Constructor
//_______________________________________________________
ViconDriver2::ViconDriver2()
{
  this->connected          = 0;
  this->threadRunning      = 0;
  this->maxBufferedPackets = 100;
  
  pthread_mutex_init( &(this->dataMutex) , NULL );
}


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Destructor
//_______________________________________________________
ViconDriver2::~ViconDriver2()
{
  this->Disconnect(); 
}


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Connect and set up default parameters
//_______________________________________________________
int ViconDriver2::Connect(std::string host)
{
  for(int i=0; i <3; i++) // repeat to check disconnecting doesn't wreck next connect
  {
    VICON_LOG_INFO("Connecting to " << host <<"....");
    while( !this->viconClient.IsConnected().Connected )
    {
      // Direct connection
      this->viconClient.Connect( host );

      // Multicast connection
      // this->viconClient.ConnectToMulticast( HostName, "224.0.0.0" );
    }
  }
    
  VICON_LOG_INFO("done");
  
  this->viconClient.EnableSegmentData();
  this->viconClient.EnableMarkerData();
  this->viconClient.EnableUnlabeledMarkerData();
  this->viconClient.EnableDeviceData();

  VICON_LOG_INFO("Segment Data Enabled: "          << Adapt( this->viconClient.IsSegmentDataEnabled().Enabled )         );
  VICON_LOG_INFO("Marker Data Enabled: "           << Adapt( this->viconClient.IsMarkerDataEnabled().Enabled )          );
  VICON_LOG_INFO("Unlabeled Marker Data Enabled: " << Adapt( this->viconClient.IsUnlabeledMarkerDataEnabled().Enabled ) );
  VICON_LOG_INFO("Device Data Enabled: "           << Adapt( this->viconClient.IsDeviceDataEnabled().Enabled )          );
  
  
  // Set the streaming mode
  // this->viconClient.SetStreamMode( ViconDataStreamSDK::CPP::StreamMode::ClientPull );
  // this->viconClient.SetStreamMode( ViconDataStreamSDK::CPP::StreamMode::ClientPullPreFetch );
  this->viconClient.SetStreamMode( ViconDataStreamSDK::CPP::StreamMode::ServerPush );

  // Set the global up axis
  this->viconClient.SetAxisMapping( Direction::Forward, 
                            Direction::Left, 
                            Direction::Up ); // Z-up
  // this->viconClient.SetGlobalUpAxis( Direction::Forward, 
  //                           Direction::Up, 
  //                           Direction::Right ); // Y-up

  Output_GetAxisMapping _Output_GetAxisMapping = this->viconClient.GetAxisMapping();
  VICON_LOG_INFO("Axis Mapping: X-" << Adapt( _Output_GetAxisMapping.XAxis ) 
                          << " Y-" << Adapt( _Output_GetAxisMapping.YAxis ) 
                          << " Z-" << Adapt( _Output_GetAxisMapping.ZAxis )  );

  // Discover the version number
  Output_GetVersion _Output_GetVersion = this->viconClient.GetVersion();
  VICON_LOG_INFO("Version: " << _Output_GetVersion.Major << "." 
                            << _Output_GetVersion.Minor << "." 
                            << _Output_GetVersion.Point );
                            
                            
  int ret = this->StartThread();
  
  if (ret)
  {
    VICON_LOG_ERROR("could not start vicon thread");
    return -1;
  }

  this->connected = 1;
 
  return 0;
}


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Disconnect the client
//_______________________________________________________
int ViconDriver2::Disconnect()
{
  this->StopThread();
  
  this->viconClient.DisableSegmentData();
  this->viconClient.DisableMarkerData();
  this->viconClient.DisableUnlabeledMarkerData();
  this->viconClient.DisableDeviceData();
  
  this->viconClient.Disconnect();
  
  return 0;
}


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Start the internal polling thread
//_______________________________________________________
int ViconDriver2::StartThread()
{
  if (this->threadRunning)
    return 0;
  
  VICON_LOG_INFO("Starting Vicon thread...");

  if (pthread_create(&this->thread, NULL, this->ThreadFunc, (void *)this))
  {
    VICON_LOG_ERROR("Could not start thread\n");
    return -1;
  }
  VICON_LOG_INFO("done\n");
  
  this->threadRunning = 1;
  return 0;
}

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Stop the thread
//_______________________________________________________
int ViconDriver2::StopThread()
{
  if (this->threadRunning)
  {
    VICON_LOG_INFO("Stopping thread...");
    pthread_cancel(this->thread);
    pthread_join(this->thread,NULL);
    VICON_LOG_INFO("done\n"); 
    this->threadRunning=false;
  }
  return 0; 
}


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Parse the subjects into internal data structures
//_______________________________________________________
int ViconDriver2::ParseSubjects(std::list<ViconSubject> & subjects)
{
  //clear the list of subjects
  subjects.clear();
  
  unsigned int SubjectCount = this->viconClient.GetSubjectCount().SubjectCount;

  for( unsigned int SubjectIndex = 0 ; SubjectIndex < SubjectCount ; ++SubjectIndex )
  {
    ViconSubject subj;

    std::string SubjectName = this->viconClient.GetSubjectName( SubjectIndex ).SubjectName;
    std::string RootSegment = this->viconClient.GetSubjectRootSegmentName( SubjectName ).SegmentName;
    
    subj.name = SubjectName;

    // Count the number of segments
    unsigned int SegmentCount = this->viconClient.GetSegmentCount( SubjectName ).SegmentCount;
    unsigned int SegmentIndex = 0;  //only look at the first segment: assume a rigid body
    
    if (SegmentIndex < SegmentCount)
    {
      std::string SegmentName = this->viconClient.GetSegmentName( SubjectName, SegmentIndex ).SegmentName;

      Output_GetSegmentGlobalTranslation _Output_GetSegmentGlobalTranslation = 
        this->viconClient.GetSegmentGlobalTranslation( SubjectName, SegmentName );
                                                   
      subj.pose.xyz[0]   = _Output_GetSegmentGlobalTranslation.Translation[ 0 ];
      subj.pose.xyz[1]   = _Output_GetSegmentGlobalTranslation.Translation[ 1 ];
      subj.pose.xyz[2]   = _Output_GetSegmentGlobalTranslation.Translation[ 2 ];
      subj.pose.validXyz = _Output_GetSegmentGlobalTranslation.Occluded == false;
                                                    
      Output_GetSegmentGlobalRotationMatrix _Output_GetSegmentGlobalRotationMatrix = 
        this->viconClient.GetSegmentGlobalRotationMatrix( SubjectName, SegmentName );
    
      memcpy(subj.pose.rot, &(_Output_GetSegmentGlobalRotationMatrix.Rotation[0]), 9*sizeof(double));                                          
      subj.pose.validRot = _Output_GetSegmentGlobalRotationMatrix.Occluded == false;

      // Get the global segment rotation in quaternion co-ordinates
      Output_GetSegmentGlobalRotationQuaternion _Output_GetSegmentGlobalRotationQuaternion = 
        this->viconClient.GetSegmentGlobalRotationQuaternion( SubjectName, SegmentName );
       
      memcpy(subj.pose.quat, &(_Output_GetSegmentGlobalRotationQuaternion.Rotation[0]), 4*sizeof(double));                                                      
      subj.pose.validQuat = _Output_GetSegmentGlobalRotationQuaternion.Occluded == false;

      // Get the global segment rotation in EulerXYZ co-ordinates
      Output_GetSegmentGlobalRotationEulerXYZ _Output_GetSegmentGlobalRotationEulerXYZ = 
        this->viconClient.GetSegmentGlobalRotationEulerXYZ( SubjectName, SegmentName );
                            
      memcpy(subj.pose.rpy, &(_Output_GetSegmentGlobalRotationEulerXYZ.Rotation[0]), 3*sizeof(double));
      subj.pose.validRpy = _Output_GetSegmentGlobalRotationEulerXYZ.Occluded == false;
    }

    // Count the number of markers
    unsigned int MarkerCount = this->viconClient.GetMarkerCount( SubjectName ).MarkerCount;

    for( unsigned int MarkerIndex = 0 ; MarkerIndex < MarkerCount ; ++MarkerIndex )
    {
      // Get the marker name
      std::string MarkerName = this->viconClient.GetMarkerName( SubjectName, MarkerIndex ).MarkerName;

      // Get the marker parent
      std::string MarkerParentName = this->viconClient.GetMarkerParentName( SubjectName, MarkerName ).SegmentName;

      // Get the global marker translation
      Output_GetMarkerGlobalTranslation _Output_GetMarkerGlobalTranslation =
        this->viconClient.GetMarkerGlobalTranslation( SubjectName, MarkerName );
                                  
      ViconLabeledMarker marker;
      marker.name    = MarkerName;
      marker.xyz[0]  = _Output_GetMarkerGlobalTranslation.Translation[ 0 ];
      marker.xyz[1]  = _Output_GetMarkerGlobalTranslation.Translation[ 1 ];
      marker.xyz[2]  = _Output_GetMarkerGlobalTranslation.Translation[ 2 ];
      marker.visible = _Output_GetMarkerGlobalTranslation.Occluded == false;
      subj.markers.push_back(marker);
    }
    
    
    subjects.push_back(subj);
  }
      
  return 0;
}


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Parse unlabeled markers into internal data structure
//_______________________________________________________
int ViconDriver2::ParseUnlabeledMarkers(std::list<ViconUnlabeledMarker> & markers)
{
  //clear out the list
  markers.clear();
  
  unsigned int UnlabeledMarkerCount = this->viconClient.GetUnlabeledMarkerCount().MarkerCount;

  for( unsigned int UnlabeledMarkerIndex = 0 ; UnlabeledMarkerIndex < UnlabeledMarkerCount ; ++UnlabeledMarkerIndex )
  { 
    // Get the global marker translation
    Output_GetUnlabeledMarkerGlobalTranslation _Output_GetUnlabeledMarkerGlobalTranslation =
      this->viconClient.GetUnlabeledMarkerGlobalTranslation( UnlabeledMarkerIndex );
                             
    ViconUnlabeledMarker marker;
    marker.xyz[0] = _Output_GetUnlabeledMarkerGlobalTranslation.Translation[0];
    marker.xyz[1] = _Output_GetUnlabeledMarkerGlobalTranslation.Translation[1];
    marker.xyz[2] = _Output_GetUnlabeledMarkerGlobalTranslation.Translation[2];
    
    //push the marker into the list
    markers.push_back(marker);
  }
  
  return 0;
}


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Parse latency info
//_______________________________________________________
int ViconDriver2::ParseLatencyInfo(ViconLatencyInfo & info)
{
  info.total      = this->viconClient.GetLatencyTotal().Total;
  info.delivered  = 0;
  info.processed  = 0;
  info.datastream = 0;
  
  /*
  for( unsigned int LatencySampleIndex = 0 ; LatencySampleIndex < this->viconClient.GetLatencySampleCount().Count ; ++LatencySampleIndex )
  {
    std::string SampleName  = this->viconClient.GetLatencySampleName( LatencySampleIndex ).Name;
    double      SampleValue = this->viconClient.GetLatencySampleValue( SampleName ).Value;
  }
  */

  return 0;
}

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Lock data mutex
//_______________________________________________________
void ViconDriver2::LockDataMutex()
{
  pthread_mutex_lock( &this->dataMutex );
}

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Unlock data mutex
//_______________________________________________________
void ViconDriver2::UnlockDataMutex()
{
  pthread_mutex_unlock( &this->dataMutex );
}

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Push the filled data structure into the list
//_______________________________________________________
int ViconDriver2::PushViconData(ViconData & data)
{
  this->LockDataMutex();
  
  this->viconData.push_back(data);
  
  while (this->viconData.size() > maxBufferedPackets)
    this->viconData.pop_front();
  
  this->UnlockDataMutex();
  
  return 0;
}

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Main thread function
//_______________________________________________________
void *ViconDriver2::ThreadFunc(void * arg_in)
{
  sigset_t sigs;
  sigfillset(&sigs);
  pthread_sigmask(SIG_BLOCK,&sigs,NULL);

  ViconDriver2 * vic = (ViconDriver2 *) arg_in;
  
  int cntr;
  
  ViconData data;
    
  while(1)
  {
    //see if we need to cancel the thread    
    pthread_testcancel();

    // Get a frame
    //VICON_LOG_INFO("Waiting for new frame...");
    while( vic->viconClient.GetFrame().Result != Result::Success )
    {
      // Sleep a little so that we don't lumber the CPU with a busy poll
      usleep(100000);
      pthread_testcancel();
      printf("."); fflush(stdout);
    }

    cntr++;

    // Get the frame number
    Output_GetFrameNumber _Output_GetFrameNumber = vic->viconClient.GetFrameNumber();
    //VICON_LOG_INFO("Frame Number: " << _Output_GetFrameNumber.FrameNumber);
    
    data.frameCntr = _Output_GetFrameNumber.FrameNumber;
    data.unixTime  = Timer::GetUnixTime();
    
    vic->ParseLatencyInfo(data.latencyInfo);
    vic->ParseSubjects(data.subjects);
    vic->ParseUnlabeledMarkers(data.unlabeledMarkers);
    
    vic->PushViconData(data);
  }
  
  return NULL;
}


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Data accessor function
//_______________________________________________________
int ViconDriver2::GetViconData(std::list<ViconData> & data)
{
  int len;
  
  if (!this->connected)
  {
    VICON_LOG_ERROR("not connected");
    return -1;
  }
  
  this->LockDataMutex();
  
  len  = this->viconData.size();
  data = this->viconData; //copy the list
  this->viconData.clear();
  
  this->UnlockDataMutex();
  
  
  return len;
}


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Print unlabeled markers
//_______________________________________________________
int ViconDriver2::PrintUnlabeledMarkers()
{
  unsigned int UnlabeledMarkerCount = this->viconClient.GetUnlabeledMarkerCount().MarkerCount;
  VICON_LOG_INFO("Unlabeled Markers (" << UnlabeledMarkerCount << "):");
  for( unsigned int UnlabeledMarkerIndex = 0 ; UnlabeledMarkerIndex < UnlabeledMarkerCount ; ++UnlabeledMarkerIndex )
  { 
    // Get the global marker translation
    Output_GetUnlabeledMarkerGlobalTranslation _Output_GetUnlabeledMarkerGlobalTranslation =
      this->viconClient.GetUnlabeledMarkerGlobalTranslation( UnlabeledMarkerIndex );

    VICON_LOG_INFO("      Marker #" << UnlabeledMarkerIndex   << ": ("
                                  << _Output_GetUnlabeledMarkerGlobalTranslation.Translation[ 0 ] << ", "
                                  << _Output_GetUnlabeledMarkerGlobalTranslation.Translation[ 1 ] << ", "
                                  << _Output_GetUnlabeledMarkerGlobalTranslation.Translation[ 2 ] << ") ");
                                  
  }
  
  return 0;
}

//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Print latency info
//_______________________________________________________
int ViconDriver2::PrintLatency()
{
  VICON_LOG_INFO("Latency: " << this->viconClient.GetLatencyTotal().Total << "s");
  
  for( unsigned int LatencySampleIndex = 0 ; LatencySampleIndex < this->viconClient.GetLatencySampleCount().Count ; ++LatencySampleIndex )
  {
    std::string SampleName  = this->viconClient.GetLatencySampleName( LatencySampleIndex ).Name;
    double      SampleValue = this->viconClient.GetLatencySampleValue( SampleName ).Value;

    VICON_LOG_INFO(SampleName << " " << SampleValue << "s");
  }
  
  return 0;
}


//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// Print subjects
//_______________________________________________________
int ViconDriver2::PrintSubjects()
{
  // Count the number of subjects
  unsigned int SubjectCount = this->viconClient.GetSubjectCount().SubjectCount;
  VICON_LOG_INFO("Subjects (" << SubjectCount << "):");
  
  for( unsigned int SubjectIndex = 0 ; SubjectIndex < SubjectCount ; ++SubjectIndex )
  {
    VICON_LOG_INFO("  Subject #" << SubjectIndex);
    
    // Get the subject name
    std::string SubjectName = this->viconClient.GetSubjectName( SubjectIndex ).SubjectName;
    VICON_LOG_INFO("            Name: " << SubjectName);
    
    // Get the root segment
    std::string RootSegment = this->viconClient.GetSubjectRootSegmentName( SubjectName ).SegmentName;
    VICON_LOG_INFO("    Root Segment: " << RootSegment);
    
    // Count the number of segments
    unsigned int SegmentCount = this->viconClient.GetSegmentCount( SubjectName ).SegmentCount;
    VICON_LOG_INFO("    Segments (" << SegmentCount << "):");
    
    unsigned int SegmentIndex = 0;
    
    if (SegmentIndex < SegmentCount)
    {
      VICON_LOG_INFO("      Segment #" << SegmentIndex);
      
      // Get the segment name
      std::string SegmentName = this->viconClient.GetSegmentName( SubjectName, SegmentIndex ).SegmentName;
      VICON_LOG_INFO("          Name: " << SegmentName);
      
      Output_GetSegmentGlobalTranslation _Output_GetSegmentGlobalTranslation = 
        this->viconClient.GetSegmentGlobalTranslation( SubjectName, SegmentName );
      VICON_LOG_INFO("        Global Translation: (" << _Output_GetSegmentGlobalTranslation.Translation[ 0 ]  << ", " 
                                                    << _Output_GetSegmentGlobalTranslation.Translation[ 1 ]  << ", " 
                                                    << _Output_GetSegmentGlobalTranslation.Translation[ 2 ]  << ") " 
                                                    << Adapt( _Output_GetSegmentGlobalTranslation.Occluded ));
                                                    
      Output_GetSegmentGlobalRotationMatrix _Output_GetSegmentGlobalRotationMatrix = 
      this->viconClient.GetSegmentGlobalRotationMatrix( SubjectName, SegmentName );

      VICON_LOG_INFO("        Global Rotation Matrix: (" << _Output_GetSegmentGlobalRotationMatrix.Rotation[ 0 ]     << ", " 
                                                        << _Output_GetSegmentGlobalRotationMatrix.Rotation[ 1 ]     << ", " 
                                                        << _Output_GetSegmentGlobalRotationMatrix.Rotation[ 2 ]     << ", " 
                                                        << _Output_GetSegmentGlobalRotationMatrix.Rotation[ 3 ]     << ", " 
                                                        << _Output_GetSegmentGlobalRotationMatrix.Rotation[ 4 ]     << ", " 
                                                        << _Output_GetSegmentGlobalRotationMatrix.Rotation[ 5 ]     << ", " 
                                                        << _Output_GetSegmentGlobalRotationMatrix.Rotation[ 6 ]     << ", " 
                                                        << _Output_GetSegmentGlobalRotationMatrix.Rotation[ 7 ]     << ", " 
                                                        << _Output_GetSegmentGlobalRotationMatrix.Rotation[ 8 ]     << ") " 
                                                        << Adapt( _Output_GetSegmentGlobalRotationMatrix.Occluded ) );
                                                        
                                                                                                      
      // Get the global segment rotation in quaternion co-ordinates
      Output_GetSegmentGlobalRotationQuaternion _Output_GetSegmentGlobalRotationQuaternion = 
        this->viconClient.GetSegmentGlobalRotationQuaternion( SubjectName, SegmentName );

      VICON_LOG_INFO("        Global Rotation Quaternion: (" << _Output_GetSegmentGlobalRotationQuaternion.Rotation[ 0 ]     << ", " 
                                                            << _Output_GetSegmentGlobalRotationQuaternion.Rotation[ 1 ]     << ", " 
                                                            << _Output_GetSegmentGlobalRotationQuaternion.Rotation[ 2 ]     << ", " 
                                                            << _Output_GetSegmentGlobalRotationQuaternion.Rotation[ 3 ]     << ") " 
                                                            << Adapt( _Output_GetSegmentGlobalRotationQuaternion.Occluded ));   
                                                            
                                                            
      // Get the global segment rotation in EulerXYZ co-ordinates
      Output_GetSegmentGlobalRotationEulerXYZ _Output_GetSegmentGlobalRotationEulerXYZ = 
        this->viconClient.GetSegmentGlobalRotationEulerXYZ( SubjectName, SegmentName );

      VICON_LOG_INFO("        Global Rotation EulerXYZ: (" << _Output_GetSegmentGlobalRotationEulerXYZ.Rotation[ 0 ]     << ", " 
                                                          << _Output_GetSegmentGlobalRotationEulerXYZ.Rotation[ 1 ]     << ", " 
                                                          << _Output_GetSegmentGlobalRotationEulerXYZ.Rotation[ 2 ]     << ") " 
                                                          << Adapt( _Output_GetSegmentGlobalRotationEulerXYZ.Occluded ));

    }
    
    // Count the number of markers
    unsigned int MarkerCount = this->viconClient.GetMarkerCount( SubjectName ).MarkerCount;
    VICON_LOG_INFO("    Markers (" << MarkerCount << "):");
    for( unsigned int MarkerIndex = 0 ; MarkerIndex < MarkerCount ; ++MarkerIndex )
    {
      // Get the marker name
      std::string MarkerName = this->viconClient.GetMarkerName( SubjectName, MarkerIndex ).MarkerName;

      // Get the marker parent
      std::string MarkerParentName = this->viconClient.GetMarkerParentName( SubjectName, MarkerName ).SegmentName;

      // Get the global marker translation
      Output_GetMarkerGlobalTranslation _Output_GetMarkerGlobalTranslation =
        this->viconClient.GetMarkerGlobalTranslation( SubjectName, MarkerName );

      VICON_LOG_INFO("      Marker #" << MarkerIndex            << ": "
                                    << MarkerName             << " ("
                                    << _Output_GetMarkerGlobalTranslation.Translation[ 0 ]  << ", "
                                    << _Output_GetMarkerGlobalTranslation.Translation[ 1 ]  << ", "
                                    << _Output_GetMarkerGlobalTranslation.Translation[ 2 ]  << ") "
                                    << Adapt( _Output_GetMarkerGlobalTranslation.Occluded ));
    }
  }
 
  return 0;
}
