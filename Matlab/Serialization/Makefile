MEX_EXT = $(shell mexext)

INCLUDES = -I. -I../../Common

LIBDIRS = 

DATA_TYPES = GP_MAP_DATA GP_ROBOT_PARAMETER GP_POSITION_UPDATE GP_FULL_UPDATE GP_SHORT_UPDATE GP_TRAJECTORY MotionTraj

HEADERS = MexIpcSerialization.hh MagicPlanDataTypes.h MagicPlanDataTypes.c MagicTraj.hh MagicTraj.cc
NAMESPACES = 

all: template.cc
	for i in $(DATA_TYPES) ; \
	do \
    if (cp template.cc temp.cc; cat SerializerTemplate.cc >> temp.cc; \
      mex -O $(INCLUDES) -DDATA_TYPE=$$i temp.cc -lipc -output Magic$$i\Serializer.$(MEX_EXT)) ; \
			then rm temp.cc;\
      else exit; \
      fi; \
  done;
	rm template.cc


template.cc:
	echo '' > template.cc;
	for i in $(HEADERS); do echo "#include \"$$i\"" >> template.cc; done;
	for i in $(NAMESPACES); do echo "using namespace $$i;" >> template.cc; done;

clean:
	rm -f *.mex* *~ template.cc temp.cc
