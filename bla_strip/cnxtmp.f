c ***********************************************************************
c
c $HeadURL: https://www.mech.kth.se/svn/simson/trunk/bla/cnxtmp.f $
c $LastChangedDate: 2007-11-12 13:19:01 +0100 (Mon, 12 Nov 2007) $
c $LastChangedBy: mattias@MECH.KTH.SE $
c $LastChangedRevision: 850 $
c
c ***********************************************************************
      subroutine cnxtmp(nxtmp,xl,xlold,nxp,nfxd)
c
c     Calculates intermediate number of points in streamwise
c     direction and adjusts xl for box extention.
c
      implicit none

      real xl,xlold,a
      integer nxp,nxtmp,i,j,k,nfxd
      real close

      if (xlold.eq.0.) nxtmp=nxp

      close=3000.
      do i=1+nfxd,15
         do j=0,7
            do k=0,5
               a=2**i * 3**j * 5**k
               if (abs(a-nxtmp).lt.abs(close-nxtmp)) close=a
            end do
         end do
      end do

      nxtmp=close+1.e-9
      if (xlold.gt.1.e-9.and.(xl*real(nxtmp).ne.xlold*real(nxp)))
     &     xl=xlold*real(nxp/nxtmp)

      end subroutine cnxtmp
