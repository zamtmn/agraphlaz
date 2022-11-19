unit Mycielski;

interface

uses
  Boolm, Graphs, Pointerv, MultiLst, MathErr, VectErr;

procedure GetMycielski(G: TGraph; ChromaticNumber: Integer);
{
  ������ ���� ����������� ��� �������������� ����� ChromaticNumber >=2. ����
  ����������� - ���� � ������������ ������������� ������, ��������� ��������
  ����� 2 (��������� ����� - ���������� ���������� ������ � ������������ ������
  ���������, ���, ��� �� �� �����, ������, ����� �����); ������������� �����
  ������ ������ ������������� "�������" ������� �������������� �������� �
  ������� ������� ������ ����:
  "... � � ��� ������ �p������? ���� �p�� ������ p���p����� � 4 �����, �� � ����
  ������ P5 (������ 5-�p��) => �� ��������� ����������� ������� �����p����� =>
  ��� �����p����� �p��� H���������, ����� �� p���p�������� �������� � 4 �����";
  ����� ������ �� ����������� ������� - P5 ����� �� ������ ������� � ����� ����.
}

implementation

procedure GetMycielski(G: TGraph; ChromaticNumber: Integer);

  procedure Build(N: Integer);
  var
    I, J, OldCount: Integer;
    LastVertex, OldVertex, NewVertex, Neighbour: TVertex;
  begin
    if N = 2 then G.AddEdge(G.AddVertex, G.AddVertex)
    else begin
      Build(N - 1);
      OldCount:=G.VertexCount;
      G.SetTempForVertices(-1);
      G.AddVertices(OldCount + 1);
      LastVertex:=G[2 * OldCount];
      for I:=OldCount to 2 * OldCount - 1 do begin
        OldVertex:=G[I - OldCount];
        NewVertex:=G[I];
        for J:=0 to OldVertex.Degree - 1 do begin
          Neighbour:=OldVertex.Neighbour[J];
          if Neighbour.Temp.AsInt32 = -1 then G.AddEdge(NewVertex, Neighbour);
        end;
        G.AddEdge(NewVertex, LastVertex);
      end;
    end;
  end;

begin
  G.Clear;
  if ChromaticNumber >= 2 then Build(ChromaticNumber)
  else MathError(SErrorInParameters, [0]);
end;

end.
