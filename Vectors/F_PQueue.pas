{ Version 040228. Copyright � Alexey A.Chernobaev, 1996-2004 }

unit F_PQueue;
{
  ������������ ������� �� ���������� ���� Pointer � ������������ ���� Float,
  ������������� �� ������ ������-������ ��������; �������������� ��������
  ���������� �������� � �������� �����������, ��������� ����������, ������
  �������� � ����������� ���� ������������ �����������, � ��� ����� � ���
  ����������� ��������� �� �������; ��� ��� �������� ����� ��������� O(log n).

  Priority queue with values of type Pointer and priorities of type Float based
  on red-black trees; supports insertion of value with given priority, changing
  priority, finding values with minimum and maximum priorities and removing them
  from the queue; all of these operations have time complexity O(log n).
}

interface

{$I VCheck.inc}

uses
  SysUtils, ExtType, ExtSys, Pointerv,
  {$IFDEF USE_STREAM64}VStrm64{$ELSE}VStream{$ENDIF}, VectErr;

type
  TTreeData = record
    Value: Pointer;
    Priority: Float;
  end;

  {$I RBTree.def}

  TFloatPriorityQueue = class
  protected
    FRBTree: TRBTree;
  public
    constructor Create;
    destructor Destroy; override;
    function IsEmpty: Bool;
    { ���������, ����� �� ������� }
    { checks whether the queue is empty }
    function Add(AValue: Pointer; APriority: Float): PNode;
    { ��������� � ������� �������� AValue � ����������� APriority, ���� �
      ������� ��� ���� �� �������� � ��� �� �����������, ����� ������ �� ������;
      ���������� ��������� �� ����������� ��� ������������ ���� ������,
      ���������� ���� <AValue, APriority> (������������ "��������" �������������
      ����� ��������� - � ������ ChangeNodePriority) }
    { adds value AValue with priority APriority to the queue if there is no
      value with the same priority in the queue already, otherwise does nothing;
      returns pointer to the recently added or existed tree node containing the
      pair <AValue, APriority> (the only "legal" use of this pointer is passing
      it to the ChangeNodePriority method) }
    function Min: Pointer;
    { ���������� �������� � ����������� ����������� }
    { returns value with the minimum priority }
    function Max: Pointer;
    { ���������� �������� � ������������ ����������� }
    { returns value with the maximum priority }
    function DeleteMin: Pointer;
    { ���������� �������� � ����������� ����������� � ������� ��� �� ������� }
    { returns value with the minimum priority and removes it from the queue }
    function DeleteMax: Pointer;
    { ���������� �������� � ������������ ����������� � ������� ��� �� ������� }
    { returns value with the maximum priority and removes it from the queue }
    function ChangePriority(AValue: Pointer; OldPriority, NewPriority: Float): PNode;
    { �������� ��������� �������� AValue � OldPriority �� NewPriority, ����
      �������� AValue � ����������� OldPriority ������������ � �������, �����
      Result:=Add(AValue, NewPriority) }
    { changes the priority for value AValue from OldPriority to NewPriority if
      value AValue with priority OldPriority is in the queue, otherwise
      Result:=Add(AValue, NewPriority) }
    function ChangeNodePriority(ANode: PNode; AValue: Pointer; NewPriority: Float): PNode;
    { ���� ANode = nil, �� ��������� � ������� �������� AValue � �����������
      NewPriority, ����� �������� ��������� ��������, ������������� ����� ������
      ANode, �� NewPriority; ��� ANode <> nil ������ ����� ����������� �������,
      ��� ChangePriority, ��������� � ���� ������ ��� �� ��������� ���������
      ����� ���� � ������ }
    { if ANode = nil then adds value AValue with priority NewPriority to the
      queue else changes priority of value defined by the tree node ANode to
      NewPriority; if ANode <> nil then this method executes faster then
      ChangePriority because in that case it doesn't need to search for a node
      in the tree }
  end;

implementation

{$IFDEF CHECK_OBJECTS_FREE}
uses ChckFree;
{$ENDIF}

function CMP(const a, b: TTreeData): Integer; far;
begin
  if a.Priority < b.Priority then
    Result:=-1
  else
    if a.Priority > b.Priority then
      Result:=1
    else
      if {Int32}PtrInt(a.Value) < {Int32}PtrInt(b.Value) then
        Result:=-1
      else
        if {Int32}PtrInt(a.Value) > {Int32}PtrInt(b.Value) then
          Result:=1
        else
          Result:=0;
end;

{$I RBTree.imp}

constructor TFloatPriorityQueue.Create;
begin
  {$IFDEF CHECK_OBJECTS_FREE}
  RegisterObjectCreate(Self);
  {$ENDIF}
  inherited Create;
  FRBTree:=TRBTree.Create;
end;

destructor TFloatPriorityQueue.Destroy;
begin
  {$IFDEF CHECK_OBJECTS_FREE}
  RegisterObjectFree(Self);
  {$ENDIF}
  FRBTree.Free;
  inherited Destroy;
end;

function TFloatPriorityQueue.IsEmpty: Bool;
begin
  Result:=FRBTree.IsEmpty;
end;

function TFloatPriorityQueue.Add(AValue: Pointer; APriority: Float): PNode;
var
  TreeData: TTreeData;
begin
  TreeData.Value:=AValue;
  TreeData.Priority:=APriority;
  Result:=FRBTree.AddNode(TreeData);
end;

function TFloatPriorityQueue.Min: Pointer;
begin
  Result:=FRBTree.Min.Value;
end;

function TFloatPriorityQueue.Max: Pointer;
begin
  Result:=FRBTree.Max.Value;
end;

function TFloatPriorityQueue.DeleteMin: Pointer;
var
  Node: PNode;
begin
  Node:=FRBTree.MinNode;
  Result:=Node^.data.Value;
  FRBTree.DeleteNode(Node);
end;

function TFloatPriorityQueue.DeleteMax: Pointer;
var
  Node: PNode;
begin
  Node:=FRBTree.MaxNode;
  Result:=Node^.data.Value;
  FRBTree.DeleteNode(Node);
end;

function TFloatPriorityQueue.ChangePriority(AValue: Pointer; OldPriority,
  NewPriority: Float): PNode;
var
  TreeData: TTreeData;
  Node: PNode;
begin
  TreeData.Value:=AValue;
  TreeData.Priority:=OldPriority;
  Node:=FRBTree.FindNode(TreeData);
  if Node <> nil then FRBTree.DeleteNode(Node);
  TreeData.Priority:=NewPriority;
  Result:=FRBTree.AddNode(TreeData);
end;

function TFloatPriorityQueue.ChangeNodePriority(ANode: PNode; AValue: Pointer;
  NewPriority: Float): PNode;
var
  TreeData: TTreeData;
begin
  if ANode <> nil then begin
    FRBTree.DeleteNode(ANode);
    TreeData.Value:=AValue;
    TreeData.Priority:=NewPriority;
    Result:=FRBTree.AddNode(TreeData);
  end
  else
    Result:=Add(AValue, NewPriority);
end;

end.
