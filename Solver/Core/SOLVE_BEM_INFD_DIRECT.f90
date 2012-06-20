MODULE SOLVE_BEM_INFD_DIRECT

  USE COM_VAR
  USE COMPUTE_GREEN_INFD
  USE ELEMENTARY_FNS
  USE M_SOLVER
  IMPLICIT NONE

  CONTAINS
!--------------------------------------------------------------------------!
  SUBROUTINE SOLVE_POTENTIAL_INFD_DIRECT(NVEL)
!In this subroutine the linear system Ax=b is constructed

    COMPLEX,DIMENSION(*) :: NVEL
    INTEGER :: BX,ISYM,NJJ,N
    INTEGER ::I,J,ISP,IFP
    INTEGER:: NP1,I1,JJ
    REAL:: W,tdepth,BETA,BJ,GM,DIJ,AKK
    REAL:: CB,SB,CP,CR,COEFB,COEFS,PCOS,PSIN
    REAL:: AKAD,AM0,SD1B,SD1S,SD2B,SD2S,PI,DPI,ZERO
    COMPLEX:: ZOL(IMX,2)


      NJJ=NSYMY+1
      PI=4.*ATAN(1.)
      DPI=2.*PI
      W=DPI/T
      ZERO=0.0
      AM0=W**2/G
      tdepth=1.E+20
!--------------Initilizations---------------
      CQ=0.0
      QQ=0.0
      VSXP=0.
      VSXM=0.
      VSYP=0.
      VSYM=0.
      VSZP=0.
      VSZM=0.
      ZOL=CMPLX(0.,0.)
      ZIJ=CMPLX(0.,0.)
!--------------------------------------------                                                                                                                    
      GM=0.
      NP1=NP-1
      DO 7100 I=1,NP1
	I1=I+1
	DO 7200 JJ=1,NJJ
	  BJ=(-1.)**(JJ+1)
	  DO 7200 J=I1,NP
	    DIJ=SQRT((X(J)-X(I))**2+(Y(I)-Y(J)*BJ)**2)
	    	    GM=AMAX1(DIJ,GM)
    7200 CONTINUE
 7100 CONTINUE                                               
      AKK=AM0*GM      
      CALL CINT_INFD(AKK,N)
      N=NQ

!Construction of the influence matrix 
      DO 2000 ISYM=1,NJJ
      BX=(-1)**(ISYM+1)
	DO 1 ISP=1,IMX
	  IF(ISYM.EQ.1)THEN
	    DO 31 IFP=1,IMX
              
	      call VAVINFD(1,XG(ISP),YG(ISP),ZG(ISP),ISP,IFP)  !1/r+1/r1

	      call VNSINFD(1,ISP,IFP,XG(ISP),YG(ISP),ZG(ISP))  

	      PCOS=VSXP1*XN(ISP)+VSYP1*YN(ISP)+VSZP1*ZN(ISP)
	      PSIN=VSXP2*XN(ISP)+VSYP2*YN(ISP)+VSZP2*ZN(ISP)
	      ZIJ(ISP,IFP)=CMPLX(PCOS,PSIN)
	31 CONTINUE
	  ELSE
	    DO 32 IFP=1,IMX
	      call VAVINFD(1,XG(ISP),YG(ISP),ZG(ISP),ISP,IFP)

              call VNSINFD(1,ISP,IFP,XG(ISP),YG(ISP),ZG(ISP))  

	      PCOS=VSXM1*XN(ISP)+VSYM1*YN(ISP)+VSZM1*ZN(ISP)
	      PSIN=VSXM2*XN(ISP)+VSYM2*YN(ISP)+VSZM2*ZN(ISP)
	      ZIJ(ISP,IFP)=CMPLX(PCOS,PSIN)           
	32 CONTINUE
	  ENDIF
      1 CONTINUE

!        IF(.not. RHS) then
!	AKAD=G*AM0/W
!	BETA=0.0
!	CB=COS(BETA)
!	SB=SIN(BETA)
!	DO 403 I=1,IMX
!	  CR=SIH(AM0,ZG(I),tdepth)*AKAD
!	  CP=CIH(AM0,ZG(I),tdepth)*AKAD
!	  COEFB=AM0*((XG(I)-XEFF)*CB+(YG(I)-YEFF)*SB)
!	  SD1B=CR*ZN(I)*COS(COEFB)-(XN(I)*CB+YN(I)*SB)*CP*SIN(COEFB)
!	  SD2B=CR*ZN(I)*SIN(COEFB)+(XN(I)*CB+YN(I)*SB)*CP*COS(COEFB)
!	    IF(NSYMY.EQ.1)THEN
!	      COEFS=AM0*((XG(I)-XEFF)*CB-(YG(I)-YEFF)*SB)
!	      SD1S=CR*ZN(I)*COS(COEFS)-(XN(I)*CB-YN(I)*SB)*CP*SIN(COEFS)
!	      SD2S=CR*ZN(I)*SIN(COEFS)+(XN(I)*CB-YN(I)*SB)*CP*COS(COEFS)
!	    ELSE
!	      SD1S=0.
!	      SD2S=0.
!	    ENDIF
!	    IF(ZG(I).LT.ZER)THEN
!	      ZIJ(I,IMX+1)=CMPLX(SD1B+BX*SD1S,SD2B+BX*SD2S)*0.5
!	    ELSE
!	      ZIJ(I,IMX+1)=(0.,0.)
!	    ENDIF            
 !    403 CONTINUE
  !      ENDIF


 !       IF(RHS)THEN  !RHS for prescribed NormalVelocity
	  DO I=1,IMX
	    IF (NSYMY.EQ.1) THEN
	      ZIJ(I,IMX+1)=(NVEL(I)+BX*NVEL(I+NFA))*0.5
	    ELSE
	      ZIJ(I,IMX+1)=NVEL(I)
	    END IF
	  ENDDO
 !       ENDIF
 
!------------------------------------------------!
        CALL GAUSSZ(ZIJ,NFA,IMX,IMX+1)
!------------------------------------------------!

	DO 2002 I=1,IMX
	  ZOL(I,(ISYM-1)+1)=ZIJ(I,IMX+1)
  2002 CONTINUE

 2000 CONTINUE

	ZIGB=(0.,0.)
	ZIGS=(0.,0.)

	DO 2255 I=1,IMX
	  IF(NSYMY .EQ. 0)THEN
	    ZIGB(I)=ZOL(I,1)    ! Factor 2 is removed in comparison with previous version of Aquaplus because
	                        ! Normal velocity is halved in Aquaplus (because of symmetry)
	    ZIGS(I)=0.0
	  ELSE
	    ZIGB(I)=(ZOL(I,1)+ZOL(I,2))
	    ZIGS(I)=(ZOL(I,1)-ZOL(I,2))
          ENDIF
  2255 CONTINUE      

!computation of potential phi=S*sigma on the boundary
      ZPB=(0.,0.)
      ZPS=(0.,0.)
      DO 2240 I=1,IMX
	  DO 2261 J=1,IMX
	      call VAVINFD(1,XG(I),YG(I),ZG(I),I,J)

              call VNSINFD(1,I,J,XG(I),YG(I),ZG(I)) 

	      ZPB(I)=ZPB(I)+0.5*(ZIGB(J)*CMPLX(SP1+SM1,SP2+SM2)&
                    +ZIGS(J)*CMPLX(SP1-SM1,SP2-SM2))
	      ZPS(I)=ZPS(I)+0.5*(ZIGS(J)*CMPLX(SP1+SM1,SP2+SM2)&
                    +ZIGB(J)*CMPLX(SP1-SM1,SP2-SM2))
    2261 CONTINUE

 2240 CONTINUE
!      do i=1,IMX
!      print*,'ZPB,ZPS',I,ZPB(I),ZPS(I)
!      enddo

  END SUBROUTINE


END MODULE