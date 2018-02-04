unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls;

Type TDadosGPS = Record
  data_hora:TDateTime;
  Latitude:Double;
  Longitude:Double;
  Altitude:Double;
  AltitudeBaro:Double;
  VelocidadeKMH:Double;
  Direcao:SmallInt;
end;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    btGerar: TButton;
    LabeledEditIGCFileName: TLabeledEdit;
    Memo: TMemo;
    OpenDialog: TOpenDialog;
    procedure btGerarClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    function B_IGCtoGPS( sRegistro:String ):TDadosGPS;
  public

  end;

var
  Form1: TForm1;
  valorSubida:double;

implementation



{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  if ( OpenDialog.Execute ) then
  begin
    LabeledEditIGCFileName.Text := OpenDialog.FileName;
  end;
end;

procedure TForm1.btGerarClick(Sender: TObject);
var
  arquivoIGC: TextFile;
  linhaLida:String;
  iQuantProcess:integer;
  dados, dadosAnteriores:TDadosGPS;
  sNomeArquivoCUP:String;
begin

  try
    valorSubida := 0;
  except
     //Focus no edit da subida caso não consiga converter
  end;
  linhaLida := '';

  //gera nome do arquivo .cup
  sNomeArquivoCUP := ExtractFileName( LabeledEditIGCFileName.Text );
  sNomeArquivoCUP := ChangeFileExt( LabeledEditIGCFileName.Text, '.cup');
  sNomeArquivoCUP := ExtractFilePath( LabeledEditIGCFileName.Text ) + sNomeArquivoCUP;

  Memo.clear(); //Limpa detalhes
  Memo.Lines.Add('.CUP de saída: ' +   sNomeArquivoCUP );
  Memo.Lines.Add('Abrindo arquivo IGC');

  AssignFile( arquivoIGC, LabeledEditIGCFileName.Text ); //Abre arquivo
  Reset(arquivoIGC); //Inicia arquivo para leitura

  Memo.Lines.Add('');
  Memo.Lines.Add('Cabeçalho >>>>>');
  //Passa pelo cabeçalho do arquivo até encontrar um registro 'B'
  while (( not Eof( arquivoIGC )) and ( copy( linhaLida, 1, 1) <> 'B' )) do
  begin
    readln( arquivoIGC, linhaLida ); //ler linha do arquivo e coloca na variável "linhaLida"
    Memo.Lines.Add( linhaLida );
  end;
  Memo.Lines.Add('>>>>> Cabeçalho');
  Memo.Lines.Add('');

  //Despreza o primeiro minuto de voo ou (60 registros)
  iQuantProcess := 0;
  Memo.Lines.Add('Inicinado calculos');
  while (not Eof( arquivoIGC ) and ( iQuantProcess < 60 )) do
  begin
    readln( arquivoIGC, linhaLida ); //ler linha do arquivo
    dadosAnteriores := B_IGCtoGPS( linhaLida );
    inc(iQuantProcess);
  end;

  //Processa dados
  while not Eof( arquivoIGC ) do
  begin
    readln( arquivoIGC, linhaLida );
    dados := B_IGCtoGPS( linhaLida );

    if ( dados.Altitude - dadosAnteriores.Altitude >= valorSubida ) then
    begin
      Memo.Lines.Add('out2');
    end;

    inc(iQuantProcess);
    dadosAnteriores := dados;
  end;
  CloseFile( arquivoIGC );
  Memo.Lines.Add('Registros processados: ' + IntToStr( iQuantProcess ) );

end;

function TForm1.B_IGCtoGPS( sRegistro:String ):TDadosGPS;
var
  wHora, wMinuto, wSegundo:Word;
begin
  //  HHMMSS LAT      LON         P.Alt G Alt
  //1 234567 89012345 678901234 5 67890 12345 678901
  //B 140744 1530725S 04717555W A 00934 01016 000116
  //B 093512 1754410S 05144756W A 00710 00710 004003000131077

  if Copy( sRegistro, 1, 1 ) <> 'B' then exit;

  //Hora
  wHora := StrToInt( Copy( sRegistro, 2, 2 ) );
  wMinuto := StrToInt( Copy( sRegistro, 4, 2 ) );
  wSegundo := StrToInt( Copy( sRegistro, 6, 2 ) );

  result.data_hora := EncodeTime( wHora, wMinuto, wSegundo, 0 );

  //Latitude
  result.Latitude := StrToInt( Copy( sRegistro, 8, 2 ) );
  result.Latitude := result.Latitude + ( ( StrToInt( Copy( sRegistro, 10, 5 ) ) / 1000 ) / 60 );
  if Copy( sRegistro, 15, 1 ) = 'S' then
    result.Latitude := result.Latitude * (-1);

  //Longitude
  result.Longitude := StrToInt( Copy( sRegistro, 16, 3 ) );
  result.Longitude := result.Longitude + ( ( StrToInt( Copy( sRegistro, 19, 5 ) ) / 1000 ) / 60 );
  if Copy( sRegistro, 24, 1 ) = 'W' then
    result.Longitude := result.Longitude * (-1);

  //Altitude
  result.Altitude := StrToInt( Copy( sRegistro, 26, 5 ) );

  //Altitude
  if ( result.Altitude = 0 ) then
    result.Altitude := StrToInt( Copy( sRegistro, 31, 5 ) );

end;

end.

