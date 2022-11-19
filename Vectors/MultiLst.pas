{ Version 050603. Copyright � Alexey A.Chernobaev, 1996�2005 }

unit MultiLst;
{
  ������������ (������ �������).

  Multilist (list of lists).
}

interface

{$I VCheck.inc}

uses
  ExtType, Pointerv;

type
  TMultiList = class
  protected
    FList: TClassList;
    ListClass: TClassListClass;
    function GetCount: Integer;
    procedure SetCount(ACount: Integer);
    function GetList(I: Integer): TClassList;
    procedure SetList(I: Integer; Value: TClassList);
  public
    constructor Create(AListClass: TClassListClass);
    { AListClass: ����� ������� - ��������� ������������ }
    { AListClass: class of lists - elements of the multilist }
    destructor Destroy; override;
    procedure Assign(Source: TMultiList);
    procedure Clear;
    procedure Grow(Delta: Integer);
    procedure Exchange(I, J: Integer); {$IFDEF V_INLINE}inline;{$ENDIF}
    { ������ ������� �������� � ��������� I � J }
    { exchanges elements with indexes I and J }
    procedure Add(Value: TClassList); {$IFDEF V_INLINE}inline;{$ENDIF}
    { ��������� ������ Value � ����� ������������ }
    { appends Value to the end of the multilist }
    procedure AddAssign(Value: TClassList);
    { ��������� ��������� � ������� Assign ����� Value � ����� ������������ }
    { appends the copy of Value created with help of Assign to the end of the
      multilist }
    function IsNil(I: Integer): Bool;
    { ���������, ������ �� I-� ������-�������; �������� ��������� ��� ���������
      � �������� List ������������� }
    { checks whether the Ith list-element was created; lists are created
      automatically when accessing the List property }
    procedure Delete(I: Integer);
    { ���������� � ������� I-� ������� }
    { frees and deletes the Ith element }
    function Last: TClassList;
    { ���������� ��������� ������-������� }
    { returns the last list-element }
    function IndexOf(Value: TClassList): Integer;
    { ���������� ������ ������� ��������� ������ Value � ������������, ���� -1,
      ���� ��� ��������� }
    { returns the index of the first occurrence of the list Value in the
      multilist or -1 if there are no such occurrences }

    property Count: Integer read GetCount write SetCount;
    { ���������� ��������� }
    { number of elements in the multilist }
    property List[I: Integer]: TClassList read GetList write SetList; default;
    { ������-��������; ������ ��������� ��� ��������� � �������� �������������,
      ���� ��� ���������� (IsNil[I] = True); ����� ���������� I-� ������,
      ������� ��������� ��� �������� nil }
    { lists-elements; lists are created automatically when accessing this
      property if needed (i.e. if IsNil[I] = True); to free the Ith list it's
      necessary to assign it the nil value }
  end;

implementation

constructor TMultiList.Create(AListClass: TClassListClass);
begin
  inherited Create;
  ListClass:=AListClass;
  FList:=TClassList.Create;
end;

destructor TMultiList.Destroy;
begin
  FList.FreeItems;
  FList.Free;
  inherited Destroy;
end;

function TMultiList.GetCount: Integer;
begin
  Result:=FList.Count;
end;

procedure TMultiList.SetCount(ACount: Integer);
var
  I: Integer;
begin
  if ACount < FList.Count then
    for I:=ACount to FList.Count - 1 do TClassList(FList[I]).Free;
  FList.Count:=ACount;
end;

function TMultiList.GetList(I: Integer): TClassList;
begin
  Result:=TClassList(FList[I]);
  if Result = nil then begin
    Result:=ListClass.Create;
    FList[I]:=Result;
  end;
end;

procedure TMultiList.SetList(I: Integer; Value: TClassList);
begin
  TClassList(FList[I]).Free;
  FList[I]:=Value;
end;

procedure TMultiList.Assign(Source: TMultiList);
var
  I, N: Integer;
  AList: TClassList;
begin
  N:=Source.Count;
  Count:=N;
  if ListClass = Source.ListClass then
    for I:=0 to N - 1 do begin
      AList:=TClassList(Source.FList[I]);
      if AList <> nil then List[I].Assign(AList)
      else begin
        TClassList(FList[I]).Free;
        FList[I]:=nil;
      end;
    end
  else begin
    ListClass:=Source.ListClass;
    for I:=0 to N - 1 do begin
      AList:=TClassList(Source.FList[I]);
      List[I]:=nil;
      if AList <> nil then List[I].Assign(AList);
    end;
  end;
end;

procedure TMultiList.Clear;
begin
  Count:=0;
end;

procedure TMultiList.Grow(Delta: Integer);
begin
  Count:=Count + Delta;
end;

procedure TMultiList.Exchange(I, J: Integer);
begin
  FList.Exchange(I, J);
end;

procedure TMultiList.Add(Value: TClassList);
begin
  FList.Add(Value);
end;

procedure TMultiList.AddAssign(Value: TClassList);
var
  N: Integer;
begin
  N:=FList.Count;
  FList.Count:=N + 1;
  TClassList(List[N]).Assign(Value);
end;

function TMultiList.IsNil(I: Integer): Bool;
begin
  Result:=FList[I] = nil;
end;

procedure TMultiList.Delete(I: Integer);
begin
  TObject(FList[I]).Free;
  FList.Delete(I);
end;

function TMultiList.Last: TClassList;
begin
  Result:=List[Count - 1];
end;

function TMultiList.IndexOf(Value: TClassList): Integer;
begin
  Result:=FList.IndexOf(Value);
end;

end.
