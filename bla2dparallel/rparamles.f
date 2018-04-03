c ***********************************************************************
c
c $HeadURL: https://www.mech.kth.se/svn/simson/branches/bla2dparallel/rparamles.f $
c $LastChangedDate: 2007-10-29 14:23:13 +0100 (Mon, 29 Oct 2007) $
c $LastChangedBy: qiang@MECH.KTH.SE $
c $LastChangedRevision: 786 $
c
c ***********************************************************************
      subroutine rparamles(iles,iiles,iiles_smag,
     &     cutoff,iord,ihighorder,my_node,chi,ineg,cs,prt)
      
      implicit none
      include 'par.f'

      integer iles,iord,my_node,ineg,iiles,iiles_smag
      integer ihighorder
      real cutoff,cutoff_inv,chi,cs
      logical endc
      integer version,version_bla
      real prt
c
c     Reads LES parameters from sgs.i
c
      open(unit=10,status='old',file='sgs.i')      
c
c     Default values and explanation
c
      iles = 1
c     iles = 0: no SGS model
c     iles = 1: ADM-RT
c     iles = 2: eddy viscosity
c     iles = 3: HPF eddy viscosity
      cutoff_inv = 1.5
      iord = 5
      chi = 0.2
      ineg = 1
c     ineg = 0: no clipping
c     ineg = 1: clipping to positive values
c     ineg = 2: clipping to positive viscosity
      ihighorder = 2
c     ihighorder = 0: two-dimensional filtering
c     ihighorder = 1: iterative filtering
c     ihighorder = 2: tensorial filtering
      cs = 0.
c     cs = 0 gives dynamic procedure
      prt = 0.6
c     turbulent Prandtl number

c
c     Reads in version
c
      call comment(10)
      read(10,*) version
      version_bla=20060909
      if (version.ne.version_bla) then
         write(*,*) 'Wrong version of sgs.i, now: ',version
         write(*,*) 'bla version is: ',version_bla
         call stopnow(345432)
      end if
c
c     Set LES parameters
c
      call comment(10)
      read(10,*) iles

      if (iles.eq.1) then
c     iles = 1: ADM-RT
         call comment(10)
         read(10,*) cutoff_inv
         call comment(10)
         read(10,*) iord
         call comment(10)
         read(10,*) chi
      else if (iles.eq.2) then
c     iles = 2: dynamic Smagorinsky
         call comment(10)
         read(10,*) cs
         if (cs.eq.0) then
            call comment(10)
            read(10,*) ineg
         end if
      else if (iles.eq.3) then
c     iles = 3: HPF Smagorinsky model
         call comment(10)
         read(10,*) cutoff_inv
         call comment(10)
         read(10,*) iord
         call comment(10)
         read(10,*) cs
         if (cs.eq.0) then
            call comment(10)
            read(10,*) ineg
         end if
      end if
      close(10)
c
c     Calculate/check parameters
c
      if (my_node.eq.0) then
         write(*,*)
         write(*,*)
         write(*,*) '>>>>>>  LES parameters read from sgs.i <<<<<<<'
         write(*,*) '--------------------------------------------'//
     &              '-----------------------'
         write(*,*) 'Version of input file (version)      : ',version
      end if

      endc = .false.

      if (iiles.lt.0.or.iiles.gt.1) then
         write(*,*) 'iiles must be 0 or 1: ',iiles
         endc = .true.
      end if
      if (iiles_smag.lt.0.or.iiles_smag.gt.1) then
         write(*,*) 'iiles_smag must be 0 or 1: ',iiles_smag
         endc = .true.
      end if
      if (iles.ge.1.and.iiles.ne.1) then
         write(*,*) 'Compile with LES support, iiles=1: ',iiles
         endc = .true.
      end if
      if (iles.eq.2.and.iiles_smag.ne.1) then
         write(*,*) 'Compile with Smag. support, iiles_smag=1: ',
     &        iiles_smag
         endc = .true.
      end if
      if (iles.eq.3.and.iiles_smag.ne.1) then
         write(*,*) 'Compile with Smag. support, iiles_smag=1: ',
     &        iiles_smag
         endc = .true.
      end if

      if (iles.lt.0.or.iles.gt.3) then
         write(*,*) 'iles must be between 0 and 3: ',iles
         endc = .true.
      end if
      
      cutoff = 1./cutoff_inv
      if (cutoff.lt.0..or.cutoff.gt.1.) then
         write(*,*) 'cutoff wavenumber must be between 0 and 1: ',
     &        cutoff,cutoff_inv
         endc = .true.
      end if

      if (iord.lt.0.or.iord.gt.5) then
         write(*,*) 'iord must be between 0 and 5: ',iord
         endc = .true.
      end if

      if (ineg.lt.0.or.ineg.gt.2) then
         write(*,*) 'ineg must be between 0 and 2: ',ineg
         endc = .true.
      end if

      if (cs.ne.0.and.ineg.ne.1) then
         write(*,*) 'ineg must be 1: ',ineg
         endc = .true.
      end if

      if (ihighorder.lt.0.or.ihighorder.gt.2) then
         write(*,*) 'ihighorder must be 0,1,2: ',ihighorder
         endc= .true.
      end if

      if (endc) then
         call stopnow(45543)
      end if
c
c     Write out parameters
c
      if (my_node.eq.0) then
         if (iiles.eq.0) then
            write(*,*) 'LES: arrays are not allocated'
         else
            write(*,*) 'LES: arrays are allocated'
         end if
         if (iiles_smag.eq.0) then
            write(*,*) 'LES: Smag. arrays are not allocated'
         else
            write(*,*) 'LES: Smag. arrays are allocated'
         end if

         if (iles.eq.0) then
            write(*,*) 'LES: No SGS model selected'
         else if (iles.eq.1) then
            write(*,*) 'LES: Relaxation-term model (3D)'
            write(*,*) 'LES: w_c=',cutoff
            write(*,*) 'LES: N=',iord
            write(*,*) 'LES: Constant chi=',chi
            write(*,*) 'LES: ihighorder = ',ihighorder
         else if (iles.eq.2) then
            write(*,*) 'LES: Smagorinsky model'
            if (cs.eq.0) then
               write(*,*) 'LES: Dynamic procedure (Germano/Lilly)'
               write(*,*) 'LES: 2D spectral cutoff at pi/2'
               write(*,*) 'LES: Averaging in spanwise direction'
               if (ineg.eq.1) then
                  write(*,*) 'LES: Clipping negative eddy viscosity'
               else if (ineg.eq.2) then
                  write(*,*) 'LES: Clipping negative total viscosity'
               else if (ineg.eq.0) then
                  write(*,*) 'LES: NO CLIPPING'
               end if
            else
               write(*,*) 'LES: Cs=',cs
            end if
         else if (iles.eq.3) then
            write(*,*) 'LES: HPF Smagorinsky model'
            write(*,*) 'LES: w_c=',cutoff
            write(*,*) 'LES: N=',iord
            write(*,*) 'LES: ihighorder = ',ihighorder
            if (cs.eq.0) then
               write(*,*) 'LES: Dynamic procedure (Germano/Lilly)'
               write(*,*) 'LES: 2D spectral cutoff at pi/2'
               write(*,*) 'LES: Averaging in spanwise direction'
               if (ineg.eq.1) then
                  write(*,*) 'LES: Clipping negative eddy viscosity'
               else if (ineg.eq.2) then
                  write(*,*) 'LES: Clipping negative total viscosity'
               else if (ineg.eq.0) then
                  write(*,*) 'LES: NO CLIPPING'
               end if
            else
               write(*,*) 'LES: Cs=',cs
            end if
         else
            write(*,*) 'LES: No valid model'
            call stopnow(35432)
         end if
         if (scalar.gt.0) then
            write(*,*) 'LES: Turbulent Prandtl number Prt=',prt
         end if
      end if

      end subroutine rparamles
