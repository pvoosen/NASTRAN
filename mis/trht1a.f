      SUBROUTINE TRHT1A (CASEXX,USETD,GPTT,TRL,NGROUP)        
C        
C     TRHT1A INITIALIZES FOR TRHT MODULE        
C        
C     ITS TASK IS TO EXTRACT INITIAL CONDITION POINTS FROM CASEXX       
C     AND TO PUT INITIAL STUFF ON ICR5        
C        
      EXTERNAL        ANDF        
      INTEGER         CASEXX,USETD,GPTT,TRL,SYSBUF,IZ(160),NAME(2),     
     1                FILE,ANDF,TWO1,MCB(7),IA(1)        
      COMMON /BITPOS/ ISK(11),IUE,ISK1(3),IUD        
      COMMON /TWO   / TWO1(32)        
      COMMON /BLANK / X        
      COMMON /SYSTEM/ SYSBUF        
      COMMON /TRHTX / IK(7),IB(7),ICR1,ICR2,ICR3,ICR4,ISCR5        
      COMMON /TRDD1 / NLFT1,DIT1,NLFTP1        
CZZ   COMMON /ZZTRDC/ Z(1)        
      COMMON /ZZZZZZ/ Z(1)        
      COMMON /ZBLPKX/ A(4),II        
      COMMON /PACKX / IT1,IT2,II1,JJ1,INCR        
      EQUIVALENCE     (Z(1),IZ(1)), (A(1),IA(1))        
      DATA    NAME  / 4HTRHT,4H1A  /        
C        
C        
      NZ = KORSZ(Z)        
      NX = NZ        
      IBUF1 = NZ - SYSBUF + 1        
      NZ = NZ - SYSBUF        
      CALL GOPEN (CASEXX,IZ(IBUF1),0)        
      CALL FREAD (CASEXX,IZ(1),166,1)        
      CALL CLOSE (CASEXX,1)        
      ITSTEP = IZ(38)        
      NLFTP1 = IZ(160)        
      INTMP  = IZ(9)        
      INLTMP = IZ(8)        
C        
C     FIND STUFF ON TRL        
C        
      FILE = TRL        
      CALL OPEN (*200,TRL,IZ(IBUF1),0)        
      CALL READ (*220,*10,TRL,IZ(1),NZ,0,IFLAG)        
      GO TO 230        
   10 NS =  IZ(3)        
      CALL SKPREC (TRL,NS)        
   30 CALL READ (*240,*40,TRL,IZ(1),NZ,0,IFLAG)        
      GO TO 230        
   40 IF (IZ(1) .NE. ITSTEP) GO TO 30        
C        
C     TSTEP STUFF FOUND        
C        
      CALL CLOSE (TRL,1)        
      NGROUP = (IFLAG-1)/3        
C        
C     MOVE TSETP STUFF TO BOTTOM OF CURE        
C        
      NZ = NX - IFLAG + 1        
      IGROUP = NZ + 1        
      DO 50 I = 2,IFLAG        
      K = IGROUP + I - 2        
      IZ(K) = IZ(I)        
   50 CONTINUE        
      IBUF1 = NZ - SYSBUF + 1        
      IBUF2 = IBUF1 -SYSBUF        
      NZ = IBUF2        
      CALL GOPEN (ISCR5,IZ(IBUF1),1)        
      CALL WRITE (ISCR5,IZ(IGROUP),IFLAG-1,1)        
      FILE = USETD        
C        
C     BRING IN USETD        
C        
      CALL GOPEN (USETD,IZ(IBUF2),0)        
      CALL READ (*220,*60,USETD,IZ(1),NZ,1,LUSETD)        
      GO TO 230        
   60 CALL CLOSE (USETD,1)        
C        
C     BUILD SIL TO SILD CONVERTER TABLE        
C        
      MSKUE = TWO1(IUE)        
      MSKUD = TWO1(IUD)        
      M = 1        
      L = 0        
      DO 70 I = 1,LUSETD        
      IF (ANDF(IZ(I),MSKUE) .NE. 0) GO TO 65        
      L = L + 1        
      IF (ANDF(IZ(I),MSKUD) .EQ. 0) GO TO 67        
      IZ(L) = M        
   65 CONTINUE        
      M = M + 1        
      GO TO 70        
   67 IZ(L) = 0        
   70 CONTINUE        
C        
C     FIND STUFF IN GPTT        
C        
      ITS = INTMP        
      CALL MAKMCB (MCB,ISCR5,M-1,2,1)        
      NS  = 0        
      FILE = GPTT        
      CALL OPEN (*200,GPTT,IZ(IBUF2),0)        
C        
C     POSITION TO HEADER RECORD        
C        
      IVAL = NZ - 2*L        
      CALL READ (*220,*80,GPTT,IZ(L+1),IVAL,0,IFLAG)        
      GO TO 230        
C        
C     PUT OUT TEMPS        
C        
   80 CONTINUE        
C        
C     DETERMINE NUMBER OF ELEMENT TEMP RECORDS TO SKIP.        
C        
      LIST = L + 3        
      K = L + IFLAG        
   82 NSK = IZ(K)        
      IF (NSK .GT. 0) GO TO 84        
      K = K - 3        
      IF (K .GT. LIST) GO TO 82        
C        
C     SET IPOS TO SKIP ELEMENT TEMP RECORDS AND DUPLICATE HEADER.       
C        
   84 IPOS = -NSK        
      MCB(2) = 0        
   90 IF (ITS .EQ. 0) GO TO 170        
      K = LIST        
  100 IF (IZ(K) .EQ.  ITS) GO TO 110        
      K = K + 3        
      IF (K .GT. L+IFLAG) CALL MESAGE (-31,ITS,NAME)        
      GO TO 100        
C        
C     FOUND TEMP SET        
C        
  110 TDFLT = 0.0        
      IF (IZ(K+1) .NE. -1) TDFLT = Z(K+1)        
      M = L + IFLAG        
      DO 130 I = 1,L        
      J = M + I        
      Z(J) = TDFLT        
  130 CONTINUE        
C        
C     RECORD NUMBER OF TEMP SET FOUND        
C        
      NS = IZ(K+2)        
      IF (NS .EQ. 0) GO TO 150        
C        
C     SKIP TO DESIRED RECORD        
C        
  132 IF (NS-IPOS) 134,140,136        
  134 CALL BCKREC (GPTT)        
      IPOS = IPOS - 1        
      GO TO 132        
  136 CALL FWDREC (*220,GPTT)        
      IPOS = IPOS + 1        
      GO TO 132        
  140 CALL READ (*220,*145,GPTT,A,2,0,IFLG)        
      IF (IA(1) .LE. 0) GO TO 140        
      J = IA(1) + M        
      Z (J) = A(2)        
      GO TO 140        
  145 IPOS = IPOS + 1        
C        
C     ALL SET UP OUTPUT        
C        
  150 INEXT = M + 1        
      DO 160 I = 1,L        
      J = M + I        
      II = IZ(I) + M        
      IF (II .EQ. M) GO TO 160        
      IF (II .EQ. INEXT) GO TO 155        
      DO 153 K = INEXT,II        
  153 Z(K)  = 0.0        
  155 Z(II) = Z(J)        
      INEXT = II + 1        
  160 CONTINUE        
      J = INEXT - (M+1)        
      CALL WRITE (ISCR5,Z(M+1),J,0)        
  170 CALL WRITE (ISCR5,Z(1),0,1)        
      MCB(2) = MCB(2) + 1        
      IF (MCB(2) .EQ. 2) GO TO 190        
      ITS = INLTMP        
      GO TO 90        
C        
C     ALL DONE        
C        
  190 CALL CLOSE (ISCR5,1)        
      CALL CLOSE (GPTT,1)        
      CALL WRTTRL (MCB)        
      RETURN        
C        
C     ERROR MESAGES        
C        
  200 IP1 = -1        
  210 CALL MESAGE (IP1,FILE,NAME)        
      RETURN        
  220 IP1 = -2        
      GO TO 210        
  230 IP1 = -8        
      GO TO 210        
  240 CALL MESAGE (-31,ITSTEP,NAME)        
      RETURN        
      END        