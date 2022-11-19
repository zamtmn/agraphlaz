unit TestRings;

interface

uses
  MultiLst,
  Pointerv,
  Graphs;

procedure Test;

implementation

procedure Test;
var
  G: TGraph;
  M: TMultiList;

  procedure ShowRings;
  var
    I, J: Integer;
  begin
    for I:=0 to M.Count - 1 do begin
      writeln('Ring: ', Succ(I));
      for J:=0 to M[I].Count - 1 do With TEdge(M[I][J]) do
        write('(', V1.Index, ',', V2.Index, ') ');
      writeln;
    end;
    if M.Count > 0 then writeln;
  end;

begin
  writeln('*** Fundamental vice Min Rings ***'#10);
  G:=TGraph.Create;
  M:=TMultiList.Create(TClassList);
  try
    G.AddVertices(4);
    G.AddEdges([0, 1,  0, 2,  1, 3,  2, 3,  1, 2]);
    G.FindFundamentalRings(M);
    writeln('Fundamental Rings');
    ShowRings;
    G.FindMinRingCovering(M);
    writeln('Min Ring Covering');
    ShowRings;
  finally
    G.Free;
    M.Free;
  end;
end;

end.