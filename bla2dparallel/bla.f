c ***********************************************************************
c
c $HeadURL: https://www.mech.kth.se/svn/simson/branches/bla2dparallel/bla.f $
c $LastChangedDate: 2013-04-19 22:31:50 +0200 (Fri, 19 Apr 2013) $
c $LastChangedBy: pschlatt@MECH.KTH.SE $
c $LastChangedRevision: 1822 $
c
c ***********************************************************************
      program bla


      implicit none

      include 'par.f'
#ifdef MPI
      include 'mpif.h'
#endif
c     
c     Flags to turn on/off certain features
c
      integer,parameter :: iiles = 0
      integer,parameter :: iiles_smag = iiles*0

      integer,parameter :: iimhd = 0

      integer,parameter :: iisfd  = 0 

      integer,parameter :: iiwall = 1
      integer,parameter :: iibase = 0
      integer,parameter :: iilen  = 0
      integer,parameter :: iiwave = 0
      integer,parameter :: iipert = 0
      integer,parameter :: iibf3 = 0

      integer,parameter :: nsave = 5000
      integer,parameter :: mpl   = 0
      integer,parameter :: nwave = 0


      integer,parameter :: iadjoint=0

c
c     Main storage (distributed in z among the processors)
c
      real ur(memnx,memny,memnz,memnxyz),ui(memnx,memny,memnz,memnxyz)
c
c     In case of memory related problems, the following lines
c     can be tried out:
c      common /MAIN/ ur,ui
c
c      static ur,ui
c
c      real,allocatable :: ur(:,:,:,:),ui(:,:,:,:)
c      allocate(ur(memnx,memny,memnz,memnxyz)
c      allocate(ui(memnx,memny,memnz,memnxyz)
c
c
c     Step 2 storage (nonlinbl)
c
      real u2r ((nxp/2+1)*mby*nzd_new/nprocz*3       ,nthread)
      real u2i ((nxp/2+1)*mby*nzd_new/nprocz*3       ,nthread)
      real om2r((nxp/2+1)*mby*nzd_new/nprocz*3       ,nthread)
      real om2i((nxp/2+1)*mby*nzd_new/nprocz*3       ,nthread)
      real wr  ((nxp/2+1)*mby*nzd_new/nprocz         ,nthread)
      real wi  ((nxp/2+1)*mby*nzd_new/nprocz         ,nthread)
      real du2r((nxp/2+1)*mby,nzd_new/nprocz,3,3     ,nthread)
      real du2i((nxp/2+1)*mby,nzd_new/nprocz,3,3     ,nthread)
      real th2r((nxp/2+1)*mby*nzd_new/nprocz*4*scalar,nthread)
      real th2i((nxp/2+1)*mby*nzd_new/nprocz*4*scalar,nthread)
c
c     Step 3 storage (linearbl,prhs)
c
      real u3r   (memnx*mbz*nyp*3,nthread)
      real u3i   (memnx*mbz*nyp*3,nthread)
      real om3r  (memnx*mbz*nyp*3,nthread)
      real om3i  (memnx*mbz*nyp*3,nthread)
      real h3r   (memnx*mbz*nyp*3,nthread)
      real h3i   (memnx*mbz*nyp*3,nthread)
      real domyr (memnx*mbz*nyp  ,nthread)
      real domyi (memnx*mbz*nyp  ,nthread)
      real domyh (memnx*mbz*nyp  ,nthread)
      real omyh  (memnx*mbz*nyp  ,nthread)
      real homyr (memnx*mbz*nyp  ,nthread)
      real homyi (memnx*mbz*nyp  ,nthread)
      real dvr   (memnx*mbz*nyp  ,nthread)
      real dvi   (memnx*mbz*nyp  ,nthread)
      real dvh   (memnx*mbz*nyp  ,nthread)
      real dvh2  (memnx*mbz*nyp  ,nthread)
      real vr    (memnx*mbz*nyp  ,nthread)
      real vi    (memnx*mbz*nyp  ,nthread)
      real vh    (memnx*mbz*nyp  ,nthread)
      real vh2   (memnx*mbz*nyp  ,nthread)
      real hvr   (memnx*mbz*nyp  ,nthread)
      real hvi   (memnx*mbz*nyp  ,nthread)
      real w3    (memnx*mbz*nyp  ,nthread)
      real d2omyh(memnx*mbz*nyp  ,nthread)
      real th3r  (memnx*mbz*nyp*scalar,nthread)
      real th3i  (memnx*mbz*nyp*scalar,nthread)
      real hthr  (memnx*mbz*nyp*scalar,nthread)
      real hthi  (memnx*mbz*nyp*scalar,nthread)
      real pthr  (memnx*mbz*nyp*scalar,nthread)
      real pthi  (memnx*mbz*nyp*scalar,nthread)
      real dthr  (memnx*mbz*nyp*scalar,nthread)
      real dthi  (memnx*mbz*nyp*scalar,nthread)
      real c     (memnx*mbz*ny    ,nthread)
      real d     (memnx*mbz*ny    ,nthread)  
      real e     (memnx*mbz*ny    ,nthread)
      real q     (memnx*mbz*(ny+2),nthread)
      real puw   (ny,2+scalar)
c
c     Step 3 collection variables
c
      real f  (memnx*mbz*nyp,5+2*scalar,nthread)
      real bis(memnx*mbz*nyp,6+2*scalar,nthread)
      real d2v(memnx*mbz*nyp,4         ,nthread)
c
c     Variables for tbc>0
c
      real fth_bc   (memnx*mbz*nyp*2*scalar,nthread)
      real d2th_bc  (memnx*mbz*nyp*4*scalar,nthread)   
      real dth3r_bc (memnx*mbz*nyp  *scalar,nthread)
      real dth3i_bc (memnx*mbz*nyp  *scalar,nthread)
      real dth3r_bc2(memnx*mbz*nyp  *scalar,nthread)
      real dth3i_bc2(memnx*mbz*nyp  *scalar,nthread)
c
c     Partial right-hand sides (prhs)
c
      real pomyr (memnx,mbz,nyp),pomyi (memnx,mbz,nyp)
      real pvr   (memnx,mbz,nyp),pvi   (memnx,mbz,nyp)
c
c     Temporary storage
c
      real boxr  (memnx,mbz,nyp),boxi  (memnx,mbz,nyp)
c
c     Pressure
c     
      real h2r((nxp/2+1)*mby*nzd_new/nprocz*3*pressure,nthread)
      real h2i((nxp/2+1)*mby*nzd_new/nprocz*3*pressure,nthread)
c
c     Comment out the next 6 variables if running without pressure b.c.
c
      real rv1r(nx/2,nzc,2*pressure)
      real rv1i(nx/2,nzc,2*pressure)
      real aaar(nxp/2+1,nzd_new,2)
      real aaai(nxp/2+1,nzd_new,2)
      real tempr((nxp/2+1)*mby,nzd_new/nprocz,2)
      real tempi((nxp/2+1)*mby,nzd_new/nprocz,2)
c
c     Time stepping parameters
c
      logical vart
      real t,tc,tmax,tleft,dtmax,dtn,dtnp1
      real an,bn,anp1,bnp1,cnp1,anrk(4,2),bnrk(4,2),cnrk(4,2)
      integer it,maxit,nst
      integer rksubstep
      integer stop_now
c
c     Numerics
c
      logical icorr,cim
c
c     File communication
c
      logical write_inter
      logical varsiz
      character*80 namnin,namnut,nmsave(nsave)
      character*80 namnut_inter,namnut_sfd
      real tsave(nsave)
      integer isave
      real urx(nx)
c
c     Runtime plane saving
c
      real wxy(nx,nyp),wyz(nyp,nz)
      real plxy(nx,nyp/nproc+1)
      character*80 nampl(mpl)
      integer ipl,npl,tpl(mpl,3)
      real cpl(mpl)
      integer wplblodd(mpl)
c
c     Runtime statistics
c
      logical do_stat,do_press,do_press_nl
      logical longli,fileurms
      integer icfl,iamp,mwave,ixys,ixyss
      character*80 namamp,namwav,namext,namxys
      real cfl,cflmax,cflp(memny),sumw,txys
      integer kx(nwave),kz(nwave)
      real amp(nyp,20)
      complex campw(nyp,4,nwave)
      integer iext
      real vext(nyp,2,6),cext(nyp,2,6,2)
      real xys     (nx,nyp/nprocz+1,nxys)
      real xysth   (nx,nyp/nprocz+1,nxysth,scalar)
c
c     Flow
c
      character*80 namfre,nambfl
      logical spat,gall,tabfre,rbfl
      integer fltype,ibc
      real re,px,rot,cdev,pr(scalar),m1(scalar),retau,thgrad(scalar)
      real mflux
      logical cflux
      real u0low,u0upp,w0low,w0upp,du0upp
      real spanv,rlam
c
c     Disturbance volume force
c
      integer loctyp
      real fp1,fpds1,fpds2,fpds3,fpds4,fpds5,fpds6,fpds7
      real fpds8,fpdds1,fpdds2,fpdds3,fpdds4,fpdds5,fpdds6
c
c     Fringe function
c
      real fmax,fstart,fend,frise,ffall
      real cphas1(osnf,nxp/2,nzd_new/nprocz)
      real cphas2(osnf,nxp/2,nzd_new/nprocz)
      real sphas1(osnf,nxp/2,nzd_new/nprocz)
      real sphas2(osnf,nxp/2,nzd_new/nprocz)
      real fring1(nxp/2),fring2(nxp/2)
      real xc1(nxp/2),xc2(nxp/2)
c
c     Trip forcing
c
      logical tripf
      integer seed,nzt,ntdt
      real tdt,ttzc(nzp+2,4),tamps,tampt,tysc,txsc,tx0
c
c     Blowing and suction
c
      integer wbci
      real wp1,wp2
      real wpds1,wpds2,wpds3,wpds4,wpds5
      real wpds6,wpds7,wpds8,wpds9,wpds10,wpds11,wpds12
      real wpdds1,wpdds2
      real wallvr(nxp/2+1,nzd*iiwall),wallvi(nxp/2+1,nzd*iiwall)
      real jetwr(nxp/2+1,nzd*iiwall),jetwi(nxp/2+1,nzd*iiwall)

c
c     Boundary conditions for scalar fiels
c
      integer tbc(scalar)
      real dtheta0_upp(scalar),dtheta0_low(scalar)
      real theta0_low(scalar),theta0_upp(scalar)
      real wallthr(nxp/2+1,nzd*iiwall, scalar)
      real wallthi(nxp/2+1,nzd*iiwall, scalar)
c
c     Wall roughness (wbci==-1)
c
      integer nxm,nxn,nzn,lenx
      parameter(nxm=nxp/2+1,nxn=nx/2+1,nzn=nz/2+1)
      parameter (lenx=nx/8)
      integer every,zfunc,hst,hen,hlen
      real delh,h_rough,hstart,hend,hrise,hfall,joker,qq,psi,tpsi,switch
      real wallur(nxm,memnz*iiwall),wallui(nxm,memnz*iiwall)
      real wlvr(nxm,memnz*iiwall),wlvi(nxm,memnz*iiwall)
      real wallwr(nxm,memnz*iiwall),wallwi(nxm,memnz*iiwall)
      character*80 wallroughinput,monfile,roughfile
      logical updat,v_wall,taylor4,rghfil,monitor
c
c     Jet in CrossFlow (wbci==-2)
c
      real jet_diam,xjet,zjet,jetmag
      integer jet_prof
c
c     Wave generation
c
      real evr(nyp),evi(nyp),eur(nyp),eui(nyp),ewr(nyp),ewi(nyp)
      real afw,alfaw,betaw,ampob,amp2d
      real ev2r(nyp),ev2i(nyp),eu2r(nyp),eu2i(nyp),afw2d,alf2d
c
c     Orr-Sommerfeld modes
c
      logical osmod,osdamp
      real osamp
      integer osn,osnumb
      real osymax,osbeta(osnf), osre, osomega(osnf)
      real osalr(osnf), osali(osnf)
      real osur(osnf,nyp), osvr(osnf,nyp), oswr(osnf,nyp)
      real osui(osnf,nyp), osvi(osnf,nyp), oswi(osnf,nyp)
      character*80 osfil
c
c     Asymptotic suction layer
c
      logical suction,asbl
      real vsuc
c
c     Streak generation
c
      logical streak
      character*80 str_nam1,str_nam2
      real iampst,ampst(2),tsmoo(4),tsmst(2),tsmend(2)
      real betast(2),omegast(2),phist
      real uust_r(nyp,180,2*iiwave),vvst_r(nyp,180,2*iiwave)
      real wwst_r(nyp,180,2*iiwave)
      real uust_i(nyp,180,2*iiwave),vvst_i(nyp,180,2*iiwave)
      real wwst_i(nyp,180,2*iiwave)
      integer ndxst
c
c     Wave in fringe generation parameters
c
      logical waves
      real waamp,wamoo,wamst,waiamp
      real omega
      real ucwa(nyp,180*iiwave),uswa(nyp,180*iiwave)
      real vcwa(nyp,180*iiwave),vswa(nyp,180*iiwave) 
      integer ndxwa
c
c     Box extension
c
      real xlold
      integer nxtmp
c
c     Geometrics
c
      real alfa(nx/2,mbz),beta(nz)
      real eta(nyp),deta(nyp),wint(nyp),wd1(nyp,4),xl,zl
      real gridx(nx),gridy(nyp),gridz(nz)
      real deltaxyz2(nyp)
      real zs,zsc,xs,xsc,xs0
      real x0,dstar,dstar2,xblc,xbl
c
c     Base flow
c
      integer nbla
      real dybla
      real fbla(mbla,7+3*scalar)
      real wbr(nxp/2+1,nyp),wbi(nxp/2+1,nyp)
      real bstart,bslope
c
c     Base flow and derivatives
c
      real bu1(nxp/2+1,nyp,3+scalar),bu2(nxp/2+1,nyp,3+scalar)
      real bu3(nxp/2+1,nyp*iipert,3+scalar)
      real bu4(nxp/2+1,nyp*iipert,3+scalar)
      real bu1jr(nxp/2+1,3+scalar,3),bu1ji(nxp/2+1,3+scalar,3)
c
c     Fixed base flow and derivatives for blshift, blfou
c
      real bu1f(nxp/2+1,nyp*iibase,3+scalar)
      real bu2f(nxp/2+1,nyp*iibase,3+scalar)
      real bu1jr0(nxp/2+1,3+scalar,3*iibase)
      real bu1ji0(nxp/2+1,3+scalar,3*iibase)
c
c     Base flow for lenbox
c
      real bucorr(nxp,nyp,3*iilen)
      real pxz(nxp+2,nzd*iilen),wxz(nxp+2,nzd)
c
c     FFT preprocessing data
c
      real prex(nxp+15),prey(nyp*2+15)
      real prez(nzp*2+15),pres(nzst*2+15),prea(nzat*3/2+15)
      real prexn(nx+15),prezn(nz*2+15),presn(nz+2+15),prean(nz*3/4+15)
      real prezr(nzp+15)
c
c     Two-point correlation
c
      character*80 corrnam,corrnam_x
      real corrx(mcorr), corry(mcorr)
      real corrz(mcorr), corry_x(mcorr)
      integer corrt(mcorr),corrt_x(mcorr)
      real corrxx(mcorr),corryy(mcorr)
      real corrzz(mcorr),corryy_x(mcorr)
      real corr(nzc+2,mcorr),corr_x(nx+2,mcorr)
      real totcorr(nzc+2),totcorr_x(nx+2)
      real corr_ms(4,mcorr),totcorr_ms(4),totcorr_ms_x(4)
      real corr_ms_x(4,mcorr)
      integer corrxi(mcorr),corrxodd(mcorr),corryi(mcorr)
      integer corrzi(mcorr),corryi_x(mcorr)
      logical corrf,corrf_x
      integer ncorr,ncorr_x
      real corrwsave(nzc+15)
      real corrwsave_x(nx+15)
c
c     Time series
c
      real series(msamp,0:mser),totseries(msamp,0:mser)
      character(len=80) namser
      real serc(3,mser)
      real sercc(3,mser)
      integer serci(4,mser)
      integer sert(mser)
      logical serf
      integer nser,sercount,nsamp
c
c     Constant
c
      real pi
      parameter (pi = 3.1415926535897932385)
c
c     Loop indices, pointers
c
      integer yb,zb,myb,i,j
c
c     Indices for parallelization
c
      integer ybp,zbp,ip
c
c     Timing
c
      character*20 sttimec,timdat
      real sttimet,delta_wall_time
      real,parameter :: delta_wall_time_int = 10.
      integer kode
      ! Start time
      real wtime0,ctime0
      ! Timings for one time step
      real wtime1,ctime1
      real wtime2,ctime2
      ! Partial timing
      real wtime3,ctime3
      real wtime4,ctime4
      ! Different timings
      real wtime_stat,ctime_stat
      real wtime_nonlin,ctime_nonlin
      real wtime_linear,ctime_linear
      real wtime_io,ctime_io
      real wtime_adj,ctime_adj
      real wtime_les,ctime_les
      real wtime_tau,ctime_tau
      real wtime_startup,ctime_startup
      real wtime_end,ctime_end
      real wtime_rest,ctime_rest
      real wtime_trip,ctime_trip
      real wtime_ffun,ctime_ffun
      real wtime_cfl,ctime_cfl
      real wtime_planes,ctime_planes
      real wtime_press,ctime_press
      real cpumax,wallmax
      real tcom,tser
c
c     MHD
c
      real fmhdr(iimhd*memnx*memny*memnz*2)
      real fmhdi(iimhd*memnx*memny*memnz*2)
      real j2r((nxp/2+1)*mby*nzd*4*iimhd,nthread)
      real j2i((nxp/2+1)*mby*nzd*4*iimhd,nthread)
      integer imhd
      real b0(3),mhd_n
c
c     Large-eddy simulation (LES)
c     iiles can be 0 or 1 to determine whether the LES arrays are allocated.
c     iiles_smag (0 or 1) is to allocate arrays for the dynamic procedure.
c
      logical sgs
      ! Filtered velocity field / SGS force
      real gur(iiles*memnx,memny,memnz,5+2*scalar)
      real gui(iiles*memnx,memny,memnz,5+2*scalar)
      real gsr(iiles*memnx,memny,memnz,scalar)
      real gsi(iiles*memnx,memny,memnz,scalar)
      ! SGS stresses for velocity and scalars
      real taur(iiles*iiles_smag*memnx,memny,memnz,(6+3*scalar))
      real taui(iiles*iiles_smag*memnx,memny,memnz,(6+3*scalar))
      ! Temporary fields
      real gu3r  (iiles*memnx*mbz*nyp  ,nthread)
      real gu3i  (iiles*memnx*mbz*nyp  ,nthread)
      real ggu3r (iiles*memnx*mbz*nyp  ,nthread)
      real ggu3i (iiles*memnx*mbz*nyp  ,nthread)
      real gth3r (iiles*memnx*mbz*nyp  ,nthread)
      real gth3i (iiles*memnx*mbz*nyp  ,nthread)
      real ggth3r(iiles*memnx*mbz*nyp  ,nthread)
      real ggth3i(iiles*memnx*mbz*nyp  ,nthread)
      real gplane(iiles*memnx*mbz*nyp  ,nthread)
      real tau3r (iiles*memnx*mbz*nyp*6,nthread)
      real tau3i (iiles*memnx*mbz*nyp*6,nthread)
      real tau2r (iiles*(nxp/2+1)*mby*nzd_new/nprocz*6,nthread)
      real tau2i (iiles*(nxp/2+1)*mby*nzd_new/nprocz*6,nthread)
      real s2r   (iiles*(nxp/2+1)*mby*nzd_new/nprocz*6,nthread)
      real s2i   (iiles*(nxp/2+1)*mby*nzd_new/nprocz*6,nthread)
      real l2r   (iiles*(nxp/2+1)*mby*nzd_new/nprocz*6,nthread)
      real l2i   (iiles*(nxp/2+1)*mby*nzd_new/nprocz*6,nthread)
      real ls2r   (iiles*(nxp/2+1)*mby*nzd_new/nprocz*3*scalar,nthread)
      real ls2i   (iiles*(nxp/2+1)*mby*nzd_new/nprocz*3*scalar,nthread)
      real m2r   (iiles*(nxp/2+1)*mby*nzd_new/nprocz*6,nthread)
      real m2i   (iiles*(nxp/2+1)*mby*nzd_new/nprocz*6,nthread)
      real b2r   (iiles*(nxp/2+1)*mby*nzd_new/nprocz*6,nthread)
      real b2i   (iiles*(nxp/2+1)*mby*nzd_new/nprocz*6,nthread)
      real gu2r  (iiles*(nxp/2+1)*mby*nzd_new/nprocz*3,nthread)
      real gu2i  (iiles*(nxp/2+1)*mby*nzd_new/nprocz*3,nthread)
      real gom2r (iiles*(nxp/2+1)*mby*nzd_new/nprocz*3,nthread)
      real gom2i (iiles*(nxp/2+1)*mby*nzd_new/nprocz*3,nthread)
      real gdu2r (iiles*(nxp/2+1)*mby*nzd_new/nprocz*9,nthread)
      real gdu2i (iiles*(nxp/2+1)*mby*nzd_new/nprocz*9,nthread)      
      real sabsr (iiles*(nxp/2+1)*mby*nzd_new/nprocz,nthread)
      real sabsi (iiles*(nxp/2+1)*mby*nzd_new/nprocz,nthread)
      real cr    (iiles*(nxp/2+1)*mby*nzd_new/nprocz,nthread)
      real ci    (iiles*(nxp/2+1)*mby*nzd_new/nprocz,nthread)
      real glr   (iiles*memnx*mby*nzd_new*6)
      real gli   (iiles*memnx*mby*nzd_new*6)
      real glsr  (iiles*memnx*mby*nzd_new*3*scalar)
      real glsi  (iiles*memnx*mby*nzd_new*3*scalar)
      real sdr   (iiles*(nxp/2+1)*mby*nzd_new/nprocz,nthread)
      real sdi   (iiles*(nxp/2+1)*mby*nzd_new/nprocz,nthread)
      ! Filter 
      real gewy1(nyp,5),gewy2(nyp,5)
      real gewspecx(nx/2+2)
      real gewspecz(nz/2+2)
      real diags(nyp,5)
      real filtxz(iiles*memnx,nz)
      real lpfxz(iiles*memnx,nz)
      ! Secondary highpass filter
      real gewy12(nyp,5),gewy22(nyp,5)
      real diags2(nyp,5)
      real filtxz2(iiles*memnx,nz)
      real lpfxz2(iiles*memnx,nz)
      integer iord,ihighorder
      real cutoff
      ! Diverse
      integer iles,ineg
      real chi,chi_scaled,cs,prt
c
c     Selective frequency damping (SFD)
c     
      integer isfd
      logical sfdzero
      real sfd_chi,sfd_delta
      real sfdur(memnx,memny,memnz,iisfd*6)
      real sfdui(memnx,memny,memnz,iisfd*6)
c
c     Perturbation equations and linearised version
c
      logical lin,pert
      real bom1(nxp/2+1,nyp*iipert,3+2*scalar)
      real bom2(nxp/2+1,nyp*iipert,3+2*scalar)
      real bom3(nxp/2+1,nyp*iipert,3)
      real bom4(nxp/2+1,nyp*iipert,3)
      real appr((nxp/2+1)*iipert),appi((nxp/2+1)*iipert)
      real app2r((nxp/2+1)*iipert),app2i((nxp/2+1)*iipert)
      real wlin(nxp/2+1,nyp*iipert)
c
c     3D base flow
c
      logical bf3
      character*80 bf3nam
      real bf3ur(memnx,memny,memnz,6*iibf3)
      real bf3ui(memnx,memny,memnz,6*iibf3)
      real bf3u2r((nxp/2+1)*mby,nzd_new/nprocz,nyp/nprocz+1,6*iibf3)
      real bf3u2i((nxp/2+1)*mby,nzd_new/nprocz,nyp/nprocz+1,6*iibf3)
      real bf3tempr(nxp/2+1,nzd,3*iibf3)
      real bf3tempi(nxp/2+1,nzd,3*iibf3)


c
c     THE REST IS TO BE IMPLEMENTED!!!
c

c
c     Arnoldi
c
      character*80 arnoldi_namnin,arnoldi_namnut
      real arnoldi_tend, arnoldi_dt
      integer arnoldi
c
c     OpenMP
c
      integer ompnproc,ompnthreads,ompmaxthreads
#ifdef OPENMP
      integer omp_get_num_procs, omp_get_num_threads
      integer omp_get_thread_num, omp_get_max_threads
#endif
c
c     MPI
c
      integer all_nodes_world,my_node_world,all_nodes_x,all_nodes_z
      integer all_nodes,my_node_z,my_node_x,my_comm_z,my_comm_x
      integer realg1,realg2,realg3,realg4,realg5,realg6
      integer nypp
#ifdef MPI
      integer realg1_vec,realg2_vec,realg3_vec,realg4_vec
      integer realg5_vec,realg6_vec
      integer block_lengths(2),displacements(2),types(2)
      integer(kind=mpi_address_kind) displacements2(2)

      integer group_world,my_group_z,my_group_x,rank(3),d1,d2

      integer my_procs, my_threads
      character(len=mpi_max_processor_name) my_name
      character(len=mpi_max_processor_name) all_names(nproc)
      integer all_threads(nproc),all_procs(nproc)
      integer ierror
      integer x,y,z
c     For MPI-2
c      integer irequired,iprovided

#endif

c
c     Adjoint variables
c
      real fur(memnx,memny,memnz,3*iadjoint)
      real fui(memnx,memny,memnz,3*iadjoint)
      real fur_t(memnx,memny,memnz,3*iadjoint)
      real fui_t(memnx,memny,memnz,3*iadjoint)
      real fur_t_i(memnx,memny,memnz,3*iadjoint)
      real fui_t_i(memnx,memny,memnz,3*iadjoint)
      real fur_n(memnx,memny,memnz,3*iadjoint)
      real fui_n(memnx,memny,memnz,3*iadjoint)
      real fur_n_i(memnx,memny,memnz,3*iadjoint)
      real fui_n_i(memnx,memny,memnz,3*iadjoint)
      real fur1(memnx,memny,memnz,3*iadjoint)
      real fui1(memnx,memny,memnz,3*iadjoint)
      real fur2(memnx,memny,memnz,3*iadjoint) 
      real fui2(memnx,memny,memnz,3*iadjoint)
      real fu2r ((nxp/2+1)*mby*nzd*3       ,nthread*iadjoint)
      real fu2i ((nxp/2+1)*mby*nzd*3       ,nthread*iadjoint)
      real ur_t(memnx,memny,memnz,memnxyz*iadjoint)
      real ui_t(memnx,memny,memnz,memnxyz*iadjoint)
c      real frwrdsol(memnx,memny,memnz,3*iadjoint,2,maxfnum)
      logical adjoint,file_save,sav_fr_fou,sensit
      logical optim_force,use_scratch,meas_ener
      logical loc_f_x,loc_f_z,loc_forc_xzt
      real x0loc,xend,rise_loc_x,fall_loc_x
      real z0loc,zend,rise_loc_z,fall_loc_z
      real gauss_x,gauss_x0,gauss_z,gauss_t
      real period,fact_t
c      real  kenergy,t_1,t_2,te1,te2,freq,tim
c      real kenergy_t(maxfnum),meank,savtime
      integer iter,ffr,maxitof,itime,Nper
      integer ix,iy,iz
c
c     Adjoint storage
c
      real u2xr((nxp/2+1)*mby*nzd*3*iadjoint       ,nthread)
      real u2xi((nxp/2+1)*mby*nzd*3*iadjoint       ,nthread)
      real u2zr((nxp/2+1)*mby*nzd*3*iadjoint       ,nthread)
      real u2zi((nxp/2+1)*mby*nzd*3*iadjoint       ,nthread)
c
c     Adoint base flow gradients
c
      real bfgrad1(nxp/2+1,nyp,3*iadjoint,2) 
      real bfgrad2(nxp/2+1,nyp,3*iadjoint,2)
c
c     Adjoint file communication
c
      integer file_num
      character*80 nmsave_1(nsave)
      real tsave_1(nsave)
      character*80 nmfor_t,nmfor_1,nmfor_2,zer1,zer2,zer3,zer4
c      character*80 name_list(maxfnum),name_list_out(maxfnum)
c      real time_list(maxfnum),time_list_out(maxfnum) 
      character*80 enerfile,nm_frc_rsp,namfou
      character*80 loc_frc_rsp
      integer msave

c
c     Various arrays needed for the 2D parallelization
c
      real boxr_z(memnx,nzd_new,6)
      real boxi_z(memnx,nzd_new,6)
      real boxrz_z(memnx,nzd_new,6*iadjoint)
      real boxiz_z(memnx,nzd_new,6*iadjoint)
      real boxrx_z(memnx,nzd_new,6*iadjoint)
      real boxix_z(memnx,nzd_new,6*iadjoint)
      real boxrs_z(memnx,nzd_new,6*iadjoint)
      real boxis_z(memnx,nzd_new,6*iadjoint)

      real dboxr_z(memnx,nzd_new,3,3)
      real dboxi_z(memnx,nzd_new,3,3)
      real boxrr(memnx,nzd_new,4*scalar+3*pressure)
      real boxii(memnx,nzd_new,4*scalar+3*pressure)

      real wr_z(memnx,nzd_new)
      real wi_z(memnx,nzd_new)
      real wr_x(nxp/2+1,nzd_new/nprocz)
      real wi_x(nxp/2+1,nzd_new/nprocz)

      real gboxr_z(iiles*memnx*nzd_new*6)
      real gboxi_z(iiles*memnx*nzd_new*6)
      real gboxr(iiles*memnx*nzd_new*4*scalar)
      real gboxi(iiles*memnx*nzd_new*4*scalar)
      real gdboxr_z(iiles*memnx*nzd_new*9)
      real gdboxi_z(iiles*memnx*nzd_new*9)



c-----------------------------------
c
c     Equivalence statements
c     **   mbox2 = (nxp/2+1)*nzd*mby*nthread
c     **   mbox3 = nx/2*nyp*mbz*nthread
c
c     These statements alias the work arrays in steps 2 and 3
c     onto each other. Therefore, a substantial memory saving
c     can be achieved. 
c     The equivalence statementes can savely be commented out
c     if not needed (or unsure).
c
c     remaining big variables: plxy,wxy,wyz,wbr,wbi
c
c-----------------------------------
#ifdef MEMORY_SAVE
      real alloc2(mbox2,32+8*scalar+6*pressure)
      real alloc3(mbox3,47+21*scalar)

      equivalence (alloc2,alloc3)
      equivalence (alloc2(1,1),u2r)
      equivalence (alloc2(1,4),u2i)
      equivalence (alloc2(1,7),om2r)
      equivalence (alloc2(1,10),om2i)
      equivalence (alloc2(1,13),wr)
      equivalence (alloc2(1,14),wi)
      equivalence (alloc2(1,15),du2r)
      equivalence (alloc2(1,24),du2i)
      equivalence (alloc2(1,33),th2r)
      equivalence (alloc2(1,33+4*scalar),th2i)
      equivalence (alloc2(1,33+8*scalar),h2r)
      equivalence (alloc2(1,33+8*scalar+3*pressure),h2i)
    
      equivalence (alloc3(1,1),u3r,h3r)
      equivalence (alloc3(1,4),u3i,h3i)
      equivalence (alloc3(1,7),om3r)
      equivalence (alloc3(1,10),om3i)
      equivalence (alloc3(1,13),domyr,pomyr)
      equivalence (alloc3(1,14),domyi,pomyi)
      equivalence (alloc3(1,15),domyh,pvr)
      equivalence (alloc3(1,16),omyh,pvi)
      equivalence (alloc3(1,17),homyr,boxr)
      equivalence (alloc3(1,18),homyi,boxi)
      equivalence (alloc3(1,19),dvr)
      equivalence (alloc3(1,20),dvi)
      equivalence (alloc3(1,21),dvh)
      equivalence (alloc3(1,22),dvh2)
      equivalence (alloc3(1,23),vr)
      equivalence (alloc3(1,24),vi)
      equivalence (alloc3(1,25),hvr)
      equivalence (alloc3(1,26),hvi)
      equivalence (alloc3(1,27),w3)
      equivalence (alloc3(1,28),d2omyh)
      equivalence (alloc3(1,29),d2v)
      equivalence (alloc3(1,33),f)
      equivalence (alloc3(1,38+2*scalar),bis)
      equivalence (alloc3(1,44+4*scalar),th3r)
      equivalence (alloc3(1,44+5*scalar),th3i)
      equivalence (alloc3(1,44+6*scalar),hthr)
      equivalence (alloc3(1,44+7*scalar),hthi)
      equivalence (alloc3(1,44+8*scalar),pthr)
      equivalence (alloc3(1,44+9*scalar),pthi)
      equivalence (alloc3(1,44+10*scalar),dthr)
      equivalence (alloc3(1,44+11*scalar),dthi)
      equivalence (alloc3(1,44+12*scalar),c)
      equivalence (alloc3(1,45+12*scalar),d)
      equivalence (alloc3(1,46+12*scalar),e)
      equivalence (alloc3(1,47+12*scalar),fth_bc)
      equivalence (alloc3(1,47+14*scalar),d2th_bc)
      equivalence (alloc3(1,47+18*scalar),dth3r_bc)
      equivalence (alloc3(1,47+19*scalar),dth3i_bc)
      equivalence (alloc3(1,47+20*scalar),dth3r_bc2)
      equivalence (alloc3(1,47+21*scalar),dth3i_bc2)
#endif

#ifdef MPI
c     test dummy variables for debugging...
      integer ii, iii, zb_t
      integer status1(mpi_status_size),status2(mpi_status_size)
      real urtemp(memnx),uitemp(memnx)
c      common /fields/ ur,ui,u2r,u2i,h2r,h2i
#endif

c-----------------------------------------------------------------------
c     BEGIN OF PROGRAM
c-----------------------------------------------------------------------


      
#ifdef MPI
c
c     Startup MPI
c
      call mpi_init(ierror)
c
c     Create the global group and communicator
c
      call mpi_comm_group(mpi_comm_world,group_world,ierror)
      call mpi_group_rank(group_world,my_node_world,ierror)
      call mpi_group_size(group_world,all_nodes_world,ierror)
c      write(*,*) 'started MPI',my_node_world
#endif


c
c     Initialise timers
c
      call time_string(sttimec)
      call ctim(ctime0,wtime0)
      ctime3=ctime0
      wtime3=wtime0
c
c     Initialise array d2v
c
      d2v = 0.

#ifdef MPI
c
c     For MPI-2
c      irequired = MP_THREAD_MULTIPLE
c      call mpi_init_thread(irequired,iprovided,ierror)
c      write(*,*) irequired,iprovided
c      stop

c
c     MPI environment
c
      call mpi_findout(mpi_comm_world,all_names,my_name, 
     &     all_procs,my_procs,all_threads,my_threads)
#else
c
c     Set MPI variables to serial settings
c
      my_node_world = 0
      my_node_z=0
      my_node_x=0
      all_nodes_world = 1
#endif

      if (my_node_world.eq.0) then
         write(*,*) '********************************************'//
     &              '***********************'
         write(*,*) '*                                           '//
     &              '                      *'
         write(*,*) '*                            Simson 2D      '//
     &              '                      *'
         write(*,*) '*                         bla $Rev: 1822 $   '//
     &              '                      *'
         write(*,*) '*                                           '//
     &              '                      *'
         write(*,*) '********************************************'//
     &              '***********************'

         write(*,*)
         write(*,*)
         write(*,*) '>>>>>>  General information  <<<<<<<'
         write(*,*) '--------------------------------------------'//
     &        '-----------------------'
         write(*,*) 'Started              : ',sttimec

      end if

#ifdef OPENMP
c
c     OpenMP setting
c
      ompnproc=OMP_GET_NUM_PROCS()
c
c     The next line sets the number of threads to the max. number of
c     threads the code is compiled for
c      call OMP_SET_NUM_THREADS(nthread)
c
c     Another possibility is to set it to the number of processors
c     available at the moment
c      call OMP_SET_NUM_THREADS(min(nthread,ompnproc))
c
c     Otherwise the number of threads is determined by the
c     environmental variable OMP_NUM_THREADS (system dependent if not set)

!$omp parallel
      ompnthreads=OMP_GET_NUM_THREADS()
!$omp end parallel
#else
c     
c     Set OpenMP variables to serial settings
c
      ompnproc = 1
      ompnthreads = 1
#endif

c
c     Step 1
c
c
c     Print compile-time parameters
c
      call ppar(my_node_world,all_nodes_world,ompnthreads,ompnproc)

#ifdef MPI
c     
c     Create sub-group and corresponding communicator for FFT in z
c
      j=mod(my_node_world,nprocx)+1
      rank(:)=(/j-1, nprocx*(nprocz-1)+j-1, nprocx/) 
      call mpi_group_range_incl(group_world,1,rank, 
     &     d1,ierror)
      call mpi_comm_create(mpi_comm_world,d1,
     &     d2,ierror)      
      my_group_z = d1
      my_comm_z = d2
      call mpi_group_rank(my_group_z,my_node_z,ierror)
      call mpi_group_size(my_group_z,all_nodes_z,ierror)
c     
c     Create sub-group and corresponding communicator for FFT in x
c     
      j=my_node_world/nprocx+1
      rank(:) = (/(j-1)*nprocx, j*nprocx-1, 1/) 
      call mpi_group_range_incl(group_world,1,rank, 
     &     d1,ierror)
      call mpi_comm_create(mpi_comm_world,d1,
     &     d2,ierror)
      my_group_x = d1
      my_comm_x = d2
      call mpi_group_rank(my_group_x,my_node_x,ierror)
      call mpi_group_size(my_group_x,all_nodes_x,ierror)
c
c     In the following, mpi_type_struct is deprecated and should not
c     be used. However, mpi_type_create_struct is MPI-2 and might not
c     be supported by older MPI libraries. Then just use the mpi_type_struct
c     command instead.
c
c---------------------------- TYPE 1 ------------------
c
      call mpi_type_vector(memnz,memnx,memnx*memny,
     &     mpi_double_precision,realg1_vec,ierror)
      call mpi_type_commit(realg1_vec,ierror)

      block_lengths(1:2) = (/1, 1/)                                           
      displacements(1:2) = (/0, 8*memnx /)
      displacements2(1:2) = (/0, 8*memnx /)
      types(1:2) = (/realg1_vec, MPI_UB/)
c      call mpi_type_struct(2,block_lengths,displacements,types, 
c     &     realg1,ierror)
      call mpi_type_create_struct(2,block_lengths,displacements2,types, 
     &     realg1,ierror)
      call mpi_type_commit(realg1, ierror)      
c
c---------------------------- TYPE 2 ------------------
c
      call mpi_type_vector(memnz,memnx,memnx,
     &     mpi_double_precision,realg2,ierror)
      call mpi_type_commit(realg2,ierror)
c
c---------------------------- TYPE 3 ------------------
c
      call mpi_type_vector(nzd_new/nprocz,memnx,memnx,
     &     mpi_double_precision,realg3,ierror)
      call mpi_type_commit(realg3,ierror)
c
c---------------------------- TYPE 4 ------------------
c
      call mpi_type_vector(nzd_new/nprocz,memnx,nxp/2+1,
     &     mpi_double_precision,realg4_vec,ierror)
      call mpi_type_commit(realg4_vec,ierror)

      block_lengths(1:2) = (/1, 1/)
      displacements(1:2) = (/0, 8*memnx /)
      displacements2(1:2) = (/0, 8*memnx /)
      types(1:2) = (/realg4_vec, MPI_UB/)
c      call mpi_type_struct(2,block_lengths,displacements,types,
c     &     realg4,ierror)
      call mpi_type_create_struct(2,block_lengths,displacements2,types,
     &     realg4,ierror)
      call mpi_type_commit(realg4, ierror)
c
c---------------------------- TYPE 5 ------------------ 
c
      call mpi_type_vector(memnz,memnx,memnx,
     &     mpi_double_precision,realg5,ierror)
      call mpi_type_commit(realg5,ierror)
c
c---------------------------- TYPE 6 ------------------
c
      call mpi_type_vector(memnz,memnx,nxp/2+1,
     &     mpi_double_precision,realg6_vec,ierror)
      call mpi_type_commit(realg6_vec,ierror)

      block_lengths(1:2) = (/1, 1/)
      displacements(1:2) = (/0, 8*memnx /)
      displacements2(1:2) = (/0, 8*memnx /)
      types(1:2) = (/realg6_vec, MPI_UB/)
c      call mpi_type_struct(2,block_lengths,displacements,types,
c     &     realg6,ierror)
      call mpi_type_create_struct(2,block_lengths,displacements2,types,
     &     realg6,ierror)
      call mpi_type_commit(realg6, ierror)
c
c------------------------------------------------------
c
#endif
c
c     Runge-Kutta/CN coefficients
c
      call rkcoeff(anrk,bnrk,cnrk)
c
c     Figure out if we are doing an adjoint simulation
c     (this logical should probably be set in bla.i)
c
      if (iadjoint .gt. 0) then
         adjoint=.true.
      else
         adjoint=.false.
      end if
c
c     Read run-time parameters
c
      call rparambl(namnin,namnut,
     &     tmax,dtn,dtmax,
     &     vart,nst,varsiz,rot,cdev,
     &     loctyp,fp1,fpds1,fpds2,fpds3,fpds4,fpds5,fpds6,fpds7,
     &     fpds8,fpdds1,fpdds2,fpdds3,fpdds4,fpdds5,
     &     wbci,wp1,wp2,
     &     wpds1,wpds2,wpds3,wpds4,wpds5,
     &     wpds6,wpds7,wpds8,wpds9,wpds10,wpds11,wpds12,
     &     wpdds1,wpdds2,wallroughinput,
     &     tripf,tamps,tampt,txsc,tysc,nzt,tdt,seed,tx0,
     &     tsave,nmsave,nsave,cflmax,icfl,iamp,namamp,longli,ibc,cim,
     &     icorr,spat,tabfre,namfre,rbfl,nambfl,gall,
     &     fmax,fstart,fend,frise,ffall,
     &     ampob,amp2d,osmod,osdamp,osamp,osfil,iext,namext,ixys,ixyss,
     &     namxys,txys,maxit,kx,kz,mwave,nwave,namwav,
     &     ipl,nampl,npl,tpl,cpl,mpl,xl,cpumax,wallmax,
     &     corrf,corrf_x,corrnam,corrnam_x,
     &     corrx,corry,corrz,corry_x,corrt,corrt_x,ncorr,ncorr_x,
     &     write_inter,namnut_inter,
     &     my_node_world,suction,asbl,vsuc,
     &     streak,iampst,ampst,tsmoo,tsmst,tsmend,phist,
     &     str_nam1,str_nam2,isfd,sfd_delta,sfd_chi,sfdzero,namnut_sfd,
     &     sgs,waves,waamp,wamoo,wamst,waiamp,pert,lin,
     &     namser,serc,sert,serf,nser,tbc,
     &     dtheta0_upp,dtheta0_low,theta0_low,theta0_upp,cflux,retau,
     &     iimhd,imhd,b0,mhd_n,fileurms,bf3,bf3nam,
     &     jet_prof,jet_diam,xjet,zjet,jetmag,
     &     adjoint)
c
c     Check if adjoint flag is correct
c
      if (iadjoint.eq.0.and.adjoint) then
         if (my_node_world.eq.0) write(*,*) 
     &        'iadjoint=1 required for adjoint=.true.'
         call stopnow(888812)
      endif





      if (my_node_world.eq.0) then
         write(*,*)
         write(*,*)
         write(*,*) '>>>>>>  Initialisation  <<<<<<<'
         write(*,*) '--------------------------------------------'//
     &        '-----------------------'
      end if
c
c     Adjoint
c
      if (my_node_world.eq.0) then
         if (adjoint) then
            write(*,*) 'Adjoint equations              :',adjoint
         end if
      end if
c
c     Arnoldi
c
      arnoldi=0
      if (arnoldi.eq.1) then
         write(*,*)'Not Implemented'
         call stopnow(123)
         namnin = arnoldi_namnin
         namnut = arnoldi_namnut
         dtn = arnoldi_dt
         vart = .false.
         tmax = arnoldi_tend 
      endif
c
c     Reading additional parameters for wall roughness
c
      if (wbci.eq.-1) then
         write(*,*)'Not Implemented'
         call stopnow(234)
c         call rparamwallrough(wallroughinput,updat,every,monitor,
c     &        monfile,v_wall,taylor4,h_rough,hstart,hend,hrise,hfall,
c     &        zfunc,qq,psi,rghfil,roughfile,pert,my_node_world)
      end if
c
c     SFD (selective frequency damping)
c
      if (isfd.eq.1) then
         if (iisfd.eq.0) then
            write(*,*) 'iisfd must be 1'
            call stopnow(45435)
         end if
      end if
c
c     Initialise SFD array
c     Read from file if sfdzero is false, otherwise initialise to zero 
c     further down.
c
      if (isfd.eq.1.and..not.sfdzero) then
         if (my_node_world.eq.0) then
            write(*,*) '** Read SFD field from ',trim(namnut_sfd)
         end if
         call rdiscbl(sfdur,sfdui,u0low,u0upp,w0low,w0upp,du0upp,re,pr,
     &        xlold,zl,t,xs,dstar,fltype,bstart,bslope,rlam,m1,spanv,
     &        spat,namnut_sfd,varsiz,3,boxr,boxi,
     &        w3,urx,nxtmp,my_node_world)
      end if

c
c     3D base flow
c
      if (bf3) then
         if (iibf3.eq.0) then
            write(*,*) 'iibf3 must be 1'
            call stopnow(45436)
         end if
c
c     Read 3D base flow field from file bf3nam
c

c         write(*,*) 'reading the 3D base flow not implemented yet!'
c         call stopnow(919293)
         call rdiscbl(bf3ur,bf3ui,u0low,u0upp,w0low,w0upp,du0upp,re,pr,
     &        xlold,zl,t,xs,dstar,fltype,bstart,bslope,rlam,m1,spanv,
     &        spat,bf3nam,varsiz,3+scalar,boxr,boxi,w3,urx,nxtmp,
     &        my_node_world)
      end if

c     
c     Read initial flow field from file namnin
c     note that u0upp, w0upp are overwritten in bflow and
c     du0upp is computed there based on the base flow
c
      call rdiscbl(ur,ui,u0low,u0upp,w0low,w0upp,du0upp,re,pr,
     &     xlold,zl,t,xs,dstar,fltype,bstart,bslope,rlam,m1,spanv,
     &     spat,namnin,varsiz,3+scalar,boxr,boxi,w3,urx,nxtmp,
     &     my_node_world)
c
c     Jet In Crossflow: Assign the Jet parameters
c     jet_prof = 1 is parabolic boundary conditioni
c     jet_prof = 2 is a top-hat boundary condition
c
      if (wbci.eq.-2) then
 
         jet_diam= jet_diam*dstar 
         suction = .false.
         asbl = .false.

         if (my_node_world.eq.0) then
            write(*,*)
            write(*,*) 'Jet in crossflow simulation'
            if (jet_prof.eq.1) then
               write(*,*) 'Parabolic Jet profile'
               write(*,*) 'Centerline velocity ratio    = ',jetmag
               write(*,*) 'Bulk velocity ratio    = ',jetmag/3.
            else if (jet_prof.eq.2) then
               write(*,*) 'Top-Hat Jet profile'
               write(*,*) 'Centerline velocity ratio    = ',jetmag
               write(*,*) 'Bulk velocity ratio    = ',jetmag
            end if
            write(*,*) 'Jet diameter      = ',jet_diam/dstar
c
c     Jet x location is now the position of the jet, not the fraction
c     of the streamwise distance as in earlier versions!
c
            write(*,*) 'x location        = ',xjet
            write(*,*) 'z location        = ',(zjet-0.5)*zl/dstar
            write(*,*)
         end if
      end if

      do i=1,scalar
         if (m1(i).ne.0.) then
            if (tbc(i).eq.1.or.tbc(i).eq.3.and.abs(m1(i)-0.5).lt.1e-12) 
     &           then
            else
               if (my_node_world.eq.0) then
                  write(*,*) 'Varying scalar at the wall and Dirichlet'
                  write(*,*) 'b.c. not yet implemented.'
               end if
               call stopnow(656453)
            end if
         end if
      end do
c
c     Asymptotic suction layer 
c
      if (suction.and.asbl) then
         vsuc=1./(re*dstar)
         if (my_node_world.eq.0) then
            write(*,*) 'ASBL suction: ',vsuc
         end if
      end if
c
c     Set to zero for spatial cases
c     Will however be overwritten by the values computed from the 
c     base flow (bflow.f)
c
      if (abs(u0low).lt.1e-8) u0low = 0.
      if (abs(w0low).lt.1e-8) w0low = 0.
      if (abs(u0upp).lt.1e-8) u0upp = 0.
      if (abs(w0upp).lt.1e-8) w0upp = 0.
c
c     Introduce boundary-layer scaling
c
      call rescale(tmax,dtn,dtmax,rot,tsave,nsave,dstar,xl,
     &     fpds1,fpds2,fpds3,fpds4,fpds5,fpds6,fpds7,
     &     fpds8,fpdds1,fpdds2,fpdds3,fpdds4,fpdds5,fpdds6,
     &     wpds1,wpds2,wpds3,wpds4,wpds5,
     &     wpds6,wpds7,wpds8,wpds9,wpds10,wpds11,wpds12,
     &     wpdds1,wpdds2,
     &     tamps,tampt,txsc,tysc,tdt,txys,tx0,
     &     fmax,fstart,fend,frise,ffall,tsmst,tsmend,tsmoo,
     &     sfd_delta,sfd_chi,dtheta0_low,dtheta0_upp)
c
c     Changing domain size
c
      if (.not.spat.or.(spat.and.abs(xl/xlold-1.).le.1.e-2)) then
         xl=xlold
      else
         if (abs(xl/xlold-1.).gt.0.) then
            if (my_node_world.eq.0) then
               write(*,*) 'Change length of domain in bla.i'
            end if
            call stopnow(565456)
            call cnxtmp(nxtmp,xl,xlold,nxp,0)
         end if
      end if
c
c     Compute some constant values for the simulation
c
      call preprbl(alfa,beta,eta,deta,xl,zl,prex,prey,prez,pres,prea,
     &     prexn,prezn,presn,prean,prezr,wint,wd1,
     &     gridx,gridy,gridz,dstar,deltaxyz2)
c
c     Read base-flow table ??? Should no be read for some other flow types as well
c
      if (fltype.ne.1.and.fltype.ne.2.and.fltype.ne.-3) then
         call rbla(fbla,nbla,dybla,rlam,dstar2,fltype,m1,pr,
     &        my_node_world,x0,re,dstar,thgrad)
      end if
c
c     xblc: current position for parallel flows in terms of reference
c           velocity and current time
c     xs:   shifting of the box since time zero
c     xs0:  shifting of the box since time zero (at beginning of simulation)
c
      xblc = x0+cdev*t
      xs0  = xs
      if (abs(u0low).gt.1.e-12) xs0=0.
c
c     Change box size (not possible with new code yet)
c
      if (spat.and.abs(xl/xlold-1.).gt.1.e-9) then
         call stopnow(5543)
         call lenbox(ur,ui,bu1,bu2,bucorr,xs,x0,fbla,
     &        rlam,spanv,re,nxtmp,xl,xlold,dstar,
     &        bstart,bslope,tabfre,namfre,u0low,w0low,
     &        fltype,fend,fstart,prex,bu1jr,prez,pres,prea,prey,
     &        wbr,wbi,pxz,wxz,my_node_world,eta,dybla,nbla,
     &        m1,suction,asbl,vsuc)
      end if
c
c     Use Gallilean shift velocity to maximize CFL number:
c     Determine shift velocity and adapt flow and boundary conditions
c
      if (gall) then
         call stopnow(98984)
         call fshift(ur,ui,u0low,u0upp,w0low,w0upp,
     &        prex,prez,pres,prea,u2r,u2i,u3r,u3i,wr,wi,xs,xl,zl)
      end if
c
c     Read waves to be put in the fringe
c
      if (ampob.ne.0.0.or.amp2d.ne.0.0.or.osmod) then
         call rwavebl(xl,zl,evr,evi,eur,eui,ewr,ewi,afw,alfaw,betaw,
     &        ampob,amp2d,prey,
     &        dstar,ev2r,ev2i,eu2r,eu2i,afw2d,alf2d,
     &        osmod,osn,osnumb,osymax,osbeta,osre,osomega,osalr,osali,
     &        osur,osui,osvr,osvi,oswr,oswi,osfil,my_node_world,osdamp)
      end if
c
c     Read waves from file
c
      if (waves) then
         write(*,*)'Not Implemented'
         call stopnow(2345)
         call rwavesbl(omega,ucwa,uswa,vcwa,vswa,ndxwa,
     &        dstar,my_node_world)
      end if
c
c     Check dimensions of OS modes
c
      if (osmod) then
         if ((int(re*dstar+0.5).eq.int(osre+0.5))
     &        .and.(int(2./dstar+0.5).eq.int(osymax+0.5))
     &        .and.(osn.eq.nyp)) then
         else
            write(*,*) '* Dimension conflict in bla and ',trim(osfil)
            write(*,'(a9,2E18.9)') '*    Re = ',re*dstar,osre
            write(*,'(a9,2I5)')    '*    Ny = ',nyp,osn
            write(*,'(a9,2E18.9)') '*    yl = ',2./dstar, osymax
            stop
         end if
      end if
c
c     Read streak from file
c
      if (streak) then
         write(*,*)'Not Implemented'
         call stopnow(4567)
         call rstreakbl(betast,omegast,
     &     ndxst,uust_r,uust_i,vvst_r,vvst_i,wwst_r,wwst_i,
     &     str_nam1,str_nam2)
      end if
c
c     Initialize two-point correlation in z
c
      if (corrf) then
         do i = 1, ncorr
c     
c     x-coordinate
c     
            if (corrt(i).lt.0) then
               corrt(i) = -corrt(i)
               corrxx(i) = 0.
               corrxi(i) = 0
               corrxodd(i) = 0
               corrx(i) = 0.
            else
               corrxx(i)  = corrx(i)*dstar
               corrxi(i)  = modulo(
     &              nint(corrxx(i)/xl*real(nx))+nx/2,nx)+1
               corrxodd(i)= mod(corrxi(i),2)
               corrxi(i)  = (corrxi(i)+1)/2
               corrxx(i)  = nint(corrx(i)/xl*real(nx))*xl/real(nx)
            end if
c     
c     y-coordinate
c     
            if (fltype.eq.1.or.fltype.eq.2.or.
     &           fltype.eq.4.or.fltype.eq.5) then
               corryy(i) = corry(i)*dstar
               corryi(i) = int(acos(corryy(i))/pi*real(nyp-1)+1.5)
               corryy(i) = (cos(pi*real(corryi(i)-1)/
     &              real(nyp-1)))/dstar
            else
               corryy(i) = corry(i)*dstar-1.
               corryy(i) = max(corryy(i),-1.)
               corryy(i) = min(corryy(i),1.)
               corryi(i) = int(acos(corryy(i))/pi*real(nyp-1)+1.5)
               corryy(i) = (cos(pi*real(corryi(i)-1)/
     &              real(nyp-1))+1.)/dstar
            end if
c
c     Set correlation data to zero
c     
            do j=1,nzc+2
               corr(j,i)=0.
            end do
            do j=1,4
               corr_ms(j,i) = 0.
            end do
         end do
c     
c     Initialize correlation FFT
c
         call vrffti(nzc,corrwsave,i)
      end if
c
c     Initialize two-point correlation in x
c     
      if (corrf_x) then
         do i = 1, ncorr_x
c     
c     z-coordinate
c     
            if (corrt_x(i).lt.0) then
               corrt_x(i) = -corrt_x(i)
               corrzz(i) = 0.
               corrzi(i) = 0
               corrz(i) = 0.
            else
               corrzz(i)  = corrz(i)*dstar
               corrzi(i)  = 
     &              modulo(nint(corrzz(i)/zl*real(nz))+nz/2,nz)+1
               corrzz(i)  = nint(corrz(i)/zl*real(nz))*zl/real(nz)
            end if
c     
c     y-coordinate
c     
            if (fltype.eq.1.or.fltype.eq.2.or.
     &           fltype.eq.4.or.fltype.eq.5) then
               corryy_x(i) = corry_x(i)*dstar
               corryi_x(i) = int(acos(corryy_x(i))/pi*real(nyp-1)+1.5)
               corryy_x(i) = (cos(pi*real(corryi_x(i)-1)/
     &              real(nyp-1)))/dstar
            else
               corryy_x(i) = corry_x(i)*dstar-1.
               corryy_x(i) = max(corryy_x(i),-1.)
               corryy_x(i) = min(corryy_x(i),1.)
               corryi_x(i) = int(acos(corryy_x(i))/pi*real(nyp-1)+1.5)
               corryy_x(i) = (cos(pi*real(corryi_x(i)-1)/
     &              real(nyp-1))+1.)/dstar
            end if
c     
c     Set correlation data to zero
c     
            do j=1,nx+2
               corr_x(j,i)=0.
            end do
            do j=1,4
               corr_ms_x(j,i) = 0.
            end do
         end do
c     
c     Initialize correlation FFT
c
         call vrffti(nx,corrwsave_x,i)
      end if
c     
c     Initialize time series
c
      if (serf) then
         do i=1, nser
c
c     x-coordinate
c
            sercc(1,i) = serc(1,i)*dstar
            serci(1,i) = modulo(nint(sercc(1,i)/xl*real(nx))+nx/2,nx)+1
            serci(4,i) = mod(serci(1,i),2)
            serci(1,i) = (serci(1,i)+1)/2
            sercc(1,i) = nint(serc(1,i)/xl*real(nx))*xl/real(nx)
c
c     y-coordinate
c
            sercc(2,i) = serc(2,i)*dstar-1.
            sercc(2,i) = max(sercc(2,i),-1.)
            sercc(2,i) = min(sercc(2,i),1.)
            serci(2,i) = int(acos(sercc(2,i))/pi*real(nyp-1)+1.5)
            sercc(2,i) = (cos(pi*real(serci(2,i)-1)/
     &           real(nyp-1))+1.)/dstar
c
c     z-coordinate
c
            sercc(3,i) = serc(3,i)*dstar 
            serci(3,i) = modulo(nint(sercc(3,i)/zl*real(nz))+nz/2,nz)+1
            sercc(3,i) = nint(serc(3,i)/zl*real(nz))*zl/real(nz)

         end do
c
c     Check array size
c
         nsamp = ixyss/ixys+min(1,mod(ixyss,ixys))
         if (nsamp.gt.msamp) then
            if (my_node_world.eq.0) then
               write(*,*) 'increase msamp to at least ',nsamp
            end if
            call stopnow(56455435)
         end if
         series = 0.
      end if
      sercount = 0

c
c     3D-base flow: Compute vorticities and transform to physical space
c
      if (bf3) then

         call mpi_barrier(mpi_comm_world,ierror)

         call bfvort3(bf3ur,bf3ui,alfa,beta,my_node_x,my_node_z,prey)

         call mpi_barrier(mpi_comm_world,ierror)
         
         if (my_node_world.eq.0) then
            write(*,*) 'Vorticity of 3D base flow computed!'
         end if

         if (nproc.eq.1) then
            nypp = nyp
         else
            nypp = nyp/nprocz+1
         end if

         do ybp=1,nypp
            yb =(ybp-1)*nprocz+my_node_world/nprocx+1
 
            call pre_nlin_3d(bf3ur,bf3ui,my_node_x,my_comm_x,
     &        my_node_world,
     &        my_node_z,my_comm_z,
     &        prex,pres,prez,prea,
     &        realg1,realg2,realg3,realg4,
     &        bf3u2r,bf3u2i,yb,ybp,
     &        boxi_z,boxr_z,wr_x,wr_z)

         end do

         call mpi_barrier(mpi_comm_world,ierror)

      end if

c
c     Compute/read base flow
c     Note: u0upp,w0upp,du0upp are set according to the base flow
c     The base flow is only needed for spatial simulations or
c     for cases where the boundary conditions are set by the base flow,
c     i.e. ibc=100,101,110,120,130,140,150.
c
      if (fltype.ne.1.and.fltype.ne.2.and.fltype.ne.-3) then
         call bflow(bu1,bu2,bu1jr,bu1ji,xs0,x0,eta,fbla,
     &        rlam,m1,spanv,re,xl,dstar,bstart,bslope,
     &        tabfre,namfre,rbfl,nambfl,u0low,w0low,u0upp,du0upp,
     &        wd1,prex,
     &        prey,wbr,wbi,boxr,boxi,w3,fltype,my_node_world,
     &        suction,asbl,vsuc,pert,nbla,dybla,thgrad,dtheta0_low,tbc,
     &        theta0_low,theta0_upp,w0upp)
      end if
c
c     Compute vorticity associated with base flow and adjust boundary conditions
c
      if (pert.and..not.bf3) then
         write(*,*) 'Computing base flow vorticity...'
         call bfvort(bu1,bu2,bom1,bom2,alfa,prex,prey,prexn,
     &        wbr,wbi,appr,appi,app2r,app2i,wlin,bu3,bu4,bom3,bom4)
         u0upp = 0.
         w0upp = 0.
         du0upp= 0.
      end if
c
c     Adjoint base flow gradient
c
      if (adjoint.and..not.bf3) then
         call bfgrad(bu1,bu2,bfgrad1,bfgrad2,
     &     alfa,prex,prey)
      end if

      if (my_node_world.eq.0) then
         write(*,*)
         write(*,*) 'Boundary conditions (according to base flow)'
         write(*,*) '  u0low,w0low : ',u0low,w0low
         write(*,*) '  u0upp,w0upp : ',u0upp,w0upp
         write(*,*) '  du0upp      : ',du0upp
      end if
c
c     Transform base flow for moving lower wall
c
      if (spat.and.abs(u0low).gt.1.e-12) then
         call stopnow(65765564)
         call blfou(bu1f,bu2f,bu1,bu2,
     &        bu1jr0,bu1ji0,bu1jr,bu1ji,prex,wbr,wbi)
      end if
c
c     Get time step dt for first iteration
c
      if (vart) then
         call getdt(dtn,cflmax,rot,deta,xl,zl,prex,prez,pres,prea,
     &        ur,ui,u2r,u2i,bu1,bu2,pert,lin,wr,wi,
     &        realg1,realg2,realg3,realg4,wbci,my_comm_z,my_node_z,
     &        my_comm_x,my_node_x,my_node_world,
     &        boxr_z,boxi_z,wr_z,wi_z,wr_x,wi_x)
         if (my_node_world.eq.0) then
            write(*,*)
            write(*,*) 'First time step      : ',dtn/dstar
         end if
      end if

      if (spat) then
c
c     Time step limitation for fringe region for spatial problem:
c     l_max={left boundary of absolute stability region along real axis}
c     l_max= 2.8 RK4, 2.5 RK3, 1 AB2
c     fmax : maximum of the fringe function
c     dt < 0.7 * l_max/fmax*dstar (for dt in channel scaling)
c
         if (nst.eq.1) dtmax = min(dtmax,0.7/fmax)
         if (nst.eq.3) dtmax = min(dtmax,1.75/fmax)
         if (nst.eq.4) dtmax = min(dtmax,1.96/fmax)
         if (my_node_world.eq.0) then
            write(*,*) 'Maximum time step due to fringe forcing: ',
     &           dtmax/dstar
         end if
      end if
c      
c     Fix time-integration factors for first time step
c
      dtn=min(dtn,dtmax)
      if (nst.gt.2) then
         an   = dtn*anrk(1,nst-2)
         cnp1 = 0.
      else
         an   = dtn
         cnp1 = an*.5
      end if
      dtnp1 = dtn
      anp1  = an
      bnp1  = 0.
c
c     Large-Eddy Simulation
c
      iles = 0
      if (sgs) then
c
c     Get LES parameters
c
        call rparamles(iles,iiles,iiles_smag,
     &       cutoff,iord,ihighorder,my_node_world,chi,ineg,cs,prt)
      end if
      if (iles.eq.1.or.iles.eq.3) then
c
c     Prepare LES filters
c
c     Initialize the primary lowpass filter
c     note that kc=nx/2 resp. nz/2
c
         ip=mod(my_node_world,nprocx)*memnx
         gewspecx = 0.
         gewspecz = 0.
         call init_filter(cutoff,nx/2+1,nyp,nz/2+1,gridy, 
     &        gewy1,gewy2,gewspecx,gewspecz,diags,my_node_world)
c         
c     Compose xz-plane lowpass filter weights
c
         do i=1,memnx
            do j=1,nz/2
               filtxz(i,j) = gewspecx(i+ip)*gewspecz(j)
            end do
            do j=nz/2+1,nz
               filtxz(i,j) = gewspecx(i+ip)*gewspecz(nz-j+2)
            end do
         end do
c
c     High-order xz-plane lowpass filter
c
c         call stopnow(43242)
c     the next lines commented out due to internal compiler error
         do j=1,nz
            do i=1,memnx
               lpfxz(i,j) = 1-(1-filtxz(i,j))**(iord+1)
            end do
         end do

         if (iles.eq.3.and.cs.eq.0) then
            gewspecx = 0.
            gewspecz = 0.
            call init_filter(cutoff,nx/4+1,nyp,nz/4+1,gridy, 
     &           gewy12,gewy22,gewspecx,gewspecz,diags2,my_node_world)
c
c     Compose xz-plane filter weights
c
            do i=1,memnx
               do j=1,nz/2
                  filtxz2(i,j) = gewspecx(i+ip)*gewspecz(j)
               end do
               do j=nz/2+1,nz
                  filtxz2(i,j) = gewspecx(i+ip)*gewspecz(nz-j+2)
               end do
            end do
c            
c     High-order lowpass filter
c
c            call stopnow(43242)
c     the next lines commented out due to internal compiler error
            do j=1,nz
               do i=1,memnx
                  lpfxz2(i,j) = 1-(1-filtxz2(i,j))**(iord+1)
               end do
            end do
         end if
      end if
c
c     Initialise SFD arrays to zero if not read from file
c
      if (isfd.eq.1.and.sfdzero) then
         if (my_node_world.eq.0) then
            write(*,*) '** SFD field initialized to zero'
         end if
         do i=1,3
            sfdur(:,:,:,i) = ur(:,:,:,i)
            sfdui(:,:,:,i) = ui(:,:,:,i)
         end do
      end if
c
c     Build partial rhs for first Euler step (i.e. next step)
c     filtering in wall-normal direction in gur,gui
c
      call prhs(ur,ui,puw,alfa,beta,re,pr,anp1,prey,u3r,u3i,om3r,om3i,
     &     th3r,th3i,
     &     pomyr,pomyi,pvr,pvi,pthr,pthi,boxr,boxi,w3,dthr,dthi,
     &     iles,gur,gui,taur,taui,gu3r,gu3i,ggu3r,ggu3i,gsr,gsi,
     &     gth3r,gth3i,ggth3r,ggth3i,gewy1,gewy2,gewy12,gewy22,iord,
     &     diags,diags2,gplane,
     &     filtxz,filtxz2,lpfxz,lpfxz2,my_node_world,ihighorder,cs)
c
c     Initialize some variables
c
      if (nproc.eq.1) then
         nypp = nyp
      else
         nypp = nyp/nprocz+1
      end if

      sumw = 0.
      xys = 0.
      xysth = 0.
      stop_now = 0
      it = 1
      zs = 0.
      ctime_stat = 0.
      wtime_stat = 0.
      ctime_les = 0.
      wtime_les = 0.
      ctime_nonlin = 0.
      wtime_nonlin = 0.
      ctime_linear = 0.
      wtime_linear = 0.
      ctime_io = 0.
      wtime_io = 0.
      ctime_tau = 0.
      wtime_tau = 0.
      ctime_rest = 0.
      wtime_rest = 0.
      ctime_trip = 0.
      wtime_trip = 0.
      ctime_ffun = 0.
      wtime_ffun = 0.
      ctime_cfl = 0.
      wtime_cfl = 0.
      ctime_planes = 0.
      wtime_planes = 0.
      ctime_press = 0.
      wtime_press = 0.
      tcom = 0.
      tser = 0.
      delta_wall_time = 0.
      
      do_stat = .false.
      do_press = .false.
      do_press_nl = .false.
c
c     Pressure gradient for temporal channel flow (fltype=1)
c     For all other cases (e.g. boundary-layer flows) it should be zero.
c
      if (fltype.eq.1) then

         if (cflux) then
c
c     Set mflux for fixed mass flux
c     px is only used as a first guess
c
            mflux = 4./3.
            px = -2./re
            if (my_node_world.eq.0) then
               write(*,*)
               write(*,*) 'Fixed mass flux for channel flow : '
               write(*,*) '   mflux  : ',mflux
            end if
         else
c
c     Set px for fixed pressure gradient
c
c     The pressure gradient in laminar channel flows (with Re based
c     on the centre-line velocity), the skin friction is given as
c            retau = sqrt(2.*re)
c
            mflux = 0.
            px = -(retau/re)**2
            retau = sqrt(-px)*re
            if (my_node_world.eq.0) then
               write(*,*)
               write(*,*) 'Fixed pressure gradient for channel flow : '
               write(*,*) '   px     : ',px
               write(*,*) '   Re_tau : ',retau
            end if
         end if
      else
         px = 0.
         mflux = 0.
         cflux = .false.
         if (my_node_world.eq.0) then
            write(*,*) 'No pressure gradient : ',px,mflux,cflux
         end if
      end if
c
c     Open files for amplitude, waves and extrema
c
      amp = 0.
      if (my_node_world.eq.0) then
         if (iamp .gt.0) open(unit=15,file=namamp)
         if (mwave.gt.0) open(unit=16,file=namwav)
         if (iext .gt.0) open(unit=18,file=namext)
      end if
c
c     Determine next full flow field to save
c
      isave = 1
      do i=1,nsave
         if (.not.adjoint) then
            if (t.ge.tsave(i)) then 
               isave=isave+1
            else
               exit
            end if
         elseif (adjoint) then
            if (t.le.tsave(i)) then 
               isave=isave+1
            else
               exit
            end if
         end if
      end do
      if (my_node_world.eq.0) then
         write(*,*) 'Next field to save   : isave =',isave,
     &        ' at t=',tsave(isave)/dstar
      end if
      
#ifdef MPI
      if (nproc.gt.1) call mpi_barrier(mpi_comm_world,ierror)
#endif

      sttimet = t

      if (my_node_world.eq.0) then

         call ctim(ctime4,wtime4)
         wtime_startup = wtime4-wtime3
         ctime_startup = ctime4-ctime3
         ctime3=ctime4
         wtime3=wtime4
         ctime1=ctime4
         wtime1=wtime4

         write(*,'(a,f10.3,a,f10.3,a)') ' CPU time             : ',
     &        ctime4-ctime0,
     &        ' sec'
         write(*,'(a,f10.3,a,f10.3,a)') ' Wall time            : ',
     &        wtime4-wtime0,' sec'
         write(*,*)
         write(*,*)
         write(*,*) '>>>>>>  Starting simulation  <<<<<<'
         write(*,*) '--------------------------------------------'//
     &              '-----------------------'
         write(*,*) 'Starting iteration at t=',t/dstar
         write(*,*)
c
c     Write out first step file
c
         open(file='step.out',unit=87)
         write(87,'(a20,f18.9,a,f18.9,a)') 'Time now: ',t/dstar,
     &        ' (max. ',tmax/dstar,')'
         write(87,'(a20,f18.9)') 'Started with: ',sttimet/dstar
         write(87,'(a20,f18.9)') 'Delta: ',(t-sttimet)/dstar
         write(87,'(a20,i18,a,i18,a)') 'Iterations: ',it-1,
     &        ' (max. ',maxit,')'
         call time_string(timdat)
         write(87,'(a20,a20)') 'Time now: ',timdat
         write(87,'(a20,a20)') 'Started: ',sttimec
         write(87,'(a,f18.9,a,f18.9,a)') 'CPU time       ',
     &        ctime4-ctime0,
     &        ' seconds (max. ',cpumax,')'
         write(87,'(a,f18.9,a,f18.9,a)') 'Wallclock time ',
     &        wtime4-wtime0,
     &        ' seconds (max. ',wallmax,')'
         close(87)


      end if
c
c     Wall roughness
c
      if (wbci.eq.-1) then 
         write(*,*)'Not Implemented'
         call stopnow(345678)
c
c     Rescale the wall-roughness parameters
c
         hstart=hstart*dstar
         hend=hend*dstar
         hrise=hrise*dstar
         hfall=hfall*dstar      
         h_rough=h_rough*dstar
c
c     Start and end index of roughness (x direction):
c
         delh = xl/nx
         joker = 0.5*hstart/delh
         hst =  int(joker)
         joker = joker - hst
         if (joker.ge.0.5) hst = hst+1
         joker = 0.5*hend/delh
         hen =   int(joker)
         joker = joker - hen
         if (joker.ge.0.5) hen = hen+1
         hlen = hen-hst+1

         write(*,*) hst,hen,hlen

         if (my_node_world .eq. 0) then
            if (hlen .gt. lenx) then
               write(*,*) 'Wall roughness: '
               write(*,*) 'hlen vs. lenx: ',hlen,lenx
               write(*,*) 'Increase "lenx" in bla.f, steadywallrough.f '
               write(*,*) 'and updatewallrough.f , please.'
               stop
            end if
         end if

c         call steadywallrough(bu1,bu2,wallur,wallui,
c     &        wallwr,wallwi,v_wall,wlvr,wlvi,
c     &        prexn,prey,prezn,presn,prean,
c     &        alfa,beta,zl,xsc,zsc,dstar,hst,hlen,delh,
c     &        h_rough,hstart,hend,hrise,hfall,zfunc,qq,psi,tpsi,taylor4,
c     &        rghfil,roughfile,monitor,monfile,my_node_world)
      end if

c------------------------------------
c>>>>>>  START OF INTEGRATION  <<<<<<
c------------------------------------

c
c     Timestep loop, starting with it=1
c
 1    continue

c
c     Step 2
c
c     Time of the substep
c
      rksubstep = mod(it-1,nst)+1
      tc=t+cnp1

c      write(*,*) '>>>>>> RK STEP <<<<<<',rksubstep,it
c      write(*,*) '      step: ',t/dstar,'-',(t+dtn)/dstar
c      write(*,*) '   substep: t=',tc/dstar
 
c
c     Impose the jet boundary condition
c
      if (wbci.eq.-2) then

      if (iiwall.eq.0) then
        call stopnow(432343)
      endif

         call jetinit(wallvr,wallvi,vsuc,tc,dstar,jet_diam,xjet,zjet, 
     &        jetmag,jet_prof, zsc,xsc, zl,xl,
     &        prex,prez,pres,jetwi,jetwr,it,my_node_world,
     &        wallthr,wallthi)
      end if
c     
c     Move centre of the box according to u0low, w0low
c
      xsc=xs-cnp1*u0low
      zsc=zs-cnp1*w0low
c
c     Only needed for temporal boundary-layer simulations:
c     Streamwise position of the boundary layer
c    
      xbl =x0+cdev*t
      xblc=x0+cdev*tc
c
c     Decide whether statistics are taken
c
      if (ixys.gt.0.and.mod(it-1-nst,ixys).eq.0..and.t.ge.txys
     &     .and.it.gt.1) then

         if (.not. adjoint) then
            if (t.ge.txys) then
               do_stat = .true.
            end if
         else
            do_stat =.true.
         end if
c     
c     Check if pressure field has been computed during last time step
c
         if (pressure.eq.1.and..not.do_press) then
            if (my_node_world.eq.0) then
               write(*,*) 'Pressure has not been computed',it
            end if
            call stopnow(56654543)
         end if
      else
         do_stat = .false.
      end if
c            
c     Decide whether the pressure has to be computed
c     At the moment only if statistics are taken, maxit or 
c     tmax is hit, or a regular file is written.
c
      if (pressure.eq.1) then
         if (ixys.gt.0.and.mod(it-nst,ixys).eq.0
     &        .and.t+1.5*dtn.ge.txys) then
            do_press = .true.
         else if (t+1.5*dtn.ge.tmax.and.mod(it,nst).eq.0) then
            do_press = .true.
         else if (maxit.gt.0.and.it.ge.maxit
     &              .and.mod(it,nst).eq.0) then
            do_press = .true.
         else if (t+1.5*dtn.gt.tsave(isave).and.mod(it,nst).eq.0) then
            do_press = .true.
         else
            do_press = .false.
         end if

         if (ixys.gt.0.and.mod(it+nst-1-nst,ixys).eq.0
     &        .and.t+1.5*dtn.ge.txys) then
            do_press_nl = .true.
         else if (t+1.5*dtn.ge.tmax.and.mod(it+nst-1,nst).eq.0) then
            do_press_nl = .true.
         else if (maxit.gt.0.and.it+nst-1.ge.maxit
     &              .and.mod(it+nst-1,nst).eq.0) then
            do_press_nl = .true.
         else if (t+1.5*dtn.gt.tsave(isave)
     &              .and.mod(it+nst-1,nst).eq.0) then
            do_press_nl = .true.
         else
            do_press_nl = .false.
         end if

      end if

      call ctim(ctime4,wtime4)
      ctime_rest = ctime_rest + (ctime4-ctime3)
      wtime_rest = wtime_rest + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4
c
c     Write planes
c
      if (npl.gt.0.and.mod(it-1,ipl).eq.0) then
         write(*,*)'Not Implemented'
         call stopnow(3456789)
         if (nproc.eq.1) then
c
c     Serial plane writing
c
            call wplbl_serial(npl,nampl,tpl,cpl,
     &           it,u2r,u2i,wxz,wxy,wyz,wr,wi,ur,ui,
     &           mpl,re,xl,zl,t,xs,dstar,fltype,
     &           prexn,prezn,presn,prean,u0low,w0low,alfa,zs,
     &           beta,wplblodd)
         else
c
c     Parallel plane writing
c
            call wplbl(npl,nampl,tpl,cpl,
     &           it,u2r,u2i,wxz,wxy,wyz,wr,wi,ur,ui,
     &           mpl,re,xl,zl,t,xs,dstar,fltype,
     &           prexn,prezn,presn,prean,u0low,w0low,alfa,zs,
     &           beta,wplblodd,my_node_world,realg1,realg2,plxy)
         end if

      end if
c
c     Compute base flow shift
c
      if (spat.and.abs(u0low).gt.1.e-12) then
c
c     This should be checked again...???
c
         call stopnow(65464)
         call blshift(bu1,bu2,bu1jr,bu1ji,bu1jr0,bu1ji0,
     &        bu1f,bu2f,xsc,xl,prex,wbr,wbi)
      end if

      call ctim(ctime4,wtime4)
      ctime_planes = ctime_planes + (ctime4-ctime3)
      wtime_planes = wtime_planes + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4
c
c     Generate trip forcing
c
      if (tripf) then
            call gtrip(tc,zsc,zl,tdt,ttzc,nzt,tamps,tampt,
     &           it,seed,ntdt,prezr)
      end if

      call ctim(ctime4,wtime4)
      ctime_trip = ctime_trip + (ctime4-ctime3)
      wtime_trip = wtime_trip + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4

c########################################
      if (iles.eq.2.or.iles.eq.3) then
         if (iles.eq.2) then
            if (my_node_world.eq.0.and.rksubstep.eq.1) then
               if (cs.eq.0) then
                  write(*,*) '** Calculate dyn. EV **', t/dstar
               else
                  write(*,*) '** Calculate EV **', t/dstar
               end if
            end if
         else
            if (my_node_world.eq.0.and.rksubstep.eq.1) then
               if (cs.eq.0) then
                  write(*,*) '** Calculate dyn. HPF EV **', t/dstar
               else
                  write(*,*) '** Calculate HPF EV **', t/dstar
               end if
            end if
         end if
c            
c     Compute tau_ij
c
!$omp parallel do private(ybp,ip,yb,myb)
         do ybp=1,nypp
#ifdef OPENMP
            ip = OMP_GET_THREAD_NUM()+1
#else
            ip = 1
#endif
            yb = (ybp-1)*nprocz+my_node_world/nprocx+1
            myb= (yb-1)/mby+1
            call les(re,xs,zs,yb,ur,ui,
     &           u0low,w0low,prexn,prezn,presn,prean,
     &           alfa,beta,u2r(1,ip),u2i(1,ip),
     &           om2r(1,ip),om2i(1,ip),
     &           wr(1,ip),wi(1,ip),
     &           du2r(1,1,1,1,ip),du2i(1,1,1,1,ip),
     &           s2r(1,ip),s2i(1,ip),l2r(1,ip),l2i(1,ip),
     &           m2r(1,ip),m2i(1,ip),b2r(1,ip),b2i(1,ip),
     &           sabsr(1,ip),sabsi(1,ip),cr(1,ip),ci(1,ip),
     &           sdr(1,ip),sdi(1,ip),
     &           my_node_world,realg1,realg2,realg5,realg6,
     &           my_node_z,my_node_x,my_comm_z,my_comm_x,
     &           deltaxyz2,taur,taui,
     &           do_stat,xys,ybp,dtn,ineg,iles,cs,
     &           gur,gui,gu2r(1,ip),gu2i(1,ip),gom2r(1,ip),gom2i(1,ip),
     &           gdu2r(1,ip),gdu2i(1,ip),
     &           th2r(1,ip),th2i(1,ip),ls2r(1,ip),ls2i(1,ip),
     &           glr,gli,glsr,glsi,prt,boxr_z,boxi_z,
     &           dboxr_z,dboxi_z,boxrr,boxii,wr_z,wi_z,wr_x,wi_x,
     &           gboxr_z,gboxi_z,gboxr,gboxi,gdboxr_z,gdboxi_z,gridy)
         end do
      end if

      call ctim(ctime4,wtime4)
      ctime_les = ctime_les + (ctime4-ctime3)
      wtime_les = wtime_les + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4
         
      if (iles.eq.2.or.iles.eq.3) then
c
c     Compute sigma_i=dtau_ij/dx_j
c
!$omp parallel do private(zbp,zb,ip)
         do zbp=1,memnz
#ifdef OPENMP
            ip = OMP_GET_THREAD_NUM()+1
#else 
            ip = 1
#endif
            zb = my_node_world/nprocx*memnz+zbp
            call sgs_stress(taur,taui,zb,zbp,alfa,beta,
     &           gur,gui,gu3r(1,ip),gu3i(1,ip),w3(1,ip),prey,
     &           u3r(1,ip),u3i(1,ip),tau3r(1,ip),tau3i(1,ip),
     &           gsr,gsi,my_node_world)
         end do
      end if
c########################################

c-------------------------------------
c     MHD PART
c-------------------------------------
c     independent xy planes in z
c     zbp    local index of xy plane
c     ip     thread number
c     zb     start index of box
c     mbz    thickness of box
c-------------------------------------

      if (imhd.eq.1) then
         write(*,*)'Not Implemented'
         call stopnow(11223)
!$omp parallel do private(zbp,zb,ip)
         do zbp=1,memnz
#ifdef OPENMP
            ip = OMP_GET_THREAD_NUM()+1
#else
            ip = 1
#endif
            zb = my_node_world*memnz+zbp
            call mhd_poi(ur,ui,zb,zbp,alfa,beta,
     &           om3r(1,ip),om3i(1,ip),
     &           u3r(1,ip),u3i(1,ip),f(1,1,ip),f(1,1,ip),f(1,2,ip),
     &           w3(1,ip),prey,bis(1,1,ip),bis(1,1,ip),bis(1,2,ip),
     &           q(1,ip),c(1,ip),d(1,ip),e(1,ip),fmhdr,fmhdi,
     &           b0)
            
         end do
      end if
c-------------------------------------

      call ctim(ctime4,wtime4)
      ctime_tau = ctime_tau + (ctime4-ctime3)
      wtime_tau = wtime_tau + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4
c-------------------------------------
c     STATISTICS
c-------------------------------------
c     independent xz planes in y
c     ybp    local index of xz plane
c     ip     thread number
c     yb     start index of box
c     mby    thickness of box
c     myb    box number
c-------------------------------------
      if (do_stat) then
         sercount = sercount + 1
         if (my_node_world.eq.0) then
            write(*,*) '** Calculate statistics **', t/dstar,sercount
         end if
         
!$omp parallel do private(ybp,ip,yb,myb)
         do ybp=1,nypp
#ifdef OPENMP
            ip = OMP_GET_THREAD_NUM()+1
#else
            ip = 1
#endif
            yb =(ybp-1)*nprocz+my_node_world/nprocx+1
            myb=(yb-1)/mby+1
            call boxxys(xys,xysth,tc,xs,zs,yb,dtn,ur,ui,
     &           u0low,w0low,prexn,prezn,presn,prean,
     &           alfa,beta,u2r(1,ip),u2i(1,ip),
     &           h2r(1,ip),h2i(1,ip),
     &           om2r(1,ip),om2i(1,ip),
     &           wr(1,ip),wi(1,ip),
     &           du2r(1,1,1,1,ip),du2i(1,1,1,1,ip),
     &           th2r(1,ip),th2i(1,ip),
     &           corrf,corrf_x,corrxi,corryi,corrzi,corryi_x,corr,
     &           corr_x,corrwsave,corrwsave_x,ncorr,ncorr_x,corrxodd,
     &           corrt,corrt_x,corr_ms,corr_ms_x,it,
     &           my_node_world,realg1,realg2,realg5,realg6,
     &           my_node_z,my_node_x,my_comm_z,my_comm_x,
     &           taur,taui,tau2r(1,ip),tau2i(1,ip),iles,
     &           series,serci,sert,serf,nser,sercount,re,fltype,dstar,
     &           pert,bu3,bu4,bom3,bom4,
     &           fmhdr,fmhdi,j2r(1,ip),j2i(1,ip),b0,imhd,px,mflux,mhd_n,
     &           boxr_z,boxi_z,dboxr_z,dboxi_z,boxrr,boxii,wr_z,wi_z,
     &           wr_x,wi_x,gboxr_z,gboxi_z,ybp)
          end do
         sumw=sumw+dtn
      end if
c-------------------------------------

      call ctim(ctime4,wtime4)
      ctime_stat = ctime_stat + (ctime4-ctime3)
      wtime_stat = wtime_stat + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4

c      if (ixys.gt.0.and.mod(it-1,ixyss).eq.0.and.t.ge.txys
c     &     .and.it.gt.1.and.sumw.gt.0.) then


      if (ixys.gt.0.and.mod(it-1,ixyss).eq.0.
     &     .and.it.gt.1.and.sumw.gt.0.) then

         if (.not. adjoint) then
            if (t.ge.txys) then
               do_stat = .true.
            end if
         else
            do_stat =.true.
         end if


c
c     Write statistics and intermediate velocity field
c
         if (my_node_world.eq.0) then
            write(*,*) '** Write statistics **', t/dstar,sumw/dstar
         end if
         call wxys(xys,xysth,my_comm_z,my_comm_x,
     &        totcorr,corr,ncorr,corrf,
     &        totcorr_ms,corr_ms,
     &        totcorr_x,corr_x,ncorr_x,corrf_x,
     &        totcorr_ms_x,corr_ms_x,
     &        my_node_world,
     &        series,serf,nser,totseries,
     &        sumw,re,xl,zl,t,dstar,fltype,
     &        bstart,bslope,rlam,spanv,namxys,wxy,
     &        corrnam,corrxx,corryy,corrwsave,
     &        corrx,corry,corrxi,corryi,pr,m1,corrt,
     &        corrnam_x,corrzz,corryy_x,corrwsave_x,
     &        corrz,corry_x,corrzi,corryi_x,corrt_x,
     &        nsamp,namser,sercount,mhd_n,b0)

         sercount = 0

         if (write_inter) then
            if (my_node_world.eq.0) then
               write(*,*) '** Write intermediate velocity field **',
     &              t/dstar
            end if

            call wdiscbl(ur,ui,re,pr,m1,xl,zl,t,xs,dstar,fltype,
     &           bstart,bslope,rlam,spanv,namnut_inter,3+scalar,gall,
     &           boxr,boxi,urx,alfa,zs,beta,my_node_world,
     &           u0low,u0upp,w0low,w0upp,du0upp)
         end if
      end if

      call ctim(ctime4,wtime4)
      ctime_io = ctime_io + (ctime4-ctime3)
      wtime_io = wtime_io + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4

c ??? Also for flow type 9?
      if (spat) then
c
c     Compute the fringe function and the OS-modes
c
         call ffun(fstart,fend,frise,ffall,fmax,
     &        xl,zl,tc,xsc,zsc,xc1,xc2,fring1,fring2,
     &        cphas1,cphas2,sphas1,sphas2,
     &        osnumb,osomega,osalr,osali,osbeta,osamp,
     &        osdamp,osmod,my_node_world)
      end if

      call ctim(ctime4,wtime4)
      ctime_ffun = ctime_ffun + (ctime4-ctime3)
      wtime_ffun = wtime_ffun + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4


c#######################################
      if (iles.eq.1) then
c
c     The relaxation term has to be rescaled.
c     stability is determined by assuming du/dt=lambda u with
c     lambda being chi+fringe forcing. 
c
c     Save value for constant chi
c
         chi_scaled = chi/dstar

         if (my_node_world.eq.0.and.rksubstep.eq.1) then
            write(*,'(a,2e18.9,a)') 
     &           'LES with chi=',chi,dtn*(chi_scaled+fmax),'<=2.78'
         end if
c
c     Stability criterion of RT: dtn*chi <= 0.7*2.8=1.96 (RK4)
c
         if (dtn*(chi_scaled+fmax).gt.2.78) then
            write(*,*) 'chi+fmax higher than RK4 stability limit.'
            write(*,*) 'chimax (2.78) = ',(2.78/dtn-fmax)*dstar
c            call stopnow(453453)
         end if
      end if
c######################################

c      tcom = 0.
c      tser = 0.

c-------------------------------------
c     NONLINEAR PART (explicit)
c-------------------------------------
c     independent xz planes in y
c     ybp    local index of xz plane
c     ip     thread number
c     yb     start index of box
c     mby    thickness of box
c     myb    box number
c-------------------------------------


!$omp parallel do private(ybp,ip,yb,myb)
      do ybp=1,nypp
#ifdef OPENMP
         ip = OMP_GET_THREAD_NUM()+1
#else
         ip = 1
#endif
         yb =(ybp-1)*nprocz+my_node_world/nprocx+1
         myb=(yb-1)/mby+1
         call nonlinbl(amp,campw,kx,kz,nwave,cflp(myb),vext,cext,
     &        iext,ur,ui,tc,xsc,zsc,xs,yb,rot,spat,fltype,
     &        fstart,fend,nst,
     &        bu1,bu2,
     &        loctyp,fp1,fpds1,fpds2,fpds3,fpds4,fpds5,fpds6,
     &        fpds7,fpds8,fpdds1,fpdds2,fpdds3,fpdds4,fpdds5,
     &        tripf,txsc,tysc,ttzc,tx0,
     &        osmod,osnumb,
     &        osur,osui,osvr,osvi,oswr,oswi,
     &        xc1,xc2,fring1,fring2,cphas1,cphas2,sphas1,sphas2,
     &        evr,evi,eur,eui,ewr,ewi,afw,alfaw,betaw,ampob,amp2d,
     &        ev2r,ev2i,eu2r,eu2i,afw2d,alf2d,
     &        fbla,nbla,dybla,rlam,cdev,re,xblc,alfa,
     &        beta,eta,deta,xl,zl,prex,prez,pres,prea,it,icfl,
     &        iamp,u2r(1,ip),u2i(1,ip),om2r(1,ip),om2i(1,ip),
     &        th2r(1,ip),th2i(1,ip),
     &        wr(1,ip),wi(1,ip),
     &        iles,gur,gui,chi_scaled,prt,
     &        my_node_world,my_node_z,my_node_x,my_comm_z,my_comm_x,
     &        realg1,realg2,realg3,realg4,realg5,realg6,
     &        suction,vsuc,ampst,streak,betast,omegast,
     &        ndxst,uust_r,uust_i,vvst_r,vvst_i,wwst_r,wwst_i,
     &        tsmoo,tsmst,tsmend,iampst,phist,
     &        isfd,sfd_chi,sfd_delta,sfdur,sfdui,anp1,bnp1,wbci,
     &        pert,lin,bom1,bom2,x0,spanv,rv1r,rv1i,do_press_nl,
     &        tcom,tser,gsr,gsi,fmhdr,fmhdi,imhd,
     &        du2r(1,1,1,1,ip),du2i(1,1,1,1,ip),b0,mhd_n,
     &        boxr_z,boxi_z,boxrr,boxii,wr_z,wi_z,wr_x,wi_x,
     &        bf3,bf3u2r,bf3u2i,ybp,
     &        adjoint,bfgrad1,bfgrad2,u2xr,u2xi,u2zr,u2zi,
     &        boxrz_z,boxiz_z,boxrx_z,boxix_z,boxrs_z,boxis_z,
     &        tempr,tempi,aaar,aaai)
      end do

c-------------------------------------

      call ctim(ctime4,wtime4)
      ctime_nonlin = ctime_nonlin + (ctime4-ctime3)
      wtime_nonlin = wtime_nonlin + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4
c
c     Write amplitude file
c
      if (mod(it-1-nst,iamp).eq.0.and.iamp.gt.0) then
         call wampbl(t,it,amp,campw,kx,kz,
     &        mwave,nwave,wint,re,xl,zl,longli,dstar,
     &        rlam,xbl,my_node_world,eta,fbla,dybla,nbla,spanv,fileurms,
     &        my_node_x,my_node_z,my_comm_x,fltype,px,vsuc)
      end if
c
c     Write extremum file
c
      if (mod(it-1,iext).eq.0.and.iext.gt.0) then
         write(*,*)'Not Implemented'
         call stopnow(77889)
         call wextbl(t,vext,cext,re,xl,
     &        xbl,u0low,w0low,longli,dstar,eta,fltype,fend,
     &        my_node_world,fbla,dybla,nbla)
      end if

      call ctim(ctime4,wtime4)
      ctime_io = ctime_io + (ctime4-ctime3)
      wtime_io = wtime_io + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4
c
c     Update cfl time-step restriction
c
      if (mod(it-1,icfl).eq.0.and.icfl.gt.0) then
         call wcflbl(dtn,cfl,cflp,rot,dstar,my_node_world)
      end if
c
c     Step 3
c
      if (vart.and.mod(it,nst).eq.0) then
         ! time step for NEXT iteration
         tleft=min(tmax,tsave(isave))-t-dtn
         if(adjoint) then
            tleft=-max(tmax,tsave(isave))+t-dtn
         end if
         if (cfl/cflmax.gt.10./9.) then
            dtnp1 = dtn* cflmax/cfl
         else
            dtnp1 = dtn*( 0.8 + 0.2*cflmax/cfl )
         end if
         dtnp1=min(dtnp1,dtmax)
         if (.5*dtnp1.lt.tleft.and.tleft.lt.4.*dtnp1) then
            if (my_node_world.eq.0) then
               write(*,*) 'Adjusting time step to ',
     &              min(tmax,tsave(isave))/dstar
            end if
            dtnp1=tleft/aint(tleft/dtnp1+1.)
         end if
      end if
c
c     RK integration weights
c
      ! weights for this iteration
      an=anp1
      bn=bnp1
      ! weights for next iteration
      if (nst.eq.1) then
         bnp1=-dtnp1**2/(2.*dtn)
         anp1=dtnp1-bnp1
         cnp1=dtnp1*.5
      else
         anp1=dtnp1*anrk(mod(it,nst)+1,nst-2)
         bnp1=dtnp1*bnrk(mod(it,nst)+1,nst-2)
         cnp1=dtnp1*cnrk(mod(it,nst)+1,nst-2)
      end if

      call ctim(ctime4,wtime4)
      ctime_cfl = ctime_cfl + (ctime4-ctime3)
      wtime_cfl = wtime_cfl + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4

      if (wbci.gt.0) then
c
c     Suction and blowing at the wall
c
         call stopnow(56564)
         call cwallbc(wallvr,wallvi,wp1,wp2,wpds1,
     &        wpds2,wpds3,wpds4,wpds5,
     &        wpds6,wpds7,wpds8,wpds9,wpds10,wpds11,wpds12,
     &        wpdds1,wpdds2,
     &        prex,prez,pres,wr,wi,xl,xsc,zl,zsc,tc,wbci)
      end if

      call ctim(ctime4,wtime4)
      ctime_rest = ctime_rest + (ctime4-ctime3)
      wtime_rest = wtime_rest + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4

c-------------------------------------
c     LINEAR PART
c-------------------------------------
c     independent xy planes in z
c     zbp    local index of xy plane
c     ip     thread number
c     zb     start index of box
c     mbz    thickness of box
c-------------------------------------

!$omp parallel do private(zbp,zb,ip)
      do zbp=1,memnz
#ifdef OPENMP
         ip = OMP_GET_THREAD_NUM()+1
#else
         ip = 1
#endif
         zb = my_node_world/nprocx*memnz+zbp
         call linearbl(ur,ui,puw,zb,an,bn,anp1,bnp1,re,pr,alfa,beta,
     &        u0low,u0upp,w0low,w0upp,du0upp,px,ibc,cim,icorr,
     &        bu1jr,bu1ji,prey,h3r(1,ip),h3i(1,ip),
     &        hthr(1,ip),hthi(1,ip),pthr(1,ip),pthi(1,ip),
     &        dthr(1,ip),dthi(1,ip),
     &        u3r(1,ip),u3i(1,ip),om3r(1,ip),om3i(1,ip),
     &        th3r(1,ip),th3i(1,ip),f(1,1,ip),
     &        f(1,1,ip),f(1,2,ip),f(1,3,ip),f(1,4,ip),f(1,5,ip),
     &        f(1,4,ip),f(1,5,ip),f(1,6,ip),f(1,7,ip),
     &        bis(1,1,ip),bis(1,2,ip),
     &        bis(1,3,ip),bis(1,4,ip),bis(1,2,ip),
     &        bis(1,3,ip),bis(1,4,ip),bis(1,1,ip),bis(1,5,ip),
     &        bis(1,6,ip),bis(1,7,ip),bis(1,8,ip),
     &        domyr(1,ip),domyi(1,ip),domyh(1,ip),
     &        omyh(1,ip),d2omyh(1,ip),
     &        vr(1,ip),vi(1,ip),vh(1,ip),vh2(1,ip),
     &        dvr(1,ip),dvi(1,ip),dvh(1,ip),dvh2(1,ip),d2v(1,1,ip),
     &        d2v(1,2,ip),d2v(1,3,ip),d2v(1,4,ip),d2v(1,1,ip),
     &        d2v(1,2,ip),d2v(1,3,ip),homyr(1,ip),homyi(1,ip),
     &        hvr(1,ip),hvi(1,ip),q(1,ip),c(1,ip),d(1,ip),e(1,ip),
     &        w3(1,ip),
     &        wallvr,wallvi,wbci,
     &        wallur,wallui,wallwr,wallwi,v_wall,wlvr,wlvi,
     &        iles,gur,gui,taur,taui,gu3r(1,ip),gu3i(1,ip),
     &        ggu3r(1,ip),ggu3i(1,ip),gsr,gsi,
     &        gth3r(1,ip),gth3i(1,ip),ggth3r(1,ip),ggth3i(1,ip),
     &        gewy1,gewy2,gewy12,gewy22,iord,
     &        diags,diags2,gplane(1,ip),filtxz,filtxz2,
     &        lpfxz,lpfxz2,zbp,ihighorder,cs,my_node_world,tbc,
     &        dtheta0_upp,dtheta0_low,d2th_bc(1,ip),fth_bc(1,ip),
     &        dth3r_bc(1,ip),dth3i_bc(1,ip),
     &        dth3r_bc2(1,ip),dth3i_bc2(1,ip),theta0_low,theta0_upp,
     &        cflux,mflux,vsuc,wallthr,wallthi)
      end do

c-------------------------------------

      call ctim(ctime4,wtime4)
      ctime_linear = ctime_linear + (ctime4-ctime3)
      wtime_linear = wtime_linear + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4
c
c     Pressure solver
c
      if (do_press) then
         if (my_node_world.eq.0) then
            write(*,*) '** Calculate pressure **',
     &           (t+dtn)/dstar,mod(it,nst)
         end if

!$omp parallel do private(ybp,ip,yb,myb)
         do ybp=1,nypp
#ifdef OPENMP
            ip = OMP_GET_THREAD_NUM()+1
#else
            ip = 1
#endif
            yb = (ybp-1)*nprocz+my_node_world/nprocx+1
            myb= (yb-1)/mby+1
            call nonlinp(ur,ui,xsc,yb,rot,spat,fstart,fend,
     &           bu1,bu2,alfa,beta,xl,prex,prez,pres,prea,
     &           u2r(1,ip),u2i(1,ip),om2r(1,ip),om2i(1,ip),
     &           wr(1,ip),wi(1,ip),my_node_world,
     &           my_node_z,my_node_x,my_comm_z,my_comm_x,
     &           realg1,realg2,realg3,realg4,fring1,fring2,
     &           boxr_z,boxi_z,wr_z,wi_z,wr_x,wi_x)
         end do

         do zbp=1,memnz
#ifdef OPENMP
            ip = OMP_GET_THREAD_NUM()+1
#else 
            ip = 1
#endif
            zb = my_node_world/nprocx*memnz+zbp
            
            call linearp(ur,ui,zb,zbp,re,alfa,beta,cim,prey,
     &           h3r(1,ip),h3i(1,ip),
     &           u3r(1,ip),u3i(1,ip),om3r(1,ip),om3i(1,ip),
     &           f(1,1,ip),f(1,1,ip),f(1,2,ip),
     &           bis(1,1,ip),bis(1,2,ip),bis(1,3,ip),
     &           bis(1,2,ip),bis(1,3,ip),
     &           vr(1,ip),vi(1,ip),d2v(1,2,ip),d2v(1,3,ip),
     &           hvr(1,ip),hvi(1,ip),
     &           q(1,ip),c(1,ip),d(1,ip),e(1,ip),
     &           w3(1,ip),rv1r,rv1i,wd1,it,dtn,my_node_world)
         end do
      end if

      call ctim(ctime4,wtime4)
      ctime_press = ctime_press + (ctime4-ctime3)
      wtime_press = wtime_press + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4
c
c     If wall-roughness BCs to be updated during the simulation,
c     i.e. wbci==-1 and updat==T)
c
      if (wbci.eq.-1) then
         write(*,*)'Not Implemented'
         call stopnow(112234)
         if (updat) then 
            if (it.gt.int(50/every)*every*nst) then
c     
c     No update within the first 50 t steps
c
               switch=(it-1)/real(nst*every) 
               if (switch.eq.int(switch)) then
c                  call updatewallrough(ur,ui,
c     &                 xsc,hst,hlen,delh,zl,zsc,it,
c     &                 prexn,prey,prezn,presn,prean,alfa,beta,
c     &                 h_rough,hstart,hend,hrise,hfall,zfunc,qq,
c     &                 tpsi,v_wall,
c     &                 taylor4,monitor,120,my_node_world,
c     &                 wallur,wallui,wlvr,wlvi,wallwr,wallwi)
               end if
            end if
         end if
      end if

      call ctim(ctime4,wtime4)
      ctime_rest = ctime_rest + (ctime4-ctime3)
      wtime_rest = wtime_rest + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4

c---- RK SUB-STEP ITERATION FINISHED

      it=it+1

      if (mod(it-1,nst).eq.0) then
c     if at the end of a full RK step
c      write(*,*) '>>>>>> FULL STEP <<<<<<'
c
c     Update time step and shift of lower wall
c
         t = t + dtn

c     Adjoint time going backwards
c
         if (adjoint) t=t-2*dtn

         xs = xs - dtn*u0low
         zs = zs - dtn*w0low
         if (vart) dtn = dtnp1
c
c     Save velocity field?
c
         file_save=.false.
         if(.not.adjoint)then
            if (t+.5*dtn.gt.tsave(isave)) then
               file_save=.true.   
            end if
         elseif(adjoint)then
            if (t-.5*dtn.lt.tsave(isave)) then
               file_save=.true.
            end if
         end if


         if (file_save.eqv..true.) then
c
c     Check if file already exists
c
            open(unit=11,file=nmsave(isave),form='unformatted',
     &           status='old',iostat=kode)
#ifdef MPI
            if (nproc.gt.1) call mpi_barrier(mpi_comm_world,ierror)
#endif
c
c     If you want to replace files: Uncomment next line
c
            kode = 1
            if (kode.eq.0) then
c
c     File already exists: stop
c
               close(11)
               write(*,*) 'Velocity field already exists: ',
     &              trim(nmsave(isave))
               call stopnow(57584)
            else
c
c     File does not exist: continue
c
               if (my_node_world.eq.0) then
                  write(*,*) '** Write velocity field **',
     &                 t/dstar,isave
               end if

               call wdiscbl(ur,ui,re,pr,m1,xl,zl,t,xs,dstar,
     &              fltype,bstart,
     &              bslope,rlam,spanv,nmsave(isave),3+scalar,gall,
     &              boxr,boxi,urx,alfa,zs,beta,my_node_world,
     &              u0low,u0upp,w0low,w0upp,du0upp)

               if (pressure.eq.1) then
c     
c     Check whether pressure has been computed
c     
                  if (.not.do_press) then
                     if (my_node_world.eq.0) then
                        write(*,*) 'Pressure has not been computed'
                     end if
                     call stopnow(56654547)
                  end if
                  
                  call wdiscp(ur,ui,re,pr,m1,xl,zl,t,xs,dstar,
     &                 fltype,bstart,
     &                 bslope,rlam,spanv,nmsave(isave),gall,
     &                 boxr,boxi,urx,alfa,zs,beta,my_node_world)
                  
               end if

            end if
            isave=isave+1
         end if

         if (my_node_world.eq.0) then
c
c     Writing out internal buffer for logfile
c
c            call cflush(6)
c
c     Writing out internal buffers for amplitude and plane files
c
            if (iamp.gt.0) call cflush(15)
            do i=1,npl
c               call cflush(30+i)
            end do
         end if
      end if

      call ctim(ctime4,wtime4)
      ctime_io = ctime_io + (ctime4-ctime3)
      wtime_io = wtime_io + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4

      if (mod(it-1,nst).eq.0) then
c
c     Start timing for next step...
c
         if (my_node_world.eq.0) then
            call ctim(ctime2,wtime2)
            write(*,'(a,f10.3,a,f10.3,a)') ' CPU time: ',ctime2-ctime1,
     &           ' sec    wall time: ',wtime2-wtime1,' sec'
            write(*,*) '** Simulation time **',t/dstar,
     &           'it: ',it-1
c     
c     Write out step-file
c     writing is done (approximately) every delta_wall_time_int
c     seconds. If positive, also history is written.
c     
            delta_wall_time = delta_wall_time + wtime2-wtime1
            
            if (delta_wall_time.gt.abs(delta_wall_time_int)) then
               delta_wall_time = 0.
               open(file='step.out',unit=87)
               write(87,'(a20,f18.9,a,f18.9,a)') 'Time now: ',t/dstar,
     &              ' (max. ',tmax/dstar,')'
               write(87,'(a20,f18.9)') 'Started with: ',sttimet/dstar
               write(87,'(a20,f18.9)') 'Delta: ',(t-sttimet)/dstar
               write(87,'(a20,i18,a,i18,a)') 'Iteration: ',it-1,
     &              ' (max. ',maxit,')'
               call time_string(timdat)
               write(87,'(a20,a20)') 'Time now: ',timdat
               write(87,'(a20,a20)') 'Started: ',sttimec
               write(87,'(a,f18.9,a,f18.9,a)') 'CPU time       ',
     &              ctime2-ctime0,
     &              ' seconds (max. ',cpumax,')'
               write(87,'(a,f18.9,a,f18.9,a)') 'Wallclock time ',
     &              wtime2-wtime0,
     &              ' seconds (max. ',wallmax,')'
               write(87,'(a,f18.9,a)') 'Last time step ',ctime2-ctime1,
     &              ' seconds (CPU time)'
               write(87,'(a,f18.9,a)') 'Last time step ',wtime2-wtime1,
     &              ' seconds (wallclock time)'
               close(87)
c
c     History file
c
               if (delta_wall_time_int.gt.0) then
                  open(file='history.out',position='append',unit=87)
                  write(87,'(f18.9,a25,f30.3)') t/dstar,timdat,wtime2
                  close(87)
               end if
            end if

            ctime1=ctime2
            wtime1=wtime2
c
c     Decide iteration loop break criteria (only on node 0)
c
            stop_now = 0 
         
c
c     Stop only if statistics have been taken
c
            if (ixys.gt.0.and.t.ge.txys.and.mod(it-1,ixys).ne.0) then
            else

            ! Check stop.now file
            open(unit=11,file='stop.now',status='old',iostat=kode)
            if (kode.eq.0) then
               close(11)
               stop_now = 1
               write(*,*) 'STOP DUE TO stop.now FILE'
            end if

            ! Check cpu time
            if (cpumax.gt.0) then
               if ((ctime2-ctime0).gt.cpumax) then
                  stop_now = 1
                  write(*,*) 'STOP DUE TO CPU TIME'
               end if
            end if

            ! Check wall time
            if (wallmax.gt.0) then
               if ((wtime2-wtime0).gt.wallmax) then
                  stop_now = 1
                  write(*,*) 'STOP DUE TO WALL TIME'
               end if
            end if

            ! Check iterations
            if (maxit.gt.0) then
               if (it-1.ge.maxit) then
                  stop_now = 1
                  write(*,*) 'STOP DUE TO ITERATIONS'
               end if
            end if

            ! Check integration time
            if (.not.adjoint) then
               if (t+.5*dtn.gt.tmax) then
                  stop_now = 1
                  write(*,*) 'STOP DUE TO INTEGRATION TIME'
               end if
            end if
            if (adjoint) then
               if (t-.5*dtn.lt.tmax) then
                  stop_now = 1
                  write(*,*) 'ADJOINT STOP DUE TO INTEGRATION TIME'
               end if
            end if
         end if

         end if
#ifdef MPI
c
c     Communicate break criterion
c
         if (nproc.gt.1) then
            call mpi_bcast(stop_now,1,mpi_integer4,0,mpi_comm_world,
     &           ierror)
         end if
#endif

      end if
c     
c     Continue integration for stop_now=0
c
      if (stop_now.eq.0) then
         goto 1
      end if

c------------------------------------
c>>>>>>   END OF INTEGRATION   <<<<<<
c------------------------------------

      if (my_node_world.eq.0) then
         write(*,*) '** Stop iteration **',t/dstar
      end if

      call ctim(ctime4,wtime4)
      ctime_rest = ctime_rest + (ctime4-ctime3)
      wtime_rest = wtime_rest + (wtime4-wtime3)
      ctime3=ctime4
      wtime3=wtime4
c
c     Do all the work after time integration
c     (note that one could do some statistics)
c
c     Write statistics
c
      if (ixys.gt.0.and.sumw.gt.0.) then 

         if (.not. adjoint) then
            if (t.ge.txys) then
               do_stat = .true.
            end if
         else
            do_stat =.true.
         end if


         if (my_node_world.eq.0) then
            write(*,*) '** Write statistics **', t/dstar,sumw/dstar
         end if
         call wxys(xys,xysth,my_comm_z,my_comm_x,
     &        totcorr,corr,ncorr,corrf,
     &        totcorr_ms,corr_ms,
     &        totcorr_x,corr_x,ncorr_x,corrf_x,
     &        totcorr_ms_x,corr_ms_x,
     &        my_node_world,
     &        series,serf,nser,totseries,
     &        sumw,re,xl,zl,t,dstar,fltype,
     &        bstart,bslope,rlam,spanv,namxys,wxy,
     &        corrnam,corrxx,corryy,corrwsave,
     &        corrx,corry,corrxi,corryi,pr,m1,corrt,
     &        corrnam_x,corrzz,corryy_x,corrwsave_x,
     &        corrz,corry_x,corrzi,corryi_x,corrt_x,
     &        nsamp,namser,sercount,mhd_n,b0)
         sercount = 0
      end if
c
c     Write end velocity field
c
      if (my_node_world.eq.0) then
         write(*,*) '** Write field **', t/dstar
      end if
      call wdiscbl(ur,ui,re,pr,m1,xl,zl,t,xs,dstar,fltype,
     &     bstart,bslope,rlam,spanv,namnut,3+scalar,gall,
     &     boxr,boxi,urx,alfa,zs,beta,my_node_world,
     &     u0low,u0upp,w0low,w0upp,du0upp)

      if (pressure.eq.1) then
c     
c     Only write pressure file if it has been computed
c     
         if (.not.do_press) then
            if (my_node_world.eq.0) then
               write(*,*) 'Pressure has not been computed'
            end if
         else
c            call wdiscp(ur,ui,re,pr,m1,xl,zl,t,xs,dstar,
c     &           fltype,bstart,
c     &           bslope,rlam,spanv,namnut,gall,
c     &           boxr,boxi,urx,alfa,zs,beta,my_node_world)
         end if
      end if

      if (isfd.eq.1) then
c
c     Write out low-pass filtered velocity field
c
         if (my_node_world.eq.0) then
            write(*,*) '** Write SFD field **', t/dstar
         end if
         namnut_sfd = trim(namnut)//'.sfd'
         call wdiscbl(sfdur,sfdui,re,pr,m1,xl,zl,t,xs,dstar,fltype,
     &        bstart,bslope,rlam,spanv,namnut_sfd,3,gall,
     &        boxr,boxi,urx,alfa,zs,beta,my_node_world,
     &        u0low,u0upp,w0low,w0upp,du0upp)

         
      end if
c
c     Close open files
c
      if (my_node_world.eq.0) then
         if (iamp.gt.0) close(unit=15)
         if (mwave.gt.0) close(unit=16)
         if (iext.gt.0) close(unit=18)
         do i=1,npl
            close(unit=30+i)
         end do
      end if
c
c     Write summary
c
      if (my_node_world.eq.0) then
         call ctim(ctime4,wtime4)
         ctime_end = ctime4-ctime3
         wtime_end = wtime4-wtime3

#ifdef OPENMP
         ompnproc=OMP_GET_NUM_PROCS()
         ompmaxthreads=OMP_GET_MAX_THREADS()
#else
         ompnproc = 1
         ompmaxthreads = 1
#endif

         write(*,*)
         write(*,*)
         write(*,*) '>>>>>>  Summary  <<<<<<'
         write(*,*) '--------------------------------------------'//
     &              '-----------------------'
         write(*,*)
         write(*,'(a23,f18.9)') ' Time now             :',t/dstar
         write(*,'(a23,f18.9)') ' Started with         :',sttimet/dstar
         write(*,'(a23,f18.9)') ' Delta                :',
     &                          (t-sttimet)/dstar
         write(*,'(a23,i6)') ' Iterations           :',it-1
         call time_string(timdat)
         write(*,'(a24,a20)') ' Started              : ',sttimec
         write(*,'(a24,a20)') ' Ended                : ',timdat
         write(*,*)
         write(*,*) 'Total CPU time       :',ctime4-ctime0,' seconds'
         write(*,*) 'Total wallclock time :',wtime4-wtime0,' seconds'
         write(*,*) 'Average time step    :',
     &              (wtime4-wtime0-wtime_startup-wtime_end)
     &        /real(it-1)*nst
         write(*,*)
         
         write(*,'(a,i4,a)') ' Compiled for         :',nproc,
     &        ' processors'
         write(*,'(a,i4,a)') '                      :',nthread,
     &        ' threads'
         write(*,'(a,i4,a)') ' Running on           :',ompnproc,
     &              ' OMP processors'
         write(*,'(a,i4,a)') ' Running on           :',all_nodes_world,
     &              ' MPI processors.'
         write(*,'(a,i4,a)') ' Running with max.    :',ompmaxthreads,
     &              ' OMP threads'
         write(*,*)
         write(*,'(a,3a20)')   '             ','Wall time','CPU time',
     &        'Wall time per it.'
         write(*,'(a,3f20.8)') ' LES        : ',
     &        wtime_les,ctime_les,wtime_les/real(it-1)*nst
         write(*,'(a,3f20.8)') ' tau_ij     : ',
     &        wtime_tau,ctime_tau,wtime_tau/real(it-1)*nst
         write(*,'(a,3f20.8)') ' statistics : ',
     &        wtime_stat,ctime_stat,wtime_stat/real(it-1)*nst
         write(*,'(a,3f20.8)') ' nonlin     : ',
     &        wtime_nonlin,ctime_nonlin,wtime_nonlin/real(it-1)*nst
         write(*,'(a,3f20.8)') ' linear     : ',
     &        wtime_linear,ctime_linear,wtime_linear/real(it-1)*nst
         write(*,'(a,3f20.8)') ' IO         : ',
     &        wtime_io,ctime_io,wtime_io/real(it-1)*nst
         write(*,'(a,3f20.8)') ' trip       : ',
     &        wtime_trip,ctime_trip,wtime_trip/real(it-1)*nst
         write(*,'(a,3f20.8)') ' ffun+mhd   : ',
     &        wtime_ffun,ctime_ffun,wtime_ffun/real(it-1)*nst
         write(*,'(a,3f20.8)') ' CFL        : ',
     &        wtime_cfl,ctime_cfl,wtime_cfl/real(it-1)*nst
         write(*,'(a,3f20.8)') ' planes     : ',
     &        wtime_planes,ctime_planes,wtime_planes/real(it-1)*nst
         write(*,'(a,3f20.8)') ' press      : ',
     &        wtime_press,ctime_press,wtime_press/real(it-1)*nst
         write(*,'(a,3f20.8)') ' rest       : ',
     &        wtime_rest,ctime_rest,wtime_rest/real(it-1)*nst
         write(*,'(a,2f20.8)') ' startup    : ',
     &        wtime_startup,ctime_startup
         write(*,'(a,2f20.8)') ' shutdown   : ',
     &        wtime_end,ctime_end
         write(*,'(a,3f20.8)') ' sum        : ',
     &        wtime_stat+wtime_nonlin+wtime_linear+wtime_io+
     &        wtime_startup+wtime_end+wtime_les+wtime_tau+
     &        wtime_rest+wtime_trip+wtime_ffun+wtime_cfl+
     &        wtime_planes+wtime_press,
     &        ctime_stat+ctime_nonlin+ctime_linear+ctime_io+
     &        ctime_startup+ctime_end+ctime_les+ctime_tau+
     &        ctime_rest+ctime_trip+ctime_ffun+ctime_cfl+
     &        ctime_planes+ctime_press,
     &        (wtime_stat+wtime_nonlin+wtime_linear+wtime_io+
     &        wtime_les+wtime_tau+
     &        wtime_rest+wtime_trip+wtime_ffun+wtime_cfl+
     &        wtime_planes+wtime_press)/real(it-1)*nst
         write(*,'(a,3f20.8)') ' nl(com,ser): ',tcom,tser,tcom+tser
c
c     Write final step file
c
         open(file='step.out',unit=87)
         write(87,*) '** Finished **'
         write(87,'(a22,f18.9)') ' Time now             : ',t/dstar
         write(87,'(a22,f18.9)') ' Started with         : ',
     &                           sttimet/dstar
         write(87,'(a22,f18.9)') ' Delta                : ',
     &                           (t-sttimet)/dstar
         write(87,'(a23,i6)') ' Iterations           : ',it-1
         write(87,'(a24,a20)') ' Started              : ',sttimec
         write(87,'(a24,a20)') ' Ended                : ',timdat
         write(87,*)
         write(87,*) 'Total CPU time       :',ctime4-ctime0,' seconds'
         write(87,*) 'Total wallclock time :',wtime4-wtime0,' seconds'
         write(87,*) 'Average time step    :',
     &               (wtime4-wtime0-wtime_startup-wtime_end)
     &        /real(it-1)*nst
         write(87,*)
         write(87,'(a,i4,a)') ' Compiled for         :',nproc,
     &        ' processors'
         write(87,'(a,i4,a)') '                      :',nthread,
     &        ' threads'
         write(87,'(a,i4,a)') ' Running on           :',ompnproc,
     &              ' OMP processors'
         write(87,'(a,i4,a)') ' Running on           :',all_nodes_world,
     &              ' MPI processors.'
         write(87,'(a,i4,a)') ' Running with max.    :',ompmaxthreads,
     &              ' OMP threads'
         write(87,*)
         write(87,'(a,3a20)')   '             ','wall time','CPU time',
     &        'Wall time per it.'
         write(87,'(a,3f20.8)') ' LES        : ',
     &        wtime_les,ctime_les,wtime_les/real(it-1)*nst
         write(87,'(a,3f20.8)') ' tau_ij     : ',
     &        wtime_tau,ctime_tau,wtime_tau/real(it-1)*nst
         write(87,'(a,3f20.8)') ' statistics : ',
     &        wtime_stat,ctime_stat,wtime_stat/real(it-1)*nst
         write(87,'(a,3f20.8)') ' nonlin     : ',
     &        wtime_nonlin,ctime_nonlin,wtime_nonlin/real(it-1)*nst
         write(87,'(a,3f20.8)') ' linear     : ',
     &        wtime_linear,ctime_linear,wtime_linear/real(it-1)*nst
         write(87,'(a,3f20.8)') ' IO         : ',
     &        wtime_io,ctime_io,wtime_io/real(it-1)*nst
         write(87,'(a,3f20.8)') ' trip       : ',
     &        wtime_trip,ctime_trip,wtime_trip/real(it-1)*nst
         write(87,'(a,3f20.8)') ' ffun+mhd   : ',
     &        wtime_ffun,ctime_ffun,wtime_ffun/real(it-1)*nst
         write(87,'(a,3f20.8)') ' CFL        : ',
     &        wtime_cfl,ctime_cfl,wtime_cfl/real(it-1)*nst
         write(87,'(a,3f20.8)') ' planes     : ',
     &        wtime_planes,ctime_planes,wtime_planes/real(it-1)*nst
         write(87,'(a,3f20.8)') ' press      : ',
     &        wtime_press,ctime_press,wtime_press/real(it-1)*nst
         write(87,'(a,3f20.8)') ' rest       : ',
     &        wtime_rest,ctime_rest,wtime_rest/real(it-1)*nst
         write(87,'(a,2f20.8)') ' startup    : ',
     &        wtime_startup,ctime_startup
         write(87,'(a,2f20.8)') ' shutdown   : ',
     &        wtime_end,ctime_end
         write(87,'(a,3f20.8)') ' sum        : ',
     &        wtime_stat+wtime_nonlin+wtime_linear+wtime_io+
     &        wtime_startup+wtime_end+wtime_les+wtime_tau+
     &        wtime_rest+wtime_trip+wtime_ffun+wtime_cfl+
     &        wtime_planes+wtime_press,
     &        ctime_stat+ctime_nonlin+ctime_linear+ctime_io+
     &        ctime_startup+ctime_end+ctime_les+ctime_tau+
     &        ctime_rest+ctime_trip+ctime_ffun+ctime_cfl+
     &        ctime_planes+ctime_press,
     &        (wtime_stat+wtime_nonlin+wtime_linear+wtime_io+
     &        wtime_les+wtime_tau+
     &        wtime_rest+wtime_trip+wtime_ffun+wtime_cfl+
     &        wtime_planes+wtime_press)/real(it-1)*nst
         write(87,'(a,3f20.8)') ' nl(com,ser): ',tcom,tser,tcom+tser
         
         close(87)

         write(*,*)
         write(*,*) 'bla terminated normally.'
      end if
c
c     Finalize program
c
#ifdef MPI
      call mpi_barrier(mpi_comm_world,ierror)
      call mpi_finalize(ierror)
#endif

      end program bla
