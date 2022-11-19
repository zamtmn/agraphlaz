{ Version 030505. Copyright � Alexey A.Chernobaev, 1996-2003 }

unit RWGML;
{
  ������ � ������ ������ �������� � GML-�������.
  ���������� � ������������ � "GML: Graph Modelling Language. Draft version.
  Michael Himsolt. December 19, 1996."
  ������� �� ������� ��������:
  1) ��� ����������� �� ����� ������ (�� �������� - �� ����� 254-� ��������);
  2) ������ �� �����������;
  3) ������ �� �������������� � ISO 8859-1 ���������;
  4) ������ ����������� � ������� ������� (ASCII 34); ������� �������,
     �������� � ������ ������, �����������.
}

interface

{$I VCheck.inc}

uses
  SysUtils, ExtType, Pointerv, VectStr, VTxtStrm, VFormat, GMLObj;

const
  ListOpen = '[';
  ListClose = ']';
  GMLIndent: String = '  '; { ������, ������������ ��� ������ GML-�������� }

type
  EGMLReadError = class(Exception);

  TGMLReader = class
  protected
    Line: String;
    Pos, LineLen: Integer;
    FLineNumber: Int32;
    FStream: TTextStream;
  public
    constructor Create(AStream: TTextStream);
    procedure Error(const Msg: String);
    function HaveData: Bool;
    function GetTerm: String;
    function ReadObject(const AKey: String): TGMLObject;
    function FindKey(const AKey: String): Bool;
    { ����� ��������� ������ � ������ AKey (AKey ������ ���� � lower case) }
    procedure ReadObjects(AList: TClassList; ReadingList: Bool);
    property LineNumber: Int32 read FLineNumber;
  end;

function CreateGMLObjectFromStream(TextStream: TTextStream): TGMLObject;
{ ������ �� ���������� ������ � ������� ��������� GML-������ �������� ������;
  ���� ��� ������ ���������� ������ ���� ����� ����, �� ������������
  �������������� �������� }

procedure ReadGMLObjectsFromStream(GMLObjects: TClassList; TextStream: TTextStream);
{ ������ �� ���������� ������ ������ ������ GML-�������� (��������, ������) }

procedure WriteGMLObjectsToStream(const Indent: String; GMLObjects: TClassList;
  TextStream: TTextStream);
{ ���������� � ��������� ����� ������ GML-�������� � �������� Indent }

implementation

const
  Spaces = [#0..' '];
  Comment = '#';
  Delimiters = [ListOpen, ListClose];
  Quote = '"';

  SUnexpectedEOF = 'Unexpected end of file';
  SWrongIdentifier = 'Wrong identifier';
  SListCloseExpected = '''' + ListClose + ''' expected';
  SUnterminatedString = 'Unterminated string';
  SWrongNumber = 'Wrong number';
  SOnLine = ' on line #';

constructor TGMLReader.Create(AStream: TTextStream);
begin
  inherited Create;
  FStream:=AStream;
  FLineNumber:=AStream.LineNumber;
  Pos:=1;
end;

procedure TGMLReader.Error(const Msg: String);
{$IFDEF V_DELPHI}{$IFDEF WIN32}
  function ReturnAddr: Pointer;
  asm
          mov     eax, [ebp+4]
  end;
{$ENDIF}{$ENDIF}
begin
  raise EGMLReadError.Create(Msg + SOnLine + IntToStr(FLineNumber))
    {$IFDEF V_DELPHI}{$IFDEF WIN32}at ReturnAddr{$ENDIF}{$ENDIF};
end;

function TGMLReader.HaveData: Bool;
{ ���� ������� ������ ��������� ���������, �� ������ ��������� ������ � �������,
  ��������� ������ ������ � ������-����������� (������, ������������ � �������
  Comment); ���� ��������� ����� ������, �� ���������� True, ����� - False; �
  ��������� ������ � ����������� ������ ���������� ��������� � �������� �������
  � ������ <= ' ', ����� ���� ��� ���������� � ���� Line � �����������
  ������������ LineLen:=Length(Line); Pos:=1 }
begin
  if Pos > LineLen then begin
    repeat
      if FStream.EOF then begin
        Result:=False;
        Exit;
      end;
      Line:=FStream.ReadTrimmed;
    until (Line <> '') and (Line[1] <> Comment);
    LineLen:=Length(Line);
    Pos:=1;
  end;
  Result:=True;
end;

function TGMLReader.GetTerm: String;
{ ���������� ��������� ������� }
var
  OldPos: Integer;
  B: Bool;
  C: Char;
begin
  B:=HaveData;
  FLineNumber:=FStream.LineNumber;
  if not B then Error(SUnexpectedEOF);
  OldPos:=Pos;
  Inc(Pos);
  if not (Line[OldPos] in Delimiters) then
    if Line[OldPos] <> Quote then
      { �� Quote => ������ �� ����� ��� ����������� }
      while (Pos <= LineLen) and not (Line[Pos] in (Spaces + Delimiters)) do
        Inc(Pos)
    else
      { Quote => ������ ������, � ������� ����������� ��������� Quote }
      while Pos <= LineLen do begin
        C:=Line[Pos];
        Inc(Pos);
        if (C = Quote) and (Pos <= LineLen) then
          if Line[Pos] = Quote then Inc(Pos)
          else
            Break;
      end;
  Result:=Copy(Line, OldPos, Pos - OldPos);
  while (Pos <= LineLen) and (Line[Pos] in Spaces) do Inc(Pos);
end;

function TGMLReader.ReadObject(const AKey: String): TGMLObject;
var
  KeyLineNumber: Integer;
  T: String;
  NewList: TClassList;
begin
  KeyLineNumber:=FLineNumber;
  if not IsCorrectIdentifier(AKey,false) then
    Error(SWrongIdentifier + ' ''' + AKey + '''');
  T:=GetTerm;
  if T = ListOpen then begin
    NewList:=TClassList.Create;
    try
      ReadObjects(NewList, True);
    except
      NewList.FreeItems;
      NewList.Free;
      raise;
    end;
    Result:=TGMLObject.CreateList(AKey, NewList);
  end
  else if T[1] = Quote then begin
    if (Length(T) < 2) or (T[Length(T)] <> Quote) then
      Error(SUnterminatedString);
    Result:=TGMLObject.CreateString(AKey, LiteralToString(T));
  end
  else begin
    Result:=nil;
    try
      if System.Pos('.', T) = 0 then
        Result:=TGMLObject.CreateInt(AKey, StrToInt(T))
      else
        Result:=TGMLObject.CreateReal(AKey, StringToReal(T));
    except
      Result.Free;
      Error(SWrongNumber + ' ''' + T + '''');
    end;
  end;
  Result.Tag:=KeyLineNumber;
end;

function TGMLReader.FindKey(const AKey: String): Bool;
var
  Key: String;
begin
  while HaveData do begin
    Key:=LowerCase(GetTerm);
    if Key = AKey then begin
      Result:=True;
      Exit;
    end
    else begin
      if not IsCorrectIdentifier(Key,false) then
        Error(SWrongIdentifier + ' ''' + Key + '''');
      if GetTerm = ListOpen then
        if not FindKey(ListClose) then Error(SListCloseExpected);
    end;
  end;
  Result:=False;
end;

procedure TGMLReader.ReadObjects(AList: TClassList; ReadingList: Bool);
var
  Key: String;
begin
  while HaveData do begin
    Key:=GetTerm;
    if ReadingList and (Key = ListClose) then Exit;
    AList.Add(ReadObject(Key));
  end;
  if ReadingList then begin
    FLineNumber:=FStream.LineNumber;
    Error(SListCloseExpected);
  end;
end;

function CreateGMLObjectFromStream(TextStream: TTextStream): TGMLObject;
var
  GMLReader: TGMLReader;
begin
  GMLReader:=TGMLReader.Create(TextStream);
  try
    Result:=GMLReader.ReadObject(GMLReader.GetTerm);
  finally
    GMLReader.Free;
  end;
end;

procedure ReadGMLObjectsFromStream(GMLObjects: TClassList; TextStream: TTextStream);
var
  GMLReader: TGMLReader;
begin
  GMLReader:=TGMLReader.Create(TextStream);
  try
    GMLReader.ReadObjects(GMLObjects, False);
  finally
    GMLReader.Free;
  end;
end;

procedure WriteGMLObjectsToStream(const Indent: String; GMLObjects: TClassList;
  TextStream: TTextStream);
var
  I: Integer;
  GMLObject: TGMLObject;

  procedure WriteValue(const Value: String);
  begin
    TextStream.WriteString(Indent + GMLObject.Key + ' ' + Value);
  end;

  function CorrectedReal(const Value: String): String;
  { ��� ����, ����� �������� � GML ������������ ����� �� �����, � ������
    ������ ����������� ������ �������������� '.' }
  var
    I: Integer;
  begin
    Result:=Value;
    I:=Pos('.', Value);
    if I = 0 then Result:=Result + '.0';
  end;

begin
  for I:=0 to GMLObjects.Count - 1 do begin
    GMLObject:=TGMLObject(GMLObjects[I]);
    Case GMLObject.GMLType of
      GMLInt:
        WriteValue(IntToStr(GMLObject.Data.AsInt));
      GMLReal:
        WriteValue(CorrectedReal(RealToString(GMLObject.Data.AsReal, DefaultRealFormat)));
      GMLString:
        WriteValue(StringToLiteral2(GMLObject.Data.AsString^));
    Else {GMLList}
      WriteValue(ListOpen);
      WriteGMLObjectsToStream(Indent + GMLIndent, GMLObject.Data.AsList,
        TextStream);
      TextStream.WriteString(Indent + ListClose);
    End;
  end;
end;

end.
