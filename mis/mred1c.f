      SUBROUTINE MRED1C        
C        
C     THIS SUBROUTINE CONVERTS THE EQSS DATA AND BGSS DATA TO CORRESPOND
C     TO THE BOUNDARY DEGREES OF FREEDOM (UB) FOR THE MRED1 MODULE      
C        
C     INPUT DATA        
C     SOF - BGSS - BASIC GRID POINT IDENTIFICATION TABLE        
C        
C     OUTPUT DATA        
C     GINO - EQST - TEMPORARY EQSS DATA FILE        
C        
C     PARAMETERS        
C     INPUT - GBUF1  - GINO BUFFER        
C             KORLEN - LENGTH OF OPEN CORE        
C             NEWNAM - NAME OF NEW SUBSTRUCTURE        
C             RGRID  - FREEBODY MODE IDENTIFICATION NUMBERS (SET IN     
C                      MRED1)        
C                      RGRID(1) .EQ. GRID POINT IDENTIFICATION NUMBER   
C                      RGRID(2) .EQ. NUMBER OF CONTRIBUTING SUBSTRUCTURE
C             NCSUBS - NUMBER OF CONTRIBUTING SUBSTRUCTURES        
C             NAMEBS - BEGINNING ADDRESS OF BASIC SUBSTRUCTURE NAMES    
C             EQSIND - BEGINNING ADDRESS OF EQSS GROUP ADDRESSES        
C             NSLBGN - BEGINNING ADDRESS OF SIL DATA        
C             NSIL   - NUMBER OF SIL GROUPS        
C             LOCUST - BEGINNING ADDRESS OF USET ARRAY        
C        
      EXTERNAL        ANDF,ORF        
      LOGICAL         BOUNDS        
      INTEGER         OLDNAM,DRY,GBUF1,EQSIND,RGRID,Z,SILDOF,UB,ESTDTA, 
     1                SILIND,ESTWRT,BITPAT,EQST,EQSTRL,ANDF,ORF        
      DIMENSION       BITPAT(32),MODNAM(2),EQSTRL(7)        
      COMMON /BLANK / OLDNAM(2),DRY,IDUM1(6),GBUF1,IDUM2(4),KORLEN,     
     1                NEWNAM(2),IDUM3(4),RGRID(2),IDUM4(4),NCSUBS,      
     2                NAMEBS,EQSIND,NSLBGN,NSIL,IDUM6(3),LOCUST,        
     3                IDUM7(4),BOUNDS        
CZZ   COMMON /ZZMRD1/ Z(1)        
      COMMON /ZZZZZZ/ Z(1)        
      COMMON /TWO   / ITWO(32)        
      COMMON /BITPOS/ IDUM5(20),UB        
      DATA    EQST  , NHBGSS,MODNAM / 203,4HBGSS,4HMRED,4H1C  /        
C        
C     IF OLDBOUNDS OPTION, GET EQST TRAILER        
C        
      IF (DRY .EQ. -2) RETURN        
      EQSTRL(1) = EQST        
      IF (.NOT. BOUNDS) GO TO 5        
      CALL RDTRL (EQSTRL)        
C        
C     GET SIL DOF AND DECODE        
C        
    5 NEWIPS = 0        
      DO 30 I = 1,NSIL        
      SILDOF = NSLBGN + ((2*I) - 1)        
      ICODE  = Z(SILDOF)        
      CALL DECODE (ICODE,BITPAT,NWDSD)        
C        
C     TEST FOR DOF REMAINING IN BOUNDARY SET        
C        
      NDOF = 0        
      KOMPNT = 0        
      DO 10 J = 1,NWDSD        
      K = LOCUST + (Z(SILDOF-1)-1) + (J-1)        
      IF (ANDF(Z(K),ITWO(UB)) .EQ. 0) GO TO 10        
      K = 32 - BITPAT(J)        
      KOMPNT = ORF(KOMPNT,ITWO(K))        
      NDOF = NDOF + 1        
   10 CONTINUE        
C        
C     SAVE NEW SIL DATA        
C        
      IF (NDOF .EQ. 0) GO TO 20        
      NEWIPS = NEWIPS + 1        
      Z(SILDOF-1) = (8*NEWIPS) + NDOF        
      Z(SILDOF) = KOMPNT        
      GO TO 30        
C        
C     SIL DATA NOT NEEDED        
C        
   20 Z(SILDOF-1) = -1        
   30 CONTINUE        
C        
C     WRITE EQSS GROUP 0 DATA ONTO TEMPORARY EQST TABLE        
C        
      CALL GOPEN (EQST,Z(GBUF1),1)        
      CALL WRITE (EQST,NEWNAM,2,0)        
      CALL WRITE (EQST,NCSUBS,1,0)        
      CALL WRITE (EQST,NEWIPS,1,0)        
      NWDS = EQSIND - NAMEBS        
      CALL WRITE (EQST,Z(NAMEBS),NWDS,1)        
      EQSTRL(2) = NWDS + 4        
C        
C     WRITE REMAINING EQSS GROUP DATA ONTO TEMPORARY EQST TABLE        
C        
      EQSTRL(3) = NCSUBS        
      DO 60 I = 1,NCSUBS        
      J = 2*(I-1)        
      ESTDTA = Z(EQSIND+J)        
      NWDS = Z(EQSIND+J+1)        
C        
C     TEST SUBSTRUCTURE COMPONENTS        
C        
      IF (NWDS .LE. 0) GO TO 60        
      DO 50 J = 1,NWDS,3        
      SILIND = NSLBGN + (2*(Z(ESTDTA+J) - 1))        
      IF (RGRID(1) .LE. 0) GO TO 40        
      IF (I .NE. RGRID(2)) GO TO 40        
      IF (RGRID(1) .NE. Z(ESTDTA+J-1)) GO TO 40        
      RGRID(1) = Z(ESTDTA+J)        
   40 IF (Z(SILIND) .EQ. -1) GO TO 50        
C        
C     REPLACE IP, SIL NUMBERS AND WRITE DATA        
C        
      ESTWRT = ESTDTA + J        
      Z(ESTWRT  ) = Z(SILIND)/8        
      Z(ESTWRT+1) = Z(SILIND+1)        
      CALL WRITE (EQST,Z(ESTWRT-1),3,0)        
   50 CONTINUE        
   60 CALL WRITE (EQST,0,0,1)        
C        
C     REDUCE SIL ENTRIES AND STORE NEW SIL DATA AT Z(2*NSIL)        
C        
      NDOF   = 1        
      LOINDX = 0        
      NEWSIL = NSLBGN + (2*NSIL)        
      IF ((NEWSIL+(2*NSIL)) .GE. KORLEN) GO TO 130        
      DO 70 I = 1,NSIL        
      J = 2*(I-1)        
      IF (Z(NSLBGN+J) .EQ. -1) GO TO 70        
      Z(NEWSIL+LOINDX  ) = NDOF        
      Z(NEWSIL+LOINDX+1) = Z(NSLBGN+J+1)        
      NDOF = NDOF + ANDF(Z(NSLBGN+J),7)        
      LOINDX = LOINDX + 2        
   70 CONTINUE        
C        
C     WRITE SIL DATA ONTO TEMPORARY EQST TABLE        
C        
      KORBGN = NAMEBS        
      IF (LOINDX .LE. 0) CALL WRITE (EQST,0,0,1)        
      IF (LOINDX .GT. 0) CALL WRITE (EQST,Z(NEWSIL),LOINDX,1)        
      EQSTRL(4) = LOINDX        
C        
C     READ AND WRITE BGSS GROUP 0 DATA        
C        
      CALL SFETCH (OLDNAM,NHBGSS,1,ITEST)        
      IF (ITEST .EQ. 3) GO TO 90        
      IF (ITEST .EQ. 4) GO TO 100        
      IF (ITEST .EQ. 5) GO TO 110        
      CALL SUREAD (Z(KORBGN),-1,NWDSRD,ITEST)        
      Z(KORBGN  ) = OLDNAM(1)        
      Z(KORBGN+1) = OLDNAM(2)        
      NBGSS = Z(KORBGN+2)        
      Z(KORBGN+2) = LOINDX/2        
      CALL WRITE (EQST,Z(KORBGN),3,1)        
C        
C     ELIMINATE BGSS DATA NOT REQUIRED        
C        
      I = 0        
      EQSTRL(5) = 0        
      DO 80 J = 1,NBGSS        
      CALL SUREAD (Z(KORBGN),4,NWDSRD,ITEST)        
      IF (I .GT. (2*NSIL)) GO TO 80        
      IF (Z(NSLBGN+I) .EQ. -1) GO TO 80        
      CALL WRITE (EQST,Z(KORBGN),4,0)        
      EQSTRL(5) = EQSTRL(5) + 4        
   80 I = I + 2        
      CALL WRITE  (EQST,0,0,1)        
      CALL WRTTRL (EQSTRL)        
C        
C     CLOSE EQST FILE        
C        
      CALL CLOSE (EQST,1)        
      RETURN        
C        
C     PROCESS MODULE FATAL ERRORS        
C        
   90 IMSG = -1        
      GO TO 120        
  100 IMSG = -2        
      GO TO 120        
  110 IMSG = -3        
  120 CALL SMSG (IMSG,NHBGSS,OLDNAM)        
      RETURN        
C        
C     PROCESS SYSTEM FATAL ERRORS        
C        
  130 IMSG = -8        
      IFILE = 0        
      CALL SOFCLS        
      CALL MESAGE (IMSG,IFILE,MODNAM)        
C        
      RETURN        
      END        