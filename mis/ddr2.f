      SUBROUTINE DDR2        
C        
C     DYNAMIC DATA RECOVERY--PART 2 --MODE ACCELERATION        
C        
C     DMAP SEQUENCE        
C        
C     INPUTS = 9        
C        
C     USETD,VUD,PD,K2DD,B2DD,MDD,FRL,LLL,DM        
C        
C     OUTPUTS = 3        
C        
C     UAV,UEV,PAF        
C        
C     SCRATCHES = 6        
C        
C     PARAMETERS 1 BCD, 3INTEGERS        
C        
      INTEGER         USETD,PD,B2DD,FRL,DM,UAV,PAF,        
     1                SCR2,SCR3,SCR4,SCR5,SCR6,SCR7,        
     2                TYPE,REACT,TRAN,USET,VUD,PAD,UEV,PL        
      COMMON /BLANK / TYPE(2),NOUE,REACT,FRQSET        
      COMMON /BITPOS/ UM,UO,UR,USG,USB,UL,UA,UF,US,UN,UG,UE,UP,UNE,UFE, 
     1                UD        
      COMMON /PATX  / LC,N,NO,N4,USET        
CZZ   COMMON /ZZDDR1/ CORE(1)        
      COMMON /ZZZZZZ/ CORE(1)        
      DATA    USETD , VUD, PD, K2DD,B2DD,MDD,FRL,LLL,DM  /        
     1        101   , 102,103,  104, 105,106,107,108,109 /        
      DATA    UAV   , UEV, PAF, TRAN   /        
     1        201   , 202, 203, 4HTRAN /        
      DATA    SCR2  , SCR3,SCR4,SCR5,SCR6,SCR7,PAD /        
     1        302   , 303 , 304, 305, 306, 301,302 /        
C        
C        
      LC   = KORSZ(CORE)        
      VUD  = 102        
      SCR7 = 301        
      USET = USETD        
      PL   = SCR6        
      ISOL = SCR7        
      IF (NOUE .GE. 0) GO TO 10        
      PAD  = PAF        
   10 CONTINUE        
      IF (TYPE(1) .NE. TRAN) SCR7 = UAV        
      IF (TYPE(1).NE.TRAN .AND. REACT.LT.0 .AND. NOUE.GE.0) SCR7 = VUD  
C        
C     MODE ACCELERATION        
C        
C     FORM PAD        
C        
C        
      CALL DDR1A (PD,K2DD,B2DD,MDD,VUD,PAD,FRL,FRQSET,SCR3,SCR4,SCR5,   
     1            SCR6,TYPE(1),SCR7)        
C        
C     DISP ON SCR7 IN TRANSIENT        
C        
      IF (NOUE .LT. 0) GO TO 50        
      CALL CALCV (SCR3,UD,UA,UE,CORE(1))        
      CALL SSG2A (VUD,SCR4,UEV,SCR3)        
C        
C     UA IS ON SCR4        
C        
      VUD = SCR4        
C        
C     BREAK UP PAD        
C        
      CALL SSG2A (PAD,PAF,SCR5,SCR3)        
   50 IF (REACT .GE. 0) GO TO 90        
C        
C     UR NULL        
C        
      IF (TYPE(1) .NE. TRAN) SCR7 = ISOL        
      IF (TYPE(1).NE.TRAN .AND. NOUE.LT.0) SCR7 = UAV        
      CALL SSG3A (0,LLL,PAF,SCR7,SCR3,SCR6,-1,0)        
   60 IF (TYPE(1) .NE. TRAN) GO TO 80        
C        
C     MERGE RECALCULATED SOLUTIONS AND ACCEL AND VELOCITY        
C        
      ISOL = UAV        
      IF (NOUE .LT. 0) GO TO 70        
      ISOL = SCR5        
   70 CALL DDR1B (VUD,SCR7,ISOL)        
C        
C     BUILD UP TO DSIZE  ADDING IN UEV        
C        
   80 IF (NOUE .LT. 0) GO TO 30        
      CALL SDR1B (SCR4,ISOL,UEV,UAV,UD,UA,UE,USETD,0,0)        
   30 RETURN        
C        
C     FREE BODY PROBLEM        
C        
   90 CALL CALCV (SCR3,UA,UL,UR,CORE(1))        
C        
C     PARTITION PAF AND UA        
C        
      CALL SSG2A (PAF,PL,SCR5,SCR3)        
      IVEC = VUD        
      IF (TYPE(1) .EQ. TRAN) IVEC = SCR7        
      CALL SSG2A (IVEC,SCR2,SCR5,SCR3)        
C        
C     UR IS  ON SCR5        
C        
      CALL SSG3A (0,LLL,PL,SCR3,SCR2,SCR6,-1,0)        
      CALL SSG2B (DM,SCR5,SCR3,SCR4,0,2,1,SCR6)        
      CALL SDR1B (SCR3,SCR4,SCR5,SCR7,UA,UL,UR,USETD,0,0)        
      GO TO 60        
      END        
