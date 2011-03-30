#include "MicroParams.hh"
#include <math.h>

ParamTable ptable1;
ParamTable ptable2;
ParamTable ptable3;
ParamTable ptable4;
ParamTable ptable5;
ParamTable ptable6;
ParamTable ptable7;
ParamTable ptable8;
ParamTable ptable9;
ParamTable ptable10;

int MicroParamsInitialize()
{

  ptable1.id           = 1;
  ptable1.mode         = 0;
  ptable1.accBiasX     = 660;
  ptable1.accBiasY     = 660;
  ptable1.accBiasZ     = 660;
  ptable1.accSenX      = (1.0/139.0);
  ptable1.accSenY      = (1.0/139.0);
  ptable1.accSenZ      = (1.0/139.0);
  ptable1.gyroSenX     = (M_PI/180.0/3.5);
  ptable1.gyroSenY     = (M_PI/180.0/3.5);
  ptable1.gyroSenZ     = (M_PI/180.0/3.5);
  ptable1.gyroNomBiasX = 485;
  ptable1.gyroNomBiasY = 485;
  ptable1.gyroNomBiasZ = 485;
  ptable1.dummy        = 0;
  ptable1.checksum     = 0;


  ptable2.id           = 2;
  ptable2.mode         = 0;
  ptable2.accBiasX     = 660;
  ptable2.accBiasY     = 660;
  ptable2.accBiasZ     = 660;
  ptable2.accSenX      = (1.0/139.0);
  ptable2.accSenY      = (1.0/139.0);
  ptable2.accSenZ      = (1.0/139.0);
  ptable2.gyroSenX     = (M_PI/180.0/3.5);
  ptable2.gyroSenY     = (M_PI/180.0/3.5);
  ptable2.gyroSenZ     = (M_PI/180.0/3.5);
  ptable2.gyroNomBiasX = 485;
  ptable2.gyroNomBiasY = 485;
  ptable2.gyroNomBiasZ = 485;
  ptable2.dummy        = 0;
  ptable2.checksum     = 0;


  ptable3.id           = 3;
  ptable3.mode         = 0;
  ptable3.accBiasX     = 660;
  ptable3.accBiasY     = 660;
  ptable3.accBiasZ     = 660;
  ptable3.accSenX      = (1.0/139.0);
  ptable3.accSenY      = (1.0/139.0);
  ptable3.accSenZ      = (1.0/139.0);
  ptable3.gyroSenX     = (M_PI/180.0/3.5);
  ptable3.gyroSenY     = (M_PI/180.0/3.5);
  ptable3.gyroSenZ     = (M_PI/180.0/3.5);
  ptable3.gyroNomBiasX = 485;
  ptable3.gyroNomBiasY = 485;
  ptable3.gyroNomBiasZ = 485;
  ptable3.dummy        = 0;
  ptable3.checksum     = 0;



  ptable4.id           = 4;
  ptable4.mode         = 0;
  ptable4.accBiasX     = 660;
  ptable4.accBiasY     = 660;
  ptable4.accBiasZ     = 660;
  ptable4.accSenX      = (1.0/139.0);
  ptable4.accSenY      = (1.0/139.0);
  ptable4.accSenZ      = (1.0/139.0);
  ptable4.gyroSenX     = (M_PI/180.0/3.5);
  ptable4.gyroSenY     = (M_PI/180.0/3.5);
  ptable4.gyroSenZ     = (M_PI/180.0/3.5);
  ptable4.gyroNomBiasX = 485;
  ptable4.gyroNomBiasY = 485;
  ptable4.gyroNomBiasZ = 485;
  ptable4.dummy        = 0;
  ptable4.checksum     = 0;


  ptable5.id           = 5;
  ptable5.mode         = 0;
  ptable5.accBiasX     = 660;
  ptable5.accBiasY     = 660;
  ptable5.accBiasZ     = 660;
  ptable5.accSenX      = (1.0/139.0);
  ptable5.accSenY      = (1.0/139.0);
  ptable5.accSenZ      = (1.0/139.0);
  ptable5.gyroSenX     = (M_PI/180.0/3.5);
  ptable5.gyroSenY     = (M_PI/180.0/3.5);
  ptable5.gyroSenZ     = (M_PI/180.0/3.5);
  ptable5.gyroNomBiasX = 485;
  ptable5.gyroNomBiasY = 485;
  ptable5.gyroNomBiasZ = 485;
  ptable5.dummy        = 0;
  ptable5.checksum     = 0;



  ptable6.id           = 6;
  ptable6.mode         = 0;
  ptable6.accBiasX     = 660;
  ptable6.accBiasY     = 660;
  ptable6.accBiasZ     = 660;
  ptable6.accSenX      = (1.0/139.0);
  ptable6.accSenY      = (1.0/139.0);
  ptable6.accSenZ      = (1.0/139.0);
  ptable6.gyroSenX     = (M_PI/180.0/3.5);
  ptable6.gyroSenY     = (M_PI/180.0/3.5);
  ptable6.gyroSenZ     = (M_PI/180.0/3.5);
  ptable6.gyroNomBiasX = 485;
  ptable6.gyroNomBiasY = 485;
  ptable6.gyroNomBiasZ = 485;
  ptable6.dummy        = 0;
  ptable6.checksum     = 0;


  ptable7.id           = 7;
  ptable7.mode         = 0;
  ptable7.accBiasX     = 660;
  ptable7.accBiasY     = 660;
  ptable7.accBiasZ     = 660;
  ptable7.accSenX      = (1.0/139.0);
  ptable7.accSenY      = (1.0/139.0);
  ptable7.accSenZ      = (1.0/139.0);
  ptable7.gyroSenX     = (M_PI/180.0/3.5);
  ptable7.gyroSenY     = (M_PI/180.0/3.5);
  ptable7.gyroSenZ     = (M_PI/180.0/3.5);
  ptable7.gyroNomBiasX = 485;
  ptable7.gyroNomBiasY = 485;
  ptable7.gyroNomBiasZ = 485;
  ptable7.dummy        = 0;
  ptable7.checksum     = 0;



  ptable8.id           = 8;
  ptable8.mode         = 0;
  ptable8.accBiasX     = 669;
  ptable8.accBiasY     = 666;
  ptable8.accBiasZ     = 695;
  ptable8.accSenX      = (1.0/139.0);
  ptable8.accSenY      = (1.0/139.0);
  ptable8.accSenZ      = (1.0/139.0);
  ptable8.gyroSenX     = (M_PI/180.0/3.5);
  ptable8.gyroSenY     = (M_PI/180.0/3.5);
  ptable8.gyroSenZ     = (M_PI/180.0/3.5);
  ptable8.gyroNomBiasX = 485;
  ptable8.gyroNomBiasY = 485;
  ptable8.gyroNomBiasZ = 485;
  ptable8.dummy        = 0;
  ptable8.checksum     = 0;


  ptable9.id           = 9;
  ptable9.mode         = 0;
  ptable9.accBiasX     = 660;
  ptable9.accBiasY     = 660;
  ptable9.accBiasZ     = 660;
  ptable9.accSenX      = (1.0/139.0);
  ptable9.accSenY      = (1.0/139.0);
  ptable9.accSenZ      = (1.0/139.0);
  ptable9.gyroSenX     = (M_PI/180.0/3.5);
  ptable9.gyroSenY     = (M_PI/180.0/3.5);
  ptable9.gyroSenZ     = (M_PI/180.0/3.5);
  ptable9.gyroNomBiasX = 485;
  ptable9.gyroNomBiasY = 485;
  ptable9.gyroNomBiasZ = 485;
  ptable9.dummy        = 0;
  ptable9.checksum     = 0;



  ptable10.id           = 10;
  ptable10.mode         = 0;
  ptable10.accBiasX     = 660;
  ptable10.accBiasY     = 660;
  ptable10.accBiasZ     = 660;
  ptable10.accSenX      = (1.0/139.0);
  ptable10.accSenY      = (1.0/139.0);
  ptable10.accSenZ      = (1.0/139.0);
  ptable10.gyroSenX     = (M_PI/180.0/3.5);
  ptable10.gyroSenY     = (M_PI/180.0/3.5);
  ptable10.gyroSenZ     = (M_PI/180.0/3.5);
  ptable10.gyroNomBiasX = 485;
  ptable10.gyroNomBiasY = 485;
  ptable10.gyroNomBiasZ = 485;
  ptable10.dummy        = 0;
  ptable10.checksum     = 0;


  return 0;
}
