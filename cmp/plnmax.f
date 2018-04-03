c ***********************************************************************
c
c $HeadURL: https://www.mech.kth.se/svn/simson/trunk/cmp/plnmax.f $
c $LastChangedDate: 2007-11-12 13:19:01 +0100 (Mon, 12 Nov 2007) $
c $LastChangedBy: mattias@MECH.KTH.SE $
c $LastChangedRevision: 850 $
c
c ***********************************************************************
      subroutine plnmax(vext,y1,xext,zext,vr,vi,xc1,xc2,zl)
c
c     Finds the max value of a variable and its position in a plane
c
      implicit none

      include 'par.f'

      integer y1
      real vext,xext,zext,zl,xc1(nxp/2+1),xc2(nxp/2+1)
      real vr((nxp/2+1),mby,nzd),vi((nxp/2+1),mby,nzd)
c
      real vmax(nzpc),vmax2,vmax1
      integer x,z,zm
c
c     First do vectorizable reduction in x direction
c
      do z=1,nzpc
         vmax1=-1.E20
         do x=1,nxp/2
            if (vr(x,y1,z).gt.vmax1) vmax1=vr(x,y1,z)
         end do
         do x=1,nxp/2
            if (vi(x,y1,z).gt.vmax1) vmax1=vi(x,y1,z)
         end do
         vmax(z)=vmax1
      end do
c
c     Now do the nonvectorizable reduction in the z direction
c
      vext=-1.E20
      do z=1,nzpc
         if (vmax(z).gt.vext) then
            vext=vmax(z)
            zext=zl*float(z-nzp/2-1)/float(nzp)
            zm=z
         end if
      end do
c
c     Finally find the x-value where the maximum really occured
c
      vmax2=-1.E20
      do x=1,nxp/2
         if (vr(x,y1,zm).gt.vmax2) then
            xext=xc1(x)
            vmax2=vr(x,y1,zm)
         end if
         if (vi(x,y1,zm).gt.vmax2) then
            xext=xc2(x)
            vmax2=vr(x,y1,zm)
         end if
      end do

      return

      end subroutine plnmax
