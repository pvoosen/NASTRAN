      SUBROUTINE SHGMGS (*,ELID,TEM,MID,TS,NOALFA,G,RHO,GSUBE,TSUB0,    
     1                   EGNOR,ALPHA)        
C        
C     MATERIAL PROPERTY G-MATRICES GENERATOR FOR SHELL ELEMENTS        
C        
C     SINGLE PRECISION VERSION        
C        
C     INPUT :        
C           ELID   - ELEMENT ID        
C           TEM    - 3X3 TRANSFORMATION BETWEEN ELEMENT AND MATERIAL    
C                    COORDINATE SYSTEMS        
C           MID    - ARRAY OF LENGTH 4, CONTAINS MATERIAL ID'S        
C           TS     - EQUIVALENT SHEAR THICKNESS        
C           NOALFA - LOGICAL TO REQUEST OR NOT REQUEST THERMAL EXPANSION
C                    COEFFICIENTS        
C        
C     OUTPUT:        
C           G      - ARRAY OF LENGTH 36 (FOUR 3X3), CONATINS MATERIAL   
C                    PROPERTIES IN ELEMENT COORD. SYSTEM        
C           RHO    - MASS DENSITY FROM MEMBRANE MATERIAL        
C           GSUBE  - DAMPING COEFFICIENT FROM MEMBRANE OR BENDING       
C                    MATERIALS        
C           TSUB0  - REFERENCE TEMPERATURE        
C           EGNOR  - ARRAY OF PSEUDO E'S AND G'S FOR SHEAR FACTOR       
C                    CALCULATIONS IN BENDING        
C           ALPHA  - ARRAY OF THERMAL EXPANSION COEFFICIENTS        
C        
C     NOTES:        
C           1- THIS ROUTINE BUILDS THE MATERIAL PROPERTY MATRIX USING   
C              THE OUTPUT OF SUBROUTINE 'MAT' (/MATOUT/).        
C              /MATOUT/ IS IN MAT2 FORMAT IF MAT1 AND/OR MAT2 ARE USED  
C              /MATOUT/ IS IN MAT8 FORMAT IF MAT8 CARD IS REQUESTED.    
C           2- ISOTROPIC, ORTHOTROPIC, AND ANISOTROPIC PROPERTY TYPES   
C              ARE SUPPORTED.        
C           3- PROPERTIES FOR MEMBRANE, BENDING, SHEAR FLEXIBILITY, AND 
C              MEMBRANE/BENDING COUPLING ARE PROCESSED.        
C           4- NON-STANDARD RETURN IS TAKEN WHEN THE MATERIAL FOR SHEAR 
C              FLEXIBILITY IS NOT PROPERLY DEFINED.        
C           5- SOME OF THE CONTENTS OF /MATIN/ MUST BE DEFINED PRIOR TO 
C              A CALL TO THIS ROUTINE.        
C           6- CONTENTS OF /TERMS/, MID, AND TS MAY BE CHANGED IN THIS  
C              ROUTINE.        
C        
C        
C        
      LOGICAL          MEMBRN,BENDNG,SHRFLX,MBCOUP,NORPTH,NOALFA        
      INTEGER          MID(4),INDEX(3,3),ELID,NAME(2)        
      REAL             NU12,NU21,MATSET        
      REAL             G(36),TEM(9),U(9),GT(9),EGNOR(4),DN12,DN21,PS1,  
     1                 PS2,RHO,TS,CONST,ALPHA(6),TALPHA(6),DETU,BDUM    
      COMMON /TERMS /  MEMBRN,BENDNG,SHRFLX,MBCOUP,NORPTH        
      COMMON /MATIN /  MATID,INFLAG,ELTEMP,DUMMY,SINMAT,COSMAT        
      COMMON /MATOUT/  G11,G12,G13,G22,G23,G33,RHOX,ALPH1,ALPH2,ALPH12, 
     1                 TREF,GE,ST,SC,SS,E,DUM(8),MATSET        
C                      MAT8 FORMAT...        
      EQUIVALENCE      (E1 ,G11),(NU12,G12),(E2,G13),(G2Z,G23),        
     1                 (G1Z,G33),(G12X,G22)        
C    2,                (GE  ,E  ),(T0,ALPH12)        
C             EQUIV    (MATOUT(1),G11))        
      DATA    NAME  /  4HSHGM,4HGS    /        
C        
C        
C     INITIALIZE        
C        
C     SET INFLAG = 12 SO THAT SUBROUTINE MAT WILL SEARCH FOR:        
C     ISOTROPIC   MATERIAL PROPERTIES AMONG THE MAT1 CARDS,        
C     ORTHOTROPIC MATERIAL PROPERTIES AMONG THE MAT8 CARDS, AND        
C     ANISOTROPIC MATERIAL PROPERTIES AMONG THE MAT2 CARDS.        
C        
      DO 10 IG = 1,36        
   10 G(IG) = 0.0        
      DO 20 IG = 1,4        
   20 EGNOR(IG) = 0.0        
      IF (NOALFA) GO TO 40        
      DO 30 IG = 1,6        
      ALPHA(IG) = 0.0        
   30 CONTINUE        
C        
   40 RHO   = 0.0        
      GSUBE = 0.0        
      TSUB0 = 0.0        
      INFLAG= 12        
      IGOBK = 0        
      IT0   = 0        
C        
C     BEGIN THE LOOP TO FETCH PROPERTIES FOR EACH MATERIAL ID. FOR SHEAR
C     FLEXIBILITY MATERIAL, DEFAULT TO THE BENDING MATERIAL IF BENDING  
C     IS PRESENT.        
C     IF SHEAR MATERIAL IS PRESENT, BUT YIELDS ZEROES, GO BACK AND RESET
C     IT TO BENDING MATERIAL.        
C        
      M = 0        
  100 LPOINT = M*9        
      M = M + 1        
      IF (M .GT. 4) GO TO 600        
      IF (M.EQ.4 .AND. IGOBK.EQ.1) GO TO 610        
      MATID = MID(M)        
      IF (MATID.EQ.0 .AND. M.NE.3) GO TO 100        
      IF (MATID.EQ.0 .AND. M.EQ.3. AND. .NOT.BENDNG) GO TO 100        
      IF (MATID.EQ.0 .AND. M.EQ.3. AND. BENDNG) MATID = MID(2)        
C        
      IF (M-1) 130,120,110        
  110 IF (MATID.EQ.MID(M-1) .AND. IGOBK.EQ.0) GO TO 130        
  120 CALL MAT (ELID)        
      TMTSET = MATSET        
      IF (MATSET .EQ. 8.0) TMTSET = 3.0        
      MTYPE = IFIX(TMTSET+0.05) - 2        
C        
C     SET THE MISC ITEMS        
C        
  130 IF (MEMBRN .AND. M.EQ.1) RHO = RHOX        
      IF (MEMBRN .AND. M.NE.1 .OR. .NOT.MEMBRN .AND. M.NE.2) GO TO 140  
      GSUBE = GE        
      IF (MTYPE .GT. 0) GSUBE = E        
  140 IF (IT0 .GT. 0) GO TO 150        
      IT0   = 1        
      TSUB0 = TREF        
      IF (MTYPE .GT. 0) TSUB0 = ALPH12        
C        
C     BRANCH ON MATERIAL TYPE        
C        
  150 IF (MTYPE) 200, 210, 250        
C               MAT1,MAT2,MAT8        
C        
C        
C     ISOTROPIC  MATERIALS (MAT1)        
C     ---------------------------        
C        
C 200 IF (M .NE. 3) GO TO 205        
  200 IF (M .NE. 3) GO TO 220        
C        
C     G(LPOINT+1) = MATOUT(3)   <== G13, SHOULD BE MATOUT(6) <== G33    
C     G(LPOINT+4) = G(LPOINT+1)        
C     IF (G(LPOINT+1).EQ.0.0 .AND. SHRFLX) GO TO 300        
C        
      G(LPOINT+1) = G33        
      G(LPOINT+4) = G33        
      IF (G33.EQ.0.0 .AND. SHRFLX) GO TO 300        
      GO TO 400        
C        
C     ACCORDING TO Q4GMGS, SHOULD TO TO 220 NEXT        
C        
C 205 G(LPOINT+1) = G22        
C     G(LPOINT+2) = G12*G22        
C     G(LPOINT+4) = G12*G22        
C     G(LPOINT+5) = G22        
C     G(LPOINT+9) = G13         <== G13,  SHOULD IT BE G33 ??        
C     GO TO 400        
C        
C     ANISOTROPIC  MATERIALS (MAT2)        
C     -----------------------------        
C        
  210 IF (M .EQ. 3) GO TO 230        
  220 G(LPOINT+1) = G11        
      G(LPOINT+2) = G12        
      G(LPOINT+3) = G13        
      G(LPOINT+4) = G12        
      G(LPOINT+5) = G22        
      G(LPOINT+6) = G23        
      G(LPOINT+7) = G13        
      G(LPOINT+8) = G23        
      G(LPOINT+9) = G33        
      GO TO 400        
C        
  230 IF (SHRFLX) GO TO 240        
      IF (G11.EQ.0.0 .OR. G22.EQ.0.0) GO TO 400        
      DN21  = G12/G11        
      DN12  = G12/G22        
      CONST = DN21*DN12        
      IF (CONST .LT. 0.0) GO TO 400        
      PS1 = G11*(1.0-CONST)        
      PS2 = G22*(1.0-CONST)        
      IF (CONST .GT. 0.0) CONST = SQRT(CONST)        
      CONST = 2.0*(1.0+CONST)        
      G(LPOINT+1) = PS1/CONST        
      G(LPOINT+4) = PS2/CONST        
      GO TO 400        
C        
  240 G(LPOINT+1) = G11        
      G(LPOINT+2) = G12        
      G(LPOINT+3) = G12        
      G(LPOINT+4) = G22        
      IF (G33 .NE. 0.0) GO TO 300        
      GO TO 400        
C        
C     ORTHOTROPIC MATERIALS (MAT8)        
C     ----------------------------        
C        
  250 IF (M  .EQ.   3) GO TO 260        
      IF (E1 .EQ. 0.0) GO TO 400        
      NU21 = NU12*E2/E1        
      CONST= 1.0 - NU21*NU12        
      IF (CONST .LE. 0.0) GO TO 400        
      G(LPOINT+1) = E1/CONST        
      G(LPOINT+2) = NU12*E2/CONST        
      G(LPOINT+4) = G(LPOINT+2)        
      G(LPOINT+5) = E2/CONST        
      G(LPOINT+9) = G12X        
      GO TO 400        
C        
  260 IF (SHRFLX) GO TO 270        
      IF (E1 .EQ. 0.0) GO TO 400        
      NU21  = NU12*E2/E1        
      CONST = NU21*NU12        
      IF (CONST .LE. 0.0) GO TO 400        
      CONST = SQRT(CONST)        
      CONST = 2.0*(1.0+CONST)        
      G(LPOINT+1) = E1/CONST        
      G(LPOINT+4) = E2/CONST        
      GO TO 400        
C        
C 270 G(LPOINT+1) = MATOUT(5)         <== COSMIC (5) & (6) INTERCHANGED 
C     G(LPOINT+4) = MATOUT(6)        
  270 G(LPOINT+1) = G1Z        
      G(LPOINT+4) = G2Z        
      IF (G1Z.EQ.0.0 .AND. G2Z.EQ.0.0) GO TO 300        
      GO TO 400        
C        
C     BAD SHEAR MATERIAL        
C        
  300 IF (.NOT.SHRFLX .AND. BENDNG) GO TO 400        
      RETURN 1        
C        
C     TRANSFORM NON-ISOTROPIC MATERIALS        
C        
  400 IF (MTYPE .LT. 0) GO TO 430        
      IF (M     .EQ. 3) GO TO 410        
      U(1) = TEM(1)*TEM(1)        
      U(2) = TEM(4)*TEM(4)        
      U(3) = TEM(1)*TEM(4)        
      U(4) = TEM(2)*TEM(2)        
      U(5) = TEM(5)*TEM(5)        
      U(6) = TEM(2)*TEM(5)        
      U(7) = TEM(1)*TEM(2)*2.0        
      U(8) = TEM(4)*TEM(5)*2.0        
      U(9) = TEM(1)*TEM(5) + TEM(2)*TEM(4)        
      L    = 3        
      GO TO 420        
C        
  410 U(1) = TEM(5)*TEM(9) + TEM(6)*TEM(8)        
      U(2) = TEM(2)*TEM(9) + TEM(8)*TEM(3)        
      U(3) = TEM(4)*TEM(9) + TEM(7)*TEM(6)        
      U(4) = TEM(1)*TEM(9) + TEM(3)*TEM(7)        
      L    = 2        
C        
  420 CALL GMMATS ( U(1),L,L,1, G(LPOINT+1),L,L,0, GT(1))        
      CALL GMMATS (GT(1),L,L,0, U(1),L,L,0,  G(LPOINT+1))        
C        
C     GET THE THERMAL EXPANSION COEFFICIENTS, IF NEEDED        
C        
  430 IF (NOALFA .OR. M.GT.2) GO TO 100        
      MORB = (M-1)*3        
      IF (MTYPE) 500 ,510 ,520        
C                MAT1,MAT2,MAT8        
C        
C     MAT1        
C        
  500 ALPHA(MORB+1) = ALPH1        
      ALPHA(MORB+2) = ALPH1        
      ALPHA(MORB+3) = 0.0        
      GO TO 100        
C        
C     MAT2        
C        
  510 ALPHA(MORB+1) = ALPH1        
      ALPHA(MORB+2) = ALPH2        
      ALPHA(MORB+3) = ALPH12        
      GO TO 530        
C        
C     MAT8        
C        
  520 ALPHA(MORB+1) = ALPH1        
      ALPHA(MORB+2) = ALPH2        
      ALPHA(MORB+3) = 0.0        
C        
C     TRANSFORM THERMAL EXPANSION COEFFICIENTS AND STORE THEM IN ALPHA. 
C     THE ALPHAS NEED TO BE PREMULTIPLIED BY [U] INVERSE.        
C        
  530 DO 540 IG = 1,3        
  540 TALPHA(IG+MORB) = ALPHA(IG+MORB)        
      MORB = MORB + 1        
      CALL INVERS (3,U,3,BDUM,0,DETU,ISNGU,INDEX)        
      CALL GMMATS (U,3,3,0, TALPHA(MORB),3,1,0, ALPHA(MORB))        
      GO TO 100        
C        
C        
C     LOOP IS DONE, CHECK FOR ALL ZEROES FOR SHEAR MATERIAL        
C        
  600 IF (G(19).NE.0.0 .OR. G(20).NE.0.0 .OR. G(21).NE.0.0 .OR.        
     1    G(22).NE.0.0) GO TO 610        
      IGOBK  = 1        
      M      = 2        
      MID(3) = 0        
      SHRFLX = .FALSE.        
      TS     = 0.833333333        
C              0.833333333 = 5.0/6.0        
      GO TO 100        
C        
C     SAVE PSEUDO E'S AND G'S FOR SHEAR FACTOR CALCULATIONS        
C        
  610 IF (.NOT.BENDNG) GO TO 620        
      EGNOR(1) = G(10)        
      EGNOR(2) = G(14)        
      EGNOR(3) = G(19)        
      EGNOR(4) = G(22)        
C        
  620 RETURN        
      END        
