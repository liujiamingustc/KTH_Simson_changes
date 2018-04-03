c ***********************************************************************
c
c $HeadURL: https://www.mech.kth.se/svn/simson/branches/bla2dparallel/rparambl.f $
c $LastChangedDate: 2011-10-15 11:54:32 +0200 (Sat, 15 Oct 2011) $
c $LastChangedBy: pschlatt@MECH.KTH.SE $
c $LastChangedRevision: 1747 $
c
c ***********************************************************************
      subroutine rparambl(namnin,namnut,
     &     tmax,dt,dtmax,vart,nst,varsiz,rot,cdev,
     &     loctyp,fp1,fpds1,fpds2,fpds3,fpds4,fpds5,fpds6,fpds7,fpds8,
     &     fpdds1,fpdds2,fpdds3,fpdds4,fpdds5,
     &     wbci,wp1,wp2,
     &     wpds1,wpds2,wpds3,wpds4,wpds5,
     &     wpds6,wpds7,wpds8,wpds9,wpds10,wpds11,wpds12,
     &     wpdds1,wpdds2,wallroughinput,
     &     tripf,tamps,tampt,txsc,tysc,nzt,tdt,seed,tx0,
     &     tsave,nmsave,nsave,cflmax,icfl,iamp,namamp,longli,ibc,cim,
     &     icorr,spat,tabfre,namfre,rbfl,nambfl,gall,
     &     fmax,fstart,fend,frise,ffall,ampob,amp2d,osmod,osdamp,osamp,
     &     osfil,iext,namext,ixys,ixyss,namxys,txys,maxit,kx,
     &     kz,mwave,nwave,namwav,
     &     ipl,nampl,npl,tpl,cpl,mpl,xl,cpumax,wallmax,
     &     corrf,corrf_x,corrnam,corrnam_x,corrx,corry,corrz,corry_x,
     &     corrt,corrt_x,ncorr,ncorr_x,write_inter,namnut_inter,
     &     my_node,suction,asbl,vsuc,
     &     streak,iampst,ampst,tsmoo,tsmst,tsmend,phist,
     &     str_nam1,str_nam2,isfd,sfd_delta,sfd_chi,sfdzero,namnut_sfd,
     &     sgs,waves,waamp,wamoo,wamst,waiamp,pert,lin,
     &     namser,serc,sert,serf,nser,tbc,
     &     dtheta0_upp,dtheta0_low,theta0_low,theta0_upp,cflux,retau,
     &     iimhd,imhd,b0,mhd_n,fileurms,bf3,bf3nam,     
     &     jet_prof,jet_diam,xjet,zjet,jetmag,
     &     adjoint)
c
c     Reads the parameter file bla.i
c
      implicit none

      include 'par.f'

      real pi
      parameter (pi = 3.1415926535897932385)

      logical adjoint
      logical vart,varsiz,longli,spat,icorr,cim,gall
      logical tabfre,rbfl,osmod,osdamp,write_inter,fileurms
      integer nsave,icfl,iamp,ixys,ixyss,maxit
      integer nwave,mwave,kx(nwave),kz(nwave)
      integer ipl,npl,mpl,tpl(mpl,3),nst,iext,ibc
      real tmax,dt,dtmax,tsave(nsave),cflmax,cpl(mpl),rot,cdev,txys
      integer loctyp,wbci
      real fp1,fpds1,fpds2,fpds3,fpds4,fpds5,fpds6,fpds7
      real fpds8,fpdds1,fpdds2,fpdds3,fpdds4,fpdds5
      real wp1,wp2,wpds1,wpds2,wpds3,wpds4,wpds5
      real wpds6,wpds7,wpds8,wpds9,wpds10,wpds11,wpds12
      real wpdds1,wpdds2
      logical tripf,endc
      real tamps,tampt,txsc,tysc,tdt,tx0,xl,cpumax,osamp
      real wallmax
      integer nzt,seed,j
      real fmax,fstart,fend,frise,ffall,ampob,amp2d
      character*80 nmsave(nsave),namnin,namnut,namamp,namwav,nampl(mpl)
      character*80 namext,namxys,namfre,nambfl,namnut_inter,osfil
      logical suction,asbl,sgs,cflux
      real vsuc,cflmaxin,retau
c
c     Selective Frequency Damping (SFD)
c
      integer isfd
      real sfd_delta
      real sfd_chi
      logical sfdzero
      character*80 namnut_sfd
c
c     Perturbation
c
      logical lin,pert

c
c     3D base flow
c
      logical bf3
      character*80 bf3nam
c
c     Boundary conditions for scalar fields
c     
      integer tbc(scalar),ith
      real dtheta0_upp(scalar),dtheta0_low(scalar)
      real theta0_low(scalar),theta0_upp(scalar)
c
c     Linear sinuosoidal streaks in fringe
c
      logical streak
      real iampst,ampst(2),tsmoo(4),tsmst(2),tsmend(2),phist
      character*80 str_nam1,str_nam2
c
c     Waves in fringe (waves)
c
      logical waves
      real waamp,wamoo,wamst,waiamp
c
c     Wall roughness (wbci==-1)
c
      character*80 wallroughinput
c
c     Two-point correlation
c
      character*80 corrnam,corrnam_x
      real corrx(mcorr), corry(mcorr)
      real corrz(mcorr), corry_x(mcorr)
      integer corrt(mcorr),corrt_x(mcorr)
      logical corrf,corrf_x
      integer ncorr,ncorr_x
c
c     File version
c
      integer version,version_bla
c
c     Time series
c
      character(len=80) namser
      real serc(3,mser)
      integer sert(mser)
      logical serf
      integer nser
c
c     Saving of intermediate vel. fields
c
      integer sign
      real omga
c
c     MHD
c
      integer iimhd,imhd
      real b0(3),mhd_n,fact
c
c     MPI
c
      integer my_node

      integer i,large,msave
      parameter (large=1000000)
c
c     Jet in crossflow (wbci==-2)
c
      real jet_diam,xjet,zjet,jetmag
      integer jet_prof

      endc = .false.
c
c     Reads parameters from bla.i
c
      open(unit=10,status='old',file='bla.i')
c
c     Reads in version
c
      call comment(10)
      read(10,*) version
      version_bla=20070716
      if (version.ne.version_bla) then
         write(*,*) 'Wrong version of bla.i, now: ',version
         write(*,*) 'bla version is: ',version_bla
         call stopnow(345431)
      end if
c
c     Flow field names
c
      call comment(10)
      read(10,'(a)') namnin
      if (my_node.eq.0) then
         write(*,*)
         write(*,*)
         write(*,*) '>>>>>>  Parameters read from bla.i <<<<<<<'
         write(*,*) '--------------------------------------------'//
     &              '-----------------------'
         write(*,*) 'Version of input file (version)      : ',version
         write(*,*) 'Initial field (namnin)               : ',
     &        trim(namnin)
      end if

      call comment(10)
      read(10,'(a)') namnut
      if (my_node.eq.0) then
         write(*,*) 'End field (namnut)                   : ',
     &        trim(namnut)
      end if
c
c     Read final simulation time (tmax)
c
      call comment(10)
      read(10,*) tmax
      if (my_node.eq.0) then
         write(*,*) 'Final simulation time (tmax)         :',tmax
      end if
c
c     Maximum number of iterations (maxit)
c
      call comment(10)
      read(10,*) maxit
      maxit=max(maxit,0)
      if (my_node.eq.0) then
         write(*,*) 'Maximum number of iterations (maxit) :',maxit
      end if
c
c     Maximum available cpu time (cpumax)
c
      call comment(10)
      read(10,*) cpumax
      cpumax=max(cpumax,0.)
      if (my_node.eq.0) then
         write(*,*) 'Maximum available cpu time (cpumax)  :',cpumax
      end if
c
c     Maximum wall time (wallmax)
c
      call comment(10)
      read(10,*) wallmax
      wallmax=max(wallmax,0.)
      if (my_node.eq.0) then
         write(*,*) 'Maximum wall time (wallmax)          :',wallmax
      end if
c
c     Write intermediate velocity fields (write_inter)
c
      call comment(10)
      read(10,*) write_inter
      if (my_node.eq.0) then
         write(*,*) 'Write intermed. vel. (write_inter)   :',write_inter
      end if
      if (write_inter) then
         namnut_inter = namnut
         if (my_node.eq.0) then
            write(*,*) '   Intermediate velocity fields to ',
     &           trim(namnut_inter)
         end if
      end if
c
c     Time step
c
      call comment(10)
      read(10,*) dt
      if (my_node.eq.0) then
         write(*,*) 'Time step (dt)                       :',dt
      end if
c
c     Time integration method (nst)
c
      call comment(10)
      read(10,*) nst
      if (my_node.eq.0) then
         write(*,*) 'Time integration method (nst)        :',nst
      end if
c
c     CFL number (fraction of maximum possible time step)
c
      call comment(10)
      read(10,*) cflmaxin
      if (my_node.eq.0) then
         write(*,*) 'CFL number (cflmaxin)                :',cflmaxin
      end if
c
c     Box size (xl)
c
      call comment(10)
      read(10,*) xl
      if (my_node.eq.0) then
         write(*,*) 'Box size (xl)                        :',xl
      end if
c
c     Allow different resolutions in file (varsiz)
c
      call comment(10)
      read(10,*) varsiz
      if (my_node.eq.0) then
         write(*,*) 'Allow different res. in file (varsiz):',varsiz
      end if
c
c     Rotation (rot)
c
      call comment(10)
      read(10,*) rot
      if (my_node.eq.0) then
         write(*,*) 'Rotation (rot)                       :',rot
      end if
c
c     Constant massflux (cflux)
c
      call comment(10)
      read(10,*) cflux
      if (my_node.eq.0) then
         write(*,*) 'Constant mass flux (cflux)           :',cflux
      end if
      retau = 0.
      if (cflux) then
      else
         call comment(10)
         read(10,*) retau
         if (my_node.eq.0) then
            write(*,*) 'Re_tau (retau)                       :',retau
         end if
      end if
c
c     Perturbation equation
c
      call comment(10)
      read(10,*) pert
      if (my_node.eq.0) then
         write(*,*) 'Perturbation equations               :',pert
      end if
      if (pressure.eq.1.and.pert) then
         if (my_node.eq.0) then
            write(*,*) 'Pressure solver and perturbation code'
            write(*,*) 'not implemented yet.'
         end if
         call stopnow(54543532)
      end if
      lin=.false.
      bf3=.false.
      if (pert) then
         call comment(10)
         read(10,*) lin
         if (my_node.eq.0) then
            write(*,*) '   Linearized equations              :',lin
         end if
      end if
c
c     3D base flow
c
      if (pert) then
         call comment(10)
         read(10,*) bf3
         if (bf3) then
            call comment(10)
            read(10,'(a)') bf3nam
         end if
         if (my_node.eq.0) then
            write(*,*) '   3D base flow                      :',bf3
            if (bf3) then
               write(*,*) '      bf3nam : ',trim(bf3nam)
            end if
         end if
      end if
c     Adjoint variable check! (only for lin)
      if(adjoint) then
         if(.not.lin) then
            write(*,*)'Adjoint of nonlinear equations',
     &           'not implemented !'
            write(*,*)'Use lin=.true. and pert=.true.'
            call stopnow(1241123)
         end if
         if (rot.ne.0.) then
            write(*,*)'Adjoint with rotation not implemented!'
            call stopnow(1241124)
         end if
      endif
c
c     Freestream boundary condition (ibc)
c
      call comment(10)
      read(10,*) ibc
      if (my_node.eq.0) then
         write(*,*) 'Freestream boundary condition (ibc)  :',ibc
      end if
c
c     Boundary conditions for scalar
c
      tbc = 0
      dtheta0_low = -999.
      dtheta0_upp = -999.
      theta0_low  = -999.
      theta0_upp  = -999.
      do ith=1,scalar
         call comment(10)
         read(10,*) tbc(ith)
         if (my_node.eq.0) then
            write(*,'(a,i3,a,i3)') ' B.c. (tbc) for scalar No. ',
     &           ith,'        :',tbc(ith)
         end if
c
c     tbc   wall                    freestream
c     0      theta =  theta0_low    theta =  theta0_upp
c     1     Dtheta = dtheta0_low    theta =  theta0_upp
c     2      theta =  theta0_low   Dtheta = dtheta0_upp
c     3     Dtheta = dtheta0_low   Dtheta = dtheta0_upp
c
c     The values for the boundary conditions are read in from bla.i.
c     There is however no sanity check with respect to fsc or bls.
c         
c     Note that the present initial condition (via fsc) does not allow
c     a specification of the freestream derivative, so it needs to
c     be set to zero here. 
c
c     For tbc=3 the additional value of theta0_upp must be given which
c     corresponds to a constant translation of the scalar value 
c     (possible due to linearity). The same value could in principle
c     be given for tbc=2, but only for the homogeneous Neumann condition
c     (which is however always the case, see above).
c
         if (tbc(ith).eq.0) then
            call comment(10)
            read(10,*) theta0_low(ith)
            call comment(10)
            read(10,*) theta0_upp(ith)
            if (my_node.eq.0) then
               write(*,*) '   Value of scalar at lower boundary: ',
     &              theta0_low(ith)
               write(*,*) '   Value of scalar at upper boundary: ',
     &              theta0_upp(ith)
            end if
         else if (tbc(ith).eq.1) then
            call comment(10)
            read(10,*) dtheta0_low(ith)
            call comment(10)
            read(10,*) theta0_upp(ith)
            if (my_node.eq.0) then
               write(*,*) '   Derivative of scalar at lower boundary: ',
     &              dtheta0_low(ith)
               write(*,*) '   Value of scalar at upper boundary: ',
     &              theta0_upp(ith)
            end if
         else if (tbc(ith).eq.2) then
            call comment(10)
            read(10,*) theta0_low(ith)
            call comment(10)
            read(10,*) dtheta0_upp(ith)
            if (my_node.eq.0) then
               write(*,*) '   Value of scalar at lower boundary: ',
     &              theta0_low(ith)
               write(*,*) '   Derivative of scalar at upper boundary: ',
     &              dtheta0_upp(ith)
            end if
            theta0_upp(ith) = 0.
         else if (tbc(ith).eq.3) then
            call comment(10)
            read(10,*) dtheta0_low(ith)
            call comment(10)
            read(10,*) dtheta0_upp(ith)
            call comment(10)
            read(10,*) theta0_upp(ith)
            if (my_node.eq.0) then
               write(*,*) '   Derivative of scalar at lower boundary: ',
     &              dtheta0_low(ith)
               write(*,*) '   Derivative of scalar at upper boundary: ',
     &              dtheta0_upp(ith)
               write(*,*) '   Value of scalar at upper boundary: ',
     &              theta0_upp(ith)
            end if
         else
            if (my_node.eq.0) then
               write(*,*) 'tbc not valid.'
            end if
            call stopnow(56533)
         end if
      end do
c
c     Integration method (cim) (otherwise tau method)
c
      call comment(10)
      read(10,*) cim
      if (my_node.eq.0) then
         write(*,*) 'Integration method (cim)             :',cim
      end if
      icorr=.false.
      if (cim) then
         call comment(10)
         read(10,*) icorr
         if (my_node.eq.0) then
            write(*,*) ' - cim correction (icorr)            :',icorr
         end if
      end if
      do ith=1,scalar
         if(tbc(ith).gt.0.and.cim) then
            write(*,*)'tbc >0 and cim not implemented!'
            write(*,*)'Use cim=.false.'
            call stopnow(1230123)
         end if
      end do
c
c     Galileo transform (gall)
c
      call comment(10)
      read(10,*) gall
      if (my_node.eq.0) then
         write(*,*) 'Galileo transform (gall)             :',gall
      end if
c
c     Suction
c
      suction = .false.
      asbl = .false.
      vsuc = 0.
      call comment(10)
      read(10,*) suction
      if (my_node.eq.0) then
         write(*,*) 'Suction (suction)                    :',suction
      end if
      if (suction) then
c
c     Asymptotic suction boundary layer
c
         call comment(10)
         read(10,*) asbl
         if (my_node.eq.0) then
            write(*,*) '   ASBL (asbl)                       :',asbl
         end if
         if (asbl) then
c
c     Asymptotic suction, vsuc is defined later
c
         else
c
c     Suction rate
c
            call comment(10)
            read(10,*) vsuc
            if (my_node.eq.0) then
               write(*,*) '      Suction rate (vsuc)            :',vsuc
            end if
         end if
      end if
c
c     Spatial simulation (spat)
c
      call comment(10)
      read(10,*) spat
      if (my_node.eq.0) then
         write(*,*) 'Spatial simulation (spat)            :',spat
      end if
      cdev=0.0
      ampob=0.
      amp2d=0.
      osmod=.false.
      streak=.false.
      waves=.false.
      seed=-1
      rbfl=.false.
      tabfre=.false.
      if (spat) then
         call comment(10)
         read(10,*) tabfre
         if (tabfre) then
            call comment(10)
            read(10,'(a)') namfre
         end if
         call comment(10)
         read(10,*) rbfl
         if (rbfl) then
            call comment(10)
            read(10,'(a)') nambfl
         end if
         call comment(10)
         read(10,*) fmax
         call comment(10)
         read(10,*) fstart
         call comment(10)
         read(10,*) fend
         call comment(10)
         read(10,*) frise
         call comment(10)
         read(10,*) ffall
         call comment(10)
         read(10,*) ampob
         call comment(10)
         read(10,*) amp2d
         call comment(10)
         read(10,*) osmod
         if (osmod) then
            call comment(10)
            read(10,*) osdamp
            call comment(10)
            read(10,*) osamp
            call comment(10)
            read(10,*) osfil
         end if
         if (my_node.eq.0) then
            write(*,*) '   tabfre  ',tabfre
            if (tabfre) write(*,*) '   namfre  ',trim(namfre)
            write(*,*) '   rbfl    ',rbfl
            if (rbfl) write(*,*) '   nambfl  ',trim(nambfl)
            write(*,*) '   fmax    ',fmax
            write(*,*) '   fstart  ',fstart
            write(*,*) '   fend    ',fend
            write(*,*) '   frise   ',frise
            write(*,*) '   ffall   ',ffall
            write(*,*) ' - ampob   ',ampob
            write(*,*) '   amp2d   ',amp2d
            write(*,*) ' - osmod   ',osmod
            if (osmod) then
               write(*,*) '   osdamp  ',osdamp
               write(*,*) '   osamp   ',osamp
               write(*,*) '   osfil  ',trim(osfil)
            end if
         end if
c
c     Read streak parameters
c
         call comment(10)
         read(10,*) streak
         if (my_node.eq.0) then
            write(*,*) ' - Streak (streak)                   :',streak
         end if
         if (streak) then
            call comment(10)
            read(10,*) str_nam1
            call comment(10)
            read(10,*) ampst(1)
            call comment(10)
            read(10,*) tsmoo(1)
            call comment(10)
            read(10,*) tsmoo(2)
            call comment(10)
            read(10,*) tsmst(1)
            call comment(10)
            read(10,*) tsmend(1)
            call comment(10)
            read(10,*) iampst            
            call comment(10)
            read(10,*) str_nam2
            call comment(10)
            read(10,*) ampst(2)
            call comment(10)
            read(10,*) tsmoo(3)
            call comment(10)
            read(10,*) tsmoo(4)
            call comment(10)
            read(10,*) tsmst(2)
            call comment(10)
            read(10,*) tsmend(2)
            call comment(10)
            read(10,*) phist
            if (my_node.eq.0) then
               write(*,*) '    - Streak one: '
               write(*,*) '      Input file ',trim(str_nam1)
               write(*,*) '      Amplitude (ampst) ',ampst(1)
               write(*,*) '      Length of smooth turn on (tsmoo) ',
     &              tsmoo(1)
               write(*,*) '      Length of smooth turn off (tsmoo) ',
     &              tsmoo(2)
               write(*,*) '      Start of smooth turn on (tsmst) ',
     &              tsmst(1)
               write(*,*) '      Start of smooth turn off (tsmend) ',
     &              tsmend(1)
               write(*,*) '      Initial amp. of streak (iampst) ',
     &              iampst
               write(*,*) '    - Streak two: '
               write(*,*) '      Input file ',trim(str_nam2)
               write(*,*) '      Amplitude (ampst) ',ampst(2)
               write(*,*) '      Length of smooth turn on (tsmoo) ',
     &              tsmoo(3)
               write(*,*) '      Length of smooth turn off (tsmoo) ',
     &              tsmoo(4)
               write(*,*) '      Start of smooth turn on (tsmst) ',
     &              tsmst(2)
               write(*,*) '      Start of smooth turn off (tsmend) ',
     &              tsmend(2)
               write(*,*) '    - Relative phase(/pi) of streaks (phist)'
     &              ,phist
            end if
         end if
c
c     Waves in fringe (waves)
c
         call comment(10)
         read(10,*) waves
         if (my_node.eq.0) then
            write(*,*) ' - Waves (waves)                     :',waves
         end if
         if (waves) then
            call comment(10)
            read(10,*) waamp
            call comment(10)
            read(10,*) wamoo
            call comment(10)
            read(10,*) wamst
            call comment(10)
            read(10,*) waiamp
            if (my_node.eq.0) then
               write(*,*) '      Amplitude (waamp) ',waamp
               write(*,*) '      Smoothing (wamoo) ',wamoo
               write(*,*) '      Start time (wamst) ',wamst
               write(*,*) '      Initial amplitude (wamst) ',waiamp
            end if
         end if
      else
         if (.not.suction ) then
            call comment(10)
            read(10,*) cdev
         end if
         if (my_node.eq.0) then
            write(*,*) '   cdev                              :',cdev
         end if
         if (cdev.gt.0.0) then
            write(*,*) 'Warning! cdev larger than zero needs to '//
     &                 'be verified together with parallel '//
     &                 'forcing'
            call stopnow(131313)
         end if
      end if
c
c     LES or DNS (LES if sgs true)
c
      call comment(10)
      read(10,*) sgs
      if (my_node.eq.0) then
         write(*,*) 'LES (sgs)                            :',sgs
      end if
c
c     Selective frequency damping
c
      call comment(10)
      read(10,*) isfd
      if (my_node.eq.0) then
         write(*,*) 'SFD (isfd)                           :',isfd
      end if
      sfdzero = .true.
      if (isfd.ge.1) then
         call comment(10)
         read(10,*) sfdzero
         if (.not.sfdzero) then
            call comment(10)
            read(10,*) namnut_sfd
         end if
         call comment(10)
         read(10,*) sfd_delta
         call comment(10)
         read(10,*) sfd_chi
         if (my_node.eq.0) then
            write(*,*) '   sfdzero     ',sfdzero
            write(*,*) '   sfd_delta   ',sfd_delta
            write(*,*) '   sfd_chi     ',sfd_chi
         end if
      end if
c
c     MHD
c
      call comment(10)
      read(10,*) imhd
      if (my_node.eq.0) then
         write(*,*) 'MHD (imhd)                           :',imhd
      end if
      if (imhd.eq.1) then
         if (iimhd.ne.1) then
            if (my_node.eq.0) then
               write(*,*) 'iimhd must be 1'
            end if
            endc = .true.
         end if
         call comment(10)
         read(10,*) b0(1)
         call comment(10)
         read(10,*) b0(2)
         call comment(10)
         read(10,*) b0(3)
         call comment(10)
         read(10,*) mhd_n
         fact = sqrt(b0(1)**2 + b0(2)**2 + b0(3)**2)
         if (abs(fact).lt.1e-10) then
            if (my_node.eq.0) then
               write(*,*) 'Magnetic field b0 needs to be nonzero'
            end if
            endc = .true.
         end if
         b0 = b0/fact
         if (my_node.eq.0) then
            write(*,*) '   b0(1)       ',b0(1)
            write(*,*) '   b0(2)       ',b0(2)
            write(*,*) '   b0(3)       ',b0(3)
            write(*,*) '   mhd_n       ',mhd_n
         end if
      else if (imhd.eq.0) then
         mhd_n = 0.
         b0 = 0.
      else
         if (my_node.eq.0) then
            write(*,*) 'imhd must be 0 or 1.'
         end if
         endc = .true.
      end if
c
c     Disturbance type (loctyp)
c
      call comment(10)
      read(10,*) loctyp
      if (my_node.eq.0) then
         write(*,*) 'Disturbance type (loctyp)            :',loctyp
      end if
      if (loctyp.eq.1) then
         call comment(10)
         read(10,*) fpdds1
         call comment(10)
         read(10,*) fpdds2
         call comment(10)
         read(10,*) fpdds3
         call comment(10)
         read(10,*) fpds2
         call comment(10)
         read(10,*) fpds1
         call comment(10)
         read(10,*) fpds3
         call comment(10)
         read(10,*) fpds4
         if (fpds4.lt.0) then
            call comment(10)
            read(10,*) fp1
         end if
         call comment(10)
         read(10,*) fpds5
         if (my_node.eq.0) then
            write(*,*) '   ampx    ',fpdds1
            write(*,*) '   ampy    ',fpdds2
            write(*,*) '   ampz    ',fpdds3
            write(*,*) '   xscale  ',fpds2
            write(*,*) '   xloc0   ',fpds1
            write(*,*) '   yscale  ',fpds3
            write(*,*) '   zscale  ',fpds4
            if (fpds4.lt.0) write(*,*) '      lskew   ',fp1
            write(*,*) '   tscale  ',fpds5
         end if
      end if
      if (loctyp.eq.2) then
         call comment(10)
         read(10,*) fpdds1
         call comment(10)
         read(10,*) fpdds2
         call comment(10)
         read(10,*) fpdds3
         call comment(10)
         read(10,*) fpds1
         call comment(10)
         read(10,*) fpds2
         call comment(10)
         read(10,*) fpds3
         call comment(10)
         read(10,*) fpds4
         call comment(10)
         read(10,*) fpds5
         call comment(10)
         read(10,*) fpds6
         call comment(10)
         read(10,*) fpds7
         call comment(10)
         read(10,*) fpds8
         call comment(10)
         read(10,*) fpdds4
         call comment(10)
         read(10,*) fpdds5
         if (my_node.eq.0) then
            write(*,*) '   ampx    ',fpdds1
            write(*,*) '   ampy    ',fpdds2
            write(*,*) '   ampz    ',fpdds3
            write(*,*) '   xstart  ',fpds1
            write(*,*) '   xend    ',fpds2
            write(*,*) '   xrise   ',fpds3
            write(*,*) '   xfall   ',fpds4
            write(*,*) '   ystart  ',fpds5
            write(*,*) '   yend    ',fpds6
            write(*,*) '   yrise   ',fpds7
            write(*,*) '   yfall   ',fpds8
            write(*,*) '   zbet    ',fpdds4
            write(*,*) '   tomeg   ',fpdds5
         end if
      end if
      if (loctyp.eq.3) then
         call comment(10)
         read(10,*) fpdds1
         call comment(10)
         read(10,*) fpdds2
         call comment(10)
         read(10,*) fpdds3
         call comment(10)
         read(10,*) fpds1
         call comment(10)
         read(10,*) fpds2
         call comment(10)
         read(10,*) fpds3
         call comment(10)
         read(10,*) fp1
         call comment(10)
         read(10,*) fpdds4
         if (my_node.eq.0) then
            write(*,*) '   ampx   ',fpdds1
            write(*,*) '   ampy   ',fpdds2
            write(*,*) '   ampz   ',fpdds3
            write(*,*) '   xscale ',fpds1
            write(*,*) '   xloc0  ',fpds2
            write(*,*) '   yscale ',fpds3
            write(*,*) '   xtype  ',fp1
            write(*,*) '   tomeg  ',fpdds4
         end if
      end if
      if (loctyp.eq.4) then
         call comment(10)
         read(10,*) fpdds1
         call comment(10)
         read(10,*) fpds1
         call comment(10)
         read(10,*) fpds2
         call comment(10)
         read(10,*) fpds3
         call comment(10)
         read(10,*) fpds4
         call comment(10)
         read(10,*) fpdds2
         if (my_node.eq.0) then
            write(*,*) '   ampz   ',fpdds1
            write(*,*) '   yscale ',fpds1
            write(*,*) '   tstart ',fpds2
            write(*,*) '   tend   ',fpds3
            write(*,*) '   tscale ',fpds4
            write(*,*) '   tomeg  ',fpdds2
         end if
      end if
      if (loctyp.eq.5) then
         call comment(10)
         read(10,*) fpdds1
         call comment(10)
         read(10,*) fpdds2
         call comment(10)
         read(10,*) fpdds3
         call comment(10)
         read(10,*) fpds2
         call comment(10)
         read(10,*) fpds1
         call comment(10)
         read(10,*) fpds3
         call comment(10)
         read(10,*) fpds4
         if (fpds4.lt.0) then
            call comment(10)
            read(10,*) fp1
         end if
         call comment(10)
         read(10,*) fpds5
         call comment(10)
         read(10,*) fpds6
         call comment(10)
         read(10,*) fpdds4
         call comment(10)
         read(10,*) fpdds5
         call comment(10)
         read(10,*) fpds7
         call comment(10)
         read(10,*) fpds8
         if (my_node.eq.0) then
            write(*,*) '   ampx    ',fpdds1
            write(*,*) '   ampy    ',fpdds2
            write(*,*) '   ampz    ',fpdds3
            write(*,*) '   xscale  ',fpds2
            write(*,*) '   xloc0   ',fpds1
            write(*,*) '   yscale  ',fpds3
            write(*,*) '   zscale  ',fpds4
            if (fpds4.lt.0) write(*,*) '      lskew   ',fp1
            write(*,*) '   tscale  ',fpds5
            write(*,*) '   xo      ',fpds6
            write(*,*) '   aomeg   ',fpdds4
            write(*,*) '   tomeg   ',fpdds5
            write(*,*) '   y0      ',fpds7
            write(*,*) '   yscale1 ',fpds8
         end if
      end if
      if (loctyp.eq.6) then
         call comment(10)
         read(10,*) fpdds1
         call comment(10)
         read(10,*) fpds1
         call comment(10)
         read(10,*) fpds2
         call comment(10)
         read(10,*) fpds3
         call comment(10)
         read(10,*) fpdds4
         call comment(10)
         read(10,*) fpdds2
         call comment(10)
         read(10,*) fpdds3
         if (my_node.eq.0) then
            write(*,*) '   amp2d   ',fpdds1
            write(*,*) '   xscale  ',fpds1
            write(*,*) '   xloc0   ',fpds2
            write(*,*) '   yscale  ',fpds3
            write(*,*) '   tomeg2D ',fpdds4
            write(*,*) '   amp3d   ',fpdds2
            write(*,*) '   tomeg3D ',fpdds3
         end if
      end if
      if (loctyp.eq.7) then
         call comment(10)
         read(10,*) fpdds1
         call comment(10)
         read(10,*) fpds1
         call comment(10)
         read(10,*) fpds2
         call comment(10)
         read(10,*) fpds3
         call comment(10)
         read(10,*) fpds4
         call comment(10)
         read(10,*) fpdds2
         if (my_node.eq.0) then
            write(*,*) '   amp     ',fpdds1
            write(*,*) '   xloc0   ',fpds1
            write(*,*) '   yloc0   ',fpds2
            write(*,*) '   xscale  ',fpds3
            write(*,*) '   yscale  ',fpds4
            write(*,*) '   tomeg   ',fpdds2
         end if
      end if
      if (loctyp.eq.8) then
         call comment(10)
         read(10,*) fpdds1
         call comment(10)
         read(10,*) fpdds2
         call comment(10)
         read(10,*) fpdds3
         call comment(10)
         read(10,*) fpds1
         call comment(10)
         read(10,*) fpds2
         call comment(10)
         read(10,*) fpds3
         call comment(10)
         read(10,*) fpds6
         call comment(10)
         read(10,*) fpds4
         call comment(10)
         read(10,*) fpds5
         if (my_node.eq.0) then
            write(*,*) '   ampx   ',fpdds1
            write(*,*) '   ampy   ',fpdds2
            write(*,*) '   ampz   ',fpdds3
            write(*,*) '   xscale ',fpds1
            write(*,*) '   xloc0  ',fpds2
            write(*,*) '   yscale ',fpds3
            write(*,*) '   yloc0  ',fpds6
            write(*,*) '   tscale ',fpds4
           write(*,*)  '   tstart ',fpds5
         end if
      end if
c
c     Trip forcing (tripf)
c
      call comment(10)
      read(10,*) tripf
      if (my_node.eq.0) then
         write(*,*) 'Trip forcing (tripf)                 :',tripf
      end if
      if (tripf) then
         call comment(10)
         read(10,*) tamps
         call comment(10)
         read(10,*) tampt
         call comment(10)
         read(10,*) txsc
         call comment(10)
         read(10,*) tx0
         call comment(10)
         read(10,*) tysc
         call comment(10)
         read(10,*) nzt
         call comment(10)
         read(10,*) tdt
         call comment(10)
         read(10,*) seed
         if (my_node.eq.0) then
            write(*,*) '   tamps   ',tamps
            write(*,*) '   tampt   ',tampt
            write(*,*) '   txsc    ',txsc
            write(*,*) '   tx0     ',tx0
            write(*,*) '   tysc    ',tysc
            write(*,*) '   nzt     ',nzt
            write(*,*) '   tdt     ',tdt
            write(*,*) '   seed    ',seed
            if (seed.ge.0) then
               write(*,*) 'Random seed must be negative.'
               endc=.true.
            end if
         end if
      end if
c
c     Boundary-layer wall boundary condition (wbci)
c
      call comment(10)
      read(10,*) wbci
      if (my_node.eq.0) then
         write(*,*) 'Boundary-layer wall bc (wbci)        :',wbci
      end if
      if (wbci.eq.1) then
         call comment(10)
         read(10,*) wp1
         call comment(10)
         read(10,*) wp2
         call comment(10)
         read(10,*) wpds1
         call comment(10)
         read(10,*) wpds2
         call comment(10)
         read(10,*) wpds3
         call comment(10)
         read(10,*) wpds4
         call comment(10)
         read(10,*) wpdds1
         call comment(10)
         read(10,*) wpdds2
         if (my_node.eq.0) then
            write(*,*) '   amp     ',wp1
            write(*,*) '   damp    ',wp2
            write(*,*) '   xstart  ',wpds1
            write(*,*) '   xend    ',wpds2
            write(*,*) '   xrise   ',wpds3
            write(*,*) '   xfall   ',wpds4
            write(*,*) '   zbet    ',wpdds1
            write(*,*) '   tomeg   ',wpdds2
         end if
      end if
      if (wbci.eq.2) then
         call comment(10)
         read(10,*) wp1
         call comment(10)
         read(10,*) wpds1
         call comment(10)
         read(10,*) wpds2
         call comment(10)
         read(10,*) wpds3
         call comment(10)
         read(10,*) wpds4
         call comment(10)
         read(10,*) wpds5
         call comment(10)
         read(10,*) wpds6
         call comment(10)
         read(10,*) wpds7
         call comment(10)
         read(10,*) wpds8
         call comment(10)
         read(10,*) wpds9
         call comment(10)
         read(10,*) wpds10
         call comment(10)
         read(10,*) wpds11
         call comment(10)
         read(10,*) wpds12
         call comment(10)
         read(10,*) wpdds1
         if (my_node.eq.0) then
            write(*,*) '   amp         ',wp1
            write(*,*) '   xstart      ',wpds1
            write(*,*) '   xend        ',wpds2
            write(*,*) '   xrise       ',wpds3
            write(*,*) '   xfall       ',wpds4
            write(*,*) '   zstart      ',wpds5
            write(*,*) '   zend        ',wpds6
            write(*,*) '   zrise       ',wpds7
            write(*,*) '   zfall       ',wpds8
            write(*,*) '   tstart      ',wpds9
            write(*,*) '   tend        ',wpds10
            write(*,*) '   trise       ',wpds11
            write(*,*) '   tfall       ',wpds12
            write(*,*) '   disdomega   ',wpdds1
         end if
      end if
      if (wbci.eq.-1) then  
         call comment(10)
         read(10,*) wallroughinput
         if (my_node.eq.0) then
            write(*,*) '   Wall-roughness param. from file   : ', 
     &           trim(wallroughinput)
         end if
      end if
      if (wbci.eq.-2) then
         if (my_node.eq.0) then
            write(*,*) '   Impose jet profile'
         end if
            call comment(10)
            read(10,*) jet_prof
            call comment(10)
            read(10,*) jet_diam
            call comment(10)
            read(10,*) xjet
            call comment(10)
            read(10,*) zjet
            call comment(10)
            read(10,*) jetmag
            call comment(10)
      end if
c
c     Iterations between cfl calculcations (icfl)
c
      call comment(10)
      read(10,*) icfl
      if (my_node.eq.0) then
         write(*,*) 'Iter. between cfl calc. (icfl)       :',icfl
      end if
c
c     Iterations between amplitude calculations (iamp)
c
      call comment(10)
      read(10,*) iamp
      if (my_node.eq.0) then
         write(*,*) 'Iter. between amplitude calc. (iamp) :',iamp
      end if
      if (iamp.gt.0) then 
         call comment(10)
         read(10,'(a)') namamp
         if (my_node.eq.0) then
            write(*,*) '   Name of amplitude file (namamp)   : ',
     &           trim(namamp)
         end if
         read(10,*) fileurms
         if (my_node.eq.0) then
            write(*,*) 
     &           'Write urms velocities (fileurms)     :',
     &           fileurms
         end if
      end if
c
c     Generate amplitude (longli)
c
      call comment(10)
      read(10,*) longli
      if (my_node.eq.0) then
         write(*,*) 'y-dependent statitics (longli)       :',longli
      end if
c
c     Number of iterations between extremum amplitudes (iext)
c
      call comment(10)
      read(10,*) iext
      if (my_node.eq.0) then
         write(*,*) 'Number of it. extremum ampl. (iext)  :',iext
      end if
      if (iext.gt.0) then
         call comment(10)
         read(10,'(a)') namext
         if (my_node.eq.0) then
            write(*,*) '   Name of extremum file (namext)   : ',
     &           trim(namext)
         end if
      end if
c
c     Statistic evaluation interval (ixys)
c
      call comment(10)
      read(10,*) ixys
      ixys=max(0,ixys)
      if (ixys.gt.0) ixys=max(ixys,nst)/nst*nst
      if (my_node.eq.0) then
         write(*,*) 'Statistic evaluation interval (ixys) :',ixys
      end if
      corrf = .false.
      serf = .false.
      ixyss = 0
      if (ixys.gt.0) then
         call comment(10)
         read(10,'(a)') namxys
         call comment(10)
         read(10,*) ixyss
         call comment(10)
         read(10,*) txys
         ixyss=max(0,ixyss)
         if (ixyss.gt.0) ixyss=max(ixyss,nst)/nst*nst
         if (my_node.eq.0) then
            write(*,*) '   namxys: ',trim(namxys)
            write(*,*) '   ixyss:  ',ixyss
            write(*,*) '   txys:   ',txys
         end if
c
c     Two-point correlation in z
c
         call comment(10)
         read(10,*) corrf
         if (my_node.eq.0) then
            write(*,*) '   Save correlations (corrf)         :',corrf
         end if
         if (corrf) then
            call comment(10)
            read(10,'(a)') corrnam
            call comment(10)
            read(10,*) ncorr
            if (my_node.eq.0) then
               write(*,*) '      File name: ',trim(corrnam)
               write(*,*) '      Number: ',ncorr
            end if

            if (ncorr.gt.0) then
               if (mcorr.lt.ncorr) then
                  write(*,*) 'increase mcorr in par.f to ',ncorr
                  call stopnow(5453)
               end if
c
c     Read positions from two-point.dat
c
               open(unit=17,status='old',file='two-point.dat')
               do i=1,ncorr
                  read(17,*) corrx(i),corry(i),corrt(i)
               end do
               close(17)
c
c     Read from bla.i
c
c               do i=1,ncorr
c                  read(10,*) corrx(i),corry(i),corrt(i)
c               end do
            else
               call stopnow(65645)
               ncorr=ncorr*nyp
               if (mcorr.lt.-ncorr) then
                  write(*,*) 'increase mcorr in par.f to ',ncorr
                  call stopnow(5453)
               end if
               do i=1,-ncorr/nyp
                  read(10,*) corrx(i)
               end do
            end if


         end if
c
c     Two-point correlation in x
c
         call comment(10)
         read(10,*) corrf_x
         if (my_node.eq.0) then
            write(*,*) '   Save correlations (corrf_x):',corrf_x
         end if
         if (corrf_x) then
            call comment(10)
            read(10,'(a)') corrnam_x
            call comment(10)
            read(10,*) ncorr_x
            if (my_node.eq.0) then
               write(*,*) '      File name: ',trim(corrnam_x)
               write(*,*) '      Number: ',ncorr_x
            end if

            if (ncorr_x.gt.0) then
               if (mcorr.lt.ncorr_x) then
                  write(*,*) 'increase mcorr in par.f to ',ncorr_x
                  call stopnow(5453)
               end if
c
c     Read positions from two-point_x.dat
c
               open(unit=27,status='old',file='two-point_x.dat')
               do i=1,ncorr_x
                  read(27,*) corrz(i),corry_x(i),corrt_x(i)
               end do
               close(27)
c
c     Read from bla.i
c
c               do i=1,ncorr
c                  read(10,*) corrx(i),corry(i),corrt(i)
c               end do
            else
               call stopnow(65645)
               ncorr_x=ncorr_x*nyp
               if (mcorr.lt.-ncorr_x) then
                  write(*,*) 'increase mcorr in par.f to ',ncorr_x
                  call stopnow(5453)
               end if
               do i=1,-ncorr_x/nyp
                  read(10,*) corrz(i)
               end do
            end if


         end if
c
c     Time series
c
         call comment(10)
         read(10,*) serf
         if (my_node.eq.0) then
            write(*,*) '   Save time series (serf)           :',serf
         end if
         if (serf) then
            call comment(10)
            read(10,'(a)') namser
            call comment(10)
            read(10,*) nser
            if (my_node.eq.0) then
               write(*,*) '      File name: ',trim(namser)
               write(*,*) '      Number: ',nser
            end if
            
            if (mser.lt.nser) then
               write(*,*) 'Increase mser in par.f to ',nser
               call stopnow(5456)
            end if
c
c     Read positions from probe.dat
c
            open(unit=17,status='old',file='probe.dat')     
            do i=1,nser
               read(17,*) serc(1,i),serc(2,i),serc(3,i),sert(i)
            end do
            close(17)
c
c     Read positions from bla.i
c
c            do i=1,nser
c               read(10,*) serc(1,i),serc(2,i),serc(3,i),sert(i)
c            end do
         end if
      end if
c
c     Velocity fields to save
c
      call comment(10)
      read(10,*) msave
      sign = 1
      if (msave.lt.0) then
         sign = -1
      end if
      if (msave.eq.100000) then
         sign = -2
      end if
      msave = sign*msave
      if (my_node.eq.0.and.sign.ne.-2) then
         write(*,*) 'Number of vel. fields to save (msave):',msave
      end if
      msave=max(0,msave)
      if (msave.ge.nsave) then
         endc = .true.
         write(*,*) 'Stop: msave cannot be greater than nsave.'
         write(*,*) 'Change msave in bla.i or nsave in bla.f.'
         write(*,*) 'msave, nsave=',msave,nsave
      end if
      if (sign.eq.1) then
         do i=1,msave
            call comment(10)
            read(10,*) tsave(i)
            call comment(10)
            read(10,'(a)') nmsave(i)           
            if (my_node.eq.0) then
               write(*,*) '   tsave  : ',tsave(i),i
               write(*,*) '   nmsave : ',trim(nmsave(i))
            end if
         end do
      else if (sign.eq.-1) then
         call comment(10) 
         read(10,*) omga
         if (omga.lt.0) omga = -omga
         if (my_node.eq.0) then
            write(*,*) '   Period : ',(2.*pi/omga),'omega=',omga
         end if
         do i=1,msave
c
c     Save the files at given interval and specify names
c            tsave(i) = 8000.+(2.*pi/omga)/real(msave)*real(i-1)
c            write(nmsave(i),'(a1,i2.2,a2)') 'f',i-1,'.u'
c
            tsave(i) = tmax-0.5*real(msave+1-i)*pi/omga
            call comment(10)
            read(10,'(a)') nmsave(i)

            if (my_node.eq.0) then
               write(*,*) '   tsave  : ',tsave(i),i
               write(*,*) '   nmsave : ',trim(nmsave(i))
            end if
         end do
      else if (sign.eq.-2) then
         if (my_node.eq.0) then
           write(*,*) "Writing out velocity fields at regular intervals"
         end if
         msave = nsave-1
         do i=1,msave
            tsave(i) = 10700.+i*25.
            j=0.+i*1
            if (namnut(len_trim(namnut)-2:len_trim(namnut)).eq.".uu")
     &           then
               write(nmsave(i),'(a,i4.4,a)') 'field.',j,'.uu'
            else
               write(nmsave(i),'(a,i4.4,a)') 'field.',j,'.u'
            end if
            if (my_node.eq.0) then
               write(*,*) i,tsave(i),trim(nmsave(i))
            end if
         end do

      end if
      tsave(msave+1)=1.E30
      if(adjoint) tsave(msave+1)=-1.E30
c
c     Number of seperate wavenumbers to save (mwave)
c
      call comment(10)
      read(10,*) mwave
      mwave=max(0,mwave)
      if (my_node.eq.0) then
         write(*,*) 'Number of wavenumbers to save (mwave):',mwave
      end if
      if (mwave.gt.nwave) then
         write(*,*) 'Stop: mwave can''t be greater than nwave.'
         write(*,*) 'Change mwave in bla.i or nwave in bla.f.'
         write(*,*) 'mwave, nwave=', mwave, nwave
         endc=.true.
      end if
      if (mwave.gt.0) then
         call comment(10)
         read(10,'(a)') namwav
         do i=1,mwave
            call comment(10)
            read(10,*) kx(i),kz(i)
         end do
         if (my_node.eq.0) then
            if (mwave.gt.0) write(*,*) '   namwav: ',trim(namwav)
            do i=1,mwave
              write(*,*) '   kx,kz   ',kx(i),kz(i)
              if (kx(i).lt.0.or.kx(i).ge.nx/2) then
                 write(*,*)'Stop: kx must be from 0 to nx/2-1.'
                 endc=.true.
              end if
              if (kz(i).lt.(1-nz/2)*(1-nfzsym).or.kz(i).ge.nz/2) then
                 write(*,*) 'Stop: kz must be from '
                 write(*,*) '-(nz/2-1)*(1-nfzsym) to nz/2-1.'
                 endc=.true.
              end if
            end do
         end if
      end if
c
c     Number of full planes to save (npl)
c
      call comment(10)
      read(10,*) npl
      npl=max(0,npl)
      if (my_node.eq.0) then
         write(*,*) 'Number of planes to save (npl)       :',npl
      end if
      if (npl.gt.0) then
         call comment(10)
         read(10,*) ipl
         ipl=max(0,ipl)
         if (ipl.gt.0) ipl=max(ipl,nst)/nst*nst
         if (npl.gt.mpl) then
            write(*,*)'Stop: npl can''t be greater than mpl. Change npl in
     &           bla.i or mpl in bla.f. npl, mpl=', npl, mpl
            endc=.true.
         end if
         do i=1,npl
            call comment(10)
            read(10,*) tpl(i,1)
            call comment(10)
            read(10,*) tpl(i,2)
            call comment(10)
            read(10,*) cpl(i)
            call comment(10)
            read(10,'(a)') nampl(i)
         end do
         if (my_node.eq.0) then
            if (npl.gt.0) write(*,*) 'ipl     ',ipl
            do i=1,npl
               write(*,*) '   tpl(.,1) ',tpl(i,1)
               write(*,*) '   tpl(.,2) ',tpl(i,2)
               write(*,*) '   cpl      ',cpl(i)
               write(*,*) '   nampl : ',trim(nampl(i))
            end do
         end if
      end if
c
c     Close input file
c
      close(unit=10)
c
c     Some adjustments
c
      if (icfl.gt.0.and.icfl.lt.nst) icfl=nst
      if (icfl.gt.0) icfl=min(icfl/nst*nst,3*nst)
      if (dt.le.0.and.icfl.le.0) icfl=nst
c
c     Echo sub-parameters to logfile and checking
c
      if (my_node.eq.0) then
         if (nst.ne.3.and.nst.ne.4) then
            write(*,*)'Stop: nst must be 3 for 3-stage Rk3 or'
     &           //' 4 for 4-stage RK3.'
            endc=.true.
         end if
c
c     Check box size
c
         if (xl.le.0.) then
            write(*,*) 'Stop: The box size xl must be >0.'
            endc=.true.
         end if
c
c     Check boundary condition setting
c
         if (ibc.ne.0.and.ibc.ne.1.and.ibc.ne.2.and.ibc.ne.3.and.
     &        ibc.ne.10
     &        .and.ibc.ne.11.and.ibc.ne.12.and.ibc.ne.20.and.
     &        ibc.ne.100.and.
     &        ibc.ne.101.and.ibc.ne.110.and.ibc.ne.120.and.ibc.ne.130
     &        .and.
     &        ibc.ne.140.and.ibc.ne.150) then
            write(*,*)'Stop: ibc must be 1,2,3,10,11,12,20,'
     &           //'100,101,110,120,'
            write(*,*)'130,140 or 150.'
            endc=.true.
         end if

         if (spat) then
c
c     Check fringe parameters
c
            if (fstart.ge.fend.or.frise.le.0..or.ffall.le.0..or.
     &           fmax.le.0.
c     &           .or.
c     &           fmax.lt.log(1.e6)/(fend-fstart-.5*(frise+ffall))
     &           .or.fstart.gt..5
     &           *xl.or.fstart.lt.-.5*xl.or.fend.gt..5*xl
     &           .or.fend.lt.-.5*xl) then
               write(*,*)'Stop: fmax,frise,ffall must be positive or'
               write(*,*)'please choose fstart and fend '
               write(*,*) 'in -xl/2 to xl/2.'
               endc=.true.
            end if
         else
            if (.not.suction) then
               if (cdev.lt.0) then
                  write(*,*) 'cdev has to be non-negative.'
                  endc=.true.
               end if
            end if
         end if
c
c     Check selective frequency damping
c
         if (isfd.eq.1) then
         else
            if (isfd.ne.0) then
               write(*,*) 'isfd must be 0 or 1'
               endc=.true.
            end if
         end if
c     
c     Perturbation formulation of scalar not implemented
c
         if (scalar.ge.1.and.pert) then
            write(*,*)'Scalar and pert not implemented'
            endc=.true.
         end if
c
c     Suction and perturbation not implemented
c
         if (vsuc.ne.0..and.pert) then
            write(*,*)'Suction and pert not implemented'
            endc=.true.
         end if
c
c     Two- and three-dimensional base flow checks
c
         if (rbfl.and.bf3) then
            write(*,*)'Two- and three-dimensional base flow'
            write(*,*)'Choose one!'
            endc=.true.
         end if
c
c     Issue warning about boundary control
c
         if (wbci.ne.0) then
            write(*,*) ' WARNING! WARNING! WARNING!'
            write(*,*) ' Numerical instabilities can occour with'
            write(*,*) ' strong blowing and suction or wall roughness. '
            write(*,*) ' They are caused by too large'
            write(*,*) ' timestep and can be removed by removing'
            write(*,*) ' line 24 in boxcfl.f " if (ny.ge.17) ..."'
         end if
c
c     Stop is necessary
c
         if (endc) then
            write(*,*) 'Program stop due to error in bla.i.'
            call stopnow(13)
         end if
      end if
c
c     Set some parameters based on read data
c      
      kx(mwave+1)=-1
      vart=dt.le.0
      dtmax=1.E30
      
      if (dt.lt.0) dtmax=-dt
c
c     Original values for cflmax
c      if (nst.eq.1) cflmax = .7
c      if (nst.eq.3) cflmax = .9*sqrt(3.)
c      if (nst.eq.4) cflmax = .9*sqrt(8.)
c
c     RK4 stability criterion:
c     along imaginary axis: sqrt(8.)=2.828
c     along real axis:      2.785
c
c     RK3 stability criterion:
c     along imaginary axis: sqrt(3.)=1.73
c     along real axis:      2.52
c
      if (nst.eq.1) cflmax = 1.
      if (nst.eq.3) cflmax = sqrt(3.)
      if (nst.eq.4) cflmax = sqrt(8.)
      cflmax = cflmaxin*cflmax
      
      if (my_node.eq.0) then
         write(*,*) 
         write(*,'(a,f14.9,a,f14.9,a)') 
     &        ' cflmax = ',cflmax,' (cfl number = ',cflmaxin,')'
      end if

      if (icfl.eq.0) icfl=-large
      if (iamp.eq.0) iamp=-large
      if (iext.eq.0) iext=-large
      if (ipl.eq.0) ipl=-large
      if (ixys.eq.0) ixys=-large
      if (ixyss.eq.0) ixyss=-large
      maxit=maxit/nst*nst

      end subroutine rparambl
