# compiler
FC := gfortran

# compile flags
FCFLAGS = -g -c -Wall -Wextra -Wconversion -Og -pedantic -fcheck=bounds -fmax-errors=5
# link flags
FLFLAGS =

# source files and objects
SRCS = plumerise_briggs_mod.F90 briggs_driver.F90

# program name
PROGRAM = sofiev

all: $(PROGRAM)

$(PROGRAM): $(SRCS)
	$(FC) $(FLFLAGS) -o $@ $^

%.mod: %.F90
	$(FC) $(FCFLAGS) -o $@ $<

%.o: %.F90
	$(FC) $(FCFLAGS) -o $@ $<

clean:
	rm -f *.o *.mod $(PROGRAM)
