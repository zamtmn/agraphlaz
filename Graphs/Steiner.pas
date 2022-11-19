{ Version 030515. Copyright � Alexey A.Chernobaev, 1996-2003 }
{
  ������� ������������ ������� ������ �������� (������ ���������� �����������
  ������, ������������ �������� ������������ ������ �����).

  ������������ ��������, ��������� � "L.Kou, G.Markowsky and L.Berman. A fast
  algorithm for steiner trees, Acta Informatica, 15, pp.141-145, 1981".
  ��������: "Samir Kuller. Design and Analysis of Algorithms: Course Notes.
  University of Maryland, 1996".

  �����������: ����������� ������ ��������������� ���� �����.
}

unit Steiner;

interface

{$I VCheck.inc}

uses
  ExtType, AttrType, Aliasv, Int16v, Boolv, Pointerv, Graphs, ExtGraph, VectErr;

function ApproximateSteinerTree(G: TGraph; SteinerVertices,
  SteinerTreeEdges: TClassList): Float;
{
  ������� ������������ ������� ������ �������� (������ ���������� �����������
  ������, ������������ �������� ������������ ������ �����) ��� ������ �
  ���������������� ������ �����. ��������, ��� ����� ����������� ������
  �� ����� ��� � ��� ���� ����������� ����� ������� �������.
  �� �����: G - ���������� ����, SteinerVertices - ������� ����� G, �������
  ������ ������� � ������� ������. �� ������: ���� SteinerTreeEdges <> nil, ��
  � SteinerTreeEdges ������������ ����� G, �������� � ��������� ������.
  ��������� ������� ����� ����� ������.
}

implementation

function ApproximateSteinerTree(G: TGraph; SteinerVertices,
  SteinerTreeEdges: TClassList): Float;
const
  AttrEdgeIndex = 'I';
var
  I, J, IndexOffset: Integer;
  H: TGraph;
  E: TEdge;
  SSTList, EdgeList: TClassList;
  CopyVertexToGS, CopyEdgeToGS: TBoolVector;
  VertexMap: TIntegerVector;
begin
  if not G.Connected then TGraph.Error(SMethodNotApplicable{, [0]});
  H:=TGraph.Create;
  try
    { ������ ������ ���� H �� �������� SteinerVertices; ���� ����� H �����
      ������ ���������� ����� ����� ���������������� ��������� ����� G }
    GetCompleteGraph(H, SteinerVertices.Count);
    H.Features:=[Weighted];
    for I:=0 to H.EdgeCount - 1 do begin
      E:=H.Edges[I];
      E.Weight:=G.FindMinWeightPathCond(SteinerVertices[E.V1.Index],
        SteinerVertices[E.V2.Index], nil, nil, nil);
    end;
    SSTList:=TClassList.Create;
    try
      { ������� ���������� �������� ������ � H }
      H.FindShortestSpanningTree(SSTList);
      CopyVertexToGS:=nil;
      CopyEdgeToGS:=nil;
      EdgeList:=nil;
      VertexMap:=nil;
      try
        { �������� � G ������� � �����, �������� � GS }
        CopyVertexToGS:=TBoolVector.Create(G.VertexCount, False);
        CopyEdgeToGS:=TBoolVector.Create(G.EdgeCount, False);
        EdgeList:=TClassList.Create;
        for I:=0 to SteinerVertices.Count - 1 do
          CopyVertexToGS[TVertex(SteinerVertices[I]).Index]:=True;
        for I:=0 to SSTList.Count - 1 do begin
          With TEdge(SSTList[I]) do
            G.FindMinWeightPathCond(SteinerVertices[V1.Index],
              SteinerVertices[V2.Index], nil, nil, EdgeList);
          for J:=0 to EdgeList.Count - 1 do With TEdge(EdgeList[J]) do begin
            CopyVertexToGS[V1.Index]:=True;
            CopyVertexToGS[V2.Index]:=True;
            CopyEdgeToGS[Index]:=True;
          end;
        end;
        { ������ ������� GS ����� G, ���������� ��� ������� SteinerVertices,
          � ����� ��� ������� � �����, �������� � �� ����������� ���� �����
          ��������� G, ������� ������������� ������ SST(H); ��������� ������
          ���� H ����� �� �����, ��� �������� GS ���������� ��� �� ������ H }
        H.Clear;
        IndexOffset:=H.CreateEdgeAttr(AttrEdgeIndex, AttrPointer);
        H.AddVertices(CopyVertexToGS.NumTrue);
        VertexMap:=TIntegerVector.Create(G.VertexCount, -1);
        J:=0;
        for I:=0 to G.VertexCount - 1 do
          if CopyVertexToGS[I] then begin
            VertexMap[I]:=J;
            Inc(J);
          end;
        for I:=0 to G.EdgeCount - 1 do begin
          E:=G.Edges[I];
          if CopyEdgeToGS[I] then
            With H.AddEdgeI(VertexMap[E.V1.Index], VertexMap[E.V2.Index]) do begin
              Weight:=E.Weight;
              AsPointerByOfs[IndexOffset]:=E;
            end;
        end;
        { ����������� �������� ���������� �������� ������ GS }
        if SteinerTreeEdges <> nil then begin
          Result:=H.FindShortestSpanningTree(SSTList);
          SteinerTreeEdges.Count:=SSTList.Count;
          for I:=0 to SSTList.Count - 1 do
            SteinerTreeEdges[I]:=TEdge(SSTList[I]).AsPointerByOfs[IndexOffset];
        end
        else
          Result:=H.FindShortestSpanningTree(nil);
      finally
        CopyVertexToGS.Free;
        CopyEdgeToGS.Free;
        EdgeList.Free;
        VertexMap.Free;
      end;
    finally
      SSTList.Free;
    end;
  finally
    H.Free;
  end;
end;

end.
