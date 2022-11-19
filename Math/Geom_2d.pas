{ Version 990830. Copyright � Alexey A.Chernobaev, 1994�1999 }

unit Geom_2d;

interface

uses
  Types, ExtType;

function InRect(const Rect: TRect; X, Y: Integer): Bool;
{ ���������, ���������� �� ����� (X, Y) ������ �������������� Rect }

function PointInRect(A, B, P: TPoint): Boolean;
{ ���������, ���������� �� P ������ ��������������, ��������� ������� A � B }

procedure ReduceToRect(var A, B: TPoint);
{ ����� ������ A � B �������� ����������� ������������ ������ �������� � �������
  ������� ���� ������������� (�.�. A.X <= B.X � A.Y <= B.Y) }

function MoveRect(const Rect: TRect; DX, DY: Integer): TRect;
{ ��������� ������������ ������� Rect �� (DX, DY) }

function GrowRect(const Rect: TRect; DX, DY: Integer): TRect;
{ �������� ������ Rect, ������� DX �� Rect.Left � DY �� Rect.Top, � �����
  ��������� DX � Rect.Right � DY � Rect.Bottom }

function ResizeRect(const Rect: TRect; Factor: Float): TRect;
{ ������������ ������������� � ������������� Factor, �������� ����������� ����� }

function GetFitFactor(const FromRect, ToRect: TRect): Float;
{ ���������� �����������, � ������� ���� ������������� ���������� �������������
  FromRect, ����� �������� ������������ �������������, ������� ����� ����������
  ������ ������ �������� ���� � ����� ������� ����� ����������� ��������������
  ToRect ����� ��������� ���������� ������ ToRect (���������� ������������� -
  ������������� � ������������� ������� � �������); � ������ ������������
  ��������������� ��������� �� ��������� }

function Distance(A, B: TPoint): Float;
{ ����� ������� AB }

function DistanceFloat(X1, Y1, X2, Y2: Float): Float;
{ ����� ������� (X1,Y1)-(X2,Y2) }

function SqrLengthOfNormal(A, B, C: TPoint): Float;
{ ������� ����� �������, ��������� �� ����� C �� ������, ���������� ����� �����
  A � B; ���� A = B, �� ������������ Sqr(|AC|)=Sqr(|BC|) }

function LengthOfNormal(A, B, C: TPoint): Float;
{ ����� �������, ��������� �� ����� C �� ������, ���������� ����� ����� A � B }

function SegmentsIntersect(A, B, C, D: TPoint; var P: TPoint): Bool;
{ ���������� True, ���� ������� AB � CD ������������, ��� ���� P - �����
  ����������� ��������, ���� False, ���� ������� �� ������������ }

function SameSide(A, B, C, D: TPoint): Bool;
{ ���������, ��������� �� ����� C � D � ����� ������������� ������������ ������,
  ���������� ����� ����� A � B }

function ClipLine(const Rect: TRect; const A, B: TPoint): TPoint;
{ ���� ����� A ��������� ������� �������������� Rect, � B - ������, ��
  ���������� ����� ����������� ������� AB � ����� �� ������ ��������������,
  ����� ���������� B }

implementation

function InRect(const Rect: TRect; X, Y: Integer): Bool;
begin
  Result:=(X >= Rect.Left) and (X <= Rect.Right) and
    (Y >= Rect.Top) and (Y <= Rect.Bottom);
end;

function PointInRect(A, B, P: TPoint): Boolean;
begin
  ReduceToRect(A, B);
  Result:=(P.X >= A.X) and (P.X <= B.X) and (P.Y >= A.Y) and (P.Y <= B.Y);
end;

procedure ReduceToRect(var A, B: TPoint);
var
  T: Integer;
begin
  if A.X > B.X then begin T:=A.X; A.X:=B.X; B.X:=T; end;
  if A.Y > B.Y then begin T:=A.Y; A.Y:=B.Y; B.Y:=T; end;
end;

function MoveRect(const Rect: TRect; DX, DY: Integer): TRect;
begin
  Result.Left:=Rect.Left + DX;
  Result.Top:=Rect.Top + DY;
  Result.Right:=Rect.Right + DX;
  Result.Bottom:=Rect.Bottom + DY;
end;

function GrowRect(const Rect: TRect; DX, DY: Integer): TRect;
begin
  Result.Left:=Rect.Left - DX;
  Result.Top:=Rect.Top - DY;
  Result.Right:=Rect.Right + DX;
  Result.Bottom:=Rect.Bottom + DY;
end;

function ResizeRect(const Rect: TRect; Factor: Float): TRect;
var
  T: Integer;
begin
  With Rect do begin
    T:=UpRound((Right - Left) * Factor);
    Result.Left:=(Right - T + Left) div 2;
    Result.Right:=Result.Left + T;
    T:=UpRound((Bottom - Top) * Factor);
    Result.Top:=(Bottom - T + Top) div 2;
    Result.Bottom:=Result.Top + T;
  end;
end;

function GetFitFactor(const FromRect, ToRect: TRect): Float;
var
  R: Float;
  T: Integer;
begin
  T:=FromRect.Right - FromRect.Left;
  if T <> 0 then Result:=(ToRect.Right - ToRect.Left) / T else Result:=MaxFloat;
  T:=FromRect.Bottom - FromRect.Top;
  if T <> 0 then R:=(ToRect.Bottom - ToRect.Top) / T else R:=MaxFloat;
  if R < Result then Result:=R;
end;

function SqrDistFloat(X1, Y1, X2, Y2: Float): Float;
begin
  Result:=Sqr(X1 - X2) + Sqr(Y1 - Y2);
end;

function Distance(A, B: TPoint): Float;
begin
  Result:=Sqrt(Sqr(A.X - B.X) + Sqr(A.Y - B.Y));
end;

function DistanceFloat(X1, Y1, X2, Y2: Float): Float;
begin
  Result:=Sqrt(Sqr(X1 - X2) + Sqr(Y1 - Y2));
end;

function SqrLengthOfNormal(A, B, C: TPoint): Float;
var
  T: Float;
begin
  Result:=SqrDistFloat(A.X, A.Y, C.X, C.Y);
  T:=SqrDistFloat(A.X, A.Y, B.X, B.Y);
  if T > 0 then
    Result:=Result - Sqr(Result + T - SqrDistFloat(C.X, C.Y, B.X, B.Y)) / (4 * T)
end;

function LengthOfNormal(A, B, C: TPoint): Float;
begin
  Result:=Sqrt(SqrLengthOfNormal(A, B, C));
end;

function Canonize(var A, B: TPoint): Bool;
var
  T: TPoint;
begin
  if A.X > B.X then begin
    T:=A; A:=B; B:=T;
    Result:=True;
  end
  else if (A.X = B.X) and (A.Y > B.Y) then begin
    T.X:=A.Y; A.Y:=B.Y; B.Y:=T.X;
    Result:=True;
  end
  else
    Result:=False;
end;

function SegmentsIntersect1(A, B, C, D: TPoint; var L: Int32; var P: TPoint): Bool;
var
  ACX, ACY, ABX, ABY, CDX, CDY: Int32;
  R, T1, T2: Float;
begin
  ACX:=Int32(C.X) - A.X;
  ACY:=Int32(C.Y) - A.Y;
  ABX:=Int32(B.X) - A.X;
  ABY:=Int32(B.Y) - A.Y;
  CDX:=Int32(D.X) - C.X;
  CDY:=Int32(D.Y) - C.Y;
  L:=CDY * ABX - CDX * ABY;
  if L <> 0 then begin
    T1:=ABX;
    T2:=ABY;
    R:=(T1 * ACY * CDX + T2 * A.X * CDX - T1 * C.X * CDY) / (-L);
    if R > MaxInt then R:=MaxInt
    else if R < -MaxInt then R:=-MaxInt;
    P.X:=UpRound(R);
    R:=(T2 * ACX * CDY + T1 * A.Y * CDY - T2 * C.Y * CDX) / L;
    if R > MaxInt then R:=MaxInt
    else if R < - MaxInt then R:= - MaxInt;
    P.Y:=UpRound(R);
    Result:=PointInRect(A, B, P) and PointInRect(C, D, P);
  end
  else begin
    P:=A;
    if SqrLengthOfNormal(A, B, D) <> 0 then Result:=False
    else begin
      Canonize(A, B);
      Canonize(C, D);
      if (A.X < C.X) or (A.X = C.X) and (A.Y < C.Y) then
        Result:=(B.X > C.X) or (B.X = C.X) and (B.Y >=C.Y)
      else
        Result:=(D.X > A.X) or (D.X = A.X) and (D.Y >=A.Y);
    end;
  end;
end;

function SegmentsIntersect(A, B, C, D: TPoint; var P: TPoint): Bool;
var
  T: Int32;
begin
  Result:=SegmentsIntersect1(A, B, C, D, T, P);
end;

function SameSide(A, B, C, D: TPoint): Bool;
var
  T: Int32;
  P: TPoint;
begin
  SameSide:=not (SegmentsIntersect1(A, B, C, D, T, P) or
    (T <> 0) and PointInRect(C, D, P));
end;

function ClipLine(const Rect: TRect; const A, B: TPoint): TPoint;
var
  P1, P2, P3: TPoint;
begin
  Result:=B;
  if InRect(Rect, B.X, B.Y) then begin
    if A.Y < B.Y then begin
      P1.Y:=Rect.Top;
      P2.Y:=Rect.Top;
      P3.Y:=Rect.Bottom;
    end
    else begin
      P1.Y:=Rect.Bottom;
      P2.Y:=Rect.Bottom;
      P3.Y:=Rect.Top;
    end;
    if A.X < B.X then begin
      P1.X:=Rect.Left;
      P2.X:=Rect.Right;
      P3.X:=Rect.Left;
    end
    else begin
      P1.X:=Rect.Right;
      P2.X:=Rect.Left;
      P3.X:=Rect.Right;
    end;
    if not SegmentsIntersect(P1, P2, A, B, Result) then
      SegmentsIntersect(P1, P3, A, B, Result);
  end;
end;

end.
