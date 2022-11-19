{ Version 050625. Copyright � Alexey A.Chernobaev, 1996-2005 }

unit HamilCyc;

interface

{$I VCheck.inc}

uses
  ExtType, AttrType, Graphs, Int16v, Aliasv, Boolv, Pointerv, MultiLst, VectErr;

function FindHamiltonCycles(G: TGraph; FromVertex: TVertex; N: Integer;
  EdgePaths: TMultiList): Integer;
{
  ������� �������� ���������� ������������� ������ (������, ���������� �����
  ������ ������� ����� ����� ���� ���) � ��������������� ����� G, ������� �
  FromVertexIndex-�������; ���� N <= 0, �� ������������ ��� �����; ���� N > 0,
  �� ������������ min(N, <���������� ������>) ������; ������� ����������
  ���������� ��������� ������; ����� ������������ � ������������ EdgePaths.
}

implementation

{$IFDEF NOWARN}{$WARNINGS OFF}{$ENDIF}
function FindHamiltonCycles(G: TGraph; FromVertex: TVertex; N: Integer;
  EdgePaths: TMultiList): Integer;
label
  Loop;
const
  OriginalIndex = 'HamilCyc';
var
  I, J, K, M, OriginalIndexOfs: Integer;
  TempGraph: TGraph;
  OutArcsList, InArcsList: TMultiList;
  FromIndex, InDegrees, OutDegrees, BackArcsCount: TIntegerVector;
  CurrentPath, OutArcs, BackVerticesList, BackArcsList: TClassList;
  AllowedVertices, AllowedEdges: TBoolVector;
  CurrentVertex, NewVertex: TVertex;
  E1, E2: TEdge;
  ExitFlag, B: Bool;

  function GraphReduction(FromVertex, ToVertex: TVertex; Arc: TEdge): Bool;
  { ���������� �������� �����, ������� ������ ����� ����� Arc (� ���������������
    ������� ToVertex) ��� ����������� �����, ������ �� ������� FromVertex;
    ���� �����������, ��� ��� ����� ������ ������� �� ����������, �� �������
    ���������� True }
  var
    I, J, K, L, BackArcs, RecursionCount: Integer;
    ArcList, NewFromVertexList, NewToVertexList: TClassList;
    E: TEdge;
    V, Neighbour: TVertex;
  begin
    { 1. ��������� ��� ����������� ����, �������� � ToVertex, �� �����������
      ���, ��������� �� ��� ����������� ������ ��� FromVertex }
    Result:=True;
    BackArcs:=0;
    RecursionCount:=0;
    NewFromVertexList:=TClassList.Create;
    NewToVertexList:=TClassList.Create;
    try
      I:=ToVertex.Index;
      ArcList:=InArcsList[I];
      for J:=0 to ArcList.Count - 1 do begin
        E:=TEdge(ArcList[J]);
        if AllowedEdges[E.Index] then begin
          V:=E.OtherVertex(ToVertex);
          if V <> FromVertex then begin
            K:=V.Index;
            if AllowedVertices[K] then begin
              { ���� � ToVertex ������ ���� �� ��������� ����������� �������,
                �� ����������� � FromVertex, � ��� �������� ������������
                �����, ��������� �� ���� �������, �� ��� ������� }
              L:=OutDegrees[K];
              if L = 1 then Exit; { finally �����������! }
              if L = 2 then NewFromVertexList.Add(V);
              OutDegrees.DecItem(K, 1);
              InDegrees.DecItem(I, 1);
              BackArcsList.Add(E);
              AllowedEdges[E.Index]:=False;
              Inc(BackArcs);
            end;
          end;
        end;
      end;
      { 2. ��������� ��� ����������� ����, ��������� �� FromVertex, ����� Arc }
      I:=FromVertex.Index;
      ArcList:=OutArcsList[I];
      for J:=0 to ArcList.Count - 1 do begin
        E:=TEdge(ArcList[J]);
        if (E <> Arc) and AllowedEdges[E.Index] then begin
          V:=E.OtherVertex(FromVertex);
          K:=V.Index;
          { ���� � �������� ������� ������ ������������ ����������� ����,
            �� ��� ������� }
          L:=InDegrees[K];
          if L = 1 then Exit; { finally �����������! }
          if L = 2 then NewToVertexList.Add(V);
          OutDegrees.DecItem(I, 1);
          InDegrees.DecItem(K, 1);
          BackArcsList.Add(E);
          AllowedEdges[E.Index]:=False;
          Inc(BackArcs);
        end;
      end;
      { 3. ���������� �������� ���������� }
      for I:=0 to NewFromVertexList.Count - 1 do begin
        V:=TVertex(NewFromVertexList[I]);
        ArcList:=OutArcsList[V.Index];
        for J:=0 to ArcList.Count - 1 do begin
          E:=TEdge(ArcList[J]);
          if AllowedEdges[E.Index] then begin
            Neighbour:=E.OtherVertex(V);
            if AllowedVertices[Neighbour.Index] then begin
              Inc(RecursionCount);
              if GraphReduction(V, Neighbour, E) then Exit;
            end;
          end;
        end;
      end;
      for I:=0 to NewToVertexList.Count - 1 do begin
        V:=TVertex(NewToVertexList[I]);
        ArcList:=OutArcsList[V.Index];
        for J:=0 to ArcList.Count - 1 do begin
          E:=TEdge(ArcList[J]);
          if AllowedEdges[E.Index] then begin
            Neighbour:=E.OtherVertex(V);
            if AllowedVertices[Neighbour.Index] then begin
              Inc(RecursionCount);
              if GraphReduction(Neighbour, V, E) then Exit;
            end;
          end;
        end;
      end;
      Result:=False;
    finally
      for I:=0 to RecursionCount - 1 do
        Inc(BackArcs, BackArcsCount.Pop);
      BackArcsCount.Add(BackArcs);
      NewFromVertexList.Free;
      NewToVertexList.Free;
    end;
  end;

  procedure RestoreGraph;
  { ��������� ����������� ����� }
  var
    I: Integer;
    E: TEdge;
  begin
    for I:=1 to BackArcsCount.Pop do begin
      E:=TEdge(BackArcsList.Pop);
      AllowedEdges[E.Index]:=True;
      OutDegrees.IncItem(E.V1.Index, 1);
      InDegrees.IncItem(E.V2.Index, 1);
    end;
  end;

begin
  {$IFDEF CHECK_GRAPHS}
  if not (Directed in G.Features) then TGraph.Error(SMethodNotApplicable);
  {$ENDIF}
  Result:=0;
  EdgePaths.Clear;
  M:=G.VertexCount;
  if M > 1 then begin
    { ���� ���� �������, � ������� �� ������� �� ���� ����, ���� �� �������
      �� ������� �� ���� ����, �� ����������� ���� �� ���������� }
    for I:=0 to M - 1 do begin
      G[I].GetInOutDegree(J, K);
      if (J = 0) or (K = 0) then Exit;
    end;
    TempGraph:=TGraph.Create;
    try
      TempGraph.AssignSceleton(G);
      OriginalIndexOfs:=TempGraph.CreateEdgeAttr(OriginalIndex, AttrInt32);
      for I:=0 to TempGraph.EdgeCount - 1 do
        TempGraph.Edges[I].AsInt32ByOfs[OriginalIndexOfs]:=I;
      TempGraph.Features:=[Directed];
      FromVertex:=TempGraph[FromVertex.Index];
      { ������� � TempGraph ����� � ������� ����� }
      TempGraph.RemoveLoops;
      TempGraph.RemoveParallelEdges;
      { �������� TempGraph: ���� � ��������� ������� u ����� ������ ���� ����
        �� ������� v, �� ������� ��� ����, ��������� �� v, ����� ���� (v, u);
        ���� ��� ���� ���������� ������������� �������, �� ����������� ����
        �� ���������� }
      AllowedVertices:=TBoolVector.Create(M, True);
      try
        repeat
          ExitFlag:=True;
          for I:=0 to M - 1 do begin
            CurrentVertex:=TempGraph[I];
            if AllowedVertices[CurrentVertex.Index] then begin
              B:=False;
              for J:=0 to CurrentVertex.Degree - 1 do begin
                E1:=CurrentVertex.IncidentEdge[J];
                if E1.V2 = CurrentVertex then begin
                  NewVertex:=E1.V1;
                  if B then begin
                    B:=False;
                    Break;
                  end;
                  B:=True;
                  E2:=E1;
                end;
              end;
              if B then begin
                { ������� "������" ��������� �� v ���� }
                for J:=NewVertex.Degree - 1 downto 0 do begin
                  E1:=NewVertex.IncidentEdge[J];
                  if (E1 <> E2) and (E1.V1 = NewVertex) then begin
                    K:=E1.V2.InDegree;
                    if K = 1 then Exit; { ��� ������������ ����� }
                    if K = 2 then begin
                      ExitFlag:=False;
                      AllowedVertices[E1.V2.Index]:=True;
                    end;
                    E1.Free;
                  end;
                end;
              end;
              AllowedVertices[CurrentVertex.Index]:=False;
            end;
          end;
        until ExitFlag;
        { �������� ����� ��������� }
        OutArcsList:=TMultiList.Create(TClassList);
        InArcsList:=nil;
        FromIndex:=nil;
        InDegrees:=nil;
        OutDegrees:=nil;
        BackArcsCount:=nil;
        CurrentPath:=nil;
        BackVerticesList:=nil;
        BackArcsList:=nil;
        AllowedEdges:=nil;
        try
          InArcsList:=TMultiList.Create(TClassList);
          FromIndex:=TIntegerVector.Create(M, 0);
          InDegrees:=TIntegerVector.Create(M, 0);
          OutDegrees:=TIntegerVector.Create(M, 0);
          BackArcsCount:=TIntegerVector.Create(0, 0);
          CurrentPath:=TClassList.Create;
          BackVerticesList:=TClassList.Create;
          BackArcsList:=TClassList.Create;
          AllowedEdges:=TBoolVector.Create(TempGraph.EdgeCount, True);
          AllowedVertices.FillValue(True);
          TempGraph.GetInArcsList(InArcsList);
          TempGraph.GetOutArcsList(OutArcsList);
          for I:=0 to M - 1 do begin
            InDegrees[I]:=InArcsList[I].Count;
            OutDegrees[I]:=OutArcsList[I].Count;
          end;
          CurrentVertex:=FromVertex;
        Loop:
          I:=CurrentVertex.Index;
          AllowedVertices[I]:=False;
          OutArcs:=OutArcsList[I];
          { ���� ���������� ���������� ����� ����, �� �������, �� ��������� �� ��
            ������� CurrentVertex ������� FromVertex }
          if CurrentPath.Count = M - 1 then
            for J:=0 to OutArcs.Count - 1 do begin
              E1:=TEdge(OutArcs[J]);
              NewVertex:=E1.OtherVertex(CurrentVertex);
              if NewVertex = FromVertex then begin { ����� ����������� ���� }
                CurrentPath.Add(G.Edges[E1.AsInt32ByOfs[OriginalIndexOfs]]);
                EdgePaths.AddAssign(CurrentPath);
                Inc(Result);
                if Result = N then Exit; { ����� N ������������� ������ }
                CurrentPath.Grow(-1);
              end;
            end
          else begin
            for J:=FromIndex[I] to OutArcs.Count - 1 do begin
              E1:=TEdge(OutArcs[J]);
              if AllowedEdges[E1.Index] then begin
                NewVertex:=E1.OtherVertex(CurrentVertex);
                K:=NewVertex.Index;
                if AllowedVertices[K] then begin { ���������� ������� }
                  { ���������� �������� �����; ���� �����������, ��� ��� ������
                    ������� NewVertex ������� �� ����� ������������, �� �������
                    �� ����� � ���������� ������� }
                  if GraphReduction(CurrentVertex, NewVertex, E1) then begin
                    RestoreGraph;
                    Continue;
                  end;
                  FromIndex[I]:=J + 1;
                  { ���������� ���������� ��� �������� }
                  CurrentPath.Add(G.Edges[E1.AsInt32ByOfs[OriginalIndexOfs]]);
                  BackVerticesList.Add(CurrentVertex);
                  { ���������� ����� }
                  AllowedVertices[K]:=False;
                  CurrentVertex:=NewVertex;
                  goto Loop;
                end;
              end;
            end;
          end;
          { ��� ����������� }
          if BackVerticesList.Count > 0 then begin
            I:=CurrentVertex.Index;
            FromIndex[I]:=0;
            AllowedVertices[I]:=True;
            CurrentPath.Grow(-1);
            CurrentVertex:=TVertex(BackVerticesList.Pop);
            RestoreGraph;
            goto Loop;
          end;
        finally
          InArcsList.Free;
          OutArcsList.Free;
          FromIndex.Free;
          InDegrees.Free;
          OutDegrees.Free;
          BackArcsCount.Free;
          CurrentPath.Free;
          BackVerticesList.Free;
          BackArcsList.Free;
          AllowedEdges.Free;
        end;
      finally
        AllowedVertices.Free;
      end;
    finally
      TempGraph.Free;
    end;
  end;
end;
{$IFDEF NOWARN}{$WARNINGS ON}{$ENDIF}

end.
