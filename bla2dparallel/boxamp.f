c ***********************************************************************
c
c $HeadURL: https://www.mech.kth.se/svn/simson/branches/bla2dparallel/boxamp.f $
c $LastChangedDate: 2010-09-07 15:31:07 +0200 (Tue, 07 Sep 2010) $
c $LastChangedBy: pschlatt@MECH.KTH.SE $
c $LastChangedRevision: 1508 $
c
c ***********************************************************************
      subroutine boxamp(amp,campw,kx,kz,nwave,
     &     u2r,u2i,om2r,om2i,th2r,th2i,yb,
     &     alfa,beta,my_node_x,my_node_z,ybp,my_node_world)
c
c     Accumulates the amplitude from an xz-box
c     this version accumulates u(i)**2,om(i)**2
c
      implicit none

      include 'par.f'

      integer yb,nwave,kx(nwave),kz(nwave),zb
      complex campw(nyp,4,nwave)
      real amp(nyp,20)
      real u2r((nxp/2+1),mby,nzd_new/nprocz,3)
      real u2i((nxp/2+1),mby,nzd_new/nprocz,3)
      real om2r((nxp/2+1),mby,nzd_new/nprocz,3)
      real om2i((nxp/2+1),mby,nzd_new/nprocz,3)
      real th2r((nxp/2+1),mby,nzd_new/nprocz,4)
      real th2i((nxp/2+1),mby,nzd_new/nprocz,4)
      real alfa(nx/2),beta(nz)

      integer i,z,y,x,zp,y1,nzz,ybp
      integer my_node_x,my_node_z,my_node_world
      real c
c
c amp(y,1)  streamwise velocity average (squared)
c amp(y,2)  normal velocity average (squared)
c amp(y,3)  spanwise velocity average (squared)
c amp(y,4)  streamwise vorticity average (squared)
c amp(y,5)  normal vorticity average (squared)
c amp(y,6)  spanwise vorticity average (squared) 
c
c amp(y,7)  empty
c amp(y,8)  reynolds stress average
c
c amp(y,9)  mean streamwise velocity
c amp(y,10) mean spanwise velocity
c amp(y,11) mean streamwise vorticity component
c amp(y,12) mean spanwise vorticity component (to calculate wall shear)
c
c amp(y,14) mean theta
c amp(y,15) theta**2
c amp(y,16) mean theta_y
c amp(y,17) theta_y**2
c
c amp(y,13-20) empty 
c
c campw(y,i,wave) complex normal velocity and normal vorticity averages 
c                 from selected wavenumbers
c

      amp(ybp,:) = 0.
c
c     Velocities and vorticities squared
c
      do i=1,3
         do z=1,nzd_new/nprocz
            do x=1,nxp/2
               amp(ybp,i) = amp(ybp,i) + 
     c              u2r (x,1,z,i)**2 + u2i (x,1,z,i)**2
               amp(ybp,i+3) = amp(ybp,i+3) + 
     c              om2r(x,1,z,i)**2 + om2i(x,1,z,i)**2

            end do
         end do
      end do
c
c     Temperature mean and fluctuation
c
      if (scalar.gt.0) then
         do z=1,nzd_new/nprocz
            do x=1,nxp/2
               amp(ybp,14) = amp(ybp,14) + 
     c              th2r (x,1,z,1) + th2i (x,1,z,1)
               amp(ybp,15) = amp(ybp,15) + 
     c              th2r (x,1,z,1)**2 + th2i (x,1,z,1)**2
               amp(ybp,16) = amp(ybp,16) + 
     c              th2r (x,1,z,3) + th2i (x,1,z,3)
               amp(ybp,17) = amp(ybp,17) + 
     c              th2r (x,1,z,3)**2 + th2i (x,1,z,3)**2
            end do
         end do
      end if
c
c     mean and Reynolds stress
c
      do z=1,nzd_new/nprocz
         do x=1,nxp/2
            amp(ybp,8)=amp(ybp,8)+(
     &           u2r(x,1,z,1) * u2r(x,1,z,2) +
     &           u2i(x,1,z,1) * u2i(x,1,z,2) )
            amp(ybp,9)=amp(ybp,9) +   u2r (x,1,z,1) + u2i (x,1,z,1)
            amp(ybp,10)=amp(ybp,10) + u2r (x,1,z,3) + u2i (x,1,z,3)
            amp(ybp,11)=amp(ybp,11) + om2r(x,1,z,1) + om2i(x,1,z,1)
            amp(ybp,12)=amp(ybp,12) + om2r(x,1,z,3) + om2i(x,1,z,3)
         end do
      end do



c     
c     Accumulate energy for selected wavenumbers
c

      if (nwave.gt.0) then
         call stopnow(45543432)
      end if



      end subroutine boxamp
