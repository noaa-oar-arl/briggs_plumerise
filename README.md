# briggs_plumerise
Standalone driver/model for Briggs Plume rise from CMAQv5.3.1

Column Inputs:
        real    :: zf           !Layer surface heights (m)
        real    :: zh           !Layer center  heights (m)
        real    :: pres         !Pressures at full layer hts (hPa)
        real    :: ta           !Temperatures (K)
        real    :: qv           !Mixing Ratios (kg/kg)
        real    :: uw           !X-direction winds (m/s)
        real    :: vw           !Y-direction winds (m/s)
Surface Inputs:        
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
Outputs:
        real plmHGT    !final plume centerline height (m)
