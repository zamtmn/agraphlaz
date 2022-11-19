{ Version 990825. Copyright � Alexey A.Chernobaev, 1996-1999 }

unit Gauss;
{
  1. ������� ������� �������� ��������� ������� ������ � ������� �������������
  �� ������ �������� � �������. ����� �������� ��������� � �������: ~(m^3/3).

  2. ��������� �������. ����� �������� ��������� � �������: ~(m^4/3).
  ����������: ���������� ����� ����������� �����.
}

interface

{$I VCheck.inc}

uses
  ExtType, Aliasv, Aliasm, Int16v, F32g, F64g, F80g, F32m, F32v, F64v, F80v,
  F64m, F80m, Boolv, VectErr, MathErr;

function SolveLinearSystem(A: TFloatMatrix; f: TGenericFloatVector;
  x: TGenericFloatVector; Eps: Float): Int8;
{
  �� �����: ������� Ax = f, ���

  A - ������� ������������� (����������); f - ������ ������ �����;
  x - ������, � ������� ����� ���������� �������.

  Eps - ����� ��������������� �����; ������� Eps > 0 ��������� � ���������
  ������� ����������� ������ ����������� � ����� ������������� �������
  (�������, � ������� ����������� �������� A ������ � ����).

  �� ������:
  1) ��������� > 0 => ������� ������� (x - �������); ���� ��������� ����� 1,
     �� ������� ����� ������������ �������; > 1 => ����� ������ �������
     (x - ���� �� �������);
  2) ��������� ����� -1 => ������� ����������� (� ���� ������ �������� x
     �� ����������).
}

function MatrixInversion(A, B: TFloatMatrix): Bool;
{
  �� �����:
  A - �������� ������� (����������); B - ������� ���������� (��� �� �����������).

  �� ������:
  1) True => ������� ������� ��������; B - ���������;
  2) False => ������� �� ������� �������� (������� A ����������); � ���� ������
     �������� B �� ����������.
}

implementation

{$IFDEF NOWARN}{$WARNINGS OFF}{$ENDIF}
function SolveLinearSystem(A: TFloatMatrix; f: TGenericFloatVector;
  x: TGenericFloatVector; Eps: Float): Int8;
var
  Temp: TFloatMatrix;
  RowTrace: TIntegerVector;
  RowProcessed: TBoolVector;
  I, J, K, L, M: Integer;
  T1, T2: Float;
begin
  {$IFDEF CHECK_MATH}
  if (A.RowCount <> A.ColCount) or (A.RowCount <> x.Count) or
    (A.RowCount <> f.Count) then MathError(SErrorInParameters, [0]);
  {$ENDIF}
  Result:=1;
  M:=A.RowCount;
  Temp:=TFloatMatrix.Create(M, M + 1, 0);
  RowTrace:=TIntegerVector.Create(M, -1);
  RowProcessed:=TBoolVector.Create(M, False);
  try
    { ������������� }
    for I:=0 to M - 1 do begin
      for J:=0 to M - 1 do
        Temp[I, J]:=A[I, J];
      Temp[I, M]:=f[I];
    end;
    { ������ ��� }
    for J:=0 to M - 1 do begin
      L:=-1;
      T1:=0;
      for I:=0 to M - 1 do
        if not RowProcessed[I] then begin
          K:=I;
          T2:=Abs(Temp[I, J]);
          if T2 > T1 then begin
            T1:=T2;
            L:=I;
          end;
        end;
      if L >= 0 then begin
        K:=L;
        RowProcessed[K]:=True;
        if J < M - 1 then begin
          T1:=Temp[K, J];
          for I:=0 to M - 1 do begin
            T2:=Temp[I, J];
            if (T2 <> 0) and not RowProcessed[I] then begin
              T2:=T2 / T1;
              Temp[I, J]:=0;
              for L:=J + 1 to M do
                Temp.DecItem(I, L, T2 * Temp[K, L]);
            end;
          end;
        end;
      end
      else begin
        RowProcessed[K]:=True;
        Result:=2;
      end;
      RowTrace[J]:=K;
    end;
    { �������� ��� }
    for J:=M - 1 downto 0 do begin
      I:=RowTrace[J];
      T1:=Temp[I, M];
      for K:=J + 1 to M - 1 do
        T1:=T1 - Temp[I, K] * x[K];
      T2:=Temp[I, J];
      if T2 <> 0 then x[J]:=T1 / T2
      else
        if Abs(T1) < Eps then x[J]:=0 { ����� �������� }
        else begin { �������, ��� ������� ����������� }
          Result:=-1;
          Exit;
        end;
    end;
  finally
    Temp.Free;
    RowTrace.Free;
    RowProcessed.Free;
  end;
end;
{$IFDEF NOWARN}{$WARNINGS ON}{$ENDIF}

function MatrixInversion(A, B: TFloatMatrix): Bool;
var
  I, J, M: Integer;
  f, x: TFloatVector;
begin
  {$IFDEF CHECK_MATH}
  if (A.RowCount <> A.ColCount) or (B.RowCount <> B.ColCount) or
    (A.RowCount <> B.RowCount) then TFloatMatrix.Error(SErrorInParameters, [0]);
  {$ENDIF}
  M:=A.RowCount;
  f:=TFloatVector.Create(M, 0);
  x:=TFloatVector.Create(M, 0);
  try
    for J:=0 to M - 1 do begin
      if J > 0 then f[J - 1]:=0;
      f[J]:=1;
      if SolveLinearSystem(A, f, x, 0) <> 1 then begin
        Result:=False;
        Exit;
      end;
      for I:=0 to M - 1 do
        B[I, J]:=x[I];
    end;
    Result:=True;
  finally
    f.Free;
    x.Free;
  end;
end;

end.
