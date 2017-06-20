program delphi_vcl_image;

uses
  Vcl.Forms,
  FormOpenALPRImage in 'FormOpenALPRImage.pas' {OpenALPRImageForm},
  openalpr in '..\..\openalpr.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TOpenALPRImageForm, OpenALPRImageForm);
  Application.Run;
end.
