#! /bin/make
##############################################
# Makefile for the 'SingleSnap' sample,
# == DO NOT CHANGE !!! ==
##############################################
#-------------------------------------------
ROOT_PATH=../..

#-------------------------------------------
MODULE_NAME=SingleSnap

#-------------------------------------------
OOBJ =										\
	saveimg.o

#-------------------------------------------
vpath %.cpp ..

#-------------------------------------------
USR_INCLS =					\

#-------------------------------------------
USR_LIBS =					\

#-------------------------------------------
CPPFLAGS_1 = 				\

#		-DMALLOC_TRACE		\

#-------------------------------------------
include $(ROOT_PATH)/Makefile.samp.inc

#-------------------------------------------
#-------------------------------------------

