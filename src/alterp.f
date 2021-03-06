*DECK ALTERP
*     This is a modifedf version of the code written by Alain Hebert.
*     The array WK is used as an argument in order to avoid allocation
*     in Fortran, since this can cause problem withe the '".Fortran' 
*     R interface.        

      SUBROUTINE ALTERP(LCUBIC, N, X, VAL, LDERIV, TERP, WK)
*
*-----------------------------------------------------------------------
*
*Purpose:
* determination of the TERP interpolation/derivation components using
* the order 4 Ceschino method with cubic Hermite polynomials.
*
*Copyright:
* Copyright (C) 2006 Ecole Polytechnique de Montreal
* This library is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version
*
*Author(s): A. Hebert
*
*Parameters: input
* LCUBIC  =.TRUE.: cubic Ceschino interpolation; =.FALSE: linear
*         Lagrange interpolation.
* N       number of points.
* X       abscissas
* VAL     abscissa of the interpolated point.
* LDERIV  set to .true. to compute the first derivative with respect
*         to X. Set to .false. to interpolate.
*
*Parameters: output
* TERP    interpolation/derivation components.
*
*-----------------------------------------------------------------------
*
*----
*  SUBROUTINE ARGUMENTS
*----
      INTEGER N, LCUBIC, LDERIV
      double precision X(N), VAL, TERP(N)
*---
* LOCAL VARIABLES
*---
      CHARACTER HSMG*131
      double precision WK(3, N)
*
      I0 = 0
      IF (N .LE. 1) RETURN
      IF (N .EQ. 2) GO TO 110
      DO 10 I = 1, N
      WK(3, I) = 0.0
   10 TERP(I) = 0.0
*----
*  INTERVAL IDENTIFICATION.
*----
      DO 20 I = 1, N-1
      IF ((VAL .GE. X(I)) .AND. (VAL .LE. X(I + 1))) THEN
         I0 = I
         GO TO 30
      ENDIF
   20 CONTINUE
c$$$      WRITE(HSMG,'(35HALTERP: UNABLE TO INTERPOLATE (VAL=,1P,E11.4,
c$$$     1 8H LIMITS=,E11.4,2H, ,E11.4,2H).)') VAL, X(1), X(N)
      return
   30 DX = X(I0 + 1) - X(I0)
*     write ( *, * ) 'DX = ', DX
*----
*  LINEAR LAGRANGE POLYNOMIAL.
*----
      IF(LCUBIC .LE. 0) THEN
        IF (LDERIV .GT. 0) THEN
           TERP(I0) = -1.0 / DX
           TERP(I0 + 1) = 1.0 / DX
        ELSE
           TERP(I0) = (X(I0 + 1) - VAL) / DX
           TERP(I0 + 1) = 1.0 - TERP(I0)
        ENDIF
        RETURN
      ENDIF
*----
*  CESCHINO CUBIC POLYNOMIAL.
*----
      U = (VAL - 0.5 * (X(I0) + X(I0 + 1))) / DX
      IF (LDERIV .GT. 0) THEN
         H1 = (-6.0 * (0.5 - U) + 6.0 * (0.5 - U)**2) / DX
         H2 = (-2.0 * (0.5 - U) + 3.0 * (0.5 - U)**2) / DX
         H3 = (6.0 * (0.5 + U) - 6.0 * (0.5 + U)**2) / DX
         H4 = (-2.0 * (0.5 + U) + 3.0 * (0.5 + U)**2) / DX
         TEST = 0.0
      ELSE
         H1 = 3.0 * (0.5 - U)**2 - 2.0 * (0.5 - U)**3
         H2 = (0.5 - U)**2 - (0.5 - U)**3
         H3 = 3.0 * (0.5 + U)**2 - 2.0*(0.5 + U)**3
         H4 = -(0.5 + U)**2 + (0.5 + U)**3
         TEST = 1.0
      ENDIF
      TERP(I0) = H1
      TERP(I0 + 1) = H3
      WK(3, I0) = H2 * DX
      WK(3, I0 + 1) = H4 * DX
*----
*  COMPUTE THE COEFFICIENT MATRIX.
*----
      HP = 1.0 / (X(2) - X(1))
      WK(1, 1) = HP
      WK(2, 1) = HP
      DO 40 I = 2, N-1
      HM = HP
      HP = 1.0 / (X(I + 1) - X(I))
      WK(1, I) = 2.0 * (HM + HP)
   40 WK(2, I) = HP
      WK(1,N) = HP
      WK(2,N) = HP
*----
*  FORWARD ELIMINATION.
*----
      PMX = WK(1, 1)
      WK(3, 1) = WK(3, 1) / PMX
      DO 50 I = 2, N
      GAR = WK(2, I - 1)
      WK(2, I - 1) = WK(2, I - 1) / PMX
      PMX = WK(1, I) - GAR * WK(2, I - 1)
   50 WK(3, I) = (WK(3, I) - GAR * WK(3, I - 1)) / PMX
*----
*  BACK SUBSTITUTION.
*----
      DO 60 I = N-1, 1, -1
   60 WK(3, I) = WK(3, I) - WK(2, I) * WK(3, I + 1)
*----
*  COMPUTE THE INTERPOLATION FACTORS.
*----
      DO 100 J= 1, N
      IMIN = MAX(2, J - 1)
      IMAX = MIN(N - 1, J + 1)
      DO 70 I = 1, N
   70 WK(1, I) = 0.0
      WK(1, J) = 1.0
      HP = 1.0 / (X(IMIN) - X(IMIN - 1))
      YLAST = WK(1, IMIN - 1)
      WK(1, IMIN - 1) = 2.0 * HP * HP * (WK(1, IMIN) - WK(1, IMIN - 1))
      DO 80 I = IMIN,IMAX
      HM = HP
      HP = 1.0/(X(I + 1) - X(I))
      PMX = 3.0*(HM*HM*(WK(1, I)-YLAST) +HP*HP*(WK(1, I + 1)- WK(1,I)))
      YLAST = WK(1,I)
   80 WK(1,I) = PMX
      WK(1, IMAX + 1) = 2.0 * HP * HP * (WK(1, IMAX + 1) - YLAST)
      DO 90 I=IMIN-1,IMAX+1
   90 TERP(J) = TERP(J) + WK(1, I) * WK(3, I)
      IF(ABS(TERP(J)) .LE. 1.0E-7) TERP(J) = 0.0
 100  TEST = TEST - TERP(J)
      IF(ABS(TEST) .GT. 1.0E-5) RETURN
      RETURN
*
  110 IF (LDERIV .GT. 0) THEN
         TERP(1) = -1.0 / (X(2) - X(1))
         TERP(2) = 1.0 / (X(2) - X(1))
      ELSE
         TERP(1) = (X(2) - VAL) / (X(2) - X(1))
         TERP(2) = 1.0 - TERP(1)
      ENDIF

      RETURN
      END
