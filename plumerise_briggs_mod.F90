module plumerise_briggs_mod


  implicit none

contains

!------------------------------------------------------------------------!
!  The Community Multiscale Air Quality (CMAQ) system software is in     !
!  continuous development by various groups and is based on information  !
!  from these groups: Federal Government employees, contractors working  !
!  within a United States Government contract, and non-Federal sources   !
!  including research institutions.  These groups give the Government    !
!  permission to use, prepare derivative works of, and distribute copies !
!  of their work in the CMAQ system to the public and to permit others   !
!  to do so.  The United States Environmental Protection Agency          !
!  therefore grants similar permission to use the CMAQ system software,  !
!  but users are requested to provide copies of derivative works or      !
!  products designed to operate in the CMAQ system to the United States  !
!  Government without restrictions as to use by others.  Software        !
!  that is used with the CMAQ system but distributed under the GNU       !
!  General Public License or the GNU Lesser General Public License is    !
!  subject to their copyright restrictions.                              !
!------------------------------------------------------------------------!

!:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
      SUBROUTINE PLMRIS( EMLAYS, HFX, HMIX, STKDM, STKHT, STKTK, &
                         STKVE, USTAR, TS, PSFC, TA, QV, UW, VW, &
                         PRES, WSPD, ZF, ZH, ZPLM )

!-----------------------------------------------------------------------
 
! Description:  
!     computes final effective plume centerline height.
 
! Preconditions:
!     meteorology and stack parameters
 
! Subroutines and Functions Called:
 
! Revision History:
!     Prototype 12/95 by CJC, based on Briggs algorithm adapted from
!     RADM 2.6 subroutine PLUMER() (but with completely different 
!     data structuring).
!     Copied from plmris.F 4.4 by M Houyoux 3/99 
!     Aug 2015, D. Wong: Used assumed shape array declaration
!     Feb 2021 P.C. Campbell:  Converted to standalone Briggs plume rise/driver from CMAQv5.3.1 
!-----------------------------------------------------------------------
! Modified from:
   
! Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling System
! File: @(#)$Id: plmris.F,v 1.2 2011/10/21 16:11:31 yoj Exp $
! COPYRIGHT (C) 2002, MCNC Environmental Modeling Center
! All Rights Reserved
! See file COPYRIGHT for conditions of use.
! Environmental Modeling Center
! MCNC
! P.O. Box 12889
! Research Triangle Park, NC  27709-2889
! smoke@emc.mcnc.org
! Pathname: $Source: /project/yoj/arc/CCTM/src/plrise/smoke/plmris.F,v $
! Last updated: $Date: 2011/10/21 16:11:31 $ 
   
!-----------------------------------------------------------------------
!      USE RUNTIME_VARS, ONLY : LOGDEV

!      IMPLICIT NONE

! Includes:
!      INCLUDE SUBST_CONST     ! CMAQ physical and mathematical constants

! Arguments:
      INTEGER, INTENT( IN )  :: EMLAYS          ! no. of emission layers
!      INTEGER, INTENT( IN )  :: LSTK            ! lyr of top of stack, = RADM's KSTK
      REAL,    INTENT( IN )  :: HFX             ! sensible heat flux [m K/s]
      REAL,    INTENT( IN )  :: HMIX            ! mixing height [m]
      REAL,    INTENT( IN )  :: PSFC            ! surface pressure
      REAL,    INTENT( IN )  :: TS              ! surface temperature
      REAL,    INTENT( IN )  :: STKDM           ! stack diameter [m]
      REAL,    INTENT( IN )  :: STKHT           ! stack height [m]
      REAL,    INTENT( IN )  :: STKTK           ! exhaust temperature [deg K]
      REAL,    INTENT( IN )  :: STKVE           ! exhaust velocity [m/s]
!      REAL,    INTENT( IN )  :: TSTK            ! tmptr at top of stack [deg K]
      REAL,    INTENT( IN )  :: USTAR           ! friction velocity [m/s]
!      REAL,    INTENT( IN )  :: DTHDZ( : )      ! gradient of THETV
      REAL,    INTENT( IN )  :: QV  ( : )       ! mixing ratio
      REAL,    INTENT( IN )  :: TA   ( : )      ! temperature [deg K]
      REAL,    INTENT( IN )  :: UW  ( : )       ! x-direction winds
      REAL,    INTENT( IN )  :: VW  ( : )       ! y-direction winds
      REAL,    INTENT( IN )  :: PRES( 0: )      ! pres at full layer hts (mod by YOJ)
!      REAL,    INTENT( IN )  :: WSPD ( : )      ! wind speed [m/s]
      REAL,    INTENT( IN )  :: ZF ( 0:  )      ! layer surface height [m]
      REAL,    INTENT( IN )  :: ZH   ( : )      ! layer center height [m]
!      REAL,    INTENT( IN )  :: ZSTK ( : )      ! zf( l ) - stkht [m]
!      REAL,    INTENT( INOUT ) :: WSTK          ! wind speed @ top of stack [m/s] 
                                                ! OUT for reporting, only
      REAL,    INTENT( OUT ) :: ZPLM            ! temporarily, plume top height
                                                ! above stack, finally plume centerline
                                                ! height [m] (can be greater than the
                                                ! height of the top of the EMLAYS layer)

! Parameters:
      REAL, PARAMETER :: HCRIT   = 1.0E-4 * 0.03  ! hfx min * tolerance
      REAL, PARAMETER :: SMALL   = 3.0E-5         ! Criterion for stability
      REAL, PARAMETER :: D3      = 1.0 / 3.0
      REAL, PARAMETER :: D6      = 1.0 / 6.0
      REAL, PARAMETER :: D45     = 1.0 / 45.0
      REAL, PARAMETER :: D2664   = 1.0 / 2.664
      REAL, PARAMETER :: D59319  = 1.0 / 59.319
      REAL, PARAMETER :: TWOTHD  = 2.0 / 3.0
      REAL, PARAMETER :: FIVETHD = 5.0 / 3.0
      ! Geometric Constants:

      REAL,      PARAMETER :: PI = 3.14159265
      REAL( 8 ), PARAMETER :: DPI = 3.14159265358979324D0

! pi/180 [ rad/deg ]
      REAL, PARAMETER :: PI180  = PI / 180.0

! Geodetic Constants:

! radius of the earth [ m ]
! FSB: radius of sphere having same surface area as
! Clarke ellipsoid of 1866 ( Source: Snyder, 1987)
!     REAL, PARAMETER :: REARTH = 6370997.0
      REAL, PARAMETER :: REARTH = 6370000.0    ! default Re in MM5 and WRF

! length of a sidereal day [ sec ]
! FSB: Source: CRC76 pp. 14-6
      REAL, PARAMETER :: SIDAY = 86164.09

! mean gravitational acceleration [ m/sec**2 ]
! FSB: Value is mean of polar and equatorial values.
! Source: CRC Handbook (76th Ed) pp. 14-6
      REAL, PARAMETER :: GRAV = 9.80622

! latitude degrees to meters
      REAL, PARAMETER :: DG2M = REARTH * PI180

! Solar Constant:
! Solar constant [ W/m**2 ], p14-2 CRC76
      REAL, PARAMETER :: SOLCNST = 1373.0

! Fundamental Constants: ( Source: CRC76, pp. 1-1 to 1-6)

! Avogadro's Constant [ number/mol ]
      REAL,      PARAMETER :: AVO  = 6.0221367E23
! The NIST Reference on Constants, Units, and Uncertainty. US National
! Institute of Standards and Technology. June 2015. Retrieved 2017-04-21.
! http://physics.nist.gov/cgi-bin/cuu/Value?na
      REAL( 8 ), PARAMETER :: DAVO = 6.02214085774D23

! universal gas constant [ J/mol-K ]
      REAL, PARAMETER :: RGASUNIV = 8.314510
! The NIST Reference on Constants, Units, and Uncertainty. US National
! Institute of Standards and Technology. June 2015. Retrieved 2017-04-21.
! http://physics.nist.gov/cgi-bin/cuu/Value?r
      REAL( 8 ), PARAMETER :: DRGASUNIV = 8.314459848D0

! standard atmosphere  [ Pa ]
      REAL, PARAMETER :: STDATMPA = 101325.0

! Standard Temperature [ K ]
      REAL, PARAMETER :: STDTEMP = 273.15

! Stefan-Boltzmann [ W/(m**2 K**4) ]
      REAL, PARAMETER :: STFBLZ = 5.67051E-8

! FSB Non-MKS

! Molar volume at STP [ L/mol ] Non MKS units
      REAL, PARAMETER :: MOLVOL = 22.41410

! Atmospheric Constants:

! mean molecular weight for dry air [ g/mol ]
! FSB: 78.06% N2, 21% O2, and 0.943% A on a mole
! fraction basis ( Source : Hobbs, 1995) pp. 69-70
      REAL, PARAMETER :: MWAIR = 28.9628
! dry-air gas constant [ J / kg-K ]
      REAL, PARAMETER :: RDGAS = 1.0E3 * RGASUNIV / MWAIR   ! 287.07548994

! mean molecular weight for water vapor [ g/mol ]
      REAL, PARAMETER :: MWWAT = 18.0153

! gas constant for water vapor [ J/kg-K ]
      REAL, PARAMETER :: RWVAP = 1.0E3 * RGASUNIV / MWWAT   ! 461.52492604

! FSB NOTE: CPD, CVD, CPWVAP and CVWVAP are calculated assuming dry air and
! water vapor are classical ideal gases, i.e. vibration does not contribute
! to internal energy.

! specific heat of dry air at constant pressure [ J/kg-K ]
      REAL, PARAMETER :: CPD = 7.0 * RDGAS / 2.0            ! 1004.7642148

! specific heat of dry air at constant volume [ J/kg-K ]
      REAL, PARAMETER :: CVD = 5.0 * RDGAS / 2.0            ! 717.68872485

! specific heat for water vapor at constant pressure [ J/kg-K ]
      REAL, PARAMETER :: CPWVAP = 4.0 * RWVAP               ! 1846.0997042

! specific heat for water vapor at constant volume [ J/kg-K ]
      REAL, PARAMETER :: CVWVAP = 3.0 * RWVAP               ! 1384.5747781

! vapor press of water at 0 C [ Pa ] Source: CRC76 pp. 6-15
      REAL, PARAMETER :: VP0 = 611.29

! FSB The following values are taken from p. 641 of Stull (1988):

! latent heat of vaporization of water at 0 C [ J/kg ]
      REAL, PARAMETER :: LV0 = 2.501E6

! Rate of change of latent heat of vaporization with
! respect to temperature [ J/kg-K ]
      REAL, PARAMETER :: DLVDT = 2370.0

! latent heat of fusion of water at 0 C [ J/kg ]
      REAL, PARAMETER :: LF0 = 3.34E5
!.......................................................................

!Parameters from PREPLM
      INTEGER, PARAMETER :: DEG = 3       ! degree of interpolationg polynomial
      REAL,    PARAMETER :: CTOK = 273.15 ! conversion from deg. C to deg. K

! Local Variables:
      INTEGER IQ              ! stability class:  1=unstbl, 2=neut, 3=stbl, 4=use DHM
      INTEGER LPLM            ! first L: ZH(L) > Plume height ! same as RADM's KPR
      INTEGER NN              ! counter for interations through layers
      REAL    BFLX            ! buoyancy flux (m**4/s**3)
      REAL    DH              ! plume rise increment to center of the plume
      REAL    DHM             ! plume rise from momentum
      REAL    DHSM            ! stable momentum plume rise
      REAL    DHN             ! plume rise for neutral case
      REAL    DHT             ! plume rise increment to the top of the plume
      REAL    HSTAR           ! convective scale at stack (m**2/s**3)
      REAL    PX, RX, SX      ! scratch coefficients
      REAL    RBFLX           ! residual buoyancy flux (m**4/s**3)
      REAL    TPLM            ! temperature at top of plume (m/s)
      REAL    WPLM            ! wind speed  at top of plume (m/s)
      REAL    ZMIX            ! hmix - hs
! Local Variables from PREPLM
      INTEGER      L, M, I, J
      REAL         ES
      REAL         QSFC
      REAL         TVSFC
      REAL         THETG
      REAL         THV1
      REAL         THVK
!     REAL         TV( EMLAYS )   ! Virtual temperature
!     REAL         TF( EMLAYS )   ! Full-layer height temperatures
      REAL, ALLOCATABLE :: TV( : )   ! Virtual temperature
      REAL, ALLOCATABLE :: TF( : )   ! Full-layer height temperatures
      REAL         P, Q, PP
      REAL         DZZ
      REAL         DELZ
      INTEGER LSTK            ! first L: ZF(L) > STKHT      
      INTEGER LPBL            ! first L: ZF(L) > mixing layer
      REAL    WSTK            ! wind speed @ top of stack [m/s]
      REAL    TSTK            ! temperature @ top of stack [K]
      REAL, ALLOCATABLE :: ZSTK ( : )      ! zf( l ) - stkht [m] 
      REAL, ALLOCATABLE :: DDZF( : )       ! 1/( zf(l) - zf(l-1) )
      REAL, ALLOCATABLE :: DTHDZ( : )      ! potential temp. grad.
      REAL, ALLOCATABLE :: WSPD ( : )      ! wind speed [m/s]
      LOGICAL :: FIRSTIME = .TRUE.
      INTEGER :: STAT
! Statement Functions:
      REAL    B, H, S, U, US  ! arguments
      REAL    NEUTRL          ! neutral-stability plume rise function
      REAL    STABLE          ! stable            plume rise function
      REAL    UNSTBL          ! unstable          plume rise function

      NEUTRL( H, B, U, US ) = &
              MIN( 10.0 * H,  &
              1.2 * (           ( B / ( U * US * US ) ) ** 0.6 &    ! pwr 3 * 0.2
                    * ( H + 1.3 * B / ( U * US * US ) ) ** 0.4 ) ) ! pwr 2 * 0.2
      STABLE( B, U, S ) =  2.6 * ( B / ( U * S ) ) ** D3
      UNSTBL( B, U )    = 30.0 * ( B / U ) ** 0.6

!-----------------------------------------------------------------------

      IF ( FIRSTIME ) THEN
         FIRSTIME = .FALSE.
      END IF


!Begin PREPLM Calculation Functions -------------------
      ALLOCATE ( TV( EMLAYS ), TF( EMLAYS ), ZSTK( EMLAYS ), &
                 DDZF( EMLAYS ), DTHDZ( EMLAYS ), WSPD( EMLAYS ), STAT=STAT )
      IF ( STAT .NE. 0 ) THEN
         WRITE( *, *) ' Cannot allocate TV and TF in PREPLM'
!         CALL M3MSG2( XMSG )
         STOP
      END IF

! Convert pressure to millibars from pascals, compute wind speed,
! and virtual temperature

      DO L = 1, EMLAYS
         P = UW( L )
         Q = VW( L )
         WSPD( L ) = SQRT( P * P + Q * Q )
         TV( L ) = TA( L ) * ( 1.0 + 0.622 * ( QV( L ) / ( 1.0 + QV( L ) ) ) )
      END DO

      ES    = 6.1078 * EXP( 5384.21 / CTOK - 5384.21 / TS )
      QSFC  = 0.622 * ES / ( PSFC - ES )
      TVSFC = TS * ( 1.0 + 0.6077 * QSFC )
      THETG = TVSFC * ( 1000.0 / PSFC ) ** 0.286
      IF ( HMIX .LE. ZF( 1 ) ) LPBL = 1
      IF ( STKHT .LE. ZF( 1 ) ) LSTK = 1

! Interpolate the virtual temperatures at the full-layer face heights (at ZFs)
      DO L = 1, EMLAYS - 1
         ZSTK ( L ) = ZF( L ) - STKHT
         DELZ = ZH( L+1 ) - ZH( L )
         TF( L ) = TV( L ) + ( TV( L+1 ) - TV( L ) ) * ( ZF( L ) - ZH( L ) ) / DELZ
      END DO
      L = EMLAYS
      DELZ = ZH( L ) - ZH( L-1 )
      TF( L ) = TV( L ) + ( TV( L ) - TV( L-1 ) ) * ( ZF( L ) - ZH( L ) ) / DELZ

!     THV1  = TF( 1 ) * ( 1000.0 / PRES( 2 ) ) ** 0.286
      THV1  = TF( 1 ) * ( 1000.0 / PRES( 1 ) ) ** 0.286

!     DTHDZ( 1 ) = ( THV1 - THETG ) / ZF( 1 )

      DO L = 2, EMLAYS

         IF ( HMIX .GT. ZF( L-1 ) ) LPBL = L
         IF ( STKHT .GT. ZF( L-1 ) ) LSTK = L
         
!        THVK = TF( L ) * ( 1000.0 / PRES( L+1 ) ) ** 0.286
         THVK = TF( L ) * ( 1000.0 / PRES( L ) ) ** 0.286
         DDZF ( L ) = ZF( L ) - ZF( L-1 )
         DTHDZ( L ) = DDZF( L ) * ( THVK - THV1 )
         THV1 = THVK

      END DO

! Set the 1st level vertical THETV gradient to the 2nd layer value -
! overrides the layer 1 gradient determined above
      DTHDZ( 1 ) = DTHDZ( 2 )

!      IF ( .NOT. FIREFLG ) THEN
! Interpolate ambient temp. and windspeed to top of stack using DEG deg polynomial
         M    = MAX( 1, LSTK - DEG - 1 )
!         TSTK =      POLY( STKHT, ZH( M:EMLAYS ), TA( M:EMLAYS ), DEG )
!         WSTK = MAX( POLY( STKHT, ZH( M:EMLAYS ), WSPD( M:EMLAYS ), DEG ), 0.1 )

!Simple lagrangian polynomial (i.e., linear) interpolation in place of IOAPI POLY Function - PCC
        PP=1
        DO I = 1, EMLAYS
        DO J = 1, EMLAYS
        IF (I.EQ.J) CYCLE
        PP=PP*(STKHT-ZH(J))/(ZH(I)-ZH(J))
        TSTK=TSTK+PP*TA(I)
        WSTK=WSTK+PP*WSPD(I)
        END DO
        END DO
        WSTK=MAX(WSTK,0.1)
!      ELSE
!         TSTK = TS
!         WSTK = WSPD( 1 )
!      END IF

      DEALLOCATE ( TV, TF, ZSTK, DDZF, DTHDZ, WSPD )


!End PREPLM Calculation Functions -------------------

!Begin Briggs Plume Rise Calculation----------------

! Compute convective scale, buoyancy flux.

      HSTAR = GRAV * HFX / TA( 1 )   ! Using surface temperature is correct
      BFLX  = 0.25 * GRAV * ( STKTK - TSTK ) * STKVE * STKDM * STKDM / STKTK

! Initialize layer of plume
      LPLM  = LSTK

! Compute momentum rise ( set min wind speed to 1 m/s)
      WSTK = MAX( WSTK, 1.0 )
      DHM  = 3.0 * STKDM * STKVE / WSTK

! When BFLX <= zero, use momentum rise only
! NOTE: This part of algorithm added based on Models-3 plume rise

      IF ( BFLX .LE. 0.0 ) THEN
! (06/02) Set the ZPLM plume rise height to the momentum value DHM above
         ZPLM = STKHT + MAX( DHM, 2.0 )
         RETURN
      END IF

! Compute initial plume rise from stack top to next level surface:

      IF ( HSTAR .GT. HCRIT ) THEN           ! unstable case:
         ZMIX = HMIX - STKHT

         IF ( ZMIX .LE. 0.0 ) THEN           ! Stack at or above mixing height:
            SX = MAX( GRAV * DTHDZ( LPLM ) / TSTK, SMALL )

! Reset the wind speed at stack to the wind speed at plume when the layer
! of the plume is not equal to the layer of the stack.
            IF ( LPLM .NE. LSTK ) THEN
               WSTK = MAX( WSPD( LPLM ), 1.0 )
            END IF
            IF ( DTHDZ( LPLM ) .GT. 0.001 ) THEN
! Compute the stable momentum rise, for layer of the stack
               DHSM = 0.646 * ( STKVE * STKVE * STKDM * STKDM &
                    / ( STKTK * WSTK ) ) ** D3 * SQRT( TSTK ) &
                    / DTHDZ( LPLM ) ** D6
            ELSE
               DHSM = DHM    ! set it to DHM, if THGRAD too small
            END IF
            DHM = MIN( DHSM, DHM )
          
! Compute the neutral and stable plume rises          
            DHN = NEUTRL( STKHT, BFLX, WSTK, USTAR )
            DH  = STABLE( BFLX, WSTK, SX )

            IF ( DHN .LT. DH ) THEN  ! Take the minimum of neutral and stable
               DH = DHN
               IQ = 2
            ELSE 
               IQ = 3
            END IF

!           IF ( DHM .GT. DH .AND. WSTK .GT. 1.0 ) THEN
            IF ( DH .LT. DHM ) THEN  ! Take the minimum of the above and momentum rise
               DH = DHM
               IQ = 4
            END IF
            DHT = 1.5 * DH

         ELSE                        !  unstable case:
            DHN = NEUTRL( STKHT, BFLX, WSTK, USTAR )
            DH  = UNSTBL( BFLX, WSTK )

            IF ( DHN .LT. DH ) THEN  ! Take the minimum of neutral and unstable
               DH = DHN
               IQ = 2
            ELSE
               IQ = 1
            END IF

!           IF ( DHM .GT. DH .AND. WSTK .GT. 1.0 ) THEN
            IF ( DH .LT. DHM ) THEN  ! Take the minimum of the above and momentum rise
               DH = DHM
               IQ = 4
            END IF
            DHT = 1.5 * DH
           
         END IF

      ELSE IF ( HSTAR .LT. -HCRIT .OR. DTHDZ( LSTK ) .GT. 0.001 ) THEN   ! stable case:

         SX  = MAX( GRAV * DTHDZ( LSTK ) / TSTK, SMALL )
         DHN = 1.5 * NEUTRL( STKHT, BFLX, WSTK, USTAR )
         DHT = 1.5 * STABLE( BFLX, WSTK, SX )
         IF ( DHN .LT. DHT ) THEN  ! Take the minimum of neutral and stable
            DHT = DHN
            IQ = 2
         ELSE
            IQ = 3
         END IF

      ELSE                              !  neutral case:

         DHT = 1.5 * NEUTRL( STKHT, BFLX, WSTK, USTAR )
         IQ  = 2

      END IF                  !  hstar ==> unstable, stable, or neutral
  
      ZPLM  = DHT

! End calculations if the momentum rise was used in the calculation
!      IF ( IQ .EQ. 4 ) GO TO 199  ! to point past iterative buoyancy loop
     IF ( IQ .NE. 4 ) THEN
! Compute further plume rise from between level surfaces:
      NN = 0
      RBFLX = BFLX

      DO       ! infinite loop computing further plume rise
       
         RX = ZPLM - ZSTK( LPLM )
         IF ( RX .LE. 0.0 ) THEN
            EXIT  ! exit plume rise loop
         END IF

         IF ( LPLM .EQ. EMLAYS ) THEN   ! we're finished
            ZPLM = MIN( ZPLM, ZSTK( EMLAYS ) )
!            WRITE( LOGDEV,'(5X, A, I3, F10.3)' ) &
            write(*,*) 'Plume rise reached EMLAYS with ZPLM:', EMLAYS, ZPLM
            EXIT  ! exit plume rise loop
         END IF

! Reset met data. NOTE - the original RADM code interpolated WSPD and TA,
! but then set the height of interpolation identical to ZH( LPLM ).
         NN = NN + 1
         IF ( NN .GT. 1 ) THEN
            WPLM = WSPD( LPLM )
            TPLM = TA  ( LPLM )
         ELSE                  ! 1st time, use stack values ...
            WPLM = WSTK
            TPLM = TSTK
         END IF
 
! Compute residual bflx by stability case IQ:

         IF ( IQ .EQ. 1 ) THEN
            RX = D45 * RX      ! Includes the 1.5 factor for plume top
            RBFLX = WPLM * ( RX ** FIVETHD )
         ELSE IF ( IQ .EQ. 2 ) THEN
            PX = STKHT + TWOTHD * ZPLM         
            RBFLX = D2664 * ( RX ** FIVETHD ) * WPLM * ( USTAR * USTAR ) / PX ** TWOTHD
         ELSE        !  else iq = 3:
            RBFLX = D59319 * WPLM * SX * RX ** 3
         END IF      !  if stability flag iq is 1, 2, or 3

! Increment the layer number below
         IF ( LPLM .LT. EMLAYS ) LPLM = LPLM + 1
         WPLM = WSPD( LPLM )
         TPLM = TA( LPLM )

! Prevent divide-by-zero by WPLM
         WPLM = MAX( WPLM, 1.0 )

! Process according to stability cases:
         SX = GRAV * DTHDZ( LPLM ) / TPLM
         IF ( SX .GT. SMALL ) THEN               ! stable case:
            DHN = 1.5 * NEUTRL( STKHT, RBFLX, WPLM, USTAR )
            DHT = 1.5 * STABLE( RBFLX, WPLM, SX )
            IF ( DHN .LT. DHT ) THEN  ! Take the minimum of neutral and stable
               DHT = DHN
               IQ  = 2
            ELSE
               IQ  = 3
            END IF
            DH = DHT / 1.5

         ELSE          ! if upper layer is not stable, use neutral formula

            DHN = NEUTRL( STKHT, RBFLX, WPLM, USTAR )
            DH = UNSTBL( RBFLX, WPLM )
            IF ( DHN .LT. DH ) THEN  ! Take the minimum of neutral and unstable
               DH = DHN
               IQ  = 2
            ELSE
               IQ  = 1
            END IF
            DHT = 1.5 * DH

         END IF
  
         ZPLM = ZSTK( LPLM-1 ) + DHT
!        DH   = ZSTK( LPLM-1 ) + DH 
        
      END DO   ! end loop computing further plume rise

!199   CONTINUE
     END IF ! end momentum rise if check

! Adjustment for layer 1 combustion pt. source stacks with plume rise limited
! to layer 1; put plume height in middle of layer 2:
      IF ( STKHT + TWOTHD * ZPLM .LE. ZF( 1 ) .AND. STKTK .GT. TA( 1 ) ) THEN
         ZPLM = ZH( 2 )
      END IF

! set final plume centerline height (ZPLM):
      ZPLM = STKHT + TWOTHD * ZPLM 

      RETURN

!End Briggs Plume Rise Calculation----------------

      END SUBROUTINE PLMRIS

end module plumerise_briggs_mod