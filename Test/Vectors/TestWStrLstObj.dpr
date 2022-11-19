program TestWideStrLstObj;

{$I VCheck.inc}

uses
  SysUtils, ExtType, VectStr, WStrLst;

{$APPTYPE CONSOLE}

type
  ETestError = class(Exception);

procedure Test;

  procedure Error;
  begin
    raise ETestError.Create('Wrong Result');
  end;

  procedure Check(Vector: TWideStrLst; const Values: array of String);
  var
    I: Integer;
  begin
    for I:=0 to High(Values) do
      if Vector.Items[I] <> Values[I] then Error;
  end;

var
  S1, S2: TWideStrLstObj;
  S: WideString;
begin
  S1:=TCaseSensWideStrLstObj.Create;
  S2:=TCaseSensWideStrLstObj.Create;
  try
    S1.Add('qwerty');
    if S1.Objects[0] <> nil then Error;
    S1.AddObject('����', Pointer(1));
    Check(S1, ['qwerty', '����']);
    if S1.IndexOf('����') <> 1 then Error;
    if S1.IndexOf('z') >= 0 then Error;
    if S1.IndexOfObject(Pointer(1)) <> 1 then Error;
    if S1.IndexOfObject(Pointer(2)) <> -1 then Error;
    S1.Add('zxcvb');
    Check(S1, ['qwerty', '����', 'zxcvb']);
    S1.Objects[0]:=Pointer(2);
    if (S1.IndexOfObject(Pointer(2)) <> 0) then Error;
    S1.Sort;
    Check(S1, ['qwerty', 'zxcvb', '����']);
    S1.Exchange(0, 2);
    S1.Exchange(1, 2);
    if S1.IndexOfObject(Pointer(1)) <> 0 then Error;
    if S1.IndexOfObject(Pointer(2)) <> 1 then Error;
    if S1.IndexOfObject(nil) <> 2 then Error;
    S1.Objects[0]:=nil;
    if S1.IndexOfObject(Pointer(1)) <> -1 then Error;
    S1.InsertObject(2, 'abc', Pointer(1));
    Check(S1, ['����', 'qwerty', 'abc', 'zxcvb']);
    if S1.IndexOfObject(Pointer(1)) <> 2 then Error;
    S2.Assign(S1);
    Check(S2, ['����', 'qwerty', 'abc', 'zxcvb']);
               { nil } { 2 }     { 1 }  { nil }
    if S2.IndexOfObject(nil) <> 0 then Error;
    if S2.IndexOfObject(Pointer(1)) <> 2 then Error;
    if S2.IndexOfObject(Pointer(2)) <> 1 then Error;
    if S2.IndexOfObject(Pointer(3)) <> -1 then Error;
    S2.Move(0, 3);
    Check(S2, ['qwerty', 'abc', 'zxcvb', '����']);
    if S2.IndexOfObject(nil) <> 2 then Error;
    if S2.IndexOfObject(Pointer(1)) <> 1 then Error;
    if S2.IndexOfObject(Pointer(2)) <> 0 then Error;
    if S2.IndexOfObject(Pointer(3)) <> -1 then Error;
    S1.Clear;
    S1.ConcatenateWith(S2);
    if not S1.Equals(S2) then Error;
    S1.ConcatenateWith(S1);
    Check(S1, ['qwerty', 'abc', 'zxcvb', '����',
               'qwerty', 'abc', 'zxcvb', '����']);
    S:=S1.Text;
    {$IFDEF V_WIN}
    writeln(AnsiToOem(S));
    {$ENDIF}
    if S1.Objects[0] <> Pointer(2) then Error;
    if S1.Objects[1] <> Pointer(1) then Error;
    if S1.Objects[2] <> nil then Error;
    if S1.Objects[3] <> nil then Error;
    if S1.Objects[4] <> Pointer(2) then Error;
    if S1.Objects[5] <> Pointer(1) then Error;
    if S1.Objects[6] <> nil then Error;
    if S1.Objects[7] <> nil then Error;
    if S1.Names[0] <> '' then Error;
    if S1.Values[0] <> '' then Error;
    S1.Insert(0, 'a=b');
    if S1.Names[0] <> 'a' then Error;
    if S1.Values[0] <> 'b' then Error;
    S1.Text:=S;
    Check(S1, ['qwerty', 'abc', 'zxcvb', '����',
               'qwerty', 'abc', 'zxcvb', '����']);
  finally
    S1.Free;
    S2.Free;
  end;
  writeln('Ok');
end;

begin
  Test;
  write('Press Return to continue...');
  readln;
end.
