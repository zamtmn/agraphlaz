{ Version 030614. Copyright � Alexey A.Chernobaev, 1996-2003 }

unit Int16g;

interface

{$I VCheck.inc}

uses
  SysUtils, ExtType, Vectors, Base16v,
  {$IFDEF USE_STREAM64}VStrm64{$ELSE}VStream{$ENDIF}, VTxtStrm, VectErr;

type
  NumberType = Int16;
  PArrayType = PInt16Array;

  TGenericNumberVector = class(TBase16Vector)
  {$I VGeneric.def}
  end;

  TGenericInt16Vector = TGenericNumberVector;
  TGenericSmallIntVector = TGenericInt16Vector;

implementation

{$I VGeneric.imp}

end.
