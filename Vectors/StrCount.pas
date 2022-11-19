{ Version 000907. Copyright � Alexey A.Chernobaev, 1996-2000 }

unit StrCount;
{
  �������-������� �����.

  String-counting dictionary.
}

interface

{$I VCheck.inc}

uses
  SysUtils, ExtType, Pointerv, Aliasv, SIDic;

type
  EStrCounterError = class(Exception);

  TStrCounter = class
  protected
    FSIDic: TStrIntDic;
    FTotalCount: Integer;
    procedure Initialize; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    { ������� ������� }
    { clears the dictionary }
    function IsEmpty: Bool;
    { ���������� True, ���� ������� ����, � False ����� }
    { returns True if the dictionary is empty or False otherwise }
    function Add(const AValue: String): Bool;
    { ��������� �������� � �������; ���������� True, ���� � ������� �� ����
      �����, ������ AValue (��������� ������������ ������� FSIDic.Compare),
      ����� False; � ������ ������ ������� ���������� �����, ������ AValue,
      ��������������� ������ 1, �� ������ - ������������� �� 1 }
    { adds the value to the dictionary; returns True if there are no values
      equal to AValue in the dictionary (equality is defined by FSIDic.Compare)
      and False otherwise; in the first case sets the counter of strings equal
      to AValue to 1, in the second - increases it by 1 }
    function AddWithCount(const AValue: String; ACount: Integer): Bool;
    { ������ Add, ������� ����������� ������� ���������� �����, ������ AValue,
      �� ACount (ACount >= 1) }
    { analog of Add which increases the counter of string equal to AValue by
      ACount (ACount >= 1) }
    function Find(const AValue: String): Bool;
    { ���������� True, ���� � ������� ���� ������, ������ AValue (���������
      ������������ ������� FSIDic.Compare), � False - ����� }
    { returns True if there is a string equal to AValue in the dictionary
      (equality is defined by FSIDic.Compare) and False otherwise }
    function DeleteMin: String;
    { ���������� ����������� ������ � ��������� �� ������� �� �������; ����
      ������� ��� ����� 1, �� ������� ��� ������ �� ������� }
    { returns the minimum string and decreases it's counter by 1; if this
      counter was equal to 1 then deletes the string from the dictionary }
    function DeleteMax: String;
    { ���������� ������������ ������ � ��������� �� ������� �� �������; ����
      ������� ��� ����� 1, �� ������� ��� ������ �� ������� }
    { returns the maximum string and decreases it's counter by 1; if this
      counter was equal to 1 then deletes the string from the dictionary }
    function StringCount(const AValue: String): Integer;
    { ���������� �������� �������� �����, ������ AValue (��������� ������������
      ������� FSIDic.Compare), � ������� }
    { returns the counter of strings equal to AValue in the dictionary (equality
      is defined by FSIDic.Compare)}
    function Count: Integer;
    { ���������� ���������� ��������� ����� (�.�. ���������� ����� ��� �����
      ���������) � ������� }
    { returns the number of different strings (i.e. the number of strings
      leaving counters out of account) in the dictionary }
    function TotalCount: Integer;
    { ���������� ����� ���������� ����� (�.�. ����� ���� ���������) � ������� }
    { returns the total number of strings (i.e. the sum of all counters) in the
      dictionary }
    property Dic: TStrIntDic read FSIDic;
    { ������������ ������� "������� ������" ���� string-integer }
    { used "low-level" dictionary of type string-integer }
  end;

  TStrCounterClass = class of TStrCounter;

  TCaseSensStrCounter = class(TStrCounter)
    procedure Initialize; override;
  end;

  TCaseSensStrCounterClass = class of TCaseSensStrCounter;

implementation

{$IFDEF CHECK_OBJECTS_FREE}
uses ChckFree;
{$ENDIF}

{ TStrCounter }

constructor TStrCounter.Create;
begin
  inherited Create;
  Initialize;
  {$IFDEF CHECK_OBJECTS_FREE}
  RegisterObjectCreate(Self);
  {$ENDIF}
end;

procedure TStrCounter.Initialize;
begin
  FSIDic:=TStrIntDic.Create;
end;

destructor TStrCounter.Destroy;
begin
  {$IFDEF CHECK_OBJECTS_FREE}
  RegisterObjectFree(Self);
  {$ENDIF}
  FSIDic.Free;
  inherited Destroy;
end;

procedure TStrCounter.Clear;
begin
  FSIDic.Clear;
  FTotalCount:=0;
end;

function TStrCounter.IsEmpty: Bool;
begin
  Result:=FSIDic.IsEmpty;
end;

function TStrCounter.Add(const AValue: String): Bool;
begin
  Result:=AddWithCount(AValue, 1);
end;

function TStrCounter.AddWithCount(const AValue: String; ACount: Integer): Bool;
var
  P: PDicData;
begin
  if ACount <= 0 then
    raise EStrCounterError.Create('TStrCounter.AddWithCount: error in parameters');
  P:=FSIDic.PData(AValue);
  if P = nil then begin
    FSIDic.Add(AValue, ACount);
    Result:=True;
  end
  else begin
    Inc(P^, ACount);
    Result:=False;
  end;
  Inc(FTotalCount, ACount);
end;

function TStrCounter.Find(const AValue: String): Bool;
begin
  Result:=FSIDic.Find(AValue);
end;

function TStrCounter.DeleteMin: String;
var
  Node: PNode;
begin
  Node:=FSIDic.MinNode;
  Result:=Node^.data.Key;
  Dec(Node^.data.Data);
  if Node^.data.Data = 0 then FSIDic.DeleteNode(Node);
end;

function TStrCounter.DeleteMax: String;
var
  Node: PNode;
begin
  Node:=FSIDic.MaxNode;
  Result:=Node^.data.Key;
  Dec(Node^.data.Data);
  if Node^.data.Data = 0 then FSIDic.DeleteNode(Node);
end;

function TStrCounter.StringCount(const AValue: String): Integer;
var
  P: PDicData;
begin
  P:=FSIDic.PData(AValue);
  if P <> nil then Result:=P^ else Result:=0
end;

function TStrCounter.Count: Integer;
begin
  Result:=FSIDic.Count;
end;

function TStrCounter.TotalCount: Integer;
begin
  Result:=FTotalCount;
end;

{ TCaseSensStrCounter }

procedure TCaseSensStrCounter.Initialize;
begin
  FSIDic:=TCaseSensStrIntDic.Create;
end;

end.
