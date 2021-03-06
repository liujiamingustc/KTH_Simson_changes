c ***********************************************************************
c
c $HeadURL: https://www.mech.kth.se/svn/simson/trunk/bla/plnmin.f $
c $LastChangedDate: 2007-11-12 13:19:01 +0100 (Mon, 12 Nov 2007) $
c $LastChangedBy: mattias@MECH.KTH.SE $
c $LastChangedRevision: 850 $
c
c ***********************************************************************
      subroutine plnmin(vext,y1,xext,zext,vr,vi,xc1,xc2,zl)
c
c     Finds the min value of a variable and its position in a plane
c
      implicit none

      include 'par.f'

      integer y1
      real vext,xext,zext,zl,xc1(nxp/2+1),xc2(nxp/2+1)
      real vr((nxp/2+1),mby,nzd),vi((nxp/2+1),mby,nzd)

      real vmin(nzpc),vmin2,vmin1
      integer x,z,zm
c
c     First do vectorizable reduction in x direction
c
      do z=1,nzpc
         vmin1=1.E20
         do x=1,nxp/2
            if (vr(x,y1,z).lt.vmin1) vmin1=vr(x,y1,z)
         end do
         do x=1,nxp/2
            if (vi(x,y1,z).lt.vmin1) vmin1=vi(x,y1,z)
         end do
         vmin(z)=vmin1
      end do
c
c     Now do the nonvectorizable reduction in the z direction
c
      vext=1.E20
      do z=1,nzpc
         if (vmin(z).lt.vext) then
            vext=vmin(z)
            zext=zl*real(z-nzp/2-1)/real(nzp)
            zm=z
         end if
      end do
c
c     Finally find the x-value where the minimum really occured
c
      vmin2=1.E20
      do x=1,nxp/2
         if (vr(x,y1,zm).lt.vmin2) then
            xext=xc1(x)
            vmin2=vr(x,y1,zm)
         end if
         if (vi(x,y1,zm).lt.vmin2) then
            xext=xc2(x)
            vmin2=vi(x,y1,zm)
         end if
      end do

      end subroutine plnmin
