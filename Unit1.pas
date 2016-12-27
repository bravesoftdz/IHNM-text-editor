unit Unit1;
{$optimization off}
{$H+}
interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    __RusMemo: TMemo;
    _Part: TScrollBar;
    Memo2: TMemo;
    _OriginalText: TScrollBar;
    SaveBtn: TButton;
    _TextPart: TLabel;
    _1: TLabel;
    btn1: TButton;
    procedure FormActivate(Sender: TObject);
    procedure _PartChange(Sender: TObject);
    procedure SaveBtnClick(Sender: TObject);
    procedure _OriginalTextChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
buf   : PByteArray; // �������� ����� ������������� ����� scripts.res
BlockA_offset : array of LongInt; // ������� �� 16 ��������, ���� scripts.res ������� �� 16 ������.
BlockA_size : array of longint;  // ������� �������� 16 �������� ����� scripts.res
Strings : array of AnsiString;  // ������ ����� �� scripts.res, ������ ���������� � ������ ������
LinesTotal : LongInt; // ���������� ����� ������ � ������ �����
GlobalBlocksCount : LongInt;
GlobalFileSize:longint; // ������ buf

implementation

{$R *.dfm}

procedure TForm1.FormActivate(Sender: TObject);
var
fin:file of Byte;
i,j, offset1, offset2, BlockSize:LongInt;

begin
// ������ � buf ����
FileMode := fmShareDenyNone; // ����� ������� ��������� ������
AssignFile(fin, '.\out\scripts.res');
Reset(fin);
GlobalFileSize := FileSize(fin); // GlobalFileSize - ������ ����� ����� scripts.res
GetMem(Buf, GlobalFileSize); // �������� ������ �������
Blockread(fin, Buf[0], GlobalFileSize);  // ������ ���� ���� ����
CloseFile (fin);

// �������� ���� ������� ������ � ����� scripts.res = 16
GlobalBlocksCount:=buf[GlobalFileSize - 4] + 256*buf[GlobalFileSize - 3] + 256*256*buf[GlobalFileSize - 2] + 256*256*256*buf[GlobalFileSize - 1];

SetLength (BlockA_offset, GlobalBlocksCount);
SetLength (BlockA_size, GlobalBlocksCount);

_Part.Max:=GlobalBlocksCount;
_Part.Min:=1;

// �������� �� ������� �������� � ��������
offset1:=buf[GlobalFileSize - 8] + 256*buf[GlobalFileSize - 7] + 256*256*buf[GlobalFileSize - 6] + 256*256*256*buf[GlobalFileSize - 5];
//Memo2.Lines.Add(IntToStr(offset1) + ' offset to 1st resource');

//offset2:=buf[offset1 - 8] + 256*buf[offset1 - 7] + 256*256*buf[offset1 - 6] + 256*256*256*buf[offset1 - 5];
// ��������� ������� �������� � ��������
for i:=0 to (GlobalBlocksCount - 1) do
 begin
  BlockA_offset[i]:=buf[offset1 + 0 + i*8] + 256*buf[offset1 + 1 + i*8] + 256*256*buf[offset1 + 2 + i*8] + 256*256*256*buf[offset1 + 3 + i*8];
  BlockA_Size[i]:=  buf[offset1 + 4 + i*8] + 256*buf[offset1 + 5 + i*8] + 256*256*buf[offset1 + 6 + i*8] + 256*256*256*buf[offset1 + 7 + i*8];
 end;

end;

procedure TForm1._PartChange(Sender: TObject);
var i, j, NumBlock, BlockOffset, CurOffset, CurOffset2, TextStart:LongInt;
curbyte : Byte;
tempText, tmpStr1:string;
f : TextFile;
begin
__RusMemo.Clear;
Memo2.Clear;
_originaltext.position := 0;
SaveBtn.Enabled:=false;
// �������� ����� ���� ����������
if ( Trunc(_Part.Position/2) <> (_Part.Position/2)  ) then Exit;
SaveBtn.Enabled:=True;

//����� ����� �����
NumBlock := _Part.Position - 1;
BlockOffset := BlockA_offset[NumBlock]; // ������ �����
CurOffset:=buf[BlockOffset + 0] + 256 * (buf[BlockOffset + 1]);
LinesTotal:= Trunc (CurOffset / 2);

//if NumBlock=15 then LinesTotal:=110;
//Memo2.Lines.Add(IntToStr(LinesTotal) + ' ' + IntToStr(buf[BlockOffset]) + ' ' + IntToStr(buf[BlockOffset + 1]) );

SetLength (strings, LinesTotal);
_OriginalText.Max := LinesTotal - 1;
_OriginalText.min := 0;

//AssignFile (f, 'offsets.txt');
//Rewrite (f);
for i:=0 to (LinesTotal - 1) do
 begin
   CurOffset:=buf[BlockOffset + i*2] + 256 * ( buf[BlockOffset + i*2 + 1]);
   TextStart:=BlockOffset + CurOffset;
   tempText:='';
   j:=0;

   repeat
     curbyte := buf[textstart + j];
     tempText:=tempText + chr(curbyte);
     inc (j);
   until (curbyte=0);

  // Writeln (f, inttostr (CurOffset) + ' - ' + temptext);
   Strings[i]:=tempText;
 end;
 //CloseFile (f);
 // ���������
//Strings[632] := strings [632];

 // ������� ���� �������� �����������
 CurOffset:=(LinesTotal) * 2; // �������� �� ������� ������������ �����������

_OriginalTextChange(Sender);
end;


// ����� �������� ����� �����
// � ������� textoffsets[i] �������� ������ ������
procedure TForm1.SaveBtnClick(Sender: TObject);
var
i,j, Gi, k, TextBlockSize, OffsetBlocksSize, TranslateBlockSize, off, off2, numblock, NewSize:longint;
text2translate, curText:string;
outcode, tmpstr:string;
buf2, buf3 : PByteArray;
f: file of byte;
LO_BYTE, HI_BYTE, byte0, byte1, byte2, byte3 : Byte;
FILE_FINALE : file of Byte;
//i:Integer;
TranslateFile : TextFile;
UTF8str1 : UTF8String;
Ansistr1 : AnsiString;
FileNum, delta, nullStrCount : Integer;
ftxt : TextFile;
begin
SaveBtn.Enabled:=false;

if ( trunc (_Part.Position/2) <> (_Part.Position/2)  ) then Exit;

SaveBtn.Enabled:=True;
// ������ ���� �������� �� \rus_text
//== ������ ���� �������� � �������� ��� � ������ Strings[LinesTotal-1] �� 0
FileNum := Trunc(_Part.Position / 2);
AssignFile (TranslateFile, '.\rus_text\�����_' + IntToStr(FileNum) + '.txt');
Reset(TranslateFile);
__RusMemo.Lines.Clear;

// ����� 1-632
// Strings[0] := strings[0];
//AssignFile (ftxt, '_' + IntToStr(_Part.Position) + '_log.txt');
//Rewrite (ftxt);

for Gi := 0 to (LinesTotal - 1) do
 begin
  tmpstr := Strings[Gi];
  //Writeln (ftxt, tmpstr);
 end;
//CloseFile (ftxt);

delta:=0;
if FileNum=8 then delta:=2;

for Gi := delta to (LinesTotal - 1) do
 begin
  //if ( (Gi>315) and (_Part.Position=15)) then Break;

  tmpstr := Strings[Gi];
  if ( (tmpstr=#0) or (tmpstr=' ' + #0) ) then
    begin
     //inc (LinesTotal);
     continue; // ���������� ������ ������ � ���������
    end;


  // ������ ������� �� .\rus_text
  Readln (TranslateFile, UTF8str1);
  while (UTF8str1='') do
   Readln (TranslateFile, UTF8str1);

  Ansistr1 := Utf8ToAnsi(UTF8str1);
  text2translate:=Ansistr1;

  // ������� �� �������� ������ ��� ���� 13, ��������� ��� 10, ������� �����
  // Trim ������ � ������ � ����� ������� � �����������
  text2translate:=trim (StringReplace(text2translate, #13, '', [rfReplaceAll]));
  if text2translate[1]='?' then Delete (text2translate, 1, 1);
  text2translate:=text2translate + #0;

  Strings[Gi] := text2translate; //  ������� ������� � ����� �������� �����
  if (FileNum = 8) then
   //Strings[1] := '��������. ������� ��������, ��� � ��� ��������. �� ��� ����� 623 ��������� �� ���� �� ������������ ������. ���� ����� ��������ӻ ������� �� ������ �� ���������, ��� �� ������� � ����������� ���� ��� ���������, ��� � � ��� ���������. ��������. ��������.' + #0;
   //Strings[1] := 'lurkmore.to/���������' + #0;
  end;
// Strings[632] := strings[632];
 CloseFile (TranslateFile);

// ��������� ����� ������ ������ �����
// � strings[i] ���������� ������������ ����� � ����� �� �����
TextBlockSize:=0;
nullStrCount := 0;
for i:=0 to (LinesTotal - 1) do
 begin
  TextBlockSize := TextBlockSize + Length(Strings[i]);
  if (strings[i]=#0) then inc (nullStrCount);
 end;

// ������ ����� ��������
OffsetBlocksSize:=(LinesTotal) * 2;
{
if (_Part.Position=16) then
      OffsetBlocksSize:=(LinesTotal + 1) * 2;
}
// ����� ������ �����
TranslateBlockSize := OffsetBlocksSize + TextBlockSize;

// ������� ����� ����� ��� ���� � ���������
GetMem(Buf2, TranslateBlockSize); // �������� ������ ������, �� ������ ������ ������
for i:=0 to (TranslateBlockSize - 1) do
 buf2[i]:=0;

// ��������� buf2
 off:=OffsetBlocksSize;
 delta := 0;
 if _Part.Position=16 then delta:=-2;
// ������ ������� �������� �������
 for j := 0 to (LinesTotal - 1) do
  begin
   HI_BYTE := Trunc( off /256);
   LO_BYTE := off - HI_BYTE * 256;
   buf2[j*2 + 0] := LO_BYTE;
   buf2[j*2 + 1] := HI_BYTE;
   off:=off + Length(Strings[j]);
  end;
  {
   inc (j);
   HI_BYTE := Trunc( off /256);
   LO_BYTE := off - HI_BYTE * 256;
   buf2[j*2 + 0] := LO_BYTE;
   buf2[j*2 + 1] := HI_BYTE;
   }
// �� buf2[sizeoffsetblocks] �� TranslateBlockSize
// ��������� �� strings �������
  i := OffsetBlocksSize;
  for j := 0 to (LinesTotal - 1) do
   begin
    tmpstr := strings[j];
    if tmpstr=#0 then
     begin
      //Dec (i);
      //Continue;
     end;

    for k:=0 to (Length(tmpstr) - 1) do
     buf2[i + k] := Ord(tmpstr[k + 1]);

    inc (i, Length(tmpstr));
   end;
// ��� ���� �����, buf2, ������ TotalBlockSize
// ����� ������, ���������� �������� (����� 2, 4, 6 ... 16) � ����� ���� ����.
// buf   : PByteArray; // �������� ���� ������������ ���� scripts.res
// TextOffsets : array of LongInt; // ������� �������� ������
// ��������� �� �� Trunc(ScrollBar1.Position/2) �����

{  // �������� ����� ������ buf2
   assignfile (f, 'buf16.block');
   Rewrite (f);
   BlockWrite(f, Buf2[0], TranslateBlockSize);  // ������ ���� ���� ����
   CloseFile (f);
   Exit;
}

  // ����� ������
  // numblock �� 0 �� 15
   NumBlock:= _Part.Position - 1;

   // ������ ���������� ����� - TextOffsets[numblock]
   // ���� ������ ����� ������, ����� ������� ���������� ����, ������� �������� ������
   // ������� ���� ����� ��������� ���������
   // BlockA_offset : array of LongInt; // ������� �������� ������ 0 - 15
   // ����� buf2 ������ TotalBlockSize
   // ������ ����� ����� GlobalFileSize

   // ��������� ������ ������ �� ������ ������ ������������� �����
   // ��������� ������ numblock �����
   BlockA_size[numblock]:=TranslateBlockSize;

   // ������������ �������� ��������� ������ � ������ ����� �����
   NewSize := 0;
   for i := 0 to (GlobalBlocksCount -1 ) do
    NewSize := NewSize + BlockA_size[i];

   NewSize := NewSize + GlobalBlocksCount*8 + 8;
   GetMem(Buf3, NewSize); // �������� ������ ������

   off:=BlockA_offset[numblock];
   // ��������  ������ � ����� ����
   for i:=0 to (off - 1) do
    buf3[i]:=buf[i];

   // �������� �������� ��� ����� ���� ��� ��������� ����
   for i:=0 to (TranslateBlockSize - 1) do
    buf3[off + i] := buf2[i];

   // ���� ��� �� ��������� ����, �� �������� �������� ����
   if ( (numblock+1) <> GlobalBlocksCount ) then
     begin
       off := BlockA_offset[numblock] + TranslateBlockSize;
       //NewSize:=globalfilesize - BlockA_offset[numblock + 2];
       for i:=(blockA_offset[numblock + 1]) to (globalFileSize - GlobalBlocksCount*8 - 8) do
        begin
         buf3[off]:=buf[i];
         Inc (off);
        end;
     end;

   // ������� �������� ����, ������������� ������� ��������
   for i:=(numblock + 1) to (GlobalBlocksCount - 1) do
    BlockA_offset[i]:=BlockA_offset[i-1] + BlockA_size[i-1];

    // ���������� ����� ������� �������� ������ � �������� ������ � ����� ����� scripts.res
    // byte0-3 - ������ �������� � �������� ��������� � ����� ����� scripts.res
    i:=0;
    j:=0;
    off2:=NewSize - GlobalBlocksCount*8 - 8;
    while (i < (GlobalBlocksCount*8)) do
     begin
      off:=blockA_offset[j];
      //����� �������� �����
      BYTE3:=Trunc(off/(256*256*256));
      BYTE2:=Trunc ((off - BYTE3 *256*256*256)/(256*256));
      BYTE1:=Trunc ((off - BYTE2*256*256 - BYTE3*256*256*256)/(256));
      BYTE0:=off - BYTE1*256 - BYTE2*256*256 - BYTE3*256*256*256;

      buf3[off2 + i + 0]:=byte0;
      buf3[off2 + i + 1]:=byte1;
      buf3[off2 + i + 2]:=byte2;
      buf3[off2 + i + 3]:=byte3;

      // ����� ������ �����
      off:=blockA_size[j];

      // ����� �������� �����
      BYTE3:=Trunc(off/(256*256*256));
      BYTE2:=Trunc ((off - BYTE3 *256*256*256)/(256*256));
      BYTE1:=Trunc ((off - BYTE2*256*256 - BYTE3*256*256*256)/(256));
      BYTE0:=off - BYTE1*256 - BYTE2*256*256 - BYTE3*256*256*256;

      buf3[off2 + i + 4]:=byte0;
      buf3[off2 + i + 5]:=byte1;
      buf3[off2 + i + 6]:=byte2;
      buf3[off2 + i + 7]:=byte3;

      inc (i, 8);
      inc (j);
     end;

     // ����� ��������� 4 * 2 ����, �������� � ���������� ������
      off:=off2;
     // ����� �������� �����
      BYTE3:=Trunc(off/(256*256*256));
      BYTE2:=Trunc ((off - BYTE3 *256*256*256)/(256*256));
      BYTE1:=Trunc ((off - BYTE2*256*256 - BYTE3*256*256*256)/(256));
      BYTE0:=off - BYTE1*256 - BYTE2*256*256 - BYTE3*256*256*256;

      buf3[NewSize - 8 + 0]:=byte0;
      buf3[NewSize - 8 + 1]:=byte1;
      buf3[NewSize - 8 + 2]:=byte2;
      buf3[NewSize - 8 + 3]:=byte3;

      off:=GlobalBlocksCount;
      BYTE3:=Trunc(off/(256*256*256));
      BYTE2:=Trunc ((off - BYTE3 *256*256*256)/(256*256));
      BYTE1:=Trunc ((off - BYTE2*256*256 - BYTE3*256*256*256)/(256));
      BYTE0:=off - BYTE1*256 - BYTE2*256*256 - BYTE3*256*256*256;

      buf3[NewSize - 4 + 0]:=byte0;
      buf3[NewSize - 4 + 1]:=byte1;
      buf3[NewSize - 4 + 2]:=byte2;
      buf3[NewSize - 4 + 3]:=byte3;

   assignfile (f, '.\out\scripts.res');
   Rewrite (f);
   BlockWrite(f, Buf3[0], NewSize);  // ������ ���� ���� ����
   CloseFile (f);
   //FreeMem (buf3);
   //Freemem (buf2);
form1.__RusMemo.Lines.Add('done');
FormActivate(sender);
end;

procedure TForm1._OriginalTextChange(Sender: TObject);
begin
_1.Caption := IntToStr(_OriginalText.Position);
// �������� ����� ���� ����������
 if ( Trunc(_Part.Position / 2) <> (_Part.Position / 2)  ) then Exit;
 __RusMemo.Clear;
 Memo2.Clear;
 Memo2.Lines.Add(strings[_OriginalText.position]);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 FreeMem(Buf); // ����������, ������� � ����.
end;

procedure TForm1.btn1Click(Sender: TObject);
var
  i:Integer;
begin
 for i := 1 to 16 do
  begin
    _Part.Position := i;
    SaveBtnClick(Sender);
  end;
end;

end.
