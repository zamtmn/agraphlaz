{ Version 000314. Copyright � Alexey A.Chernobaev, 1996-2000 }

unit Kirchhof;
{
  ������ ������������� ����� ����������� ���� � ������� ������ ��������.
}

interface

{$I VCheck.inc}

uses
  SysUtils, ExtType, AttrType, Int8v, Aliasv, Aliasm, Pointerv, MultiLst, Gauss,
  Graphs;

const
  Resistance = 'KirchhofR';
  ElectromotiveForse = 'KirchhofE';

function FindCurrents(G: TGraph; Currents: TFloatVector): Bool;
{ ��������� ����, ���������� ����� ������� ����, ���������� ������ G; ������
  ����� ����� ������������� ������� ���� ��� ������������; ������������� �������
  �������� Float-��������� ����� Resistance (������ ������ 0), ���������������
  ���� - Float-��������� ElectromotiveForse (�.�.�. ����� ���� ������������:
  �.�.�. ������ 0 <=> ��������� ����� ����� � ������� �������� ������, ���
  ��������� ����� � ������� ��������); ���������� True � ������ ������, �����
  False; � ������ ��������� ���������� ���� ������������ � Currents; ����
  Currents[I] > 0 (��� I = 0..G.EdgeCount - 1), �� �������� ����������� ����,
  ����������� ����� I-� ������� ����, ��������� � ������������ I-�� ����� (�����
  ��������� ������������ �� ������� � ������� �������� � ������� � �������
  ��������), ����� �������� ����������� ���� �������������� ����������� ����� }

implementation

{$IFDEF NOWARN}{$WARNINGS OFF}{$ENDIF}
function FindCurrents(G: TGraph; Currents: TFloatVector): Bool;
var
  I, J: Integer;
  Sign, LastSign: Int8;
  EMF: Float;
  V: TVertex;
  E, LastEdge: TEdge;
  Cycles: TMultiList;
  Directions: TClassList;
  EVector: TFloatVector;
  A: TFloatMatrix;
begin
  if not G.Connected or (G.RingEdgeCount <> G.EdgeCount) or (G.LoopCount > 0) then
    raise Exception.Create('Graph must be connected, no acyclic edges or loops allowed');
  Cycles:=TMultiList.Create(TClassList);
  Directions:=nil;
  EVector:=nil;
  A:=nil;
  try
    { 1. ������� ������� ����������� �������� }
    G.FindFundamentalRings(Cycles);
    { 2. ���������� ����������� ����� �� ������ ������� (�����) ������� ������� }
    Directions:=TClassList.Create;
    Directions.Count:=G.EdgeCount;
    for I:=0 to G.EdgeCount - 1 do
      Directions[I]:=TInt8Vector.Create(Cycles.Count, 0);
    EVector:=TFloatVector.Create(G.EdgeCount, 0); { ������ ����� ������� }
    for I:=0 to Cycles.Count - 1 do begin
      LastEdge:=nil;
      for J:=0 to Cycles[I].Count - 1 do begin
        E:=Cycles[I][J];
        if LastEdge <> nil then
          if (LastEdge.V2 <> E.V1) and (LastEdge.V1 <> E.V2) then
            Sign:=-LastSign
          else
            Sign:=LastSign
        else
          Sign:=1;
        LastEdge:=E;
        LastSign:=Sign;
        EMF:=E.AsFloat[ElectromotiveForse];
        if Sign > 0 then
          EVector.IncItem(I, EMF)
        else
          EVector.DecItem(I, EMF);
        TInt8Vector(Directions[E.Index])[I]:=Sign;
      end;
    end;
    { 3. ���������� ������� ��������� }
    { ������ ������� �������� }
    A:=TFloatMatrix.Create(G.EdgeCount, G.EdgeCount, 0);
    for I:=0 to Cycles.Count - 1 do
      for J:=0 to G.EdgeCount - 1 do begin
        E:=G.Edges[J];
        A[I, J]:=TInt8Vector(Directions[E.Index])[I] * E.AsFloat[Resistance];
      end;
    { ������ ������� �������� }
    for I:=0 to G.VertexCount - 2 do begin
      V:=G[I];
      for J:=0 to V.Degree - 1 do begin
        E:=V.IncidentEdge[J];
        if E.V1 = V then Sign:=1 else Sign:=-1;
        A[Cycles.Count + I, E.Index]:=Sign;
      end;
    end;
    Result:=SolveLinearSystem(A, EVector, Currents, 0) > 0;
  finally
    Cycles.Free;
    if Directions <> nil then Directions.FreeItems;
    Directions.Free;
    EVector.Free;
    A.Free;
  end;
end;
{$IFDEF NOWARN}{$WARNINGS ON}{$ENDIF}

end.
