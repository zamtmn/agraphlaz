unit TestMinWeightPath2;

{$MODE Delphi}

interface

uses
  Graphs,
  ExtGraph,
  ExtType,
  Pointerv;

procedure Test(NumVertices, NumEdges: Integer);

implementation

procedure Test(NumVertices, NumEdges: Integer);
var
  G: TGraph;
  I: Integer;
  OldTime: LongInt;
begin
  if NumVertices < 1 then NumVertices:=1;
  if NumEdges < 0 then NumEdges:=0;
  writeln('*** Min Weight Path for graph with ', NumVertices, ' vertices and ',
    NumEdges, ' edges ***');
  writeln;
  writeln('RandSeed = ', RandSeed);
  writeln;
  G:=TGraph.Create;
  G.Features:=[Weighted];
  try
    write('Creating graph...');
    GetRandomGraph(G, NumVertices, NumEdges);
    for I:=0 to NumEdges - 1 do
      G.Edges[I].Weight:=Random(100);
    writeln;
    write('Finding Min Weight Path...');
    writeln;
    //OldTime:=GetTickCount;
    writeln('Sum Weight = ', G.FindMinWeightPath(G[0], G[NumVertices - 1], nil) :0:1);
    //writeln('Calculation Time: ', Abs(GetTickCount - OldTime) / 1000 :0:1, ' s');
    write('Press Return to continue...');
    readln;
  finally
    G.Free;
  end;
end;

end.
