      SUBROUTINE SCHEME (IG,INV,II3,INT,ICC,ILD,NORIG,IP,UN,Z)        
C        
      INTEGER         Z(1),     SCR1,     RD,       RDREW,    WRT,      
     1                WRTREW,   REW        
      DIMENSION       IG(1),    INV(1),   INT(1),   ICC(1),   ILD(1),   
     1                NORIG(1), IP(1),    SUB(2),   UN(1)        
      COMMON /BANDA / IBUF1,    DUM4A(4), METHOD,   ICRIT        
      COMMON /BANDB / NBITIN,   KORE,     IFL,      NGRID,    IPASS,    
     1                NW,       KDIM        
      COMMON /BANDD / DUM7D(7), NEQ,      NEQR        
      COMMON /BANDS / NN,       MM,       DUM2(2),  MAXGRD,   MAXDEG,   
     1                KMOD,     MACH,     MINDEG,   NEDGE        
      COMMON /GEOMX / GDUM(3),  SCR1        
      COMMON /SYSTEM/ IBUF,     NOUT        
      COMMON /NAMES / RD,       RDREW,    WRT,      WRTREW,   REW       
      DATA            SUB /     4HSCHE,4HME    /        
C        
C     THIS ROUTINE IS USED ONLY IN BANDIT MODULE        
C        
C     ZERO OUT CORE SPACE AND SET BANDWIDTH IMPROVEMENT FLAG, JUMP      
C     JUMP = 1,  NO IMPROVEMENT OF CRITERION SELECTED        
C          = 0,  IMPROVEMENT        
C        
      DO 10 I = 1,KORE        
 10   Z(I) = 0        
      JUMP = 1        
C        
C     READ ELEMENT DATA FROM GEOM2 FILE AND SET UP CONNECTION TABLE IG. 
C     ALSO, EXAMINE MPC EQUATIONS.        
C        
      CALL BREAD (IG,INV,II3,NORIG,Z)        
      IF (NGRID .LE. 0) RETURN        
C        
C     NGRID = NO. OF GRID POINTS IN THE PROBLEM        
C           =  0, ONE OR MORE SEQGP CARD IS PRESENT IN NASTRAN INPUT    
C                 DECK, AND/OR QDSEP ELEMENTS        
C           = -1, INSUFFICIENT CORE SPACE (IG TABLE TOO SMALL)        
C           = -2, INSUFFICIENT SCRATCH AREA WHILE USING CTHMCK        
C           = -3, INSUFFICIENT SCRATCH AREA WHILE USING GIBSTK        
C        
C     MODIFY IG TO ACCOUNT FOR MPC EQUATIONS AND RIGID ELEMENTS        
C        
      IF (NEQ+NEQR .NE. 0) CALL TIGER (IG,ICC,INV,II3,NORIG,Z,UN)       
C        
C     SORT ORIGINAL GRID NOS. AND OUTPUT THE LIST IN INT, WHERE INT(I)  
C     IS THE I-TH ORIGINAL GRID NUMBER.        
C     ALSO OUTPUT ILD, WHERE IDL(I) = SORTED INTERNAL NO. CORRESPONDING 
C     TO THE UNSORTED BANDIT INTERNAL LABEL I.        
C        
C     CALL BRIGIT (INV,II3,INT,ILD)        
C     BRIGIT AND INTERN ARE NOW REPLACED BY 17 LINES BELOW /G.CHAN 1988 
C        
      K = 0        
      DO 15 I = 1,II3        
      IF (INV(I) .EQ. 0) GO TO 15        
      K = K + 1        
      INT(K) = INV(I)        
 15   CONTINUE        
      CALL SORT (0,0,1,1,INT,NN)        
      DO 17 I = 1,NN        
      J = INT(I)        
      IF (J .LE. 0) GO TO 120        
      LOC = J - 1        
 16   LOC = MOD(LOC,KMOD) + 1        
      IF (INV(LOC) .EQ. 0) GO TO 120        
      IF (INV(LOC) .NE. J) GO TO 16        
      J = INV(LOC+II3)        
      ILD(J) = I        
 17   CONTINUE        
C        
C     METHOD WAS SET IN BANDIT -        
C     METHOD = -1, CM ONLY,    = +1, GPS ONLY,    = 0, BOTH METHODS.    
C        
      IF (METHOD .NE. 0) GO TO 20        
C        
C     SAVE ORIGINAL GRID POINT ORDERING (ILD) IN SCR1 FILE        
C        
      CALL OPEN (*70,SCR1,Z(IBUF1),WRTREW)        
      CALL WRITE (SCR1,ILD,NN,1)        
      CALL CLOSE (SCR1,REW)        
C        
C     RE-SEQUENCE GRIDS WITH CUTHILL-MCKEE ALGORITHM        
C        
 20   I = MAXGRD + 2        
      J = I + MAXGRD        
      IF (MAXDEG .GT. MAXGRD) J = J + MAXDEG - MAXGRD        
      K = J + MAXGRD        
      CALL CTHMCK (80,1,2,ICRIT,IG,INV,INV(I),INV(J),INV(K),INT,ICC,    
     X             ILD,IP,JUMP,UN,Z)        
      NGRID1 = NGRID        
      IF (METHOD) 60,25,30        
C        
C     READ ORIGINAL SEQUENCE BACK IF CTHMCK MAKES NO IMPROVEMENT        
C        
 25   IF (JUMP .EQ. 0) GO TO 30        
      CALL OPEN (*70,SCR1,Z(IBUF1),RDREW)        
      CALL READ (*80,*80,SCR1,ILD,NN,1,M)        
      CALL CLOSE (SCR1,REW)        
 30   DO 40 K1 = 1,NN        
 40   INT(K1) = ILD(K1)        
C        
C     RESEQUENCE NODES WITH GPS ALGORITHM.        
C        
      K1 = 1        
      K2 = K1 + KDIM        
      K3 = K2 + KDIM        
      K4 = K3 + KDIM        
      K5 = K4 + KDIM/2        
      CALL GIBSTK (IG,INT,ILD,INV(I),INV,INV(J),INV(K),ICC,JUMP,ICRIT,  
     1             Z(K1),Z(K2),Z(K3),Z(K4),Z(K5),UN,KDIM)        
C        
C     GENERATE SEQGP CARDS AND OUTPUT THEM TO GEOM1 FILE        
C        
 60   CALL BSEQGP (NORIG,ILD,JUMP)        
      IF (NGRID1.EQ.-2 .OR. NGRID.EQ.-3) GO TO 100        
      RETURN        
C        
C     SCRATCH FILE ERROR        
C        
 70   K = -1        
      GO TO 90        
 80   K = -2        
 90   CALL MESAGE (K,SCR1,SUB)        
C        
 100  WRITE  (NOUT,110) KDIM        
 110  FORMAT (28H0*** BANDIT SCRATCH ARRAY OF,I5,20H WORDS IS TOO SMALL.
     1,/5X,57HUSER COULD USE ONE OF THE FOLLOWING OPTIONS AND RESUBMIT ,
     2 27HJOB. (USERS MANUAL P.2.1-1), /5X,        
     2 53HINCREASE SCRATCH ARRAY BY NASTRAN BANDTDIM OPTION, OR, /5X,   
     3 53HSWITCH TO CUTHILL-MCKEE METHOD ONLY BY  BANDTMTH=1 OR, /5X,   
     4 57HSKIP BANDIT COMPUTATION BY SETTING NASTRAN CARD BANDIT=-1,//) 
      GO TO 140        
C        
 120  WRITE  (NOUT,130) K,NN,II3,KMOD,MAXGRD,MAXDEG        
 130  FORMAT ('0*** BANDIT FATAL ERROR - TRY TO RERUN JOB WITH ',       
     1       22H'NASTRAN BANDTDIM = N',' WHERE N = 3,4,...,OR 9', //5X, 
     2       '@17/  K,NN,II3,KMOD,MAXGRD,MAXDEG =',6I8)        
 140  CALL MESAGE (-37,SUB,SUB)        
      RETURN        
      END        