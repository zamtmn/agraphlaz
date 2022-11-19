{ Version 991226. Copyright � Alexey A.Chernobaev, 1996-1999 }

unit Optimize;
{
  � ������ ����������� ��������� ��������� ���������� �����������:
  - ������� ������ � �������;
  - ���������� ���������� ������������ ���������������������;
  - ���������� ������������� ������� ������ � ���������� ��������;
  - ���������� ������� ������� (���� �������) ������ � ���������� ��������;
  - ���������� ������� ������� ������ � �������� ������������ ���������� ����.
}

interface

{$I VCheck.inc}

uses
  ExtType, ExtSys, Aliasv, Aliasm, Int16v, Int16g, Int16m, Int32m, F32v, F64v,
  Boolv, Boolm, Pointerv, VectErr, MathErr;

function KnapsackPacking(Values, Volumes: TGenericIntegerVector; Limit: Integer;
  Solution: TBoolVector): Integer;
{ ������ ������ � ������� ������� ������������� ����������������. ������ �
  �������: ������� N > 0 ��������� � "����������" Values[I] (Values[I] >= 0) �
  "��������" Volumes[I] (Volumes[I] >= 0), I=0..N-1. ��������� ����� �����
  "�������" �������, ����� �������� ��������� ��������� Limit, ����� ���������
  ��������� ���������� � ������ ��������� ���� �����������. ������� ����������
  ��������� ������������ ��������� ���������. ���� Solution <> nil, �� �����
  ���������� ������ ������� Solution[I] ����� True, ���� I-� ������� ������ �
  ����������� �������, � False �����.
  ����������:
  1) ���� ������ ����� ����� ������ �������, �� ������� ������� ����� �� ���;
  2) ���� Values[I] = 0, �� ������� �� ������� (Solution[I] = False) ���� ���
     Volumes[I] = 0;
  3) ���� Limit <= 0, �� Solution[I] = False, I=0..N-1. }

function FindLIS(Sequence, Solution: TGenericIntegerVector): Integer;
{ ������� ���������� ������������ ��������������������� (LIS: Longest Increasing
  Subsequence) ������� Sequence. ������: ��� ������� [1, 2, 8, 9, 3, 2, 4, 6]
  �������� �������� [1, 2, 3, 4, 6]. ������������ ����� ��������� LIS; ����
  Solution <> nil, �� � Solution ������������ ���� �� ��������� �������.
  ���������: O(n^2). }

function CoveringExists(Matrix: TBoolMatrix): Bool;
{ ���������, ����� �� ������� ���� �������, �.�. � ������ �� ������ ���� "1". }

function GradientCovering(Matrix: TBoolMatrix; Solution: TGenericIntegerVector): Bool;
{ ������� �������� 0,1-������� Matrix � �������������� ������������� ������������
  ������. ������ � ���������� �������� ������� (���): ����� ����� ����� ��������
  �������, ��� �� ���������� (OR) ���� ������, ��������� ������ �� ������, �,
  ����� ����, ���������� �������� � ���� ������ ����������. ���� ������� �����
  ���� ������� (�.�. � ��� ��� �����, ��������� ������ �� �����), �� �������
  ������� ������������ ������� ��� � ���������� True; ������ ��������, ��������
  � ��������� ��������, ������������ � ������� Solution.
  ����������� �����: �� ��������� ���� ���������� �������, �����������
  ������������ ���������� ��� �� �������� ����� �������; ������� ������������,
  ���� �� ����� ������� ��� ������. }

function FindMinCoverings(Matrix: TBoolMatrix; SolutionCount: Integer;
  Solutions: TClassList): Integer;
{ ������� ������ ������� ��� ��� 0,1-������� Matrix; ������������ ����������
  ����� ������ � ������. ���� SolutionCount <= 0, �� � Solutions ������������
  ��� ������� (� ���� ������ �������� ������ TIntegerVector, ������ �� �������
  ������������� ������ ��������); ���� SolutionCount > 0, �� ������������
  min(SolutionCount, <���������� ����������� ��������>) �������. �������
  ���������� ���������� ��������� ��������.
  ����������: ����� ������������ Solutions ���������� ���������� ��������
  � ������ Solutions ������� (Solutions.FreeItems). }

function FindMinWeightCovering(Matrix: TBoolMatrix; Weights: TFloatVector;
  Solution: TGenericIntegerVector; var Weight: Float): Bool;
{ ������� �������� ������������ ���������� ���� ��� 0,1-������� Matrix (���
  � ������); ������������ ���������� ����� ������ � ������. ���� ��������
  ���������� � Weights; ������� ������������ � ������� Solution; � ����������
  Weight ������������ ��������� ����������� ���. }

implementation

function KnapsackPacking(Values, Volumes: TGenericIntegerVector; Limit: Integer;
  Solution: TBoolVector): Integer;
var
  N, I, T, VolumeSum: Integer;
  Cache: TIntegerMatrix;
  B: Bool;

  function F(I, E: Integer): Integer;
  var
    T: Integer;
  begin
    if (E < Limit) and (I <= N) then begin
      Result:=Cache[I, E];
      if Result < 0 then begin
        if I < N then begin
          Result:=F(I + 1, E);
          T:=E + Volumes[I];
          if T < Limit then begin
            T:=Values[I] + F(I + 1, T);
            if T > Result then Result:=T;
          end;
        end
        else
          if E > Limit - Volumes[N] then Result:=0
          else Result:=Values[N];
        Cache[I, E]:=Result;
      end;
    end
    else
      Result:=0;
  end;

begin
  {$IFDEF CHECK_MATH}
  if (Values.Count <> Volumes.Count) or (Values.Min < 0) or (Volumes.Min < 0) then
    MathError(SErrorInParameters, [0]);
  {$ENDIF}
  N:=Values.Count;
  if Solution <> nil then Solution.Count:=N;
  if (Limit > 0) and (Limit >= Volumes.Min) then begin
    Cache:=TSparseIntegerMatrix.Create(N, Limit, -1);
    Dec(N);
    try
      { ������ ��� }
      Result:=F(1, 0);
      B:=False;
      T:=Volumes[0];
      if T < Limit then begin
        T:=Values[0] + F(1, T);
        if T > Result then begin
          Result:=T;
          B:=True;
        end;
      end;
      { �������� ��� }
      if Solution <> nil then begin
        Solution[0]:=B;
        VolumeSum:=Ord(B) * Volumes[0];
        for I:=1 to N - 1 do begin
          B:=False;
          T:=VolumeSum + Volumes[I];
          if (T < Limit) and (Values[I] + F(I + 1, T) > F(I + 1, VolumeSum)) then begin
            B:=True;
            VolumeSum:=T;
          end;
          Solution[I]:=B;
        end;
        if N > 0 then Solution[N]:=(Values[N] > 0) and (VolumeSum + Volumes[N] <= Limit);
      end;
    finally
      Cache.Free;
    end;
  end
  else begin
    if Solution <> nil then Solution.FillValue(False);
    Result:=0;
  end;
end;

function FindLIS(Sequence, Solution: TGenericIntegerVector): Integer;
{
  ��������: Pruhs Kirk. How to Design Dynamic Programming Algorithms Sans
  Recursion (kirk@cs.pitt.edu). - University of Pittsburgh, Computer Science
  Department.
  ������������ ������������ ����������������: LIS[i, j] = <����� ����������
  ������������ ��������������������� ������������������ x[1]...x[i], �������
  ������������ ��������� x[j]>, ��� x[i] = Sequence[i], 1<=i<=N, 1<=j<=N,
  N = |Sequence|.
}
var
  I, J, K, N, MaxIndex: Integer;
  LIS: TIntegerMatrix;
begin
  N:=Sequence.Count;
  if N > 0 then begin
    LIS:=TIntegerMatrix.Create(N, N, 1);
    try
      for I:=1 to N - 1 do
        for J:=0 to I - 1 do begin
          LIS[I, J]:=IntMax(LIS[I - 1, J], LIS[I, J]);
          if Sequence[J] < Sequence[I] then { '<=', ���� ���� ����� ����������� ����-�� }
            LIS[I, I]:=IntMax(LIS[I, I], LIS[I - 1, J] + 1);
        end;
      MaxIndex:=LIS.RowMaxIndex(N - 1, Result);
      if Solution <> nil then begin
        Solution.Count:=Result;
        K:=Result - 1;
        Solution[K]:=Sequence[MaxIndex];
        I:=N;
        while K > 0 do begin
          Dec(MaxIndex);
          Dec(I);
          for J:=MaxIndex downto 1 do
            if LIS[I, J] = K then begin
              MaxIndex:=J;
              Break;
            end;
          Dec(K);
          Solution[K]:=Sequence[MaxIndex];
        end;
      end;
    finally
      LIS.Free;
    end;
  end
  else begin
    if Solution <> nil then Solution.Clear;
    Result:=0;
  end;
end;

function CoveringExists(Matrix: TBoolMatrix): Bool;
{ ���������, ����� �� ������� ���� ������� }
label NextI;
var
  I, J, N: Integer;
begin
  N:=Matrix.ColCount;
  Result:=False;
  if N > 0 then begin
    for I:=0 to Matrix.RowCount - 1 do begin
      for J:=0 to N - 1 do
        if Matrix[I, J] then goto NextI;
      Exit;
  NextI:
    end;
    Result:=True;
  end;
end;

function GradientCovering(Matrix: TBoolMatrix; Solution: TGenericIntegerVector): Bool;
var
  I, J, K, M, N, Sum: Integer;
  NumTrue: TIntegerVector;
  RowAllowed: TBoolVector;
begin
  Result:=False;
  Solution.Clear;
  if CoveringExists(Matrix) then begin
    M:=Matrix.RowCount;
    N:=Matrix.ColCount;
    NumTrue:=TIntegerVector.Create(N, 0);
    RowAllowed:=TBoolVector.Create(M, True);
    try
      for J:=0 to N - 1 do begin
        Sum:=0;
        for I:=0 to M - 1 do
          Inc(Sum, Ord(Matrix[I, J]));
        NumTrue[J]:=Sum;
      end;
      repeat
        K:=NumTrue.MaxIndex(Sum);
        if Sum = 0 then Break;
        Solution.Add(K);
        for I:=0 to M - 1 do
          if RowAllowed[I] and Matrix[I, K] then begin
            for J:=0 to N - 1 do
              NumTrue.DecItem(J, Ord(Matrix[I, J]));
            RowAllowed[I]:=False;
          end;
      until False;
      Result:=True;
    finally
      NumTrue.Free;
      RowAllowed.Free;
    end;
  end;
end;

function FindMinCoverings(Matrix: TBoolMatrix; SolutionCount: Integer;
  Solutions: TClassList): Integer;
var
  I, J, K, M, N, MinCount, CurrentCount, RowsAllowed, ColsAllowed: Integer;
  FindMany, MatrixReduced, B: Bool;
  RowAllowed, ColAllowed, CurrentSolution: TBoolVector;
  CommonSolution, BackCounts, BackIndexes, NewColToCol, ColList, NumTrue,
    TempRowsAllowed, TempCounts, TempNumTrue: TIntegerVector;
  TempRowAllowed, RowCols: TClassList;
  NewMatrix: TBoolMatrix;

  function SingleTrueInRow(Row: Integer): Integer;
  { ���� � ������ Row ������� Matrix ������� ����� ���� �������� True, ��
    ������� ���������� ������ ����� ��������, ����� ������������ -1 }
  var
    J: Integer;
  begin
    Result:=-1;
    for J:=0 to N - 1 do
      if Matrix[Row, J] then begin
        if Result >= 0 then begin
          Result:=-1;
          Exit;
        end;
        Result:=J;
      end;
  end;

  function Column1Dominates2(Column1, Column2: Integer): Bool;
  var
    I: Integer;
  begin
    for I:=0 to M - 1 do
      if Matrix[I, Column2] and not Matrix[I, Column1] then begin
        Result:=False;
        Exit;
      end;
    Result:=True;
  end;

  procedure DoCover(Level: Integer);
  var
    I, J, K, L, OldRowsAllowed, BackCount: Integer;
    ColList, OldNumTrue, T: TIntegerVector;

    function CurrentSolutionDominated: Bool;
    { ���������, �� ������������ �� ������� ��������� ������� ����� ���������
      ��������� �������� (���� ��������� ������� ������������ ������, ���� ���
      ������� �� ������ ���� �������, � ��� ������, �������� ������, �������
      ������, �.�. ������ ������� "�����" �������) }
    var
      I, N: Integer;
      TempBoolVector: TBoolVector;
    begin
      I:=0;
      N:=TempCounts.Count;
      while (I < N) and (TempCounts[I] <= CurrentCount) do begin
        { ��������� RowAllowed.Dominates(...), � �� ��������, ��������� ������
          �� �������� ������, �, ��������, ����������� ������ }
        if (RowsAllowed >= TempRowsAllowed[I]) and
          RowAllowed.Dominates(TBoolVector(TempRowAllowed[I]))
        then begin
          Result:=True;
          Exit;
        end;
        Inc(I);
      end;
      { ��������� ������� ��������� ������� � ������ �������� � ��������� ������� }
      Result:=False;
      if HaveMemoryReserve then begin
        if (I < N) and (I > 0) and (TempCounts[I - 1] = CurrentCount) then begin
          Dec(I);
          repeat
            if TBoolVector(TempRowAllowed[I]).Dominates(RowAllowed) then begin
              TempRowsAllowed.Delete(I);
              TempCounts.Delete(I);
              TBoolVector(TempRowAllowed[I]).Free;
              TempRowAllowed.Delete(I);
            end
            else
              Inc(I);
          until (I = TempCounts.Count) or (TempCounts[I] <> CurrentCount);
        end;
        TempRowsAllowed.Insert(I, RowsAllowed);
        TempCounts.Insert(I, CurrentCount);
        TempBoolVector:=TBoolVector.Create(0, False);
        TempBoolVector.Assign(RowAllowed);
        TempRowAllowed.Insert(I, TempBoolVector);
      end
      else
        if I < N then begin
          TempRowsAllowed.Grow(-1);
          TempCounts.Grow(-1);
          TBoolVector(TempRowAllowed.Pop).Free;
        end;
    end;

  begin
    ColList:=TIntegerVector(RowCols[Level]);
    { ������������� ColList �� �������� ���������� ��� ���������� ����� -
      ��� ������ ��������� ������� �������� ����������� ������� }
    TempNumTrue.Count:=ColList.Count;
    for I:=0 to ColList.Count - 1 do begin
      K:=ColList[I];
      TempNumTrue[I]:=NumTrue[K];
    end;
    TempNumTrue.SortDescWith(ColList);
    for I:=0 to ColList.Count - 1 do begin
      K:=ColList[I];
      if NumTrue[K] = 0 then Break;
      Inc(CurrentCount);
      if (CurrentCount < MinCount) or FindMany and (CurrentCount = MinCount)
      then begin
        { ����� ����������� �������� � ������� K-� ������� }
        OldRowsAllowed:=RowsAllowed;
        { ���������, �� ������� �� �������, �������� ������ �����������
          (����������) ����� � ���������� ���������� ��� �������� }
        BackCount:=0;
        OldNumTrue:=TIntegerVector.Create(0, 0);
        try
          OldNumTrue.Assign(NumTrue);
          for J:=0 to NewMatrix.RowCount - 1 do
            if NewMatrix[J, K] and RowAllowed[J] then begin
              Dec(RowsAllowed);
              RowAllowed[J]:=False;
              for L:=0 to ColsAllowed - 1 do
                if NewMatrix[J, L] then NumTrue.DecItem(L, 1);
              BackIndexes.Add(J);
              Inc(BackCount);
            end;
          CurrentSolution[K]:=True;
          BackCounts.Add(BackCount);
          if RowsAllowed = 0 then begin { ������� ������� }
            MinCount:=CurrentCount;
            for J:=Solutions.Count - 1 downto 0 do begin
              T:=TIntegerVector(Solutions[J]);
              if T.Count > CurrentCount then begin
                T.Free;
                Solutions.Delete(J);
              end;
            end;
            if (SolutionCount <= 0) or (Solutions.Count < SolutionCount) then begin
              T:=TIntegerVector.Create(CurrentCount, 0);
              J:=0;
              for L:=0 to ColsAllowed - 1 do
                if CurrentSolution[L] then begin
                  T[J]:=L;
                  Inc(J);
                end;
              Solutions.Add(T);
            end;
          end
          else
            { ���� ���� ����� ���� �������, �� ���������, �� ������������ ��
              ������ ��������� ������� ������ ��������� ��������; ���� ���,
              �� ���������� ����� }
            if FindMany or not CurrentSolutionDominated then begin
              J:=Level;
              repeat
                Inc(J);
              until RowAllowed[J];
              DoCover(J);
            end;
          { ������� }
          NumTrue.Assign(OldNumTrue);
          BackCount:=BackCounts.Pop;
          for J:=BackIndexes.Count - BackCount to BackIndexes.Count - 1 do
            RowAllowed[BackIndexes[J]]:=True;
          BackIndexes.Grow(-BackCount);
          RowsAllowed:=OldRowsAllowed;
          CurrentSolution[K]:=False;
        finally
          OldNumTrue.Free;
        end;
      end;
      Dec(CurrentCount);
    end; {for}
  end;

begin
  if CoveringExists(Matrix) then begin
    M:=Matrix.RowCount;
    N:=Matrix.ColCount;
    RowAllowed:=TBoolVector.Create(M, True);
    ColAllowed:=TBoolVector.Create(N, True);
    CommonSolution:=TIntegerVector.Create(0, 0);
    try
      RowsAllowed:=M;
      ColsAllowed:=N;
      { ���������� �������, ������� �������� ������ � ��������:
      { �������, ������� �������� �������, ������������ � ����� ������ }
      for I:=0 to M - 1 do begin
        K:=SingleTrueInRow(I);
        if (K >= 0) and ColAllowed[K] then begin;
          for J:=0 to M - 1 do
            if Matrix[J, K] and RowAllowed[J] then begin
              Dec(RowsAllowed);
              RowAllowed[J]:=False;
            end;
          CommonSolution.Add(K);
          ColAllowed[K]:=False;
          Dec(ColsAllowed);
        end;
      end;
      if RowsAllowed > 0 then begin
        FindMany:=SolutionCount <> 1;
        NumTrue:=TIntegerVector.Create(0, 0);
        CurrentSolution:=TBoolVector.Create(ColsAllowed, False);
        TempRowsAllowed:=TIntegerVector.Create(0, 0);
        BackCounts:=TIntegerVector.Create(0, 0);
        BackIndexes:=TIntegerVector.Create(0, 0);
        TempRowAllowed:=TClassList.Create;
        NewColToCol:=TIntegerVector.Create(ColsAllowed, 0);
        NewMatrix:=nil;
        RowCols:=TClassList.Create;
        TempCounts:=TIntegerVector.Create(0, 0);
        TempNumTrue:=TIntegerVector.Create(0, 0);
        try
          if not FindMany then begin
            Matrix.GetColumnsNumTrue(NumTrue);
            { ��������� �������, ������� ������������ ������� ���������  }
            for I:=1 to N - 1 do begin
              if ColAllowed[I] then begin
                for J:=0 to I - 1 do begin
                  if (NumTrue[I] <= NumTrue[J]) and Column1Dominates2(J, I) then begin
                    ColAllowed[I]:=False;
                    Dec(ColsAllowed);
                    Break;
                  end
                  else
                    if ColAllowed[J] and
                      (NumTrue[J] <= NumTrue[I]) and Column1Dominates2(I, J)
                    then begin
                      ColAllowed[J]:=False;
                      Dec(ColsAllowed);
                      Break;
                    end;
                end; {for J}
              end;
            end; {for I}
          end;
          MatrixReduced:=(RowsAllowed < M) or (ColsAllowed < N);
          if MatrixReduced then begin
            NumTrue.Clear;
            NumTrue.Count:=ColsAllowed;
            { ������� ������� ������������ NewColToCol ����� ��������� ��������
              ������� Matrix � ������������� �������������� ������� NewMatrix,
              � ����� ������������� �������������� ������ ����� NewCounts }
            K:=0;
            for J:=0 to N - 1 do
              if ColAllowed[J] then begin
                NewColToCol[K]:=J;
                Inc(K);
              end;
            { ������ ������� NewMatrix }
            NewMatrix:=TBoolMatrix.Create(RowsAllowed, ColsAllowed, False);
            K:=0;
            for I:=0 to M - 1 do
              if RowAllowed[I] then begin
                for J:=0 to ColsAllowed - 1 do begin
                  B:=Matrix[I, NewColToCol[J]];
                  NewMatrix[K, J]:=B;
                  if B then NumTrue.IncItem(J, 1);
                end;
                Inc(K);
              end;
          end
          else begin
            if FindMany then Matrix.GetColumnsNumTrue(NumTrue);
            NewMatrix:=Matrix;
          end;
          { ������ ������ ��������, ����������� �������� ������ }
          RowCols.Count:=RowsAllowed;
          for I:=0 to RowsAllowed - 1 do begin
            ColList:=TIntegerVector.Create(0, 0);
            for J:=0 to ColsAllowed - 1 do
              if NewMatrix[I, J] then ColList.Add(J);
            ColList.Pack;
            RowCols[I]:=ColList;
          end;
          { ��� ������ ����� ������� ������� ��������� }
          RowAllowed.Count:=RowsAllowed;
          RowAllowed.FillValue(True);
          { ����������� �������� ������ }
          ColAllowed.Free;
          ColAllowed:=nil;
          { �������� }
          CurrentCount:=0;
          MinCount:=MaxInt;
          DoCover(0);
          if MatrixReduced then begin
            { ��������� ������� }
            for I:=0 to Solutions.Count - 1 do
              With TIntegerVector(Solutions[I]) do begin
                for J:=0 to Count - 1 do
                  Items[J]:=NewColToCol[Items[J]];
                ConcatenateWith(CommonSolution);
              end;
            end;
        finally
          NumTrue.Free;
          CurrentSolution.Free;
          TempRowsAllowed.Free;
          BackCounts.Free;
          BackIndexes.Free;
          TempCounts.Free;
          TempRowAllowed.FreeItems;
          TempRowAllowed.Free;
          NewColToCol.Free;
          if NewMatrix <> Matrix then NewMatrix.Free;
          RowCols.FreeItems;
          RowCols.Free;
          TempNumTrue.Free;
        end;
      end
      else begin
        Solutions.Add(CommonSolution);
        CommonSolution:=nil;
      end;
      Result:=Solutions.Count;
    finally
      RowAllowed.Free;
      ColAllowed.Free;
      CommonSolution.Free;
    end;
  end
  else
    Result:=0;
end;

function FindMinWeightCovering(Matrix: TBoolMatrix; Weights: TFloatVector;
  Solution: TGenericIntegerVector; var Weight: Float): Bool;
label
  Check3, NextJ, NextI;
var
  I, J, K, L, M, N, P, Q, R, S, U, MinCount, CurrentCount, RowsAllowed,
    ColsAllowed: Integer;
  CurrentWeight, MinWeight, T1, T2, T3: Float;
  B: Bool;
  RowAllowed, ColAllowed, OptimumSolution, CurrentSolution: TBoolVector;
  BackCounts, BackIndexes, TempIntVector, NewColToCol, ColList,
    NumTrue: TIntegerVector;
  TempWeights, NewWeights, NumTrueByWeights: TFloatVector;
  TempRowAllowed, RowCols: TClassList;
  NewMatrix: TBoolMatrix;

  function SingleTrueInRow(Row: Integer): Integer;
  { ���� � ������ Row ������� Matrix ������� ����� ���� �������� True, ��
    ������� ���������� ������ ����� ��������, ����� ������������ -1 }
  var
    J: Integer;
  begin
    Result:=-1;
    for J:=0 to N - 1 do
      if Matrix[Row, J] then begin
        if Result >= 0 then begin
          Result:=-1;
          Exit;
        end;
        Result:=J;
      end;
  end;

  procedure AddToOptimumSolution(J: Integer);
  var
    I: Integer;
  begin
    for I:=0 to M - 1 do
      if Matrix[I, J] and RowAllowed[I] then begin
        Dec(RowsAllowed);
        RowAllowed[I]:=False;
      end;
    OptimumSolution[J]:=True;
    Solution.Add(J);
    Weight:=Weight + Weights[J];
    ColAllowed[J]:=False;
    Dec(ColsAllowed);
  end;

  function Column1Dominates2(Column1, Column2: Integer): Bool;
  var
    I: Integer;
  begin
    for I:=0 to M - 1 do
      if Matrix[I, Column2] and not Matrix[I, Column1] then begin
        Result:=False;
        Exit;
      end;
    Result:=True;
  end;

  procedure DoCover(Level: Integer);
  var
    I, J, K, L, OldRowsAllowed, BackCount: Integer;
    NewWeight: Float;
    ColList, OldNumTrue: TIntegerVector;

    function CurrentSolutionDominated: Bool;
    { ���������, �� ������������ �� ������� ��������� ������� ����� ���������
      ��������� �������� (���� ��������� ������� ������������ ������, ���� ���
      ������� �� ������ ���� �������, � ��� ������, �������� ������, �������
      ������, �.�. ������ ������� "�����" �������) }
    var
      I, N: Integer;
      TempBoolVector: TBoolVector;
    begin
      I:=0;
      N:=TempWeights.Count;
      while (I < N) and (TempWeights[I] <= CurrentWeight) do begin
        { ��������� RowAllowed.Dominates(...), � �� ��������, ��������� ������
          �� �������� ������, �, ��������, ����������� ������ }
        if (RowsAllowed >= TempIntVector[I]) and
          RowAllowed.Dominates(TBoolVector(TempRowAllowed[I]))
        then begin
          Result:=True;
          Exit;
        end;
        Inc(I);
      end;
      { ��������� ������� ��������� ������� � ������ ����� � ��������� ������� }
      Result:=False;
      if HaveMemoryReserve then begin
        if (I < N) and (I > 0) and (TempWeights[I - 1] = CurrentWeight) then begin
          Dec(I);
          repeat
            if TBoolVector(TempRowAllowed[I]).Dominates(RowAllowed) then begin
              TempIntVector.Delete(I);
              TempWeights.Delete(I);
              TBoolVector(TempRowAllowed[I]).Free;
              TempRowAllowed.Delete(I);
            end
            else
              Inc(I);
          until (I = TempWeights.Count) or (TempWeights[I] <> CurrentWeight);
        end;
        TempIntVector.Insert(I, RowsAllowed);
        TempWeights.Insert(I, CurrentWeight);
        TempBoolVector:=TBoolVector.Create(0, False);
        TempBoolVector.Assign(RowAllowed);
        TempRowAllowed.Insert(I, TempBoolVector);
      end
      else
        if I < N then begin
          TempIntVector.Grow(-1);
          TempWeights.Grow(-1);
          TBoolVector(TempRowAllowed.Pop).Free;
        end;
    end;

  begin
    ColList:=TIntegerVector(RowCols[Level]);
    { ������������� ColList �� �������� ��������� <���������� �����������> /
      <���> - ��� ������ ��������� ������� �������� ����������� ������� }
    NumTrueByWeights.Count:=ColList.Count;
    for I:=0 to ColList.Count - 1 do begin
      K:=ColList[I];
      NumTrueByWeights[I]:=NumTrue[K] / NewWeights[K];
    end;
    NumTrueByWeights.SortDescWith(ColList);
    for I:=0 to ColList.Count - 1 do begin
      K:=ColList[I];
      if NumTrue[K] = 0 then Break;
      NewWeight:=CurrentWeight + NewWeights[K];
      if (NewWeight < MinWeight) or
        (NewWeight = MinWeight) and (CurrentCount + 1 < MinCount)
      then begin
        { ����� ����������� �������� � ������� K-� ������� }
        OldRowsAllowed:=RowsAllowed;
        { ���������, �� ������� �� �������, �������� ������ �����������
          (����������) ����� � ���������� ���������� ��� �������� }
        BackCount:=0;
        OldNumTrue:=TIntegerVector.Create(0, 0);
        try
          OldNumTrue.Assign(NumTrue);
          for J:=0 to NewMatrix.RowCount - 1 do
            if NewMatrix[J, K] and RowAllowed[J] then begin
              Dec(RowsAllowed);
              RowAllowed[J]:=False;
              for L:=0 to ColsAllowed - 1 do
                if NewMatrix[J, L] then NumTrue.DecItem(L, 1);
              BackIndexes.Add(J);
              Inc(BackCount);
            end;
          Inc(CurrentCount);
          CurrentSolution[K]:=True;
          CurrentWeight:=NewWeight;
          BackCounts.Add(BackCount);
          if RowsAllowed = 0 then begin { ������� ������� }
            MinWeight:=CurrentWeight;
            MinCount:=CurrentCount;
            OptimumSolution.Assign(CurrentSolution);
          end
          else
            { ���������, �� ������������ �� ������ ��������� ������� ������
              ��������� ��������; ���� ���, �� ���������� ����� }
            if not CurrentSolutionDominated then begin
              J:=Level;
              repeat
                Inc(J);
              until RowAllowed[J];
              DoCover(J);
            end;
          { ������� }
          NumTrue.Assign(OldNumTrue);
          BackCount:=BackCounts.Pop;
          for J:=BackIndexes.Count - BackCount to BackIndexes.Count - 1 do
            RowAllowed[BackIndexes[J]]:=True;
          BackIndexes.Grow(-BackCount);
          RowsAllowed:=OldRowsAllowed;
          CurrentWeight:=CurrentWeight - NewWeights[K];
          CurrentSolution[K]:=False;
          Dec(CurrentCount);
        finally
          OldNumTrue.Free;
        end;
      end;
    end;
  end;

begin
  {$IFDEF CHECK_MATH}
  if Matrix.ColCount <> Weights.Count then MathError(SErrorInParameters, [0]);
  {$ENDIF}
  Result:=CoveringExists(Matrix);
  if Result then begin
    Solution.Clear;
    M:=Matrix.RowCount;
    N:=Matrix.ColCount;
    RowAllowed:=TBoolVector.Create(M, True);
    OptimumSolution:=TBoolVector.Create(N, False);
    ColAllowed:=TBoolVector.Create(N, True);
    NumTrue:=TIntegerVector.Create(0, 0);
    try
      RowsAllowed:=M;
      ColsAllowed:=N;
      Weight:=0;
      { ���������� �������, ������� �������� ������ � ��������:
        1. ������� �������������� ���� }
      for J:=0 to N - 1 do
        if Weights[J] < 0 then AddToOptimumSolution(J);
      { 2. �������, ������� �������� �������, ������������ � ����� ������ }
      for I:=0 to M - 1 do begin
        K:=SingleTrueInRow(I);
        if (K >= 0) and not OptimumSolution[K] then AddToOptimumSolution(K);
      end;
      { ��������� ������� ���������������� ����, ��������� ������ �� ����� }
      Matrix.GetColumnsNumTrue(NumTrue);
      for J:=0 to N - 1 do begin
        if ColAllowed[J] and (NumTrue[J] = 0) and (Weights[J] >= 0) then begin
          ColAllowed[J]:=False;
          Dec(ColsAllowed);
        end;
      end;
      if RowsAllowed > 0 then begin
        CurrentSolution:=TBoolVector.Create(ColsAllowed, False);
        TempIntVector:=TIntegerVector.Create(N, 0);
        BackCounts:=TIntegerVector.Create(0, 0);
        BackIndexes:=TIntegerVector.Create(0, 0);
        TempWeights:=TFloatVector.Create(0, 0);
        TempRowAllowed:=TClassList.Create;
        NewColToCol:=TIntegerVector.Create(ColsAllowed, 0);
        NewWeights:=TFloatVector.Create(ColsAllowed, 0);
        NewMatrix:=TBoolMatrix.Create(RowsAllowed, ColsAllowed, False);
        RowCols:=TClassList.Create;
        NumTrueByWeights:=TFloatVector.Create(0, 0);
        try
          { ��������� �������, ������� ������������ ���������� ������ ��������,
            �.�. ��������� ������� Ci, ��� ������� ���������� ����� ������� Cjk
            � ������� ���� ������ ��������� �����, ��� ���� ������� ������� Ci,
            ����������� �� ��������� ������, ����� �������, �� ��� ������� �
            ����� �� �������� Cjk �������� �������, ����������� � ��� �� ������
            � ����� ������ ������� }
          TempWeights.Assign(Weights);
          TempIntVector.ArithmeticProgression(0, 1);
          TempWeights.SortWith(TempIntVector);
          TempWeights.Clear;
          for I:=1 to N - 1 do begin
            K:=TempIntVector[I];
            if ColAllowed[K] then begin
              T1:=Weights[K];
              { �������������� �������������� �����, ����� ��� ����� ��������� }
              for J:=0 to I - 1 do begin
                L:=TempIntVector[J];
                if (NumTrue[K] <= NumTrue[L]) and Column1Dominates2(L, K) then begin
                  ColAllowed[K]:=False;
                  Dec(ColsAllowed);
                  Break;
                end
                else
                  { ���� ���� �����, �� ��������� ������������� "��������" }
                  if (T1 = Weights[L]) and ColAllowed[L] and
                    (NumTrue[L] <= NumTrue[K]) and Column1Dominates2(K, L)
                  then begin
                    ColAllowed[L]:=False;
                    Dec(ColsAllowed);
                    Break;
                  end;
                T2:=Weights[L];
                for Q:=0 to J - 1 do begin
                  R:=TempIntVector[Q];
                  T3:=T2 + Weights[R];
                  if T3 <= T1 then begin
                    for P:=0 to M - 1 do
                      if Matrix[P, K] and not (Matrix[P, R] or Matrix[P, L]) then
                        goto Check3;
                    ColAllowed[K]:=False;
                    Dec(ColsAllowed);
                    goto NextI;
                  Check3:
                    for S:=0 to Q - 1 do begin
                      U:=TempIntVector[S];
                      if T3 + Weights[U] <= T1 then begin
                        for P:=0 to M - 1 do
                          if Matrix[P, K] and
                            not (Matrix[P, U] or Matrix[P, R] or Matrix[P, L]) then
                              goto NextJ;
                        ColAllowed[K]:=False;
                        Dec(ColsAllowed);
                        goto NextI;
                      end;
                    end; {for S}
                  end;
                end; {for Q}
            NextJ:
              end; {for J}
            end;
        NextI:
          end; {for I}
          { ������� ������� ������������ NewColToCol ����� ��������� ��������
            ������� Matrix � ������������� �������������� ������� NewMatrix,
            � ����� ������������� �������������� ������ ����� NewWeights }
          K:=0;
          for J:=0 to N - 1 do begin
            L:=TempIntVector[J];
            if ColAllowed[L] then begin
              NewColToCol[K]:=L;
              NewWeights[K]:=Weights[L];
              Inc(K);
            end;
          end;
          { ������ ������� NewMatrix }
          RowCols.Count:=RowsAllowed;
          NumTrue.Clear;
          NumTrue.Count:=ColsAllowed;
          K:=0;
          for I:=0 to M - 1 do
            if RowAllowed[I] then begin
              ColList:=TIntegerVector.Create(0, 0);
              for J:=0 to ColsAllowed - 1 do begin
                B:=Matrix[I, NewColToCol[J]];
                NewMatrix[K, J]:=B;
                if B then begin
                  ColList.Add(J);
                  NumTrue.IncItem(J, 1);
                end;
              end;
              RowCols[K]:=ColList;
              Inc(K);
            end;
          { ��� ������ ����� ������� ������� ��������� }
          RowAllowed.Count:=RowsAllowed;
          RowAllowed.FillValue(True);
          { ����������� �������� ������ }
          ColAllowed.Free;
          ColAllowed:=nil;
          TempIntVector.Clear;
          { �������� }
          CurrentWeight:=0;
          MinWeight:=MaxFloat;
          DoCover(0);
          { ��������� ������� }
          for J:=0 to ColsAllowed - 1 do
            if OptimumSolution[J] then begin
              K:=NewColToCol[J];
              Solution.Add(K);
              Weight:=Weight + Weights[K];
            end;
        finally
          CurrentSolution.Free;
          TempIntVector.Free;
          BackCounts.Free;
          BackIndexes.Free;
          TempWeights.Free;
          TempRowAllowed.FreeItems;
          TempRowAllowed.Free;
          NewColToCol.Free;
          NewWeights.Free;
          NewMatrix.Free;
          RowCols.FreeItems;
          RowCols.Free;
          NumTrueByWeights.Free;
        end;
      end;
    finally
      RowAllowed.Free;
      OptimumSolution.Free;
      ColAllowed.Free;
      NumTrue.Free;
    end;
  end;
end;

end.
