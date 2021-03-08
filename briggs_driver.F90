      program briggs_driver

!  the driver to run the Briggs plume rise algorithm
!
!  Ref: M. Sofiev et al., Evaluation of the smoke-injection
!    height from wild-land fires using remote sensing data.
!    Atmos. Chem. Phys., 12, 1995-2006, 2012.
!
!  History:
!    Prototype: Patrick Campbell, 02/26/2021
!
!-------------------------------------------------------------
      use plumerise_briggs_mod

      implicit none

! ! ... this block gives example emiss layers, 2D parameters, and stack inputs to 
! !     Briggs that would be passed by rrfs_cmaq/ccpp
! !     Ex values taken from NAQFC 5X (i=329;j=161) on Aug 01,2019
        integer, parameter    ::    emlays=35          !Number of total emission layers
        real,    parameter    ::    hfx=25.0           !Sensible Heat Flux (W/m2)
        real,    parameter    ::    hmix=500.0         !Mixing Height (m)
        real,    parameter    ::    ustar=0.2          !Friction velocity (m/s)
        real,    parameter    ::    tsfc=291.0         !Surface temperature (K)
        real,    parameter    ::    psfc=980.0         !Surface pressure (hPa)
        real,    parameter    ::    stkdm=7.0          !Stack diameter (m)
        real,    parameter    ::    stkht=181.0        !Stack height (m)
        real,    parameter    ::    stktk=348.0        !Stack exit temperature (K)
        real,    parameter    ::    stkve=27.0         !Stack exit velocity (m/s)

        integer i,i0
        real :: plmHGT               !final plume centerline height (m)
        real :: plmFRAC  ( emlays )  ! final plume fractions

!     met 3D input profile data that should be passed by rrfs_cmaq/ccpp
      TYPE :: profile_type
        integer :: lay          !Layer number
        real    :: zf           !Layer surface heights (m)
        real    :: zh           !Layer center  heights (m)
        real    :: pres         !Pressures at full layer hts (hPa)
        real    :: ta           !Temperatures (K)
        real    :: qv           !Mixing Ratios (kg/kg)
        real    :: uw           !X-direction winds (m/s)
        real    :: vw           !Y-direction winds (m/s)
      end TYPE profile_type

      type(profile_type) :: profile( emlays )

! ... read met profile data that should be passed by rrfs_cmaq/ccpp
      open(9,  file='input_profile.txt',  status='old')
      i0 = 0
      read(9,*,iostat=i0)  	! skip headline
      do i=1, 35
        read(9, *) profile(i)
      end do

      call plmris(profile%zf,profile%zh,profile%ta,profile%qv, &
                  profile%uw,profile%vw,profile%pres, &
                  hfx,hmix,ustar,tsfc,psfc,emlays, &
                  stkdm,stkht,stktk,stkve,plmHGT,plmFRAC)

      write(*,*)  'Stack Height (m):' , stkht
      write(*,*)  'Plume Center Height (m):' , plmHGT
      write(*,*)  'Plume Fractions:' , plmFRAC

    end program briggs_driver
