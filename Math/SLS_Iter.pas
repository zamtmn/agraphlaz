{ Version 990830. Copyright � Alexey A.Chernobaev, 1996-1999 }

unit SLS_Iter;
{
  ������� ������� �������� ��������� ������������ ������� ����������� �������.

  �������: Ax = f;
  ������������ �������: (x(n+1) - x(n))/t(n+1) + Ax(n)=f;
  �������: r(n)=Ax(n) - f;
  t(n+1)=(r(n), Ar(n)) / (Ar(n), Ar(n)).

  ����������� ������� ����������: A > 0.
}

interface

{$I VCheck.inc}

uses
  ExtType, Aliasv, Aliasm, F32v, F64v, F80v, F32m, F64m, F80m, VectErr;

function SolveLinearSystemIter(A: TFloatMatrix; f: TFloatVector;
  MaxIter: Integer; Precision: Float; x: TFloatVector): Bool;
{ �� �����:
  A - ������� ������������� (����������); f - ������ ������ �����;
  MaxIter - ������������ ���������� ��������, ������� ����������� �����������;
  Precision - �������� (����� ���������� ��� |r(n)| <= Precision).

  A � f ������ ���� ���������� �����������.

  �� ������: ��������� ����� True, ���� ���������� ��������� ��������, � False,
  ���� ��������� ����� �� ���������� ���������� �������� MaxIter;
  x - ������������ �������. }

implementation

function SolveLinearSystemIter(A: TFloatMatrix; f: TFloatVector;
  MaxIter: Integer; Precision: Float; x: TFloatVector): Bool;
var
  xn, Arn, rn: TFloatMatrix;
  I, m: Integer;
begin
  {$IFDEF CHECK_MATH}
  if (A.RowCount <> A.ColCount) or (A.RowCount <> x.Count) or
    (A.RowCount <> f.Count) then TFloatMatrix.Error(SErrorInParameters, [0]);
  {$ENDIF}
  Result:=False;
  m:=A.RowCount;
  xn:=TFloatMatrix.Create(m, 1, 0); { x(0):=0 }
  rn:=TFloatMatrix.Create(m, 1, 0);
  Arn:=TFloatMatrix.Create(m, 1, 0);
  Precision:=Sqr(Precision);
  try
    rn.Vector.SubVector(f); { r(0):=-f }
    for I:=0 to MaxIter - 1 do begin
      if rn.Vector.SqrSum <= Precision then begin
        Result:=True;
        Break;
      end;
      Arn.MatrixProduct(A, rn); { Ar(n):=A*r(n) }
      xn.Vector.AddScaled( - Arn.Vector.DotProduct(rn.Vector) /
        Arn.Vector.DotProduct(Arn.Vector), rn.Vector); { x(n+1):=-t(n+1)*r(n)+x(n) }
      rn.MatrixProduct(A, xn); { r(n):=A*x(n) }
      rn.Vector.SubVector(f); { r(n):=A*x(n)-f }
    end;
    x.Assign(xn.Vector);
  finally
    xn.Free;
    rn.Free;
    Arn.Free;
  end;
end;

end.
