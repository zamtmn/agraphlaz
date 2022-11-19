{ Version 001019. Copyright � Alexey A.Chernobaev, 1996-2000 }

unit GraphIO;

interface

{$I VCheck.inc}

uses
  ExtType, Boolm, VTxtStrm, Graphs, GraphGML;

function CreateGraphFromGMLFile(const FileName: String; SaveGMLAttrs: Bool): TGraph;
{ ������ � ������� ���� �� GML-�����;
  SaveGMLAttrs: ��. GraphGML.CreateGraphFromGMLStream }

procedure GetGraphFromGMLFile(G: TGraph; const FileName: String; SaveGMLAttrs: Bool);
{ ������ ���� �� GML-����� }

procedure WriteGraphToGMLFile(G: TGraph; const FileName: String; SaveAllAttrs: Bool);
{ ���������� ���� G � ��������� ����, ��������� GML-������;
  SaveAllAttrs: ��. GraphGML.WriteGraphToGMLStream }

procedure WriteGraphSimple(G: TGraph; const FileName: String);
{ ���������� ���� G � ��������� ����, ��������� ������� ��������� ������:
  � ������ ������ ������������ ���������� ������, ����� - ������� ���������
  ����� }

implementation

function CreateGraphFromGMLFile(const FileName: String; SaveGMLAttrs: Bool): TGraph;
var
  S: TTextStream;
begin
  S:=TTextStream.Create(FileName, tsRead);
  try
    Result:=CreateGraphFromGMLStream(S, SaveGMLAttrs);
  finally
    S.Free;
  end;
end;

procedure GetGraphFromGMLFile(G: TGraph; const FileName: String; SaveGMLAttrs: Bool);
var
  S: TTextStream;
begin
  S:=TTextStream.Create(FileName, tsRead);
  try
    GetGraphFromGMLStream(G, S, SaveGMLAttrs);
  finally
    S.Free;
  end;
end;

procedure WriteGraphToGMLFile(G: TGraph; const FileName: String; SaveAllAttrs: Bool);
var
  S: TTextStream;
begin
  S:=TTextStream.Create(FileName, tsRewrite);
  try
    WriteGraphToGMLStream(G, S, SaveAllAttrs);
  finally
    S.Free;
  end;
end;

procedure WriteGraphSimple(G: TGraph; const FileName: String);
var
  S: TTextStream;
  M: TBoolMatrix;
begin
  S:=TTextStream.Create(FileName, tsRewrite);
  M:=nil;
  try
    M:=G.CreateConnectionMatrix;
    M.WriteToTextStream(S);
  finally
    S.Free;
    M.Free;
  end;
end;

end.
