unit Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  System.ImageList, Vcl.ImgList;

type
  TFrmMain = class(TForm)
    btnLogin: TButton;
    ListView1: TListView;
    ImageList1: TImageList;
    procedure btnLoginClick(Sender: TObject);
    procedure ListView1SelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure ListView1Deletion(Sender: TObject; Item: TListItem);
    procedure ListView1DblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

uses IdHTTP, StrUtils, MSHTML, Winapi.ActiveX, ShellApi;

function RefString(const S: string): Pointer;
var
  Local: string;
begin
  Local := S;
  Result := Pointer(Local);
  Pointer(Local) := nil;
end;

procedure ReleaseString(P: Pointer);
var
  Local: string;
begin
  Pointer(Local) := P;
end;

function DoLogin(const username, password: string): string;
var
  IdHTTP: TIdHTTP;
  Request: TStringList;
begin
  try
    Request := TStringList.Create;
    try
      Request.Add('action=do_login');
      Request.Add('url=http://www.delphican.com/index.php');
      Request.Add('quick_login=1');
      Request.Add('quick_username='+username);
      Request.Add('quick_password='+password);
      Request.Add('quick_remember=yes');
      Request.Add('submit=Giriş Yap');
      IdHTTP := TIdHTTP.Create;
      try
        IdHTTP.AllowCookies := True;
        IdHTTP.HandleRedirects := True;
        IdHTTP.Request.ContentType := 'application/x-www-form-urlencoded';
        IdHTTP.Post('http://www.delphican.com/member.php', Request);
        Result := IdHTTP.Get('http://www.delphican.com');
        if ContainsStr(Result, 'quick_login') then //Login başarısız demektir
          Result := '';
      finally
        IdHTTP.Free;
      end;
    finally
      Request.Free;
    end;
  except
    Result := '';
  end;
end;

procedure TFrmMain.btnLoginClick(Sender: TObject);
var
  doc: OleVariant;
  satir, satirlar, kolonlar: OleVariant;
  i,j: Integer;
  sonuc_html, icerik: string;
  ilk_satir: Boolean;
  aItem: TListItem;
begin
  sonuc_html := DoLogin('kullanıcı_adı', 'şifre');
  if sonuc_html = '' then
  begin
    ShowMessage('login başarısız');
    Exit;
  end;

  doc := coHTMLDocument.Create as IHTMLDocument2;
  doc.write(sonuc_html);
  doc.close;

  ListView1.Clear;
  ListView1.Items.BeginUpdate;
  try
    ilk_satir := True;
    satirlar := doc.body.all.tags('TR');
    for i := 0 to satirlar.length - 1 do
    begin
      satir := satirlar.item(i);
      if satir.className = 'trow1 smalltext' then
      begin
        if ilk_satir then // ilk satırı atlıyoruz
        begin
          ilk_satir := False;
          Continue;
        end;
        kolonlar := satir.all.tags('TD');

        aItem := ListView1.Items.Add;
        aItem.ImageIndex := Integer(ContainsStr(satir.innerHTML, 'ps_minion'));
        aItem.Data := RefString(satir.all.tags('A').item(0).href);
        for j := 0 to kolonlar.length-1 do
        begin
          icerik := kolonlar.item(j).innerText;
          case j of
            0: aItem.Caption := icerik; // konu sütunu
            2: aItem.SubItems.Add(icerik); // yazar sütunu
            4: aItem.SubItems.Add(icerik); // forum sütunu
          end;
        end;
      end;
    end;
  finally
    ListView1.Items.EndUpdate;
  end;
end;

procedure TFrmMain.ListView1DblClick(Sender: TObject);
var
  link: String;
begin
  if ListView1.Selected <> nil then
  begin
    link := String(ListView1.Selected.Data);
    ShellExecute(0, 'open', PWideChar(link), nil, nil, SW_ShowNormal);
  end;
end;

procedure TFrmMain.ListView1Deletion(Sender: TObject; Item: TListItem);
begin
  ReleaseString(Item.Data);
end;

procedure TFrmMain.ListView1SelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  Caption := String(Item.Data);
end;

end.
