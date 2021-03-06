      SUBROUTINE FNDLVL (NAME,NEWNM)        
C        
C     THIS SUBROUTINE LOOKS FOR A LOWER LEVEL SUBSTRUCTUE TO THE        
C     SUBSTRUCTURE NAME.  IF NAME DOES HAVE A LOWER LEVEL SUBSTRUCTURE, 
C     THE NAME OF ONE OF THESE LOWER LEVEL SUBSTRUCTURES WILL BE        
C     RETURNED IN NEWNM.  IF NAME DOES NOT HAVE A LOWER LEVEL        
C     SUBSTRUCTURE, NAME WILL BE RETURNED IN NEWNM.  IF NAME IS NOT     
C     KNOWN TO THE SYSTEM, BLANKS WILL BE RETURNED IN NEWNM.        
C        
      EXTERNAL        RSHIFT,ANDF        
      INTEGER         RSHIFT,ANDF,BUF        
      DIMENSION       NAME(2),NEWNM(2),NMSBR(2)        
CZZ   COMMON /SOFPTR/ BUF(1)        
      COMMON /ZZZZZZ/ BUF(1)        
      DATA    LL    / 2 /        
      DATA    IEMPTY/ 4H     /, NMSBR / 4HFNDL,4HVL   /        
C        
C     CHECK IF NAME EXISTS        
C        
      CALL CHKOPN (NMSBR(1))        
      CALL FDSUB (NAME(1),K)        
      IF(K .NE. -1) GO TO 10        
      NEWNM(1) = IEMPTY        
      NEWNM(2) = IEMPTY        
      RETURN        
C        
C     FIND THE LOWER LEVEL SUBSTRUCTURE        
C        
   10 CALL FMDI (K,IMDI)        
      ILL = ANDF(RSHIFT(BUF(IMDI+LL),20),1023)        
      IF(ILL .EQ. 0) GO TO 20        
C        
C     NAME DOES HAVE A LOWER LEVEL SUBSTRUCTURE        
C        
      CALL FDIT (ILL,JDIT)        
      NEWNM(1) = BUF(JDIT)        
      NEWNM(2) = BUF(JDIT+1)        
      RETURN        
C        
C     NAME DOES NOT HAVE A LOWER LEVEL SUBSTRUCTURE        
C        
   20 NEWNM(1) = NAME(1)        
      NEWNM(2) = NAME(2)        
      RETURN        
      END        
