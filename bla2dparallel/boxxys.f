c ***********************************************************************
c
c $HeadURL: https://www.mech.kth.se/svn/simson/branches/bla2dparallel/boxxys.f $
c $LastChangedDate: 2012-02-13 11:33:58 +0100 (Mon, 13 Feb 2012) $
c $LastChangedBy: wei@MECH.KTH.SE $
c $LastChangedRevision: 1762 $
c
c ***********************************************************************
      subroutine boxxys(xys,xysth,tc,xs,zs,yb,dtn,ur,ui,
     &     u0low,w0low,prexn,prezn,presn,prean,
     &     alfa,beta,u2r,u2i,h2r,h2i,om2i,om2r,wr,wi,
     &     du2r,du2i,th2r,th2i,corrf,corrf_x,corrxi,corryi,corrzi,
     &     corryi_x,corr,corr_x,corrwsave,corrwsave_x,ncorr,ncorr_x,
     &     corrxodd,corrt,corrt_x,corr_ms,corr_ms_x,it,
     &     my_node_world,realg1,realg2,realg5,realg6,
     &     my_node_z,my_node_x,my_comm_z,my_comm_x,
     &     taur,taui,tau2r,tau2i,iles,
     &     series,serci,sert,serf,nser,sercount,re,fltype,dstar,
     &     pert,bu3,bu4,bom3,bom4,
     &     fmhdr,fmhdi,j2r,j2i,b0,imhd,px,mflux,mhd_n,
     &     boxr_z,boxi_z,dboxr_z,dboxi_z,boxr,boxi,wr_z,wi_z,
     &     wr_x,wi_x,gboxr_z,gboxi_z,ybp)
c      
c     Accumulates statistics dependent on the x and y coordinate
c     from one box
c
      implicit none

      include 'par.f'
#ifdef MPI
      include 'mpif.h'
#endif
      real xys  (nx,nyp/nprocz+1,nxys)
      real xysth(nx,nyp/nprocz+1,nxysth,scalar)
      real xs,zs,dtn
      integer yb,it,is,ie,ixy
      real dstar
      real u0low,w0low
      real ur(memnx,memny,memnz,memnxyz),ui(memnx,memny,memnz,memnxyz)
      real wr(nxp/2+1,mby,nzd_new/nprocz)
      real wi(nxp/2+1,mby,nzd_new/nprocz)
      real u2r ((nxp/2+1)*mby,nzd_new/nprocz,3)
      real u2i ((nxp/2+1)*mby,nzd_new/nprocz,3)
      real om2r((nxp/2+1)*mby,nzd_new/nprocz,3)
      real om2i((nxp/2+1)*mby,nzd_new/nprocz,3)
      real th2r((nxp/2+1)*mby,nzd_new/nprocz,4,scalar)
      real th2i((nxp/2+1)*mby,nzd_new/nprocz,4,scalar)
      real h2r ((nxp/2+1)*mby,nzd_new/nprocz,3)
      real h2i ((nxp/2+1)*mby,nzd_new/nprocz,3)
      real du2r((nxp/2+1)*mby,nzd_new/nprocz,3,3)
      real du2i((nxp/2+1)*mby,nzd_new/nprocz,3,3)
      real prexn(nx+15),prezn(nz*2+15),presn(nz+2+15),prean(nz*3/4+15)
      real alfa(nx/2*mbz),beta(nz)
c
c     Base flow necessary for perturbation mode
c
      real bu3((nxp/2+1),nyp,3+scalar),bu4((nxp/2+1),nyp,3+scalar)
      real bom3((nxp/2+1),nyp,3),bom4((nxp/2+1),nyp,3)
      logical pert

      integer nxy,npl
      integer x,y,xy,z,i,j,k,fltype,ith,tth,xb,xp,yp 
      real c,c1,tc,re

      real sabsr,sr1,sr2,sr3,sr4,sr5,sr6
      real sabsi,si1,si2,si3,si4,si5,si6
c
c     Two-point correlation
c
      logical corrf,corrf_x
      integer corrxi(mcorr),corryi(mcorr),corrxodd(mcorr)
      integer corrzi(mcorr),corrzi_x(mcorr)
      integer corrt(mcorr)
      integer corrxi_x(mcorr),corryi_x(mcorr)
      integer corrt_x(mcorr)
      real corrval1(nzc+2),corrval2(nzc+2),corrwsave(nzc+15),cw(nzc+2)
      real corrval3(2,nzc+2)
      real corrval4(2,nzc+2)

      real corrvaltemp3(2,nzc+2),corrvaltemp4(2,nzc+2)
      real corrztemp1(nzc+2),corrztemp2(nzc+2)
 
      real corrval1x(nx+2),corrval2x(nx+2)
      real corrwsave_x(nx+15),cw_x(nx+2)
      real corr(nzc+2,mcorr),corr_ms(4,mcorr)
      real corr_x(nx+2,mcorr),corr_ms_x(4,mcorr)
      integer ncorr,zb,ncorr_x,k_ind

      integer  ixyouter,ixyinner,ngroupz,zzz,zzznode
c
c     umax
c
      real ut1,ut2,umax1,umax2,umin1,umin2
c
c     MPI
c
      integer my_node_world
      integer realg1,realg2,realg5,realg6
      integer my_node_z,my_node_x,my_comm_z,my_comm_x
      integer ybp
#ifdef MPI
      integer ierror
      real boxr_z(memnx,nzd_new,6)
      real boxi_z(memnx,nzd_new,6)
      real dboxr_z(memnx,nzd_new,3,3)
      real dboxi_z(memnx,nzd_new,3,3)
      real boxr(memnx,nzd_new,4*scalar+3*pressure)
      real boxi(memnx,nzd_new,4*scalar+3*pressure)
      real wr_z(memnx,nzd_new)
      real wi_z(memnx,nzd_new)
      real wr_x(nxp/2+1,nzd_new/nprocz)
      real wi_x(nxp/2+1,nzd_new/nprocz)
      integer status(mpi_status_size)
      integer status1(mpi_status_size)
#endif
c
c     LES
c
      integer iles
      real taur (memnx,memny,memnz,6)
      real taui (memnx,memny,memnz,6)
      real tau2r((nxp/2+1)*mby,nzd_new/nprocz,6)
      real tau2i((nxp/2+1)*mby,nzd_new/nprocz,6)
      real dr,di
      real gboxr_z(memnx,nzd_new,6)
      real gboxi_z(memnx,nzd_new,6)
c
c     MHD
c     
      real fmhdr(memnx,memny,memnz,2)
      real fmhdi(memnx,memny,memnz,2)
      real j2r((nxp/2+1)*mby,nzd,4)
      real j2i((nxp/2+1)*mby,nzd,4)      
      real b0(3),px,mflux,mhd_n
      integer imhd
c
c     Time series
c
      real series(msamp,0:mser)
      integer serci(4,mser)
      integer sert(mser)
      logical serf
      integer nser,sercount
      integer ii,jj
c
c     Spectra
c
      logical specf,specf_
      character(len=5) ch
      integer,parameter ::  maxtcorr=240
c     53 or 240


      specf = .false.
      specf_ = .false.


c
c     ******************************************************************
c     **                                                              **
c     **           STATISTICS                                         **
c     **                                                              **
c     ******************************************************************
c
c     Velocity/pressure statistics (xys):
c     ----------------------------
c     1-  3 : u,v,w
c     4-  6 : u^2,v^2,w^2
c     7-  9 : vorticities
c    10- 12 : vorticities squared
c    13- 15 : uv,uw,vw
c    16- 24 : two-point correlation (NOT IMPLEMENTED)
c    25- 30 : dissipation tensor re*reps_ij = dui/dxk duj/dxk
c        31 : pressure
c        32 : pressure squared
c    33- 35 : up,vp,wp
c    36- 38 : p ux, p vy, p wz
c    39- 40 : p uy, p vz
c    41- 42 : p wx, p uz
c    43- 44 : min/max u
c        45 : S_ij S_ij
c    46- 51 : strain-rate tensor S_ij
c        52 : LES model coefficient C (added in les.f)
c        53 : tau_ij S_ij
c    54- 59 : tau_ij
c        60 : nu_t (added in les.f)
c    61- 62 : tau_ij S_ij (forward/backscatter)
c    63- 65 : velocity skewness   
c    66- 72 : triple velocity correlation
c    73- 74 : p vx, p wy
c    75- 77 : velocity flatness
c    78- 79 : pressure skewness and flatness
c    80- 82 : <tau_ij u_j>
c    83- 84 : <phi>,<phi^2>
c    85- 93 : <j_i>,<j_i^2>,<j1j2>,<j1j3>,<j2j3> 
c    94- 96 : <phi j_i>
c
c
c
c     Scalar statistics (xysth):
c     -----------------
c         1 : theta
c         2 : theta squared
c      3- 5 : u_i theta
c      6- 8 : u_i theta^2
c      9-11 : dtheta/dxi dtheta/dxi
c     12-15 : scalar-pressure correlations
c     16-21 : velocity^2-scalar correlations
c     22-30 : u_j dtheta/dxi   
c     31-33 : Scalar-velocity "dissipation" dui/dxj dtheta/dxj
c     34-35 : scalar skewness and flatness
c
c     ******************************************************************
c
c     The next line helped on the IBM SP-3 for large cases
c     static xy,du2r,du2i
c

c      call mpi_barrier(mpi_comm_world,ierror)

      npl=min(mby,nyp-yb+1)
      nxy=(nxp/2+1)*npl-(nxp/2+1-nx/2)
      xb=mod(my_node_world,nprocx)*memnx
      zb = mod(my_node_world,nprocz)*memnz+1
c
c     Nullify the statistics arrays
c
      du2r = 0.0
      du2i = 0.0
      u2r  = 0.0
      u2i  = 0.0
      om2r = 0.0
      om2i = 0.0

      if (scalar.ge.1.and.nxysth.gt.0) then
         th2r = 0.0
         th2i = 0.0
      end if
      if (pressure.eq.1) then
         h2r = 0.0
         h2i = 0.0
      end if
      if (imhd.eq.1) then
         j2r = 0.
         j2i = 0.
      end if
#ifdef MPI
      boxr_z = 0.0
      boxi_z = 0.0
      dboxr_z = 0.0
      dboxi_z = 0.0
      boxr = 0.0
      boxi = 0.0
      if (iles.gt.0) then
         gboxr_z=0.0
         gboxi_z=0.0
      end if
#endif


c
c     Find velocities and vorticities (computed in linearbl/prhs)
c
      if (nproc.eq.1) then
         do i=1,3
            call getxz(u2r(1,1,i),u2i(1,1,i),yb,i,0,ur,ui)
         end do
         call getxz(om2r(1,1,1),om2i(1,1,1),yb,4,0,ur,ui)
         call getxz(om2r(1,1,3),om2i(1,1,3),yb,5,0,ur,ui)
c
c     Find scalar and its derivative in y direcction
c
         if (nxysth.gt.0) then
            do ith=1,scalar
               call getxz(th2r(1,1,1,ith),th2i(1,1,1,ith),
     &              yb,8+pressure+3*(ith-1),0,ur,ui)
               call getxz(th2r(1,1,3,ith),th2i(1,1,3,ith),
     &              yb,9+pressure+3*(ith-1),0,ur,ui)
            end do
         end if
c
c     Find pressure
c
         if (pressure.eq.1) then
            call getxz(h2r(1,1,1),h2i(1,1,1),yb,8,0,ur,ui)
         end if
      
      else
#ifdef MPI
         do i=1,3
            call getpxz_z(boxr_z(1,1,i),boxi_z(1,1,i),yb,i,0,ur,ui,
     &           realg1,realg2,my_node_z,my_comm_z,my_node_world)
         end do
c
c     Compute the wall-normal vorticity
c
ccccc symmetry is not considered here
         do z=1,nzc
            do y=yb,min(nyp,yb+mby-1)
               do xp=1,memnx
                  x=xp+xb
                  xy=xp+(y-yb)*(nxp/2+1)
                  boxr_z(xy,z,5)=-beta(z)*boxi_z(xy,z,1)
     &                 +alfa(x)*boxi_z(xy,z,3)
                  boxi_z(xy,z,5)= beta(z)*boxr_z(xy,z,1)
     &                 -alfa(x)*boxr_z(xy,z,3)
               end do
            end do
         end do

         if (nxysth.gt.0) then
            do ith=1,scalar
               call getpxz_z(boxr(1,1,1+4*(ith-1)),boxi(1,1,1+4*(ith-1))
     &              ,yb,8+pressure+3*(ith-1),0,ur,ui,
     &              realg1,realg2,my_node_z,my_comm_z,my_node_world)
               call getpxz_z(boxr(1,1,3+4*(ith-1)),boxi(1,1,3+4*(ith-1))
     &              ,yb,9+pressure+3*(ith-1),0,ur,ui,
     &              realg1,realg2,my_node_z,my_comm_z,my_node_world)
            end do
         end if
c
c     Compute the derivatives of theta th2(:,:,1) in 2,4
c
ccccc symmetry is not considered here
         do ith=1,scalar
            do z=1,nzc
               do y=yb,min(nyp,yb+mby-1)
                  do xp=1,memnx
                     x=xp+xb
                     xy=xp+(y-yb)*(nxp/2+1)
c
c     Calculate x derivative
c                   
                     boxr(xy,z,2+4*(ith-1))=-alfa(x)
     &                    *boxi(xy,z,1+4*(ith-1))
                     boxi(xy,z,2+4*(ith-1))= alfa(x)
     &                    *boxr(xy,z,1+4*(ith-1))
c
c     Calculate z derivative
c
                     boxr(xy,z,4+4*(ith-1))=-beta(z)
     &                    *boxi(xy,z,1+4*(ith-1))
                     boxi(xy,z,4+4*(ith-1))= beta(z)
     &                    *boxr(xy,z,1+4*(ith-1))
                  end do
               end do
            end do
         end do
         if (nfzsym.eq.0) then
c     
c     Oddball zeroing only
c     Only for even nz, take away centre row
c
            if (mod(nz,2).eq.0) then
               do x=1,memnx*npl
                  boxr_z(x,nz/2+1,5)=0.0
                  boxi_z(x,nz/2+1,5)=0.0
               end do
            end if
            do ith=1,scalar
               do xy=1,memnx*npl
                  boxr(xy,nz/2+1,2+4*(ith-1))=0.0
                  boxi(xy,nz/2+1,2+4*(ith-1))=0.0
                  
                  boxr(xy,nz/2+1,4+4*(ith-1))=0.0
                  boxi(xy,nz/2+1,4+4*(ith-1))=0.0
               end do
            end do
         end if
c
c     Subtract lower wall shifting velocity
c
c         write(*,*)u0low,w0low
         if (yb.eq.1) then
            do y=1,npl
               xy=1+(y-1)*(nxp/2+1)
c               boxr_z(xy,1,1)=boxr_z(xy,1,1)-u0low
c               boxr_z(xy,1,3)=boxr_z(xy,1,3)-w0low
            end do
         end if
         call getpxz_z(boxr_z(1,1,4),boxi_z(1,1,4),yb,4,0,ur,ui,
     &        realg1,realg2,my_node_z,my_comm_z,my_node_world)
         call getpxz_z(boxr_z(1,1,6),boxi_z(1,1,6),yb,5,0,ur,ui,
     &        realg1,realg2,my_node_z,my_comm_z,my_node_world)
         

         if (pressure.eq.1) then
               call getpxz_z(boxr(1,1,1+4*scalar),boxi(1,1,1+4*scalar)
     &              ,yb,8,0,ur,ui,
     &              realg1,realg2,my_node_z,my_comm_z,my_node_world)
         end if
c
c     Calculate all velocity derivatives
c     Horizontal derivatives by multiplication by alfa or beta
c
         do i=1,3      
            do z=1,nzc
               do y=1,npl
                  do xp=1,memnx
                     x=xp+xb        
                     xy=xp+(y-1)*(nxp/2+1)
                     dboxr_z(xy,z,i,1)=-alfa(x)*boxi_z(xy,z,i)
                     dboxi_z(xy,z,i,1)= alfa(x)*boxr_z(xy,z,i)
                     dboxr_z(xy,z,i,3)=-beta(z)*boxi_z(xy,z,i)
                     dboxi_z(xy,z,i,3)= beta(z)*boxr_z(xy,z,i)
                  end do
               end do
            end do
         end do
c
c     Calculate pressure derivatives
c
         if (pressure.eq.1) then
            do z=1,nzc
               do y=1,npl
                  do xp=1,memnx
                     x=xp+xb
                     xy=xp+(y-1)*(nxp/2+1)
                     boxr(xy,z,2+4*scalar)=-alfa(x)*
     &                    boxi(xy,z,1+4*scalar)
                     boxi(xy,z,2+4*scalar)=alfa(x)*
     &                    boxr(xy,z,1+4*scalar)
                     boxr(xy,z,3+4*scalar)=-beta(z)*
     &                    boxi(xy,z,1+4*scalar)
                     boxi(xy,z,3+4*scalar)=beta(z)*
     &                    boxr(xy,z,1+4*scalar)
c                  h2r(xy,z,2)=-alfa(x)*h2i(xy,z,1)
c                  h2i(xy,z,2)= alfa(x)*h2r(xy,z,1)
c                  h2r(xy,z,3)=-beta(z)*h2i(xy,z,1)
c                  h2i(xy,z,3)= beta(z)*h2r(xy,z,1)
                  end do
               end do
            end do
         end if
c
c     The wall normal derivatives can be found from :
c     omx= dwdy-dvdz
c     omz= dvdx-dudy
c     i.e. :
c     dudy= dvdx-omz
c     dvdy=-dudx-dwdz   (from continuity)
c     dwdy= omx+dvdz
c
         do z=1,nzc
            do y=1,npl
               do xp=1,memnx
                  x=xp+xb        
                  xy=xp+(y-1)*(nxp/2+1)
                  dboxr_z(xy,z,1,2)=-alfa(x)*boxi_z(xy,z,2)
     &                 -boxr_z(xy,z,6)
                  dboxi_z(xy,z,1,2)= alfa(x)*boxr_z(xy,z,2)
     &                 -boxi_z(xy,z,6)
                  dboxr_z(xy,z,2,2)= alfa(x)*boxi_z(xy,z,1)
     &                 +beta(z)*boxi_z(xy,z,3)
                  dboxi_z(xy,z,2,2)=-alfa(x)*boxr_z(xy,z,1)
     &                 -beta(z)*boxr_z(xy,z,3)
                  dboxr_z(xy,z,3,2)=boxr_z(xy,z,4)
     &                 -beta(z)*boxi_z(xy,z,2)
                  dboxi_z(xy,z,3,2)=boxi_z(xy,z,4)
     &                 +beta(z)*boxr_z(xy,z,2)
               end do
            end do
         end do
c     
c     Backward Fourier transform in z
c     
         if (nfzsym.eq.0) then
            do i=1,6
c               call xzsh(boxr_z(1,1,i),boxi_z(1,1,i),xs,zs,alfa,beta,yb)
               call vcfftb(boxr_z(1,1,i),boxi_z(1,1,i),wr_z,wi_z,
     &              nz,memnx,memnx,1,prezn)
            end do
            do i=1,3
               do j=1,3
c                  call xzsh(dboxr_z(1,1,i,j),dboxi_z(1,1,i,j),xs,zs
c     &                 ,alfa,beta,yb)
                  call vcfftb(dboxr_z(1,1,i,j),dboxi_z(1,1,i,j),
     &                 wr_z,wi_z,nz,memnx,memnx,1,prezn)
               end do
            end do
         end if       
c     
c     Maybe some shifting (as above) could be done here as well.
c
         if (nxysth.gt.0.and.nfzsym.eq.0) then
            do ith=1,scalar
               do i=1,4
             call vcfftb(boxr(1,1,i+4*(ith-1)),boxi(1,1,i+4*(ith-1)),
     &                 wr_z,wi_z,nz,memnx,memnx,1,prezn)
               end do
            end do
         end if
         if (pressure.eq.1) then
            do i=1,3
               call vcfftb(boxr(1,1,i+4*scalar),boxi(1,1,i+4*scalar),
     &              wr_z,wi_z,nz,memnx,memnx,1,prezn)
            end do
         end if

         do i=1,3
            call getpxz_x(u2r(1,1,i),u2i(1,1,i),yb,i,0,
     &           boxr_z(1,1,i),boxi_z(1,1,i),
     &           realg5,realg6,my_node_x,my_comm_x,my_node_world)
            call getpxz_x(om2r(1,1,i),om2i(1,1,i),yb,i+3,0,
     &           boxr_z(1,1,i+3),boxi_z(1,1,i+3),
     &           realg5,realg6,my_node_x,my_comm_x,my_node_world)
            do j=1,3
               call getpxz_x(du2r(1,1,i,j),du2i(1,1,i,j),yb,i,0,
     &              dboxr_z(1,1,i,j),dboxi_z(1,1,i,j),
     &              realg5,realg6,my_node_x,my_comm_x,my_node_world)
            end do
         end do

         if (nxysth.gt.0) then
            do ith=1,scalar
               do i=1,4
                  call getpxz_x(th2r(1,1,i,ith),th2i(1,1,i,ith)
     &                 ,yb,8+pressure+3*(ith-1),0,
     &                 boxr(1,1,i+4*(ith-1)),boxi(1,1,i+4*(ith-1)),
     &                 realg5,realg6,my_node_x,my_comm_x,my_node_world)
               end do
            end do
         end if
         if (pressure.eq.1) then
               do i=1,3
                  call getpxz_x(h2r(1,1,i),h2i(1,1,i)
     &                 ,yb,8,0,
     &                 boxr(1,1,i+4*scalar),boxi(1,1,i+4*scalar),
     &                 realg5,realg6,my_node_x,my_comm_x,my_node_world)
               end do
         end if
c     
c     Backward Fourier transform in x
c     
         if (nfzsym.eq.0) then
            do i=1,3
               call vrfftb(u2r(1,1,i),u2i(1,1,i),wr_x,wi_x,
     &              nx,memnz,1,nxp/2+1,prexn)
               call vrfftb(om2r(1,1,i),om2i(1,1,i),wr_x,wi_x,
     &              nx,memnz,1,nxp/2+1,prexn)
               do j=1,3
                  call vrfftb(du2r(1,1,i,j),du2i(1,1,i,j),wr_x,wi_x,
     &                 nx,memnz,1,nxp/2+1,prexn)
               end do
            end do
         end if

         if (nxysth.gt.0.and.nfzsym.eq.0) then
            do ith=1,scalar
               do i=1,4
               call vrfftb(th2r(1,1,i,ith),th2i(1,1,i,ith),
     &                 wr_x,wi_x,nx,memnz,1,nxp/2+1,prexn)
               end do
            end do
         end if
         if (pressure.eq.1) then
            do i=1,3
               call vrfftb(h2r(1,1,i),h2i(1,1,i),wr_x,wi_x,
     &              nx,memnz,1,nxp/2+1,prexn)
            end do
         end if
#endif
      end if


      if (nproc.eq.1) then
c
c     Calculate missing vorticity omega_y
c
         do z=1,nzc
            do y=yb,min(nyp,yb+mby-1)
               do x=1,nx/2
                  xy=x+(y-yb)*(nxp/2+1)
                  om2r(xy,z,2)=-beta(z)*u2i(xy,z,1)+alfa(x)*u2i(xy,z,3)
                  om2i(xy,z,2)= beta(z)*u2r(xy,z,1)-alfa(x)*u2r(xy,z,3)
               end do
               om2r(nx/2+1+(y-yb)*(nxp/2+1),z,2)=0.0 
            end do
         end do
c
c     Calculate x and z derivatives for scalar field
c
         if (nxysth.gt.0) then
            do ith=1,scalar
               do z=1,nzc
                  do y=yb,min(nyp,yb+mby-1)
                     do x=1,nx/2
                        xy=x+(y-yb)*(nxp/2+1)
c
c     Calculate x derivative
c
                        th2r(xy,z,2,ith)=-alfa(x)*
     &                       th2i(xy,z,1,ith)
                        th2i(xy,z,2,ith)= alfa(x)*
     &                       th2r(xy,z,1,ith)
c     
c     Calculate z derivative
c     
                        th2r(xy,z,4,ith)=-beta(z)*
     &                       th2i(xy,z,1,ith)
                        th2i(xy,z,4,ith)= beta(z)*
     &                       th2r(xy,z,1,ith)
                     end do
                     th2r(nx/2+1+(y-yb)*(nxp/2+1),z,2,ith)=0.0 
                     th2r(nx/2+1+(y-yb)*(nxp/2+1),z,4,ith)=0.0 
                  end do
               end do
            end do
         end if
         
         if (nfzsym.eq.0) then
c     
c     Zero oddball (z)
c     
            do xy=1,(nxp/2+1)*npl
               om2r(xy,nz/2+1,2)=0.0
               om2i(xy,nz/2+1,2)=0.0
            end do
            if (nxysth.gt.0) then
               do ith=1,scalar
                  do xy=1,(nxp/2+1)*npl
                     th2r(xy,nz/2+1,2,ith)=0.0
                     th2i(xy,nz/2+1,2,ith)=0.0
                     th2r(xy,nz/2+1,4,ith)=0.0
                     th2i(xy,nz/2+1,4,ith)=0.0
                  end do
               end do
            end if
         end if
c     
c     Subtract lower wall shifting velocity
c
         do y=1,npl
            xy=1+(y-1)*(nxp/2+1)
c            u2r(xy,1,1)=u2r(xy,1,1)-u0low
c            u2r(xy,1,3)=u2r(xy,1,3)-w0low
         end do
c
c     Calculate all velocity derivatives
c     Horizontal derivatives by multiplication by alfa or beta
c
         do i=1,3      
            do z=1,nzc
               do y=1,npl
                  do x=1,nx/2        
                     xy=x+(y-1)*(nxp/2+1)
                     du2r(xy,z,i,1)=-alfa(x)*u2i(xy,z,i)
                     du2i(xy,z,i,1)= alfa(x)*u2r(xy,z,i)
                     du2r(xy,z,i,3)=-beta(z)*u2i(xy,z,i)
                     du2i(xy,z,i,3)= beta(z)*u2r(xy,z,i)
                  end do
               end do
            end do
         end do
c
c     Calculate pressure derivatives
c
         if (pressure.eq.1) then
            do z=1,nzc
               do y=1,npl
                  do x=1,nx/2
                     xy=x+(y-1)*(nxp/2+1)
                     h2r(xy,z,2)=-alfa(x)*h2i(xy,z,1)
                     h2i(xy,z,2)= alfa(x)*h2r(xy,z,1)
                     h2r(xy,z,3)=-beta(z)*h2i(xy,z,1)
                     h2i(xy,z,3)= beta(z)*h2r(xy,z,1)
                  end do
               end do
            end do
         end if
c
c     The wall normal derivatives can be found from :
c     omx= dwdy-dvdz
c     omz= dvdx-dudy
c     i.e. :
c     dudy= dvdx-omz
c     dvdy=-dudx-dwdz   (from continuity)
c     dwdy= omx+dvdz
c
         do z=1,nzc
            do y=1,npl
               do x=1,nx/2        
                  xy=x+(y-1)*(nxp/2+1)
                  du2r(xy,z,1,2)=-alfa(x)*u2i(xy,z,2)-om2r(xy,z,3)
                  du2i(xy,z,1,2)= alfa(x)*u2r(xy,z,2)-om2i(xy,z,3)
                  du2r(xy,z,2,2)= alfa(x)*u2i(xy,z,1)
     &                 +beta(z)*u2i(xy,z,3)
                  du2i(xy,z,2,2)=-alfa(x)*u2r(xy,z,1)
     &                 -beta(z)*u2r(xy,z,3)
                  du2r(xy,z,3,2)=om2r(xy,z,1)-beta(z)*u2i(xy,z,2)
                  du2i(xy,z,3,2)=om2i(xy,z,1)+beta(z)*u2r(xy,z,2)
               end do
            end do
         end do
c
c     Set oddball mode to zero
c
         do j=1,3
            do i=1,3
               do z=1,nzc
                  do y=1,npl
                     du2r(nx/2+1+(y-1)*(nxp/2+1),z,i,j)=0.0
                  end do
               end do
            end do
         end do
         if (pressure.eq.1) then
            do i=2,3
               do z=1,nzc
                  do y=1,npl
                     h2r(nx/2+1+(y-1)*(nxp/2+1),z,i)=0.0
                  end do
               end do
            end do
         end if

c
c     Transform to physical space
c
         if (0.eq.0) then
            do i=1,3
c               call xzsh(u2r(1,1,i),u2i(1,1,i),xs,zs,alfa,beta,yb)
c               call xzsh(om2r(1,1,i),om2i(1,1,i),xs,zs,alfa,beta,yb)
c               do j=1,3        
c                  call xzsh(du2r(1,1,i,j),du2i(1,1,i,j),xs,zs,alfa,
c     &                 beta,yb)
c               end do
               if (nfzsym.eq.0) then
                  call vcfftb(u2r(1,1,i),u2i(1,1,i),wr,wi,nz,
     &                 nxy,(nxp/2+1)*mby,1,prezn)
                  call vcfftb(om2r(1,1,i),om2i(1,1,i),wr,wi,nz,
     &                 nxy,(nxp/2+1)*mby,1,prezn)
                  do j=1,3        
                     call vcfftb(du2r(1,1,i,j),du2i(1,1,i,j),wr,wi,nz,
     &                    nxy,(nxp/2+1)*mby,1,prezn)
                  end do
               else
                  if (i.le.2) then
                     call vcffts(u2r(1,1,i),u2i(1,1,i),wr,
     &                    nz/2+1,nxy,(nxp/2+1)*mby,1,presn)
                     call vcftab(om2r(1,2,i),om2i(1,2,i),
     &                    wr,wi,nz/2-1,nxy,(nxp/2+1)*mby,1,prean)
                     call vcffts(du2r(1,1,i,1),du2i(1,1,i,1),wr,
     &                    nz/2+1,nxy,(nxp/2+1)*mby,1,presn)
                     call vcffts(du2r(1,1,i,2),du2i(1,1,i,2),wr,
     &                    nz/2+1,nxy,(nxp/2+1)*mby,1,presn)
                     call vcftab(du2r(1,2,i,3),du2i(1,2,i,3),
     &                    wr,wi,nz/2-1,nxy,(nxp/2+1)*mby,1,prean)
                  else
                     call vcftab(u2r(1,2,i),u2i(1,2,i),
     &                    wr,wi,nz/2-1,nxy,(nxp/2+1)*mby,1,prean)
                     call vcffts(om2r(1,1,i),om2i(1,1,i),wr,
     &                    nz/2+1,nxy,(nxp/2+1)*mby,1,presn)
                     call vcftab(du2r(1,2,i,1),du2i(1,2,i,1),
     &                    wr,wi,nz/2-1,nxy,(nxp/2+1)*mby,1,prean)
                     call vcftab(du2r(1,2,i,2),du2i(1,2,i,2),
     &                    wr,wi,nz/2-1,nxy,(nxp/2+1)*mby,1,prean)
                     call vcffts(du2r(1,1,i,3),du2i(1,1,i,3),wr,
     &                    nz/2+1,nxy,(nxp/2+1)*mby,1,presn)
                  end if
               end if 
               call vrfftb(u2r(1,1,i),u2i(1,1,i),wr,wi,
     &              nx,nzpc*mby,1,nxp/2+1,prexn)
               call vrfftb(om2r(1,1,i),om2i(1,1,i),wr,wi,
     &              nx,nzpc*mby,1,nxp/2+1,prexn)
               do j=1,3
                  call vrfftb(du2r(1,1,i,j),du2i(1,1,i,j),wr,wi,
     &                 nx,nzpc*mby,1,nxp/2+1,prexn)
               end do
            end do
         end if

         if (nxysth.gt.0) then
c
c     Maybe some shifting (as above) could be done here as well.
c
            do ith=1,scalar
               do i=1,4      
                  call vcfftb(th2r(1,1,i,ith),th2i(1,1,i,ith)
     &                 ,wr,wi,nz,nxy,(nxp/2+1)*mby,1,prezn)
                  call vrfftb(th2r(1,1,i,ith),th2i(1,1,i,ith)
     &                 ,wr,wi,nx,nzpc*mby,1,nxp/2+1,prexn)
               end do
            end do
         end if
         if (pressure.eq.1) then
            do i=1,3
c               call xzsh(h2r(1,1,i),h2i(1,1,i),xs,zs,alfa,beta,yb)
               call vcfftb(h2r(1,1,i),h2i(1,1,i),wr,wi,nz,
     &              nxy,(nxp/2+1)*mby,1,prezn)
               call vrfftb(h2r(1,1,i),h2i(1,1,i),wr,wi,
     &              nx,nzpc*mby,1,nxp/2+1,prexn)
            end do
         end if
      end  if



      xb=mod(my_node_world,nprocx)*nz/nprocz
c
c     Add base flow if pertubation mode
c


c
c     FORCING PROBES TO WORK IN PERTURBATION MODE...
c

c      if (pert) then
c         write(*,*)'Not Implemented'
c         call stopnow(556677889)
c         do i=1,3
c            do x=1,nxp/2
c               do z=1,nzd
c                  u2r(x,z,i)  = u2r(x,z,i) + bu3(x,yb,i)
c                  u2i(x,z,i)  = u2i(x,z,i) + bu4(x,yb,i)
c                  om2r(x,z,i) = om2r(x,z,i) + bom3(x,yb,i)
c                  om2i(x,z,i) = om2i(x,z,i) + bom4(x,yb,i)
c               end do
c            end do
c         end do
c      end if


c
c     ******************************************************************
c     **                                                              **
c     **           X / Y - ONE-POINT  STATISTICS                      **
c     **                                                              **
c     ******************************************************************
c
c     Accumulate statistics using the timestep as weight
c     We use non central statistics for these simple quantities
c
      c1=dtn/real(nzc)
c
c     Velocities and vorticities
c
      if (nxys.ge.12) then
         do i=1,3
            do y=1,npl
               do z=1,memnz
                  c=c1
                  if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
                  do x=1,nx/2
                     xy=x+(y-1)*(nxp/2+1)
c     
c     Velocities (1-3)
c     
                     xys(2*x-1,ybp+y-1,i)=xys(2*x-1,ybp+y-1,i)+
     &                    u2r(xy,z,i)*c
                     xys(2*x  ,ybp+y-1,i)=xys(2*x  ,ybp+y-1,i)+
     &                    u2i(xy,z,i)*c
c     
c     Velocities squared (4-6)
c     
                     xys(2*x-1,ybp+y-1,i+3)=xys(2*x-1,ybp+y-1,i+3)+
     &                    u2r(xy,z,i)**2*c
                     xys(2*x  ,ybp+y-1,i+3)=xys(2*x  ,ybp+y-1,i+3)+
     &                    u2i(xy,z,i)**2*c
c     
c     Vorticities (7-9)
c     
                     xys(2*x-1,ybp+y-1,i+6)=xys(2*x-1,ybp+y-1,i+6)+
     &                    om2r(xy,z,i)*c
                     xys(2*x  ,ybp+y-1,i+6)=xys(2*x  ,ybp+y-1,i+6)+
     &                    om2i(xy,z,i)*c
c     
c     Vorticities squared (10-12)
c     
                     xys(2*x-1,ybp+y-1,i+9)=xys(2*x-1,ybp+y-1,i+9)+
     &                    om2r(xy,z,i)**2*c
                     xys(2*x  ,ybp+y-1,i+9)=xys(2*x  ,ybp+y-1,i+9)+
     &                    om2i(xy,z,i)**2*c
                  end do
               end do
            end do
         end do
      end if

c      do x=1,nx
c         write(*,*) x,ybp,yb,xys(x,ybp,1)/c1/16
c      end do


c
c     Off-diagonal Reynolds stresses (13-15)
c
      if (nxys.ge.15) then
         do y=1,npl 
            do z=1,memnz
               c=c1
               if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
               do x=1,nx/2
                  xy=x+(y-1)*(nxp/2+1)
c     
c     uv (13)
c     
                  xys(2*x-1,ybp+y-1,13)=xys(2*x-1,ybp+y-1,13)+
     &                 u2r(xy,z,1)*u2r(xy,z,2)*c
                  xys(2*x,ybp+y-1,13)=xys(2*x,ybp+y-1,13)+
     &                 u2i(xy,z,1)*u2i(xy,z,2)*c
c     
c     uw (14)
c     
                  xys(2*x-1,ybp+y-1,14)=xys(2*x-1,ybp+y-1,14)+
     &                 u2r(xy,z,1)*u2r(xy,z,3)*c
                  xys(2*x,ybp+y-1,14)=xys(2*x,ybp+y-1,14)+
     &                 u2i(xy,z,1)*u2i(xy,z,3)*c
c     
c     vw (15)
c     
                  xys(2*x-1,ybp+y-1,15)=xys(2*x-1,ybp+y-1,15)+
     &                 u2r(xy,z,2)*u2r(xy,z,3)*c
                  xys(2*x,ybp+y-1,15)=xys(2*x,ybp+y-1,15)+
     &                 u2i(xy,z,2)*u2i(xy,z,3)*c
               end do
            end do
         end do
      end if
c
c     Two point correlations at one point separation (16-24)
c     xys(,,16) u(x)*u(x+1)
c     xys(,,17) v(x)*v(x+1)
c     xys(,,18) w(x)*w(x+1)
c     xys(,,19) u(y)*u(y+1)
c     xys(,,20) v(y)*v(y+1)
c     xys(,,21) w(y)*w(y+1)
c     xys(,,22) u(z)*u(z+1)
c     xys(,,23) v(z)*v(z+1)
c     xys(,,24) w(z)*w(z+1)
c
c     Note that we need the next y-box to step to the next y-position
c     find velocities and put in om2r,i (obs !)
c
c     These statistics are commented out since they involve 
c     another getxz operation that is expensive with MPI.
c     Therefore, entries 16-24 are empty.
c

      goto 1111

      if (yb+mby-1.lt.nyp) then 
         do i=1,3
            call getxz(om2r(1,1,i),om2i(1,1,i),yb+mby,i,0,ur,ui)
         end do
c
c     Subtract lower wall shifting velocity
c
         do y=1,npl
            xy=1+(y-1)*(nxp/2+1)
            om2r(xy,1,1)=om2r(xy,1,1)-u0low
            om2r(xy,1,3)=om2r(xy,1,3)-w0low
         end do
c
c     Transform to physical space
c
         do i=1,3
c            call xzsh(om2r(1,1,i),om2i(1,1,i),xs,zs,alfa,beta,yb+mby)
            if (nfzsym.eq.0) then
               call vcfftb(om2r(1,1,i),om2i(1,1,i),wr,wi,nz,
     &              nxy,(nxp/2+1)*mby,1,prezn)
            else
               if (i.le.2) then
                  call vcffts(om2r(1,1,i),om2i(1,1,i),wr,
     &                 nz/2+1,nxy,(nxp/2+1)*mby,1,presn)
               else
                  call vcftab(om2r(1,2,i),om2i(1,2,i),
     &                 wr,wi,nz/2-1,nxy,(nxp/2+1)*mby,1,prean)
               end if
            end if 
            call vrfftb(om2r(1,1,i),om2i(1,1,i),wr,wi,
     &           nx,nzpc*mby,1,nxp/2+1,prexn)
         end do
      end if
c
c     x-correlations
c
      do i=1,3
         do y=1,npl 
            do z=1,nzc+nfzsym
               c=c1
               if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
               do x=1,nx/2-1
                  xy=x+(y-1)*(nxp/2+1)
                  xys(2*x-1,yb+y-1,15+i)=xys(2*x-1,yb+y-1,15+i)+
     &                 u2r(xy,z,i)*u2i(xy,z,i)*c
                  xys(2*x,yb+y-1,15+i)=xys(2*x,yb+y-1,15+i)+
     &                 u2i(xy,z,i)*u2r(xy+1,z,i)*c
               end do
c
c     Fix the wrap around point 
c
               xys(nx-1,yb+y-1,15+i)=xys(nx-1,yb+y-1,15+i)+
     &              u2r(nx/2+(y-1)*(nxp/2+1),z,i)*u2i(nx/2+
     &              (y-1)*(nxp/2+1),z,i)*c
               xys(nx,yb+y-1,15+i)=xys(nx,yb+y-1,15+i)+
     &              u2i(nx/2+(y-1)*(nxp/2+1),z,i)*u2r(1+(y-1)
     &              *(nxp/2+1),z,i)*c
            end do
         end do
      end do
c
c     y-correlations
c
      do i=1,3
         do y=1,npl-1
            do z=1,nzc+nfzsym
               c=c1
               if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
               do x=1,nx/2
                  xy=x+(y-1)*(nxp/2+1)
                  xys(2*x-1,yb+y-1,18+i)=xys(2*x-1,yb+y-1,18+i)+
     &                 u2r(xy,z,i)*u2r(xy+nxp/2+1,z,i)*c
                  xys(2*x,yb+y-1,18+i)=xys(2*x,yb+y-1,18+i)+
     &                 u2i(xy,z,i)*u2i(xy+nxp/2+1,z,i)*c
               end do
            end do
         end do
      end do
c
c     Overlap to next box
c     Note that om2r,i contains velocities in the next box, NOT vorticities
c
      if (yb+mby-1.lt.nyp) then 
         do i=1,3
            do z=1,nzc+nfzsym
               c=c1
               if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
               do x=1,nx/2
                  xy=x+(npl-1)*(nxp/2+1)
                  xys(2*x-1,yb+npl-1,18+i)=xys(2*x-1,yb+npl-1,18+i)+
     &                 u2r(xy,z,i)*om2r(x,z,i)*c
                  xys(2*x,yb+npl-1,18+i)=xys(2*x,yb+npl-1,18+i)+
     &                 u2i(xy,z,i)*om2i(x,z,i)*c
               end do
            end do
         end do
      end if
c
c     z-correlations
c
      do i=1,3
         do y=1,npl
            do z=1,nzc+nfzsym-1
               c=c1
               if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
               do x=1,nx/2
                  xy=x+(y-1)*(nxp/2+1)
                  xys(2*x-1,yb+y-1,21+i)=xys(2*x-1,yb+y-1,21+i)+
     &                 u2r(xy,z,i)*u2r(xy,z+1,i)*c
                  xys(2*x,yb+y-1,21+i)=xys(2*x,yb+y-1,21+i)+
     &                 u2i(xy,z,i)*u2i(xy,z+1,i)*c
               end do
            end do
         end do
      end do
c
c     Wrap around in z
c
      if (nfzsym.eq.0) then
c
c     Non symmetric case
c
         c=c1
         do i=1,3
            do y=1,npl
               do x=1,nx/2
                  xy=x+(y-1)*(nxp/2+1)
                  xys(2*x-1,yb+y-1,21+i)=xys(2*x-1,yb+y-1,21+i)+
     &                 u2r(xy,nzc,i)*u2r(xy,1,i)*c
                  xys(2*x,yb+y-1,21+i)=xys(2*x,yb+y-1,21+i)+
     &                 u2i(xy,nzc,i)*u2i(xy,1,i)*c
               end do
            end do
         end do
      else
c
c     Symmetric case
c
         c=c1/2.
         do y=1,npl
            do x=1,nx/2
               xy=x+(y-1)*(nxp/2+1)
c
c     u symmetric
c
               xys(2*x-1,yb+y-1,22)=xys(2*x-1,yb+y-1,22)+
     &              u2r(xy,nzc+1,1)*u2r(xy,nzc,1)*c
               xys(2*x,yb+y-1,22)=xys(2*x,yb+y-1,22)+
     &              u2i(xy,nzc+1,1)*u2i(xy,nzc,1)*c
c
c     v symmetric
c
               xys(2*x-1,yb+y-1,23)=xys(2*x-1,yb+y-1,23)+
     &              u2r(xy,nzc+1,2)*u2r(xy,nzc,2)*c
               xys(2*x,yb+y-1,23)=xys(2*x,yb+y-1,23)+
     &              u2i(xy,nzc+1,2)*u2i(xy,nzc,2)*c
c
c     w anti symmetric so this is zero, but to be formally correct :
c
               xys(2*x-1,yb+y-1,24)=xys(2*x-1,yb+y-1,24)-
     &              u2r(xy,nzc+1,3)*u2r(xy,nzc,3)*c
               xys(2*x,yb+y-1,24)=xys(2*x,yb+y-1,24)-
     &              u2i(xy,nzc+1,3)*u2i(xy,nzc,3)*c
            end do
         end do
      end if
c
c     Here we continue with the statistics
c
 1111 continue
c
c     Dissipation tensor (25-30)
c
c     xys(,,25) re*eps11=ux^2+uy^2+uz^2
c     xys(,,26) re*eps22=vx^2+vy^2+vz^2
c     xys(,,27) re*eps33=wx^2+wy^2+wz^2
c     xys(,,28) re*eps12=uxvx+uyvy+uzvz
c     xys(,,29) re*eps13=uxwx+uywy+uzwz
c     xys(,,30) re*eps23=vxwx+vywy+vzwz
c
      if (nxys.ge.30) then
         do i=1,3
            do j=1,3
               do y=1,npl
                  do z=1,memnz
                     c=c1
                     if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
                     do x=1,nx/2
                        xy=x+(y-1)*(nxp/2+1)
                        xys(2*x-1,ybp+y-1,24+i)=xys(2*x-1,ybp+y-1,24+i)+
     &                       du2r(xy,z,i,j)*du2r(xy,z,i,j)*c
                        xys(2*x  ,ybp+y-1,24+i)=xys(2*x  ,ybp+y-1,24+i)+
     &                       du2i(xy,z,i,j)*du2i(xy,z,i,j)*c
                     end do
                  end do
               end do
            end do
         end do
         
         do j=1,3
            do y=1,npl
               do z=1,memnz
                  c=c1
                  if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
                  do x=1,nx/2
                     xy=x+(y-1)*(nxp/2+1)
                     xys(2*x-1,ybp+y-1,28)=xys(2*x-1,ybp+y-1,28)+
     &                    du2r(xy,z,1,j)*du2r(xy,z,2,j)*c
                     xys(2*x  ,ybp+y-1,28)=xys(2*x  ,ybp+y-1,28)+
     &                    du2i(xy,z,1,j)*du2i(xy,z,2,j)*c
                     xys(2*x-1,ybp+y-1,29)=xys(2*x-1,ybp+y-1,29)+
     &                    du2r(xy,z,1,j)*du2r(xy,z,3,j)*c
                     xys(2*x  ,ybp+y-1,29)=xys(2*x  ,ybp+y-1,29)+
     &                    du2i(xy,z,1,j)*du2i(xy,z,3,j)*c
                     xys(2*x-1,ybp+y-1,30)=xys(2*x-1,ybp+y-1,30)+
     &                    du2r(xy,z,2,j)*du2r(xy,z,3,j)*c
                     xys(2*x  ,ybp+y-1,30)=xys(2*x  ,ybp+y-1,30)+
     &                    du2i(xy,z,2,j)*du2i(xy,z,3,j)*c
                  end do
               end do
            end do
         end do
      end if
c     
c     Pressure statistics (entries 31-42)
c
      if (pressure.eq.1.and.nxys.ge.42) then
         do y=1,npl
            do z=1,memnz
               c=c1
               if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
               do x=1,nx/2
                  xy=x+(y-1)*(nxp/2+1)
c
c     Pressure (31)
c
                  xys(2*x-1,ybp+y-1,31)=xys(2*x-1,ybp+y-1,31)+
     &                 h2r(xy,z,1)*c
                  xys(2*x  ,ybp+y-1,31)=xys(2*x  ,ybp+y-1,31)+
     &                 h2i(xy,z,1)*c
c     
c     Pressure squared (32)
c     
                  xys(2*x-1,ybp+y-1,32)=xys(2*x-1,ybp+y-1,32)+
     &                 h2r(xy,z,1)**2*c
                  xys(2*x  ,ybp+y-1,32)=xys(2*x  ,ybp+y-1,32)+
     &                 h2i(xy,z,1)**2*c
               end do
            end do
         end do
c
c     Pressure-velocity correlation (33-35)
c     
         do y=1,npl 
            do z=1,memnz
               c=c1
               if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
               do x=1,nx/2
                  xy=x+(y-1)*(nxp/2+1)
c     up        
                  xys(2*x-1,ybp+y-1,33)=xys(2*x-1,ybp+y-1,33)+
     &                 u2r(xy,z,1)*h2r(xy,z,1)*c
                  xys(2*x  ,ybp+y-1,33)=xys(2*x  ,ybp+y-1,33)+
     &                 u2i(xy,z,1)*h2i(xy,z,1)*c
c     vp        
                  xys(2*x-1,ybp+y-1,34)=xys(2*x-1,ybp+y-1,34)+
     &                 u2r(xy,z,2)*h2r(xy,z,1)*c
                  xys(2*x  ,ybp+y-1,34)=xys(2*x  ,ybp+y-1,34)+
     &                 u2i(xy,z,2)*h2i(xy,z,1)*c
c     wp        
                  xys(2*x-1,ybp+y-1,35)=xys(2*x-1,ybp+y-1,35)+
     &                 u2r(xy,z,3)*h2r(xy,z,1)*c
                  xys(2*x  ,ybp+y-1,35)=xys(2*x  ,ybp+y-1,35)+
     &                 u2i(xy,z,3)*h2i(xy,z,1)*c 
               end do
            end do
         end do
c
c     Pressure-strain correlation (36-42)
c
c     p ux, p vy, p wz
c
         do i=1,3
            do y=1,npl
               do z=1,memnz
                  c=c1
                  if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
                  do x=1,nx/2
                     xy=x+(y-1)*(nxp/2+1)
                     xys(2*x-1,ybp+y-1,35+i)=xys(2*x-1,ybp+y-1,35+i)+
     &                    h2r(xy,z,1)*du2r(xy,z,i,i)*c
                     xys(2*x  ,ybp+y-1,35+i)=xys(2*x  ,ybp+y-1,35+i)+
     &                    h2i(xy,z,1)*du2i(xy,z,i,i)*c
                  end do
               end do
            end do
         end do
c
c     p uy, p vz, p wx, p uz
c
         do i=1,2
            do y=1,npl
               do z=1,memnz
                  c=c1
                  if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
                  do x=1,nx/2
                     xy=x+(y-1)*(nxp/2+1)
                     xys(2*x-1,ybp+y-1,38+i)=xys(2*x-1,ybp+y-1,38+i)+
     &                    h2r(xy,z,1)*du2r(xy,z,i,1+i)*c
                     xys(2*x  ,ybp+y-1,38+i)=xys(2*x  ,ybp+y-1,38+i)+
     &                    h2i(xy,z,1)*du2i(xy,z,i,1+i)*c
                     xys(2*x-1,ybp+y-1,40+i)=xys(2*x-1,ybp+y-1,40+i)+
     &                    h2r(xy,z,1)*du2r(xy,z,5-2*i,2*i-1)*c
                     xys(2*x  ,ybp+y-1,40+i)=xys(2*x  ,ybp+y-1,40+i)+
     &                    h2i(xy,z,1)*du2i(xy,z,5-2*i,2*i-1)*c
                  end do
               end do
            end do
         end do

      end if

      if (nxys.ge.44) then
c
c     Maximum disturbance amplitude (43-44)
c
         do y=1,npl
            do x=1,nx/2
               xy=x+(y-1)*(nxp/2+1)
c
c     Instantaneous mean over z
c
               ut1=0.
               ut2=0.
               do z=1,memnz
                  ut1=ut1+u2r(xy,z,1)
                  ut2=ut2+u2i(xy,z,1)
               end do
               ut1=ut1/real(memnz)
               ut2=ut2/real(memnz)
c
c     Get extrema
c
               umin1 = xys(2*x-1,ybp+y-1,43)
               umin2 = xys(2*x  ,ybp+y-1,43)
               umax1 = xys(2*x-1,ybp+y-1,44)
               umax2 = xys(2*x  ,ybp+y-1,44)
               do z=1,memnz
                  umax1 = max(umax1,u2r(xy,z,1)-ut1)
                  umax2 = max(umax2,u2i(xy,z,1)-ut1)
                  umin1 = min(umin1,u2r(xy,z,1)-ut1)
                  umin2 = min(umin2,u2i(xy,z,1)-ut1)
               end do
c
c     And save it
c
               xys(2*x-1,ybp+y-1,43) = umin1
               xys(2*x  ,ybp+y-1,43) = umin2
               xys(2*x-1,ybp+y-1,44) = umax1
               xys(2*x  ,ybp+y-1,44) = umax2
            end do
         end do
      end if
c
c     Strain-rate tensor Sij
c     45     <S_ij S_ij>    1
c     46-51  <S_ij>         6
c
      if (nxys.ge.51) then
         do y=1,npl
            do z=1,memnz
               c=c1
               if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
               do x=1,nx/2
                  xy=x+(y-1)*(nxp/2+1)

                  sr1 =     du2r(xy,z,1,1)
                  sr2 = .5*(du2r(xy,z,2,1)+du2r(xy,z,1,2))
                  sr3 = .5*(du2r(xy,z,3,1)+du2r(xy,z,1,3))
                  sr4 =     du2r(xy,z,2,2)
                  sr5 = .5*(du2r(xy,z,2,3)+du2r(xy,z,3,2))
                  sr6 =     du2r(xy,z,3,3)
                  
                  si1 =     du2i(xy,z,1,1)
                  si2 = .5*(du2i(xy,z,2,1)+du2i(xy,z,1,2))
                  si3 = .5*(du2i(xy,z,3,1)+du2i(xy,z,1,3))
                  si4 =     du2i(xy,z,2,2)
                  si5 = .5*(du2i(xy,z,2,3)+du2i(xy,z,3,2))
                  si6 =     du2i(xy,z,3,3)
                  
     
                  sabsr = sr1**2 + sr4**2 + sr6**2 +
     &                 2.*(sr2**2 + sr3**2 + sr5**2)
                  sabsi = si1**2 + si4**2 + si6**2 +
     &                 2.*(si2**2 + si3**2 + si5**2)


c     <Sij Sij> (position 45)
                  xys(2*x-1,ybp+y-1,45) = xys(2*x-1,ybp+y-1,45) + 
     &                 sabsr*c
                  xys(2*x  ,ybp+y-1,45) = xys(2*x  ,ybp+y-1,45) + 
     &                 sabsi*c
c     <S11>
                  xys(2*x-1,ybp+y-1,46) = xys(2*x-1,ybp+y-1,46) + sr1*c
                  xys(2*x  ,ybp+y-1,46) = xys(2*x  ,ybp+y-1,46) + si1*c
c     <S12>
                  xys(2*x-1,ybp+y-1,47) = xys(2*x-1,ybp+y-1,47) + sr2*c
                  xys(2*x  ,ybp+y-1,47) = xys(2*x  ,ybp+y-1,47) + si2*c
c     <S13>
                  xys(2*x-1,ybp+y-1,48) = xys(2*x-1,ybp+y-1,48) + sr3*c
                  xys(2*x  ,ybp+y-1,48) = xys(2*x  ,ybp+y-1,48) + si3*c
c     <S22>
                  xys(2*x-1,ybp+y-1,49) = xys(2*x-1,ybp+y-1,49) + sr4*c
                  xys(2*x  ,ybp+y-1,49) = xys(2*x  ,ybp+y-1,49) + si4*c
c     <S23>
                  xys(2*x-1,ybp+y-1,50) = xys(2*x-1,ybp+y-1,50) + sr5*c
                  xys(2*x  ,ybp+y-1,50) = xys(2*x  ,ybp+y-1,50) + si5*c
c     <S33> (position 51)
                  xys(2*x-1,ybp+y-1,51) = xys(2*x-1,ybp+y-1,51) + sr6*c
                  xys(2*x  ,ybp+y-1,51) = xys(2*x  ,ybp+y-1,51) + si6*c
               end do
            end do
         end do
      end if
c
c     Position 52 is added in les.f (C=C_S^2)
c
c     LES statistics (positions 53-59)
c     (only if tau_ij is available, i.e. eddy-viscosity models)
c
      if (nxys.ge.59.and.(iles.eq.2.or.iles.eq.3)) then
         if (nproc.eq.1) then
            do i=1,6
               call getxz(tau2r(1,1,i),tau2i(1,1,i),yb,i,0,taur,taui)

               call vcfftb(tau2r(1,1,i),tau2i(1,1,i),wr,wi,nz,
     &              nxy,(nxp/2+1)*mby,1,prezn)
               call vrfftb(tau2r(1,1,i),tau2i(1,1,i),wr,wi,
     &              nx,nzpc*mby,1,nxp/2+1,prexn)
            end do
            
         else
#ifdef MPI
            do i=1,6
               call getpxz_z(gboxr_z(1,1,i),gboxi_z(1,1,i),
     &              yb,i,0,taur,taui,
     &              realg1,realg2,my_node_z,my_comm_z,my_node_world)
            
               call vcfftb(gboxr_z(1,1,i),gboxi_z(1,1,i),
     &              wr_z,wi_z,nz,memnx,memnx,1,prezn)
                       
               call getpxz_x(tau2r(1,1,i),tau2i(1,1,i),yb,i,0,
     &              gboxr_z(1,1,i),gboxi_z(1,1,i),
     &              realg5,realg6,my_node_x,my_comm_x,my_node_world)
               
               call vrfftb(tau2r(1,1,i),tau2i(1,1,i),wr_x,wi_x,
     &              nx,memnz,1,nxp/2+1,prexn)
            end do

#endif
         end if


 


         do y=1,npl
            do z=1,memnz
               c=c1
               if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
               do x=1,nx/2
                  xy=x+(y-1)*(nxp/2+1)

                  sr1 =     du2r(xy,z,1,1)
                  sr2 = .5*(du2r(xy,z,2,1)+du2r(xy,z,1,2))
                  sr3 = .5*(du2r(xy,z,3,1)+du2r(xy,z,1,3))
                  sr4 =     du2r(xy,z,2,2)
                  sr5 = .5*(du2r(xy,z,2,3)+du2r(xy,z,3,2))
                  sr6 =     du2r(xy,z,3,3)
                  
                  si1 =     du2i(xy,z,1,1)
                  si2 = .5*(du2i(xy,z,2,1)+du2i(xy,z,1,2))
                  si3 = .5*(du2i(xy,z,3,1)+du2i(xy,z,1,3))
                  si4 =     du2i(xy,z,2,2)
                  si5 = .5*(du2i(xy,z,2,3)+du2i(xy,z,3,2))
                  si6 =     du2i(xy,z,3,3)
c
c     <tau_ij u_j> (position 80-82)
c
                  dr = tau2r(xy,z,1)*u2r(xy,z,1) + 
     &                 tau2r(xy,z,2)*u2r(xy,z,2) +
     &                 tau2r(xy,z,3)*u2r(xy,z,3)
                  di = tau2i(xy,z,1)*u2i(xy,z,1) + 
     &                 tau2i(xy,z,2)*u2i(xy,z,2) +
     &                 tau2i(xy,z,3)*u2i(xy,z,3)
                  xys(2*x-1,ybp+y-1,80) = xys(2*x-1,ybp+y-1,80) + dr*c
                  xys(2*x  ,ybp+y-1,80) = xys(2*x  ,ybp+y-1,80) + di*c
                  dr = tau2r(xy,z,2)*u2r(xy,z,1) + 
     &                 tau2r(xy,z,4)*u2r(xy,z,2) +
     &                 tau2r(xy,z,5)*u2r(xy,z,3)
                  di = tau2i(xy,z,2)*u2i(xy,z,1) + 
     &                 tau2i(xy,z,4)*u2i(xy,z,2) +
     &                 tau2i(xy,z,5)*u2i(xy,z,3)
                  xys(2*x-1,ybp+y-1,81) = xys(2*x-1,ybp+y-1,81) + dr*c
                  xys(2*x  ,ybp+y-1,81) = xys(2*x  ,ybp+y-1,81) + di*c
                  dr = tau2r(xy,z,3)*u2r(xy,z,1) + 
     &                 tau2r(xy,z,5)*u2r(xy,z,2) +
     &                 tau2r(xy,z,6)*u2r(xy,z,3)
                  di = tau2i(xy,z,3)*u2i(xy,z,1) + 
     &                 tau2i(xy,z,5)*u2i(xy,z,2) +
     &                 tau2i(xy,z,6)*u2i(xy,z,3)
                  xys(2*x-1,ybp+y-1,82) = xys(2*x-1,ybp+y-1,82) + dr*c
                  xys(2*x  ,ybp+y-1,82) = xys(2*x  ,ybp+y-1,82) + di*c
c
c     <tau_ij S_ij> (position 53)
c
                  dr = tau2r(xy,z,1)*sr1+tau2r(xy,z,4)*sr4+
     &                 tau2r(xy,z,6)*sr6+2.*tau2r(xy,z,2)*sr2+
     &                 2.*tau2r(xy,z,3)*sr3+2.*tau2r(xy,z,5)*sr5
                  di = tau2i(xy,z,1)*si1+tau2i(xy,z,4)*si4+
     &                 tau2i(xy,z,6)*si6+2.*tau2i(xy,z,2)*si2+
     &                 2.*tau2i(xy,z,3)*si3+2.*tau2i(xy,z,5)*si5
                  xys(2*x-1,ybp+y-1,53) = xys(2*x-1,ybp+y-1,53) + dr*c
                  xys(2*x  ,ybp+y-1,53) = xys(2*x  ,ybp+y-1,53) + di*c
c
c     Conditional sampling: <tau_ij S_ij> (position 61/62)
c
                  if (dr.gt.0) then
c
c     Forward scatter (position 61) 
c
                     xys(2*x-1,ybp+y-1,62) = xys(2*x-1,ybp+y-1,62) +
     &                    dr*c
                  else
c
c     Backscatter (position 62)
c
                     xys(2*x-1,ybp+y-1,61) = xys(2*x-1,ybp+y-1,61) +
     &                    dr*c
                  end if
                  if (di.gt.0) then
c
c     Forward scatter (position 61)
c
                     xys(2*x  ,ybp+y-1,62) = xys(2*x  ,ybp+y-1,62) +
     &                    di*c
                  else
c
c     Backscatter (position 62)
c
                     xys(2*x  ,ybp+y-1,61) = xys(2*x  ,ybp+y-1,61) +
     &                    di*c
                  end if
c
c     <tau_11> (position 54)
c
                  xys(2*x-1,ybp+y-1,54) = xys(2*x-1,ybp+y-1,54) + 
     &                 tau2r(xy,z,1)*c
                  xys(2*x  ,ybp+y-1,54) = xys(2*x  ,ybp+y-1,54) + 
     &                 tau2i(xy,z,1)*c
c
c     <tau_12> (position 55)
c
                  xys(2*x-1,ybp+y-1,55) = xys(2*x-1,ybp+y-1,55) + 
     &                 tau2r(xy,z,2)*c
                  xys(2*x  ,ybp+y-1,55) = xys(2*x  ,ybp+y-1,55) + 
     &                 tau2i(xy,z,2)*c
c
c     <tau_13> (position 56)
c
                  xys(2*x-1,ybp+y-1,56) = xys(2*x-1,ybp+y-1,56) + 
     &                 tau2r(xy,z,3)*c
                  xys(2*x  ,ybp+y-1,56) = xys(2*x  ,ybp+y-1,56) + 
     &                 tau2i(xy,z,3)*c
c
c     <tau_22> (position 57)
c
                  xys(2*x-1,ybp+y-1,57) = xys(2*x-1,ybp+y-1,57) + 
     &                 tau2r(xy,z,4)*c
                  xys(2*x  ,ybp+y-1,57) = xys(2*x  ,ybp+y-1,57) + 
     &                 tau2i(xy,z,4)*c
c
c     <tau_23> (position 58)
c
                  xys(2*x-1,ybp+y-1,58) = xys(2*x-1,ybp+y-1,58) + 
     &                 tau2r(xy,z,5)*c
                  xys(2*x  ,ybp+y-1,58) = xys(2*x  ,ybp+y-1,58) + 
     &                 tau2i(xy,z,5)*c
c
c     <tau_33> (position 59)
c
                  xys(2*x-1,ybp+y-1,59) = xys(2*x-1,ybp+y-1,59) + 
     &                 tau2r(xy,z,6)*c
                  xys(2*x  ,ybp+y-1,59) = xys(2*x  ,ybp+y-1,59) + 
     &                 tau2i(xy,z,6)*c
               end do
            end do
         end do
      end if
c
c     Statistics added in les.f routine (dynamic Smagorinsky)
c     52     <C=C_S^2>      1 scalar
c     60     <nu_t>         1 scalar
c
c     LES statistics to be added in sgs_stress (all SGS models)
c     well, will be implemented later...
c     1     <sigma_i>       1 scalar
c     2-4   <sigma_i u_i>   3 scalars
c

c
c     Triple correlation for the velocities (63-72)
c
c     Velocities skewness (63-65)
c
      if (nxys.ge.72) then
         do i=1,3
            do y=1,npl
               do z=1,memnz
                  c=c1
                  if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
                  do x=1,nx/2
                     xy=x+(y-1)*(nxp/2+1)
                     xys(2*x-1,ybp+y-1,62+i)=xys(2*x-1,ybp+y-1,62+i)+
     &                    u2r(xy,z,i)**3*c
                     xys(2*x  ,ybp+y-1,62+i)=xys(2*x  ,ybp+y-1,62+i)+
     &                    u2i(xy,z,i)**3*c
                  end do
               end do
            end do
         end do
c
c     Mixed triple correlations (66-72)
c
         do y=1,npl
            do z=1,memnz
               c=c1
               if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
               do x=1,nx/2
                  xy=x+(y-1)*(nxp/2+1)
c     u^2 v (66)
                  xys(2*x-1,ybp+y-1,66)=xys(2*x-1,ybp+y-1,66)+
     &                 u2r(xy,z,1)**2*u2r(xy,z,2)*c
                  xys(2*x,ybp+y-1,66)=xys(2*x,ybp+y-1,66)+
     &                 u2i(xy,z,1)**2*u2i(xy,z,2)*c
c     u^2 w (67)
                  xys(2*x-1,ybp+y-1,67)=xys(2*x-1,ybp+y-1,67)+
     &                 u2r(xy,z,1)**2*u2r(xy,z,3)*c
                  xys(2*x,ybp+y-1,67)=xys(2*x,ybp+y-1,67)+
     &                 u2i(xy,z,1)**2*u2i(xy,z,3)*c
c     v^2 u (68)
                  xys(2*x-1,ybp+y-1,68)=xys(2*x-1,ybp+y-1,68)+
     &                 u2r(xy,z,2)**2*u2r(xy,z,1)*c
                  xys(2*x,ybp+y-1,68)=xys(2*x,ybp+y-1,68)+
     &                 u2i(xy,z,2)**2*u2i(xy,z,1)*c
c     v^2 w (69)
                  xys(2*x-1,ybp+y-1,69)=xys(2*x-1,ybp+y-1,69)+
     &                 u2r(xy,z,2)**2*u2r(xy,z,3)*c
                  xys(2*x,ybp+y-1,69)=xys(2*x,ybp+y-1,69)+
     &                 u2i(xy,z,2)**2*u2i(xy,z,3)*c
c     w^2 u (70)
                  xys(2*x-1,ybp+y-1,70)=xys(2*x-1,ybp+y-1,70)+
     &                 u2r(xy,z,3)**2*u2r(xy,z,1)*c
                  xys(2*x,ybp+y-1,70)=xys(2*x,ybp+y-1,70)+
     &                 u2i(xy,z,3)**2*u2i(xy,z,1)*c
c     w^2 v (71)
                  xys(2*x-1,ybp+y-1,71)=xys(2*x-1,ybp+y-1,71)+
     &                 u2r(xy,z,3)**2*u2r(xy,z,2)*c
                  xys(2*x,ybp+y-1,71)=xys(2*x,ybp+y-1,71)+
     &                 u2i(xy,z,3)**2*u2i(xy,z,2)*c
c     u v w (72)
                  xys(2*x-1,ybp+y-1,72)=xys(2*x-1,ybp+y-1,72)+
     &                u2r(xy,z,1)*u2r(xy,z,2)*u2r(xy,z,3)*c
                  xys(2*x,ybp+y-1,72)=xys(2*x,ybp+y-1,72)+
     &                u2i(xy,z,1)*u2i(xy,z,2)*u2i(xy,z,3)*c
               end do
            end do
         end do
      end if
c
c     pvx,pwy (73-74)
c
      if (pressure.eq.1.and.nxys.ge.74) then
         do i=1,2
            do y=1,npl
               do z=1,memnz
                  c=c1
                  if(nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
                  do x=1,nx/2
                     xy=x+(y-1)*(nxp/2+1)
                     xys(2*x-1,ybp+y-1,72+i)=xys(2*x-1,ybp+y-1,72+i)+
     &                    h2r(xy,z,1)*du2r(xy,z,i+1,i)*c
                     xys(2*x,ybp+y-1  ,72+i)=xys(2*x,ybp+y-1  ,72+i)+
     &                    h2i(xy,z,1)*du2i(xy,z,i+1,i)*c
                  end do
               end do
            end do
         end do
      end if
c
c     Velocity flatness (75-77)
c
      if (nxys.ge.77) then
         do i=1,3
            do y=1,npl
               do z=1,memnz
                  c=c1
                  if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
                  do x=1,nx/2
                     xy=x+(y-1)*(nxp/2+1)
                     xys(2*x-1,ybp+y-1,74+i)=xys(2*x-1,ybp+y-1,74+i)+
     &                    u2r(xy,z,i)**4*c
                     xys(2*x  ,ybp+y-1,74+i)=xys(2*x  ,ybp+y-1,74+i)+
     &                    u2i(xy,z,i)**4*c
                  end do
               end do
            end do
         end do
      end if
c
c     Pressure skewness and flatness (78-79)
c
      if (pressure.eq.1.and.nxys.ge.79) then
         do y=1,npl
            do z=1,memnz
               c=c1
               if(nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
               do x=1,nx/2
                  xy=x+(y-1)*(nxp/2+1)
                  xys(2*x-1,ybp+y-1,78)=xys(2*x-1,ybp+y-1,78)+
     &                 h2r(xy,z,1)**3*c
                  xys(2*x  ,ybp+y-1,78)=xys(2*x  ,ybp+y-1,78)+
     &                 h2i(xy,z,1)**3*c
                  xys(2*x-1,ybp+y-1,79)=xys(2*x-1,ybp+y-1,79)+
     &                 h2r(xy,z,1)**4*c
                  xys(2*x  ,ybp+y-1,79)=xys(2*x  ,ybp+y-1,79)+
     &                 h2i(xy,z,1)**4*c
               end do
            end do
         end do
      end if
c
c     MHD statistics (83-96)
c
      if (imhd.eq.1.and.nxys.ge.96) then
         write(*,*)'Not Implemented'
         call stopnow(112233445566)
c
c     Get the potential
c
         if (nproc.eq.1) then
            call getxz(j2r(1,1,1),j2i(1,1,1),yb,1,0,fmhdr,fmhdi)
            call getxz(j2r(1,1,3),j2i(1,1,3),yb,2,0,fmhdr,fmhdi)
         else
#ifdef MPI
            call getpxz(j2r(1,1,1),j2i(1,1,1),yb,1,0,fmhdr,fmhdi,
     &           realg1,realg2,my_node_world)
            call getpxz(j2r(1,1,3),j2i(1,1,3),yb,2,0,fmhdr,fmhdi,
     &           realg1,realg2,my_node_world)
#endif
         end if
c
c     Compute the currents
c     1) First the derivatives in Fourier space
c     2) add u x B
c
         do z=1,nzc
            do y=yb,min(nyp,yb+mby-1)
               do x=1,nx/2
                  xy=x+(y-yb)*(nxp/2+1)
                  j2r(xy,z,2) = -alfa(x)*j2i(xy,z,1)
                  j2i(xy,z,2) =  alfa(x)*j2r(xy,z,1)
                  
                  j2r(xy,z,4) = -beta(z)*j2i(xy,z,1)
                  j2i(xy,z,4) =  beta(z)*j2r(xy,z,1)
               end do
               j2r(nx/2+1+(y-yb)*(nxp/2+1),z,1)=0.0 
               j2r(nx/2+1+(y-yb)*(nxp/2+1),z,2)=0.0 
               j2r(nx/2+1+(y-yb)*(nxp/2+1),z,3)=0.0 
               j2r(nx/2+1+(y-yb)*(nxp/2+1),z,4)=0.0 
            end do
         end do         
         if (nfzsym.eq.0) then
c
c     Zero oddball (z)
c     
            do xy=1,(nxp/2+1)*npl
               j2r(xy,nz/2+1,1)=0.0
               j2i(xy,nz/2+1,1)=0.0
               j2r(xy,nz/2+1,2)=0.0
               j2i(xy,nz/2+1,2)=0.0
               j2r(xy,nz/2+1,3)=0.0
               j2i(xy,nz/2+1,3)=0.0
               j2r(xy,nz/2+1,4)=0.0
               j2i(xy,nz/2+1,4)=0.0
            end do
         end if
c
c     Back transform to physical space
c
         do i=1,4
            call vcfftb(j2r(1,1,i),j2i(1,1,i),wr,wi,nz,
     &           nxy,(nxp/2+1)*mby,1,prezn)
            call vrfftb(j2r(1,1,i),j2i(1,1,i),wr,wi,
     &           nx,nzpc*mby,1,nxp/2+1,prexn)
         end do
c
c     <phi>,<phi^2> (Position 83-84)
c     <j_i>,<j_i^2>,<j1j2>,<j1j3>,<j2j3> (Position 85-93)
c     <phi j_i> (Position 94-96)
c
         do y=1,npl
            do z=1,memnz
               c=c1
               if(nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
               do x=1,nx/2
                  xy=x+(y-1)*(nxp/2+1)

                  j2r(xy,z,2) = -j2r(xy,z,2) 
     &                 +u2r(xy,z,2)*b0(3)-u2r(xy,z,3)*b0(2)
                  j2i(xy,z,2) = -j2i(xy,z,2) 
     &                 +u2i(xy,z,2)*b0(3)-u2i(xy,z,3)*b0(2)
                  j2r(xy,z,3) = -j2r(xy,z,3) 
     &                 +u2r(xy,z,3)*b0(1)-u2r(xy,z,1)*b0(3)
                  j2i(xy,z,3) = -j2i(xy,z,3) 
     &                 +u2i(xy,z,3)*b0(1)-u2i(xy,z,1)*b0(3)
                  j2r(xy,z,4) = -j2r(xy,z,4) 
     &                 +u2r(xy,z,1)*b0(2)-u2r(xy,z,2)*b0(1)
                  j2i(xy,z,4) = -j2i(xy,z,4) 
     &                 +u2i(xy,z,1)*b0(2)-u2i(xy,z,2)*b0(1)


                  xys(2*x-1,ybp+y-1,83)=xys(2*x-1,ybp+y-1,83)+
     &                 j2r(xy,z,1)*c
                  xys(2*x  ,ybp+y-1,83)=xys(2*x  ,ybp+y-1,83)+
     &                 j2i(xy,z,1)*c

                  xys(2*x-1,ybp+y-1,84)=xys(2*x-1,ybp+y-1,84)+
     &                 j2r(xy,z,1)**2*c
                  xys(2*x  ,ybp+y-1,84)=xys(2*x  ,ybp+y-1,84)+
     &                 j2i(xy,z,1)**2*c

                  xys(2*x-1,ybp+y-1,85)=xys(2*x-1,ybp+y-1,85)+
     &                 j2r(xy,z,2)*c
                  xys(2*x  ,ybp+y-1,85)=xys(2*x  ,ybp+y-1,85)+
     &                 j2i(xy,z,2)*c

                  xys(2*x-1,ybp+y-1,86)=xys(2*x-1,ybp+y-1,86)+
     &                 j2r(xy,z,3)*c
                  xys(2*x  ,ybp+y-1,86)=xys(2*x  ,ybp+y-1,86)+
     &                 j2i(xy,z,3)*c

                  xys(2*x-1,ybp+y-1,87)=xys(2*x-1,ybp+y-1,87)+
     &                 j2r(xy,z,4)*c
                  xys(2*x  ,ybp+y-1,87)=xys(2*x  ,ybp+y-1,87)+
     &                 j2i(xy,z,4)*c

                  xys(2*x-1,ybp+y-1,88)=xys(2*x-1,ybp+y-1,88)+
     &                 j2r(xy,z,2)*j2r(xy,z,2)*c
                  xys(2*x  ,ybp+y-1,88)=xys(2*x  ,ybp+y-1,88)+
     &                 j2i(xy,z,2)*j2i(xy,z,2)*c

                  xys(2*x-1,ybp+y-1,89)=xys(2*x-1,ybp+y-1,89)+
     &                 j2r(xy,z,3)*j2r(xy,z,3)*c
                  xys(2*x  ,ybp+y-1,89)=xys(2*x  ,ybp+y-1,89)+
     &                 j2i(xy,z,3)*j2i(xy,z,3)*c

                  xys(2*x-1,ybp+y-1,90)=xys(2*x-1,ybp+y-1,90)+
     &                 j2r(xy,z,4)*j2r(xy,z,4)*c
                  xys(2*x  ,ybp+y-1,90)=xys(2*x  ,ybp+y-1,90)+
     &                 j2i(xy,z,4)*j2i(xy,z,4)*c

                  xys(2*x-1,ybp+y-1,91)=xys(2*x-1,ybp+y-1,91)+
     &                 j2r(xy,z,2)*j2r(xy,z,3)*c
                  xys(2*x  ,ybp+y-1,91)=xys(2*x  ,ybp+y-1,91)+
     &                 j2i(xy,z,2)*j2i(xy,z,3)*c

                  xys(2*x-1,ybp+y-1,92)=xys(2*x-1,ybp+y-1,92)+
     &                 j2r(xy,z,2)*j2r(xy,z,4)*c
                  xys(2*x  ,ybp+y-1,92)=xys(2*x  ,ybp+y-1,92)+
     &                 j2i(xy,z,2)*j2i(xy,z,4)*c

                  xys(2*x-1,ybp+y-1,93)=xys(2*x-1,ybp+y-1,93)+
     &                 j2r(xy,z,3)*j2r(xy,z,4)*c
                  xys(2*x  ,ybp+y-1,93)=xys(2*x  ,ybp+y-1,93)+
     &                 j2i(xy,z,3)*j2i(xy,z,4)*c

                  xys(2*x-1,ybp+y-1,94)=xys(2*x-1,ybp+y-1,94)+
     &                 j2r(xy,z,1)*j2r(xy,z,2)*c
                  xys(2*x  ,ybp+y-1,94)=xys(2*x  ,ybp+y-1,94)+
     &                 j2i(xy,z,1)*j2i(xy,z,2)*c

                  xys(2*x-1,ybp+y-1,95)=xys(2*x-1,ybp+y-1,95)+
     &                 j2r(xy,z,1)*j2r(xy,z,3)*c
                  xys(2*x  ,ybp+y-1,95)=xys(2*x  ,ybp+y-1,95)+
     &                 j2i(xy,z,1)*j2i(xy,z,3)*c

                  xys(2*x-1,ybp+y-1,96)=xys(2*x-1,ybp+y-1,96)+
     &                 j2r(xy,z,1)*j2r(xy,z,4)*c
                  xys(2*x  ,ybp+y-1,96)=xys(2*x  ,ybp+y-1,96)+
     &                 j2i(xy,z,1)*j2i(xy,z,4)*c

               end do
            end do
         end do
      end if
c
c     ******************************************************************
c     **                                                              **
c     **           SCALAR  STATISTICS                                 **
c     **                                                              **
c     ******************************************************************
c
c     Statistics for the scalar field (1-11)
c


      do ith=1,scalar
         if (nxysth.ge.11) then
            do y=1,npl
               do z=1,memnz
                  c=c1
                  if (nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
                  do x=1,nx/2
                     xy=x+(y-1)*(nxp/2+1)
c     Scalar (1)
                     xysth(2*x-1,ybp+y-1,1,ith)=
     &                    xysth(2*x-1,ybp+y-1,1,ith)+
     &                    th2r(xy,z,1,ith)*c
                     xysth(2*x  ,ybp+y-1,1,ith)=
     &                    xysth(2*x  ,ybp+y-1,1,ith)+
     &                 th2i(xy,z,1,ith)*c
c     Scalar squared (2)
                     xysth(2*x-1,ybp+y-1,2,ith)=
     &                    xysth(2*x-1,ybp+y-1,2,ith)+
     &                    th2r(xy,z,1,ith)**2*c
                     xysth(2*x  ,ybp+y-1,2,ith)=
     &                    xysth(2*x  ,ybp+y-1,2,ith)+
     &                    th2i(xy,z,1,ith)**2*c
c     U scalar (3)
                     xysth(2*x-1,ybp+y-1,3,ith)=
     &                    xysth(2*x-1,ybp+y-1,3,ith)+
     &                    u2r(xy,z,1)*th2r(xy,z,1,ith)*c
                     xysth(2*x  ,ybp+y-1,3,ith)=
     &                    xysth(2*x  ,ybp+y-1,3,ith)+
     &                    u2i(xy,z,1)*th2i(xy,z,1,ith)*c
c     V scalar (4)
                     xysth(2*x-1,ybp+y-1,4,ith)=
     &                    xysth(2*x-1,ybp+y-1,4,ith)+
     &                    u2r(xy,z,2)*th2r(xy,z,1,ith)*c
                     xysth(2*x  ,ybp+y-1,4,ith)=
     &                    xysth(2*x  ,ybp+y-1,4,ith)+
     &                    u2i(xy,z,2)*th2i(xy,z,1,ith)*c
c     W scalar (5)
                     xysth(2*x-1,ybp+y-1,5,ith)=
     &                    xysth(2*x-1,ybp+y-1,5,ith)+
     &                    u2r(xy,z,3)*th2r(xy,z,1,ith)*c
                     xysth(2*x  ,ybp+y-1,5,ith)=
     &                    xysth(2*x  ,ybp+y-1,5,ith)+
     &                    u2i(xy,z,3)*th2i(xy,z,1,ith)*c
c     U scalar^2 (6)
                     xysth(2*x-1,ybp+y-1,6,ith)=
     &                    xysth(2*x-1,ybp+y-1,6,ith)+
     &                    u2r(xy,z,1)*th2r(xy,z,1,ith)**2*c
                     xysth(2*x  ,ybp+y-1,6,ith)=
     &                    xysth(2*x  ,ybp+y-1,6,ith)+
     &                    u2i(xy,z,1)*th2i(xy,z,1,ith)**2*c
c     V scalar^2 (7)
                     xysth(2*x-1,ybp+y-1,7,ith)=
     &                    xysth(2*x-1,ybp+y-1,7,ith)+
     &                    u2r(xy,z,2)*th2r(xy,z,1,ith)**2*c
                     xysth(2*x  ,ybp+y-1,7,ith)=
     &                    xysth(2*x  ,ybp+y-1,7,ith)+
     &                    u2i(xy,z,2)*th2i(xy,z,1,ith)**2*c
c     W scalar^2 (8)
                     xysth(2*x-1,ybp+y-1,8,ith)=
     &                    xysth(2*x-1,ybp+y-1,8,ith)+
     &                    u2r(xy,z,3)*th2r(xy,z,1,ith)**2*c
                     xysth(2*x  ,ybp+y-1,8,ith)=
     &                    xysth(2*x  ,ybp+y-1,8,ith)+
     &                    u2i(xy,z,3)*th2i(xy,z,1,ith)**2*c
c     Scalar dissipation (d theta/dx)^2+(d theta/dy)^2+(d theta/dz)^2 (9-11)
                     xysth(2*x-1,ybp+y-1,9,ith)=
     &                    xysth(2*x-1,ybp+y-1,9,ith)+
     &                    th2r(xy,z,2,ith)**2*c
                     xysth(2*x  ,ybp+y-1,9,ith)=
     &                    xysth(2*x  ,ybp+y-1,9,ith)+
     &                    th2i(xy,z,2,ith)**2*c
                     xysth(2*x-1,ybp+y-1,10,ith)=
     &                    xysth(2*x-1,ybp+y-1,10,ith)+
     &                    th2r(xy,z,3,ith)**2*c
                     xysth(2*x  ,ybp+y-1,10,ith)=
     &                    xysth(2*x  ,ybp+y-1,10,ith)+
     &                    th2i(xy,z,3,ith)**2*c
                     xysth(2*x-1,ybp+y-1,11,ith)=
     &                    xysth(2*x-1,ybp+y-1,11,ith)+
     &                    th2r(xy,z,4,ith)**2*c
                     xysth(2*x  ,ybp+y-1,11,ith)=
     &                    xysth(2*x  ,ybp+y-1,11,ith)+
     &                    th2i(xy,z,4,ith)**2*c
                  end do
               end do
            end do
         end if
      end do
c
c     Statictics for the scalar-pressure field (12-15)
c
      do ith=1,scalar
         if (pressure.eq.1.and.nxysth.ge.15) then
            do y=1,npl
               do z=1,memnz
                  c=c1
                  if(nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
                  do x=1,nx/2
                     xy=x+(y-1)*(nxp/2+1)
c
c     Pressure scalar (12)
c
                     xysth(2*x-1,ybp+y-1,12,ith)=
     &                    xysth(2*x-1,ybp+y-1,12,ith)+
     &                    h2r(xy,z,1)*th2r(xy,z,1,ith)*c
                     xysth(2*x,ybp+y-1,12,ith)=
     &                    xysth(2*x,ybp+y-1,12,ith)+
     &                    h2i(xy,z,1)*th2i(xy,z,1,ith)*c
c
c     Pressure scalar-gradient correlation (13-15)
c
c     p dtheta/dx (13)
                     xysth(2*x-1,ybp+y-1,13,ith)=
     &                    xysth(2*x-1,ybp+y-1,13,ith)+
     &                    h2r(xy,z,1)*th2r(xy,z,2,ith)*c
                     xysth(2*x  ,ybp+y-1,13,ith)=
     &                    xysth(2*x  ,ybp+y-1,13,ith)+
     &                    h2i(xy,z,1)*th2i(xy,z,2,ith)*c
c     p dtheta/dy (14)
                     xysth(2*x-1,ybp+y-1,14,ith)=
     &                    xysth(2*x-1,ybp+y-1,14,ith)+
     &                    h2r(xy,z,1)*th2r(xy,z,3,ith)*c
                     xysth(2*x  ,ybp+y-1,14,ith)=
     &                    xysth(2*x  ,ybp+y-1,14,ith)+
     &                    h2i(xy,z,1)*th2i(xy,z,3,ith)*c
c     p dtheta/dz (15)
                     xysth(2*x-1,ybp+y-1,15,ith)=
     &                    xysth(2*x-1,ybp+y-1,15,ith)+
     &                    h2r(xy,z,1)*th2r(xy,z,4,ith)*c
                     xysth(2*x  ,ybp+y-1,15,ith)=
     &                    xysth(2*x  ,ybp+y-1,15,ith)+
     &                    h2i(xy,z,1)*th2i(xy,z,4,ith)*c
                  end do
               end do
            end do               
         end if
      end do               
c
c     Additional scalar-velocity correlations (16-21)
c
      do ith=1,scalar
         if (nxysth.ge.21) then
            do y=1,npl
               do z=1,memnz
                  c=c1
                  if(nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
                  do x=1,nx/2
                     xy=x+(y-1)*(nxp/2+1)
c     u^2 theta (16)
                     xysth(2*x-1,ybp+y-1,16,ith)=
     &                    xysth(2*x-1,ybp+y-1,16,ith)+
     &                    u2r(xy,z,1)**2*th2r(xy,z,1,ith)*c
                     xysth(2*x  ,ybp+y-1,16,ith)=
     &                    xysth(2*x,ybp+y-1  ,16,ith)+
     &                    u2i(xy,z,1)**2*th2i(xy,z,1,ith)*c
c     v^2 theta (17)
                     xysth(2*x-1,ybp+y-1,17,ith)=
     &                    xysth(2*x-1,ybp+y-1,17,ith)+
     &                    u2r(xy,z,2)**2*th2r(xy,z,1,ith)*c
                     xysth(2*x  ,ybp+y-1,17,ith)=
     &                    xysth(2*x,ybp+y-1,17,ith)+
     &                    u2i(xy,z,2)**2*th2i(xy,z,1,ith)*c
c     w^2 theta (18)
                     xysth(2*x-1,ybp+y-1,18,ith)=
     &                    xysth(2*x-1,ybp+y-1,18,ith)+
     &                    u2r(xy,z,3)**2*th2r(xy,z,1,ith)*c
                     xysth(2*x  ,ybp+y-1,18,ith)=
     &                    xysth(2*x  ,ybp+y-1,18,ith)+
     &                    u2i(xy,z,3)**2*th2i(xy,z,1,ith)*c
c     u v theta (19)
                     xysth(2*x-1,ybp+y-1,19,ith)=
     &                    xysth(2*x-1,ybp+y-1,19,ith)+
     &                    u2r(xy,z,1)*u2r(xy,z,2)*th2r(xy,z,1,ith)*c
                     xysth(2*x  ,ybp+y-1,19,ith)=
     &                    xysth(2*x  ,ybp+y-1,19,ith)+
     &                    u2i(xy,z,1)*u2i(xy,z,2)*
     &                    th2i(xy,z,1,ith)*c
c     u w theta (20)
                     xysth(2*x-1,ybp+y-1,20,ith)=
     &                    xysth(2*x-1,ybp+y-1,20,ith)+
     &                    u2r(xy,z,1)*u2r(xy,z,3)*
     &                    th2r(xy,z,1,ith)*c
                     xysth(2*x  ,ybp+y-1,20,ith)=
     &                    xysth(2*x  ,ybp+y-1,20,ith)+
     &                    u2i(xy,z,1)*u2i(xy,z,3)*
     &                    th2i(xy,z,1,ith)*c
c     v w theta (21)
                     xysth(2*x-1,ybp+y-1,21,ith)=
     &                    xysth(2*x-1,ybp+y-1,21,ith)+
     &                    u2r(xy,z,2)*u2r(xy,z,3)*
     &                    th2r(xy,z,1,ith)*c
                     xysth(2*x  ,ybp+y-1,21,ith)=
     &                    xysth(2*x  ,ybp+y-1,21,ith)+
     &                    u2i(xy,z,2)*u2i(xy,z,3)*
     &                    th2i(xy,z,1,ith)*c
                  end do
               end do
            end do
         end if
      end do
c
c     u_j thetax_i (22-30)
c
      do ith=1,scalar
         if (nxysth.ge.30) then
            do j=1,3
               do i=1,3
                  k = 22 + (i-1) + 3*(j-1)
                  do y=1,npl
                     do z=1,memnz
                        c=c1
                        if(nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) 
     &                       c=c1/2.
                        do x=1,nx/2
                           xy=x+(y-1)*(nxp/2+1)
                           xysth(2*x-1,ybp+y-1,k,ith)=
     &                          xysth(2*x-1,ybp+y-1,k,ith)+
     &                          u2r(xy,z,j)*th2r(xy,z,i+1,ith)*c
                           xysth(2*x,ybp+y-1,k,ith)=
     &                          xysth(2*x,ybp+y-1,k,ith)+
     &                          u2i(xy,z,j)*th2i(xy,z,i+1,ith)*c
                        end do
                     end do
                  end do
               end do
            end do
         end if
      end do
c
c     Scalar-velocity "dissipation" dui/dxj dtheta/dxj (31-33)
c
      do ith=1,scalar
         if (nxysth.ge.33) then
            do i=1,3
               k = 31 + (i-1)
               do y=1,npl
                  do z=1,memnz
                     c=c1
                     if(nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
                     do x=1,nx/2
                        xy=x+(y-1)*(nxp/2+1)
                        xysth(2*x-1,ybp+y-1,k,ith)=
     &                       xysth(2*x-1,ybp+y-1,k,ith)+
     &                       du2r(xy,z,i,1)*th2r(xy,z,2,ith)*c+
     &                       du2r(xy,z,i,2)*th2r(xy,z,3,ith)*c+
     &                       du2r(xy,z,i,3)*th2r(xy,z,4,ith)*c
                        xysth(2*x  ,ybp+y-1,k,ith)=
     &                       xysth(2*x  ,ybp+y-1,k,ith)+
     &                       du2i(xy,z,i,1)*th2i(xy,z,2,ith)*c+
     &                       du2i(xy,z,i,2)*th2i(xy,z,3,ith)*c+
     &                       du2i(xy,z,i,3)*th2i(xy,z,4,ith)*c
                     end do
                  end do
               end do
            end do
         end if
      end do
c     
c     Scalar skewness and flatness (34-35)
c
      do ith=1,scalar
         if (nxysth.ge.35) then
            do y=1,npl
               do z=1,memnz
                  c=c1
                  if(nfzsym.eq.1.and.(z.eq.1.or.z.eq.nzc+1)) c=c1/2.
                  do x=1,nx/2
                     xy=x+(y-1)*(nxp/2+1)
                     xysth(2*x-1,ybp+y-1,34,ith)=
     &                    xysth(2*x-1,ybp+y-1,34,ith)+
     &                    th2r(xy,z,1,ith)**3*c
                     xysth(2*x  ,ybp+y-1,34,ith)=
     &                    xysth(2*x  ,ybp+y-1,34,ith)+
     &                    th2i(xy,z,1,ith)**3*c
                     xysth(2*x-1,ybp+y-1,35,ith)=
     &                    xysth(2*x-1,ybp+y-1,35,ith)+
     &                    th2r(xy,z,1,ith)**4*c
                     xysth(2*x  ,ybp+y-1,35,ith)=
     &                    xysth(2*x  ,ybp+y-1,35,ith)+
     &                    th2i(xy,z,1,ith)**4*c
                  end do
               end do
            end do
         end if
      end do


c
c     ******************************************************************
c     **                                                              **
c     **           TWO-POINT  CORRELATIONS                            **
c     **                                                              **
c     ******************************************************************
c
c     Spanwise two-point correlation at selected (x/y) positions
c
c     Correlation types:   1   uu
c                          2   vv
c                          3   ww
c                          4   pp
c                          5   uv
c                          6   uw
c                          7   up
c                          8   vw
c                          9   vp
c                         10   wp
c                         11   dudy dudy
c                         12   t1t1 
c                         13   t1u
c                         14   t1v
c                         15   t1w
c                         16   t1p
c                         17   dt1dy dt1dy
c                         18   t2t2
c                         19   t2u
c                         ...
c                         12+scalar*6   t1t1
c                         13+scalar*6   t1t2
c                         ...
c                         11+6*scalar+scalar**2 tNtN
c
c
c     OLD types:           1   uu
c                          2   vv
c                          3   ww
c                          4   pp
c                          5   tt
c                          6   uv
c                          7   uw
c                          8   up
c                          9   ut
c                         10   vw
c                         11   vp
c                         12   vt
c                         13   wp
c                         14   wt
c                         15   pt
c
c     

      if (corrf) then         
c
c     Coordinate indices are corrxi,corryi (corrxodd)
c
c     Loop over all correlations and determine if we are in correct plane
c
         do i=1,ncorr

            if ((yb.le.corryi(i)).and.((yb+npl-1).ge.corryi(i))) then
c
c     Get quantity depending on correlation type
c
               if (corrxi(i).eq.0) then
c
c     this is for a streamwise average
c     
                  is = 1
                  ie = nx
		 ngroupz=nprocz
               else
                  is = corrxi(i)+(yb+npl-1-corryi(i))*(nxp/2+1)
                  ie = is
		ngroupz=1
               end if

		
               do ixyouter = is,ie,ngroupz
		do ixyinner=1,ngroupz
		  ixy=ixyouter+ixyinner-1

                  
                  if (corrxi(i).eq.0) then
                     xy = (ixy-1)/2+1
                     corrxodd(i) = mod(ixy,2)
                  else
                     xy = ixy
                  end if


               if (corrt(i).le.3) then
c
c     uu, vv, ww
c
                  if (corrxodd(i).eq.1) then
                     do z=1,memnz
                        corrval1(z)=u2r(xy,z,corrt(i))
                        corrval2(z)=u2r(xy,z,corrt(i))
                     end do
                  else
                     do z=1,memnz
                        corrval1(z)=u2i(xy,z,corrt(i))
                        corrval2(z)=u2i(xy,z,corrt(i))
                     end do
                  end if
               else if (corrt(i).eq.4.and.pressure.eq.1) then
c
c     pp
c
                  if (corrxodd(i).eq.1) then
                     do z=1,memnz
                        corrval1(z)=h2r(xy,z,1)
                        corrval2(z)=h2r(xy,z,1)
                     end do
                  else
                     do z=1,memnz
                        corrval1(z)=h2i(xy,z,1)
                        corrval2(z)=h2i(xy,z,1)
                     end do
                  end if
               else if (corrt(i).eq.5) then
c
c     uv
c
                  if (corrxodd(i).eq.1) then
                     do z=1,memnz
                        corrval1(z)=u2r(xy,z,1)
                        corrval2(z)=u2r(xy,z,2)
                     end do
                  else
                     do z=1,memnz
                        corrval1(z)=u2i(xy,z,1)
                        corrval2(z)=u2i(xy,z,2)
                     end do
                  end if
               else if (corrt(i).eq.6) then
c
c     uw
c
                  if (corrxodd(i).eq.1) then
                     do z=1,memnz
                        corrval1(z)=u2r(xy,z,1)
                        corrval2(z)=u2r(xy,z,3)
                     end do
                  else
                     do z=1,memnz
                        corrval1(z)=u2i(xy,z,1)
                        corrval2(z)=u2i(xy,z,3)
                     end do
                  end if
               else if (corrt(i).eq.7.and.pressure.eq.1) then
c
c     up
c
                  if (corrxodd(i).eq.1) then
                     do z=1,memnz
                        corrval1(z)=u2r(xy,z,1)
                        corrval2(z)=h2r(xy,z,1)
                     end do
                  else
                     do z=1,memnz
                        corrval1(z)=u2i(xy,z,1)
                        corrval2(z)=h2i(xy,z,1)
                     end do
                  end if  
               else if (corrt(i).eq.8) then
c
c     vw
c
                  if (corrxodd(i).eq.1) then
                     do z=1,memnz
                        corrval1(z)=u2r(xy,z,2)
                        corrval2(z)=u2r(xy,z,3)
                     end do
                  else
                     do z=1,memnz
                        corrval1(z)=u2i(xy,z,2)
                        corrval2(z)=u2i(xy,z,3)
                     end do
                  end if
               else if (corrt(i).eq.9.and.pressure.eq.1) then
c
c     vp
c
                  if (corrxodd(i).eq.1) then
                     do z=1,memnz
                        corrval1(z)=u2r(xy,z,2)
                        corrval2(z)=h2r(xy,z,1)
                     end do
                  else
                     do z=1,memnz
                        corrval1(z)=u2i(xy,z,2)
                        corrval2(z)=h2i(xy,z,1)
                     end do
                  end if  
               else if (corrt(i).eq.10.and.pressure.eq.1) then
c
c     wp
c
                  if (corrxodd(i).eq.1) then
                     do z=1,memnz
                        corrval1(z)=u2r(xy,z,3)
                        corrval2(z)=h2r(xy,z,1)
                     end do
                  else
                     do z=1,memnz
                        corrval1(z)=u2i(xy,z,3)
                        corrval2(z)=h2i(xy,z,1)
                     end do
                  end if  
               else if (corrt(i).eq.11) then
c     
c     dudy dudy
c     
                  if (corrxodd(i).eq.1) then
                     do z=1,memnz
                        corrval1(z)=du2r(xy,z,1,2)*dstar
                        corrval2(z)=du2r(xy,z,1,2)*dstar
                     end do
                  else
                     do z=1,memnz
                        corrval1(z)=du2i(xy,z,1,2)*dstar
                        corrval2(z)=du2i(xy,z,1,2)*dstar
                     end do
                  end if  
               else if (corrt(i).ge.12.and.corrt(i).le.11+6*scalar) then
c
c     Scalar-velocity correlations
c
                  tth = mod(corrt(i)-12,6)+1
                  ith = (corrt(i)-11-tth)/6+1

                  if (tth.eq.1) then
c
c     tt
c
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=th2r(xy,z,1,ith)
                           corrval2(z)=th2r(xy,z,1,ith)
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=th2i(xy,z,1,ith)
                           corrval2(z)=th2i(xy,z,1,ith)
                        end do
                     end if
                  else if (tth.eq.2) then
c
c     ut
c
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=u2r (xy,z,1)
                           corrval2(z)=th2r(xy,z,1,ith)
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=u2i (xy,z,1)
                           corrval2(z)=th2i(xy,z,1,ith)
                        end do
                     end if
                  else if (tth.eq.3) then
c     
c     vt
c
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=u2r (xy,z,2)
                           corrval2(z)=th2r(xy,z,1,ith)
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=u2i (xy,z,2)
                           corrval2(z)=th2i(xy,z,1,ith)
                        end do
                     end if
                  else if (tth.eq.4) then
c
c     wt
c
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=u2r (xy,z,3)
                           corrval2(z)=th2r(xy,z,1,ith)
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=u2i (xy,z,3)
                           corrval2(z)=th2i(xy,z,1,ith)
                        end do
                     end if
                  else if (tth.eq.5) then
c
c     pt
c     
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=h2r (xy,z,1)
                           corrval2(z)=th2r(xy,z,1,ith)
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=h2i (xy,z,1)
                           corrval2(z)=th2i(xy,z,1,ith)
                        end do
                     end if
                  else if (tth.eq.6) then
c
c     dtdy dtdy
c
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=th2r(xy,z,3,ith)*dstar
                           corrval2(z)=th2r(xy,z,3,ith)*dstar
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=th2i(xy,z,3,ith)*dstar
                           corrval2(z)=th2i(xy,z,3,ith)*dstar
                        end do
                     end if
                  end if
               else if (corrt(i).ge.12+6*scalar.and.corrt(i)
     &                 .le.11+6*scalar+scalar**2) then
c
c     Scalar-scalar correlations
c
                  tth = mod(corrt(i)-(11+6*scalar)-1,scalar)+1
                  ith = (corrt(i)-(11+6*scalar)-1)/scalar+1

                  if (corrxodd(i).eq.1) then
                     do z=1,memnz
                        corrval1(z)=th2r(xy,z,1,tth)
                        corrval2(z)=th2r(xy,z,1,ith)
                     end do
                  else
                     do z=1,memnz
                        corrval1(z)=th2i(xy,z,1,tth)
                        corrval2(z)=th2i(xy,z,1,ith)
                     end do
                  end if
               else
                  if (my_node_world.eq.0) then
                     write(*,*) 'Two-point correlation ',i,' refers to'
                     write(*,*) 'a nonexisting quantity ',corrt(i)
                  end if
                  call stopnow(4534)
               end if

c     
c     Send the individual statistics to processor 0
c     
#ifdef MPI
c               call mpi_gather(corrval1,memnz,mpi_double_precision,
c     &              corrval1,memnz,mpi_double_precision,
c     &              0,my_comm_x,ierror)
c               call mpi_gather(corrval2,memnz,mpi_double_precision,
c     &              corrval2,memnz,mpi_double_precision,
c     &              0,my_comm_x,ierror)

c	for correlation on one steamwise location
	if(is.eq.ie) then

               do z=1,memnz
                  corrval3(1,z) = corrval1(z)
                  corrval3(2,z) = corrval2(z)
               end do
               call mpi_gather(corrval3,2*memnz,mpi_double_precision,
     &              corrval4,2*memnz,mpi_double_precision,
     &              0,my_comm_x,ierror)
               if (my_node_x.eq.0) then
                  do z=1,nzc+2
                     corrval1(z) = corrval4(1,z)
                     corrval2(z) = corrval4(2,z)
                  end do
               end if
#endif
c
c     Postprocess the two-point correlations on master node
c
               if (my_node_x.eq.0) then
c
c     Compute mean and square
c
                  do z=1,nzc
                     corr_ms(1,i) = corr_ms(1,i) + corrval1(z)*c1
                     corr_ms(2,i) = corr_ms(2,i) + corrval2(z)*c1
                     corr_ms(3,i) = corr_ms(3,i) + corrval1(z)**2*c1
                     corr_ms(4,i) = corr_ms(4,i) + corrval2(z)**2*c1
                  end do            
c
c     Transform to Fourier space
c
                  call vrfftf(corrval1(1),corrval1(2),cw(1),cw(2),
     &                 nzc,1,2,1,corrwsave)
                  call vrfftf(corrval2(1),corrval2(2),cw(1),cw(2),
     &                 nzc,1,2,1,corrwsave)
c     
c     Compute correlation in Fourier space and rescale
c
                  do z=1,nzc+2,2
                     dr = corrval1(z  )*corrval2(z  )+
     &                    corrval1(z+1)*corrval2(z+1)
                     corrval1(z+1)=corrval1(z+1)*corrval2(z  )-
     &                    corrval1(z  )*corrval2(z+1)
                     corrval1(z) = dr
                  end do
                  do z=1,nzc+2
                     corr(z,i)=corr(z,i)+corrval1(z)*dtn/
     &                    real(nzc)/real(nzc)
                  end do
               end if

c	for correlations averaged over the streamwise direction
#ifdef MPI
	else
               do z=1,memnz
		zzz=(ixyinner-1)*memnz + z
                  corrvaltemp3(1,zzz) = corrval1(z)
                  corrvaltemp3(2,zzz) = corrval2(z)
c                  corrvaltemp4(1,z,ixyinner) = corrval1(z)
c                  corrvaltemp4(2,z,ixyinner) = corrval2(z)
               end do
#endif
	endif
c		if(i.eq.1.and.ixy.eq.ie)then
c		write(*,*)'ier xnode z',ixyinner, my_node_x,my_node_z
c		endif
	enddo

		
#ifdef MPI	
	if(is.ne.ie)then
c		if(i.eq.1.and.my_node_x.eq.0.and.ixy.eq.ie)then
c		write(*,*)'before all2all node 1',corrvaltemp3(1,memnz+1),
c     & corrvaltemp4(1,nzc+1)
c		endif
               call mpi_alltoall(corrvaltemp3,2*memnz,
     &                 mpi_double_precision,corrvaltemp4
     &              ,2*memnz,mpi_double_precision,
     &              my_comm_x,ierror)
c               if (my_node_x.eq.0) then
c		if(i.eq.1.and.my_node_x.eq.1.and.ixy.eq.ie)then
c		write(*,*)'after all2all node 2',corrvaltemp4(1,1),
c     &  corrvaltemp4(1,nzc+1)
c		endif
c		if(i.eq.1.and.ixy.eq.ie)then
c		write(*,*)'ixy xnode znode',ixy, my_node_x,my_node_z
c		endif

                 do z=1,nzc+2
c		do zzznode=1,ngroupz
c		    do zzz=1,memnz		
c		    z=(zzznode-1)*memnz+zzz
                     corrval1(z) = corrvaltemp4(1,z)
                     corrval2(z) = corrvaltemp4(2,z)
c		   end do 
                 end do
c               end if

c
c     Postprocess the two-point correlations on each node
c
c     Compute mean and square
c

	
                  do z=1,nzc
                     corr_ms(1,i) = corr_ms(1,i) + corrval1(z)*c1
                     corr_ms(2,i) = corr_ms(2,i) + corrval2(z)*c1
                     corr_ms(3,i) = corr_ms(3,i) + corrval1(z)**2*c1
                     corr_ms(4,i) = corr_ms(4,i) + corrval2(z)**2*c1
                  end do     


c
c     Transform to Fourier space
c
                  call vrfftf(corrval1(1),corrval1(2),cw(1),cw(2),
     &                 nzc,1,2,1,corrwsave)
                  call vrfftf(corrval2(1),corrval2(2),cw(1),cw(2),
     &                 nzc,1,2,1,corrwsave)
c     
c     Compute correlation in Fourier space and rescale
c
                  do z=1,nzc+2,2
                     dr = corrval1(z  )*corrval2(z  )+
     &                    corrval1(z+1)*corrval2(z+1)
                     corrval1(z+1)=corrval1(z+1)*corrval2(z  )-
     &                    corrval1(z  )*corrval2(z+1)
                     corrval1(z) = dr
                  end do
c                  do z=1,nzc+2
c                     corrztemp1(z)=corrval1(z)*dtn/
c     &                    real(nzc)/real(nzc)
c			corrztemp2(z)=0.
c                  end do
c		if(i.eq.1.and.ixy.eq.ie)then
c		write(*,*)'before sum ',corrval1(1),corrval1(nzc+1)
c		endif
                  call mpi_reduce(corrval1,corrztemp2,nzc+2,
     &              mpi_double_precision,MPI_SUM, 0,my_comm_x,ierror)

c		if(i.eq.1.and.ixy.eq.ie.and.my_node_x.eq.0)then
c		write(*,*)'after sum ',corrztemp2(1),corrztemp2(nzc+1)
c		endif
c
c     Postprocess the two-point correlations on master node
c
               if (my_node_x.eq.0) then		
                 do z=1,nzc+2
                     corr(z,i)=corr(z,i)+corrztemp2(z)*dtn/
     &                    real(nzc)/real(nzc)
                 end do
	       endif

	end if
#endif

               end do
#ifdef MPI
		if (corrxi(i).eq.0) then
                  call mpi_reduce(corr_ms,corrztemp1,4,
     &              mpi_double_precision,MPI_SUM, 0,my_comm_x,ierror)  
              	  if (my_node_x.eq.0) then		
 		     corr_ms(1,i) = corrztemp1(1)
                     corr_ms(2,i) = corrztemp1(2)
                     corr_ms(3,i) = corrztemp1(3)
                     corr_ms(4,i) = corrztemp1(4)
		  else
		     corr_ms(1,i) = 0.
                     corr_ms(2,i) = 0.
                     corr_ms(3,i) = 0.
                     corr_ms(4,i) = 0.			
		  endif
		endif
#endif        
	    end if
         end do
      end if

c
c     ******************************************************************
c     **                                                              **
c     **           TWO-POINT CORRELATIONS                             **
c     **                                                              **
c     ******************************************************************
c
c     axial two-point correlation at selected (x/y) positions in the
c     middle z-plane
c     Correlation types:   1   uu
c                          2   vv
c                          3   ww
c                          4   pp
c                          5   uv
c                          6   uw
c                          7   up
c                          8   vw
c                          9   vp
c                         10   wp
c                         11   dudy dudy
c                         12   t1t1
c                         13   t1u
c                         14   t1v
c                         15   t1w
c                         16   t1p
c                         17   dt1dy dt1dy
c                         18   t2t2
c                         19   t2u
c                         ...
c                         12+scalar*6   t1t1
c                         13+scalar*6   t1t2
c                         ...
c                         11+6*scalar+scalar**2 tNtN
c
c
c     OLD types:           1   uu
c                          2   vv
c                          3   ww
c                          4   pp
c                          5   tt
c                          6   uv
c                          7   uw
c                          8   up
c                          9   ut
c                         10   vw
c                         11   vp
c                         12   vt
c                         13   wp
c                         14   wt
c                         15   pt
c
      if (corrf_x) then
c
c     Coordinate indices are corrzi,corryi_x
c
c     Loop over all correlations and determine if we are in correct plane
c
         do i=1,ncorr_x

            if ((yb.le.corryi_x(i)).and.((yb+npl-1).ge.corryi_x(i))) 
     &           then


             if ((corrzi(i).ge.zb.and.corrzi(i).lt.(zb+memnz))
     &              .or.corrzi(i).eq.0) then
c
c     Get quantity depending on correlation type
c
               xy=(yb+npl-1-corryi_x(i))*(nxp/2+1)+1

               if (corrzi(i).eq.0) then
                  is=1
                  ie=memnz
               else
                  is = mod(corrzi(i)-1,memnz)+1
                  ie = is
               end if

               do k_ind=is,ie


               if (corrt_x(i).le.3) then
cc
cc     uu, vv, ww
cc
                do x=1,nx/2
                   corrval1x(2*x-1)=u2r(xy+x-1,k_ind,corrt_x(i))
                   corrval1x(2*x)=u2i(xy+x-1,k_ind,corrt_x(i))
                   corrval2x(2*x-1)=u2r(xy+x-1,k_ind,corrt_x(i))
                   corrval2x(2*x)=u2i(xy+x-1,k_ind,corrt_x(i))
                end do

               else if (corrt_x(i).eq.4.and.pressure.eq.1) then
c
c     pp
c
                do x=1,nx/2
                   corrval1x(2*x-1)=h2r(xy+x-1,k_ind,1)
                   corrval1x(2*x)=h2i(xy+x-1,k_ind,1)
                   corrval2x(2*x-1)=h2r(xy+x-1,k_ind,1)
                   corrval2x(2*x)=h2i(xy+x-1,k_ind,1)
                end do


               else if (corrt_x(i).eq.5) then

c     uv
c
                do x=1,nx/2
                   corrval1x(2*x-1)=u2r(xy+x-1,k_ind,1)
                   corrval1x(2*x)=u2i(xy+x-1,k_ind,1)
                   corrval2x(2*x-1)=u2r(xy+x-1,k_ind,2)
                   corrval2x(2*x)=u2i(xy+x-1,k_ind,2)
                end do

               else if (corrt_x(i).eq.6) then
c
c     uw
c
                do x=1,nx/2
                   corrval1x(2*x-1)=u2r(xy+x-1,k_ind,1)
                   corrval1x(2*x)=u2i(xy+x-1,k_ind,1)
                   corrval2x(2*x-1)=u2r(xy+x-1,k_ind,3)
                   corrval2x(2*x)=u2i(xy+x-1,k_ind,3)
                end do

               else if (corrt_x(i).eq.7.and.pressure.eq.1) then
c
c     up
c
                do x=1,nx/2
                   corrval1x(2*x-1)=u2r(xy+x-1,k_ind,1)
                   corrval1x(2*x)=u2i(xy+x-1,k_ind,1)
                   corrval2x(2*x-1)=h2r(xy+x-1,k_ind,1)
                   corrval2x(2*x)=h2i(xy+x-1,k_ind,1)
                end do

               else if (corrt_x(i).eq.8) then
c
c     vw
c
                do x=1,nx/2
                   corrval1x(2*x-1)=u2r(xy+x-1,k_ind,2)
                   corrval1x(2*x)=u2i(xy+x-1,k_ind,2)
                   corrval2x(2*x-1)=u2r(xy+x-1,k_ind,3)
                   corrval2x(2*x)=u2i(xy+x-1,k_ind,3)
                end do

               else if (corrt_x(i).eq.9.and.pressure.eq.1) then
c
c     vp
c
                do x=1,nx/2
                   corrval1x(2*x-1)=u2r(xy+x-1,k_ind,2)
                   corrval1x(2*x)=u2i(xy+x-1,k_ind,2)
                   corrval2x(2*x-1)=h2r(xy+x-1,k_ind,1)
                   corrval2x(2*x)=h2i(xy+x-1,k_ind,1)
                end do

               else if (corrt_x(i).eq.10.and.pressure.eq.1) then
c
c     wp
c
                do x=1,nx/2
                   corrval1x(2*x-1)=u2r(xy+x-1,k_ind,3)
                   corrval1x(2*x)=u2i(xy+x-1,k_ind,3)
                   corrval2x(2*x-1)=h2r(xy+x-1,k_ind,1)
                   corrval2x(2*x)=h2i(xy+x-1,k_ind,1)
                end do

               else if (corrt_x(i).eq.11) then
c
c     dudy dudy
c
                do x=1,nx/2
                   corrval1x(2*x-1)=(du2r(xy+x-1,k_ind,1,2))*dstar
                   corrval1x(2*x)=(du2i(xy+x-1,k_ind,1,2))*dstar
                   corrval2x(2*x-1)=(du2r(xy+x-1,k_ind,1,2))*dstar
                   corrval2x(2*x)=(du2i(xy+x-1,k_ind,1,2))*dstar
                end do

               else if (corrt_x(i).ge.12.and.corrt_x(i).le.11+6*scalar)
     &               then
c
c     Scalar-velocity correlations
c
                  tth = mod(corrt_x(i)-12,6)+1
                  ith = (corrt_x(i)-11-tth)/6+1
                  
                  if (tth.eq.1) then
c     
c     tt
c     
                     do x=1,nx/2
                        corrval1x(2*x-1)=th2r(xy+x-1,k_ind,1,ith)
                        corrval1x(2*x)=th2i(xy+x-1,k_ind,1,ith)
                        corrval2x(2*x-1)=th2r(xy+x-1,k_ind,1,ith)
                        corrval2x(2*x)=th2i(xy+x-1,k_ind,1,ith)
                     end do
                     
                  else if (tth.eq.2) then
c     
c     ut
c     
                     do x=1,nx/2
                        corrval1x(2*x-1)=u2r(xy+x-1,k_ind,1)
                        corrval1x(2*x)=u2i(xy+x-1,k_ind,1)
                        corrval2x(2*x-1)=th2r(xy+x-1,k_ind,1,ith)
                        corrval2x(2*x)=th2i(xy+x-1,k_ind,1,ith)
                     end do
                     
c     
c     vt
c     
                     do x=1,nx/2
                        corrval1x(2*x-1)=u2r(xy+x-1,k_ind,2)
                        corrval1x(2*x)=u2i(xy+x-1,k_ind,2)
                        corrval2x(2*x-1)=th2r(xy+x-1,k_ind,1,ith)
                        corrval2x(2*x)=th2i(xy+x-1,k_ind,1,ith)
                     end do
                     
c     
c     wt
c     
                     do x=1,nx/2
                        corrval1x(2*x-1)=u2r(xy+x-1,k_ind,3)
                        corrval1x(2*x)=u2i(xy+x-1,k_ind,3)
                        corrval2x(2*x-1)=th2r(xy+x-1,k_ind,1,ith)
                        corrval2x(2*x)=th2i(xy+x-1,k_ind,1,ith)
                     end do
                     
                  else if (tth.eq.5) then
c     
c     pt
c     
                     do x=1,nx/2
                        corrval1x(2*x-1)=h2r(xy+x-1,k_ind,1)
                        corrval1x(2*x)=h2i(xy+x-1,k_ind,1)
                        corrval2x(2*x-1)=th2r(xy+x-1,k_ind,1,ith)
                        corrval2x(2*x)=th2i(xy+x-1,k_ind,1,ith)
                     end do
                     
                  else if (tth.eq.6) then
c     
c     dtdy dtdy
c     
                     do x=1,nx/2
                        corrval1x(2*x-1)=th2r(xy+x-1,k_ind,3,ith)
                        corrval1x(2*x)=th2i(xy+x-1,k_ind,3,ith)
                        corrval2x(2*x-1)=th2r(xy+x-1,k_ind,3,ith)
                        corrval2x(2*x)=th2i(xy+x-1,k_ind,3,ith)
                     end do
                     
                  endif
               else if (corrt_x(i).ge.12+6*scalar.and.corrt_x(i)
     &                 .le.11+6*scalar+scalar**2) then
c     
c     Scalar-scalar correlations
c     
                  tth = mod(corrt_x(i)-(11+6*scalar)-1,scalar)+1
                  ith = (corrt_x(i)-(11+6*scalar)-1)/scalar+1
                  
                  do x=1,nx/2
                     corrval1x(2*x-1)=th2r(xy+x-1,k_ind,1,tth)
                     corrval1x(2*x)=th2i(xy+x-1,k_ind,1,tth)
                     corrval2x(2*x-1)=th2r(xy+x-1,k_ind,1,ith)
                     corrval2x(2*x)=th2i(xy+x-1,k_ind,1,ith)
                  end do
                  
               else
                  if (my_node_world.eq.0) then
                     write(*,*) 'Two-point correlation ',i,' refers to'
                     write(*,*) 'a nonexisting quantity ',corrt_x(i)
                  end if
                  call stopnow(4534)
               end if
c     
c     Compute mean and square
c     
               do x=1,nx
                  corr_ms_x(1,i) = corr_ms_x(1,i) + 
     &                 corrval1x(x)*dtn/real(nx)
                  corr_ms_x(2,i) = corr_ms_x(2,i) + 
     &                 corrval2x(x)*dtn/real(nx)
                  corr_ms_x(3,i) = corr_ms_x(3,i) + 
     &                 corrval1x(x)**2*dtn/real(nx)
                  corr_ms_x(4,i) = corr_ms_x(4,i) + 
     &                 corrval2x(x)**2*dtn/real(nx)
               end do
c     
c     Transform to Fourier space
c     
               call vrfftf(corrval1x(1),corrval1x(2),cw_x(1),cw_x(2),
     &              nx,1,2,1,corrwsave_x)
               call vrfftf(corrval2x(1),corrval2x(2),cw_x(1),cw_x(2),
     &              nx,1,2,1,corrwsave_x)
c     
c     Compute correlation in Fourier space and rescale
c     
               do x=1,nx+2,2
                  dr = corrval1x(x  )*corrval2x(x  )+
     &                 corrval1x(x+1)*corrval2x(x+1)
                  corrval1x(x+1)=corrval1x(x+1)*corrval2x(x  )-
     &                 corrval1x(x  )*corrval2x(x+1)
                  corrval1x(x) = dr
               end do
               do x=1,nx+2
                  corr_x(x,i)=corr_x(x,i)+corrval1x(x)*dtn/
     &                 real(nx)/real(nx)
               end do

               end do
               end if
            end if

         end do  
      end if






c
c     ******************************************************************
c     **                                                              **
c     **           TIME  SERIES                                       **
c     **                                                              **
c     ******************************************************************
c
c     Time series of given quantity at fixed (x,y,z) location
c
c     Types:   1  u
c              2  v
c              3  w
c              4  p
c              5  du/dx
c              6  dv/dx
c              7  dw/dx
c              8  du/dy
c              9  dv/dy
c             10  dw/dy
c             11  du/dz
c             12  dv/dz
c             13  dw/dz
c             14  scalar1
c             15  d scalar1/dx
c             16  d scalar1/dy
c             17  d scalar1/dz
c             18  scalar2
c             19  d scalar2/dx
c             20  d scalar2/dy
c             21  d scalar2/dz
c            ....
c             13+4*scalar   d scalarN/dz
c
      if (serf) then   
 
c
c     Save time
c
         series(sercount,0) = tc
c
c     Loop over all series and determine if we are in correct plane
c
         do i=1,nser
            if ((yb.le.serci(2,i)).and.((yb+npl-1).ge.serci(2,i))) then
               xy=serci(1,i)+(yb+npl-1-serci(2,i))*(nxp/2+1)
               if (my_node_x.eq.(mod(serci(3,i)/memnz,nprocx))) then
                  c=serci(3,i)
                  serci(3,i)=mod(serci(3,i)-1,memnz)+1
                  if (nproc.eq.1) serci(3,i)=c
c
c     Get quantity depending on series type
c
                  if (sert(i).le.3) then
c
c     Velocities u_i
c
                     if (serci(4,i).eq.1) then
                        series(sercount,i)=u2r(xy,serci(3,i),sert(i))
                     else
                        series(sercount,i)=u2i(xy,serci(3,i),sert(i))
                     end if 
                  else if (sert(i).eq.4.and.pressure.eq.1) then
c     
c     Pressure p
c
                     if (serci(4,i).eq.1) then
                        series(sercount,i)=h2r(xy,serci(3,i),1)
                     else
                        series(sercount,i)=h2i(xy,serci(3,i),1)
                     end if 
                  else if (sert(i).ge.5.and.sert(i).le.13) then
c     
c     du_i/dx_j
c
                     ii = mod(sert(i)-5,3)+1
                     jj = (sert(i)-5)/3+1
                     if (serci(4,i).eq.1) then
                        series(sercount,i)=
     &                       du2r(xy,serci(3,i),ii,jj)*dstar
                     else
                        series(sercount,i)=
     &                       du2i(xy,serci(3,i),ii,jj)*dstar
                     end if 
                  else if (sert(i).ge.14.and.sert(i)
     &                    .le.13+scalar*4) then
c
c     Scalar, d scalar_j/dx_i
c
                     ii = mod(sert(i)-14,4)+1
                     jj = (sert(i)-14)/4+1
                     c1 = 1.
                     if (ii.gt.1) c1 = dstar
                     if (serci(4,i).eq.1) then
                        series(sercount,i)=th2r(xy,serci(3,i),ii,jj)*c1
                     else
                        series(sercount,i)=th2i(xy,serci(3,i),ii,jj)*c1
                     end if 
                  else
c
c     Nonexisting quantity
c
                     if (my_node_world.eq.0) then
                        write(*,*) 'Time series no. ',i,' refers to'
                        write(*,*) 'a nonexisting quantity ',corrt(i)
                     end if
                     call stopnow(65645)
                  end if
                  serci(3,i)=c
               end if
            end if
         end do
      end if


c
c     ******************************************************************
c     **                                                              **
c     **           TWO-POINT  CORRELATIONS                            **
c     **                                                              **
c     ******************************************************************
c
c     Spanwise two-point correlation at selected (x/y) positions
c
c     Correlation types:   1   uu
c                          2   vv
c                          3   ww
c                          4   pp
c                          5   uv
c                          6   uw
c                          7   up
c                          8   vw
c                          9   vp
c                         10   wp
c                         11   dudy dudy
c                         12   t1t1 
c                         13   t1u
c                         14   t1v
c                         15   t1w
c                         16   t1p
c                         17   dt1dy dt1dy
c                         18   t2t2
c                         19   t2u
c                         ...
c                         12+scalar*6   t1t1
c                         13+scalar*6   t1t2
c                         ...
c                         11+6*scalar+scalar**2 tNtN
c
c
c     OLD types:           1   uu
c                          2   vv
c                          3   ww
c                          4   pp
c                          5   tt
c                          6   uv
c                          7   uw
c                          8   up
c                          9   ut
c                         10   vw
c                         11   vp
c                         12   vt
c                         13   wp
c                         14   wt
c                         15   pt
c
c     

      if (specf) then         
c
c     Coordinate indices are corrxi,corryi (corrxodd)
c
c     Loop over all correlations and determine if we are in correct plane
c


         if (my_node_z.eq.0.and.my_node_x.eq.0) then
            write(ch,'(i5.5)') 0
            open(file='spec.stat'//'-'//ch,
     &           unit=75,form='formatted',
     &           position='append')
            write(75,'(e25.16e3,i5)') tc/dstar,maxtcorr
            close(75)
         end if
         
         do i=1,maxtcorr

            if ((yb.le.corryi(i)).and.((yb+npl-1).ge.corryi(i))) then
c
c     Get quantity depending on correlation type
c
               xy=corrxi(i)+(yb+npl-1-corryi(i))*(nxp/2+1)

               do jj=1,5


c
c     The types are: 
c     1: u2r(xy,z,1)
c     2: u2r(xy,z,2)
c     3: u2r(xy,z,3)
c     4: h2r(xy,z,1)
c     5: du2r(xy,z,1,2)*dstar
c
                  if (jj.eq.1) then
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=u2r(xy,z,1)
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=u2i(xy,z,1)
                        end do
                     end if
                  else if (jj.eq.2) then
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=u2r(xy,z,2)
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=u2i(xy,z,2)
                        end do
                     end if
                  else if (jj.eq.3) then
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=u2r(xy,z,3)
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=u2i(xy,z,3)
                        end do
                     end if
                  else if (jj.eq.4) then
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=h2r(xy,z,1)
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=h2i(xy,z,1)
                        end do
                     end if
                  else if (jj.eq.5) then
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=du2r(xy,z,1,2)*dstar
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=du2i(xy,z,1,2)*dstar
                        end do
                     end if
                  end if


                  yp=mod(yb-1,nprocz)
c     
c     Send the individual statistics to processor 0
c     
#ifdef MPI
                  if (my_node_x.gt.0) then
                     call mpi_send(corrval1(1),memnz,
     &                    mpi_double_precision,
     &                    my_node_world/nprocx*nprocx,
     &                    my_node_world+800,
     &                    mpi_comm_world,ierror)
                  else
                     do j=1,nprocx-1
c     
c     Add correlations of other processors
c     
                        call mpi_recv(corrval1(1+j*memnz),memnz,
     &                       mpi_double_precision,
     &                       j+yp*nprocx,j+yp*nprocx+800,mpi_comm_world,
     &                       status1,ierror)
                     end do
                     
                  end if
#endif
c
c     Postprocess the two-point correlations on master nodes
c
                  if (my_node_x.eq.0) then
                     write(ch,'(i5.5)') my_node_z+1
                     open(file='spec.stat'//'-'//ch,
     &                    unit=75,form='unformatted',
     &                    position='append')
                     
                     write(75) i,jj,corrval1(1:nzc)
                     
                     close(75)
                     
                  end if
               end do
            end if




         end do

      end if
      if (specf_) then


         if (my_node_z.eq.0.and.my_node_x.eq.0) then
            write(ch,'(i5.5)') 0
            open(file='spec_.stat'//'-'//ch,
     &           unit=75,form='formatted',
     &           position='append')
            write(75,'(e25.16e3,i5)') tc/dstar,maxtcorr
            close(75)
         end if
         
         do i=1,maxtcorr

            if ((yb.le.corryi(i)).and.((yb+npl-1).ge.corryi(i))) then
c
c     Get quantity depending on correlation type
c
               xy=(corrxi(i)+2)+(yb+npl-1-corryi(i))*(nxp/2+1)

               do jj=1,5


c
c     The types are: 
c     1: u2r(xy,z,1)
c     2: u2r(xy,z,2)
c     3: u2r(xy,z,3)
c     4: h2r(xy,z,1)
c     5: du2r(xy,z,1,2)*dstar
c
                  if (jj.eq.1) then
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=u2r(xy,z,1)
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=u2i(xy,z,1)
                        end do
                     end if
                  else if (jj.eq.2) then
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=u2r(xy,z,2)
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=u2i(xy,z,2)
                        end do
                     end if
                  else if (jj.eq.3) then
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=u2r(xy,z,3)
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=u2i(xy,z,3)
                        end do
                     end if
                  else if (jj.eq.4) then
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=h2r(xy,z,1)
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=h2i(xy,z,1)
                        end do
                     end if
                  else if (jj.eq.5) then
                     if (corrxodd(i).eq.1) then
                        do z=1,memnz
                           corrval1(z)=du2r(xy,z,1,2)*dstar
                        end do
                     else
                        do z=1,memnz
                           corrval1(z)=du2i(xy,z,1,2)*dstar
                        end do
                     end if
                  end if


                  yp=mod(yb-1,nprocz)
c     
c     Send the individual statistics to processor 0
c     
#ifdef MPI
                  if (my_node_x.gt.0) then
                     call mpi_send(corrval1(1),memnz,
     &                    mpi_double_precision,
     &                    my_node_world/nprocx*nprocx,
     &                    my_node_world+800,
     &                    mpi_comm_world,ierror)
                  else
                     do j=1,nprocx-1
c     
c     Add correlations of other processors
c     
                        call mpi_recv(corrval1(1+j*memnz),memnz,
     &                       mpi_double_precision,
     &                       j+yp*nprocx,j+yp*nprocx+800,mpi_comm_world,
     &                       status1,ierror)
                     end do
                     
                  end if
#endif
c
c     Postprocess the two-point correlations on master nodes
c
                  if (my_node_x.eq.0) then
                     write(ch,'(i5.5)') my_node_z+1
                     open(file='spec_.stat'//'-'//ch,
     &                    unit=75,form='unformatted',
     &                    position='append')
                     
                     write(75) i,jj,corrval1(1:nzc)
                     
                     close(75)
                     
                  end if
               end do
            end if




         end do


      end if
      




      end subroutine boxxys
