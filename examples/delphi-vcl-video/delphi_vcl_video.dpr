program delphi_vcl_video;

uses
  Vcl.Forms,
  FormOpenALPRVideo in 'FormOpenALPRVideo.pas' {OpenALPRVideoForm},
  openalpr in '..\..\openalpr.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TOpenALPRVideoForm, OpenALPRVideoForm);
  Application.Run;
end.
